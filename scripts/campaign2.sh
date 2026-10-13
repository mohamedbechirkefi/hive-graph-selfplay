#!/usr/bin/env bash
# H9 Study 2 campaign (protocol v2, FROZEN 2026-10-13, D-038). Launch
# ONLY under a G-SPEND approval recorded in state/decisions.md.
# 2 arms x 5 seeds (11-15), 10 generations x 500 games, warm start +
# replay window W=3, sequential, interleaved grid/graph as Study 1 so a
# stop leaves both arms with equal seed counts. Resumable: re-running
# skips completed generations. Runs under nohup+caffeinate so it
# survives the session and the machine stays awake. DO NOT kill/restart
# without the human (G-SPEND / G-DESTRUCTIVE).
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
echo "campaign2 start: $(date) pid $$"
for spec in grid:11 graph:11 grid:12 graph:12 grid:13 graph:13 grid:14 graph:14 grid:15 graph:15; do
  arm="${spec%%:*}"; seed="${spec##*:}"
  echo "=== run cmp2-${arm}-s${seed} start: $(date) ==="
  if python3 scripts/run_comparison.py --arm "$arm" --seed "$seed" \
       --gens 10 --games 500 --threads 4 \
       --warm-start --window 3 --run-prefix cmp2; then
    echo "=== run cmp2-${arm}-s${seed} done: $(date) ==="
  else
    echo "=== run cmp2-${arm}-s${seed} FAILED ($?): $(date) - continuing to next run ==="
  fi
done
echo "campaign2 complete: $(date)"
