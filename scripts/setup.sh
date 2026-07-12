#!/usr/bin/env bash
# One-shot machine bootstrap: run this after cloning to set up EVERYTHING —
# toolchain, build, tests, reference engines, Python env — and optionally
# kick off the unattended training pipeline.
#
#   ./scripts/setup.sh              # set up + validate
#   ./scripts/setup.sh --overnight  # ...then launch scripts/overnight.sh
#                                   # (gauntlets -> 60k-game dataset ->
#                                   #  training -> ONNX export, ~12-14h)
#
# Idempotent: safe to re-run; finished steps are skipped.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n\033[1m=== %s\033[0m\n' "$*"; }

step "1/6 Rust toolchain"
if ! command -v cargo >/dev/null && [ ! -x "$HOME/.cargo/bin/cargo" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain stable --profile minimal
fi
export PATH="$HOME/.cargo/bin:$PATH"
rustc --version

step "2/6 Build (release)"
cargo build --release

step "3/6 Test suite (validates the rules engine on this machine)"
cargo test --release

step "4/6 Reference engines (Mzinga + nokamute)"
./scripts/fetch_opponents.sh

step "5/6 UHP conformance check"
if ./opponents/nokamute uhp-debug ./target/release/hive-engine | grep -q FAILED; then
    echo "FATAL: uhp-debug reported failures" >&2
    exit 1
fi
echo "uhp-debug: all tests passed"

step "6/6 Python training environment"
if [ ! -x python/.venv/bin/python ]; then
    python3 -m venv python/.venv
fi
python/.venv/bin/pip install --quiet --upgrade pip
python/.venv/bin/pip install --quiet -r python/requirements.txt
python/.venv/bin/python python/hivenet/model.py

step "Setup complete"
echo "Engine binary:  ./target/release/hive-engine   (UHP on stdin/stdout)"
echo "Quick gauntlet: HIVE_THREADS=6 ./target/release/hive-arena --games 10 --movetime 1 --threads 2 \\"
echo "                  -- ./target/release/hive-engine -- ./opponents/nokamute uhp"
echo "Docs:           CLAUDE.md (workflow), docs/PLAN.md (roadmap + remaining work)"

if [ "${1:-}" = "--overnight" ]; then
    step "Launching unattended pipeline (detached; ~12-14h)"
    mkdir -p logs
    nohup caffeinate -is bash scripts/overnight.sh >> logs/overnight.log 2>&1 &
    disown
    echo "PID $! — follow with: tail -f logs/overnight.log"
    echo "Keep the Mac plugged in. For closed-lid running: sudo pmset -a disablesleep 1"
    echo "(revert next morning with: sudo pmset -a disablesleep 0)"
fi
