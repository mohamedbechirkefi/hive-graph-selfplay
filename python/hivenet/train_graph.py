"""Graph-arm training loop — mirrors hivenet.train line for line where the
conventions matter (D-015 contract, D-008 truncation handling, bitwise
resume with per-epoch seeded shuffles). Only the dataset/model differ:
HiveGraphDataset tensors and HiveGraphNet, whose logits are already
restricted to legal move rows (structural masking — the same
normalisation the grid arm applies via masked softmax).

Usage:
  python -m hivenet.train_graph --data 'data/runs/r0/selfplay/gen000-*.bin' \
      --out data/runs/r0/checkpoints-graph [--epochs 3] [--seed 1]
"""

import argparse
import glob
import json
import os
import time

import torch
import torch.nn.functional as F
from torch.utils.data import DataLoader, random_split

from .dataset import WDL_TRUNCATED
from .graph_dataset import HiveGraphDataset
from .graph_model import HiveGraphNet, count_params
from .train import device, save_ckpt, value_loss


def graph_policy_loss(logits, target):
    return -(target * F.log_softmax(logits, dim=1)).sum(dim=1).mean()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", required=True, nargs="+")
    ap.add_argument("--out", default="checkpoints-graph")
    ap.add_argument("--epochs", type=int, default=4)
    ap.add_argument("--batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=0.02)
    ap.add_argument("--wd", type=float, default=1e-4)
    ap.add_argument("--hidden", type=int, default=152)
    ap.add_argument("--layers", type=int, default=8)
    ap.add_argument("--value-weight", type=float, default=0.6)
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--max-steps", type=int, default=0)
    ap.add_argument("--init", default=None)
    ap.add_argument("--resume", default=None)
    ap.add_argument("--cpu", action="store_true")
    ap.add_argument("--untyped-edges", action="store_true",
                    help="H7 ablation b: one shared edge matrix (naive adjacency)")
    ap.add_argument("--no-gpool", action="store_true",
                    help="H7 ablation a-sub: remove global-pooling bias")
    args = ap.parse_args()
    # save_ckpt records channels/blocks; map hidden/layers onto them.
    args.channels, args.blocks = args.hidden, args.layers

    torch.manual_seed(args.seed)
    paths = sorted({p for pattern in args.data for p in glob.glob(pattern)})
    assert paths, f"no shards match {args.data}"
    ds = HiveGraphDataset(paths)
    val_n = max(1, len(ds) // 50)
    train_ds, val_ds = random_split(
        ds, [len(ds) - val_n, val_n], generator=torch.Generator().manual_seed(0)
    )
    print(f"{len(train_ds)} train / {len(val_ds)} val records from {len(paths)} shards")

    dev = device(args.cpu)
    net = HiveGraphNet(args.hidden, args.layers,
                       untyped_edges=args.untyped_edges,
                       no_gpool=args.no_gpool).to(dev)
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
    print(f"HiveGraphNet {args.hidden}x{args.layers}: {count_params(net)/1e6:.2f}M params on {dev}")

    def epoch_loader(epoch: int) -> DataLoader:
        return DataLoader(
            train_ds, batch_size=args.batch, shuffle=True,
            num_workers=args.workers, drop_last=True,
            generator=torch.Generator().manual_seed(args.seed * 1000 + epoch),
        )

    val_dl = DataLoader(val_ds, batch_size=args.batch, num_workers=0)

    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "train-config.json"), "w") as f:
        json.dump({**vars(args), "shards": paths, "arm": "graph"}, f, indent=2)

    done = False
    for epoch in range(start_epoch, args.epochs):
        net.train()
        t0 = time.time()
        for nodes, nbrs, nmask, glob_, moves, mmask, target, wdl in epoch_loader(epoch):
            nodes, nbrs = nodes.to(dev), nbrs.to(dev)
            nmask, glob_ = nmask.to(dev), glob_.to(dev)
            moves, mmask = moves.to(dev), mmask.to(dev)
            target, wdl = target.to(dev), wdl.to(dev)
            p_logits, v_logits = net(nodes, nbrs, nmask, glob_, moves, mmask)
            loss_p = graph_policy_loss(p_logits, target)
            loss_v = value_loss(v_logits, wdl)
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
            if args.max_steps and step >= args.max_steps:
                done = True
                break

        net.eval()
        correct_p = correct_v = total = total_v = 0
        with torch.no_grad():
            for nodes, nbrs, nmask, glob_, moves, mmask, target, wdl in val_dl:
                p_logits, v_logits = net(
                    nodes.to(dev), nbrs.to(dev), nmask.to(dev),
                    glob_.to(dev), moves.to(dev), mmask.to(dev),
                )
                correct_p += (p_logits.argmax(1).cpu() == target.argmax(1)).sum().item()
                keep = wdl != WDL_TRUNCATED
                correct_v += (v_logits.argmax(1).cpu()[keep] == wdl[keep]).sum().item()
                total += len(wdl)
                total_v += int(keep.sum())
        print(
            f"=== epoch {epoch}: policy top-1 {correct_p/max(total,1):.1%}, "
            f"value acc {correct_v/max(total_v,1):.1%} "
            f"({total} val positions, {total - total_v} truncated excluded)"
        )
        ckpt_path = os.path.join(args.out, f"hivegraph-e{epoch}.pt")
        save_ckpt(ckpt_path, net, opt, sched, step, epoch, args)
        print(f"saved {ckpt_path}")
        if done:
            break


if __name__ == "__main__":
    main()
