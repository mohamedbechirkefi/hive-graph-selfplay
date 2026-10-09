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

Study 2 (H9, protocol v2 DRAFT) adds two options, identical for both arms
and OFF by default so that the Study 1 command lines are reproduced
exactly (scripts/test_driver_equivalence.py proves it):
  --warm-start      train generation g from generation g-1's checkpoint
                    (model weights only; optimizer and schedule restart)
  --window W        train on the shards of generations max(0,g-W+1)..g
  --run-prefix P    run directory data/runs/P-<arm>-s<seed> (default cmp)
  --dry-run         print every command without executing anything
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
DRY = False


def sh(cmd, cwd=REPO, env_extra=None, log=None):
    print(f"+ {' '.join(map(str, cmd))}", flush=True)
    if DRY:
        return
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
                    choices=["grid", "graph", "graph-untyped", "graph-nogpool",
                             "graph-untyped-clip"])
    ap.add_argument("--seed", type=int, required=True)
    ap.add_argument("--gens", type=int, default=10)
    ap.add_argument("--games", type=int, default=500)
    ap.add_argument("--epochs", type=int, default=2)
    ap.add_argument("--threads", type=int, default=4)
    ap.add_argument("--eval-at", type=int, nargs="*", default=[4, 7])
    ap.add_argument("--eval-games", type=int, default=60)  # 20/opponent
    ap.add_argument("--final-per-opp", type=int, default=100)  # task-4 pilot volume
    ap.add_argument("--warm-start", action="store_true",
                    help="Study 2: init generation g from generation g-1's checkpoint")
    ap.add_argument("--window", type=int, default=1,
                    help="Study 2: train on the last W generations' shards (1 = Study 1)")
    ap.add_argument("--run-prefix", default="cmp",
                    help="run directory prefix under data/runs/ (Study 2 uses cmp2)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the command lines without running anything")
    args = ap.parse_args()
    global DRY
    DRY = args.dry_run
    assert args.window >= 1, "--window must be >= 1"

    assert OPENINGS.exists(), "frozen openings file missing"
    run = REPO / "data" / "runs" / f"{args.run_prefix}-{args.arm}-s{args.seed}"
    if not DRY:
        for d in ("selfplay", "checkpoints", "eval"):
            (run / d).mkdir(parents=True, exist_ok=True)
        # Study-2 options are recorded with the run so a manifest reader
        # can tell the regimes apart without parsing logs.
        (run / "driver-config.json").write_text(json.dumps(
            {"arm": args.arm, "seed": args.seed, "gens": args.gens, "games": args.games,
             "epochs": args.epochs, "warm_start": args.warm_start, "window": args.window,
             "run_prefix": args.run_prefix}, indent=2))
    clock_path = run / "wallclock.json"
    clock = json.loads(clock_path.read_text()) if clock_path.exists() else {}

    py = ".venv/bin/python"
    is_graph = args.arm != "grid"
    train_mod = "hivenet.train" if args.arm == "grid" else "hivenet.train_graph"
    size_flags = (["--channels", "96", "--blocks", "8"] if args.arm == "grid"
                  else ["--hidden", "152", "--layers", "8"])
    if args.arm in ("graph-untyped", "graph-untyped-clip"):
        size_flags += ["--untyped-edges"]
    if args.arm == "graph-untyped-clip":
        size_flags += ["--clip-norm", "1.0"]
    if args.arm == "graph-nogpool":
        size_flags += ["--no-gpool"]
    graph_flags = ["--graph"] if is_graph else []
    base_seed = 100_000 * args.seed  # disjoint seed spaces per run

    # Gen 0 net: seeded random init (per-arm export mode).
    models = run / "checkpoints"
    rand_kind = "random" if args.arm == "grid" else "random-graph"
    variant_flags = ([f for f in ["--untyped-edges"]
                      if args.arm in ("graph-untyped", "graph-untyped-clip")]
                     + [f for f in ["--no-gpool"] if args.arm == "graph-nogpool"])
    var = ("-untyped" if args.arm in ("graph-untyped", "graph-untyped-clip") else "") + \
          ("-nogpool" if args.arm == "graph-nogpool" else "")
    if args.arm == "grid":
        net = models / f"hivenet-random-c96b8s{base_seed}-b1.onnx"
    else:
        net = models / f"hivegraph-random{var}-h152L8s{base_seed}-b1.onnx"
    if DRY or not net.exists():
        sh([py, "-m", "hivenet.export_onnx", rand_kind, "--out", models,
            *(["--channels", "96", "--blocks", "8"] if args.arm == "grid"
              else ["--channels", "152", "--blocks", "8"]),
            *variant_flags,
            "--seed", base_seed, "--batches", "1"],
           cwd=REPO / "python", env_extra={"PYTHONPATH": "."})

    def ckpt_of(g):
        t = f"gen{g:03d}"
        return (run / "checkpoints" / t / f"hivenet-e{args.epochs-1}.pt" if args.arm == "grid"
                else run / "checkpoints" / t / f"hivegraph-e{args.epochs-1}.pt")

    for gen in range(args.gens):
        tag = f"gen{gen:03d}"
        done_marker = run / "selfplay" / f"{tag}-manifest.json"
        ckpt = ckpt_of(gen)

        if not DRY and free_gb() < MIN_FREE_GB:
            raise SystemExit(f"HALT: free disk {free_gb():.1f} GB < {MIN_FREE_GB} GB guard")

        t0 = time.time()
        if DRY or not done_marker.exists():
            sh(["./target/release/selfplay-mcts", *graph_flags,
                "--net", net, "--games", args.games, "--threads", args.threads,
                "--sims-full", 128, "--sims-cheap", 32,
                "--seed", base_seed + gen, "--model-gen", gen,
                "--out", run / "selfplay" / tag])
        if DRY or not ckpt.exists():
            # Study 1: this generation's shards only, fresh initialisation.
            # Study 2: a window of W generations and/or a warm start from
            # the previous generation's checkpoint (weights only).
            first = max(0, gen - args.window + 1)
            data_globs = [f"{run}/selfplay/gen{g:03d}-*.bin" for g in range(first, gen + 1)]
            init_flags = (["--init", ckpt_of(gen - 1)]
                          if args.warm_start and gen > 0 else [])
            sh([py, "-m", train_mod, "--data", *data_globs,
                "--out", run / "checkpoints" / tag, "--epochs", args.epochs,
                *size_flags, "--seed", base_seed + gen, "--workers", 0, *init_flags],
               cwd=REPO / "python", env_extra={"PYTHONPATH": "."})
            sh([py, "-m", "hivenet.export_onnx", ckpt, "--out", models,
                "--batches", "1"], cwd=REPO / "python", env_extra={"PYTHONPATH": "."})
        stem = ckpt.stem
        # export writes <stem>-b1.onnx into models/; rename per generation.
        gen_net = models / f"{tag}-b1.onnx"
        exported = models / f"{stem}-b1.onnx"
        if not DRY:
            if exported.exists():
                exported.replace(gen_net)
            assert gen_net.exists(), f"missing export {gen_net}"
        net = gen_net

        if not DRY and tag not in clock:
            clock[tag] = round(time.time() - t0, 1)
            clock_path.write_text(json.dumps(clock, indent=2))

        if gen in args.eval_at or gen == args.gens - 1:
            net_flag = "--net" if args.arm == "grid" else "--graph-net"
            us = ["./target/release/hive-engine", "--mcts", net_flag, net,
                  "--sims", EVAL_SIMS, "--seed", 9000 + gen]
            for name, opp in OPPONENTS.items():
                per_opp = args.final_per_opp if gen == args.gens - 1 else args.eval_games // 3
                rec = run / "eval" / f"{tag}-vs-{name}.csv"
                if rec.exists() and not DRY:
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
