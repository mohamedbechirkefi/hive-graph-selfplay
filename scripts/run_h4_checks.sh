#!/usr/bin/env bash
# H4 pre-training checks, one command (pipeline H4 tasks 3-9).
# Usage: scripts/run_h4_checks.sh <shard-glob> <manifest.json> [run-dir]
# Checks 1-3 + stamp: hivenet.checks (python, real forward pass)
# Check 2 (id<->move): hive-nn Rust round-trip test
# Check 3 (terminal signs): hive-search/hive-mcts sign batteries
# Check 5 (save/resume): scripts/check5_resume.py
# Check 6 (no eval noise): hive-mcts eval_defaults test + configs/eval-settings.toml
# Check 7 (eval never fed back): scripts/audit_run.py (needs run-dir)
# Check 4 (tiny-batch overfit) is an experiment, journaled separately.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.cargo/bin:$PATH"
SHARDS="${1:?shard glob}"
MANIFEST="${2:?manifest.json}"
RUN_DIR="${3:-}"

echo "=== Rust battery (checks 2, 3, 6) ==="
cargo test --release -p hive-nn -p hive-mcts -p hive-search -p hive-eval

echo "=== data/model battery (checks 1-3 + stamp) ==="
(cd python && PYTHONPATH=. .venv/bin/python -m hivenet.checks "$SHARDS" --manifest "$MANIFEST")

echo "=== check 5 (save/resume) ==="
python3 scripts/check5_resume.py "$SHARDS"

if [ -n "$RUN_DIR" ]; then
  echo "=== check 7 (eval/training separation) ==="
  python3 scripts/audit_run.py "$RUN_DIR"
fi

echo "ALL H4 CHECKS PASSED"
