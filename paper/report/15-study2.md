# A second study: the comparison under a warm-started loop with a replay window {#sec:study2}

The first study answered its question inside a pipeline that trained every generation's network from a fresh initialisation on that generation's games alone (`@sec:pipeline`{=typst}, `@sec:discussion`{=typst}). This chapter reports a second, separately pre-registered study that applies the two standard remedies, weights carried across generations and training on a window of recent generations, identically to both arms, and asks whether the ordering of the two representations survives. Its protocol was frozen on 13 October 2026, before any run; its campaign started the same day. Everything the first study froze (opponents, openings, evaluation settings, networks, decoder) is reused untouched, so that the two studies differ in the training regime and in nothing else.
<!-- src: docs/protocol-v2.md:3-12 -->

## Why a second study {#sec:study2-why}

The per-generation re-initialisation of the first study is neutral for the comparison, since both encoders saw exactly the same records under the same conventions, but it bounds the regime reached: each network learned from the positions of 500 games, and the absolute strength after ten generations stayed near the ceiling against the random opponent and around 0.1 against the two strong opponents. A reviewer's first objection to the generality of a negative verdict is therefore that the graph representation might need more data per network, or a longer optimisation trajectory, before its structural prior pays. The large self-play systems carry weights from generation to generation and train on a replay window of recent games; a second study under that regime is the direct test of the objection. The question it asks is the first study's question under the new regime (RQ-H1′), with the same hypothesis (H1′): the graph arm reaches a higher mean score against the frozen population than the grid arm at equal budget. A secondary, descriptive question asks whether the graph−grid contrast moves toward zero or changes sign relative to the first study; the two studies are compared side by side and never pooled.
<!-- src: docs/protocol-v2.md:14-45; paper/report/16-discussion.md:205-229 -->

## What changed, and what did not {#sec:study2-protocol}

Exactly two things change, in both arms. First, the network of generation $g$ is initialised from the final checkpoint of generation $g-1$ (model weights only; the optimizer and the cosine learning-rate schedule restart at every generation, as before), generation 0 starting from the seeded random initialisation. Second, generation $g$ trains on the records of generations $\max(0, g-2)$ to $g$, a replay window of three generations: 500 games at generation 0, 1,000 at generation 1 and 1,500 from generation 2 onward, still for two epochs, so that the number of gradient steps grows with the window.
<!-- src: docs/protocol-v2.md:53-60 -->

The hyperparameter policy was decided by the author at the freeze and recorded with it. Both arms keep the first study's training settings unchanged (learning rate 0.02, batch 256, weight decay $10^{-4}$, value-loss weight 0.6, two epochs per generation, legal-masked policy loss; 96 channels and 8 blocks for the grid network, 152 hidden units and 8 layers for the graph network). The alternative considered was an identical, pre-registered budget of three learning rates (0.02, 0.01 and 0.005) for both arms on the first seed only, the best rate per arm then used for the remaining seeds. It was rejected because it would have tripled the cost of one seed per arm (about four more days of compute), selected on a single seed, and the pilot described below showed no sign of optimisation instability under the warm-started regime. The objection that both arms run under untuned defaults therefore remains open for both studies and is stated as a limit.
<!-- src: docs/protocol-v2.md:62-75 -->

Everything else is the first study's: the engine and its search settings (128 and 32 simulations with playout-cap randomization, exploration noise, 12 temperature plies, resignation below −0.92 with the 10% audit, the 300-ply cap), the record format, the loss and masking, both encoders and networks at 1,443,168 and 1,465,452 parameters, the shared decoder, the three frozen opponents, the 250 frozen openings, the pinned evaluation (400 simulations, no noise, 100 paired colour-swapped games per opponent), the statistics (the seed as the unit, 10,000-resample percentile bootstrap, independent seed sets for the contrast, truncation as an outcome of its own) and the rejection rule, which is the first study's rule word for word in its form: no seed-consistent graph advantage under both budget readings, and seed-level intervals on the graph−grid difference excluding a meaningful graph advantage, with the largest upper bound reported so that any threshold can be applied by the reader. Intermediate evaluations are descriptive and enter no verdict. The new runs use seeds 11 to 15, so that no random stream is shared with the first study's seeds 1 to 5.
<!-- src: docs/protocol-v2.md:40-51, 88-101 -->

The design is again two arms, five seeds, ten generations of 500 games, read twice. The same-examples reading compares final checkpoints. The same-wall-clock reading compares each run's last checkpoint completed at or before an equal-time cutoff defined, as in the first study, by a score-free rule written before any run: the median of the total training wall-clock of the five grid runs of this study, each total being the sum of the ten per-generation clocks (self-play, training and export; evaluations excluded), computed once from the clock files when the five grid runs exist and before any cross-arm number is assembled, and never recomputed. The cutoff of the second study is its own value, measured under the new regime; it is not the first study's 18.77 h.
<!-- src: docs/protocol-v2.md:105-120 -->

The pre-commitments repeat the first study's: all five seeds per arm enter the final analysis whatever their direction; a seed is excluded only for a crash, a corruption or an engine error, each recorded; no opponent, opening, evaluation setting, hyperparameter or architecture is touched; the chapter is written from the frozen tables. The stop rules are unchanged, with one addition made explicit: a running campaign is never killed or restarted without the author.
<!-- src: docs/protocol-v2.md:152-166, 180-184 -->

## Implementation and verification before the freeze {#sec:study2-implementation}

The two changes were implemented as two options of the campaign driver, identical for both arms and switched off by default, so that the driver with default options still produces the first study's commands. That property was pinned by a regression test before the protocol was frozen: for four runs of the first study (two per arm) and their ten generations each, the training command produced by the driver with default options was compared with the recorded training configuration of every generation (shard list, seed, epoch count, absence of an initialisation checkpoint), and the self-play command with the recorded manifest (seed, number of games, simulation budgets, generation index); all forty generations matched. The same test checks that, with the two options on, only the shard list and the initialisation checkpoint change, that generation 0 never warm-starts, and that generation $g$ initialises from generation $g-1$. The second study's runs are written in their own directories, and each run records its regime in a configuration file, so that the first study's records cannot be touched or confused with the new ones.
<!-- src: journal/2026-10-09-h9-driver-01.md:30-62 -->

A pilot approved by the author on 12 October 2026 then ran the complete path on both arms, one seed outside both studies' seed sets, two generations of 200 games, warm start and three-generation window, with a reduced final evaluation of 20 games per opponent that served as a check of the path and entered no analysis. `@tbl:study2-pilot`{=typst} gives the measured phases. On both arms the second generation trained from the first generation's weights on the shards of both generations, as the configuration files and the training logs record; training time grew in proportion to the number of records (a factor 2.15 on the grid arm and 2.02 on the graph arm when the second generation entered the window) and remained a small share of a generation, because self-play dominates: in the first study training took 3% of a grid run (194 to 250 s per generation) and 5% of a graph run (516 to 833 s). With the window reaching three generations from generation 2, training time over a run is about 2.7 times the first study's, which adds about one hour to a grid run and three hours to a graph run. The projected cost of the campaign is therefore the first study's plus that increment: about 18 to 20 h per grid run, 30 to 53 h per graph run, about 295 h or 12 to 13 days of sequential laptop time for the ten runs, plus about one day of evaluations.
<!-- src: journal/2026-10-12-h9-pilot-01.md:48-110; docs/protocol-v2.md:121-130 -->

| Arm | Generation | Self-play (s) | Training (s) | Training records (shards) |
| --- | --- | ---: | ---: | ---: |
| grid | 0 | 2,196 | 78 | 10,188 (4) |
| grid | 1 | 2,584 | 168 | 22,399 (8) |
| graph | 0 | 5,821 | 303 | 10,655 (4) |
| graph | 1 | 5,800 | 613 | 21,386 (8) |

Table: Pilot of the second study (12 October 2026): wall-clock of the self-play and training phases of each generation, one seed per arm, 200 games per generation, warm start and three-generation replay window, on the same laptop as the campaigns. Generation 1 trains on the records of generations 0 and 1; the training record count excludes the validation split. Export took 2 s per generation on both arms. The pilot measured costs and exercised the path; its 20-game evaluation carries no statistical meaning and is not reported. {#tbl:study2-pilot}
<!-- src: journal/2026-10-12-h9-pilot-01.md:48-60, 80-86 -->

The seven automated checks of the pipeline (`@sec:pipeline`{=typst}) were then run on each pilot run's windowed shard set. One check failed as designed. The stamp check required every record of a training set to carry the generation-and-network stamp of a single manifest, which encodes the first study's one-generation-per-training assumption; on the windowed set it reported records of two generations against one manifest. The check was generalised rather than relaxed: it now takes the manifests of every generation in the window and requires the set of record stamps to equal the set of listed stamps, so that every record comes from a listed generation and every listed generation is present; it still passes on a first-study shard set with one manifest and still fails with a wrong manifest. With that generalisation all checks passed on both arms (policy normalisation under the legal mask on a real forward pass, legality of all stored targets, outcome domain with 17,054 of 22,856 grid records and 11,298 of 21,822 graph records truncated and excluded from the value loss, record stamps, bitwise-identical save and resume, and separation of training inputs from the evaluation files).
<!-- src: journal/2026-10-12-h9-pilot-01.md:88-120; ../docs/methodology-log.md -->

## Execution {#sec:study2-execution}

The protocol was frozen on 13 October 2026 under its content hash, with the hyperparameter policy, the window of three generations and the cutoff rule decided by the author, and the campaign was approved and launched the same day at 15:02 CET, after a check that the machine was idle, that 161 GB of disk were free against a 20 GB guard, and that the frozen protocol's hash was unchanged. The ten runs execute sequentially on the same laptop as the first study, interleaved grid then graph for each seed from 11 to 15, so that an interruption would leave both arms with equal seed counts; each run is resumable at generation granularity from its recorded manifests, and intermediate evaluations of 20 games per opponent at generations 5 and 8 serve the trajectory figures only. No other heavy process runs on the machine during the campaign, since the per-generation clocks are the measurement of the same-wall-clock reading. `@tbl:study2-runs`{=typst} records each run as it completes.
<!-- src: ../state/decisions.md (D-038, D-039); journal/2026-10-13-h9-campaign-01.md:40-56 -->

| Run | Start | End | Training clock (h) |
| --- | --- | --- | ---: |
| grid, seed 11 | 13 Oct 2026 15:02 | 14 Oct 2026 09:33 | 17.46 |
| graph, seed 11 | 14 Oct 2026 09:33 | 16 Oct 2026 02:39 | 39.28 |
| grid, seed 12 | 16 Oct 2026 02:39 | 16 Oct 2026 21:46 | 17.95 |
| graph, seed 12 | 16 Oct 2026 21:46 | 18 Oct 2026 13:40 | 37.33 |
| grid, seed 13 | 18 Oct 2026 13:40 | 19 Oct 2026 08:19 | 17.63 |
| graph, seed 13 | 19 Oct 2026 08:19 | 21 Oct 2026 17:55 | 52.85 |
| grid, seed 14 | 21 Oct 2026 17:55 | 22 Oct 2026 12:18 | 17.46 |
| graph, seed 14 | 22 Oct 2026 12:18 | 24 Oct 2026 10:44 | 42.20 |
| grid, seed 15 | 24 Oct 2026 10:44 | 25 Oct 2026 06:27 | 18.52 |
| graph, seed 15 | 25 Oct 2026 06:27 | 26 Oct 2026 23:00 | 36.27 |

Table: Execution record of the second study's campaign: start and end of each run (CET) and its total training wall-clock, the sum of the ten per-generation clocks (self-play, training and export; evaluation time excluded). Ten generations of 500 games per run, warm start and three-generation replay window, sequential on one laptop. {#tbl:study2-runs}
<!-- src: journal/2026-10-13-h9-campaign-01.md:58-72 -->

## Results {#sec:study2-results}

Every table in this section shows every seed; scores exclude truncated games, reported in their own column; intervals are 95% percentile bootstrap intervals over seeds (10,000 resamples), the two arms resampled independently for the contrasts. The raw tables with the sensitivity columns are in `@sec:app-d-study2`{=typst}; the provenance of every number in `@sec:app-e`{=typst}.
<!-- src: journal/2026-10-27-h9-analysis-01.md:34-51 -->

### The verdict in one paragraph

Under both budget readings the graph arm shows no seed-consistent advantage against any opponent, and every interval on the graph−grid score difference includes zero: the six point contrasts lie between −0.052 and +0.013, and the largest upper bounds are +0.090 at equal examples, against the search opponent, and +0.055 at equal wall-clock. The first condition of the frozen rule therefore holds under both readings. Its second condition speaks, as in the first study, of a "meaningful" advantage without a number, so the bounds are stated rather than a threshold chosen after the fact: the rule rejects H1′ for any threshold above +0.090; for thresholds between +0.055 and +0.090 the same-wall-clock reading rejects while the same-examples reading leaves a graph advantage against the search opponent unexcluded; the first study's realised bound was +0.028. **H1′ is not supported**: no graph advantage was detected under either reading, and the data cannot exclude a small one, below about 0.09, against the search opponent at equal examples. The rest of the section shows the evidence seed by seed.
<!-- src: journal/2026-10-27-h9-analysis-01.md:95-112,186-205; results/study2/results-arm-difference.md -->

### Reading 1: equal number of training examples

Both arms are compared at their generation-10 checkpoints, each run having generated and trained on ten generations of 500 games under identical simulation budgets; under the warm-started regime each checkpoint has also inherited the weights of the nine before it.
<!-- src: docs/protocol-v2.md:53-60,105-108 -->

| Arm | Seed | B-RND score | B-RND truncation | B-HEU score | B-MCTS score |
| --- | --- | ---: | ---: | ---: | ---: |
| grid | 11 | 0.984 | 5% | 0.040 | 0.100 |
| grid | 12 | 0.984 | 4% | 0.055 | 0.075 |
| grid | 13 | 0.995 | 1% | 0.105 | 0.175 |
| grid | 14 | 0.990 | 2% | 0.120 | 0.260 |
| grid | 15 | 0.989 | 7% | 0.065 | 0.045 |
| graph | 11 | 1.000 | 0% | 0.125 | 0.245 |
| graph | 12 | 0.995 | 4% | 0.030 | 0.070 |
| graph | 13 | 0.940 | 42% | 0.080 | 0.145 |
| graph | 14 | 0.928 | 24% | 0.030 | 0.100 |
| graph | 15 | 0.992 | 41% | 0.105 | 0.110 |

Table: Second study, same-examples reading. Final-checkpoint (generation 10) score of every run against each frozen opponent, five independent warm-started training runs per arm (seeds 11 to 15, ten generations of 500 games, replay window of three generations); 100 paired colour-swapped games per opponent per run on the 250 frozen openings at 400 simulations per move without exploration noise. Score = mean over decided games (win 1, draw 0.5, loss 0). Truncation = share of the 100 games stopped at the 300-ply cap; no game against B-HEU or B-MCTS was truncated by either arm. {#tbl:study2-same-examples}
<!-- src: results/study2/results-same-examples.md:7-16 -->

Against the legal-random opponent grid seeds score 0.984 to 0.995 and graph seeds 0.928 to 1.000; against the heuristic, grid seeds 0.040 to 0.120 and graph seeds 0.030 to 0.125; against the search opponent, grid seeds 0.045 to 0.260 and graph seeds 0.070 to 0.245. The graph arm truncates 0 to 42% of its games against the random opponent, three seeds at 24 to 42% and two at 0 to 4%; the grid arm 1 to 7%. The per-seed ranges of the two arms overlap against every opponent, and the spread between seeds of one arm against the search opponent (0.045 to 0.260 for the grid arm) is larger than any difference between the arms. Five seeds per arm cannot resolve differences inside such a spread.
<!-- src: results/study2/results-same-examples.md:7-16 -->

| Arm | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grid | 0.989 [0.985, 0.992] | 0.077 [0.051, 0.104] | 0.131 [0.068, 0.200] |
| graph | 0.971 [0.943, 0.996] | 0.074 [0.040, 0.108] | 0.134 [0.090, 0.196] |

Table: Second study, same-examples reading. Seed-level mean score per arm and opponent with the 95% bootstrap interval over the five seeds (10,000 resamples); same runs, opponents and evaluation volume as `@tbl:study2-same-examples`{=typst}. {#tbl:study2-same-examples-means}
<!-- src: results/study2/results-same-examples.md:20-25 -->

### Reading 2: equal wall-clock on the same machine

Each run is taken at the last checkpoint it had completed within the second study's own equal-time cutoff, 17.63 hours, the median of the total training wall-clock of the five grid runs (17.46, 17.95, 17.63, 17.46 and 18.52 hours), computed on 25 October 2026 from the clock files alone, before any score of the study had been read, and never recomputed. The cutoff selects generation 10, 9, 10, 10 and 9 for grid seeds 11 to 15, and generations 4, 5, 3, 3 and 4 for graph seeds 11 to 15 (counting the initial network as generation 1; in the run logs these checkpoints are labelled gen009/gen008/gen009/gen009/gen008 and gen003/gen004/gen002/gen002/gen003). Where the cutoff checkpoint is the final one the final evaluation is reused; the other seven sets were played after the campaign at the same volume and with the pinned cutoff seeds.
<!-- src: journal/2026-10-25-h9-tstar-01.md:38-66; journal/2026-10-27-h9-analysis-01.md:40-46 -->

| Arm | Seed | B-RND score | B-RND truncation | B-HEU score | B-MCTS score |
| --- | --- | ---: | ---: | ---: | ---: |
| grid | 11 | 0.984 | 5% | 0.040 | 0.100 |
| grid | 12 | 0.984 | 5% | 0.060 | 0.110 |
| grid | 13 | 0.995 | 1% | 0.105 | 0.175 |
| grid | 14 | 0.990 | 2% | 0.120 | 0.260 |
| grid | 15 | 0.973 | 7% | 0.065 | 0.075 |
| graph | 11 | 0.995 | 1% | 0.110 | 0.160 |
| graph | 12 | 0.984 | 4% | 0.115 | 0.095 |
| graph | 13 | 0.762 | 58% | 0.140 | 0.140 |
| graph | 14 | 0.965 | 28% | 0.065 | 0.120 |
| graph | 15 | 0.958 | 40% | 0.025 | 0.080 |

Table: Second study, same-wall-clock reading. Score of every run at its last checkpoint completed within the 17.63-hour cutoff (grid seeds at generations 10, 9, 10, 10, 9; graph seeds at generations 4, 5, 3, 3, 4), against each frozen opponent; same evaluation as `@tbl:study2-same-examples`{=typst} (100 paired games per opponent, 250 frozen openings, 400 simulations, no noise). Truncation = share of games at the 300-ply cap; none against B-HEU or B-MCTS. {#tbl:study2-same-wallclock}
<!-- src: results/study2/results-same-wallclock.md:7-16 -->

| Arm | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grid | 0.985 [0.979, 0.992] | 0.078 [0.053, 0.105] | 0.144 [0.092, 0.206] |
| graph | 0.933 [0.846, 0.986] | 0.091 [0.056, 0.124] | 0.119 [0.094, 0.144] |

Table: Second study, same-wall-clock reading. Seed-level mean score per arm and opponent with the 95% bootstrap interval over the five seeds (10,000 resamples); same runs and evaluation volume as `@tbl:study2-same-wallclock`{=typst}. {#tbl:study2-same-wallclock-means}
<!-- src: results/study2/results-same-wallclock.md:20-25 -->

At equal time the graph arm is read at its third to fifth checkpoints and the grid arm at its ninth or tenth. The graph arm's mean against the random opponent falls to 0.933 [0.846, 0.986] against 0.985 [0.979, 0.992], a gap carried by seed 13 (0.762 with 58% truncation) and seeds 14 and 15 (28% and 40% truncation); against the heuristic its mean is 0.091 [0.056, 0.124] against 0.078 [0.053, 0.105], and against the search opponent 0.119 [0.094, 0.144] against 0.144 [0.092, 0.206], every interval overlapping its counterpart. Three to five warm-started generations of the graph arm therefore reach, against the two strong opponents, the level that nine or ten grid generations reach, and the random-opponent gap is the truncation channel again. The reading charges the graph arm its measured cost on this machine, 2.34 times the grid arm's per run, which is what it should do; what it cannot do with five seeds is separate means whose intervals overlap by more than half their width.
<!-- src: results/study2/results-same-wallclock.md:7-25; results/study2/wallclock-per-run.md:7-10 -->

### The arm contrast

| Opponent | Same-examples: graph − grid | Same-wall-clock: graph − grid |
| --- | ---: | ---: |
| B-RND (legal-random) | −0.018 [−0.045, +0.008] | −0.052 [−0.140, +0.002] |
| B-HEU (heuristic) | −0.003 [−0.046, +0.039] | +0.013 [−0.032, +0.055] |
| B-MCTS (search, 6,400 simulations) | +0.003 [−0.082, +0.090] | −0.025 [−0.091, +0.034] |

Table: Second study, the pre-registered contrast: difference of seed-level mean scores (graph arm minus grid arm) with the 95% bootstrap interval over seeds (five independent warm-started seeds per arm, resampled independently, 10,000 resamples), per frozen opponent and budget reading. A negative value favours the grid arm. {#tbl:study2-contrast}
<!-- src: results/study2/results-arm-difference.md -->

None of the six contrasts excludes zero. Against the legal-random opponent the graph−grid difference is −0.018 [−0.045, +0.008] at equal examples and −0.052 [−0.140, +0.002] at equal time; against the heuristic, −0.003 [−0.046, +0.039] and +0.013 [−0.032, +0.055]; against the search opponent, +0.003 [−0.082, +0.090] and −0.025 [−0.091, +0.034]. The point contrasts are within 0.05 of zero in five cells of six and the sixth touches zero at its upper bound. The intervals are wider than the first study's in four of the six cells, the widest spanning 0.17 against the search opponent, where the two arms' seeds spread from 0.045 to 0.260.
<!-- src: results/study2/results-arm-difference.md; journal/2026-10-27-h9-analysis-01.md:95-104 -->

The frozen rule's first condition asks for the absence of a seed-consistent ordering in the graph arm's favour. Graph seeds outscore grid seeds in 3, 2 and 2 of the 5 same-index pairs against the three opponents at equal examples (13, 11 and 13 of the 25 cross pairs), and in 2, 3 and 2 of 5 (7, 15 and 11 of 25) at equal time: no opponent orders the seeds in the graph arm's favour under either reading. The second condition asks for intervals excluding a meaningful graph advantage, with no number attached: the largest upper bound is +0.090 at equal examples and +0.055 at equal time. The verdict is the one stated at the head of the section, in those terms; the study claims no threshold it did not pre-register, and the reader can apply any.
<!-- src: journal/2026-10-27-h9-analysis-01.md:106-112,186-199; docs/protocol-v2.md:40-51 -->

### Truncation and the sensitivity reading

![Second study: share of the 100 final-evaluation games against the legal-random opponent (B-RND) stopped at the 300-ply cap, per run; blue, the five grid seeds (11 to 15, left to right); red, the five graph seeds. Final checkpoints (generation 10) of ten warm-started runs, 100 paired colour-swapped games each on the 250 frozen openings at 400 simulations.](figures/fig7-truncation-study2.png){#fig:study2-truncation width=85%}

Truncation again occurs only against the random opponent, in none of the 20 cells against the heuristic and the search opponent. At the final checkpoints the graph arm truncates 0%, 4%, 42%, 24% and 41% of its games against the random opponent for seeds 11 to 15, the grid arm 5%, 4%, 1%, 2% and 7% (`@fig:study2-truncation`{=typst}); at the cutoff checkpoints, 1%, 4%, 58%, 28% and 40% against 5%, 5%, 1%, 2% and 7%. The conversion pathology of the first study, present in every graph seed there (20 to 57%), persists in three graph seeds of five and is absent in two, whose rates sit inside the grid arm's band. The score that excludes truncations is close between the arms, but under the sensitivity treatment, every truncated game counted 0.5, the graph−grid difference against the random opponent is −0.101 [−0.187, −0.012] at equal examples and −0.131 [−0.256, −0.015] at equal time, and both intervals exclude zero; the other four contrasts are unchanged under every treatment, having no truncations. Under the warm-started regime the graph arm's deficit against the weakest opponent is therefore no longer a deficit in decided games; it is a deficit in deciding them, concentrated in three seeds.
<!-- src: journal/2026-10-27-h9-analysis-01.md:114-123; results/study2/results-same-examples.csv; results/study2/results-same-wallclock.csv -->

### Trajectories and cost

![Second study: mean score against the frozen population (average of the three opponents, truncations excluded) as a function of cumulative training wall-clock, for all ten warm-started runs; evaluations at generations 5, 8 and 10 (20, 20 and 100 games per opponent). Blue: grid arm; red: graph arm; one line per seed, labelled at its end. The dashed vertical line marks the second study's equal-time cutoff of 17.63 hours.](figures/fig1-score-vs-time-study2.png){#fig:study2-score-time width=90%}

![Second study: score against each frozen opponent at generations 5, 8 and 10 (20, 20 and 100 paired games per opponent), one line per run, five warm-started seeds per arm; blue, grid arm; red, graph arm; truncations excluded. Intermediate points carry 20 games and serve the trajectory only.](figures/fig5-per-opponent-study2.png){#fig:study2-per-opponent width=100%}

`@fig:study2-score-time`{=typst} places the ten runs on a common time axis: the grid runs finish between 17.46 and 18.52 hours of training wall-clock, the graph runs between 36.27 and 52.85 hours, and at the cutoff the two clouds overlap in score. `@fig:study2-per-opponent`{=typst} shows the per-opponent trajectories; the intermediate points rest on 20 games and are read for shape only. The training-clock profiles of the graph runs took two shapes, a rise to a peak around generation 4 followed by a fall to grid-like durations by generation 10 in seeds 11 and 14, and a flat profile in seeds 12, 13 and 15; the per-generation clock of seed 13 rose monotonically from 14,456 s to 21,112 s and made it the slowest run of the campaign at 52.85 hours.
<!-- src: journal/2026-10-13-h9-campaign-01.md:56-75; results/study2/wallclock-per-run.md:7-10 -->

| Metric | Grid arm | Graph arm |
| --- | ---: | ---: |
| Training wall-clock per run, seeds 11 to 15 | 17.46 / 17.95 / 17.63 / 17.46 / 18.52 h | 39.28 / 37.33 / 52.85 / 42.20 / 36.27 h |
| Training wall-clock per run, mean of 5 seeds | 17.80 h | 41.59 h (2.34×) |
| Mean self-play cost | 12.8 s/game | 29.9 s/game |
| Population score, same-examples reading | 0.399 | 0.393 |
| Population score, same-wall-clock reading (cutoff 17.63 h) | 0.402 | 0.381 |

Table: Second study, cost and score summary per arm. Training wall-clock covers self-play generation, training and export for the ten generations of a run, evaluation games excluded, on the study machine (Apple M1 Pro, four worker threads, sequential runs); self-play cost = that wall-clock divided by 5,000 games. Population score = mean over the three frozen opponents of the seed-level mean score, truncations excluded. Parameters, inference and throughput benchmarks are unchanged from the first study. {#tbl:study2-cost}
<!-- src: results/study2/wallclock-per-run.md:7-10; paper/figures/fig2-score-cost-study2.md:7-11 -->

The ten runs consumed 296.9 hours of training wall-clock (grid 89.0 h, graph 207.9 h), against a projection of about 295 hours from the pilot, on one laptop with no paid compute. The graph arm cost 2.34 times the grid arm per run, against 2.04 in the first study: the replay window adds training time in proportion to the record count on both arms, and the graph arm's training is the more expensive. The population scores differ by 0.006 at equal examples and 0.021 at equal time in the grid arm's favour, against 0.081 and 0.079 in the first study.
<!-- src: results/study2/wallclock-per-run.md:7-12; paper/figures/fig2-score-cost-study2.md:7-11; paper/figures/fig2-score-cost.md:10-11; journal/2026-10-13-h9-campaign-01.md:72-75 -->

## The two studies side by side {#sec:study2-interaction}

The comparison between the studies is descriptive. The two studies use different seed sets, two regime changes were applied at once, and no interval is computed across studies; the two sets of intervals are placed beside each other and read as such.
<!-- src: docs/protocol-v2.md:32-35,152-158 -->

| Opponent | Reading | First study: graph − grid | Second study: graph − grid |
| --- | --- | ---: | ---: |
| B-RND | same-examples | −0.169 [−0.272, −0.062] | −0.018 [−0.045, +0.008] |
| B-HEU | same-examples | −0.064 [−0.111, −0.017] | −0.003 [−0.046, +0.039] |
| B-MCTS | same-examples | −0.009 [−0.055, +0.028] | +0.003 [−0.082, +0.090] |
| B-RND | same-wall-clock | −0.161 [−0.278, −0.048] | −0.052 [−0.140, +0.002] |
| B-HEU | same-wall-clock | −0.059 [−0.087, −0.029] | +0.013 [−0.032, +0.055] |
| B-MCTS | same-wall-clock | −0.018 [−0.066, +0.025] | −0.025 [−0.091, +0.034] |

Table: The graph−grid contrast of the two studies, per frozen opponent and budget reading: difference of seed-level mean scores with the 95% bootstrap interval over seeds (five independent seeds per arm in each study, resampled independently, 10,000 resamples). First study: seeds 1 to 5, each generation's network trained from a fresh initialisation on that generation's games (cutoff 18.77 h). Second study: seeds 11 to 15, warm start and three-generation replay window (cutoff 17.63 h). The studies are not pooled. {#tbl:study1-vs-study2}
<!-- src: results/study2/study1-vs-study2.md:7-25 -->

The contrast moved toward zero on every opponent under both readings. Against the random opponent it went from −0.169 to −0.018 at equal examples and from −0.161 to −0.052 at equal time; against the heuristic from −0.064 to −0.003 and from −0.059 to +0.013; against the search opponent from −0.009 to +0.003 and from −0.018 to −0.025. Four contrasts that excluded zero in the first study include it in the second, and the sign changed in two cells, both inside intervals that include zero. The graph arm's deficit of the first study is no longer visible at equal examples and is reduced at equal wall-clock, where it survives as an interval touching zero against the random opponent. What the second study does not show is any advantage of the graph arm: its two positive point contrasts (+0.003 and +0.013) are the smallest numbers in their rows.
<!-- src: results/study2/study1-vs-study2.md:7-25 -->

The arms' absolute levels moved in different directions. The graph arm's mean against the random opponent rose from 0.812 to 0.971 at equal examples, which is where its first-study deficit lived; its means against the heuristic and the search opponent moved from 0.065 to 0.074 and from 0.115 to 0.134. The grid arm's mean against the heuristic fell from 0.129 [0.098, 0.165] to 0.077 [0.051, 0.104], two intervals that do not overlap, while its means against the random and the search opponent stayed within 0.01 (0.981 to 0.988; 0.124 to 0.131). Read descriptively, the warm-started regime with a three-generation window did not raise the strength reached against the strong opponents within ten generations at these settings; it narrowed the gap between the arms, and for the grid arm against the heuristic it coincided with a lower level. Whether the lower level is an effect of the regime (a network carried across generations trains on a window that includes its own earlier games) or of the seed set cannot be decided from two studies of five seeds, and the study does not decide it.
<!-- src: results/study2/study1-vs-study2.md:7-25; results/comparison/results-same-examples.md:20-25; results/study2/results-same-examples.md:20-25 -->

![Second study: validation policy top-1 accuracy (left) and value accuracy on non-truncated samples (right) after the first epoch of each generation, as printed by the trainer on the held-out split of the generation's windowed training set; one line per run, five warm-started seeds per arm; blue, grid arm; red, graph arm. Training diagnostics, not strength measurements.](figures/fig6-training-metrics-study2.png){#fig:study2-training width=100%}

The training diagnostics (`@fig:study2-training`{=typst}) separate one run from the other nine. Nine runs end the tenth generation with a value accuracy between 73.3% and 92.1% on their held-out split; graph seed 15 never exceeds 45% and ends at 35.2%, with a policy top-1 falling from 7.9% to 4.7%, yet its final checkpoint scores 0.992 against the random opponent (41% truncation), 0.105 against the heuristic and 0.110 against the search opponent, inside the other seeds' bands. In the first study every graph run's value accuracy rose into the grid arm's band. The run is kept, as the pre-commitments require; it shows that under this regime a network can play at the level of its peers while fitting its own windowed data poorly, and the study has no measurement that explains why.
<!-- src: journal/2026-10-27-h9-analysis-01.md:206-232 -->

Three limits bound this section. The between-study movement is not attributable to the warm start or to the window separately, since both were applied at once by design. The hyperparameters are the first study's untuned defaults in both arms, a choice made at the freeze and stated as a limit of both studies; a tuned graph arm, or a tuned grid arm, might sit elsewhere. And ten generations remain an early regime: the second study moved the pipeline toward the standard practice of self-play systems and the absolute strength against the strong opponents did not move with it, which says that the budget, not only the regime, bounds what either representation shows here.
<!-- src: docs/protocol-v2.md:62-75; journal/2026-10-27-h9-analysis-01.md:166-184 -->

Within these limits the second study answers the objection it was designed to test. The ordering of the first study does not survive the warm-started regime as a deficit: the graph representation, carried across generations and trained on a window of recent games, plays the frozen population as well as the grid representation at equal examples, within five-seed intervals, and within 0.05 of it at equal time, at 2.34 times the cost. It does not play better. The original hypothesis, that the graph representation learns a better policy at equal budget, is unsupported in both regimes; what changed between them is the size of the gap, from a clear grid advantage to none that five seeds can detect, with a conversion pathology that the regime removed in two graph seeds and left in three.
<!-- src: journal/2026-10-27-h9-analysis-01.md:186-205; results/study2/study1-vs-study2.md:7-25 -->
