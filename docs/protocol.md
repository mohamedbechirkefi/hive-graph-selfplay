# Protocol — Graph-Based Self-Play for Hive under Limited Compute

**Status: DRAFT (not frozen).** Version 0.2, 2026-09-09. This document is
frozen only through G-FREEZE with explicit human approval (pipeline H1
task 9). H2's measured values are now incorporated as labeled *measured
proposals* (D-011) — the freeze review confirms them after the pilot; the
frozen version contains no placeholders (D-004). Any number inherited from the research plan is labeled
*(planning proposal)*. After the freeze, any change to this document
constitutes a new study.

## 1. Research question and hypothesis

**RQ-H1.** At comparable training budget, does a graph architecture learn a
better policy than a grid architecture for base-game Hive, within an
AlphaZero-style self-play pipeline (plan ch. 3)?

**Hypothesis H1.** A simple message-passing graph network, receiving the hive
as a graph, reaches a higher mean score against a fixed opponent population
than a grid CNN receiving the 32×32 BFS-unwrapped frame, at equal training
budget.

H1 is **not presumed true**. Hive's geometric relations, stacking (beetle
climbs), and *empty* candidate destinations must all be represented
correctly, and a naïve adjacency graph over occupied cells may not suffice —
destinations and sliding constraints are properties of empty space that a
piece-adjacency graph does not natively carry (plan ch. 3). A negative or
null result is a publishable outcome of this study; the work does not need
to confirm H1 to count (plan ch. 3).

**What would reject H1** *(operationalization proposed by the runtime; the
human confirms or amends it at the G-FREEZE review)*: against the frozen
opponent population, under **both** budget readings of §5, the graph arm
shows no seed-consistent advantage (no consistent per-seed ordering in its
favour), **and** the interval on the score difference — computed with the
resampling unit stated in §6 — excludes a meaningful graph advantage. That
outcome is reported as-is: "at this budget, on this variant, the graph
representation did not help."

**Secondary question (strictly time-permitting, plan ch. 3):** whether the
graph representation is more robust to board translation / symmetry than the
bbox-centered grid. No deliverable depends on it; it is dropped first under
schedule pressure (invariant 11 / plan ch. 16 stop rules).

## 2. Variant

The study uses the **base game only** — queen, spider, beetle, grasshopper,
ant; no Mosquito/Ladybug/Pillbug. The engine supports all 8 game types, so
this is a scope decision, not a constraint: expansions are outside the study
perimeter (decision D-007; plan ch. 3 recommendation). Engine-level tests may
still exercise expansion rules to guard the shared kernel; no *study* result
involves an expansion.

## 3. Truncation convention

Self-play and evaluation games are truncated at a move cap of **300
plies** *(measured proposal, D-011: beyond the largest observed game — 202
plies; median 39, p90 80 over 30 profiled games — journal
H2-2026-09-09-throughput-profile-01; the G-FREEZE review confirms it after
the pilot)*.

- A truncated game is **never an official draw** (invariant 7). Truncations
  form their own outcome category everywhere: in training-data generation
  statistics, in evaluation tables, and in the report.
- **Separate reporting rule:** every result table reports win/draw/loss rates
  *and* the truncation rate as a fourth, separate figure.
- **Sensitivity procedure:** the primary metric is recomputed under at least
  two cap treatments — the protocol cap and a substantially larger cap
  *(≥2 treatments: planning proposal)* — on the same evaluation games where
  feasible, otherwise on a dedicated re-run. If the conclusion's direction
  changes with the cap, that fragility is itself a reported finding.
- Decision D-008 records the convention; the scoring of truncations for the
  primary metric is defined in §4.

## 4. Primary metric and evaluation population

**Primary metric (plan ch. 7):** mean score against a **fixed opponent
population**, scoring win = 1, draw = 0.5, loss = 0. Truncated games are
excluded from the mean score and reported via their separate rate (§3); a
sensitivity check additionally scores truncations as 0.5 to bound their
influence *(procedure: planning proposal)*.

**Evaluation population:** the baseline opponents frozen in phase H3
(legal-random, documented heuristic, MCTS-without-network — inventory task
classification), plus any checkpoints explicitly frozen for evaluation (plan
ch. 7). That population is frozen under G-FREEZE in H3; **after the freeze no
opponent is added, removed, retuned, or re-versioned**. Evaluation games use
paired positions: both arms (and both colours) play the same pre-drawn
openings.

**Elo demotion:** if an Elo-style rating is computed, it is descriptive,
relative to this population only, and never a headline number.

## 5. Budget accounting

Every run reports: **wall-clock time, hardware (machine, cores, accelerator),
number of training states consumed, and MCTS simulations per decision**
(plan ch. 6).

The comparison is read under **two mandatory budget equalisations** (plan
ch. 6):

1. **Same number of examples** — both arms train on the same number of
   self-play states (and the same simulation budget per decision).
2. **Same wall-clock** — both arms get the same hours on the same hardware; a
   graph net that is better per example but slower per example can lose this
   reading, and both readings are reported side by side.

**Simulation budgets:** from H2 profiling *(measured proposal, D-011;
journal H2-2026-09-09-throughput-profile-01)*: **full/cheap = 128/32
simulations per decision with playout-cap randomization**, conditional on
the CoreML execution provider being restored in the Rust pipeline (measured
2.62 ms/eval vs 23.5 ms CPU-only); fallback 64/16 if the pilot's wall-clock
demands it. The plan's 64/128 were placeholders, superseded by this
measured proposal; the G-FREEZE review confirms the final values after the
pilot. Profile first, optimize only measured bottlenecks (plan ch. 4).

## 6. Seeds, pairing, and uncertainty

No conclusion from one seed (invariant 8). Each arm trains **≥3 independent
seeds** *(count: planning proposal — fixed at the freeze from H2's measured
cost per run)*. Results are reported per seed, with the seed as the primary
resampling/analysis unit: evaluation-game scores are aggregated to one score
per (seed, opponent) cell first; the interval on the graph−grid score
difference is computed over seeds with pairing preserved (same evaluation
openings across arms), e.g. bootstrap over seeds / paired comparison *(exact
interval method confirmed at the freeze)*. Thousands of games from one model
never substitute for independent training runs (plan ch. 7, [S4]).

## 7. Architectures and shared machinery

Exactly **two** learned architectures:

- **Grid arm:** the existing CNN over the 32×32 BFS-unwrapped, bbox-centered
  frame (hive-nn).
- **Graph arm:** one simple message-passing network with edge attributes,
  global aggregation for the value head, per-candidate-action scoring for the
  policy *(starting shape per plan ch. 6; GraphSAGE [S3] is reading, not a
  prescription)*.

Both arms share: the same engine, the same MCTS, the same **action decoder**
over the (rel_piece, dest) move space, the same training loop, budgets,
gating and evaluation harness. Only the state encoder and network body
differ. Fairness is invariant 6: same budgets, same attempt counts, no
per-arm tuning asymmetry beyond what the protocol states.

## 8. Exclusions

Outside the study perimeter (plan ch. 3; inventory):

- The Mosquito/Ladybug/Pillbug expansions as study variants (§2).
- MuZero-style extensions (learned models of dynamics).
- The web UI (`web/`) and `crates/hive-api` — frozen, not deleted.
- Any architecture beyond the one grid net and one simple GNN of §7.
- The prior RL loop's results — demonstration, not evidence (D-003).

## 9. Fallback

If self-play remains too costly at measured throughput (plan ch. 7): study
the representations by **supervised learning / distillation on a fixed corpus
of MCTS evaluations**, then measure the effect in play against the frozen
population. Any such result is labeled honestly as supervised/distillation
evidence — never presented as self-play learning-efficiency evidence.

## 10. Novelty positioning

The lit-review matrix (`docs/reading/matrix.md`, 11 works, 2026-09-09)
records what exists on Hive AI, GNN game-playing, variable-board games, and
variable-action policy learning. Verdict (decision D-009): no identical
comparison exists — no pivot — but the claim is **scoped**: this is not the
first grid-vs-graph comparison in a board game (Keller et al. 2023 did it
for Hex under RainbowDQN; Rigaux & Kashima 2024 for chess). The contribution
is the first controlled, budget-matched, multi-seed grid-vs-graph comparison
**for Hive** — frameless board, stacking, (piece, destination) actions —
with both arms under the same AlphaZero-style self-play pipeline. AZ-Hive
(de Goede et al. 2022: all-grid encoding study, engines below plain MCTS)
motivates the question and is the baseline-arm reference. Positioning claims
in the report cite matrix rows only.

## 11. Freezes this protocol declares

- **This document** — frozen at H1 task 9 (G-FREEZE), after §3/§5 values are
  measured in H2.
- **Opponent population** — frozen in H3 (G-FREEZE) before any comparison.
- **Evaluation/test positions** — frozen in H6 (G-FREEZE) before the
  controlled comparison.

Touching any frozen artifact afterwards = a new study (workspace CLAUDE.md).
