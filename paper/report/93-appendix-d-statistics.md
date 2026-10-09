# Statistical procedures and raw result tables {#sec:app-d}

This appendix states the estimators of the study exactly as they were computed and reproduces, without rounding or recomputation, every per-run number behind the main comparison and the ablations. Values are copied from the regenerated result files and from the dated analysis records; where a record does not state a quantity, the cell says so.

## Score, truncation rate and sensitivity score

An evaluation match between one checkpoint and one opponent is 100 games on the frozen opening lines, each line played once with each colour. A game ends in a win, a draw, a loss, or a truncation at the 300-ply cap. From the game rows of one (seed, opponent) cell three statistics are derived: the **score**, the mean of win = 1, draw = 0.5, loss = 0 over the *non-truncated* games; the **truncation rate**, the number of truncated games divided by the 100 games played; and the **sensitivity score**, the mean over *all* 100 games with every truncated game counted 0.5, reported as a column and never used as the primary metric. Games are aggregated to one score per cell first; the seed is the unit of every later step, and no game enters any interval as an independent observation. <!-- src: scripts/analyze_comparison.py:8-14,48-59 --> <!-- src: scripts/make_results.py:13-16 --> <!-- src: results/comparison/opponents-manifest.md:42-44 -->

## The seed-level bootstrap

Every interval in the report is a percentile bootstrap whose resampling unit is the seed, that is, one independent training run. For a cell series $s_1, \dots, s_n$ (one score per seed, with $n$ = 5 in the final analysis and $n$ = 3 in the analysis of 19 September 2026), the procedure draws $n$ indices uniformly with replacement, averages the corresponding scores, repeats this $B$ = 10,000 times, sorts the resample means, and reports the elements at zero-based positions $\lfloor 0.025\,B \rfloor$ and $\lfloor 0.975\,B \rfloor$ as the 95% interval. No bias correction or acceleration is applied; the point estimate printed beside each interval is the plain mean of the $n$ per-seed scores. The pseudo-random generator is Python's `random.Random` seeded with the constant 0 for every call, so every interval is reproducible to the last digit from the same per-seed inputs. <!-- src: scripts/make_results.py:79-84 --> <!-- src: scripts/analyze_comparison.py:87-97 -->

The arm contrast is the difference of seed-level means, graph minus grid. In each of the $B$ = 10,000 resamples the graph seed set and the grid seed set are resampled *independently*, each with its own size, and the difference of the two resample means is recorded; the sorted differences are cut at the same two positions. Seeds are independent across arms by design (seed $k$ of one arm shares nothing with seed $k$ of the other beyond the frozen openings and opponents), so no pairing across arms is imposed. The same estimator serves seed sets of unequal size: the A1′ supplement (three seeds) against the full graph arm (five seeds) resamples three and five scores respectively. <!-- src: scripts/make_results.py:87-94,145-155 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:22-37 -->

```
procedure PERCENTILE-CI(x[1..n]; B = 10,000; seed = 0)
    rng <- Random(seed)
    for b in 1..B:
        m[b] <- mean of n draws x[rng.randrange(n)]
    sort m ascending
    return m[floor(0.025 * B)], m[floor(0.975 * B)]       # zero-based positions

procedure DIFF-CI(a[1..p], c[1..q]; B = 10,000; seed = 0)   # a = graph, c = grid
    rng <- Random(seed)
    for b in 1..B:
        d[b] <- (mean of p draws a[rng.randrange(p)]) - (mean of q draws c[rng.randrange(q)])
    sort d ascending
    return d[floor(0.025 * B)], d[floor(0.975 * B)]
```

<!-- src: scripts/make_results.py:79-94 -->

## Raw per-seed tables: same-examples reading

The same-examples reading evaluates each run's checkpoint after the tenth and last generation (checkpoint identifiers are zero-based, so this is gen009), every run having consumed the same self-play budget of 10 generations × 500 games. `@tbl:d-se-scores`{=typst} gives the scores and the truncation rate against legal-random; `@tbl:d-sens`{=typst}, after the second reading, gives the sensitivity scores against legal-random under both readings; legal-random is the only opponent against which any game was truncated. <!-- src: results/comparison/results-same-examples.md:1-16 --> <!-- src: scripts/make_results.py:65-69 -->

| Arm | Seed | B-RND score | B-RND trunc. | B-HEU score | B-MCTS score |
| --- | --- | ---: | ---: | ---: | ---: |
| grid | 1 | 0.995 | 0 % | 0.150 | 0.125 |
| grid | 2 | 0.975 | 1 % | 0.080 | 0.125 |
| grid | 3 | 0.990 | 1 % | 0.190 | 0.075 |
| grid | 4 | 0.949 | 11 % | 0.105 | 0.085 |
| grid | 5 | 0.995 | 0 % | 0.120 | 0.210 |
| graph | 1 | 0.733 | 57 % | 0.025 | 0.115 |
| graph | 2 | 0.981 | 20 % | 0.050 | 0.125 |
| graph | 3 | 0.722 | 55 % | 0.090 | 0.100 |
| graph | 4 | 0.688 | 44 % | 0.125 | 0.120 |
| graph | 5 | 0.935 | 23 % | 0.035 | 0.115 |

Table: Per-run scores, same-examples reading: the tenth-generation checkpoint of each of five independent training runs per arm (10 generations × 500 self-play games each), 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations per decision, against the frozen population (B-RND legal-random, B-HEU heuristic, B-MCTS search at 6,400 simulations). Score = mean of win 1 / draw 0.5 / loss 0 over non-truncated games (a fraction); trunc. = share of the 100 games stopped at the 300-ply cap, 0 % against B-HEU and B-MCTS in every cell and omitted. Raw values, no interval. {#tbl:d-se-scores}

<!-- src: results/comparison/results-same-examples.md:5-16 -->

## Raw per-seed tables: same-wall-clock reading

The same-wall-clock reading evaluates each run's last checkpoint completed within the equal-time cutoff (`@sec:app-d-cutoff`{=typst}). Where that checkpoint is the final one, the final evaluation set serves both readings, so the grid rows of seeds 1, 2, 4 and 5 are identical in both readings. <!-- src: scripts/make_results.py:47-76 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:22-29 -->

| Arm | Seed | Checkpoint | B-RND score | B-RND trunc. | B-HEU score | B-MCTS score |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| grid | 1 | gen009 | 0.995 | 0 % | 0.150 | 0.125 |
| grid | 2 | gen009 | 0.975 | 1 % | 0.080 | 0.125 |
| grid | 3 | gen008 | 0.939 | 1 % | 0.145 | 0.080 |
| grid | 4 | gen009 | 0.949 | 11 % | 0.105 | 0.085 |
| grid | 5 | gen009 | 0.995 | 0 % | 0.120 | 0.210 |
| graph | 1 | gen003 | 0.798 | 58 % | 0.045 | 0.075 |
| graph | 2 | gen004 | 0.926 | 39 % | 0.055 | 0.110 |
| graph | 3 | gen004 | 0.713 | 53 % | 0.060 | 0.105 |
| graph | 4 | gen002 | 0.631 | 39 % | 0.100 | 0.150 |
| graph | 5 | gen005 | 0.980 | 24 % | 0.045 | 0.095 |

Table: Per-run scores, same-wall-clock reading: for each of five independent training runs per arm, the last checkpoint completed within 18.77 h of cumulative training wall-clock (identifiers zero-based; gen009 is the tenth generation), 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations per decision, against the frozen population (B-RND legal-random, B-HEU heuristic, B-MCTS search at 6,400 simulations). Score = mean of win 1 / draw 0.5 / loss 0 over non-truncated games (a fraction); trunc. = share of the 100 games stopped at the 300-ply cap, 0 % against B-HEU and B-MCTS in every cell and omitted. Raw values, no interval. {#tbl:d-swc-scores}

<!-- src: results/comparison/results-same-wallclock.md:5-16 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:26-29 -->

| Arm | Seed | Same-examples: B-RND sens. | Same-wall-clock: B-RND sens. |
| --- | --- | ---: | ---: |
| grid | 1 | 0.9950 | 0.9950 |
| grid | 2 | 0.9700 | 0.9700 |
| grid | 3 | 0.9850 | 0.9350 |
| grid | 4 | 0.9000 | 0.9000 |
| grid | 5 | 0.9950 | 0.9950 |
| graph | 1 | 0.6000 | 0.6250 |
| graph | 2 | 0.8850 | 0.7600 |
| graph | 3 | 0.6000 | 0.6000 |
| graph | 4 | 0.6050 | 0.5800 |
| graph | 5 | 0.8350 | 0.8650 |

Table: Sensitivity scores against legal-random (B-RND) under both readings, for the same runs, checkpoints and evaluation volume as `@tbl:d-se-scores`{=typst} and `@tbl:d-swc-scores`{=typst}: the mean over all 100 games of the cell with every truncated game counted 0.5, at the four-decimal precision of the comma-separated result files. Against B-HEU and B-MCTS no game of any run was truncated under either reading, so there the sensitivity score equals the score of the main tables in every cell. Raw values, no interval. {#tbl:d-sens}

<!-- src: results/comparison/results-same-examples.csv:2-31 --> <!-- src: results/comparison/results-same-wallclock.csv:2-31 -->

## Seed-level means, intervals and arm contrasts

`@tbl:d-means`{=typst} gives the mean of the five per-seed scores for each arm, opponent and reading with its seed-level bootstrap interval; `@tbl:d-contrast`{=typst} gives the graph-minus-grid differences of those means. These are the final numbers of the study. <!-- src: results/comparison/results-same-examples.md:18-25 --> <!-- src: results/comparison/results-same-wallclock.md:18-25 --> <!-- src: results/comparison/results-arm-difference.md:1-15 -->

| Reading | Arm | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | ---: | ---: | ---: |
| same-examples | grid | 0.981 [0.964, 0.994] | 0.129 [0.098, 0.165] | 0.124 [0.087, 0.168] |
| same-examples | graph | 0.812 [0.710, 0.920] | 0.065 [0.034, 0.100] | 0.115 [0.107, 0.121] |
| same-wall-clock | grid | 0.971 [0.950, 0.991] | 0.120 [0.098, 0.142] | 0.125 [0.090, 0.168] |
| same-wall-clock | graph | 0.810 [0.697, 0.922] | 0.061 [0.047, 0.081] | 0.107 [0.087, 0.130] |

Table: Seed-level mean scores of the two arms against each frozen opponent under both budget readings (same-examples: tenth-generation checkpoints after 10 generations × 500 games; same-wall-clock: last checkpoint within 18.77 h), five independent training runs per arm, 100 paired colour-swapped games per opponent and run. Each entry is the plain mean of the five per-run scores (fraction of decided games, truncations excluded) with its 95% percentile bootstrap interval over seeds (10,000 resamples). {#tbl:d-means}

<!-- src: results/comparison/results-same-examples.md:20-25 --> <!-- src: results/comparison/results-same-wallclock.md:20-25 -->

| Opponent | Same-examples: graph − grid | Same-wall-clock: graph − grid |
| --- | ---: | ---: |
| B-RND | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| B-HEU | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| B-MCTS | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

Table: Arm contrast: difference of the seed-level means of `@tbl:d-means`{=typst}, graph arm minus grid arm, per frozen opponent and budget reading, five independent training runs per arm; unit: score difference (fraction of decided games). Brackets: 95% percentile bootstrap interval from the five graph seeds and the five grid seeds resampled independently, 10,000 resamples. {#tbl:d-contrast}

<!-- src: results/comparison/results-arm-difference.md:5-7,13-15 -->

The seeds were collected in two stages: seeds 1–3 of both arms in the campaign of 10–17 September 2026, analysed on 19 September 2026; seeds 4–5 of both arms between 27 September and 2 October 2026, under a commitment made before they were run to use all five seeds in the final analysis whatever their direction. `@tbl:d-three-seed`{=typst} records the three-seed analysis so that both stages are on the record; the extension tightened four of the six contrast intervals, and the largest upper bound of any contrast moved from +0.035 to +0.028. <!-- src: journal/2026-10-09-h6-5seed-final-01.md:4-13,59-67 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:49-62,92-96 -->

| Quantity | Reading | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | ---: | ---: | ---: |
| grid mean | same-examples | 0.987 [0.975, 0.995] | 0.140 [0.080, 0.190] | 0.108 [0.075, 0.125] |
| graph mean | same-examples | 0.812 [0.722, 0.981] | 0.055 [0.025, 0.090] | 0.113 [0.100, 0.125] |
| grid mean | same-wall-clock | 0.970 [0.939, 0.995] | 0.125 [0.080, 0.150] | 0.110 [0.080, 0.125] |
| graph mean | same-wall-clock | 0.812 [0.713, 0.926] | 0.053 [0.045, 0.060] | 0.097 [0.075, 0.110] |
| graph − grid | same-examples | −0.175 [−0.268, −0.007] | −0.085 [−0.143, −0.025] | +0.005 [−0.020, +0.035] |
| graph − grid | same-wall-clock | −0.158 [−0.254, −0.050] | −0.072 [−0.100, −0.028] | −0.013 [−0.040, +0.015] |

Table: The original three-seed analysis of 19 September 2026 (seeds 1–3 of each arm; same opponents, budget readings and evaluation volume as `@tbl:d-means`{=typst}): seed-level means and graph-minus-grid contrasts with 95% percentile bootstrap intervals over three seeds per arm (10,000 resamples; arms resampled independently). Superseded by the five-seed tables; kept as the record of the first stage of seed collection. {#tbl:d-three-seed}

<!-- src: journal/2026-09-19-h6-comparison-01.md:49-62 -->

## The equal-time cutoff and the checkpoint map {#sec:app-d-cutoff}

The cutoff was fixed by a rule stated before the campaign: the median of the full-run training wall-clocks of the grid arm's three original runs. Those totals were 18.77 h, 16.73 h and 19.07 h, so the cutoff is 18.77 h; it was computed on 16 September 2026, before any cross-arm number existed, and the two later grid seeds never entered the median. The final computation takes the median exactly from the per-generation clock files rather than from the rounded constant, so that the defining run's own final checkpoint sits at the cutoff inclusively; the resulting map for seeds 1–3 reproduces the one recorded on 16 September 2026 checkpoint for checkpoint. For each run the checkpoint retained is the last whose cumulative training wall-clock does not exceed the cutoff (`@tbl:d-cutoff`{=typst}). <!-- src: journal/2026-09-16-h6-progress-01.md:36-42 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:22-29 --> <!-- src: scripts/make_results.py:30-62 -->

| Arm | Seed | Checkpoint at the cutoff | Cumulative wall-clock | Evaluation set |
| --- | --- | --- | ---: | --- |
| grid | 1 | gen009 (final) | 18.77 h | final set reused |
| grid | 2 | gen009 (final) | 16.73 h | final set reused |
| grid | 3 | gen008 | 17.22 h | equal-time set |
| grid | 4 | gen009 (final) | not stated | final set reused |
| grid | 5 | gen009 (final) | not stated | final set reused |
| graph | 1 | gen003 | 16.50 h | equal-time set |
| graph | 2 | gen004 | 16.06 h | equal-time set |
| graph | 3 | gen004 | not stated | equal-time set |
| graph | 4 | gen002 | not stated | equal-time set |
| graph | 5 | gen005 | not stated | equal-time set |

Table: Checkpoint retained for the same-wall-clock reading in each of the ten training runs: the last checkpoint completed within the equal-time cutoff of 18.77 h of cumulative training wall-clock (identifiers zero-based; gen009 is the tenth and final generation). Cumulative hours are those stated in the analysis records; "not stated" means the record gives the checkpoint but not the hours. Where the retained checkpoint is the final one, the final evaluation set (100 paired games per opponent) serves both readings; otherwise a separate equal-time set of the same volume was evaluated. {#tbl:d-cutoff}

<!-- src: journal/2026-09-16-h6-progress-01.md:36-42 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:26-29 --> <!-- src: scripts/make_results.py:47-62 -->

The map is the measured content of the second reading: at equal wall-clock the graph arm had completed 3–6 of its ten generations (4–5 over the original three seeds), the grid arm nine or ten. `@tbl:d-wallclock`{=typst} gives the full-run training wall-clocks behind the map. Over the five seeds the means are 18.00 h (grid) and 36.70 h (graph), a ratio of 2.04×; over the original three seeds they were 18.2 h and 35.7 h, a ratio of 2.0×. The equal-time evaluation sets for seeds 1–3 were run on 18 September 2026 (about 11 h), those for the graph arm's seeds 4 and 5 on 6 October 2026 (about 6 h). <!-- src: paper/claims.md:29 --> <!-- src: results/comparison/wallclock-per-run.md:1-10 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:24-25,71-72 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:3,16 -->

| Arm | Seed 1 | Seed 2 | Seed 3 | Seed 4 | Seed 5 | Mean |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| grid | 18.77 | 16.73 | 19.07 | 18.23 | 17.19 | 18.00 |
| graph | 43.07 | 32.71 | 31.28 | 49.86 | 26.57 | 36.70 |

Table: Training wall-clock of each of the ten main-campaign runs, in hours: the per-generation self-play generation and training seconds summed over the 10 generations of the run (10 × 500 games), evaluation games excluded, from each run's clock log; one machine, four worker threads, sequential runs. The sums are 90.0 h (grid) and 183.5 h (graph), 273.5 h in all. The equal-time cutoff is the median of the three grid values of seeds 1–3. {#tbl:d-wallclock}

<!-- src: results/comparison/wallclock-per-run.md:1-10 -->

## Cap-sensitivity bounds

The protocol brackets the primary estimator (truncations excluded) with three alternative treatments of every truncated game: counted 0.5 (the sensitivity scores of `@tbl:d-sens`{=typst}), counted as a loss for the arm under test, and counted as a win for it; the last is an upper bound on what any larger cap could do for an arm that truncates. The bounds were computed from the per-game records in the analysis of 19 September 2026 (three seeds per arm): with every truncated game scored as a win for the arm under test, the graph-minus-grid contrast against legal-random is still −0.072 under the same-examples reading and −0.058 under the same-wall-clock reading, and its direction is unchanged under every treatment (excluded, 0.5, loss, win). Against B-HEU and B-MCTS no game of either arm was truncated, so all treatments coincide there. The final analysis record does not restate the bounds at five seeds. Because the graph arm truncated 20–57% of its games against legal-random in the original seeds and 23–44% in the extension seeds (grid: 0–1%, one extension seed at 11%), its primary score against that opponent is a mean over fewer decided games (43 to 80 per seed) than the grid arm's. <!-- src: journal/2026-09-19-h6-comparison-01.md:64-70 --> <!-- src: paper/ch5-protocol.md:45-49 --> <!-- src: paper/results-comparison.md:51-61 --> <!-- src: paper/ch7-discussion.md:58-61 -->

## Ablation raw tables

Three variants of the graph arm were trained with three seeds each at the full budget (10 generations × 500 games, identical self-play, training and evaluation settings) and evaluated at their tenth-generation checkpoint under the same-examples reading. `@tbl:d-abl-runs`{=typst} summarises the variants; `@tbl:d-abl-a2`{=typst} and `@tbl:d-abl-a1prime`{=typst} give the per-seed scores of the two that trained; `@tbl:d-abl-contrast`{=typst} gives the contrasts against the full graph arm. <!-- src: results/ablations/README.md:1-10 -->

| Variant | Component changed | Seeds | Training wall-clock | Outcome |
| --- | --- | --- | ---: | --- |
| A1 (`graph-untyped`) | six direction-typed edge matrices replaced by one shared matrix | 1, 2, 3 | 7.75 / 8.01 / 7.61 h | training diverged to NaN in generation 0, 3 of 3 seeds |
| A2 (`graph-nogpool`) | global-pooling bias removed from every layer (1.37M parameters vs 1.47M) | 1, 2, 3 | 39.90 / 47.44 / 32.05 h | trained; no measurable effect |
| A1′ (`graph-untyped-clip`) | untyped edges *and* gradient-norm clipping at 1.0 (two components) | 1, 2, 3 | 23.89 / 30.35 / 27.68 h | trained; within the full arm's band |

Table: The three ablation variants of the graph arm, each trained with three independent seeds at the full budget of the main comparison (10 generations × 500 self-play games; same frozen opponents, openings and evaluation settings). Training wall-clock in hours per seed under the same accounting as `@tbl:d-wallclock`{=typst} (per-generation self-play and training seconds summed, evaluation games excluded); the reference graph runs of seeds 1–3 took 43.07, 32.71 and 31.28 h. A1's short runs are a symptom of its divergence (a NaN policy plays short degenerate games) rather than a saving. {#tbl:d-abl-runs}

<!-- src: results/comparison/wallclock-per-run.md --> <!-- src: journal/2026-09-23-h7-a1-divergence-01.md:33-40 --> <!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:4-18 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:4-14 -->

No score table is given for A1 because none exists as a strength measurement: every forward pass of all three networks returned NaN for policy and value from the first checkpoint onwards, and the final evaluations of the three independently seeded runs were identical to the game (0 wins, 0 draws and 100 losses against B-HEU; 2 wins and 45 draws with 53% truncation against B-RND), which independent trainings cannot produce. The training logs carry the signature "policy top-1 100.0%, value acc 0.0%" from generation 1 onwards, and the degenerate games averaged about 42 plies with no truncation and no resignation. The raw evaluation files are kept but excluded from every table as scores. <!-- src: journal/2026-09-23-h7-a1-divergence-01.md:22-46 -->

| Opponent | A2 seed 1 | A2 seed 2 | A2 seed 3 | full seed 1 | full seed 2 | full seed 3 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| B-RND | 0.768 (59 %) | 0.714 (65 %) | 0.952 (17 %) | 0.733 (57 %) | 0.981 (20 %) | 0.722 (55 %) |
| B-HEU | 0.050 (0 %) | 0.070 (0 %) | 0.025 (0 %) | 0.025 (0 %) | 0.050 (0 %) | 0.090 (0 %) |
| B-MCTS | 0.070 (0 %) | 0.125 (0 %) | 0.105 (0 %) | 0.115 (0 %) | 0.125 (0 %) | 0.100 (0 %) |

Table: Per-seed final scores of ablation A2 (global-pooling bias removed) beside the full graph arm's seeds 1–3, same-examples reading: tenth-generation checkpoints, 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations against the frozen population. Score = fraction of decided games won (draws 0.5); truncation rate of the 100 games in parentheses. Three independent training runs per variant; raw values, no interval. {#tbl:d-abl-a2}

<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:31-38 -->

| Opponent | A1′ seed 1 | A1′ seed 2 | A1′ seed 3 |
| --- | ---: | ---: | ---: |
| B-RND | 0.566 (47 %) | 0.671 (59 %) | 0.995 (0 %) |
| B-HEU | 0.035 | 0.135 | 0.110 |
| B-MCTS | 0.090 | 0.195 | 0.060 |

Table: Per-seed final scores of the A1′ supplement (untyped edges with gradient clipping at 1.0, an explicitly two-component variant), same-examples reading: tenth-generation checkpoints, 100 paired colour-swapped games per opponent on the frozen openings at 400 simulations against the frozen population. Score = fraction of decided games won (draws 0.5); the truncation rate of the 100 games is given in parentheses where the record states it (legal-random only). Three independent training runs; raw values, no interval. {#tbl:d-abl-a1prime}

<!-- src: journal/2026-10-09-h7-a1prime-01.md:26-27 -->

| Opponent | A2 − full (3 vs 3 seeds) | A1′ mean (3 seeds) | full graph mean (5 seeds) | A1′ − full (3 vs 5 seeds) |
| --- | ---: | ---: | ---: | ---: |
| B-RND | −0.001 [−0.170, +0.165] | 0.744 | 0.810 | −0.066 [−0.254, +0.130] |
| B-HEU | −0.007 [−0.043, +0.030] | 0.093 | 0.061 | +0.032 [−0.011, +0.078] |
| B-MCTS | −0.013 [−0.043, +0.013] | 0.115 | 0.107 | +0.008 [−0.040, +0.063] |

Table: Ablation contrasts against the full graph arm, same-examples reading, frozen population, 100 paired games per opponent and run. A2 − full: difference of seed-level means over seeds 1–3 of both variants. A1′ − full: difference between the A1′ mean over its three seeds and the full graph arm's mean over its five seeds. Unit: score difference (fraction of decided games). Brackets: 95% percentile bootstrap interval, the two seed sets resampled independently with their own sizes, 10,000 resamples. The A1′ contrast is confounded by the clipping and is never attributed to edge typing alone. {#tbl:d-abl-contrast}

<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:34-38 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:28-37 --> <!-- src: results/ablations/README.md:8-10 -->

## Per-generation evaluation data

No per-generation score table exists in the result files or the analysis records. The score-versus-time and per-opponent trajectory figures are drawn directly from each run's evaluation records: every main-campaign run was evaluated, with the pinned settings and volume, at the checkpoints of generations 5, 8 and 10 (identifiers gen004, gen007 and gen009) and, where different from the final one, at its equal-time checkpoint; the population score at a point is the mean over the three opponents of the cell scores defined above, and the time axis is the cumulative sum of the run's per-generation training durations. The curves are reproducible from the released per-game records and clock files; their numbers are not reproduced here. <!-- src: scripts/make_figures.py:34-56,357-372 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:36-41 -->
