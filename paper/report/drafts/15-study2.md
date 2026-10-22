# A second study: the comparison under a warm-started loop with a replay window {#sec:study2}

The first study answered its question inside a pipeline that trained every generation's network from a fresh initialisation on that generation's games alone (`@sec:pipeline`{=typst}, `@sec:discussion`{=typst}). This chapter reports a second, separately pre-registered study that applies the two standard remedies, weights carried across generations and training on a window of recent generations, identically to both arms, and asks whether the ordering of the two representations survives. Its protocol was frozen on 13 October 2026, before any run; its campaign started the same day. Everything the first study froze (opponents, openings, evaluation settings, networks, decoder) is reused untouched, so that the two studies differ in the training regime and in nothing else.
<!-- src: docs/protocol-v2.md:3-12 -->

## Why a second study {#sec:study2-why}

The per-generation re-initialisation of the first study is neutral for the comparison, since both encoders saw exactly the same records under the same conventions, but it bounds the regime reached: each network learned from the positions of 500 games, and the absolute strength after ten generations stayed near the ceiling against the random opponent and around 0.1 against the two strong opponents. A reviewer's first objection to the generality of a negative verdict is therefore that the graph representation might need more data per network, or a longer optimisation trajectory, before its structural prior pays. The large self-play systems carry weights from generation to generation and train on a replay window of recent games; a second study under that regime is the direct test of the objection. The question it asks is the first study's question under the new regime (RQ-H1′), with the same hypothesis (H1′): the graph arm reaches a higher mean score against the frozen population than the grid arm at equal budget. A secondary, descriptive question asks whether the graph−grid contrast moves toward zero or changes sign relative to the first study; the two studies are compared side by side and never pooled.
<!-- src: docs/protocol-v2.md:14-45; paper/report/15-discussion.md:205-229 -->

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
| graph, seed 14 | 22 Oct 2026 12:18 | | |
| grid, seed 15 | | | |
| graph, seed 15 | | | |

Table: Execution record of the second study's campaign: start and end of each run (CET) and its total training wall-clock, the sum of the ten per-generation clocks (self-play, training and export; evaluation time excluded). Ten generations of 500 games per run, warm start and three-generation replay window, sequential on one laptop. {#tbl:study2-runs}
<!-- src: journal/2026-10-13-h9-campaign-01.md:58-72 -->

## Results {#sec:study2-results}

<!-- To be written from results/study2/ after the campaign and the cutoff evaluations: equal-time cutoff with its derivation; same-examples and same-wall-clock per-seed tables; seed means and intervals; graph−grid contrasts; cap sensitivity; verdict under the frozen rule, four-element paragraphs. Nothing here is read before the analysis entry. -->

## The two studies side by side {#sec:study2-interaction}

<!-- To be written from results/study2/study1-vs-study2.md: descriptive comparison, no pooling; what moved, what did not; limits. -->
