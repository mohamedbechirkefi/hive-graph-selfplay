"""Training loop for HiveNet (policy + WDL value) over self-play records.

H4 conventions (docs/action-decoder.md; D-008/D-015):
  - policy loss uses a LEGAL-MASKED log-softmax when the record carries the
    legal-move list (v3); illegal logits get -1e9 so normalisation runs over
    exactly the legal set — the same normalisation the inference path and
    (later) the graph arm use. --no-masked-policy restores the unmasked
    variant for ablation only.
  - WDL value 3 = truncated game: excluded from the value loss (never
    trained as a draw); policy target still used.
  - checkpoints carry model + optimizer + scheduler + step/epoch + RNG
    state and the run config; --resume continues bit-compatibly (with
    --workers 0; DataLoader worker scheduling is not replayed otherwise).

Usage:
  python -m hivenet.train --data 'data/runs/r0/selfplay/gen000-*.bin' \
      --out data/runs/r0/checkpoints [--epochs 4] [--seed 1] [--resume CKPT]
"""

import argparse
import glob
import json
import os
import time

import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader, random_split

from .dataset import WDL_TRUNCATED, HiveRecordDataset
from .model import HiveNet, count_params


def device(force_cpu: bool = False) -> torch.device:
    if not force_cpu and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def policy_loss(p_logits, target, mask, masked: bool):
    if masked:
        p_logits = p_logits.masked_fill(~mask, -1e9)
    return -(target * F.log_softmax(p_logits, dim=1)).sum(dim=1).mean()


def value_loss(v_logits, wdl):
    """Cross-entropy over W/D/L, truncated samples excluded (D-008)."""
    keep = wdl != WDL_TRUNCATED
    if not bool(keep.any()):
        return v_logits.sum() * 0.0
    return F.cross_entropy(v_logits[keep], wdl[keep])


def save_ckpt(path, net, opt, sched, step, epoch, args):
    torch.save(
        {
            "model": net.state_dict(),
            "opt": opt.state_dict(),
            "sched": sched.state_dict(),
            "step": step,
            "epoch": epoch,
            "torch_rng": torch.get_rng_state(),
            "channels": args.channels,
            "blocks": args.blocks,
            "args": vars(args),
        },
        path,
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, nargs="+", help="glob(s) of .bin shards")
    ap.add_argument("--out", default="checkpoints")
    ap.add_argument("--epochs", type=int, default=4)
    ap.add_argument("--batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=0.02)
    ap.add_argument("--wd", type=float, default=1e-4)
    ap.add_argument("--channels", type=int, default=96)
    ap.add_argument("--blocks", type=int, default=8)
    ap.add_argument("--value-weight", type=float, default=0.6)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--max-steps", type=int, default=0, help="0 = no limit")
    ap.add_argument("--init", default=None, help="checkpoint to initialize model weights from")
    ap.add_argument("--resume", default=None, help="checkpoint to resume training from")
    ap.add_argument("--cpu", action="store_true", help="force CPU (deterministic checks)")
    ap.add_argument("--no-masked-policy", dest="masked_policy", action="store_false")
    ap.set_defaults(masked_policy=True)
    args = ap.parse_args()

    torch.manual_seed(args.seed)

    paths = sorted({p for pattern in args.data for p in glob.glob(pattern)})
    assert paths, f"no shards match {args.data}"
    ds = HiveRecordDataset(paths)
    val_n = max(1, len(ds) // 50)
    train_ds, val_ds = random_split(
        ds, [len(ds) - val_n, val_n], generator=torch.Generator().manual_seed(0)
    )
    print(f"{len(train_ds)} train / {len(val_ds)} val records from {len(paths)} shards")

    dev = device(args.cpu)
    net = HiveNet(args.channels, args.blocks).to(dev)
    opt = torch.optim.SGD(net.parameters(), lr=args.lr, momentum=0.9, weight_decay=args.wd)
    steps_total = max(1, len(train_ds) // args.batch) * args.epochs
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(
        opt, T_max=steps_total, eta_min=args.lr / 100
    )

    step, start_epoch = 0, 0
    if args.resume:
        ckpt = torch.load(args.resume, map_location="cpu", weights_only=True)
        net.load_state_dict(ckpt["model"])
        opt.load_state_dict(ckpt["opt"])
        sched.load_state_dict(ckpt["sched"])
        step, start_epoch = ckpt["step"], ckpt["epoch"] + 1
        torch.set_rng_state(ckpt["torch_rng"])
        print(f"resumed from {args.resume} at step {step}, epoch {start_epoch}")
    elif args.init:
        ckpt = torch.load(args.init, map_location="cpu", weights_only=True)
        net.load_state_dict(ckpt["model"])
        print(f"initialized from {args.init}")
    print(
        f"HiveNet {args.channels}x{args.blocks}: {count_params(net)/1e6:.2f}M params "
        f"on {dev} (masked_policy={args.masked_policy})"
    )

    # The shuffle generator is re-seeded per epoch so a resume from an
    # epoch-boundary checkpoint replays the identical batch order (check 5).
    def epoch_loader(epoch: int) -> DataLoader:
        return DataLoader(
            train_ds, batch_size=args.batch, shuffle=True,
            num_workers=args.workers, drop_last=True,
            generator=torch.Generator().manual_seed(args.seed * 1000 + epoch),
        )

    val_dl = DataLoader(val_ds, batch_size=args.batch, num_workers=0)

    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "train-config.json"), "w") as f:
        json.dump({**vars(args), "shards": paths}, f, indent=2)

    done = False
    for epoch in range(start_epoch, args.epochs):
        net.train()
        t0 = time.time()
        for planes, target, wdl, mask in epoch_loader(epoch):
            planes, target = planes.to(dev), target.to(dev)
            wdl, mask = wdl.to(dev), mask.to(dev)
            p_logits, v_logits = net(planes)
            loss_p = policy_loss(p_logits, target, mask, args.masked_policy)
            loss_v = value_loss(v_logits, wdl)
            loss = loss_p + args.value_weight * loss_v
            # NaN guard (added 2026-09-23 after the A1 divergence
            # trained silently for 10 generations): halt loudly, never
            # train on a diverged net.
            if not torch.isfinite(loss):
                raise SystemExit(
                    f"HALT: non-finite loss at epoch {epoch} step {step} "
                    f"(p={loss_p.item()}, v={loss_v.item()}) — divergence")
            opt.zero_grad(set_to_none=True)
            loss.backward()
            opt.step()
            sched.step()
            step += 1
            if step % 100 == 0:
                print(
                    f"e{epoch} s{step}: loss {loss.item():.3f} "
                    f"(p {loss_p.item():.3f} v {loss_v.item():.3f}) "
                    f"lr {sched.get_last_lr()[0]:.4f} "
                    f"{args.batch*100/(time.time()-t0):.0f} pos/s"
                )
                t0 = time.time()
            if args.max_steps and step >= args.max_steps:
                done = True
                break

        # Validation: policy top-1 (masked as in training) and value accuracy
        # over non-truncated samples.
        net.eval()
        correct_p = correct_v = total = total_v = 0
        with torch.no_grad():
            for planes, target, wdl, mask in val_dl:
                planes = planes.to(dev)
                p_logits, v_logits = net(planes)
                p_logits = p_logits.cpu()
                if args.masked_policy:
                    p_logits = p_logits.masked_fill(~mask, -1e9)
                correct_p += (p_logits.argmax(1) == target.argmax(1)).sum().item()
                keep = wdl != WDL_TRUNCATED
                correct_v += (v_logits.argmax(1).cpu()[keep] == wdl[keep]).sum().item()
                total += len(wdl)
                total_v += int(keep.sum())
        print(
            f"=== epoch {epoch}: policy top-1 {correct_p/max(total,1):.1%}, "
            f"value acc {correct_v/max(total_v,1):.1%} "
            f"({total} val positions, {total - total_v} truncated excluded)"
        )
        ckpt_path = os.path.join(args.out, f"hivenet-e{epoch}.pt")
        save_ckpt(ckpt_path, net, opt, sched, step, epoch, args)
        print(f"saved {ckpt_path}")
        if done:
            break


if __name__ == "__main__":
    main()
