#!/usr/bin/env bash
# D-031 (5-seed extension) then D-030 (A1'), queued after ablations.sh.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
echo "extension queue start: $(date); waiting for ablations.sh"
while pgrep -f "bash scripts/ablations.sh" >/dev/null; do sleep 300; done
for spec in grid:4 graph:4 grid:5 graph:5; do
  arm="${spec%%:*}"; seed="${spec##*:}"
  echo "=== run cmp-${arm}-s${seed} start: $(date) ==="
  python3 scripts/run_comparison.py --arm "$arm" --seed "$seed" \
    --gens 10 --games 500 --threads 4 \
    && echo "=== run cmp-${arm}-s${seed} done: $(date) ===" \
    || echo "=== run cmp-${arm}-s${seed} FAILED ($?): $(date) — continuing ==="
done
for seed in 1 2 3; do
  echo "=== run cmp-graph-untyped-clip-s${seed} start: $(date) ==="
  python3 scripts/run_comparison.py --arm graph-untyped-clip --seed "$seed" \
    --gens 10 --games 500 --threads 4 \
    && echo "=== run cmp-graph-untyped-clip-s${seed} done: $(date) ===" \
    || echo "=== run cmp-graph-untyped-clip-s${seed} FAILED ($?): $(date) — continuing ==="
done
echo "extension queue complete: $(date)"
