# Chapter 5 — Experimental protocol (booklet draft, 2026-09-26)

*Source of authority: the frozen protocol v1.0 (D-020, sha256
f340a6b6…aefeb5) and the freeze/pin decisions D-017, D-019, D-025,
D-026, D-027. This chapter restates them for the reader; the frozen
document prevails on any divergence.*

## 5.1 Pre-registration discipline

Everything that could bias the comparison was frozen before any
comparison run existed, in this order: opponent population (D-017),
protocol with its rejection rule and measured budgets (D-020), fixed
shared openings (D-025); evaluation settings were pinned by config and
test (D-019). The same-wall-clock cutoff T\* was computed by a rule
stated in the pre-registered matrix — the median full-run wall-clock of
the grid arm's three runs — from grid clocks alone, before any
cross-arm number was assembled. No frozen artifact was modified at any
point; the repository history documents this.

## 5.2 Matrix, seeds, hardware, budgets

2 architectures × 3 training seeds (1–3; disjoint seed spaces), 10
generations × 500 self-play games per run at 128 full / 32 cheap
simulations per decision (measured choices, not the plan's placeholder
values), 300-ply cap. One machine (Apple M1 Pro, 10 cores, 16 GB), four
worker threads per run, runs sequential; each arm uses its measured best
inference provider (grid: CoreML at 2.62 ms/eval; graph: CPU at
3.67 ms/eval) — a real hardware interaction reported and charged, not
equalised away. Every run logs wall-clock per generation, states, and
simulations; checkpoints are kept at every generation.

## 5.3 Opponents, openings, pairing

The evaluation population is frozen: seeded legal-random (B-RND), a
documented fixed-weight heuristic (B-HEU; weights hash-pinned and
test-enforced), and 6400-simulation no-network MCTS (B-MCTS). The
gen-19 checkpoint of the prior demonstration loop is excluded (D-016/17).
Openings are 250 pre-generated, unique, legal 4-ply openings (seeded
generator, content hash recorded); every match plays pair *i* on opening
line *i* with colours swapped, so all arms, seeds and opponents face
identical opening/colour schedules (verified by schedule-hash test).

## 5.4 Metrics, intervals, exclusions

Primary metric: mean score (win 1 / draw 0.5 / loss 0) against the
population, per (seed, opponent) cell, **excluding truncated games**,
whose rate is always reported separately, with a truncations-as-0.5
sensitivity column and cap-treatment bounds (truncations as losses and
as wins) bracketing any alternative cap. The resampled unit is the
**seed**: cells aggregate games first; intervals are percentile
bootstrap (10,000 resamples) over the three seeds; the arm contrast
bootstraps both arms' seed sets independently. Games are never pooled
as i.i.d.; Elo, where printed by tooling, is descriptive only.
Checkpoint selection is mechanical: generation-10 checkpoints for the
same-examples reading; the last checkpoint completed at ≤ T\* for the
same-wall-clock reading. **Exclusion criteria:** none were needed — no
run failed, none was excluded, and a bad score is not an exclusion
criterion by protocol.

## 5.5 RQ → experiment → result matrix

| RQ | Experiment | Result artifact |
| --- | --- | --- |
| RQ-H1: does the graph arm beat the grid arm at comparable budget? | The H6 matrix under both readings vs the frozen population | Per-seed score tables + arm contrast with seed-bootstrap intervals (results-same-examples / results-same-wallclock / results-arm-difference); verdict via the frozen rejection rule |
| RQ-H2 (secondary): per-example vs per-hour reading | The same campaign read at generation-10 vs T\*-checkpoints | Score-vs-time curves (fig1); score/cost table (fig2) |
| RQ-H3 (secondary): what do graph components contribute? | Two one-component ablations at parity (A1 edge typing; A2 global pooling, substitution D-028) | Ablation table H-T3 (`results/ablations/`); A1' supplementary (two-component, clearly labeled) if run |

## 5.6 Reproduction

Every table and figure regenerates from scripts over raw per-game
records (`scripts/make_results.py`, `make_figures.py`); every run's
generator settings, seeds and model stamps live in per-run manifests;
commands, configs and seeds are annexed. The minimal reproduction
scenario (annex) replays a single recorded evaluation game
deterministically and regenerates the result tables from the shipped
records.
