"""Export a trained checkpoint to fixed-shape ONNX graphs.

The CoreML execution provider needs static shapes, so we export one graph
per batch size (1 for match play, 128 for self-play batching).

Usage:
  python -m hivenet.export_onnx checkpoints/hivenet-e3.pt --out models/
"""

import argparse
import os

import torch

from .model import FRAME, PLANES, HiveNet


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("checkpoint")
    ap.add_argument("--out", default="models")
    ap.add_argument("--batches", type=int, nargs="+", default=[1, 128])
    args = ap.parse_args()

    ckpt = torch.load(args.checkpoint, map_location="cpu", weights_only=True)
    net = HiveNet(ckpt["channels"], ckpt["blocks"])
    net.load_state_dict(ckpt["model"])
    net.eval()

    os.makedirs(args.out, exist_ok=True)
    base = os.path.splitext(os.path.basename(args.checkpoint))[0]
    for b in args.batches:
        path = os.path.join(args.out, f"{base}-b{b}.onnx")
        dummy = torch.zeros(b, PLANES, FRAME, FRAME)
        torch.onnx.export(
            net,
            (dummy,),
            path,
            input_names=["planes"],
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
    p, v = sess.run(None, {"planes": np.zeros((1, PLANES, FRAME, FRAME), np.float32)})
    print(f"onnxruntime OK: policy {p.shape}, value {v.shape}")


if __name__ == "__main__":
    main()
