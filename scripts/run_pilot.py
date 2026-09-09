#!/usr/bin/env python3
"""H4 small-budget pilot: the complete loop, deliberately tiny (task 10).

self-play (stamped v3 records) -> checks -> train (masked policy, D-008
value handling) -> export -> independent eval vs the D-017 frozen
population under configs/eval-settings.toml -> audit.

Run layout (check 7): data/runs/<id>/{selfplay,checkpoints,eval}.

Usage: python3 scripts/run_pilot.py --run pilot0 [--games 300] [--gens 1]
"""

import argparse
import os
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ENGINE = "./target/release/hive-engine"

# Pinned eval settings (configs/eval-settings.toml, D-019).
EVAL_SIMS = 400
EVAL_GAMES = 30
FROZEN_OPPONENTS = {
    "B-RND": [ENGINE, "--random", "--seed", "9101"],
    "B-HEU": [ENGINE],
    "B-MCTS": [ENGINE, "--mcts", "--sims", "6400", "--seed", "9201"],
}


def sh(cmd, cwd=REPO, extra_env=None):
    print(f"+ {' '.join(map(str, cmd))}", flush=True)
    env = {**os.environ, **(extra_env or {})}
    subprocess.run([str(c) for c in cmd], check=True, cwd=cwd, env=env)


def pysh(cmd):
    sh(cmd, cwd=REPO / "python", extra_env={"PYTHONPATH": "."})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", default="pilot0")
    ap.add_argument("--games", type=int, default=300)
    ap.add_argument("--gens", type=int, default=1)
    ap.add_argument("--sims-full", type=int, default=128)
    ap.add_argument("--sims-cheap", type=int, default=32)
    ap.add_argument("--epochs", type=int, default=3)
    ap.add_argument("--channels", type=int, default=96)
    ap.add_argument("--blocks", type=int, default=8)
    ap.add_argument("--seed", type=int, default=20260909)
    ap.add_argument("--threads", type=int, default=4)
    args = ap.parse_args()

    run = REPO / "data" / "runs" / args.run
    for d in ("selfplay", "checkpoints", "eval"):
        (run / d).mkdir(parents=True, exist_ok=True)

    py = ".venv/bin/python"
    models = run / "checkpoints"

    # Gen 0 starts from a seeded random-init export.
    pysh([py, "-m", "hivenet.export_onnx", "random", "--out", models,
          "--channels", args.channels, "--blocks", args.blocks, "--seed", args.seed])
    net_b1 = models / f"hivenet-random-c{args.channels}b{args.blocks}s{args.seed}-b1.onnx"

    for gen in range(args.gens):
        tag = f"gen{gen:03d}"
        out = run / "selfplay" / tag
        sh(["./target/release/selfplay-mcts", "--net", net_b1,
            "--games", args.games, "--threads", args.threads,
            "--sims-full", args.sims_full, "--sims-cheap", args.sims_cheap,
            "--seed", args.seed + gen, "--model-gen", gen, "--out", out])

        shard_glob = f"{out}-*.bin"
        sh(["bash", "scripts/run_h4_checks.sh", shard_glob, f"{out}-manifest.json"])

        pysh([py, "-m", "hivenet.train", "--data", shard_glob,
              "--out", run / "checkpoints" / tag,
              "--epochs", args.epochs, "--channels", args.channels,
              "--blocks", args.blocks, "--seed", args.seed + gen, "--workers", 0])

        ckpt = run / "checkpoints" / tag / f"hivenet-e{args.epochs - 1}.pt"
        pysh([py, "-m", "hivenet.export_onnx", ckpt, "--out", models,
              "--batches", "1", "128"])
        net_b1 = models / f"hivenet-e{args.epochs - 1}-b1.onnx"

        # Independent eval vs the frozen population (D-017), pinned settings.
        us = [ENGINE, "--mcts", "--net", net_b1, "--sims", EVAL_SIMS,
              "--seed", 9000 + gen]
        for name, opp in FROZEN_OPPONENTS.items():
            log = run / "eval" / f"{tag}-vs-{name}.txt"
            pgn = run / "eval" / f"{tag}-vs-{name}.pgn"
            cmd = ["./target/release/hive-arena", "--games", EVAL_GAMES,
                   "--depth", "1", "--seed", args.seed + 500 + gen,
                   "--threads", args.threads, "--pgn", pgn,
                   "--", *us, "--", *opp]
            print(f"+ {' '.join(map(str, cmd))} > {log}", flush=True)
            with open(log, "w") as f:
                subprocess.run([str(c) for c in cmd], check=True, cwd=REPO,
                               stdout=f, stderr=subprocess.STDOUT,
                               env={**os.environ, "HIVE_THREADS": "1"})
            print(Path(log).read_text().strip().splitlines()[-4:], flush=True)

    sh(["python3", "scripts/audit_run.py", run])
    print(f"pilot complete: {run}")


if __name__ == "__main__":
    main()
