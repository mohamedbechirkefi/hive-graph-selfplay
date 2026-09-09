# hive-graph-selfplay — HiveMind engine (research project 1)

UHP-compatible Hive engine (base + M/L/P expansions), Rust alpha-beta core
plus an MCTS + NN self-play stack. Now the vehicle for the representation
study "Graph-Based Self-Play for Hive under Limited Compute".

## Research mode — read this first

This repo is **project 1 of the research OS**. The workspace `../CLAUDE.md`
(operating model, gates, invariants) and `../state/STATUS.md` (routing) govern
every session here — do not act from this file alone. Phases **H1–H8** live in
`../pipelines/hive/H*.md`; execute the active phase's doc, not ad-hoc ideas.

- **Local authorities:** `docs/inventory.md` (what exists, what counts as
  evidence) and `docs/protocol.md` once H1 produces it. Where they refine the
  plan, they win locally.
- **Journal:** every experiment/measurement → `journal/YYYY-MM-DD-<slug>.md`
  per `../templates/experiment.md`. Negative results included.
- **Prior work (decision D-003):** the completed rl_loop (19 generations,
  gen 20 crashed on StorageFull) is a **demonstration, not evidence** —
  single-seed, single-architecture, no controlled budget. The new study
  inherits the engine and its validation evidence, not the loop's results.
  **Do not restart the loop from here** — that is a G-SPEND/G-DESTRUCTIVE
  decision for the human. The gen-19 checkpoint is preserved at `models/best*`
  (`best-b1.onnx`, `best-b128.onnx`, `best.pt`); never overwrite or delete it.
- **Out of the new study's scope** (plan ch. 3; inventory): the M/L/P
  expansions, MuZero-style extensions, `web/`, and `crates/hive-api` — the
  last two are **frozen, not deleted**.

## Build & test

```sh
cargo build --release          # needs ~/.cargo/bin in PATH
cargo test                     # unit + perft(≤5) + UHP server tests
cargo test --release -p hive-core --test perft_tables -- --ignored  # perft d6
./scripts/nightly.sh           # perft d7 + differential fuzz (slow)
```

## Correctness invariants (never merge a movegen change without these)

1. `cargo test` — includes perft ≤5 for all 8 game types vs Mzinga's tables.
2. `./opponents/nokamute uhp-debug ./target/release/hive-engine` — 21/21.
3. `./target/release/fuzz ./opponents/MzingaEngine -- 25 <seed>` and same
   with `./opponents/nokamute uhp` — validmoves set-equality per ply.

`opponents/` is **not in this copy** — fetch via `./scripts/fetch_opponents.sh`
first. The binaries are third-party; check their licences before publishing
anything derived from them (see `docs/inventory.md`, Rights).

## Strength testing

`hive-arena` plays paired color-swapped games from random openings:

```sh
HIVE_THREADS=6 ./target/release/hive-arena --games 24 --movetime 1 --threads 2 \
  -- ./target/release/hive-engine -- ./opponents/nokamute uhp
```

Set `HIVE_THREADS` so concurrent games don't oversubscribe cores.
Every search/eval change must not regress the gauntlet score. Concretely: run
at least 100 paired games (planning proposal until `docs/protocol.md` fixes N
at the H1 freeze) against the fixed nokamute gauntlet, journal the score, and
treat any drop larger than the binomial confidence interval as a regression —
the frozen protocol sets the final threshold. The 24-game command above is a
smoke run only (binomial 95% CI ≈ ±20 pp at N=24), never a regression check.

## Architecture notes

- Board: 64×64 wrapping byte grid (torus), absolute coords never
  renormalize → Zobrist stays incremental; hashing = splitmix64 mixing, no
  tables (`hive-core/src/zobrist.rs`).
- Stun rule needs only `last_moved: Option<PieceId>` — see the proof in the
  doc comment on `GameState::last_moved`. `(piece, dest)` uniquely
  identifies a move; walk-vs-throw collisions produce identical states.
- Search: PVS + lock-free shared TT (XOR-validated) + lazy SMP; NO null
  move (Hive has zugzwang-like pass states); quiescence = enemy-queen
  targeting moves only.
- Eval weights live in `hive_eval::Weights` (tunable struct, SPSA planned).
- NN interface (`hive-nn`): 32×32 frame (BFS-unwrapped, bbox-centered),
  policy = (rel_piece, dest) 28,673-way, compact 112-byte training records.
  The Rust `planes()` encoder and `python/hivenet/dataset.py::decode_planes`
  MUST stay identical — verified by `dump_planes` +
  `scripts/crosscheck_planes.py` (runs in nightly.sh). If you change one,
  change the other and re-run the crosscheck.
- Training data: `./target/release/selfplay --games N --depth 4 --out data/selfplay/run`
  (v1 records, one-hot policy) or `./target/release/selfplay-mcts --net models/best-b1.onnx ...`
  (v2 records with MCTS visit-distribution targets; shards start with the
  HIVEREC2 magic header). Train with
  `python/.venv/bin/python -m hivenet.train --data '<globs>'` (from python/;
  handles both record versions); export ONNX with `-m hivenet.export_onnx`.
- NN play: `hive-engine --mcts --net models/best-b1.onnx` (CoreML EP;
  `--cpu` to force CPU). Inference lives in hive-mcts/src/ort_eval.rs
  behind the default `nn` feature (ort crate downloads the ONNX Runtime
  binary at first build — needs network).
- The full unattended pipelines: `scripts/overnight.sh` (bootstrap:
  gauntlets → supervised dataset → train → export) and `scripts/rl_loop.sh`
  (AlphaZero loop: self-play → train → export → gate → promote; needs the
  bootstrap model in models/ first). Both are **prior work** — see D-003
  above before touching either.
