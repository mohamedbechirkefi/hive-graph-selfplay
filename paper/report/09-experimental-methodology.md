# Experimental methodology: a pre-registered, frozen protocol {#sec:protocol}

This chapter states what the comparison fixed in advance, how, when, and above all why. The governing protocol was frozen as version 1.0 on 10 September 2026, before any comparison run and after a pilot had confirmed every measured value in it; it declares any later change a new study, and none was made. Constants, hyperparameters and seeds are tabulated in `@sec:app-c`{=typst}; raw per-seed tables and the cutoff checkpoint map in `@sec:app-d`{=typst}.
<!-- src: docs/protocol.md:3-11; ../state/decisions.md:598-632 -->

## Why pre-register, and why freeze, at small compute {#sec:protocol-why}

A comparison on one machine with a handful of seeds leaves the experimenter great freedom after the fact: which checkpoint counts as "the" result; which opponents, at what strength; which seeds are reported; whether a game that hits the move cap is a draw, a loss, or nothing; which metric becomes the headline. Each choice, made after the numbers are visible, can manufacture or erase an effect of exactly the size such a study can detect; the garden of forking paths needs no conscious dishonesty. Two further risks are silent retuning of a baseline in view of the test result, and asymmetric attention to the arm one expects to win.

Pre-registration removes these degrees of freedom by one rule: every commitment that could bias an observation is made before the observation exists. Here that meant artifacts frozen under a content hash, each dated and approved by the author, and a protocol that names them and fixes the metric, the budget readings, the resampling unit and what outcome would count against the hypothesis. The protocol states that the hypothesis "is not presumed true" and that "a negative or null result is a publishable outcome of this study; the work does not need to confirm H1 to count". The negative answer eventually obtained was therefore a planned deliverable rather than a failure to be explained away.
<!-- src: docs/protocol.md:24-30 -->

Freezing followed a fixed order (`@tbl:fixed-timeline`{=typst}): the opponent population (`@sec:baselines`{=typst}) and the evaluation search settings on 9 September 2026; the protocol on 10 September 2026, once the pilot had re-measured the budgets and the move cap with the study's own networks, so that the frozen text carries no placeholders; the 250 shared openings and the comparison matrix with its cutoff rule the same day. The first comparison run started on 10 September 2026 at 12:42. Freezing after the pilot was the author's choice: it allowed the budgets to be confirmed on the actual arms and avoided a second freeze, which would have weakened what a freeze means.
<!-- src: ../state/decisions.md:323-333, 499-511, 572-580, 605-618, 763-771, 795-806; journal/2026-09-19-h6-comparison-01.md:24 -->

The research plan's stop rules also bounded the design: an incorrect engine suspends training, so engine validation (`@sec:engine`{=typst}) precedes all training; a budget overrun cuts configurations, never honesty; two weeks without an interpretable result shrink the scope; once the final evaluation set has been consulted the method is no longer adjusted against it. Hence the ablations were declared secondary and cuttable from the outset, and neither arm gained a second architecture when the graph arm underperformed.
<!-- src: ../plan_recherche_hive_trading.md:523-530; docs/protocol.md:41-44 -->

## Research questions and the hypothesis {#sec:protocol-rq}

The frozen protocol poses one primary question and one hypothesis, reproduced as frozen.

**RQ-H1.** At comparable training budget, does a graph architecture learn a better policy than a grid architecture for base-game Hive, within an AlphaZero-style self-play pipeline?

**Hypothesis H1.** A simple message-passing graph network, receiving the hive as a graph, reaches a higher mean score against a fixed opponent population than a grid CNN receiving the 32×32 BFS-unwrapped frame, at equal training budget.
<!-- src: docs/protocol.md:15-22 -->

The protocol itself gives reasons for not presuming H1. Stacking and above all the *empty* candidate destinations must be represented correctly, and a naive adjacency graph over occupied cells may not suffice, because destinations and sliding constraints are properties of empty space. Prior evidence was also split, with graph networks favouring long-range structure and convolutions local patterns in Hex (Keller et al., 2023).
<!-- src: docs/protocol.md:24-30; ../state/decisions.md:244-247 -->

The rejection rule, written before any comparison run, is quoted verbatim; its section references point to the protocol's own sections on budget readings and on seeds and uncertainty:

> What would reject H1 […]: against the frozen opponent population, under **both** budget readings of §5, the graph arm shows no seed-consistent advantage (no consistent per-seed ordering in its favour), **and** the interval on the score difference — computed with the resampling unit stated in §6 — excludes a meaningful graph advantage. That outcome is reported as-is: "at this budget, on this variant, the graph representation did not help."
<!-- src: docs/protocol.md:32-39 -->

The rule is conjunctive: per-seed ordering *and* interval must both fail to favour the graph arm, so one lucky seed cannot rescue the hypothesis and one unlucky seed cannot reject it. It applies under both budget readings, and it fixes the resampling unit in advance. One limit should be stated plainly: the frozen text says "meaningful" without a numeric threshold. The verdict therefore reports the largest upper bound of all graph−grid intervals, so that a reader can apply any threshold they consider meaningful; the study claims none it did not pre-register.

Two secondary questions follow. RQ-H2 asks whether the comparison changes when the budget is read per example rather than per hour; it is pre-registered in the matrix as the two budget readings. RQ-H3 asks what the graph arm's distinctive components contribute; its ablation specifications were written on 19 September 2026, after the main result was known (`@sec:protocol-ablations`{=typst}). The protocol's own time-permitting question, robustness to translation and symmetry, was declared the first thing to drop under schedule pressure, and it was dropped.
<!-- src: docs/protocol.md:41-44; configs/comparison-matrix.yaml:42-51; ../state/decisions.md:856-873 -->

## Design: two arms, five seeds, ten generations {#sec:protocol-design}

Only the state encoding and the network body differ between arms (`@sec:representations`{=typst}): a residual CNN over the 32×32 BFS-unwrapped, bounding-box-centred frame (1.44 M parameters) against a relational message-passing network over the cell graph (1.47 M, +1.5%). Both share the rules engine, the search, the shared action decoder, the training loop, the budgets and the evaluation harness. Neither received any hyperparameter search.
<!-- src: results/comparison/parameter-counts.md:7-12; docs/representations/comparison-controls.md:46-55; docs/protocol.md:136-149 -->

Each run comprises 10 generations of 500 self-play games. Self-play searches 128 simulations per decision on a random quarter of decisions and 32 on the rest, following the playout-cap randomization of Wu (2020), and only full-budget decisions yield targets. It samples from the visit distribution for 12 plies, resigns below −0.92 with a 10% no-resign audit, and truncates at 300 plies. Each generation trains 2 epochs at batch 256 and learning rate 0.02 with the legal-masked policy loss. A checkpoint is kept and the wall-clock logged at every generation, which makes the second budget reading possible.
<!-- src: configs/comparison-matrix.yaml:27-51; paper/annex-architectures.md:87-92 -->

These values were measured rather than taken from the plan's starting points of 64 and 128 simulations. Profiling on 9 September 2026 put one network evaluation at 2.62 ms on the accelerated provider, and the pilot of 10 September 2026 confirmed ≈12 s per game at generation 0, falling toward ≈3 s as play sharpens. The 300-ply cap lies beyond the longest search-guided game observed (202 plies). The pilot showed random-initialisation self-play truncating 56.7% of games at that cap, which is tolerable only because truncation is its own reported outcome.
<!-- src: docs/protocol.md:57-62, 112-119; journal/2026-09-10-h4-pilot.md:38-44, 104-110 -->

Seeds came in two stages, both disclosed. The matrix pre-registered three seeds per arm (1–3; base seed 100,000 × seed) and noted a five-seed option "if budget allows". The three-seed campaign, approved on 10 September 2026, ran sequentially on one machine, four worker threads per run, under an estimate of ≈4.6 days and a 20 GB free-disk guard. After both readings of the three-seed matrix had been analysed (19 September 2026), the author approved on 26 September 2026 seeds 4 and 5 for both arms under three pre-commitments written before any new run: (a) all five seeds per arm enter the final analysis regardless of the new seeds' direction; (b) the equal-time cutoff stays at its already-computed value; (c) the two-stage collection is disclosed. Seeds added symmetrically under an unchanged rule are a decision about statistical power rather than a tuning channel; the three-seed verdict stays on record.
<!-- src: configs/comparison-matrix.yaml:25; ../state/decisions.md:795-806, 946-956; journal/2026-10-09-h6-5seed-final-01.md:12-13, 61-67 -->

## The two budget readings and the equal-time cutoff {#sec:protocol-readings}

A network that learns more per example but costs more per example can lose at equal hours, so the protocol mandates two readings of one campaign. The asymmetry is real: the best available provider gives 2.62 ms per evaluation for the grid arm (accelerated) but 3.67 ms for the graph arm (on the CPU, since its gather-heavy operations fall back from the accelerator), and the graph runs took 2.0× the grid training wall-clock (36.7 vs 18.0 h over five seeds; 35.7 vs 18.2 h over the original three pairs). The interaction is reported and charged rather than equalised away.
<!-- src: docs/protocol.md:103-110; docs/representations/comparison-controls.md:19-32; results/comparison/wallclock-per-run.md:7-10; journal/2026-09-19-h6-comparison-01.md:71-72 -->

**Same-examples reading.** Both arms train for 10 generations × 500 games with identical generator settings, hence on the same number of games at the same simulation budget; each run is read at its final checkpoint (generation index 9 in the run logs, which count from 0).

**Same-wall-clock reading.** The cutoff (T\* in tables and figures) was defined by a rule in the pre-registered matrix: the median full-run wall-clock of the three grid runs, every run of both arms then read at its last checkpoint completed at or before it. The rule gives the grid arm its full budget by construction, charges the graph arm its true cost, and is score-free. It was executed on 16 September 2026, with five of six runs complete and the last graph run still training, from grid clocks alone and before any cross-arm number existed: median(18.77, 16.73, 19.07) = 18.77 h. Per-generation clocks count self-play, training and export; evaluation time is excluded for every run alike. The exact median, which is the first grid run's own total, is the operative value. When tables were regenerated for five seeds, the rounded constant briefly excluded that run's last checkpoint at its inclusive boundary; restoring the exact value reproduced the record of 16 September exactly.
<!-- src: configs/comparison-matrix.yaml:46-51; journal/2026-09-16-h6-progress-01.md:36-42; journal/2026-10-09-h6-5seed-final-01.md:22-29 -->

Selection is mechanical and its outcome is part of the result (`@tbl:d-cutoff`{=typst}): generation indices 9, 9, 8, 9, 9 for the grid runs and 3, 4, 4, 2, 5 for the graph runs. At equal wall-clock the graph arm had completed 3–6 of its ten generations, the grid arm nine or ten. Cutoff checkpoints were evaluated after the campaigns (18 September 2026; 6 October 2026 for the extension) at the same 100-game volume; where the cutoff checkpoint is the final one, the final evaluation is reused.
<!-- src: journal/2026-09-16-h6-progress-01.md:38-42; journal/2026-10-09-h6-5seed-final-01.md:3, 26-29 -->

## Evaluation: frozen population, frozen openings, pinned search {#sec:protocol-eval}

**Opponent population.** The population comprises three opponents, frozen by the author on 9 September 2026 before any training run: B-RND, uniform over the engine's legal moves, seeded; B-HEU, the documented hand-written evaluation played greedily at depth 1, weights pinned by hash and by a test; B-MCTS, search without a network at 6,400 simulations per decision. The prior demonstration loop's checkpoint was excluded: its single-seed, uncontrolled provenance would have invited a reading as "the old AI". The search opponent's 37.5% against the heuristic was diagnosed and deliberately not retuned, since the freeze forbids adjusting an opponent in view of results; no opponent was touched afterwards.
<!-- src: docs/baselines.md:49-58, 69-97; ../state/decisions.md:499-521; docs/protocol.md:85-92 -->

**Openings and pairing.** Games start from 250 unique legal four-ply openings generated blind by a seeded random walk over the engine's legal moves (generator seed 20260910), frozen on 10 September 2026 under their content hash. Pair *i* of every match plays line *i* once with each colour, so every arm, seed, checkpoint and opponent faces an identical opening-and-colour schedule (a harness test showed byte-identical schedules for different agents and match seeds). Final and cutoff evaluations play 100 paired games per opponent (openings 0–49, both colours); intermediate evaluations at generations 4 and 7 play 20 per opponent and serve only the trajectory figures.
<!-- src: results/comparison/opponents-manifest.md:30-47; configs/comparison-matrix.yaml:53-59; journal/2026-09-10-h6-matrix-01.md:40-44 -->

**Why 100 games.** The final volume was recalibrated after the first finals: on 16 September 2026 the seed-to-seed spread against the heuristic (0.080–0.190, SD ≈ 0.056) was about twice the per-pairing game noise at 100 games (SE ≈ 0.03), so more games could not materially narrow the seed-level interval. The volume stayed at 100; the only lever is more seeds, which the extension later provided.
<!-- src: journal/2026-09-16-h6-progress-01.md:58-64; ../state/decisions.md:823-849 -->

**Pinned search.** Every evaluation of a trained network runs 400 simulations per decision, with no Dirichlet root noise (the code default, asserted by a test) and a deterministic best move; these settings were pinned on 9 September 2026 by a versioned configuration and never changed. Fixed visit counts matter because training and test compute trade off (Jones, 2021); a floating evaluation budget would let measured strength drift with the search rather than with the network. The evaluated network is seeded 9000 + generation for in-run evaluations and 9500 for cutoff sets, B-RND 9101 and B-MCTS 9201 (B-HEU is deterministic). Evaluation games never feed back into training; an audit check verifies the separation.
<!-- src: configs/eval-settings.toml:5-18; ../state/decisions.md:572-591; paper/annex-reproduction.md:35-41 -->

## Statistics and the truncation policy {#sec:protocol-stats}

**Metric and unit.** The primary metric is the mean score against the population (win 1, draw 0.5, loss 0) over the non-truncated games of a (seed, opponent) cell; game-level data are first aggregated to one score per cell, and the seed is the unit of analysis. Games played by one trained network are not independent samples of the *method*: they share that network's weights, and how well a representation learns varies across independent runs far more than across games of one run. Pooling thousands of games from one model yields intervals precise about the wrong thing (Agarwal et al., 2021); no table in this report does so.
<!-- src: docs/protocol.md:79-83, 124-132 -->

**Intervals.** Seed-level means and their 95% intervals are percentile bootstraps with 10,000 resamples over seeds. For the graph−grid contrast the two seed sets are resampled independently: training seeds are not paired across arms, whereas the pairing that does exist (identical openings and colours) is held constant across arms and absorbed within each cell. Every table shows every seed; none reports a best seed. Elo, where printed, is descriptive and relative to this population only.
<!-- src: journal/2026-09-19-h6-comparison-01.md:38-40; paper/ch5-protocol.md:48-53; docs/protocol.md:94-95 -->

**Truncation.** A game reaching the 300-ply cap is never a draw: truncations are a fourth outcome category everywhere, and each table carries the truncation rate beside the score. The primary score excludes truncated games; a sensitivity column scores them 0.5; two bounding treatments score every truncated game of the arm under test as a loss and as a win; and the direction of the contrast is reported under all four treatments. The "win" treatment bounds what any larger cap could do, which is why bounds replace a re-run at a larger cap. The policy proved necessary: against the random opponent the graph arm truncated 20–57% of its games where the grid arm truncated 0–1%, and, scored as draws, that pathology would have disappeared into half-points.
<!-- src: docs/protocol.md:57-75, 79-83; journal/2026-09-19-h6-comparison-01.md:64-70 -->

## Exclusion criteria and the record {#sec:protocol-exclusions}

A run may be excluded only for a process failure (a crash, corrupted data, or an engine error such as a rules defect exploited by an agent); a bad score is never an exclusion criterion. Across the main campaign, the extension and the ablations, no run failed, was restarted, or was excluded. Two incidents touched the measurement machinery. On 18 September 2026 the match runner was found to drop its records when every game of a match truncated; an audit showed no campaign file affected, and the defect was fixed before the cutoff evaluations ran. On 23 September 2026 the first ablation's three runs, complete without process failure, were found to have diverged to non-finite outputs in generation 0; the divergence was detected because three independently seeded runs returned evaluations identical to the game count. The divergence is reported as the result; the runs are not excluded, but their evaluation tables are not strength measurements. A loud halt on non-finite loss was added to the training loops the same day; healthy runs are unaffected.
<!-- src: paper/ch5-protocol.md:56-58; journal/2026-09-19-h6-comparison-01.md:76-79; journal/2026-09-23-h7-a1-divergence-01.md:21-55; journal/2026-10-02-h7-a2-nogpool-01.md:9-11, 42 -->

## Ablation design {#sec:protocol-ablations}

The ablation rules were fixed before the ablation runs: at most two ablations, each removing exactly one component from the full graph arm to answer one question, at full parity with the reference (seeds 1–3, the same budgets, frozen opponents, openings and pinned evaluation); a capacity change inherent to the removed component is reported, never equalised by changing a second component; and where more than one component differs, no effect is attributed to the graph. A1 replaces the six direction-typed edge matrices by one shared matrix (naive adjacency; 0.54 M parameters, the typed matrices being the component), testing the protocol's own premise. A2 removes the global-pooling bias from every layer (1.37 M). A2 is a substitution: the plan's first ablation removes symmetry augmentation, but the full method was fixed without augmentation on 10 September 2026, because consistent hex-symmetry transforms across two representations risked contaminating the main comparison, so there was nothing to remove. The substitute question was chosen on 19 September 2026 in view of the main result's mechanism signal (the graph arm's relative strength sat in its value head). This is a post-result choice of *question*, disclosed here, under an unchanged analysis. The author approved both ablations at three seeds on 20 September 2026.
<!-- src: configs/ablations/A1-edge-typing.md:1-18; configs/ablations/A2-global-pooling.md:1-14; results/comparison/parameter-counts.md:9-10; ../state/decisions.md:700-727, 856-883, 888-910 -->

A1 proved untrainable at parity, so a supplement A1′ was added and labelled explicitly as two-component: untyped edges plus a global gradient-norm clip of 1.0, the only optimizer change in the study. Approved on 26 September 2026, it answers only the question "what does a *trained* naive-adjacency network score?"; no A1′ number is attributed to edge typing alone.
<!-- src: configs/ablations/A1prime-edge-typing-clipped.md:1-14; ../state/decisions.md:917-934; paper/annex-reproduction.md:28-31 -->

## Resources actually consumed {#sec:protocol-resources}

All runs executed on one Apple M1 Pro (10 cores, 16 GB, macOS 15.3.1), sequentially, four worker threads per run; no paid compute or data was used. `@tbl:campaigns`{=typst} lists the four campaigns; training wall-clock per run sums the per-generation clocks (self-play, training, export), evaluation games excluded. Over the ten main-comparison runs these totals ranged from 16.7 to 19.1 h (grid) and 26.6 to 49.9 h (graph), 273.5 h in all; the three-seed campaign occupied the machine ≈7.4 days, ≈163 h including its cutoff evaluations; an evaluation game at 400 simulations took ≈23–32 s. The first ablation's runs are short (7.61–8.01 h) because a non-finite policy plays short degenerate games.
<!-- src: results/comparison/wallclock-per-run.md:3-10; journal/2026-09-19-h6-comparison-01.md:24-26; paper/annex-reproduction.md:70-75; journal/2026-09-23-h7-a1-divergence-01.md:15-16, 35-39 -->

| Campaign | Runs | Dates (2026) | Wall-clock per run |
| --- | ---: | --- | --- |
| Main comparison, seeds 1–3 | 6 | 10 Sep 12:42 → 17 Sep 22:31; cutoff evaluations 18 Sep (~11 h) | grid 18.77 / 16.73 / 19.07 h; graph 43.07 / 32.71 / 31.28 h |
| Ablations A1, A2 | 6 | 20 Sep 14:08 → 27 Sep 17:13 | A1 7.75 / 8.01 / 7.61 h (diverged); A2 39.90 / 47.44 / 32.05 h |
| Extension, seeds 4–5 | 4 | 27 Sep → 2 Oct; cutoff evaluations 6 Oct (≈6 h) | grid 18.23 / 17.19 h; graph 49.86 / 26.57 h |
| Supplement A1′ | 3 | 2 Oct → 6 Oct | 23.89 / 30.35 / 27.68 h |

Table: Compute consumed by the four campaigns on the single study machine (four worker threads per run, runs sequential, no paid compute). Wall-clock per run is the training wall-clock under one accounting for every campaign (per-generation self-play, training and export seconds summed, evaluation games excluded); the first-ablation runs are short because their training had diverged. {#tbl:campaigns}
<!-- src: results/comparison/wallclock-per-run.md:5-8; journal/2026-09-19-h6-comparison-01.md:24-26; journal/2026-09-23-h7-a1-divergence-01.md:8, 15; journal/2026-10-02-h7-a2-nogpool-01.md:3, 16; journal/2026-10-09-h6-5seed-final-01.md:3, 13; journal/2026-10-09-h7-a1prime-01.md:3, 13; ../state/decisions.md:893-899 -->

## What was fixed before the first comparison run, and what came after {#sec:protocol-timeline}

`@tbl:fixed-timeline`{=typst} places every commitment relative to the first comparison run; hashes and values are in `@sec:app-c`{=typst}, the provenance index in `@sec:app-e`{=typst}.

| Element | Fixed on (2026) | Timing | Safeguard |
| --- | --- | --- | --- |
| Opponent population; prior checkpoint excluded | 9 Sep | before training | hashes; never touched |
| Evaluation search settings | 9 Sep | before training | configuration and test |
| Protocol v1.0, including the rejection rule | 10 Sep | after the pilot, before the first comparison | content hash; change = new study |
| 250 shared openings | 10 Sep | before the first comparison | generated blind; content hash |
| Comparison matrix, including the cutoff rule | 10 Sep | before the first comparison | rule is score-free |
| Equal-time cutoff value, 18.77 h | 16 Sep | mid-campaign, before any cross-arm number | grid clocks only; exact median |
| Final evaluation volume, 100 games per opponent | 16 Sep | after the first finals | pre-configured value kept |
| Ablation specifications A1, A2 | 19 Sep | after the main result | one-component rule; choice disclosed |
| Seeds 4–5 | 26 Sep | after the three-seed analysis | three written pre-commitments |
| Supplement A1′ | 26 Sep | after A1's divergence | labelled two-component |

Table: Chronology of the study's commitments relative to the first comparison run (10 September 2026, 12:42). Rows one to five preceded any comparison number; the later rows were added afterwards under the safeguard stated. {#tbl:fixed-timeline}
<!-- src: ../state/decisions.md:499-521, 572-591, 605-618, 763-771, 795-806, 823-849, 856-883, 917-934, 946-956; journal/2026-09-16-h6-progress-01.md:36-37; journal/2026-09-10-h6-matrix-01.md:1-3 -->

## Question → experiment → result matrix {#sec:protocol-matrix}

| Question | Experiment | Result and where |
| --- | --- | --- |
| RQ-H1 (representation): does the graph arm learn a better policy than the grid arm at comparable budget? | Grid vs graph, 5 seeds per arm, frozen population and openings, read at the same examples and at the equal-time cutoff | Score and uncertainty per seed and opponent; graph−grid contrast with seed-level bootstrap intervals; verdict under the frozen rule (`@sec:results-main`{=typst}; raw tables in `@sec:app-d`{=typst}) |
| RQ-H2 (efficiency): does the answer change per example versus per hour? | The same campaign read at the final checkpoints, then at the cutoff checkpoints | Score-versus-training-time curves and the score/cost table (`@sec:results-cost`{=typst}) |
| RQ-H3 (components): what do the graph arm's distinctive components contribute? | One component removed at a time at full parity, 3 seeds each (A1 edge typing; A2 global pooling), plus the labelled two-component supplement A1′ | Ablation table: per-seed scores, truncation rates, seed-level intervals against the full graph arm (`@sec:results-ablations`{=typst}) |

Table: The study's three questions, the experiment that addresses each, and the form and location of its result. RQ-H1 is the pre-registered primary question; RQ-H2 and RQ-H3 are secondary. {#tbl:rq-matrix}
<!-- src: paper/ch5-protocol.md:60-66; results/comparison/results-same-examples.md:5-16; results/ablations/README.md:5-10 -->
