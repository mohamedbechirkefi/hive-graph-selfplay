# Reproduction guide {#sec:app-g}

This is the one place in the report where commands, file names and identifiers appear verbatim, because reproducing the study requires them: what is released, the minimal scenario run in a fresh environment on 9 October 2026, the full command set, the durations to expect, and the identifiers a reproduction must match.

## What is released

The release set is the repository `hive-graph-selfplay` and the records under it. Its access and release tag are fixed at diffusion time; at the time of writing nothing has left the study machine, and the licences of the third-party reference engines used only for rules validation are still under review. <!-- src: paper/front-matter.md:12-16 --> <!-- src: paper/final-control.md:15,24-28 -->

- **Code.** The Rust engine (rules kernel, protocol server, search, arena, self-play workers), the Python training and export code under `python/hivenet/`, the scripts under `scripts/`.
- **Frozen configurations.** `configs/comparison-matrix.yaml`, `configs/eval-settings.toml`, the opponent configurations and heuristic weight file under `configs/baselines/`, the ablation specifications under `configs/ablations/`.
- **Frozen openings and population manifest.** `results/comparison/openings-v1.txt` (250 four-ply lines) and `opponents-manifest.md`, which records the hashes of `@tbl:g-identifiers`{=typst}.
- **Result tables.** `results/comparison/results-same-examples.{md,csv}`, `results-same-wallclock.{md,csv}`, `results-arm-difference.md`, `wallclock-per-run.md`; `results/ablations/README.md`.
- **Per-run records**, under `data/runs/cmp-<arm>-s<seed>/`: `eval/` (one comma-separated file per checkpoint and opponent, one row per game: `opening_id, a_is_white, score_a, truncated, plies, outcome`, metadata in `#` header lines); `wallclock.json` (seconds per generation); `selfplay/` manifests tying each shard to its generating network, and the shards; `checkpoints/gen000-b1.onnx` to `gen009-b1.onnx`. Tables and figures need only `eval/` and `wallclock.json`; the replay needs one checkpoint.

The third-party engines used in rules validation (Mzinga, nokamute) are not shipped and are not needed: no study number derives from them. <!-- src: scripts/analyze_comparison.py:3-6 --> <!-- src: scripts/reproduce_minimal.sh:20-31 --> <!-- src: results/comparison/opponents-manifest.md:25-28 --> <!-- src: paper/annex-reproduction.md:3-5 -->

## The minimal fresh-environment scenario

`scripts/reproduce_minimal.sh <workdir>` performs, from a clean clone plus the shipped records, the smallest end-to-end check that touches every link of the chain: build, play, record, aggregate. It passed on 9 October 2026 and again the same day after a prose fix to the table generator, with an empty numeric difference. Its four steps: <!-- src: scripts/reproduce_minimal.sh:1-9 --> <!-- src: paper/final-control.md:13,20 -->

1. **Clone and build.** `git clone` into `<workdir>/clone`, then `cargo build --release -p hive-engine -p hive-arena`; the engine binary must exist afterwards. The inference crate downloads the ONNX Runtime binary at first build, so the first build needs network access. <!-- src: scripts/reproduce_minimal.sh:14-18 --> <!-- src: CLAUDE.md:93-94 -->
2. **Ship the records.** Copy `results/comparison/`, every run's `eval/` and `wallclock.json`, and the single checkpoint `cmp-grid-s2/checkpoints/gen009-b1.onnx` into the clone, as the release layout would. <!-- src: scripts/reproduce_minimal.sh:20-31 -->
3. **Replay one recorded game deterministically.** The game is failure position F2 of the qualitative results: the grid arm's seed-2 final checkpoint against B-HEU on opening line 2, the arm playing Black, lost in 19 plies. The arena plays that opening's colour pair (`--games 2 --depth 1 --seed 1 --threads 1`), the network at 400 simulations with seed 9009 (the final-evaluation rule, 9000 + generation index), B-HEU at depth 1 on one thread; the script asserts that the Black-side row's `score_a`, `truncated` and `plies` equal the shipped row in `cmp-grid-s2/eval/gen009-vs-B-HEU.csv` and prints `replay matches shipped row: plies 19, score 0`. <!-- src: scripts/reproduce_minimal.sh:33-49 --> <!-- src: paper/figures/fig4-failures.md:11-14 --> <!-- src: paper/annex-reproduction.md:35-41 -->
4. **Regenerate and compare.** `python3 scripts/make_results.py` (standard-library Python only) rebuilds both reading tables from the shipped records; `cmp` against the shipped `results-same-examples.md` and `results-same-wallclock.md` must report them byte-identical. The script ends with `MINIMAL REPRODUCTION: PASS`. <!-- src: scripts/reproduce_minimal.sh:51-57 -->

The scenario verifies that the released code builds from a clean checkout, that a recorded game is replayed exactly by the released checkpoint against the released opponent under the pinned settings, and that the published tables are a pure function of the released records. It does not verify training; that is the full reproduction below.

## Full reproduction commands

```sh
# toolchain: Rust (cargo) and Python 3; the project virtual environment is python/.venv
cargo build --release                      # engine, arena, self-play and fuzz binaries
cargo test                                 # rules kernel: unit tests, perft to depth 5 for all 8 game types, UHP server tests
cargo test --release -p hive-core --test perft_tables -- --ignored   # perft to depth 6

# one training run of the matrix (resumable per generation); repeat for --seed 2 … 5
python3 scripts/run_comparison.py --arm grid  --seed 1 --gens 10 --games 500
python3 scripts/run_comparison.py --arm graph --seed 1 --gens 10 --games 500
# ablations (seeds 1–3): --arm graph-untyped | graph-nogpool | graph-untyped-clip

# equal-time checkpoint evaluations for runs whose cutoff checkpoint is not the final one
bash scripts/tstar_evals.sh                # seeds 1–3
bash scripts/tstar_evals2.sh               # graph seeds 4–5

# regenerate every table and figure from raw per-game records
python3 scripts/make_results.py
python/.venv/bin/python scripts/make_figures.py

# pre-training check battery on any shard set
bash scripts/run_h4_checks.sh '<abs>/gen000-*.bin' '<abs>/gen000-manifest.json'

# fresh-environment minimal reproduction (clone, build, replay, compare)
bash scripts/reproduce_minimal.sh /tmp/repro

# French/English numeric-identity check; report build
python3 scripts/check_fr_numbers.py
python/.venv/bin/python scripts/build_report.py all
```

<!-- src: paper/annex-reproduction.md:43-66 --> <!-- src: scripts/run_comparison.py:11-14 --> <!-- src: scripts/run_h4_checks.sh:3 --> <!-- src: scripts/build_report.py:3 --> <!-- src: scripts/tstar_evals.sh:2-4 --> <!-- src: scripts/tstar_evals2.sh:2-3 --> <!-- src: CLAUDE.md:33-35,41 -->

The training driver is resumable per generation: a re-run skips completed generations and continues with the same learning-rate schedule, and every run writes its generator settings, seeds and model stamps into its manifests. Seeds derive from the run's seed number: base seed = 100,000 × seed, generation $g$ using base seed + $g$; evaluation uses network seed 9000 + generation (final sets) or 9500 (equal-time sets), opponent seeds 9101 (B-RND) and 9201 (B-MCTS). <!-- src: scripts/run_comparison.py:2-10 --> <!-- src: paper/annex-reproduction.md:33-41 -->

## Expected durations and disk

All durations in `@tbl:g-durations`{=typst} were measured on the study machine (Apple M1 Pro, 10 cores, 16 GB, macOS 15.3.1) with four worker threads per run and sequential runs; the grid arm's inference runs on CoreML (2.62 ms per evaluation), the graph arm's on CPU (3.67 ms), each the fastest provider measured for that network. <!-- src: paper/annex-reproduction.md:68-77 -->

| Step | Measured duration |
| --- | ---: |
| One grid training run (10 generations × 500 games): training wall-clock, evaluation games excluded | 16.7–19.1 h |
| One graph training run (same budget): training wall-clock, evaluation games excluded | 26.6–49.9 h |
| All ten main-campaign runs, training wall-clock summed | 273.5 h (grid 90.0 h, graph 183.5 h) |
| Original six-run campaign (seeds 1–3, both arms, sequential), elapsed | 10–17 September 2026, ≈7.4 days; ≈163 h of machine time |
| Extension runs (seeds 4–5, both arms), elapsed per run as recorded | 18.0–54.9 h, 27 September to 2 October 2026 |
| One evaluation game at 400 simulations | ≈23–32 s |
| Equal-time evaluation sets, seeds 1–3 (four checkpoints × three opponents) | ≈11 h, 18 September 2026 |
| Equal-time evaluation sets, graph seeds 4–5 (two checkpoints × three opponents) | ≈6 h, 6 October 2026 |
| Ablation runs A1 / A2 / A1′ (per seed), training wall-clock | 7.61–8.01 h (a divergence symptom) / 32.05–47.44 h / 23.89–30.35 h |
| Engine build; minimal scenario | not measured |

Table: Measured durations of the study's computations on the study machine (Apple M1 Pro, four worker threads per run, sequential runs), as recorded in the run and analysis records; ranges span the runs of the step. Training wall-clock is the sum of a run's per-generation self-play and training seconds, evaluation games excluded; campaign, extension and ablation figures are elapsed times as recorded. A1's short runs reflect its divergence (a NaN policy plays short degenerate games) rather than a lower cost. The engine build and the minimal scenario were not timed. {#tbl:g-durations}

<!-- src: paper/annex-reproduction.md:75-77 --> <!-- src: results/comparison/wallclock-per-run.md:1-10 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:24-26 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:3,12-16 --> <!-- src: journal/2026-09-23-h7-a1-divergence-01.md:15-17 --> <!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:16-17 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:13 -->

Disk: before the campaign the six-run matrix was sized at about 3–5 GB of shards, checkpoints and records, against 164 GB free with a 20 GB guard; mid-campaign the machine reported 200 GB free. The final footprint of the run directories was not recorded. <!-- src: journal/2026-09-10-h6-matrix-01.md:50-55 --> <!-- src: journal/2026-09-16-h6-progress-01.md:28-29 -->

## Identifiers a reproduction must match

A reproduction is faithful when it uses the frozen artifacts identified below and, for the minimal scenario, reproduces the shipped game row and the byte-identical tables. The frozen experimental constants that every command must leave untouched are tabulated in `@sec:app-c`{=typst}: base game with the tournament opening rule, 300-ply cap, 128/32 self-play simulations with full fraction 0.25, 12 temperature plies, resignation at −0.92 with a 10% audit, 400 evaluation simulations without noise, 100 games per opponent, 250 openings, the 18.77 h cutoff, seeds 1–5 per arm. <!-- src: results/comparison/opponents-manifest.md:3-44 --> <!-- src: paper/annex-reproduction.md:7-19 -->

| Artifact | Identifier |
| --- | --- |
| Heuristic weight file (`configs/baselines/heuristic-weights.toml`), SHA-256 | `d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a` |
| B-RND configuration (`configs/baselines/random.toml`), SHA-256 | `f2fc4a06441d3c1a7922838a6693dbb48ec54543bc34fd814d41c9a742514cd7` |
| B-HEU configuration (`configs/baselines/heuristic.toml`), SHA-256 | `7210a0a349c5bad5dcd2df099cc6865ee3cb5d8a2c30e106ce58137804818999` |
| B-MCTS configuration (`configs/baselines/mcts-nonet.toml`), SHA-256 | `3fc8f75cf2b4f21012dd61e9924408fbfc32c8ea561aa96eb44f1091ba07364e` |
| Frozen openings, content of the 250 lines, SHA-256 | `63b318d071dfc3ecfae3585636c8e6f7327ddc08e7aed86a466f915f8005af7b` |
| Frozen openings, file as frozen, SHA-256 | `538497390a3787299c67c3ca138b8feacb369d55dc562881d1aee45200cbccb2` |
| Opening/colour schedule of every 100-game match | `8cd84b6564440666` |
| Frozen protocol document | `f340a6b6…aefeb5` (recorded abbreviated), commit `44a74ff` |
| Engine code at the population freeze | commit `b94e7c1` |
| Campaign code (main comparison) | commit `ac58773` |
| Ablation code; non-finite-loss guard | commits `216fded`; `bffeea9` |
| Analysis code (final five-seed tables) | commit `7db074d` |

Table: Identifiers of the frozen artifacts and code states of the study. Hashes are SHA-256 hexadecimal digests of file content as recorded at the freeze; the schedule hash is the digest prefix printed by the analysis tool for the (opening, colour) schedule, identical for every match of the study; commits are abbreviated repository commit identifiers. {#tbl:g-identifiers}

<!-- src: results/comparison/opponents-manifest.md:10-44 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:10-11 --> <!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:9-11 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:9-10 -->
