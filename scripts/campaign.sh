#!/usr/bin/env bash
# H6 full campaign (D-026, G-SPEND approved 2026-09-10): 2 arms x 3 seeds,
# 10 generations x 500 games each, sequential. Resumable: re-running skips
# completed generations. Runs under nohup+caffeinate so it survives the
# session and the machine stays awake. DO NOT kill/restart without the
# human (G-SPEND / G-DESTRUCTIVE).
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
echo "campaign start: $(date) pid $$"
for spec in grid:1 graph:1 grid:2 graph:2 grid:3 graph:3; do
  arm="${spec%%:*}"; seed="${spec##*:}"
  echo "=== run cmp-${arm}-s${seed} start: $(date) ==="
  if python3 scripts/run_comparison.py --arm "$arm" --seed "$seed" \
       --gens 10 --games 500 --threads 4; then
    echo "=== run cmp-${arm}-s${seed} done: $(date) ==="
  else
    echo "=== run cmp-${arm}-s${seed} FAILED ($?): $(date) — continuing to next run ==="
  fi
done
echo "campaign complete: $(date)"
