```yaml
id:            H2-2026-09-09-random-invariants-01
date:          2026-09-09
hypothesis:    Seeded random games violate none of the plan ch. 4 invariants:
               apply accepts every generated move; the hive stays connected
               after every transition; GameString serialise->deserialise
               preserves position, result and the exact valid-move set;
               pass is accepted exactly when no move exists.
git_commit:    2c3e7a6 (test added on top; commit follows this entry)
config:        crates/hive-core/tests/random_invariants.rs
seeds:         base 0x20260909 (deep adds rounds +1, +2), per-game-type mix
data_version:  n/a
hardware:      MacBook (Apple Silicon arm64), release build
duration:      default session 2.7 s; deep session 214 s
cost:          0
```

## Methods

New integration test `random_invariants.rs` in hive-core, wired into the
automated suite (default `cargo test`) with a deep `--ignored` variant added
to `scripts/nightly.sh`. Per ply, over all 8 game types: play+undo of the
FULL generated move list (apply must accept each; undo must restore the
exact GameString), a one-hive BFS connectivity check after every applied
move, and a GameString round-trip (`Game::from_uhp`) compared on both the
GameString and the sorted UHP move set. Pass is played when and only when
the move list is empty.

## Raw results + uncertainty

| Session | Games | Plies walked | Generated moves applied+undone | Violations |
| --- | --- | --- | --- | --- |
| Default (in `cargo test`) | 4/type × 8 types, ≤150 plies | 4,029 | 253,936 | **0** |
| Deep (nightly, `--ignored`) | 3 rounds × 20/type × 8 types, ≤400 plies | 161,546 | 10,665,686 | **0** |

Deterministic given the seeds; violations would panic with (game type,
seed, game, ply, GameString) for archiving as regression cases — none arose.

## Failures

None.

## Limits / confounders

- Random walks explore breadth, not depth of adversarial play; corpus
  (C001–C030) and differential fuzzing cover targeted rules and reference
  agreement respectively.
- Serialise/deserialise is exercised through the UHP GameString (move-list
  replay), the same channel the pipeline uses — binary state snapshots are
  not round-tripped (none are persisted by the engine).

## Interpretation

Plan ch. 4's "random sessions without violation" requirement holds at
10.9M applied transitions across all game types. Together with the
re-confirmed suites and the 30/30 corpus, the H2 validation line is
complete pending profiling (task 6).

## Decision

**continue** — engine validated; profiling in progress.

## Artifacts

- `crates/hive-core/tests/random_invariants.rs` (default + deep sessions)
- `scripts/nightly.sh` (deep session wired in)
