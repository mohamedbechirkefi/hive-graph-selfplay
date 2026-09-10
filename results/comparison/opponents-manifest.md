# H6 opponents & openings manifest (pipeline H6 task 2)

## Frozen opponent population — D-017 (G-FREEZE crossed 2026-09-09)

Frozen by the user ("freeze the population at 6400, exclude gen-19");
nothing here re-decides it. Config/weight hashes as recorded at the
freeze, unchanged since (weights additionally pinned by the hive-eval
test `weights_pinned_for_h3_baselines`):

| Agent | Invocation | Config sha256 |
| --- | --- | --- |
| B-RND | `hive-engine --random --seed N` | `configs/baselines/random.toml` f2fc4a06441d3c1a7922838a6693dbb48ec54543bc34fd814d41c9a742514cd7 |
| B-HEU | `hive-engine`, `bestmove depth 1`, HIVE_THREADS=1 | `configs/baselines/heuristic.toml` 7210a0a349c5bad5dcd2df099cc6865ee3cb5d8a2c30e106ce58137804818999 |
| B-MCTS | `hive-engine --mcts --sims 6400 --seed N` | `configs/baselines/mcts-nonet.toml` 3fc8f75cf2b4f21012dd61e9924408fbfc32c8ea561aa96eb44f1091ba07364e |

Weights: `configs/baselines/heuristic-weights.toml`
sha256 d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a.
Engine code commit at the freeze: b94e7c1; later commits touched records,
the graph arm and arena I/O — no searcher, eval weight or MCTS default
changed (weights test green at every commit).

**Gen-19 checkpoint: excluded** per D-016 (proposal) confirmed in D-017 —
demonstration provenance, not re-decided here.

**Third-party binaries (Mzinga, nokamute): not part of this population.**
They are engine-validation references only; no H6 result derives from
them, so the A1 licence check (G-RIGHTS, still open) does not block this
phase. It must still close before publication (A1 task 7).

## Fixed shared openings — PRESENTED FOR G-FREEZE

- File: `results/comparison/openings-v1.txt` — 250 unique legal 4-ply
  base-game openings.
- sha256: `45432416764a07bc6d5a18e13948bb8b0e3b148e5b5471ced4794d0e48af9386`
- Generator: seeded random walk over engine `validmoves`
  (python `random.Random(20260910)`, engine commit of 2026-09-10);
  reproducible from the documented seed.
- Usage: pair *i* of every match plays opening line *i*, both colours
  (arena `--openings-file`; schedule identity proven by the task-3
  harness test — schedule hash `8cd84b6564440666` across distinct runs).
- Pilot uses openings 0–49 (100 games/pairing); final volume per the
  task-4 recalibration decision, never exceeding the 250 without a new
  freeze.

**On human approval this list freezes: no opening is added, removed or
reordered afterwards — any touch = a new study.** Freeze record to be
appended to `state/decisions.md` and STATUS.md's gate ledger.
