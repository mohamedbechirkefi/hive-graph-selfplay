#!/usr/bin/env bash
# Build the records archive that accompanies a public release (D-035):
# evaluation records, per-generation clock files, self-play manifests and
# the final + cutoff checkpoints of every run, without the self-play
# shards (7.6 GB) or the intermediate checkpoints. Local only; attaching
# the archive to a release is a G-PUBLIC decision.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$REPO/release"
NAME="hive-graph-selfplay-records-v2.0"
STAGE="$OUT/$NAME"
rm -rf "$STAGE"; mkdir -p "$STAGE"

# cutoff (T*) checkpoints per run, from the final 5-seed analysis
# (bash 3.2 on macOS: no associative arrays)
cutoff_of() {
  case "$1" in
    cmp-grid-s3) echo gen008 ;;
    cmp-graph-s1) echo gen003 ;;
    cmp-graph-s2) echo gen004 ;;
    cmp-graph-s3) echo gen004 ;;
    cmp-graph-s4) echo gen002 ;;
    cmp-graph-s5) echo gen005 ;;
    *) echo gen009 ;;
  esac
}

for run in "$REPO"/data/runs/cmp-*; do
  r="$(basename "$run")"
  dst="$STAGE/data/runs/$r"
  mkdir -p "$dst/eval" "$dst/selfplay" "$dst/checkpoints"
  cp "$run"/eval/*.csv "$run"/eval/*.log "$dst/eval/" 2>/dev/null || true
  cp "$run"/wallclock.json "$dst/" 2>/dev/null || true
  cp "$run"/selfplay/*-manifest.json "$dst/selfplay/" 2>/dev/null || true
  # final checkpoint (gen009) and the cutoff checkpoint when different
  cp "$run"/checkpoints/gen009-b1.onnx "$dst/checkpoints/" 2>/dev/null || true
  c="$(cutoff_of "$r")"
  if [ "$c" != "gen009" ]; then
    cp "$run"/checkpoints/"$c"-b1.onnx "$dst/checkpoints/" 2>/dev/null || true
  fi
  cp "$run"/checkpoints/gen009/train-config.json "$dst/checkpoints/train-config-gen009.json" 2>/dev/null || true
done
cp -R "$REPO/results" "$STAGE/results"
cp "$REPO/data/runs"/*.log "$STAGE/data/runs/" 2>/dev/null || true
cat > "$STAGE/README.md" <<EOF
# Records archive — Grid vs. Graph Representations for Self-Play Learning in Hive (v2.0)

Contents: per-run evaluation records (\`eval/*.csv\`, one row per game,
engine command lines in the header), per-generation clock files
(\`wallclock.json\`), self-play manifests, the final checkpoint of each
run (\`gen009-b1.onnx\`) and the equal-time cutoff checkpoint where it
differs, the generated result tables (\`results/\`), and the campaign
logs. Self-play shards and intermediate checkpoints are not included.
Regenerate every table with \`python3 scripts/make_results.py\` from the
repository after placing \`data/runs/\` from this archive at the
repository root. Produced $(date -u +%Y-%m-%dT%H:%MZ).
EOF
tar -C "$OUT" -czf "$OUT/$NAME.tar.gz" "$NAME"
du -sh "$OUT/$NAME.tar.gz" "$STAGE"
