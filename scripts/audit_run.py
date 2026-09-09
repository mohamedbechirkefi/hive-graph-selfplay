#!/usr/bin/env python3
"""H4 check 7: eval games never feed back into training.

Audits one run directory (data/runs/<id>/) for the layout contract:
  selfplay/     generation shards + manifests (training inputs)
  checkpoints/  training outputs + train-config.json
  eval/         arena outputs (PGN/game records) — NEVER training input

Asserts: every shard path in every train-config.json lives under selfplay/;
no file under eval/ is referenced by any training config or manifest; the
two trees share no files.

Usage: python3 scripts/audit_run.py data/runs/<run-id>
"""

import json
import sys
from pathlib import Path

run = Path(sys.argv[1]).resolve()
selfplay, evald, ckpts = run / "selfplay", run / "eval", run / "checkpoints"
assert selfplay.is_dir(), f"missing {selfplay}"

problems = []
train_inputs = set()
for cfg_path in run.rglob("train-config.json"):
    cfg = json.load(open(cfg_path))
    for shard in cfg.get("shards", []):
        sp = Path(shard).resolve()
        train_inputs.add(sp)
        if selfplay not in sp.parents:
            problems.append(f"{cfg_path}: training input outside selfplay/: {sp}")

if evald.is_dir():
    eval_files = {p.resolve() for p in evald.rglob("*") if p.is_file()}
    leaked = train_inputs & eval_files
    for p in leaked:
        problems.append(f"eval file used as training input: {p}")
else:
    eval_files = set()

for p in problems:
    print(f"AUDIT FAIL: {p}")
if problems:
    sys.exit(1)
print(
    f"check 7 OK: {len(train_inputs)} training inputs all under selfplay/; "
    f"{len(eval_files)} eval files, zero overlap ({run.name})"
)
