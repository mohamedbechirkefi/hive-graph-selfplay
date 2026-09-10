#!/usr/bin/env python3
"""H6 analysis over arena per-game records (protocol v1.0 §4/§6).

Record CSVs come from `hive-arena --records` (one row per game:
opening_id, a_is_white, score_a, truncated, plies, outcome; run metadata
in '#' header lines).

Conventions enforced here, not left to the caller:
  - primary score = mean over NON-truncated games (win 1 / draw 0.5 /
    loss 0); truncation rate reported separately (invariant 7 / D-008);
  - sensitivity line scores truncations 0.5;
  - games are never pooled as i.i.d.: aggregation is per (seed, opponent)
    cell first, then over seeds; opening-paired differences use the
    shared opening ids ([S4]; protocol §6).

Usage:
  analyze_comparison.py summary FILE...            per-file summaries
  analyze_comparison.py schedule FILE...           (opening,colour) schedule hash
  analyze_comparison.py paired A.csv B.csv         opening-paired diff (A vs B)
  analyze_comparison.py seeds --cell ARM:OPP F...  seed-level table + bootstrap
"""

import argparse
import hashlib
import random
import sys
from pathlib import Path


def load(path):
    meta, rows = {}, []
    for line in Path(path).read_text().splitlines():
        if line.startswith("#"):
            if ":" in line:
                k, v = line[1:].split(":", 1)
                meta[k.strip()] = v.strip()
            continue
        if line.startswith("opening_id") or not line.strip():
            continue
        oid, aw, score, trunc, plies, outcome = line.split(",", 5)
        rows.append(
            dict(opening=int(oid), a_white=aw == "1", score=float(score),
                 truncated=trunc == "1", plies=int(plies), outcome=outcome)
        )
    return meta, rows


def summarize(rows):
    n = len(rows)
    tr = [r for r in rows if r["truncated"]]
    dec = [r for r in rows if not r["truncated"]]
    wins = sum(1 for r in dec if r["score"] == 1.0)
    draws = sum(1 for r in dec if r["score"] == 0.5)
    losses = len(dec) - wins - draws
    score = sum(r["score"] for r in dec) / len(dec) if dec else float("nan")
    sens = sum(r["score"] for r in rows) / n if n else float("nan")
    return dict(games=n, wins=wins, draws=draws, losses=losses,
                truncated=len(tr), trunc_rate=len(tr) / n if n else 0.0,
                score=score, score_sens_05=sens)


def schedule_hash(rows):
    """Hash of the (opening id, colour) schedule — must be identical for
    every run that claims the same pairing plan (H6 task 3)."""
    sched = sorted((r["opening"], r["a_white"]) for r in rows)
    return hashlib.sha256(str(sched).encode()).hexdigest()[:16]


def paired_diff(rows_a, rows_b):
    """Opening-paired score difference A−B over openings decided in both
    (colour-averaged per opening; truncated games excluded per side)."""

    def per_opening(rows):
        acc = {}
        for r in rows:
            if not r["truncated"]:
                acc.setdefault(r["opening"], []).append(r["score"])
        return {o: sum(v) / len(v) for o, v in acc.items()}

    pa, pb = per_opening(rows_a), per_opening(rows_b)
    common = sorted(set(pa) & set(pb))
    diffs = [pa[o] - pb[o] for o in common]
    mean = sum(diffs) / len(diffs) if diffs else float("nan")
    return dict(openings=len(common), mean_diff=mean, diffs=diffs)


def bootstrap_over_seeds(cell_scores, iters=10000, seed=0):
    """Percentile bootstrap CI over per-seed scores (the resampling unit
    is the SEED, protocol §6)."""
    rng = random.Random(seed)
    n = len(cell_scores)
    means = []
    for _ in range(iters):
        sample = [cell_scores[rng.randrange(n)] for _ in range(n)]
        means.append(sum(sample) / n)
    means.sort()
    return means[int(0.025 * iters)], means[int(0.975 * iters)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["summary", "schedule", "paired", "seeds"])
    ap.add_argument("files", nargs="+")
    ap.add_argument("--cell", default="", help="label filter for seeds mode")
    args = ap.parse_args()

    if args.mode == "summary":
        for f in args.files:
            meta, rows = load(f)
            s = summarize(rows)
            print(f"{Path(f).name} [{meta.get('label', '')}]: "
                  f"+{s['wins']} ={s['draws']} -{s['losses']} "
                  f"trunc {s['truncated']}/{s['games']} ({s['trunc_rate']:.1%}) "
                  f"score {s['score']:.3f} (sens0.5 {s['score_sens_05']:.3f})")
    elif args.mode == "schedule":
        hashes = {}
        for f in args.files:
            _, rows = load(f)
            h = schedule_hash(rows)
            hashes.setdefault(h, []).append(Path(f).name)
            print(f"{Path(f).name}: schedule {h}")
        if len(hashes) == 1:
            print("SCHEDULES IDENTICAL")
        else:
            print("SCHEDULES DIFFER", file=sys.stderr)
            sys.exit(1)
    elif args.mode == "paired":
        assert len(args.files) == 2, "paired mode takes exactly two files"
        (_, ra), (_, rb) = load(args.files[0]), load(args.files[1])
        d = paired_diff(ra, rb)
        print(f"paired over {d['openings']} shared openings: "
              f"mean diff (A−B) {d['mean_diff']:+.3f}")
    elif args.mode == "seeds":
        scores = []
        for f in args.files:
            meta, rows = load(f)
            if args.cell and args.cell not in meta.get("label", ""):
                continue
            s = summarize(rows)
            scores.append(s["score"])
            print(f"  seed file {Path(f).name}: score {s['score']:.3f} "
                  f"(trunc {s['trunc_rate']:.1%})")
        if len(scores) >= 2:
            lo, hi = bootstrap_over_seeds(scores)
            print(f"cell '{args.cell}': {len(scores)} seeds, "
                  f"mean {sum(scores)/len(scores):.3f}, "
                  f"bootstrap95 [{lo:.3f}, {hi:.3f}] (unit = seed)")
        else:
            print(f"cell '{args.cell}': {len(scores)} seed(s) — no interval")


if __name__ == "__main__":
    main()
