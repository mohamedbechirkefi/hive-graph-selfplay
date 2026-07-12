#!/usr/bin/env bash
# Nightly deep validation: perft depth 7 for all 8 game types (parallel) and
# large-scale differential fuzzing against both reference engines.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"

cargo build --release

echo "=== deep perft (depth 7, expected values in tests/perft_fixtures.json) ==="
for gt in Base Base+M Base+L Base+P Base+ML Base+MP Base+LP Base+MLP; do
    ./target/release/perft "$gt" 7 | tail -1
done

echo "=== differential fuzz: 200 games/type vs nokamute ==="
./target/release/fuzz ./opponents/nokamute uhp -- 200 "$(date +%s)"

echo "=== differential fuzz: 100 games/type vs Mzinga ==="
./target/release/fuzz ./opponents/MzingaEngine -- 100 "$(date +%s)"

echo "nightly validation complete"
