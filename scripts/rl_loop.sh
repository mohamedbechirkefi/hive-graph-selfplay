#!/usr/bin/env bash
# AlphaZero-style reinforcement loop: self-play -> train -> export -> gate.
# Runs generations forever (Ctrl-C / kill to stop; state is on disk, so it
# resumes at the next generation). Requires a bootstrap model in models/
# (produced by scripts/overnight.sh) to seed generation 1.
#
#   ./scripts/rl_loop.sh                       # defaults below
#   GAMES_PER_GEN=3000 SIMS_FULL=600 ./scripts/rl_loop.sh
#
# Promotion rule: the freshly trained net must score >= GATE_THRESHOLD
# against the current best in a paired arena match, else the generation's
# games are kept but the old net keeps generating.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"

GAMES_PER_GEN="${GAMES_PER_GEN:-2000}"
SIMS_FULL="${SIMS_FULL:-600}"
SIMS_CHEAP="${SIMS_CHEAP:-150}"
THREADS="${THREADS:-8}"
EPOCHS="${EPOCHS:-2}"
GATE_GAMES="${GATE_GAMES:-60}"
GATE_THRESHOLD="${GATE_THRESHOLD:-0.55}"
GATE_MOVETIME="${GATE_MOVETIME:-2}"
GAMETYPE="${GAMETYPE:-Base}"
WINDOW_GENS="${WINDOW_GENS:-5}"   # train on the last N generations of data

mkdir -p data/rl models logs
PY=.venv/bin/python

# Seed: best model = latest bootstrap/promoted export.
if [ ! -f models/best-b1.onnx ]; then
    latest=$(ls -t models/*-b1.onnx 2>/dev/null | head -1)
    [ -n "$latest" ] || { echo "no bootstrap model in models/ — run scripts/overnight.sh first" >&2; exit 1; }
    cp "$latest" models/best-b1.onnx
    cp "${latest%-b1.onnx}-b128.onnx" models/best-b128.onnx 2>/dev/null || true
    # Track the checkpoint the best model came from (for --init).
    base=$(basename "${latest%-b1.onnx}")
    cp "python/checkpoints/${base}.pt" models/best.pt 2>/dev/null || true
    echo "seeded best model from $latest"
fi

# Detect latest completed generation from non-empty data files.
last_gen=$(ls -l data/rl/gen*-*.bin 2>/dev/null | awk '$5 > 0 {print $NF}' | sed 's/.*gen0*//; s/-.*//' | sort -n | tail -1)
gen=$(( ${last_gen:-0} + 1 ))

while true; do
    tag=$(printf 'gen%03d' "$gen")
    echo "[rl] === generation $gen ($tag) $(date '+%F %T') ==="

    echo "[rl] self-play: $GAMES_PER_GEN games, sims $SIMS_FULL/$SIMS_CHEAP"
    selfplay_net="models/best-b128.onnx"
    [ -f "$selfplay_net" ] || selfplay_net="models/best-b1.onnx"
    ./target/release/selfplay-mcts --net "$selfplay_net" \
        --games "$GAMES_PER_GEN" --threads "$THREADS" \
        --sims-full "$SIMS_FULL" --sims-cheap "$SIMS_CHEAP" \
        --gametype "$GAMETYPE" --seed "$gen" \
        --out "data/rl/$tag" > "logs/rl_${tag}_selfplay.log" 2>&1
    tail -1 "logs/rl_${tag}_selfplay.log"

    # Training window: last WINDOW_GENS generations (plus bootstrap data for
    # the first generations so the net doesn't forget basics early).
    data_args=""
    for p in $(ls data/rl/gen*-*.bin 2>/dev/null | sed 's/-[0-9]*\.bin$//' | sort -u | tail -"$WINDOW_GENS"); do
        data_args="$data_args ../${p}-*.bin"
    done
    if [ "$gen" -le 2 ] && ls data/selfplay/boot-000.bin >/dev/null 2>&1; then
        data_args="$data_args ../data/selfplay/boot-*.bin"
    fi
    echo "[rl] train ($EPOCHS epochs) on:$data_args"
    init_arg=""
    [ -f models/best.pt ] && init_arg="--init ../models/best.pt"
    (cd python && $PY -m hivenet.train --data $data_args \
        --out "checkpoints/$tag" --epochs "$EPOCHS" $init_arg) \
        > "logs/rl_${tag}_train.log" 2>&1
    grep "===" "logs/rl_${tag}_train.log" | tail -2
    last_ckpt=$(ls -t python/checkpoints/"$tag"/*.pt | head -1)

    echo "[rl] export ONNX"
    (cd python && $PY -m hivenet.export_onnx "../$last_ckpt" --out ../models --batches 1 128) \
        > "logs/rl_${tag}_export.log" 2>&1
    new_b1="models/$(basename "${last_ckpt%.pt}")-b1.onnx"

    echo "[rl] gating: $GATE_GAMES games @ ${GATE_MOVETIME}s/move vs current best"
    ./target/release/hive-arena --games "$GATE_GAMES" --movetime "$GATE_MOVETIME" \
        --threads 2 --gametype "$GAMETYPE" --seed "$((gen * 7))" \
        -- ./target/release/hive-engine --mcts --net "$new_b1" \
        -- ./target/release/hive-engine --mcts --net models/best-b1.onnx \
        > "logs/rl_${tag}_gate.log" 2>&1 || true
    score=$(grep -o 'score [0-9.]*%' "logs/rl_${tag}_gate.log" | tail -1 | grep -o '[0-9.]*')
    echo "[rl] gate score: ${score:-?}%"

    if [ -n "${score:-}" ] && awk -v s="$score" -v t="$GATE_THRESHOLD" 'BEGIN{exit !(s/100 >= t)}'; then
        echo "[rl] PROMOTED: $new_b1 -> models/best"
        cp "$new_b1" models/best-b1.onnx
        cp "${new_b1%-b1.onnx}-b128.onnx" models/best-b128.onnx 2>/dev/null || true
        cp "$last_ckpt" models/best.pt
    else
        echo "[rl] not promoted; best model unchanged"
    fi
    gen=$((gen + 1))
done
