# Inventory of prior work (plan ch. 2)

Snapshot taken 9 Sept 2026, carried over from `~/Documents/hive/hive-boardgame`
(original left in place as a backup). Build artifacts (`target/`, `.venv/`,
`node_modules/`, `opponents/`) were not copied — all are regenerable.

Purpose of this document: separate **what is a working demonstration** from
**what is a reproducible comparison**. Only the second kind counts as evidence.

## Engine (Rust, `crates/`)

| Component | State |
| --- | --- |
| `hive-core` | Rules kernel. Base game + Mosquito/Ladybug/Pillbug. Zero I/O, zero global state. |
| `hive-uhp` | Universal Hive Protocol server (stdin/stdout). |
| `hive-eval` / `hive-search` | Alpha-beta: PVS, lock-free shared TT, lazy SMP. No null move (zugzwang-like pass states). Quiescence limited to enemy-queen-targeting moves. |
| `hive-nn` | 32×32 BFS-unwrapped, bbox-centered frame. Policy space (rel_piece, dest) = 28,673. 112-byte training records. |
| `hive-mcts` | MCTS + ONNX inference (`ort`, CoreML EP, CPU fallback). |
| `hive-arena` | Paired colour-swapped match runner from random openings. |
| `hive-selfplay` | Self-play data generation (v1 one-hot, v2 MCTS visit distributions). |
| `hive-api` | HTTP wrapper (Axum) written for the UI prototype. **Out of scope** for the new study. |

**Board representation:** 64×64 wrapping byte grid (torus). Absolute coordinates
never renormalise, so Zobrist stays incremental. Hashing is splitmix64 mixing,
no tables.

## Validation evidence — the part that matters

This is the strongest asset carried over, and it is directly reusable as the
"engine correctness" chapter of the report (plan ch. 4).

- **Perft** against Mzinga's published tables, all 8 game types, depth ≤ 5 in
  `cargo test`; depth 6–7 under `--ignored` / `scripts/nightly.sh`.
- **UHP conformance** — 21/21 via `nokamute uhp-debug`.
- **Differential fuzzing** — `validmoves` set-equality per ply against both
  MzingaEngine and nokamute.
- **Plane-encoding crosscheck** — Rust `planes()` vs
  `python/hivenet/dataset.py::decode_planes`, verified by `dump_planes` +
  `scripts/crosscheck_planes.py` in nightly.

Gap to close: no documented corpus of 30–50 hand-annotated edge positions with
expected outcomes (plan ch. 4 requires this). The automated invariants exist;
the human-readable critical corpus does not.

## Prior AlphaZero-style loop

`scripts/rl_loop.sh` — self-play → train → export ONNX → gate → promote.

- **19 generations completed** (gen001–gen019). Generation 20 aborted
  2026-08-14 on `StorageFull`; the loop has been stopped since.
- Per generation: 2000 games, 600 full / 150 cheap simulations, 2 threads.
  Wall-clock ran roughly 150,000–157,000 s per generation on the laptop.
- Gating: 60 games @ 2 s/move against the incumbent best; promote above 50%.
- **Gen 19 promoted at 56.7%.** Current `models/best-b1.onnx`, `best-b128.onnx`,
  `best.pt` are that checkpoint.
- Training metrics fluctuated across generations rather than climbing
  monotonically: policy top-1 roughly 43–47%, value accuracy roughly 58–63%.
- Promotions were intermittent — gate scores ranged from about 45% to 63%,
  with promotions at generations 6, 7, 11, 14 and 19 among those logged.

**Honest classification of this loop:** a working demonstration, *not* a
reproducible comparison. It was single-seed, single-architecture, with no
controlled compute budget and no held-out opponent population fixed in advance.
It supports the claim "an end-to-end self-play pipeline was built and ran";
it does not support any claim about representation quality or learning
efficiency. The new study does not inherit its results.

## Out of scope for the new study

Carried over for completeness, explicitly excluded from the research perimeter
(plan ch. 3): `web/` (React + Three.js prototype), `crates/hive-api`,
the M/L/P expansions, and MuZero-style extensions.

## Rights

All code in this repo is the author's own. `opponents/` was not copied — those
binaries are fetched by `scripts/fetch_opponents.sh` and are third-party;
their licences must be checked before any result derived from them is published.

## Task classification (plan ch. 2 exit criterion)

**Necessary to the proof**
- Hand-annotated critical position corpus (30–50 positions).
- Fixed baseline opponents: legal-random, documented heuristic, MCTS-without-network.
- Shared action decoder used identically by both architectures.
- Grid encoder and graph encoder behind one interface.
- Budget accounting: states, simulations, wall-clock, hardware.
- Multi-seed protocol with paired evaluation positions.

**Demonstration**
- Short game viewer for the defence.

**Extension**
- Expansions, MuZero, additional architectures, the web UI.

## Open questions before the protocol is frozen

1. Which variant? Plan ch. 3 recommends base game only. Engine supports all 8.
2. Python/PyTorch pipeline against a Rust engine — binding layer (PyO3) or
   subprocess/UHP? Affects self-play throughput, which is the currency of RQ-H1.
3. Truncation convention. Self-play games were capped; the cap is not an
   official draw and its frequency must be reported and sensitivity-tested.
4. Measured throughput per position type — profile before choosing simulation
   budgets. The 64/128 figures in the plan are starting points, not standards.
