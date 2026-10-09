# Protocol v2 (DRAFT, not frozen) — Study 2: grid vs. graph under a warm-started self-play loop with a replay window

**Status: DRAFT written 2026-10-09 for the human's review. Freezing it is
G-FREEZE; launching the campaign is G-SPEND. Until frozen, every value
below is a proposal.** Study 1 (protocol v1.0, frozen 2026-09-10,
sha256 f340a6b6…aefeb5) is complete and untouched; this document
describes a *new* study that reuses Study 1's frozen evaluation assets
without modifying them.

## 1. Why a second study

Study 1 rejected H1 under its pre-registered rule. Its pipeline trained
every generation's network from a fresh seeded initialisation on that
generation's 500 games only: no weight carry-over, no replay window.
The property is identical in both arms (the comparison stands) but it
bounds the regime reached, and it is the first objection a reviewer
will raise against the generality of the verdict. Study 2 asks whether
the ordering of the two representations survives the standard
AlphaZero-style regime: weights carried across generations and training
on a window of recent generations.

## 2. Research question and hypothesis

**RQ-H1′.** Under a warm-started self-play loop with a replay window,
at comparable training budget, does the graph architecture learn a
better policy than the grid architecture for base-game Hive?

**H1′.** Same statement as H1 (graph arm reaches a higher mean score
against the frozen population than the grid arm, at equal budget), under
the warm-started regime.

**Secondary question (interaction).** Does the graph−grid contrast move
toward zero or change sign relative to Study 1 (same opponents, same
openings, same evaluation settings)? Reported descriptively: the two
studies are not pooled.

H1′ is not presumed true. A negative or null result is a publishable
outcome.

**Rejection rule (proposed, identical in form to Study 1):** against
the frozen opponent population, under both budget readings, the graph
arm shows no seed-consistent advantage and the seed-level bootstrap
interval on the graph−grid score difference excludes a meaningful graph
advantage. Reported as-is. The largest upper bound of the intervals is
reported so that any threshold can be applied by the reader.

## 3. What changes relative to Study 1 (exactly two things, both arms)

1. **Warm start.** Generation g's training initialises from generation
   g−1's checkpoint (model weights only; the optimizer and the cosine
   schedule restart each generation, as in Study 1). Generation 0
   starts from the seeded random initialisation.
2. **Replay window.** Generation g trains on the records of generations
   max(0, g−W+1) … g with W = 3 *(proposal)*, i.e. up to 1,500 games per
   training pass; 2 epochs per generation as before, so the number of
   gradient steps grows with the window.

Everything else is Study 1's: engine, search (128/32 simulations,
playout-cap randomization, noise, temperature, resignation, 300-ply
truncation), record format, loss and masking, both encoders and
networks (1.44 M / 1.47 M), the shared decoder, the frozen opponent
population (D-017), the 250 frozen openings (D-025), the pinned
evaluation settings (D-019: 400 simulations, no noise, 100 paired games
per opponent), the seed derivation (base seed 100,000 × seed; new runs
use seeds 11–15 so that no random stream is shared with Study 1), and
the statistics (seed as the unit, 10,000-resample percentile bootstrap,
independent seed sets for the contrast, truncation as a separate
outcome with the four treatments).

**Hyperparameter policy (to decide at the freeze):** option A, zero
tuning as in Study 1 (symmetric, cheapest); option B, an identical
pre-registered budget of three learning rates (0.02, 0.01, 0.005) for
both arms on seed 11 only, the rate with the best final population
score per arm then used for seeds 12–15 — selection on a single seed,
disclosed, same budget both arms. Option B triples the cost of one seed
per arm (≈ +4 days). The draft recommends option A unless the human
wants the tuning objection closed as well.

## 4. Design and budget

- 2 arms × 5 seeds × 10 generations × 500 games (same example budget as
  Study 1, hence comparable per-example readings).
- Budget readings: same-examples at generation 10; same-wall-clock at a
  cutoff T*′ = median total training wall-clock of the five grid runs
  of Study 2, computed before any cross-arm comparison (rule stated
  here; value measured during the campaign).
- Expected cost (from Study 1's clocks plus training growth): grid
  ≈ 18–21 h per run, graph ≈ 27–52 h per run; ≈ 12–14 days of sequential
  laptop time for the ten runs, plus ≈ 1 day of evaluations; disk
  ≈ 2 GB. No paid resources.
- Evaluations: generations 5, 8 and 10 as in Study 1 (20/20/100 games
  per opponent), cutoff checkpoints at 100 games.

## 5. Pre-commitments

- All five seeds per arm enter the final analysis regardless of
  direction; no seed is dropped for its score; exclusion only for crash,
  corruption or engine error, each journaled.
- T*′ is computed once, from grid clocks only, before any cross-arm
  number is assembled, and never recomputed.
- Study 2's numbers are reported beside Study 1's, never pooled; the
  interaction question is descriptive.
- No opponent, opening, evaluation setting or network architecture is
  touched. Window size and the warm-start rule are frozen with this
  document.
- Write-as-you-go: the Study 2 chapter of the report is drafted from
  the frozen tables; the claims register gains rows before diffusion.

## 6. Deliverables

Result tables (both readings, per seed), arm contrasts, score-vs-time
figure, a Study 1 vs Study 2 comparison table, journal entries per
campaign and per analysis, a report chapter (EN + FR) and the article's
revision.

## 7. Stop rules

As Study 1: engine incorrect → suspend; budget hit → cut seeds (never
below 3 per arm), never honesty; two weeks without an interpretable
result → shrink and diagnose.
