"""H4 pre-training checks, data/model side (pipeline H4 tasks 3-5, 9).

Run:  .venv/bin/python -m hivenet.checks <shard-glob> [--manifest M.json]

Covers:
  check 1  policy normalised over legal actions only: masked softmax puts
           exactly zero mass on illegal actions and sums to 1 over legal,
           on real recorded positions with a real forward pass;
  check 2  (python side) every stored policy-target index lies inside the
           record's legal set — id<->move round-trip itself is the Rust
           test `policy_index_roundtrips_to_move`;
  check 3  WDL byte is a valid outcome (0 L / 1 D / 2 W / 3 truncated) and
           truncated records are excluded from value-loss batches;
  stamp    every record's model stamp matches the run manifest (dataset <->
           model association, task 2).

The engine-side checks (terminal signs, eval-noise defaults) live in the
Rust test suite; scripts/run_h4_checks.sh runs both halves.
"""

import argparse
import glob
import json
import sys

import numpy as np
import torch

from .dataset import (
    POLICY_SIZE,
    RECORD_SIZE,
    RECORD_V2_TOPK,
    WDL_TRUNCATED,
    HiveRecordDataset,
    legal_mask,
    model_stamp,
)
from .model import HiveNet
from .train import policy_loss, value_loss


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("shards", help="glob of .bin shards")
    ap.add_argument("--manifest", default=None)
    ap.add_argument("--sample", type=int, default=64)
    ap.add_argument("--channels", type=int, default=32)
    ap.add_argument("--blocks", type=int, default=2)
    args = ap.parse_args()

    paths = sorted(glob.glob(args.shards))
    assert paths, f"no shards match {args.shards}"
    ds = HiveRecordDataset(paths)
    n = min(args.sample, len(ds))
    print(f"checks over {n}/{len(ds)} records from {len(paths)} shards")

    # --- check 1: legal-masked policy normalisation on a real forward pass.
    torch.manual_seed(0)
    net = HiveNet(args.channels, args.blocks).eval()
    batch = [ds[i] for i in range(n)]
    planes = torch.stack([b[0] for b in batch])
    masks = torch.stack([b[3] for b in batch])
    with torch.no_grad():
        p_logits, v_logits = net(planes)
        probs = torch.softmax(p_logits.masked_fill(~masks, -1e9), dim=1)
    illegal_mass = probs.masked_fill(masks, 0.0).sum(dim=1).max().item()
    legal_sum_err = (probs.sum(dim=1) - 1.0).abs().max().item()
    assert illegal_mass == 0.0, f"check 1 FAIL: illegal mass {illegal_mass}"
    assert legal_sum_err < 1e-5, f"check 1 FAIL: legal mass sum err {legal_sum_err}"
    print(f"check 1 OK: illegal mass exactly 0, legal sums to 1 (max err {legal_sum_err:.1e})")

    # --- check 2 (data side): stored target indices are legal.
    for i in range(n):
        rec = ds.records[i]
        mask = legal_mask(rec)
        entries = rec[RECORD_SIZE : RECORD_SIZE + RECORD_V2_TOPK * 4].reshape(-1, 2, 2)
        idxs = entries[:, 0, 0].astype(np.int64) | (entries[:, 0, 1].astype(np.int64) << 8)
        weights = entries[:, 1, 0].astype(np.int64) | (entries[:, 1, 1].astype(np.int64) << 8)
        for idx, w in zip(idxs, weights):
            if w > 0:
                assert mask[idx], f"check 2 FAIL: target idx {idx} not legal (rec {i})"
        played = int(rec[96]) | (int(rec[97]) << 8)
        assert mask[played], f"check 2 FAIL: played idx {played} not legal (rec {i})"
    print("check 2 OK: all policy-target and played indices lie in the legal set")

    # --- check 3: WDL domain + truncation exclusion from the value loss.
    wdls = torch.tensor([int(ds.records[i][98]) for i in range(len(ds))])
    assert set(wdls.tolist()) <= {0, 1, 2, WDL_TRUNCATED}, "check 3 FAIL: bad WDL byte"
    fake_logits = torch.randn(len(wdls), 3)
    lv = value_loss(fake_logits, wdls)
    keep = wdls != WDL_TRUNCATED
    if bool(keep.any()):
        expected = torch.nn.functional.cross_entropy(fake_logits[keep], wdls[keep])
        assert torch.allclose(lv, expected), "check 3 FAIL: truncated not excluded"
    trunc = int((wdls == WDL_TRUNCATED).sum())
    print(f"check 3 OK: WDL domain valid; {trunc} truncated records excluded from value loss")

    # --- masked policy loss is finite on real targets (guards -inf leaks).
    targets = torch.stack([b[1] for b in batch])
    lp = policy_loss(p_logits, targets, masks, masked=True)
    assert torch.isfinite(lp), "masked policy loss not finite"
    print(f"masked policy loss finite: {lp.item():.3f}")

    # --- stamp: dataset <-> model association.
    if args.manifest:
        man = json.load(open(args.manifest))
        want = (int(man["model_gen"]), int(man["net_fnv1a32"]))
        stamps = {model_stamp(ds.records[i]) for i in range(len(ds))}
        assert stamps == {want}, f"stamp FAIL: records {stamps} != manifest {want}"
        print(f"stamp OK: all {len(ds)} records stamped {want} per manifest")

    print("ALL CHECKS OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
