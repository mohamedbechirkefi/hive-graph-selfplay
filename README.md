# HiveMind: a Hive engine and the study "Grid vs. Graph Representations for Self-Play Learning in Hive"

## Research report (October 2026)

This repository holds the engine, the self-play pipeline, both state
encoders and every artifact of a pre-registered comparison of grid and
graph representations for AlphaZero-style self-play in base-game Hive.
The hypothesis (graph learns better at equal budget) was rejected under
the frozen rule: five seeds per arm, two budget readings, truncation as a
separate outcome, byte-identical fresh-environment reproduction. A second,
separately pre-registered study (protocol v2, October 2026: warm start and
a three-generation replay window, five new seeds per arm) detected no
graph advantage under either reading; the first study's deficit is no
longer visible at equal examples and reduced at equal wall-clock, at
2.34 times the cost. Both studies are reported side by side, never
pooled (report chapter 15).

- Full report (English, 173 pp): `paper/build/report-en.pdf`
- Rapport complet (français, 188 pp) : `paper/build/report-fr.pdf`
- Short article (18 pp): `paper/build/article-en.pdf` (French: `article-fr.pdf`)
- Sources of the report: `paper/report/` (EN) and `paper/report/fr/` (FR);
  build with `python/.venv/bin/python scripts/build_report.py all`
- Raw evaluation records, clock files, manifests and checkpoints: the
  records archive attached to the release (`v2.0-report` for the first
  study; `v2.1-report` adds the second study's runs `cmp2-*`); place its
  `data/runs/` at the repository root and run `python3 scripts/make_results.py`
  (first study) and `python3 scripts/make_results.py --study 2` (second
  study) to regenerate every table; `scripts/reproduce_minimal.sh` runs the
  minimal fresh-environment scenario.
- Frozen protocols: `docs/protocol.md` (v1.0, 2026-09-10) and
  `docs/protocol-v2.md` (v2.0, 2026-10-13); frozen opponents and openings:
  `docs/baselines.md`, `results/comparison/`; second-study tables:
  `results/study2/`.

The study was carried out by the author with an AI research assistant
under a gated methodology that reserved every scientific decision to the
author; the report's chapter 10 documents it. Licensing: releases up to
and including v2.1-report are MIT; see [License and contributions](#license-and-contributions).

## The engine

A UHP-compatible engine for [Hive](https://en.wikipedia.org/wiki/Hive_(game))
(base game + Mosquito/Ladybug/Pillbug expansions, all 8 UHP game types),
built in two stages:

- **Phase A (classical)** — fast Rust rules kernel, PVS/alpha-beta search
  with a handcrafted evaluation. Serves as sparring partner and test oracle.
- **Phase B (neural)** — AlphaZero-style MCTS + a policy/value network
  trained by self-play (PyTorch/MPS, ONNX inference in-engine).

## Layout

| crate | purpose |
|---|---|
| `hive-core` | rules kernel: board, movegen, UHP notation, Zobrist, perft |
| `hive-uhp` | UHP server loop + subprocess client for other engines |
| `hive-eval` | handcrafted evaluation (tunable weights) |
| `hive-search` | iterative-deepening PVS, TT, killers/history, LMR |
| `hive-arena` | UHP-vs-UHP match runner with Elo reporting |
| `hive-engine` | the shipped binary (also: `perft`, `fuzz` tools) |

## Quick start

Fresh machine (installs toolchain, builds, tests, fetches opponents, sets up
the Python env — add `--overnight` to also launch the unattended
gauntlet→dataset→training pipeline):

```sh
./scripts/setup.sh                    # or: ./scripts/setup.sh --overnight
```

Manual steps, if you prefer:

```sh
cargo build --release
./scripts/fetch_opponents.sh          # Mzinga (release) + nokamute (source)

./target/release/hive-engine          # UHP engine on stdin/stdout
./target/release/perft Base+MLP 6     # parallel perft
./target/release/fuzz ./opponents/MzingaEngine -- 25 42   # differential fuzz

# gauntlet vs nokamute, 20 paired games at 1s/move:
./target/release/hive-arena --games 20 --movetime 1 --threads 5 \
    -- ./target/release/hive-engine -- ./opponents/nokamute uhp
```

## Correctness

The rules kernel is validated three independent ways (see `scripts/nightly.sh`):

1. **Perft**: exact match with [Mzinga's published tables](https://github.com/jonthysell/Mzinga/wiki/Perft)
   for all 8 game types (depth ≤ 6 in CI, depth 7+ nightly).
2. **UHP conformance**: passes all 21 tests of `nokamute uhp-debug`.
3. **Differential fuzzing**: random games where after every ply our
   `validmoves` set must equal Mzinga's and nokamute's exactly, plus
   game-state cross-checks.

## How to cite

Use GitHub's **"Cite this repository"** button, or the metadata in
[`CITATION.cff`](CITATION.cff). The preferred citation is the report:
Kefi, M. B. (2026). *Grid vs. Graph Representations for Self-Play Learning in
Hive: a Pre-Registered Comparison under Limited Compute* (version 2.1).

## License and contributions

**HiveMind is a source-available, non-commercial AI research project.**

Copyright (c) 2026 Mohamed Bechir Kefi.
All rights reserved except as expressly licensed.

**Earlier releases remain MIT.** Everything up to and including release
v2.1-report (both studies, the engine, the pipeline, the report and the
records) was distributed under MIT, and those permissions, including
commercial reuse, remain valid. [`NOTICE.md`](NOTICE.md) says exactly which
material is under which license, and [`LICENSE_HISTORY.md`](LICENSE_HISTORY.md)
records the transition.

**New material** is under the
[HiveMind Source-Available Non-Commercial Research License](LICENSE), which permits:

- Reading and studying the source code
- Non-commercial academic research
- Personal educational use
- Local execution and experimentation
- Local modifications for research
- Benchmarking and reproducibility studies
- Proposing improvements through GitHub Issues and Pull Requests

Commercial use of newly licensed material, including incorporating it into
commercial software, paid applications, services or proprietary products,
requires prior written authorization from the copyright holder. General
redistribution and publication of modified versions of newly licensed
material are also restricted.

Bug reports, suggestions, experimental results and Pull Requests are welcome.
Please read [CONTRIBUTING.md](CONTRIBUTING.md) first. Copyrightable
contributions require separately recorded acceptance of the
[Contributor License Agreement](CLA.md) before merging; contributors keep
ownership of their original contributions while granting the maintainer broad
reuse and relicensing rights.

This is an independent research project and is not affiliated with or
endorsed by the publisher of the Hive board game.
