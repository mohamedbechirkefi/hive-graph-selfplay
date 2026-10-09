# The Hive engine: design, implementation and validation {#sec:engine}

Every arm, opponent and evaluation in this study shares the engine. A self-play study trains on positions the engine itself generates and scores, so a rules defect would teach both arms the same wrong game and silently invalidate the comparison rather than merely adding noise. The engine was built in July 2026 as an independent project (`@sec:chronology`{=typst}) and validated along four independent lines on 9 September 2026, before any baseline or training work. This chapter covers its goals, architecture, board representation, move generation, validation, throughput, and the two fixes recorded before training. <!-- src: paper/method-validation.md:8-17 -->

## Design goals

The engine project fixed five goals. The first was rules fidelity: all eight game types of the Universal Hive Protocol, with exact agreement to the reference engine's published perft tables and per-ply agreement of legal-move sets with two independent reference engines as acceptance criteria. The second was protocol interoperability over standard input and output, so that MzingaEngine and nokamute can be driven as subprocesses. The third was staged strength: a classical alpha-beta engine with a handcrafted evaluation first, as sparring partner and test oracle, then AlphaZero-style tree search guided by a self-play-trained network (Silver et al., 2018). The fourth was single-machine feasibility, meaning an allocation-free Rust kernel, fixed-shape ONNX exports for the CoreML execution provider, and an inference go/no-go before any self-play. The fifth was verification built in from the start: unit tests per rule, perft fast in the standard suite and deep nightly, cross-engine differential fuzzing, make/unmake hash property tests, and a tactical regression suite. <!-- src: docs/PLAN.md:5-18,93-100 -->

Two further properties mattered more for the study than strength: the rules kernel performs no input or output and holds no global state, so one kernel referees arena games, generates self-play and serves the protocol; and every stochastic component is seeded, so any recorded game replays deterministically. <!-- src: docs/inventory.md:14; crates/hive-engine/src/main.rs:1-12 -->

## Architecture

The engine is a Rust workspace of small crates with one-way dependencies: the rules kernel at the bottom, protocol and evaluation above it, the two search backends above those, and the arena, self-play generators and shipped binary on top (`@tbl:engine-components`{=typst}). Three choices deserve a word. The classical search has no null-move pruning, because Hive's forced-pass states make tempo-based pruning unsound in exactly the positions that matter, the queen races; its quiescence covers only Hive's forcing moves, those landing on or beside the enemy queen. The network-guided search is generic over an evaluator with one output contract, so the handcrafted evaluation with uniform priors (the study's no-network opponent), the grid network on CoreML and the graph network on the CPU provider all run through the identical tree search. The self-play generator implements the KataGo economies of Wu (2020): playout-cap randomization, Dirichlet root noise, early-move temperature, and resignation with an audit fraction. Root noise stays off in every other backend. <!-- src: docs/PLAN.md:20-41; docs/inventory.md:12-21; crates/hive-search/src/lib.rs:1-6,231-232; crates/hive-mcts/src/lib.rs:1-12,90-104; crates/hive-selfplay/src/bin/selfplay_mcts.rs:1-7 -->

| Component | Role | Properties the study relies on |
| --- | --- | --- |
| Rules kernel | State, move generation, make/unmake, hashing, notation, perft, canonicalisation | No input/output, no global state; all eight game types; referees every game |
| Protocol server and client | Universal Hive Protocol over standard streams; subprocess driver for other engines | Every response block ends with `ok`; any backend plugs in behind one trait |
| Handcrafted evaluation | Static evaluation, negamax convention | Queen liberties dominant, piece activity, tempo; weights hash-pinned for the heuristic opponent |
| Classical search | Principal-variation search, iterative deepening | Lock-free shared transposition table (XOR-validated), lazy SMP, killer/history ordering, late-move reductions, aspiration windows; no null move; queen-targeting quiescence |
| Neural interface | 32×32 frame of 77 planes; 28,673-way (piece, destination) policy index; training records (112-byte one-hot, 176-byte with visit distribution, study version with model stamp, legal-index list, truncation outcome) | Byte-identical to the Python decoder (golden-tested) |
| Network-guided search | Batched PUCT tree search over an evaluator | Replay-based descent, virtual loss; three evaluators, one output contract; noise off unless self-play enables it |
| Match arena | Paired colour-swapped games from seeded random openings or a fixed file (pair *i* plays line *i*) | Every reply validated by the kernel; 300-ply cap a separate outcome, excluded from the score and reported as a rate |
| Self-play generators | Alpha-beta bootstrap data; tree-search self-play | Playout-cap randomization, root noise, temperature, resignation with audit; seeded |
| Shipped binary | Protocol front-end over all backends | Alpha-beta by default; tree search with heuristic, grid or graph network; legal-random; seed and simulation flags |

Table: Components of the engine, their roles, and the properties the study relies on. One rules kernel generates, referees and serves every game in this report; the three frozen opponents and both study arms are backends of the same binary. {#tbl:engine-components}

<!-- src: docs/inventory.md:12-21; docs/PLAN.md:15,26-36; crates/hive-uhp/src/lib.rs:1-5; crates/hive-uhp/src/server.rs:17-20,77-136; crates/hive-search/src/lib.rs:1-6,42,470; crates/hive-eval/src/lib.rs:1-7; crates/hive-nn/src/lib.rs:4-17,19-40,49-60; crates/hive-mcts/src/ort_eval.rs:1-6; crates/hive-mcts/src/graph_eval.rs:1-5; crates/hive-arena/src/main.rs:1-6,32-35,175,344-347; crates/hive-selfplay/src/main.rs:1-2; crates/hive-engine/src/main.rs:1-12 -->

## Board representation and hashing

Hive has no board: pieces define the playing surface, and a hive drifts across the plane as it grows. The engine nevertheless uses a fixed 64×64 grid of cells in axial coordinates, wrapping into a torus, on a counting argument: a hive contains at most 28 pieces, so it spans at most 28 cells along any axis, and on a 64×64 torus every local query (adjacency, slides, jumps) is indistinguishable from the same query on an infinite plane. Each cell stores its top piece, stacks live in a side table, and the maximum stack height is 7 (a ground piece under 4 beetles and 2 mosquitoes). <!-- src: crates/hive-core/src/hex.rs:1-6; crates/hive-core/src/board.rs:8-9,19-20; docs/PLAN.md:52; docs/inventory.md:23-25 -->

Because the hive never leaves the torus, coordinates never need renormalising during a game, which keeps the position hash fully incremental: make and unmake XOR the moved pieces' keys in and out, and no re-centring ever forces a recomputation or invalidates transposition-table entries. Translation symmetry is therefore irrelevant inside a search tree; canonicalisation under translation and the 12 hex symmetries is isolated at the boundary with the network frame and the opening book. The Zobrist hash is computed by a mixing function rather than lookup tables (a full table would be about 6 MB; mixing a packed (piece, cell, level) key costs about 2 ns with zero memory) and folds in the side to move, the last-moved piece and an early-game phase component. Repetition detection drops the phase component, so the same arrangement reached at different plies compares equal, but keeps side to move and last-moved piece, the stun rights, much as chess repetition keys keep en-passant rights; a third occurrence is a draw unless the game is already decided by surround. <!-- src: crates/hive-core/src/zobrist.rs:1-7; crates/hive-core/src/state.rs:91-116; crates/hive-core/src/canonical.rs:1-6; crates/hive-core/src/game.rs:12-13,75-81; docs/PLAN.md:88 -->

## Move generation and rule edge cases

Move generation follows the reference engine's conventions, because those are what its published perft tables count: the queen may not be placed on either player's first turn (the tournament opening rule), for identical in-hand bugs only the lowest ordinal is placeable, a player with no placement and no movement receives the single move `pass`, and a finished game generates no moves. <!-- src: crates/hive-core/src/movegen/mod.rs:3-7; tests/perft_fixtures.json:2-8; docs/PLAN.md:16 -->

Sliding and gate legality is evaluated on a *lifted* view of the board, the occupancy with the mover removed from its origin cell. On that view the **freedom-to-move** rule for a ground-level slide step reads: the destination must be empty, and of the two cells adjacent to both origin and destination exactly one must be occupied; with zero the piece would detach in transit, and with two the gate is too narrow to pass. The **height gate** for climbing moves (beetle and ladybug steps, both legs of a pillbug throw) blocks a step if and only if both common neighbours are strictly higher than both the level the mover starts above and the destination stack; the above-ground beetle gate of the tournament FAQ falls out of this rule without a special case. The **One-Hive** rule is an articulation-point computation: a ground-level piece may be lifted if and only if its cell is not a cut vertex of the occupied-cell graph, found by a lowlink depth-first search once per move generation; tops of stacks are exempt, since the cell keeps its node, and a pinned pillbug may still throw, since it does not itself move. <!-- src: crates/hive-core/src/movegen/mod.rs:18-24,39-58,324-327,362-363; crates/hive-core/src/onehive.rs:1-3; docs/PLAN.md:17 -->

The **stun rule** of the Pillbug expansion, under which a piece moved on the previous turn may neither move nor be moved, needs a single field: the piece physically moved or placed on the previous ply. A piece is stunned if and only if it is that piece and belongs to the side to move; a pillbug may not throw that piece; the stun lapses after one opponent turn; placement also sets the field. The **mosquito** copies each adjacent bug type and is a pure beetle on top of the hive; the **ladybug** moves exactly two steps on top and one down. Because mosquito multi-copy, ladybug multi-path and walk-versus-throw can derive the same move more than once, the generated list is sorted and de-duplicated; if it is then empty, `pass` is generated. <!-- src: crates/hive-core/src/state.rs:64-71,223-228; crates/hive-core/src/movegen/mod.rs:197-202,319,335-353,381-387; crates/hive-core/src/movegen/tests.rs:154-156,184-189; docs/PLAN.md:17 -->

### Why a (piece, destination) pair identifies a move

The policy spaces of both arms and the de-duplication above rest on the claim that (piece, destination cell) determines the successor state. A placement takes the piece from hand to an empty cell, so the pair fixes the result. A movement starts from the piece's current location, which the state determines uniquely, and ends on top of the destination stack, whose height the state also determines; so the pair fixes the board. The only way two distinct actions share a pair is a pillbug throw of a piece to a cell it could also have walked to. Both produce the same board, so the successors could differ only in the record of which piece moved last, and the engine stores only *which* piece moved, not how. That suffices: at the start of a player's turn, if the last-moved piece is their own, the opponent can only have thrown it, so it is frozen this turn; if it is the opponent's, the player's pillbug may not throw it either way, and nothing else depends on the distinction. Hence the walk–throw collision yields identical states, and a policy head indexed by (piece, destination) plus pass loses nothing. <!-- src: crates/hive-core/src/state.rs:36-38,64-71; crates/hive-nn/src/lib.rs:12-17; docs/PLAN.md:71 -->

## Validation campaign (September 2026)

All validation evidence was re-established on 9 September 2026 on the study machine, an Apple M1 Pro (10 cores, 16 GB), with the reference engines freshly fetched (MzingaEngine v0.16.0, the protocol's reference implementation, and nokamute 1.0.3 built from source), before any baseline or training work. Four lines of evidence bound four different failure modes; a fifth check pins the data path to the training code. <!-- src: journal/2026-09-09-suite-rerun-01.md:12-26; paper/method-validation.md:14-17 -->

### Perft against published tables

Perft counts legal-move paths to a given depth under the reference engine's conventions, so its published tables serve as ground truth; it is exhaustive within its depth, and any discrepancy in move generation (a missing move, an extra move, a wrong stacking rule) shifts a count. The standard suite checks depth ≤5 for all eight game types on every build, a dedicated run checks depth 6, and the nightly run checks depth 7. On 9 September 2026 the standard suite passed and the depth-6 run completed in 8.32 s with every count matching; depth 7 was not repeated that day, so the study claims depth ≤6, with depth 7 last matched in July 2026 (`@tbl:perft-base`{=typst}, `@tbl:perft-types`{=typst}). <!-- src: crates/hive-core/src/perft.rs:1-3; paper/method-validation.md:20-25; journal/2026-09-09-suite-rerun-01.md:32-33,51; docs/PLAN.md:106 -->

| Depth | Nodes |
| --- | ---: |
| 1 | 4 |
| 2 | 96 |
| 3 | 1,440 |
| 4 | 21,600 |
| 5 | 516,240 |
| 6 | 12,219,480 |

Table: Perft node counts for the base game, depths 1–6, as published for the reference engine and reproduced exactly by the rules kernel on 9 September 2026 (no queen on a player's first turn; identical in-hand bugs counted once; forced pass counts as one move; a finished game generates none). {#tbl:perft-base}

<!-- src: tests/perft_fixtures.json:2-10; docs/PLAN.md:16; journal/2026-09-09-suite-rerun-01.md:32-33 -->

| Game type | Depth 4 | Depth 5 | Depth 6 |
| --- | ---: | ---: | ---: |
| Base | 21,600 | 516,240 | 12,219,480 |
| Base+M | 45,414 | 1,252,800 | 34,233,432 |
| Base+L | 45,414 | 1,252,800 | 34,233,672 |
| Base+P | 45,414 | 1,255,932 | 34,395,984 |
| Base+ML | 86,400 | 2,725,920 | 85,201,200 |
| Base+MP | 86,400 | 2,730,888 | 85,492,248 |
| Base+LP | 86,400 | 2,730,240 | 85,457,136 |
| Base+MLP | 151,686 | 5,427,108 | 192,353,904 |

Table: Perft node counts at depths 4–6 for all eight game types (M = Mosquito, L = Ladybug, P = Pillbug), as published for the reference engine and matched by the rules kernel; the Mosquito and Ladybug variants share counts through depth 5 and separate only at depth 6, hence the depth-6 run. {#tbl:perft-types}

<!-- src: tests/perft_fixtures.json:10-17 -->

### Reference-engine agreement

The protocol conformance harness shipped with nokamute passed 21/21. More stringently, differential fuzzing plays seeded random games while asserting, after every ply, *set equality* of the legal-move sets returned by the engine and by a reference. At seed 20260909 with 25 games per game type, both references agreed on every one of 27,829 positions (the identical count is expected: same seed, same games); the nightly run repeats this at 200 games per type against nokamute and 100 against MzingaEngine. Agreement with two independent code bases bounds a misreading shared with the engine, not one shared by the whole community of implementations, which the next line addresses. <!-- src: journal/2026-09-09-suite-rerun-01.md:30-41,49; scripts/nightly.sh:18-22; paper/method-validation.md:27-34 -->

### The hand-annotated critical corpus

Thirty critical positions were annotated by hand from the publisher's rules: the base-game rulesheet cited by page, the Pillbug sheet, and the World Hive Tournaments rules FAQ for above-ground gates and stun clarifications. The tournament opening rule was declared as the study's convention. Every expectation was written from the rules text, never from or against the engine, and the corpus was committed before the first run. Each case is a protocol move sequence from the empty board, hence reachable and independently checkable, with an expectation of one of seven kinds: the exact move set of a focal piece (possibly empty), a single move legal or illegal, every move a placement of a named piece, no movement moves, forced pass, or a terminal state. The runner drives the engine over the protocol, resolves move strings to cells with a geometry-only parser that knows no game rules, and compares (piece, destination) sets. `@tbl:corpus-coverage`{=typst} lists the coverage; the full corpus with every justification is in `@sec:app-a`{=typst}. <!-- src: tests/critical_positions/README.md:3-9,13-27,45-54,56-79; journal/2026-09-09-corpus-run-01.md:20-31 -->

| Rule area | Cases |
| --- | --- |
| Opening and placement rules | C001–C005 |
| Sliding, freedom to move, gates | C006–C012 |
| Beetle and stacking, beetle gate above ground level, stack colour | C013–C018, C028 |
| One-Hive, rings, grasshopper cut point | C019–C020, C027 |
| Terminal states: win, draw by simultaneous surround | C021–C022 |
| Forced pass | C023 |
| Pillbug ability, stun, just-moved guards (kernel guards, Base+P) | C024–C026 |
| Spider step count; queen move enumerations | C008, C029; C006, C011, C030 |

Table: Coverage of the 30-case hand-annotated critical corpus by rule area, with case identifiers as used in the corpus appendix. Expectations were written from the publisher's rules and committed before any engine run; three Pillbug cases guard the shared kernel's stun logic and lie outside the study's base-game perimeter. {#tbl:corpus-coverage}

<!-- src: journal/2026-09-09-corpus-run-01.md:25-31; tests/critical_positions/README.md:19-21 -->

The first run returned 29 passes and one setup error. The disputed case was the simultaneous-surround draw: its setup moved the black queen one step with both flanking cells empty, so the hive would have been "left unlinked while the piece is in transit", which is precisely the illegal-move example the rulesheet gives for the One-Hive rule; the engine's rejection was the rule-mandated behaviour. The disagreement was resolved *against the corpus*: the setup was rerouted through an intermediate cell so every step keeps an occupied flanking cell, the expected outcome (a draw) was left unchanged, and the correction was documented in the case file. The second run returned 30/30. The record of the corpus being wrong is kept deliberately: committed-before-run expectations cut both ways. Two limits are declared: no external review by a Hive-literate reader yet, and 30 cases sit at the bottom of the 30–50 range the research plan proposed; the strongest cases are the enumerations (13 destinations in one sliding case, 6 in a beetle case). <!-- src: journal/2026-09-09-corpus-run-01.md:35-61; tests/critical_positions/cases/C022-*.toml (setup correction note); tests/critical_positions/README.md:81-87 -->

### The tactical suite

A second hand-annotated set verifies the *search* rather than the rules. It holds five positions with a known good outcome: a win in one by a walking piece and by a jumping piece, each for both colours, and a position where the mover must avoid completing its own queen's surround. Since several pieces can often reach the winning cell, expectations are destination-based: the searcher's move must, or must not, land on a named cell. The network-free tree search solved 5/5 at 400, 1,600 and 6,400 simulations. Value signs under player alternation are covered by automated tests (the evaluation negates when the side to move flips; mate-in-one scores and root values are positive for the mover, both colours). One setup slip, a piece-ordering error in one case, was caught at the first run because the cases had been committed beforehand; the engine was right, so the setup was corrected and the incident recorded. The same external-review limit applies. <!-- src: tests/tactical_positions/README.md:3-14,41-53; journal/2026-09-09-baselines-01.md:29-31; ../docs/methodology-log.md (entry dated 2026-09-09, tactical set) -->

### Random invariant checks

Seeded random games across all eight game types check four invariants after every transition: every generated move is accepted by the apply path and undo restores the exact game string; the hive remains connected; the protocol game string round-trips to the same position, result and sorted legal-move set; and pass is played exactly when the move list is empty. A violation would halt with game type, seed, game, ply and game string for archiving as a regression case; none arose (`@tbl:invariants`{=typst}). The default run is in the standard suite on every build, the deep run in the nightly script. <!-- src: journal/2026-09-09-random-invariants-01.md:20-27,36-38 -->

| Run | Games | Plies walked | Generated moves applied and undone | Violations | Duration |
| --- | --- | ---: | ---: | ---: | ---: |
| Default (every build) | 4 per type × 8 types, ≤150 plies | 4,029 | 253,936 | 0 | 2.7 s |
| Deep (nightly) | 3 rounds × 20 per type × 8 types, ≤400 plies | 161,546 | 10,665,686 | 0 | 214 s |

Table: Seeded random-game invariant checks of 9 September 2026 over all eight game types (apply/undo exactness, hive connectivity, game-string round trip, pass exactly when no move exists). Deterministic given the seeds; durations on the study machine. {#tbl:invariants}

<!-- src: journal/2026-09-09-random-invariants-01.md:14,31-34 -->

### Cross-language data-path check and scope

The grid arm's plane encoder in Rust and the decoder in the Python training code are required to be byte-identical; a golden-file crosscheck over 240 positions confirmed exact agreement on 9 September 2026 and runs nightly. The graph encoder built on 10 September received the same treatment, with 160 of 160 positions across all eight game types agreeing exactly on the first run. <!-- src: journal/2026-09-09-suite-rerun-01.md:37; paper/method-validation.md:77-80; journal/2026-09-10-graph-wiring-01.md:36-38 -->

These lines bound different failure modes (exhaustiveness at depth, agreement with references, fidelity to the rules text, search correctness, invariant stability), but none proves full-game perfection, and code coverage is deliberately not claimed as correctness evidence. The stop rule that an incorrect engine suspends all training-side work was not triggered; baseline and pipeline work proceeded the same day. <!-- src: paper/method-validation.md:62-67; journal/2026-09-09-suite-rerun-01.md:55-59 -->

## Throughput profile

Before any simulation budget or move cap was fixed, the engine's costs were measured on the study machine with short runs on the existing binaries, the prior loop's generation-19 checkpoint serving only as a realistic inference workload (`@tbl:throughput`{=typst}). <!-- src: journal/2026-09-09-throughput-profile-01.md:9-27 -->

| Measurement | Value |
| --- | --- |
| Perft(5), base game | 516,240 nodes in 1.36 ms (≈380 MN/s) |
| Perft(6), base game | 12.2 M nodes in 26.5 ms (≈461 MN/s) |
| Alpha-beta, opening position, depth 10 | 7.20 Mnps |
| Alpha-beta, midgame position, depth 8 | 4.67 Mnps |
| Alpha-beta decision at depth 4 | ≈40 ms, single thread |
| Full games at depth 4 (6 threads, 100 games) | 22 s wall, 4.6 games/s, 4,397 recorded positions |
| Game length at depth 4 (30 seeded games) | mean 55.0, median 39, 90th percentile 80, maximum 202 plies; none reached the 300-ply cap |
| Network inference, Python ONNX package, CPU provider, batch 1 | 23.5 ms per evaluation (43 evaluations/s) |
| Network inference, Python ONNX package, CoreML provider, batch 1 | 2.62 ms per evaluation (382 evaluations/s) |
| Network inference, Rust bindings, CoreML provider | crashed (fixed below) |
| Protocol round trip from Python | 21.7 µs per `validmoves` (46,051 requests/s); 21.6 µs per play–undo pair |

Table: Throughput profile measured on 9 September 2026 on the study machine (Apple M1 Pro, 10 cores, 16 GB), release builds, profiling seed 20260909, game-length seeds 1001–1030 (lengths include 6 random opening plies); network inference measured with the prior loop's generation-19 checkpoint (77×32×32 input) as workload. {#tbl:throughput}

<!-- src: journal/2026-09-09-throughput-profile-01.md:15,32-60,72-75 -->

Three conclusions followed, each a measured proposal later confirmed by the pilot and frozen in the protocol. Legal-move generation is nowhere near a bottleneck; network evaluation dominates every decision, and the CoreML path decides feasibility: at 2.62 ms per evaluation a 128-simulation decision costs about 0.34 s and a 64-simulation decision about 0.17 s on one thread, whereas the CPU path is about 9× slower. The observed game lengths supported a 300-ply cap, above the observed maximum of 202 yet bounded, with truncation as its own outcome. Lastly, a protocol round trip at 21.7 µs is three to four orders of magnitude below any per-decision cost; since self-play generation lives entirely in Rust and exchanges data with Python through binary shard files, no in-process binding was built. <!-- src: journal/2026-09-09-throughput-profile-01.md:106-125; state/decisions.md:254-312 -->

## Two engine-side fixes recorded before training

Profiling surfaced two defects, each recorded as a finding first and fixed afterwards in the study's own code rather than silently patched. <!-- src: journal/2026-09-09-throughput-profile-01.md:77-93; paper/method-validation.md:64-73 -->

**CoreML execution provider.** The Rust inference path panicked on the study machine with the message "Unable to compute the prediction using a neural network model", while the Python ONNX package ran the same model on CoreML at 2.62 ms per evaluation (55 of 64 nodes on CoreML, 5 partitions). The message names the cause: the Rust bindings (version 2.0.0-rc.12) default to CoreML's legacy *NeuralNetwork* format, whereas the Python package uses *MLProgram*. Requesting MLProgram, a one-option change, restored CoreML inference, verified on 9 September 2026 with the self-play generator: at 600 full and 150 cheap simulations, 2 games on 2 threads took 44 s (≈44 thread-seconds per game, against ≈320 on the CPU fallback and ≈150 on the prior loop's working path); at the study's eventual 128/32 budget, 8 games on 4 threads took 24 s, about 3 s of wall-clock and 12 thread-seconds per game, which put a 2000-game generation at roughly 1.7 h. The full test suite, the tactical suite (5/5) and the critical corpus (30/30) were green after the change. These probes are feasibility anchors; the pilot re-measured with the study's own networks. <!-- src: journal/2026-09-09-coreml-fix-01.md:10,20-37,51-55; journal/2026-09-09-throughput-profile-01.md:79-86; crates/hive-mcts/src/ort_eval.rs:26-35 -->

**Truncation is not a draw.** Both prior-work generators capped games at 300 plies and mapped the cap to a draw, and the tree search's internal rollouts capped at 120 plies. Scoring a truncated game as a draw would let the cap manufacture or erase an advantage undetected, so the study's convention, fixed on 9 September 2026 before any measurement code was written, makes truncation a fourth outcome category everywhere: excluded from the primary score, reported as a separate rate, scored 0.5 in a sensitivity check. The prior-work code was left as a recorded finding; the study's record format carries a distinct truncation value in the outcome byte, the arena excludes truncated games from the score and reports the rate, and training excludes truncated records from the value loss. All of this landed with the study's record format on 9–10 September 2026, before the pilot. <!-- src: journal/2026-09-09-throughput-profile-01.md:87-93; state/decisions.md:184-212; crates/hive-selfplay/src/main.rs:90-99; crates/hive-arena/src/main.rs:344-347; journal/2026-09-10-h4-pilot.md:24-30 -->

With the engine validated, profiled and corrected on these two points, the study-specific pipeline, the opponents and the two encoders were built on top of it; the following chapters describe them.
