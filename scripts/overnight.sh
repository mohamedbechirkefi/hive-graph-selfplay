#!/usr/bin/env bash
# Fully unattended overnight pipeline: strength gauntlets -> 60k-game
# bootstrap dataset -> supervised training -> ONNX export.
#
# Designed to run detached (nohup, wrapped in caffeinate) so it survives the
# editor/session. Progress and results land in logs/.
set -u
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
mkdir -p logs data/selfplay

step() { echo "[overnight] $(date '+%F %T') $*"; }

step "START"
pkill -f hive-arena 2>/dev/null; pkill -f "nokamute uhp" 2>/dev/null; sleep 2

step "gauntlet 1: 24 games @ 1s/move vs nokamute (regression check)"
HIVE_THREADS=5 ./target/release/hive-arena --games 24 --movetime 1 --threads 2 --seed 77 \
    -- ./target/release/hive-engine -- ./opponents/nokamute uhp \
    > logs/gauntlet_1s.log 2>&1
tail -3 logs/gauntlet_1s.log

step "gauntlet 2: 48 games @ 5s/move vs nokamute"
HIVE_THREADS=5 ./target/release/hive-arena --games 48 --movetime 5 --threads 2 --seed 888 \
    --pgn logs/gauntlet_5s_games.txt \
    -- ./target/release/hive-engine -- ./opponents/nokamute uhp \
    > logs/gauntlet_5s.log 2>&1
tail -3 logs/gauntlet_5s.log

step "bootstrap datagen: 60k games depth 5"
./target/release/selfplay --games 60000 --depth 5 --threads 10 --seed 4242 \
    --out data/selfplay/boot > logs/datagen.log 2>&1
tail -1 logs/datagen.log

step "training: 4 epochs on bootstrap data (MPS)"
(cd python && .venv/bin/python -m hivenet.train \
    --data '../data/selfplay/boot-*.bin' --out checkpoints --epochs 4 --workers 6) \
    > logs/train.log 2>&1
grep "===" logs/train.log | tail -4

step "ONNX export + inference smoke"
(cd python && .venv/bin/python -m hivenet.export_onnx checkpoints/hivenet-e3.pt --out ../models) \
    > logs/export.log 2>&1
tail -2 logs/export.log

step "DONE — results: logs/gauntlet_*.log, logs/train.log, models/*.onnx"
