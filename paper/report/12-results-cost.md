# Results: cost and efficiency (RQ-H2) {#sec:results-cost}

The second research question asks how the two representations compare
when the budget is read as a number of training examples and when it is
read as time on the same hardware. The protocol required both readings
and required every run to report its wall-clock, its hardware, the
number of training states consumed and the simulations per decision.
This chapter reports those costs and puts the two readings side by
side.
<!-- src: docs/protocol.md:99 -->

## What each arm costs on the study machine

| Metric | Grid arm | Graph arm |
| --- | ---: | ---: |
| Parameters | 1.44 M | 1.47 M (+1.5%) |
| Best-provider inference, batch 1 | 2.62 ms (neural accelerator) | 3.67 ms (CPU) |
| Training wall-clock per run, mean of 5 seeds (10 generations × 500 games) | 18.0 h | 36.7 h (2.0×) |
| Equivalent self-play cost | 13.0 s/game | 26.4 s/game |
| Training throughput benchmark (batch 128, forward + backward) | 274 pos/s | 138 pos/s |
| Population score, same-examples reading | 0.411 | 0.331 |
| Population score, same-wall-clock reading (cutoff 18.77 h) | 0.405 | 0.326 |

Table: Cost and score summary per arm (H-T2). Training wall-clock covers
self-play generation and training for the ten generations of a run,
evaluation games excluded, averaged over the five seeds; the equivalent
self-play cost divides it by the 5,000 games of a run. Inference and
training-throughput figures are benchmark measurements of 10 September
2026 on the study machine (Apple M1 Pro, 10 cores, 16 GB). Population
score = mean over the three frozen opponents of the seed-level mean score
(truncations excluded). {#tbl:cost}
<!-- src: paper/figures/fig2-score-cost.md; docs/representations/comparison-controls.md:14 -->

The two networks are matched in size. The graph arm's single evaluation
is 1.4× slower at its best provider, its training throughput is half
that of the grid arm, and a full run costs it twice the wall-clock. Per
run, the five grid seeds took 18.77, 16.73, 19.07, 18.23 and 17.19
hours of training wall-clock; the five graph seeds took 43.07, 32.71,
31.28, 49.86 and 26.57 hours.
<!-- src: results/comparison/wallclock-per-run.md; docs/representations/comparison-controls.md:28 -->

The measured wall-clock ratio is 2.0× (36.7 h against 18.0 h on
average). At the sizing stage the ratio had been estimated at 1.7×; the
measured ratio over the first five completed runs was 2.1×, and the
estimate was replaced by the measured figure in all budget accounting
before any comparison was computed.
<!-- src: journal/2026-09-16-h6-progress-01.md:31 -->

Self-play generation dominates the wall-clock of both arms; in the
pilot, generation 0 took about 60 minutes of self-play against about
3.5 minutes of training. The graph arm's extra cost is therefore paid
mostly in the search, through its slower per-position inference and its
CPU execution. The asymmetry is a property of the deployment hardware:
the convolutional network maps cleanly onto the machine's neural
accelerator (2.62 ms per evaluation), whereas the gather-heavy graph
network falls back to the CPU for a large share of its operations and
runs fastest there (3.67 ms on the CPU against 9.84 ms on the
accelerator, with 147 of 287 operator nodes supported). The protocol
chose to report and charge this asymmetry rather than to equalise it
away. The same-wall-clock reading thus reflects what each representation
costs on this machine, while the same-examples reading is unaffected by
it.
<!-- src: docs/representations/comparison-controls.md:19; docs/representations/comparison-controls.md:43 -->

On a different accelerator the ratio could change in either direction;
on the CPU alone the graph network is the faster of the two at inference
(3.67 ms against 23.5 ms). The cost figures in this chapter are
therefore specific to this hardware by construction; the parameter
counts and the throughput figures are the portable part.
<!-- src: docs/representations/comparison-controls.md:24 -->

## The two readings side by side

Under the same-examples reading, both arms are compared after ten
generations; the grid arm's population score is 0.411 and the graph
arm's 0.331. Under the same-wall-clock reading, each run is taken at its
last checkpoint within 18.77 hours (generation 9 or 10 for the grid
runs, generation 3 to 6 for the graph runs), and the population scores
are 0.405 and 0.326. The two readings therefore give the same ordering
and nearly the same gap: 0.081 at equal examples and 0.079 at equal
time, in the grid arm's favour.
<!-- src: paper/figures/fig2-score-cost.md; results/comparison/wallclock-per-run.md; journal/2026-10-09-h6-5seed-final-01.md:22 -->

The pre-registered reason for reading the budget twice was the
possibility of a representation that learns more per example but less
per hour, in which case the two readings would disagree and both would
have to be reported. Here they agree: the graph arm learns less per
example and also less per hour. The equal-time reading does not create
the deficit; it enlarges one that the per-example reading already shows,
since within the cutoff the graph arm completes fewer than half of its
generations.
<!-- src: docs/protocol.md:103; paper/results-comparison.md:38 -->

The population score averages three opponents of very different
difficulty, so it is a summary for this comparison only and hides the
opponent structure of the result; the per-opponent tables of
`@sec:results-main`{=typst} are the primary evidence. Scores at the
intermediate generations (5 and 8) come from 20-game evaluations sized
for monitoring and do not enter any interval.
<!-- src: journal/2026-09-16-h6-progress-01.md:58 -->

## Score as a function of time

`@fig:score-vs-time`{=typst} in `@sec:results-main`{=typst} plots the
population score of every run against its cumulative training
wall-clock. Two features of the curves answer RQ-H2 directly. First, at
every wall-clock at which both arms have an evaluation, every grid run
lies above every graph run; the arms' bands do not cross. Second, the
grid runs' curves flatten after their first evaluations (against the
random opponent they are near the ceiling by generation 5), while the
graph runs' curves keep moving non-monotonically throughout their longer
runs; at the cutoff the graph runs have had 3 to 6 generations and are
still in the regime where seed-to-seed variation dominates. Within this
budget, the extra time gave the graph arm more generations without
producing a crossing.
<!-- src: scripts/make_figures.py:68; results/comparison/results-same-wallclock.md -->

## Resources consumed by the study

The main comparison consumed ten training runs totalling about 274
hours of training wall-clock (five grid runs, 90.0 h; five graph runs,
183.5 h), plus the evaluation games (100 games per opponent per
checkpoint at roughly 23–32 seconds per game at 400 simulations, for the
final and the cutoff checkpoints of every run) and the monitoring
evaluations at generations 5 and 8. The three ablation cells added nine
graph-arm runs (training wall-clock under the same accounting: A1 7.61–8.01 h
each because the divergent networks played short games; A2 32.05–47.44 h;
A1′ 23.89–30.35 h). All computation ran sequentially on one laptop kept
awake, with no cloud or paid resources; the campaigns span 10 September
to 6 October 2026.
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-09-23-h7-a1-divergence-01.md:15; paper/annex-reproduction.md:70 -->
