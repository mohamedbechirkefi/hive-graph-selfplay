# Protocol v2 — Study 2: grid vs. graph under a warm-started self-play loop with a replay window

**Status: FROZEN — version 2.0, frozen 2026-10-13 (G-FREEZE, D-038).**
Frozen by explicit user approval ("gèle A, W=3", 2026-10-13) after the
pilot confirmed every measured value (journal H9-2026-10-12-pilot-01,
D-037): hyperparameter policy option A, replay window W = 3. No
placeholders remain. **Any later change to this document constitutes a
new study** (workspace G-FREEZE rule). The freeze record, with this
file's hash and commit, is decision D-038 in `../../state/decisions.md`.
Study 1 (protocol v1.0, frozen 2026-09-10, sha256 f340a6b6…aefeb5,
D-020) is complete and untouched; this document describes a new study
that reuses Study 1's frozen evaluation assets without modifying them.

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

**H1′.** Same statement as H1 (the graph arm reaches a higher mean score
against the frozen opponent population than the grid arm, at equal
budget), under the warm-started regime.

**Secondary question (interaction).** Does the graph−grid contrast move
toward zero or change sign relative to Study 1 (same opponents, same
openings, same evaluation settings)? Reported descriptively: the two
studies are not pooled.

H1′ is not presumed true. A negative or null result is a publishable
outcome.

**Rejection rule (identical in form to Study 1's, protocol v1.0 §1):**
against the frozen opponent population, under both budget readings of
§4, the graph arm shows no seed-consistent advantage (no consistent
per-seed ordering in its favour), and the seed-level bootstrap interval
on the graph−grid score difference excludes a meaningful graph
advantage. That outcome is reported as-is. The largest upper bound of
the intervals is reported so that any threshold can be applied by the
reader. Intermediate evaluations (20 games per opponent) are
descriptive and enter no verdict.

## 3. What changes relative to Study 1 (exactly two things, both arms)

1. **Warm start.** Generation g's training initialises from generation
   g−1's final checkpoint (model weights only; the optimizer and the
   cosine schedule restart each generation, as in Study 1). Generation 0
   starts from the seeded random initialisation.
2. **Replay window W = 3.** Generation g trains on the records of
   generations max(0, g−2) … g: 500 games for g = 0, 1,000 for g = 1,
   1,500 from g = 2 on; 2 epochs per generation as before, so the number
   of gradient steps grows with the window.

**Hyperparameter policy: option A (decided by the human at the
freeze).** No tuning. Both arms keep Study 1's training settings
unchanged: learning rate 0.02, batch 256, weight decay 1e-4, value-loss
weight 0.6, 2 epochs per generation, cosine schedule restarted each
generation, masked policy loss; grid 96 channels × 8 blocks, graph 152
hidden × 8 layers. The rejected alternative, option B, was an identical
pre-registered budget of three learning rates (0.02, 0.01, 0.005) per
arm on seed 11 only, the best rate per arm then used for seeds 12–15;
it was rejected because it triples the cost of one seed per arm (about
four more days), selects on a single seed, and the pilot showed no
optimisation instability under the warm-started regime. The tuning
objection therefore remains open and is stated as a limit.

**Implementation (journal H9-2026-10-09-driver-01).** The two changes
are the driver options `--warm-start` and `--window 3` of
`scripts/run_comparison.py`, identical for both arms and off by
default; `scripts/test_driver_equivalence.py` shows that the default
command lines reproduce Study 1's recorded configs and manifests. Study
2 runs are written under `data/runs/cmp2-<arm>-s<seed>` (option
`--run-prefix cmp2`), each with a `driver-config.json` recording the
regime, so Study 1's directories are never touched. The pilot
(H9-2026-10-12-pilot-01, D-037) ran the full path on both arms and the
H4 check battery passes on the windowed shard sets (the stamp check
takes the manifests of every generation in the window).

Everything else is Study 1's: engine, search (128/32 simulations,
playout-cap randomization, noise, temperature, resignation, 300-ply
truncation), record format, loss and masking, both encoders and
networks (1,443,168 / 1,465,452 parameters), the shared decoder, the
frozen opponent population (D-017), the 250 frozen openings (D-025),
the pinned evaluation settings (D-019: 400 simulations, no noise, 100
paired games per opponent), the seed derivation (base seed 100,000 ×
seed; new runs use seeds 11–15 so that no random stream is shared with
Study 1), and the statistics (seed as the unit, 10,000-resample
percentile bootstrap, independent seed sets for the contrast,
truncation as a separate outcome with the four treatments).

## 4. Design, budget and evaluation schedule

- **Design.** 2 arms × 5 seeds (11–15) × 10 generations × 500 games:
  the same example budget as Study 1, hence comparable per-example
  readings. The driver indexes generations 0–9 (`gen000` … `gen009`);
  "generation 10" in this document is index 9, the final checkpoint.
- **Budget readings.** Same-examples: final checkpoints (index 9).
  Same-wall-clock: the checkpoint of each run completed at or before the
  cutoff T*′. **T*′ = median of the total training wall-clock of the
  five Study 2 grid runs**, each total being the sum of the ten
  per-generation entries of the run's `wallclock.json` (self-play,
  training and export; evaluations excluded), computed exactly from the
  clock files once all five grid runs exist and before any cross-arm
  number is assembled. A run's cutoff checkpoint is the last generation
  whose cumulative clock is at or below T*′ (inclusive); where it is the
  final checkpoint, the final evaluation is reused (Study 1's rule, as
  `scripts/make_results.py --study 2` implements it).
- **Budget, measured** (pilot H9-2026-10-12-pilot-01: one seed, two
  generations × 200 games per arm, warm start + W = 3). The window
  doubles training time when the second generation enters (grid 78 →
  168 s, graph 303 → 613 s at 200 games); training is 3% (grid) and 5%
  (graph) of a Study 1 run, so W = 3 adds about 1.0 h per grid run and
  3.0 h per graph run. Projection: grid ≈ 18–20 h per run, graph
  ≈ 30–53 h per run; ≈ 295 h, 12–13 days of sequential laptop time for
  the ten runs, plus ≈ 1 day of evaluations; disk ≈ 2 GB (pilot: 22 MB
  of shards per 400 games). No paid resources.
- **Evaluations** (all against the D-017 population: B-RND, seed 9101;
  B-HEU; B-MCTS at 6,400 simulations, seed 9201; the 250 D-025 openings
  from `results/comparison/openings-v1.txt`; network at 400 simulations,
  no noise; paired colour-swapped games):
  - intermediate, at indices 4 and 7 (generations 5 and 8): 20 paired
    games per opponent, network seed 9000 + index, arena seed
    777,000 + index; descriptive only;
  - final, at index 9: 100 paired games per opponent, same seed rule;
  - cutoff checkpoints: 100 paired games per opponent, network seed
    9500, arena seed 888,000 (Study 1's cutoff settings), run after T*′
    is journaled and never beside a running self-play.
- **Execution.** Runs are sequential, interleaved as in Study 1
  (grid-11, graph-11, grid-12, …, graph-15) so that a stop leaves both
  arms with equal seed counts; `scripts/campaign2.sh` under `nohup` and
  `caffeinate`, log `data/runs/campaign2.log`; resumable per generation
  from the recorded manifests; 20 GB free-disk guard; no evaluation or
  other heavy process launched beside a running self-play (the clocks
  are the measurement). Launching is G-SPEND.

## 5. Pre-commitments

- All five seeds per arm enter the final analysis regardless of
  direction; no seed is dropped for its score; exclusion only for crash,
  corruption or engine error, each journaled.
- T*′ is computed once, from the five grid clocks only, before any
  cross-arm number is assembled, and never recomputed; its derivation is
  journaled.
- Study 2's numbers are reported beside Study 1's, never pooled; the
  interaction question is descriptive.
- No opponent, opening, evaluation setting, hyperparameter or network
  architecture is touched. The window size and the warm-start rule are
  frozen with this document.
- Write-as-you-go: the Study 2 chapter of the report is drafted from
  the frozen tables; the claims register gains rows before diffusion.

## 6. Analysis and deliverables

`scripts/make_results.py --study 2` regenerates, from the raw per-game
records under `data/runs/cmp2-*/eval/`, the result tables of both
readings (per seed, score with truncations excluded, truncation rate,
0.5-sensitivity), the seed-level means with 10,000-resample percentile
bootstrap intervals, the graph−grid contrasts per opponent with
intervals, and a descriptive Study 1 vs Study 2 table, under
`results/study2/`. Deliverables: those tables, the cap-sensitivity
bounds, a score-vs-time figure, journal entries per campaign and per
analysis, a report chapter (EN + FR), the article's revision and the
claims register rows.

## 7. Stop rules

As Study 1: engine incorrect → suspend; budget hit → cut seeds (never
below 3 per arm), never honesty; two weeks without an interpretable
result → shrink and diagnose. Never kill or restart a running campaign
without the human.
