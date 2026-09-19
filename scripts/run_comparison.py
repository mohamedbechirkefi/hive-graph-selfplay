#!/usr/bin/env python3
"""H6 campaign driver — runs ONE (arm, seed) training run of the frozen
comparison matrix, resumably. LAUNCHING IT IS G-SPEND: do not start
without the human's approval recorded in state/decisions.md.

Per generation: self-play (frozen 128/32, v3 records, model-stamped) ->
train (identical conventions both arms) -> export -> wall-clock log ->
optional intermediate eval vs the frozen population on the FROZEN
openings. Checkpoints are kept every generation so the same-wall-clock
reading can pick the checkpoint at T* later. A free-disk guard halts
cleanly before StorageFull. Re-running skips completed generations.

Usage:
  python3 scripts/run_comparison.py --arm grid  --seed 1 [--gens 10] [--games 500]
  python3 scripts/run_comparison.py --arm graph --seed 1 ...
"""

import argparse
import json
import os
import shutil
import subprocess
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OPENINGS = REPO / "results" / "comparison" / "openings-v1.txt"
EVAL_SIMS = 400  # pinned, D-019
OPPONENTS = {
    "B-RND": ["./target/release/hive-engine", "--random", "--seed", "9101"],
    "B-HEU": ["./target/release/hive-engine"],
    "B-MCTS": ["./target/release/hive-engine", "--mcts", "--sims", "6400", "--seed", "9201"],
}
MIN_FREE_GB = 20


def sh(cmd, cwd=REPO, env_extra=None, log=None):
    print(f"+ {' '.join(map(str, cmd))}", flush=True)
    env = {**os.environ, **(env_extra or {})}
    if log:
        with open(log, "w") as f:
            subprocess.run([str(c) for c in cmd], check=True, cwd=cwd, env=env,
                           stdout=f, stderr=subprocess.STDOUT)
    else:
        subprocess.run([str(c) for c in cmd], check=True, cwd=cwd, env=env)


def free_gb() -> float:
    return shutil.disk_usage(REPO).free / 1e9


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--arm", required=True,
                    choices=["grid", "graph", "graph-untyped", "graph-nogpool"])
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--gens", type=int, default=10)
    ap.add_argument("--games", type=int, default=500)
    ap.add_argument("--epochs", type=int, default=2)
    ap.add_argument("--threads", type=int, default=4)
    ap.add_argument("--eval-at", type=int, nargs="*", default=[4, 7])
    ap.add_argument("--eval-games", type=int, default=60)  # 20/opponent
    ap.add_argument("--final-per-opp", type=int, default=100)  # task-4 pilot volume
    args = ap.parse_args()

    assert OPENINGS.exists(), "frozen openings file missing"
    run = REPO / "data" / "runs" / f"cmp-{args.arm}-s{args.seed}"
    for d in ("selfplay", "checkpoints", "eval"):
        (run / d).mkdir(parents=True, exist_ok=True)
    clock_path = run / "wallclock.json"
    clock = json.loads(clock_path.read_text()) if clock_path.exists() else {}

    py = ".venv/bin/python"
    is_graph = args.arm != "grid"
    train_mod = "hivenet.train" if args.arm == "grid" else "hivenet.train_graph"
    size_flags = (["--channels", "96", "--blocks", "8"] if args.arm == "grid"
                  else ["--hidden", "152", "--layers", "8"])
    if args.arm == "graph-untyped":
        size_flags += ["--untyped-edges"]
    if args.arm == "graph-nogpool":
        size_flags += ["--no-gpool"]
    graph_flags = ["--graph"] if is_graph else []
    base_seed = 100_000 * args.seed  # disjoint seed spaces per run

    # Gen 0 net: seeded random init (per-arm export mode).
    models = run / "checkpoints"
    rand_kind = "random" if args.arm == "grid" else "random-graph"
    variant_flags = ([f for f in ["--untyped-edges"] if args.arm == "graph-untyped"]
                     + [f for f in ["--no-gpool"] if args.arm == "graph-nogpool"])
    var = ("-untyped" if args.arm == "graph-untyped" else "") + \
          ("-nogpool" if args.arm == "graph-nogpool" else "")
    if args.arm == "grid":
        net = models / f"hivenet-random-c96b8s{base_seed}-b1.onnx"
    else:
        net = models / f"hivegraph-random{var}-h152L8s{base_seed}-b1.onnx"
    if not net.exists():
        sh([py, "-m", "hivenet.export_onnx", rand_kind, "--out", models,
            *(["--channels", "96", "--blocks", "8"] if args.arm == "grid"
              else ["--channels", "152", "--blocks", "8"]),
            *variant_flags,
            "--seed", base_seed, "--batches", "1"],
           cwd=REPO / "python", env_extra={"PYTHONPATH": "."})

    for gen in range(args.gens):
        tag = f"gen{gen:03d}"
        done_marker = run / "selfplay" / f"{tag}-manifest.json"
        ckpt = run / "checkpoints" / tag / f"hivenet-e{args.epochs-1}.pt" \
            if args.arm == "grid" else \
            run / "checkpoints" / tag / f"hivegraph-e{args.epochs-1}.pt"

        if free_gb() < MIN_FREE_GB:
            raise SystemExit(f"HALT: free disk {free_gb():.1f} GB < {MIN_FREE_GB} GB guard")

        t0 = time.time()
        if not done_marker.exists():
            sh(["./target/release/selfplay-mcts", *graph_flags,
                "--net", net, "--games", args.games, "--threads", args.threads,
                "--sims-full", 128, "--sims-cheap", 32,
                "--seed", base_seed + gen, "--model-gen", gen,
                "--out", run / "selfplay" / tag])
        if not ckpt.exists():
            sh([py, "-m", train_mod, "--data", f"{run}/selfplay/{tag}-*.bin",
                "--out", run / "checkpoints" / tag, "--epochs", args.epochs,
                *size_flags, "--seed", base_seed + gen, "--workers", 0],
               cwd=REPO / "python", env_extra={"PYTHONPATH": "."})
            sh([py, "-m", "hivenet.export_onnx", ckpt, "--out", models,
                "--batches", "1"], cwd=REPO / "python", env_extra={"PYTHONPATH": "."})
        stem = ckpt.stem
        # export writes <stem>-b1.onnx into models/; rename per generation.
        gen_net = models / f"{tag}-b1.onnx"
        exported = models / f"{stem}-b1.onnx"
        if exported.exists():
            exported.replace(gen_net)
        assert gen_net.exists(), f"missing export {gen_net}"
        net = gen_net

        if tag not in clock:
            clock[tag] = round(time.time() - t0, 1)
            clock_path.write_text(json.dumps(clock, indent=2))

        if gen in args.eval_at or gen == args.gens - 1:
            net_flag = "--net" if args.arm == "grid" else "--graph-net"
            us = ["./target/release/hive-engine", "--mcts", net_flag, net,
                  "--sims", EVAL_SIMS, "--seed", 9000 + gen]
            for name, opp in OPPONENTS.items():
                per_opp = args.final_per_opp if gen == args.gens - 1 else args.eval_games // 3
                rec = run / "eval" / f"{tag}-vs-{name}.csv"
                if rec.exists():
                    continue
                sh(["./target/release/hive-arena", "--games", per_opp,
                    "--depth", "1", "--seed", 777_000 + gen,
                    "--threads", args.threads,
                    "--openings-file", OPENINGS,
                    "--records", rec,
                    "--label", f"{args.arm}:s{args.seed}:{tag}:vs:{name}",
                    "--", *us, "--", *opp],
                   env_extra={"HIVE_THREADS": "1"},
                   log=run / "eval" / f"{tag}-vs-{name}.log")

    print(f"run complete: {run}; wall-clock per gen in {clock_path}")


if __name__ == "__main__":
    main()
