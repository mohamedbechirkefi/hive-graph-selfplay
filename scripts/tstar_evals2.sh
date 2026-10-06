#!/usr/bin/env bash
# T* evals for the D-031 extension seeds (graph-s4 gen002, graph-s5
# gen005); waits for the extension queue (A1'-s3) to drain first.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
OPEN=results/comparison/openings-v1.txt
echo "tstar2 queued: $(date)"
while pgrep -f "bash scripts/extension_queue.sh" >/dev/null; do sleep 300; done
echo "tstar2 start: $(date)"
run_set () { # seed gen
  local seed=$1 gen=$2
  local run=data/runs/cmp-graph-s${seed}
  local net=${run}/checkpoints/gen${gen}-b1.onnx
  for name in B-RND B-HEU B-MCTS; do
    local rec=${run}/eval/tstar-gen${gen}-vs-${name}.csv
    [ -f "$rec" ] && continue
    local opp
    case $name in
      B-RND)  opp=(./target/release/hive-engine --random --seed 9101);;
      B-HEU)  opp=(./target/release/hive-engine);;
      B-MCTS) opp=(./target/release/hive-engine --mcts --sims 6400 --seed 9201);;
    esac
    HIVE_THREADS=1 ./target/release/hive-arena --games 100 --depth 1 \
      --seed 888000 --threads 4 --openings-file $OPEN \
      --records "$rec" --label "graph:s${seed}:tstar-gen${gen}:vs:${name}" \
      -- ./target/release/hive-engine --mcts --graph-net "$net" --sims 400 --seed 9500 \
      -- "${opp[@]}" > "${run}/eval/tstar-gen${gen}-vs-${name}.log" 2>&1
    echo "done graph-s${seed} gen${gen} vs ${name}: $(date)"
  done
}
run_set 4 002
run_set 5 005
echo "tstar2 complete: $(date)"
