#!/usr/bin/env bash
# H7 ablation campaign (D-029, G-SPEND approved 2026-09-20): A1 + A2,
# 3 seeds each, budget parity with the H6 graph runs. Resumable; do not
# kill/restart without the human (G-SPEND / G-DESTRUCTIVE).
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
echo "ablation campaign start: $(date) pid $$"
for spec in graph-untyped:1 graph-untyped:2 graph-untyped:3 graph-nogpool:1 graph-nogpool:2 graph-nogpool:3; do
  arm="${spec%%:*}"; seed="${spec##*:}"
  echo "=== run cmp-${arm}-s${seed} start: $(date) ==="
  if python3 scripts/run_comparison.py --arm "$arm" --seed "$seed" \
       --gens 10 --games 500 --threads 4; then
    echo "=== run cmp-${arm}-s${seed} done: $(date) ==="
  else
    echo "=== run cmp-${arm}-s${seed} FAILED ($?): $(date) — continuing ==="
  fi
done
echo "ablation campaign complete: $(date)"
