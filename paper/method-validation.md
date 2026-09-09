# Method — Engine correctness (report section draft)

*Drafted 2026-09-09 (invariant 14: written as the phase runs). English
working master; French copy at the report milestone (D-006). Every number
traces to a journal entry (invariant 4); claims are registered in
`claims.md`.*

## Why validation precedes everything

A self-play study trains on positions the engine itself generates and
scores; a rules defect therefore does not merely add noise — it teaches
both arms a systematically wrong game and silently invalidates the
comparison ("false learning", plan ch. 4). The stop rule is absolute: an
engine found incorrect suspends all training-side work (invariant 11). We
therefore validate along four independent lines before any baseline or
training work, and report each line with its exact scope.

## Four lines of evidence

**1. Perft against published tables.** Node counts for all 8 game types
match Mzinga's published perft tables: depth ≤5 in the standard test
suite, depth 6 in a dedicated run (8.3 s, all types), depth 7 in the
nightly script. Perft is exhaustive within its depth: any movegen
discrepancy — a missing move, an extra move, a wrong stacking rule —
shifts a count. (Journal `H2-2026-09-09-suite-rerun-01`.)

**2. Reference-engine agreement.** The engine passes nokamute's UHP
conformance harness (21/21) and, more stringently, differential fuzzing
plays seeded random games while asserting per-ply *set equality* of legal
moves against two independent reference engines — MzingaEngine v0.16.0
(the UHP reference implementation) and nokamute 1.0.3: 27,829 positions at
the session's fixed seed, 200/100 games per type nightly. Two engines with
independent codebases agreeing on every legal-move set bounds the chance
of a shared rules misreading. (Journal `H2-2026-09-09-suite-rerun-01`.)

**3. Hand-annotated critical corpus.** Reference agreement cannot catch a
misreading shared by the community's engines, so 30 critical positions
were annotated *by hand from the publisher's rules* (Gen42 rulesheet and
Pillbug sheet, World Hive Tournaments FAQ; tournament opening rule
declared as a convention) — sliding and gates, beetle stacking and the
above-ground beetle gate, stack colour for placement, One-Hive cut points
and rings, win/draw termination including the simultaneous-surround draw,
forced pass, and Pillbug stun as a kernel guard. Expectations were
committed before the first engine run; the runner compares full
(piece, destination) move sets over UHP. First run: 29/30, with the single
disagreement resolved *against the corpus* — a setup line violated the
One-Hive transit rule the engine correctly enforces — and 30/30 after the
correction; the investigation is journaled either way (invariant 2).
Declared limit: the annotations have not yet had an external Hive-literate
review. (Journal `H2-2026-09-09-corpus-run-01`.)

**4. Random invariant sessions.** Seeded random games across all 8 game
types check, after every transition: every generated move is accepted by
the apply path (and undo restores the exact GameString), the hive remains
connected, serialise→deserialise through the UHP GameString reproduces the
position, result, and exact valid-move set, and pass is accepted exactly
when no move exists. 10,665,686 generated moves were applied and undone
over 161,546 plies (deep session) with zero violations; a smaller session
runs in the standard suite on every build. (Journal
`H2-2026-09-09-random-invariants-01`.)

## Scope and honest gaps

Code coverage is not claimed as correctness evidence (plan ch. 4). The
lines above bound different failure modes (exhaustive-at-depth, agreement,
rules-text fidelity, invariant stability) but none proves full-game
perfection. Known issues found during profiling and deferred to the
pipeline phase, recorded as findings rather than silently fixed: the
*prior-work* self-play generators map their 300-ply cap to a draw
(invariant 7 forbids this in any new-study measurement code), and the Rust
ONNX CoreML execution provider currently crashes on the study machine
while the same model runs on CoreML through Python onnxruntime at 2.62
ms/eval. (Journal `H2-2026-09-09-throughput-profile-01`.)

## Cross-language data-path check

The grid arm's Rust plane encoder and the Python training-side decoder are
kept byte-identical, verified by a golden-file crosscheck (240 positions,
exact agreement) that runs in the nightly script. (Journal
`H2-2026-09-09-suite-rerun-01`.)
