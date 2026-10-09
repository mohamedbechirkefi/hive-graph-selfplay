#!/usr/bin/env bash
# W6 fresh-environment minimal reproduction scenario (plan ch. 28):
# from a CLEAN CLONE of the repository plus the shipped results records,
# (1) rebuild the engine, (2) deterministically replay one recorded
# evaluation game and verify it matches its shipped CSV row,
# (3) regenerate the comparison tables from raw records and verify they
# match the shipped tables byte-for-byte (stdlib python only).
# Usage: scripts/reproduce_minimal.sh <workdir>
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${1:?workdir}"
export PATH="$HOME/.cargo/bin:$PATH"

echo "== 1. fresh clone + build =="
git clone -q "$SRC" "$WORK/clone"
cd "$WORK/clone"
cargo build --release -p hive-engine -p hive-arena -q 2>&1 | tail -1 || true
test -x target/release/hive-engine

echo "== 2. ship the records (as the release manifest would) =="
mkdir -p results data/runs/cmp-grid-s2/eval data/runs/cmp-grid-s2/checkpoints
cp -R "$SRC/results/comparison" results/
cp "$SRC"/data/runs/cmp-*/eval/gen009-vs-*.csv data/runs/ 2>/dev/null || true
# full per-run record layout for the table regeneration:
for d in "$SRC"/data/runs/cmp-gr*-s[12345]; do
  base=$(basename "$d")
  mkdir -p "data/runs/$base"
  cp -R "$d/eval" "data/runs/$base/"
  cp "$d/wallclock.json" "data/runs/$base/"
done
cp "$SRC/data/runs/cmp-grid-s2/checkpoints/gen009-b1.onnx" data/runs/cmp-grid-s2/checkpoints/

echo "== 3. replay one recorded game deterministically (fig4-F2) =="
# grid-s2 vs B-HEU, opening 2, A black, 19 plies, score_a 0, outcome row
# from the shipped CSV must be reproduced exactly.
grep -v "^#" results/comparison/openings-v1.txt | sed -n '3p' > /tmp/repro-opening.txt
HIVE_THREADS=1 ./target/release/hive-arena --games 2 --depth 1 --seed 1 --threads 1 \
  --openings-file /tmp/repro-opening.txt --records /tmp/repro.csv \
  -- ./target/release/hive-engine --mcts --net data/runs/cmp-grid-s2/checkpoints/gen009-b1.onnx --sims 400 --seed 9009 \
  -- ./target/release/hive-engine > /dev/null 2>&1
python3 - <<'PY'
import csv
rows = [r for r in csv.DictReader(l for l in open("/tmp/repro.csv") if not l.startswith("#"))]
rb = [r for r in rows if r["a_is_white"] == "0"][0]
shipped = [r for r in csv.DictReader(l for l in open("data/runs/cmp-grid-s2/eval/gen009-vs-B-HEU.csv") if not l.startswith("#"))
           if r["opening_id"] == "2" and r["a_is_white"] == "0"][0]
assert (rb["score_a"], rb["truncated"], rb["plies"]) == (shipped["score_a"], shipped["truncated"], shipped["plies"]), (rb, shipped)
print(f"  replay matches shipped row: plies {rb['plies']}, score {rb['score_a']}, outcome {rb['outcome']}")
PY

echo "== 4. regenerate tables from raw records; byte-compare =="
python3 scripts/make_results.py > /dev/null
for f in results-same-examples.md results-same-wallclock.md; do
  cmp "results/comparison/$f" "$SRC/results/comparison/$f" && echo "  $f: BYTE-IDENTICAL"
done

echo "MINIMAL REPRODUCTION: PASS"
