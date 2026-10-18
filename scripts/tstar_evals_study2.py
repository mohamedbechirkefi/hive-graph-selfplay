#!/usr/bin/env python3
"""Study 2 (protocol v2 §4) same-wall-clock cutoff evaluations.

Mirrors scripts/tstar_evals.sh (Study 1) for the cmp2-* runs:
  * T*' = median of the five Study 2 grid totals (sum of wallclock.json),
    taken from make_results.py --study 2's rule; undefined (exit 1) until
    all five grid runs have a complete clock file;
  * cutoff checkpoint per run = last generation whose cumulative clock is
    at or below T*' (inclusive); where it is gen009, the final evaluation
    is reused and nothing runs;
  * hive-arena, 100 paired games per opponent on the frozen openings,
    network at 400 simulations with seed 9500, arena seed 888000,
    opponents B-RND (seed 9101) / B-HEU / B-MCTS (6400 sims, seed 9201);
    records to <run>/eval/tstar-genNNN-vs-<opp>.csv, skipped if present.

Refuses to run while campaign2.sh is alive (the campaign's clocks are the
measurement). --dry-run prints T*', the cutoff map and the commands only.
Scores are never printed here; make_results.py --study 2 reads them.

Usage: python3 scripts/tstar_evals_study2.py [--dry-run]
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import make_results as mr  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
OPEN = REPO / "results" / "comparison" / "openings-v1.txt"
ENGINE = "./target/release/hive-engine"
OPPONENTS = {
    "B-RND": [ENGINE, "--random", "--seed", "9101"],
    "B-HEU": [ENGINE],
    "B-MCTS": [ENGINE, "--mcts", "--sims", "6400", "--seed", "9201"],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    mr.configure(2)
    tstar = mr._tstar_hours()
    if tstar is None:
        print("T*' undefined: not all five Study 2 grid runs have a complete wallclock.json")
        return 1
    alive = subprocess.run(["pgrep", "-f", "bash scripts/campaign2.sh"],
                           capture_output=True).returncode == 0
    if alive and not args.dry_run:
        print("campaign2.sh is still running; refusing to evaluate beside it")
        return 2
    print(f"T*' = {tstar:.4f} h (median of the five Study 2 grid totals)")

    plan = []
    for arm in ("grid", "graph"):
        for seed in mr.SEEDS:
            ck = mr.tstar_checkpoint(arm, seed)
            if ck is None:
                print(f"{arm}-s{seed}: wallclock.json missing, skipped")
                continue
            gen, kind = ck
            if kind == "final":
                print(f"{arm}-s{seed}: cutoff = {gen} = final checkpoint, final evaluation reused")
            else:
                print(f"{arm}-s{seed}: cutoff = {gen}")
                plan.append((arm, seed, gen))

    for arm, seed, gen in plan:
        run = REPO / "data" / "runs" / f"cmp2-{arm}-s{seed}"
        net = run / "checkpoints" / f"{gen}-b1.onnx"
        netflag = "--net" if arm == "grid" else "--graph-net"
        for name, opp in OPPONENTS.items():
            rec = run / "eval" / f"tstar-{gen}-vs-{name}.csv"
            if rec.exists():
                continue
            cmd = ["./target/release/hive-arena", "--games", "100", "--depth", "1",
                   "--seed", "888000", "--threads", "4",
                   "--openings-file", str(OPEN), "--records", str(rec),
                   "--label", f"{arm}:s{seed}:tstar-{gen}:vs:{name}",
                   "--", ENGINE, "--mcts", netflag, str(net), "--sims", "400", "--seed", "9500",
                   "--", *opp]
            print("+ " + " ".join(cmd), flush=True)
            if args.dry_run:
                continue
            assert net.exists(), f"missing network {net}"
            with open(run / "eval" / f"tstar-{gen}-vs-{name}.log", "w") as log:
                subprocess.run(cmd, cwd=REPO, env={**os.environ, "HIVE_THREADS": "1"},
                               stdout=log, stderr=subprocess.STDOUT, check=True)
            print(f"done {arm}-s{seed} {gen} vs {name}", flush=True)
    print("cutoff evaluations " + ("planned (dry run)" if args.dry_run else "complete"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
