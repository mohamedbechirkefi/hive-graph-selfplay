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
SEEDS = [1, 2, 3]
TSTAR = {  # journal H6-2026-09-16-progress-01 (pre-registered rule)
    ("grid", 1): ("gen009", "final"), ("grid", 2): ("gen009", "final"),
    ("grid", 3): ("gen008", "tstar"),
    ("graph", 1): ("gen003", "tstar"), ("graph", 2): ("gen004", "tstar"),
    ("graph", 3): ("gen004", "tstar"),
}


def cell(arm, seed, opp, reading):
    run = REPO / "data" / "runs" / f"cmp-{arm}-s{seed}" / "eval"
    if reading == "same-examples":
        f = run / f"gen009-vs-{opp}.csv"
    else:
        gen, kind = TSTAR[(arm, seed)]
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
    for reading in ["same-examples", "same-wallclock"]:
        md, csv, per, complete = table(reading)
        (OUT / f"results-{reading}.md").write_text("\n".join(md) + "\n")
        (OUT / f"results-{reading}.csv").write_text("\n".join(csv) + "\n")
        print(f"{reading}: {'complete' if complete else 'PENDING cells'} "
              f"-> results-{reading}.md")
        if complete:
            lines = [f"# Arm contrast — {reading}", "",
                     "Graph − grid difference of seed-level means; bootstrap "
                     "95% over seeds (3 per arm, independent).", ""]
            for opp in OPPONENTS:
                g = per[("graph", opp)]
                c = per[("grid", opp)]
                d = sum(g) / 3 - sum(c) / 3
                lo, hi = diff_ci(g, c)
                lines.append(f"- vs {opp}: graph−grid = {d:+.3f} "
                             f"[{lo:+.3f}, {hi:+.3f}]")
            existing = OUT / "results-arm-difference.md"
            prev = existing.read_text() if existing.exists() else ""
            block = "\n".join(lines) + "\n"
            if f"# Arm contrast — {reading}" not in prev:
                existing.write_text(prev + ("\n" if prev else "") + block)
            print(f"  arm contrast ({reading}) appended")


if __name__ == "__main__":
    main()
