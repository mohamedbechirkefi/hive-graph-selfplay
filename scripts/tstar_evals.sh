#!/usr/bin/env bash
# Same-wall-clock (T* = 18.77 h, journal H6-2026-09-16-progress-01)
# checkpoint evaluations — part of the D-026-approved campaign.
# grid-s1/s2's T* checkpoint == gen009 (finals reused; not re-run).
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
OPEN=results/comparison/openings-v1.txt
run_set () { # arm seed gen netflag
  local arm=$1 seed=$2 gen=$3 netflag=$4
  local run=data/runs/cmp-${arm}-s${seed}
  local net=${run}/checkpoints/gen${gen}-b1.onnx
  for spec in "B-RND:--random --seed 9101" "B-HEU:" "B-MCTS:--mcts --sims 6400 --seed 9201"; do
    local name="${spec%%:*}" flags="${spec#*:}"
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
      --records "$rec" --label "${arm}:s${seed}:tstar-gen${gen}:vs:${name}" \
      -- ./target/release/hive-engine --mcts $netflag "$net" --sims 400 --seed 9500 \
      -- "${opp[@]}" > "${run}/eval/tstar-gen${gen}-vs-${name}.log" 2>&1
    echo "done ${arm}-s${seed} gen${gen} vs ${name}: $(date)"
  done
}
echo "T* evals start: $(date)"
run_set grid  3 008 --net
run_set graph 1 003 --graph-net
run_set graph 2 004 --graph-net
run_set graph 3 004 --graph-net
echo "T* evals complete: $(date)"
