#!/usr/bin/env python3
"""H6 results tables (task 6) — regenerable from raw per-game records.

Reads data/runs/cmp-{arm}-s{seed}/eval/*.csv and emits, under
results/comparison/:
  results-same-examples.md/.csv   final checkpoints (gen009 per run)
  results-same-wallclock.md/.csv  T* checkpoints (grid: gen009/gen009/
                                  gen008 — s1/s2 reuse finals; graph:
                                  gen003/gen004/gen004; tstar-* files)
  results-arm-difference.md       per-opponent arm contrast with
                                  bootstrap-over-seeds CIs

Conventions (protocol v1.0 §4/§6; invariants 7, 8): score excludes
truncations (rate reported separately; 0.5-sensitivity column);
aggregation per (seed, opponent) first; intervals bootstrap over seeds;
no game pooled as i.i.d.
"""

import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from analyze_comparison import load, summarize  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "results" / "comparison"
OPPONENTS = ["B-RND", "B-HEU", "B-MCTS"]
SEEDS = [1, 2, 3, 4, 5]  # seeds 4-5 added per D-031 (all-seeds pre-commitment)
def _tstar_hours():
    """T* = median full-run wall-clock of the ORIGINAL three grid runs
    (pre-registered rule, executed 2026-09-16; D-031b: seeds 4-5 never
    enter the median). Computed exactly from the wall-clock files so the
    defining run's own final checkpoint sits AT T* inclusively — the
    rounded 18.77 h constant broke that boundary."""
    import json, statistics
    tots = []
    for seed in [1, 2, 3]:
        c = json.load(open(REPO / "data" / "runs" / f"cmp-grid-s{seed}" / "wallclock.json"))
        tots.append(sum(c.values()) / 3600)
    return statistics.median(tots)


TSTAR_H = None  # set lazily (exact median; reported as 18.77 h)


def tstar_checkpoint(arm, seed):
    """Last checkpoint completed at <= T*, from the run's wall-clock log.
    Returns (genNNN, kind) where kind 'final' means the gen009 final eval
    doubles as the T* eval (same checkpoint/volume/openings)."""
    import json
    global TSTAR_H
    if TSTAR_H is None:
        TSTAR_H = _tstar_hours()
    clock = json.load(open(REPO / "data" / "runs" / f"cmp-{arm}-s{seed}" / "wallclock.json"))
    cum, last = 0.0, None
    for gen in sorted(clock):
        cum += clock[gen]
        if cum / 3600 <= TSTAR_H:
            last = gen
    assert last is not None, f"no checkpoint within T* for {arm}-s{seed}"
    return (last, "final" if last == "gen009" else "tstar")


def cell(arm, seed, opp, reading):
    run = REPO / "data" / "runs" / f"cmp-{arm}-s{seed}" / "eval"
    if reading == "same-examples":
        f = run / f"gen009-vs-{opp}.csv"
    else:
        gen, kind = tstar_checkpoint(arm, seed)
        f = run / (f"gen009-vs-{opp}.csv" if kind == "final"
                   else f"tstar-{gen}-vs-{opp}.csv")
    if not f.exists():
        return None
    _, rows = load(f)
    return summarize(rows)


def boot_ci(vals, iters=10000, seed=0):
    rng = random.Random(seed)
    n = len(vals)
    ms = sorted(sum(vals[rng.randrange(n)] for _ in range(n)) / n
                for _ in range(iters))
    return ms[int(0.025 * iters)], ms[int(0.975 * iters)]


def diff_ci(a, b, iters=10000, seed=0):
    rng = random.Random(seed)
    ds = sorted(
        sum(a[rng.randrange(len(a))] for _ in range(len(a))) / len(a)
        - sum(b[rng.randrange(len(b))] for _ in range(len(b))) / len(b)
        for _ in range(iters)
    )
    return ds[int(0.025 * iters)], ds[int(0.975 * iters)]


def table(reading):
    md = [f"# H6 results — {reading} reading",
          "", "Score = mean over non-truncated games (win 1 / draw 0.5 / "
          "loss 0); trunc = truncation rate; sens = truncations scored 0.5.",
          ""]
    csv = ["arm,seed,opponent,score,trunc_rate,score_sens_05,games"]
    complete = True
    md.append("| Arm | Seed | " + " | ".join(
        f"{o} score / trunc" for o in OPPONENTS) + " |")
    md.append("|" + " --- |" * (2 + len(OPPONENTS)))
    per = {}
    for arm in ["grid", "graph"]:
        for seed in SEEDS:
            rowcells = []
            for opp in OPPONENTS:
                s = cell(arm, seed, opp, reading)
                if s is None:
                    rowcells.append("PENDING")
                    complete = False
                    continue
                per.setdefault((arm, opp), []).append(s["score"])
                rowcells.append(f"{s['score']:.3f} / {s['trunc_rate']:.0%}")
                csv.append(f"{arm},{seed},{opp},{s['score']:.4f},"
                           f"{s['trunc_rate']:.4f},{s['score_sens_05']:.4f},"
                           f"{s['games']}")
            md.append(f"| {arm} | s{seed} | " + " | ".join(rowcells) + " |")
    md += ["", "## Seed-level means (bootstrap 95%, unit = seed)", ""]
    for arm in ["grid", "graph"]:
        for opp in OPPONENTS:
            vals = per.get((arm, opp), [])
            if len(vals) == len(SEEDS):
                lo, hi = boot_ci(vals)
                md.append(f"- {arm} vs {opp}: mean "
                          f"{sum(vals)/len(vals):.3f} [{lo:.3f}, {hi:.3f}] "
                          f"(seeds: {', '.join(f'{v:.3f}' for v in vals)})")
    return md, csv, per, complete


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    contrast_blocks = []
    for reading in ["same-examples", "same-wallclock"]:
        md, csv, per, complete = table(reading)
        (OUT / f"results-{reading}.md").write_text("\n".join(md) + "\n")
        (OUT / f"results-{reading}.csv").write_text("\n".join(csv) + "\n")
        print(f"{reading}: {'complete' if complete else 'PENDING cells'} "
              f"-> results-{reading}.md")
        if complete:
            lines = [f"# Arm contrast — {reading}", "",
                     "Graph − grid difference of seed-level means; bootstrap "
                     f"95% over seeds ({len(SEEDS)} per arm, independent).",
                     ""]
            for opp in OPPONENTS:
                g = per[("graph", opp)]
                c = per[("grid", opp)]
                d = sum(g) / len(g) - sum(c) / len(c)
                lo, hi = diff_ci(g, c)
                lines.append(f"- vs {opp}: graph−grid = {d:+.3f} "
                             f"[{lo:+.3f}, {hi:+.3f}]")
            contrast_blocks.append("\n".join(lines) + "\n")
            print(f"  arm contrast ({reading}) computed")
    # Rewritten whole each run (an earlier append-only version kept a
    # stale seed count in the prose after the 5-seed extension).
    if contrast_blocks:
        (OUT / "results-arm-difference.md").write_text(
            "\n".join(contrast_blocks))


if __name__ == "__main__":
    main()
