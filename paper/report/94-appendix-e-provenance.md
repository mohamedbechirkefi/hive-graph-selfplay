# Provenance of every result {#sec:app-e}

This appendix is the one place in the report where internal identifiers are the point. It gives, for every table and figure, the generated artifact it was taken from, the raw records that artifact was computed from, and the journal entry that recorded the measurement; it then indexes the decision log, reproduces the claims–evidence register in full, and lists where the raw data live together with the hashes of every frozen artifact.

## The evidence chain

Every number in this report is reachable along one chain. **Raw per-game records** are written by the evaluation arena as one CSV per (checkpoint, opponent) pairing under the run directory; the file's header lines name both engine command lines verbatim (network path, simulation count, seeds), and every game carries its outcome with truncation as its own category. **Generated tables** are produced by `scripts/make_results.py`, which reads those CSVs and the per-run wall-clock logs, aggregates per (seed, opponent), bootstraps over seeds (10,000 resamples, seed as the unit, no game pooled as i.i.d.), and writes `results/comparison/*.{md,csv}`; it never retypes a number. **Figures** are produced by `scripts/make_figures.py` from the same CSVs, wall-clock logs and campaign logs. **The report** is assembled from these files; a source checker verifies that every numeric token in every chapter occurs in the evidence base, and a second checker verifies numeric identity between the English and French versions. The minimal reproduction script rebuilds the engine in a fresh clone, replays a recorded game to an exact match of its shipped row, and regenerates the tables byte-identically (verified 2026-10-09).
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-19-h6-comparison-01.md:38-41 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/scripts/make_results.py:4-7,79-87 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/final-control.md:13,20 -->

**Journals.** Every experiment or measurement has one entry under `journal/`, named `YYYY-MM-DD-<slug>.md` and carrying an identifier of the form `<phase>-<date>-<slug>-<nn>` (for example `H6-2026-10-09-5seed-final-01`). The header fixes id, date, hypothesis, git commit, configuration, seeds, data version, hardware, duration and cost; the body has fixed sections: Methods, Raw results and uncertainty, Failures, Limits and confounders, Interpretation, Decision, Artifacts. Negative results and tooling defects are entries like any other. **Decision log.** Every non-trivial decision is an entry `D-nnn` in the workspace file `state/decisions.md`, append-only: a reversed decision is never edited, a new entry supersedes it and links back. Gate crossings record the author's approval in its original wording. **Methodology log.** `docs/methodology-log.md` (workspace) records, append-only, every incident in which the method caught or missed something.
<!-- src: /Users/bechir/research/state/decisions.md:1-5 -->
<!-- src: /Users/bechir/research/docs/methodology-log.md:1-10 -->

## From each result to its artifact

`@tbl:prov-results`{=typst} covers the generated tables and figures; `@tbl:prov-method`{=typst} covers the validation, baseline, pipeline and encoder evidence cited in the method chapters, which lives in test suites, configurations and journals rather than in generated tables.

| Result in the report | Generated artifact | Raw input | Journal entry |
| --- | --- | --- | --- |
| Per-seed scores and truncation rates, same-examples reading (2 arms × 5 seeds × 3 opponents, 100 games each) | `results/comparison/results-same-examples.{md,csv}` | `data/runs/cmp-{grid,graph}-s{1..5}/eval/gen009-vs-{B-RND,B-HEU,B-MCTS}.csv` | `H6-2026-09-19-comparison-01` (3 seeds); `H6-2026-10-09-5seed-final-01` (final) |
| Per-seed scores and truncation rates, same-wall-clock reading | `results/comparison/results-same-wallclock.{md,csv}` | `eval/tstar-gen00N-vs-*.csv` of each run (the final checkpoint's files where the cutoff checkpoint is the last one) and `wallclock.json` | same two entries |
| Arm contrast graph − grid, both readings, bootstrap over seeds | `results/comparison/results-arm-difference.md` | the two CSV files above | same two entries |
| Equal-time cutoff T\* = 18.77 h and the checkpoint map at T\* | numbers in the journal; map re-derived by `make_results.py` | `wallclock.json` of grid s1–s3 (median of the three totals), then of every run | `H6-2026-09-16-progress-01`; re-derivation checked in `H6-2026-10-09-5seed-final-01` |
| Cap sensitivity bounds (every truncation scored as a win for the arm under test) | numbers in the journal | per-game records of the final evaluations | `H6-2026-09-19-comparison-01` |
| Cost table: parameters, best-provider inference, run wall-clock (self-play generation + training, evaluation excluded, mean over the five seeds), self-play cost (that wall-clock / 5,000 games), training-throughput benchmark (batch 128), population scores | `paper/figures/fig2-score-cost.md` (regenerated 2026-10-09 after a generator defect was found; see `@sec:working-method`{=typst}) | `wallclock.json` per run; `results-*.csv`; benchmark in `docs/representations/comparison-controls.md` | `H5-2026-09-10-encoders-01`; `H6-2026-09-19-comparison-01` |
| Score versus training wall-clock, all seeds, both arms, T\* marked | `paper/figures/fig1-score-vs-time.png` | `eval/*.csv` and `wallclock.json` per run | `H6-2026-09-19-comparison-01`; `H6-2026-10-09-5seed-final-01` |
| Grid planes versus cell graph for one position | `paper/figures/fig3-encodings.png` | schematic: a synthetic five-piece position drawn in the script; no measured quantity | `H5-2026-09-10-encoders-01` (encoding definitions) |
| Three failure positions F1–F3 | `paper/figures/fig4-failures.{md,png}` | `eval/gen009-vs-*.csv` and `results/comparison/openings-v1.txt`; each game reproduced deterministically and verified against its CSV row | `H6-2026-09-19-comparison-01` |
| Per-opponent score trajectories by generation, 5 seeds | `paper/figures/fig5-per-opponent.png` | `eval/{gen004,gen007,gen009}-vs-*.csv` and `wallclock.json` per run | `H8-2026-10-09-detailed-edition-01` |
| Epoch-1 policy top-1 and value accuracy by generation, 10 runs | `paper/figures/fig6-training-metrics.png` | `data/runs/campaign.log`, `data/runs/extension.log` (training logs of the 10 main runs) | `H8-2026-10-09-detailed-edition-01` |
| Final-evaluation truncation rate versus legal-random per run | `paper/figures/fig7-truncation.png` | `eval/gen009-vs-B-RND.csv` per run | `H8-2026-10-09-detailed-edition-01` |
| Ablation table: A1 divergence, A2 null effect, A1′ supplement | `results/ablations/README.md` | `data/runs/cmp-graph-{untyped,nogpool,untyped-clip}-s{1,2,3}/eval/` against the full graph arm's finals | `H7-2026-09-23-a1-divergence-01`; `H7-2026-10-02-a2-nogpool-01`; `H7-2026-10-09-a1prime-01` |
| Pipeline, architecture and chronology schematics | `paper/figures/fig8-pipeline.png`, `fig9-architectures.png`, `fig10-timeline.png` (`scripts/make_report_figures.py`) | the system documentation (`docs/inventory.md`), the journal headers and the decision log; no measured quantity | none |

Table: Provenance of every generated table and figure: the artifact it is taken from, the raw records that artifact is computed from, and the journal entry that recorded the result. Run directories are abbreviated as `eval/…` for `data/runs/cmp-<arm>-s<seed>/eval/…`. {#tbl:prov-results}
<!-- src: /Users/bechir/research/hive-graph-selfplay/scripts/make_figures.py:34-74,152-170,290-330,333-438 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/scripts/make_report_figures.py:1-10 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/figures/fig2-score-cost.md:1-13 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/scripts/make_results.py:4-7,29-72 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-09-h6-5seed-final-01.md:22-29 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-09-h8-detailed-edition-01.md:31-34 -->

| Evidence in the method chapters | Where it lives | Journal entry (date) |
| --- | --- | --- |
| Perft tables (8 game types), UHP conformance 21/21, differential fuzzing against two reference engines (27,829 positions at seed 20260909), plane-encoder crosscheck (240 positions) | test suites under `crates/`, `scripts/nightly.sh`, `scripts/crosscheck_planes.py` | `H2-2026-09-09-suite-rerun-01` (2026-09-09) |
| 30 hand-annotated critical positions, 30/30 after one setup-side correction | `tests/critical_positions/cases/*.toml`; `scripts/run_critical_corpus.py` | `H2-2026-09-09-corpus-run-01` (2026-09-09) |
| Zero invariant violations over 10.9M applied transitions | `crates/hive-core/tests/random_invariants.rs` | `H2-2026-09-09-random-invariants-01` (2026-09-09) |
| Throughput profile: 21.7 µs UHP round-trip; 2.62 ms (CoreML) versus 23.5 ms (CPU) per evaluation; game-length distribution behind the 300-ply cap | commands recorded inline in the entry | `H2-2026-09-09-throughput-profile-01` (2026-09-09) |
| CoreML inference restored in the Rust pipeline (MLProgram format) | `crates/hive-mcts/src/ort_eval.rs` | `H4-2026-09-09-coreml-fix-01` (2026-09-09) |
| Baseline definitions, characterisation round-robin, five tactical cases, weight pin | `configs/baselines/*.toml`, `docs/baselines.md`, `tests/tactical_positions/` | `H3-2026-09-09-baselines-01` (2026-09-09) |
| Pipeline pilot and the seven automated pre-training checks | `scripts/run_pilot.py`, `scripts/run_h4_checks.sh`, `data/runs/pilot0/` | `H4-2026-09-10-pilot-01` (2026-09-10) |
| Grid and graph encoders, capacity matching (1.44M vs 1.47M), cost asymmetries, property battery | `docs/representations/{grid,graph,comparison-controls}.md`, `python/hivenet/{graph_dataset,graph_model}.py` | `H5-2026-09-10-encoders-01` (2026-09-10) |
| Rust mirror of the graph encoder, golden crosscheck (160 positions), end-to-end graph arm through the same search | `scripts/crosscheck_graph.py`, `hive-nn` graph module | `H5-2026-09-10-graph-wiring-01` (2026-09-10) |
| Comparison matrix, opening generation, fixed-schedule harness test, campaign sizing | `configs/comparison-matrix.yaml`, `results/comparison/openings-v1.txt`, `results/comparison/opponents-manifest.md` | `H6-2026-09-10-matrix-01` (2026-09-10) |
| Report assembly checks and the staleness defect found by the render pass | `paper/final-control.md` | `H8-2026-10-09-detailed-edition-01` (2026-10-09) |

Table: Provenance of the method-chapter evidence (engine validation, baselines, pipeline, encoders, campaign design): the artifacts and the journal entry recording each measurement. {#tbl:prov-method}
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/claims.md:9-25 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-09-suite-rerun-01.md:1-12 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-10-h6-matrix-01.md:1-12 -->

## Decision index

`@tbl:prov-decisions`{=typst} lists the decision-log entries relevant to this study with their dates; entries D-002, D-013 and D-018 concern the other projects of the research programme and are omitted. Gate crossings are marked with their gate.
<!-- src: /Users/bechir/research/state/decisions.md:27-43,345-382,530-561 -->

| Entry | Date | Decision |
| --- | --- | --- |
| D-001 | 2026-09-09 | Goal-directed operating rules adopted: routing file, one executable document per phase, gates reserved to the human |
| D-003 | 2026-09-09 | The prior 19-generation self-play loop classified as a demonstration, not evidence; its checkpoint preserved |
| D-004 | 2026-09-09 | Protocol/validation ordering fixed (draft, then measure, then freeze); write-as-you-go and no-real-money rules added; gates park a phase, not the session |
| D-005 | 2026-09-09 | G-PUBLIC / G-SPEND: MIT licence; prior loop permanently stopped; sequential tracks |
| D-006 | 2026-09-09 | Private remotes; methodology documented; full French copy of each report |
| D-007 | 2026-09-09 | Study variant: base game only |
| D-008 | 2026-09-09 | Truncation convention: cap ≠ draw, separate reporting, sensitivity procedure |
| D-009 | 2026-09-09 | Novelty positioning: no pivot; scoped contribution claim against three closest works |
| D-010 | 2026-09-09 | Python–Rust binding by subprocess/UHP (21.7 µs round-trip), no in-process binding |
| D-011 | 2026-09-09 | Measured proposals: 128/32 simulations, 300-ply cap, two follow-up fixes |
| D-012 | 2026-09-09 | G-FREEZE review: protocol freeze deferred until after the pilots |
| D-014 | 2026-09-09 | Baseline definitions and budgets (legal-random, heuristic at depth 1, search at 6,400 simulations) |
| D-015 | 2026-09-09 | Shared action decoder: the (piece slot, destination) contract reused by both arms |
| D-016 | 2026-09-09 | Proposal to exclude the prior checkpoint from the frozen population |
| D-017 | 2026-09-09 | **G-FREEZE**: opponent population frozen, search opponent at 6,400 simulations, prior checkpoint excluded; hashes and engine commit b94e7c1 |
| D-019 | 2026-09-09 | Evaluation settings pinned: 400 simulations, no exploration noise, deterministic argmax |
| D-020 | 2026-09-10 | **G-FREEZE**: protocol frozen as v1.0 on the pilot's measured values; sha256 f340a6b6…aefeb5, commit 44a74ff |
| D-021 | 2026-09-10 | Grid representation reused as-is; frame-bounds check made an always-on assertion |
| D-022 | 2026-09-10 | Graph arm: cell graph, fixed-capacity tensors (node cap 224), Python-first with a Rust mirror |
| D-023 | 2026-09-10 | Symmetry augmentation excluded from the full method, both arms |
| D-024 | 2026-09-10 | **G-DESTRUCTIVE** (by the author directly): pre-study workspace archive deleted; research copy is the sole copy of the prior work |
| D-025 | 2026-09-10 | **G-FREEZE**: 250 shared openings frozen, generated blind; content sha256 63b318d0…5af7b |
| D-026 | 2026-09-10 | **G-SPEND**: main campaign approved at full size and launched |
| D-027 | 2026-09-16 | Evaluation volume kept at 100 games per pairing; seed variance dominates game noise |
| D-028 | 2026-09-19 | Ablation (a) substituted by A2 (global-pooling bias); A1 naive adjacency kept |
| D-029 | 2026-09-20 | **G-SPEND**: ablation campaign approved, both ablations at 3 seeds each |
| D-030 | 2026-09-26 | **G-SPEND**: supplementary two-component A1′ approved at its corrected sizing |
| D-031 | 2026-09-26 | **G-SPEND**: extension to 5 seeds per arm approved with three pre-commitments stated before any new run |
| D-032 | 2026-10-09 | Report scope: detailed edition, no frozen artifact, number or claim changed |

Table: Index of the decision-log entries relevant to this study, in order of recording. {#tbl:prov-decisions}
<!-- src: /Users/bechir/research/state/decisions.md:8-983 -->

## Claims–evidence register

`@tbl:prov-claims`{=typst} reproduces `paper/claims.md` with its section column removed; claim wording is compressed where needed, numbers are unchanged. The rule is: no row, no claim.

| Claim | Evidence | Limit |
| --- | --- | --- |
| The rules engine reproduces Mzinga's published perft tables for all 8 game types to depth 6 (depth ≤5 in the standard suite, depth 7 in nightly runs). | `H2-2026-09-09-suite-rerun-01` | depth-bounded node-count equality; d7 re-run not repeated on 2026-09-09 (d≤6 confirmed) |
| The engine passes the UHP conformance harness of the nokamute reference (21/21). | `H2-2026-09-09-suite-rerun-01` | conformance = protocol behaviour, not full rules proof |
| Per-ply legal-move sets are identical to both reference engines (MzingaEngine v0.16.0, nokamute 1.0.3) over seeded random games (27,829 positions at seed 20260909; 200/100 games/type in nightly). | `H2-2026-09-09-suite-rerun-01` | agreement with references, not with the rulesheet directly; random-walk coverage |
| The engine agrees with a 30-case corpus of hand-annotated critical positions whose expectations were committed before any engine run (30/30 after one setup-side correction). | `H2-2026-09-09-corpus-run-01`; `tests/critical_positions/` | corpus annotations not externally reviewed (declared limit); 30 cases at the low end of the 30–50 proposal |
| Seeded random-game sessions across all 8 game types show zero invariant violations over 10.9M applied transitions. | `H2-2026-09-09-random-invariants-01` | pseudo-random breadth, not adversarial depth; serialisation via UHP GameString only |
| The Rust and Python plane encoders agree exactly (240 positions, byte-identical planes). | `H2-2026-09-09-suite-rerun-01` | grid-arm encoder only at that date |
| A UHP subprocess round-trip costs ~22 µs (negligible against per-decision costs), so the Python↔Rust binding uses subprocess/UHP (no PyO3). | `H2-2026-09-09-throughput-profile-01`; D-010 | one machine (M1 Pro); revisit if Python ever enters a per-move loop |
| At the measured inference costs (2.62 ms/eval CoreML, 23.5 ms CPU, gen-19 net as workload), 128/32 sims with playout-cap randomization and a 300-ply cap are feasible for this study's compute envelope. | `H2-2026-09-09-throughput-profile-01`; D-011 | historical: proposals later pilot-confirmed and frozen (D-020); costs are net-specific |
| CoreML inference restored in the Rust pipeline (MLProgram fix): self-play at 128/32 sims costs ≈12 thread-s/game (≈3 s/game wall at 4 threads), vs ≈320 thread-s/game on the CPU fallback at 600/150. | `H4-2026-09-09-coreml-fix-01` | gen-19 net as workload; small probe counts; re-measured at the pilot |
| The heuristic baseline defeats legal-random 100–0 (100 paired games, 0 truncations); MCTS-without-network at 6400 sims scores 99.5% vs random and 37.5% vs the heuristic (−89 Elo [−150, −32]); a 4×-budget probe reaches 56.2%. | `H3-2026-09-09-baselines-01` | pilot volume (100 games/pairing); arena CI unpaired approximation; ordering finding diagnosed, not retuned; population since frozen (D-017) |
| The MCTS baseline solves all 5 hand-annotated tactical cases at 400, 1600 and 6400 sims, and value signs are pinned under player alternation. | `H3-2026-09-09-baselines-01`; `tests/tactical_positions/`; sign tests in `crates/*/tests` | 5 cases, unreviewed externally (declared limit) |
| All seven pre-training checks pass as automated tests on real self-play shards: zero illegal policy mass, id↔move identity, correct outcome perspective with truncation distinct, tiny-batch overfit (KL 0.09, argmax 15/15, value 15/15), bitwise save/resume, structurally-off eval noise, eval/training separation by audit. | `H4-2026-09-10-pilot-01`; `scripts/run_h4_checks.sh` | overfit criterion is KL to the soft-target entropy floor, not loss→0 |
| One generation of self-play from random init (300 games, 128/32 sims, 1.44M-param grid net) yields a net that beats legal-random 100–0 (28 wins, 2 truncations) while scoring 3.3% vs the heuristic and 3.3% vs 6400-sim MCTS: non-degenerate learning with a data/iteration-gap diagnosis. | `H4-2026-09-10-pilot-01`; `data/runs/pilot0/eval/` | single seed, 30 games/opponent, gen 0 only; not a study result |
| Gen-0 self-play truncates 56.7% of games at the 300-ply cap (170/300); generation cost ≈12 s/game wall (4 threads) at gen 0, falling toward ≈3 s/game with a trained net at the same budget. | `H4-2026-09-10-pilot-01`; `data/runs/pilot0/selfplay/gen000-manifest.json` | one machine, one seed; rates specific to random-init play |
| The two arms are capacity-matched to +1.5% (grid 1.44M, graph 1.47M params) behind the identical decoder, and the graph encoder loses no state information vs engine-generated records (property battery P1–P5, 300 real positions, zero illegal policy mass end-to-end). | `H5-2026-09-10-encoders-01`; `docs/representations/` | historical: Rust mirror + golden crosscheck landed green the same day (`H5-2026-09-10-graph-wiring-01`) |
| Best-available-provider inference costs differ ≈1.4× against the graph arm (grid 2.62 ms/eval CoreML vs graph 3.67 ms ORT-CPU), while CPU training throughput favours the graph arm 3.5× and MPS favours the grid arm 2×. | `H5-2026-09-10-encoders-01`; table in `comparison-controls.md` | one machine; reported, not equalised; feeds the same-wall-clock reading |
| The Rust and Python graph encoders agree exactly (160 positions across all 8 game types, byte-identical tensors, nightly-pinned), and the graph arm runs end-to-end through the identical Rust MCTS. | `H5-2026-09-10-graph-wiring-01`; `scripts/crosscheck_graph.py` | smoke-scale training; strength results belong to the comparison |
| **H1 is rejected under the pre-registered rule**: under both budget readings the graph arm shows no seed-consistent advantage against the frozen population, and every graph−grid interval excludes a meaningful graph advantage (largest upper bound +0.035). | `H6-2026-09-19-comparison-01`; `results/comparison/results-arm-difference.md` | 3 seeds/arm; one graph architecture at one capacity and budget; early-regime self-play (10 gens) |
| Arm contrast (seed-mean, bootstrap95 over seeds): vs B-RND −0.175 [−0.268, −0.007] (same-examples) and −0.158 [−0.254, −0.050] (same-wall-clock); vs B-HEU −0.085 [−0.143, −0.025] and −0.072 [−0.100, −0.028]; vs B-MCTS +0.005 [−0.020, +0.035] and −0.013 [−0.040, +0.015]. | `results/comparison/results-*.csv`; `H6-2026-09-19-comparison-01` | intervals over 3 independent seeds per arm |
| The graph arm truncates 20–57% of its games vs legal-random at the 300-ply cap (grid 0–1%); the rejection is cap-robust: scoring all truncations as graph wins leaves graph−grid at −0.072/−0.058 vs B-RND. | `H6-2026-09-19-comparison-01` (cap-sensitivity bounds); fig4-F1 | bound argument substitutes for a larger-cap re-run (stated) |
| Measured campaign costs: graph runs averaged 2.0× grid training wall-clock (36.7 vs 18.0 h per 10×500-game run, mean over 5 seeds, self-play + training, evaluation excluded; 3-seed figures were 35.7 vs 18.2 h); at T\* = 18.77 h the graph arm completes 3–6 of 10 generations (4–5 over the original three seeds). | `data/runs/cmp-*/wallclock.json`; `results/comparison/wallclock-per-run.md`; fig2 | one machine; per-arm best available provider (reported); the cost-table generator's divisor defect of 2026-10-09 affected only the previously printed means (30.0/61.2 h), never this ratio |
| All comparison artifacts were frozen before any comparison run (population D-017, protocol D-020, openings D-025), T\* was computed from grid wall-clocks before any cross-arm number existed, and no frozen artifact was touched. | D-017/D-020/D-025/D-026; `H6-2026-09-16-progress-01`, `H6-2026-09-19-comparison-01` | none |
| Ablation A1 (parity): removing geometric edge typing destroys trainability: NaN divergence at generation 0 in 3/3 seeds; typed edges contribute at minimum optimization stability; A1 eval tables are artifacts of a NaN policy and excluded as scores. | `H7-2026-09-23-a1-divergence-01`; `results/ablations/README.md` | mechanism (6× gradient scale on the shared matrix) is a grounded hypothesis, not a measured decomposition |
| Ablation A2: removing the global-pooling bias has no measurable effect: nogpool−full = −0.001 [−0.170, +0.165] (B-RND), −0.007 [−0.043, +0.030] (B-HEU), −0.013 [−0.043, +0.013] (B-MCTS); failure modes unchanged. | `H7-2026-10-02-a2-nogpool-01`; `results/ablations/README.md` | 3 seeds/cell; 0.10M param difference inherent to the component (reported) |
| **Final 5-seed analysis (pre-committed, D-031): H1 remains rejected.** Graph−grid contrasts: B-RND −0.169 [−0.272, −0.062] / −0.161 [−0.278, −0.048]; B-HEU −0.064 [−0.111, −0.017] / −0.059 [−0.087, −0.029]; B-MCTS −0.009 [−0.055, +0.028] / −0.018 [−0.066, +0.025] (same-examples / same-wall-clock); largest upper bound +0.028. Supersedes the 3-seed tables as the study's final numbers. | `H6-2026-10-09-5seed-final-01`; `results/comparison/` | seeds 4–5 collected after the 3-seed analysis (disclosed); T\* fixed at the pre-registered value |
| A1′ supplement (two-component: untyped edges + grad-clip): trains finite and scores within the full graph arm's band (all diff CIs straddle 0); with A1, the typed relations' measurable contribution at this scale concentrates in optimization stability; it is never attributed to typing alone (clip confound). | `H7-2026-10-09-a1prime-01`; `results/ablations/README.md` | 3 vs 5 seeds; wide intervals; confounded by construction |
| The working methodology (goal-level AI delegation under six human-only gates, file-based state, mechanical verification) caught at least five harness/process defects before they could contaminate results (pipeline deadlock, corpus setup error, eval-harness opponent defect, silent record-loss path, silent NaN divergence), each journaled at detection time. | `docs/methodology-log.md` (workspace); journals cited per incident in `@sec:working-method`{=typst} | process observations from one study; no counterfactual control |

Table: The claims–evidence register of this report, reproduced from the repository file with the section column removed. Every claim made in the body corresponds to one row; the limit column states what prevents a broader reading. {#tbl:prov-claims}
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/claims.md:7-36 -->

## Raw data, identifiers and frozen hashes

**Location and layout.** Raw records live on disk under `data/runs/` in the study repository; they are not under version control. There is one directory per training run, `cmp-<arm>-s<seed>`, with `<arm>` in {`grid`, `graph`} for the main comparison (seeds 1–5) and in {`graph-untyped`, `graph-nogpool`, `graph-untyped-clip`} for the ablations A1, A2 and A1′ (seeds 1–3), plus `pilot0/` for the pipeline pilot. Each run directory contains: `selfplay/gen00N-*.bin` (binary record shards of generation N, v3 format, model-stamped) with `gen00N-manifest.json` (network and its fingerprint, model generation, record version, game type, seed, game count, full and cheap simulation counts, full-move fraction, temperature plies, resignation settings, counts of resigned and truncated games, number of positions, shard list); `checkpoints/gen00N/` (`hivenet-e0.pt`, `hivenet-e1.pt`, `train-config.json`) and the exported `gen00N-b1.onnx` used for play; `eval/<checkpoint>-vs-<opponent>.csv` with its `.log` for the intermediate (gen004, gen007) and final (gen009) evaluations, and `eval/tstar-gen00N-vs-<opponent>.{csv,log}` for the equal-time cutoff checkpoint; and `wallclock.json`, the per-generation wall-clock in seconds from which every time figure and the cutoff are derived. Campaign-level logs are `data/runs/campaign.log` (main runs, seeds 1–3), `extension.log` (seeds 4–5), `ablations.log` and `tstar-evals.log`. Seed derivation: base seed = 100,000 × seed; generation g uses base seed + g; evaluation network seed 9000 + gen (finals) or 9500 (cutoff sets), opponent seeds 9101 (legal-random) and 9201 (search).
<!-- src: /Users/bechir/research/hive-graph-selfplay/scripts/run_comparison.py:1-35 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/scripts/make_results.py:4-7,29-72 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/annex-reproduction.md:33-41 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-10-h4-pilot.md:18-19,117-120 -->

**Volumes.** The main campaign comprised 10 generations × 500 self-play games per run (30,000 self-play games per three-seed arm at the 3-seed stage) and 100 paired games per (checkpoint, opponent) evaluation on the frozen openings; the campaign ran from 2026-09-10 12:42 to 2026-09-17 22:31 for seeds 1–3 (≈163 h of machine time including the cutoff evaluations), with seeds 4–5 collected 2026-09-27 to 2026-10-02. Disk footprint is recorded in the evidence base only as the launch estimates (≈3–5 GB for the main campaign, ≈3–4 GB for the ablations) against 164 GB free at launch with a 20 GB guard; exact per-run sizes were not journaled. Since the deletion recorded in D-024, the study repository is the sole copy of the pre-study material it inherited (the prior-loop checkpoint and its data, 412 MB and 75 MB), which is why those files are protected by the destructive-action gate.
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-19-h6-comparison-01.md:18-26 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-09-h6-5seed-final-01.md:12-13 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-10-h6-matrix-01.md:54-55 -->
<!-- src: /Users/bechir/research/state/decisions.md:729-753,888-915 -->

**Frozen artifacts and their hashes.** `@tbl:prov-hashes`{=typst} lists every frozen or pinned artifact with the identifier recorded at its freeze. The protocol hash is recorded in the decision log in abbreviated form; the full value was recomputed from the frozen commit while preparing this appendix and is identical to the hash of the current file, confirming that the protocol has not changed since its freeze.
<!-- src: /Users/bechir/research/state/decisions.md:492-527,598-633,755-785 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/results/comparison/opponents-manifest.md:10-44 -->

| Artifact | Frozen / pinned on | Identifier | Record |
| --- | --- | --- | --- |
| Protocol v1.0 (`docs/protocol.md`) | 2026-09-10 | sha256 f340a6b6…aefeb5 at commit 44a74ff (full: f340a6b64db0f5f0bf126ffb251c3de339450bde192fd54b719036a8a3aefeb5) | D-020 |
| Opponent B-RND (`configs/baselines/random.toml`) | 2026-09-09 | sha256 f2fc4a06441d3c1a7922838a6693dbb48ec54543bc34fd814d41c9a742514cd7 | D-017 |
| Opponent B-HEU (`configs/baselines/heuristic.toml`) | 2026-09-09 | sha256 7210a0a349c5bad5dcd2df099cc6865ee3cb5d8a2c30e106ce58137804818999 | D-017 |
| Opponent B-MCTS (`configs/baselines/mcts-nonet.toml`) | 2026-09-09 | sha256 3fc8f75cf2b4f21012dd61e9924408fbfc32c8ea561aa96eb44f1091ba07364e | D-017 |
| Heuristic weights (`configs/baselines/heuristic-weights.toml`) | 2026-09-09 | sha256 d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a; pinned by test `weights_pinned_for_h3_baselines` | D-014, D-017 |
| Engine code at the population freeze | 2026-09-09 | commit b94e7c1 | D-017 |
| Shared openings (`results/comparison/openings-v1.txt`, 250 lines) | 2026-09-10 | content sha256 63b318d071dfc3ecfae3585636c8e6f7327ddc08e7aed86a466f915f8005af7b; frozen-file sha256 538497390a3787299c67c3ca138b8feacb369d55dc562881d1aee45200cbccb2; generator seed 20260910; schedule hash 8cd84b6564440666 | D-025 |
| Evaluation settings (`configs/eval-settings.toml`) | 2026-09-09 | 400 simulations, no exploration noise, deterministic argmax, 300-ply cap | D-019 |
| Comparison matrix (`configs/comparison-matrix.yaml`) | 2026-09-10 | pre-registered sizes and the cutoff rule | D-026 |
| Equal-time cutoff T\* | 2026-09-16 | 18.77 h = median of the three original grid run totals (18.77, 16.73, 19.07 h) | `H6-2026-09-16-progress-01`; D-031 |
| Campaign and analysis code | 2026-09-10 → 2026-10-09 | campaign ac58773; analysis 1c65269 (3 seeds), 7db074d (5 seeds); ablations 216fded → bffeea9 (non-finite guard); A1′ queue 1fdd7ec | journals `H6-…`, `H7-…` |

Table: Frozen and pinned artifacts of the study with the identifiers recorded at their freeze (hashes, commits, seeds) and the decision-log or journal entry that records them. {#tbl:prov-hashes}
<!-- src: /Users/bechir/research/hive-graph-selfplay/results/comparison/opponents-manifest.md:10-44 -->
<!-- src: /Users/bechir/research/state/decisions.md:492-527,565-595,598-633,755-785,787-820,938-959 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-16-h6-progress-01.md:36-42 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-19-h6-comparison-01.md:10-11 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-09-h6-5seed-final-01.md:9-10 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-02-h7-a2-nogpool-01.md:9-10 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-09-h7-a1prime-01.md:7 -->
