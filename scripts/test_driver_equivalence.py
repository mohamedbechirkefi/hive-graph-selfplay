#!/usr/bin/env python3
"""H9 task 1 regression test: the campaign driver with default options
must reproduce Study 1's command lines exactly, and the Study-2 options
(--warm-start, --window W) must change only what they claim to change.

Evidence used: the recorded run artifacts of Study 1 under data/runs/
(train-config.json per generation: data globs, seed, epochs, init;
selfplay manifests: seed, games, sims, model_gen). The driver is run in
--dry-run mode (no file is written, no process is started).

Usage: python3 scripts/test_driver_equivalence.py   (exit 0 = PASS)
"""

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DRIVER = REPO / "scripts" / "run_comparison.py"
GENS = 10


def dry_run(arm, seed, extra=()):
    out = subprocess.run([sys.executable, str(DRIVER), "--arm", arm, "--seed", str(seed),
                          "--gens", str(GENS), "--games", "500", "--dry-run", *extra],
                         capture_output=True, text=True, check=True, cwd=REPO).stdout
    return [l[2:] for l in out.splitlines() if l.startswith("+ ")]


def parse(cmd):
    """Return (program, {flag: [values...]}) for a printed command line."""
    toks = cmd.split()
    prog = toks[0] if not toks[0].endswith("python") else " ".join(toks[:3])
    flags, cur = {}, None
    for t in toks[1:]:
        if t.startswith("--"):
            cur = t
            flags.setdefault(cur, [])
        elif cur is not None:
            flags[cur].append(t)
    return prog, flags


def check_study1(arm, seed):
    """Driver defaults vs the recorded artifacts of Study 1 run cmp-<arm>-s<seed>."""
    run = REPO / "data" / "runs" / f"cmp-{arm}-s{seed}"
    cmds = dry_run(arm, seed)
    train_cmds = [c for c in cmds if ("hivenet.train " in c or c.endswith("hivenet.train")
                                      or "hivenet.train_graph" in c)]
    sp_cmds = [c for c in cmds if "selfplay-mcts" in c]
    assert len(train_cmds) == GENS and len(sp_cmds) == GENS, (len(train_cmds), len(sp_cmds))
    errors = []
    for g in range(GENS):
        tag = f"gen{g:03d}"
        cfg = json.loads((run / "checkpoints" / tag / "train-config.json").read_text())
        man = json.loads((run / "selfplay" / f"{tag}-manifest.json").read_text())
        _, tf = parse(train_cmds[g])
        _, sf = parse(sp_cmds[g])
        # training: same data globs (as recorded), seed, epochs, no init
        if tf["--data"] != cfg["data"]:
            errors.append(f"{arm}-s{seed} {tag}: data {tf['--data']} != {cfg['data']}")
        if int(tf["--seed"][0]) != cfg["seed"]:
            errors.append(f"{arm}-s{seed} {tag}: seed {tf['--seed']} != {cfg['seed']}")
        if int(tf["--epochs"][0]) != cfg["epochs"]:
            errors.append(f"{arm}-s{seed} {tag}: epochs differ")
        if "--init" in tf or cfg.get("init") is not None:
            errors.append(f"{arm}-s{seed} {tag}: init present (Study 1 must have none)")
        # self-play: seed, games, simulation budgets, model generation
        if int(sf["--seed"][0]) != man["seed"] or int(sf["--games"][0]) != man["games"] \
                or int(sf["--sims-full"][0]) != man["sims_full"] \
                or int(sf["--sims-cheap"][0]) != man["sims_cheap"] \
                or int(sf["--model-gen"][0]) != man["model_gen"]:
            errors.append(f"{arm}-s{seed} {tag}: self-play settings differ from manifest")
    return errors


def check_study2(arm, seed, window):
    cmds = dry_run(arm, seed, ["--warm-start", "--window", str(window), "--run-prefix", "cmp2"])
    base = dry_run(arm, seed)
    train2 = [c for c in cmds if "hivenet.train" in c]
    train1 = [c for c in base if "hivenet.train" in c]
    sp2 = [c for c in cmds if "selfplay-mcts" in c]
    sp1 = [c for c in base if "selfplay-mcts" in c]
    errors = []
    for g in range(GENS):
        _, f2 = parse(train2[g])
        _, f1 = parse(train1[g])
        want = [f"{REPO}/data/runs/cmp2-{arm}-s{seed}/selfplay/gen{k:03d}-*.bin"
                for k in range(max(0, g - window + 1), g + 1)]
        if f2["--data"] != want:
            errors.append(f"study2 {arm} gen{g}: window globs {f2['--data']} != {want}")
        if g == 0 and "--init" in f2:
            errors.append("study2 gen0 must not warm-start")
        if g > 0:
            prev = f"gen{g-1:03d}"
            if "--init" not in f2 or prev not in f2["--init"][0]:
                errors.append(f"study2 {arm} gen{g}: init should point to {prev}")
        # everything else identical to Study 1 up to the run directory
        norm = lambda d: {k: [v.replace("cmp2-", "cmp-") for v in vs] for k, vs in d.items()
                          if k not in ("--data", "--init")}
        if norm(f2) != norm(f1):
            errors.append(f"study2 {arm} gen{g}: training flags differ beyond data/init")
        s2 = sp2[g].replace("cmp2-", "cmp-")
        if s2 != sp1[g]:
            errors.append(f"study2 {arm} gen{g}: self-play command differs")
    return errors


def main():
    errors = []
    for arm, seed in (("grid", 1), ("graph", 1), ("grid", 4), ("graph", 5)):
        errors += check_study1(arm, seed)
    for arm in ("grid", "graph"):
        errors += check_study2(arm, 1, 3)
    if errors:
        print("\n".join(errors[:20]))
        print(f"FAIL: {len(errors)} mismatch(es)")
        return 1
    print("PASS: driver defaults reproduce Study 1 (4 runs x 10 generations, training "
          "configs and self-play manifests); --warm-start/--window change only the data "
          "window and the initialisation checkpoint.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
