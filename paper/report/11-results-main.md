# Results: the main comparison (RQ-H1) {#sec:results-main}

This chapter reports the pre-registered comparison exactly as the frozen
protocol defined it: two arms, five independent seeds each, evaluated
against the frozen three-opponent population on the 250 frozen openings,
under two budget readings. Every table shows every seed. Scores exclude
truncated games, which are reported in their own column; intervals are
95% percentile bootstrap intervals over seeds (10,000 resamples). The
statistical procedures and the raw tables with all auxiliary columns are
in `@sec:app-d`{=typst}; the provenance of every number is in
`@sec:app-e`{=typst}.
<!-- src: docs/protocol.md:122; journal/2026-09-19-h6-comparison-01.md:38 -->

## The verdict in one paragraph

Under both budget readings, the graph arm shows no seed-consistent
advantage against any opponent, and every interval on the graph−grid
score difference excludes a meaningful graph advantage: the largest upper
bound across the six contrasts is +0.028. The pre-registered rejection
rule therefore fires, and **H1 is rejected**. At this budget, on
base-game Hive, the graph representation did not help: it scored lower
against two of the three frozen opponents under both readings, and no
better against the third. The remainder of the chapter shows the
evidence behind this paragraph, seed by seed.
<!-- src: journal/2026-10-09-h6-5seed-final-01.md:61; results/comparison/results-arm-difference.md -->

## Reading 1: equal number of training examples

In the first reading both arms are compared at their generation-10
checkpoints: each run has then generated and trained on ten generations
of 500 self-play games under identical simulation budgets, so the two
arms have consumed the same number of training examples.
<!-- src: docs/protocol.md:106; configs/comparison-matrix.yaml -->

| Arm | Seed | B-RND score | B-RND truncation | B-HEU score | B-MCTS score |
| --- | --- | ---: | ---: | ---: | ---: |
| grid | 1 | 0.995 | 0% | 0.150 | 0.125 |
| grid | 2 | 0.975 | 1% | 0.080 | 0.125 |
| grid | 3 | 0.990 | 1% | 0.190 | 0.075 |
| grid | 4 | 0.949 | 11% | 0.105 | 0.085 |
| grid | 5 | 0.995 | 0% | 0.120 | 0.210 |
| graph | 1 | 0.733 | 57% | 0.025 | 0.115 |
| graph | 2 | 0.981 | 20% | 0.050 | 0.125 |
| graph | 3 | 0.722 | 55% | 0.090 | 0.100 |
| graph | 4 | 0.688 | 44% | 0.125 | 0.120 |
| graph | 5 | 0.935 | 23% | 0.035 | 0.115 |

Table: Same-examples reading. Final-checkpoint (generation 10) score of
every run against each frozen opponent; 100 paired colour-swapped games
per opponent per run on the 250 frozen openings at 400 simulations per
move without exploration noise. Score = mean over decided games (win 1,
draw 0.5, loss 0). Truncation = share of the 100 games stopped at the
300-ply cap; no game against B-HEU or B-MCTS was truncated by either
arm. {#tbl:same-examples}
<!-- src: results/comparison/results-same-examples.md:7 -->

Against the legal-random opponent every grid seed scores
at least 0.949 while graph seeds range from 0.688 to 0.981; against the
heuristic, grid seeds range from 0.080 to 0.190 and graph seeds from
0.025 to 0.125; against the search opponent the two arms overlap
(0.075–0.210 against 0.100–0.125). The graph arm truncates 20–57% of its
games against the random opponent; the grid arm 0–11%.
<!-- src: results/comparison/results-same-examples.md:7 -->

| Arm | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grid | 0.981 [0.964, 0.994] | 0.129 [0.098, 0.165] | 0.124 [0.087, 0.168] |
| graph | 0.812 [0.710, 0.920] | 0.065 [0.034, 0.100] | 0.115 [0.107, 0.121] |

Table: Same-examples reading. Seed-level mean score per arm and
opponent with the 95% bootstrap interval over the five seeds. {#tbl:same-examples-means}
<!-- src: results/comparison/results-same-examples.md:20 -->

## Reading 2: equal wall-clock on the same machine

In the second reading each run is taken at the last checkpoint it had
completed within the equal-time cutoff of 18.77 hours, the median total
wall-clock of the three original grid runs, computed on 16 September 2026
before any cross-arm comparison. Because the graph arm's generations are
roughly twice as expensive on this machine, the cutoff selects
generation 9 or 10 for the grid runs (the generation-10 checkpoint is
reached within the cutoff by four of the five) and generations 3 to 6
for the graph runs: grid seeds 1–5 are read at generations 10, 10, 9, 10
and 10; graph seeds 1–5 at generations 4, 5, 5, 3 and 6 (counting the
initial network as generation 1; in the run logs these checkpoints are
labelled gen009/gen009/gen008/gen009/gen009 and
gen003/gen004/gen004/gen002/gen005).
<!-- src: journal/2026-09-16-h6-progress-01.md:36; journal/2026-10-09-h6-5seed-final-01.md:22 -->

| Arm | Seed | B-RND score | B-RND truncation | B-HEU score | B-MCTS score |
| --- | --- | ---: | ---: | ---: | ---: |
| grid | 1 | 0.995 | 0% | 0.150 | 0.125 |
| grid | 2 | 0.975 | 1% | 0.080 | 0.125 |
| grid | 3 | 0.939 | 1% | 0.145 | 0.080 |
| grid | 4 | 0.949 | 11% | 0.105 | 0.085 |
| grid | 5 | 0.995 | 0% | 0.120 | 0.210 |
| graph | 1 | 0.798 | 58% | 0.045 | 0.075 |
| graph | 2 | 0.926 | 39% | 0.055 | 0.110 |
| graph | 3 | 0.713 | 53% | 0.060 | 0.105 |
| graph | 4 | 0.631 | 39% | 0.100 | 0.150 |
| graph | 5 | 0.980 | 24% | 0.045 | 0.095 |

Table: Same-wall-clock reading. Score of every run at its last
checkpoint completed within the 18.77-hour cutoff, against each frozen
opponent; same evaluation as `@tbl:same-examples`{=typst} (100 paired
games per opponent, 250 frozen openings, 400 simulations, no noise).
Truncation = share of games at the 300-ply cap; none against B-HEU or
B-MCTS. {#tbl:same-wallclock}
<!-- src: results/comparison/results-same-wallclock.md:7 -->

| Arm | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grid | 0.971 [0.950, 0.991] | 0.120 [0.098, 0.142] | 0.125 [0.090, 0.168] |
| graph | 0.810 [0.697, 0.922] | 0.061 [0.047, 0.081] | 0.107 [0.087, 0.130] |

Table: Same-wall-clock reading. Seed-level mean score per arm and
opponent with the 95% bootstrap interval over the five seeds. {#tbl:same-wallclock-means}
<!-- src: results/comparison/results-same-wallclock.md:20 -->

The picture of the first reading persists at equal
time: the grid arm's means are higher against the random and the
heuristic opponents and overlapping against the search opponent; the
graph arm's truncation against the random opponent is 24–58%.
<!-- src: results/comparison/results-same-wallclock.md:7 -->

## The arm contrast

| Opponent | Same-examples: graph − grid | Same-wall-clock: graph − grid |
| --- | ---: | ---: |
| B-RND (legal-random) | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| B-HEU (heuristic) | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| B-MCTS (search, 6,400 simulations) | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

Table: The pre-registered contrast, the difference of seed-level mean
scores (graph arm minus grid arm), with the 95% bootstrap interval over
seeds (five independent seeds per arm, resampled independently, 10,000
resamples). A negative value favours the grid arm. {#tbl:contrast}
<!-- src: results/comparison/results-arm-difference.md -->

Four of the six contrasts exclude zero, all in the grid
arm's favour; the two contrasts against the search opponent straddle
zero.

Against the legal-random opponent the graph−grid
difference is −0.169 [−0.272, −0.062] at equal examples and −0.161
[−0.278, −0.048] at equal time; against the heuristic, −0.064 [−0.111,
−0.017] and −0.059 [−0.087, −0.029]; against the search opponent,
−0.009 [−0.055, +0.028] and −0.018 [−0.066, +0.025].
The largest upper bound of any interval is +0.028, which is the largest
graph advantage the data leave room for under the most favourable
reading and opponent.
<!-- src: results/comparison/results-arm-difference.md -->

The frozen rejection rule required, under both
readings, the absence of a seed-consistent graph advantage together with
intervals excluding a meaningful graph advantage. Both conditions hold:
no opponent shows a consistent per-seed ordering in the graph arm's
favour (`@tbl:same-examples`{=typst}, `@tbl:same-wallclock`{=typst}),
and no interval admits an advantage above +0.028. H1 is rejected. The
result is consistent across seeds and holds under the two budget
equalisations; it does not rest on a single interval.
<!-- src: docs/protocol.md:32 -->

Five seeds per arm bound the statistics: against the search
opponent, where both arms score around 0.1, the data cannot distinguish
the arms. The rejection concerns this simple relational message-passing
network at this capacity and this budget; it says nothing about graph
representations at larger budgets or with other architectures.

## How the five-seed analysis relates to the three-seed analysis

The protocol pre-registered three seeds per arm with an option of five.
The three-seed analysis of 19 September 2026 already rejected H1 under
both readings (contrasts against the random opponent −0.175 [−0.268,
−0.007] and −0.158 [−0.254, −0.050]; against the heuristic −0.085
[−0.143, −0.025] and −0.072 [−0.100, −0.028]; against the search
opponent +0.005 [−0.020, +0.035] and −0.013 [−0.040, +0.015]). Seeds 4
and 5 were then added to both arms under written pre-commitments made
on 26 September 2026: the final analysis would use all five seeds under
the same rule, the cutoff would stay unchanged, and the two-stage
collection would be disclosed. The extension tightened four of the six intervals,
absorbed the single graph-better seed pair observed against the
heuristic (graph seed 4 at 0.125 against grid seed 4 at 0.105) and the
best search-opponent score of any run (grid seed 5 at 0.210), and did not
change the verdict. The five-seed tables above are the study's final
numbers.
<!-- src: journal/2026-09-19-h6-comparison-01.md:56; journal/2026-10-09-h6-5seed-final-01.md:34 -->

## Can the move cap rescue the hypothesis?

Truncation was defined as a separate outcome before the first run, and
the protocol required the primary result to be recomputed under
alternative treatments of truncated games. The strongest treatment in
the graph arm's favour scores every truncated game as a win for the arm
under test, which is an upper bound on what any larger cap could deliver. Under
that bound, computed from the per-game records of the three original
seeds, the graph−grid difference against the random opponent is still
−0.072 at equal examples and −0.058 at equal time; the direction of the
contrast is unchanged under every treatment (excluded, scored 0.5,
scored as loss, scored as win). The cap value therefore
cannot reverse the verdict; it can only change its size.
<!-- src: journal/2026-09-19-h6-comparison-01.md:66; docs/protocol.md:69 -->

## Where the deficit lives

Putting the three opponents side by side shows where the deficit lies:
it is largest against the weakest opponent and absent against the
strongest. Against legal-random, where strength is mostly the
ability to finish a surround that nothing resists, the graph arm wins
material and then fails to convert; the truncation column is the trace
of that failure. Against the heuristic, which attacks the queen directly,
the graph arm's defence is weaker than the grid arm's. Against the search
opponent, both arms are in a low-score regime where ten generations of
small-budget self-play have not produced an attack either arm can
sustain. `@sec:results-qualitative`{=typst} examines these mechanisms on
individual games; `@sec:discussion`{=typst} weighs the explanations.
<!-- src: paper/ch7-discussion.md:7 -->

![Mean score against the frozen population (average of the three
opponents, truncations excluded) as a function of cumulative training
wall-clock, for all ten main runs; evaluations at generations 5, 8 and 10
(20, 20 and 100 games per opponent). Blue: grid arm; red: graph arm; one
line per seed. The dashed vertical line marks the equal-time cutoff of
18.77 hours.](figures/fig1-score-vs-time.png){#fig:score-vs-time width=92%}

<!-- src: scripts/make_figures.py:68 -->

`@fig:score-vs-time`{=typst} shows the two readings at once: at any
given wall-clock the grid arm sits above the graph arm, and at the
cutoff the graph runs have completed less than half of their
generations. `@sec:results-cost`{=typst} quantifies the cost side.
