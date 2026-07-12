"""Supervised bootstrap training: predict the alpha-beta searcher's move
(policy) and the game outcome (WDL value) from self-play records.

Usage:
  python -m hivenet.train --data 'data/selfplay/run-*.bin' --out checkpoints/ \
      [--epochs 4] [--batch 256] [--lr 0.02] [--channels 96] [--blocks 8]
"""

import argparse
import glob
import os
import time

import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader, random_split

from .dataset import HiveRecordDataset
from .model import HiveNet, count_params


def device() -> torch.device:
    if torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--data", required=True, nargs="+", help="glob(s) of .bin shards"
    )
    ap.add_argument("--out", default="checkpoints")
    ap.add_argument("--epochs", type=int, default=4)
    ap.add_argument("--batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=0.02)
    ap.add_argument("--wd", type=float, default=1e-4)
    ap.add_argument("--channels", type=int, default=96)
    ap.add_argument("--blocks", type=int, default=8)
    ap.add_argument("--value-weight", type=float, default=0.6)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--init", default=None, help="checkpoint to initialize from")
    args = ap.parse_args()

    paths = sorted({p for pattern in args.data for p in glob.glob(pattern)})
    assert paths, f"no shards match {args.data}"
    ds = HiveRecordDataset(paths)
    val_n = max(1, len(ds) // 50)
    train_ds, val_ds = random_split(
        ds, [len(ds) - val_n, val_n], generator=torch.Generator().manual_seed(0)
    )
    print(f"{len(train_ds)} train / {len(val_ds)} val records from {len(paths)} shards")

    dev = device()
    net = HiveNet(args.channels, args.blocks).to(dev)
    if args.init:
        ckpt = torch.load(args.init, map_location="cpu", weights_only=True)
        net.load_state_dict(ckpt["model"])
        print(f"initialized from {args.init}")
    print(f"HiveNet {args.channels}x{args.blocks}: {count_params(net)/1e6:.2f}M params on {dev}")

    opt = torch.optim.SGD(net.parameters(), lr=args.lr, momentum=0.9, weight_decay=args.wd)
    steps = max(1, len(train_ds) // args.batch) * args.epochs
    sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=steps, eta_min=args.lr / 100)

    train_dl = DataLoader(
        train_ds, batch_size=args.batch, shuffle=True,
        num_workers=args.workers, drop_last=True, persistent_workers=args.workers > 0,
    )
    val_dl = DataLoader(val_ds, batch_size=args.batch, num_workers=0)

    os.makedirs(args.out, exist_ok=True)
    step = 0
    for epoch in range(args.epochs):
        net.train()
        t0 = time.time()
        for planes, target, wdl in train_dl:
            planes, target, wdl = planes.to(dev), target.to(dev), wdl.to(dev)
            p_logits, v_logits = net(planes)
            # Soft cross-entropy against the (possibly one-hot) visit
            # distribution.
            loss_p = -(target * F.log_softmax(p_logits, dim=1)).sum(dim=1).mean()
            loss_v = F.cross_entropy(v_logits, wdl)
            loss = loss_p + args.value_weight * loss_v
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

        # Validation: policy top-1 and value accuracy.
        net.eval()
        correct_p = correct_v = total = 0
        with torch.no_grad():
            for planes, target, wdl in val_dl:
                planes = planes.to(dev)
                p_logits, v_logits = net(planes)
                correct_p += (p_logits.argmax(1).cpu() == target.argmax(1)).sum().item()
                correct_v += (v_logits.argmax(1).cpu() == wdl).sum().item()
                total += len(wdl)
        print(
            f"=== epoch {epoch}: policy top-1 {correct_p/total:.1%}, "
            f"value acc {correct_v/total:.1%} ({total} val positions)"
        )
        ckpt = os.path.join(args.out, f"hivenet-e{epoch}.pt")
        torch.save(
            {
                "model": net.state_dict(),
                "channels": args.channels,
                "blocks": args.blocks,
                "epoch": epoch,
                "policy_top1": correct_p / total,
            },
            ckpt,
        )
        print(f"saved {ckpt}")


if __name__ == "__main__":
    main()
