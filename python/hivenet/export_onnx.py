"""Export a trained checkpoint to fixed-shape ONNX graphs.

The CoreML execution provider needs static shapes, so we export one graph
per batch size (1 for match play, 128 for self-play batching).

Usage:
  python -m hivenet.export_onnx checkpoints/hivenet-e3.pt --out models/
"""

import argparse
import os

import torch

from .graph_dataset import GLOBAL_F, MOVE_CAP, NODE_CAP, NODE_F
from .graph_model import HiveGraphNet
from .model import FRAME, PLANES, HiveNet


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint", help="checkpoint .pt, or 'random' for a fresh init (gen 0)")
    ap.add_argument("--out", default="models")
    ap.add_argument("--batches", type=int, nargs="+", default=[1, 128])
    ap.add_argument("--channels", type=int, default=96, help="for 'random' init")
    ap.add_argument("--blocks", type=int, default=8, help="for 'random' init")
    ap.add_argument("--seed", type=int, default=0, help="for 'random' init")
    args = ap.parse_args()

    graph_arm = False
    if args.checkpoint in ("random", "random-graph"):
        torch.manual_seed(args.seed)
        if args.checkpoint == "random-graph":
            graph_arm = True
            net = HiveGraphNet(args.channels, args.blocks)
            base = f"hivegraph-random-h{args.channels}L{args.blocks}s{args.seed}"
        else:
            net = HiveNet(args.channels, args.blocks)
            base = f"hivenet-random-c{args.channels}b{args.blocks}s{args.seed}"
    else:
        ckpt = torch.load(args.checkpoint, map_location="cpu", weights_only=True)
        graph_arm = ckpt.get("args", {}).get("arm") == "graph" or "hivegraph" in os.path.basename(
            args.checkpoint
        )
        if graph_arm:
            net = HiveGraphNet(ckpt["channels"], ckpt["blocks"])
        else:
            net = HiveNet(ckpt["channels"], ckpt["blocks"])
        net.load_state_dict(ckpt["model"])
        base = os.path.splitext(os.path.basename(args.checkpoint))[0]
    net.eval()

    os.makedirs(args.out, exist_ok=True)
    for b in args.batches:
        path = os.path.join(args.out, f"{base}-b{b}.onnx")
        if graph_arm:
            dummy = (
                torch.zeros(b, NODE_CAP, NODE_F),
                torch.full((b, NODE_CAP, 6), NODE_CAP, dtype=torch.long),
                torch.zeros(b, NODE_CAP, dtype=torch.bool),
                torch.zeros(b, GLOBAL_F),
                torch.full((b, MOVE_CAP, 3), NODE_CAP, dtype=torch.long),
                torch.zeros(b, MOVE_CAP, dtype=torch.bool),
            )
            names = ["nodes", "nbrs", "nmask", "glob", "moves", "mmask"]
        else:
            dummy = (torch.zeros(b, PLANES, FRAME, FRAME),)
            names = ["planes"]
        torch.onnx.export(
            net,
            dummy,
            path,
            input_names=names,
            output_names=["policy", "value"],
            do_constant_folding=True,
            dynamo=False,
        )
        print(f"exported {path}")

    # Smoke-check with onnxruntime CPU.
    import numpy as np
    import onnxruntime as ort

    sess = ort.InferenceSession(
        os.path.join(args.out, f"{base}-b1.onnx"),
        providers=["CPUExecutionProvider"],
    )
    if graph_arm:
        feed = {
            "nodes": np.zeros((1, NODE_CAP, NODE_F), np.float32),
            "nbrs": np.full((1, NODE_CAP, 6), NODE_CAP, np.int64),
            "nmask": np.zeros((1, NODE_CAP), bool),
            "glob": np.zeros((1, GLOBAL_F), np.float32),
            "moves": np.full((1, MOVE_CAP, 3), NODE_CAP, np.int64),
            "mmask": np.zeros((1, MOVE_CAP), bool),
        }
    else:
        feed = {"planes": np.zeros((1, PLANES, FRAME, FRAME), np.float32)}
    p, v = sess.run(None, feed)
    print(f"onnxruntime OK: policy {p.shape}, value {v.shape}")


if __name__ == "__main__":
    main()
