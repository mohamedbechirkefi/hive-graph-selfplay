#!/usr/bin/env python3
"""H4 check 5: save then resume without loss.

Runs training twice on the same shards, CPU, workers=0, seeded:
  A) uninterrupted: epochs 0..1 in one process;
  B) interrupted: epochs 0 only, then a fresh process resumes from the
     epoch-0 checkpoint and trains epoch 1.
The epoch-1 checkpoints must contain bitwise-identical model tensors and
identical optimizer state (same losses along the way follow from that).

Usage: python3 scripts/check5_resume.py <shard-glob> [workdir]
"""

import subprocess
import sys
import tempfile
from pathlib import Path

import torch

SHARDS = sys.argv[1]
WORK = Path(sys.argv[2] if len(sys.argv) > 2 else tempfile.mkdtemp(prefix="check5-"))
PY = ".venv/bin/python"  # resolved relative to cwd="python"
COMMON = [
    "--data", SHARDS, "--batch", "16", "--channels", "16", "--blocks", "1",
    "--workers", "0", "--seed", "7", "--cpu", "--lr", "0.01",
]


def train(out, extra):
    cmd = [PY, "-m", "hivenet.train", "--out", str(out), *COMMON, *extra]
    import os
    env = {**os.environ, "PYTHONPATH": "."}
    r = subprocess.run(cmd, cwd="python", capture_output=True, text=True, env=env)
    if r.returncode != 0:
        print(r.stdout[-2000:], r.stderr[-2000:])
        sys.exit(f"training failed: {' '.join(cmd)}")


def load(p):
    return torch.load(p, map_location="cpu", weights_only=True)


import glob

# Steps per epoch (batch 16, drop_last, 2% val split) so the interrupted
# leg keeps the SAME planned schedule (--epochs 2) and stops exactly at
# the epoch-0 boundary via --max-steps: an interruption must never change
# the LR schedule the run was configured with.
V3_SIZE, HEADER = 818, 16
n_records = sum(
    (Path(p).stat().st_size - HEADER) // V3_SIZE
    for p in glob.glob(str(Path("python") / ".." / SHARDS))
    or glob.glob(SHARDS)
)
n_train = n_records - max(1, n_records // 50)
steps_per_epoch = n_train // 16
assert steps_per_epoch >= 1, f"too few records ({n_records}) for the check"

a, b = WORK / "uninterrupted", WORK / "resumed"
train(a, ["--epochs", "2"])
train(b, ["--epochs", "2", "--max-steps", str(steps_per_epoch)])
train(b, ["--epochs", "2", "--resume", str((b / "hivenet-e0.pt").resolve())])

ca, cb = load(a / "hivenet-e1.pt"), load(b / "hivenet-e1.pt")
assert ca["step"] == cb["step"], f"step mismatch {ca['step']} vs {cb['step']}"
for k in ca["model"]:
    ta, tb = ca["model"][k], cb["model"][k]
    assert torch.equal(ta, tb), f"model tensor {k} differs after resume"
for (ka, va), (kb, vb) in zip(
    ca["opt"]["state"].items(), cb["opt"]["state"].items()
):
    for f in va:
        if torch.is_tensor(va[f]):
            assert torch.equal(va[f], vb[f]), f"optimizer state {ka}.{f} differs"
print(f"check 5 OK: resumed epoch-1 checkpoint bitwise-identical "
      f"(step {ca['step']}, {len(ca['model'])} tensors) in {WORK}")
