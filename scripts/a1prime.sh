#!/usr/bin/env bash
# Supplementary A1' (D-030): waits for the running A2 campaign to finish,
# then runs graph-untyped-clip seeds 1-3. Two-component diff — see
# configs/ablations/A1prime-edge-typing-clipped.md. G-SPEND-gated.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
echo "a1prime queued: $(date); waiting for ablations.sh to finish"
while pgrep -f "bash scripts/ablations.sh" >/dev/null; do sleep 300; done
echo "a1prime start: $(date)"
for seed in 1 2 3; do
  echo "=== run cmp-graph-untyped-clip-s${seed} start: $(date) ==="
  if python3 scripts/run_comparison.py --arm graph-untyped-clip --seed "$seed" \
       --gens 10 --games 500 --threads 4; then
    echo "=== run cmp-graph-untyped-clip-s${seed} done: $(date) ==="
  else
    echo "=== run cmp-graph-untyped-clip-s${seed} FAILED ($?): $(date) — continuing ==="
  fi
done
echo "a1prime complete: $(date)"
