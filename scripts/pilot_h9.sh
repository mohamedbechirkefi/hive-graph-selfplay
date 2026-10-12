#!/usr/bin/env bash
# H9 pilot (pipeline task 2, G-SPEND approved 2026-10-12: "lance le pilote").
# Two generations x 200 games per arm, one seed, warm start + replay window
# W=3, sequential grid then graph. Seed 10 and run prefix "pilot2" keep the
# pilot outside both Study 1 (cmp-*, seeds 1-5) and the Study 2 campaign
# (cmp2-*, seeds 11-15), so a later campaign run can never resume from
# pilot shards. Final evaluation reduced to 20 games per opponent: the
# pilot measures clocks and exercises the path, it compares nothing.
# Runs under nohup+caffeinate. DO NOT kill/restart without the human.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
echo "pilot start: $(date) pid $$"
for arm in grid graph; do
  echo "=== run pilot2-${arm}-s10 start: $(date) ==="
  if python3 scripts/run_comparison.py --arm "$arm" --seed 10 \
       --gens 2 --games 200 --threads 4 \
       --warm-start --window 3 --run-prefix pilot2 \
       --eval-at --final-per-opp 20; then
    echo "=== run pilot2-${arm}-s10 done: $(date) ==="
  else
    echo "=== run pilot2-${arm}-s10 FAILED ($?): $(date) ==="
  fi
done
echo "pilot complete: $(date)"
