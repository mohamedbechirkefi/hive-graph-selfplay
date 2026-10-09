# Results: failure positions and training behaviour {#sec:results-qualitative}

Aggregate scores say that the graph arm learned less; they do not say
how it fails. This chapter looks at three individual games selected by
mechanical criteria, at the truncation channel that carries the
mechanism, and at what the training metrics of all ten main runs show.

## Three failure positions, selected mechanically

The research plan asks for three commented failure positions with
explicit selection criteria. The criteria are mechanical and were
applied over the raw per-game records: F1 is the longest truncated game
of the graph arm against the legal-random opponent; F2 is the shortest
decided loss of the grid arm against the heuristic opponent; F3 is the
longest drawn game of the graph arm against the search opponent. Each
selected game was reproduced deterministically from its recorded
opening and per-game seeds and verified move by move against its
recorded result row before being rendered; all three reproductions
matched. This verification step exposed a latent defect in the match
runner (a path that skipped writing records when every game of a match
was truncated); the defect was fixed before the equal-time evaluations,
and an audit found that it had affected no campaign data
(`@sec:working-method`{=typst}).
<!-- src: paper/figures/fig4-failures.md:3; docs/methodology-log.md -->

![Three commented failure positions, reproduced and verified against
their recorded result rows. F1 (left): graph arm, seed 1, against
legal-random, opening 2, white; the game reaches the 300-ply cap with
the graph arm materially ahead but unable to complete the surround. F2
(centre): grid arm, seed 2, against the heuristic, opening 2, black; a
decided loss in 19 plies to the heuristic's queen-targeting tactics. F3
(right): graph arm, seed 3, against the search opponent, opening 19,
white; a 79-ply draw in which the graph arm never generates a winning
threat.](figures/fig4-failures.png){#fig:failures width=100%}

<!-- src: paper/figures/fig4-failures.md:7 -->

*F1: a won position the graph arm cannot close.* The graph arm wins
material early, then shuffles pieces around a partially surrounded
enemy queen until the cap. The failure is tactical rather than
evaluative: the arm is ahead and stays ahead, but it does not find, or
does not prefer, the forcing sequence that completes the surround. This
is the pattern behind the arm's 20–57% truncation rate against the
random opponent, and it is invisible in any evaluation that scores
capped games as draws.
<!-- src: paper/figures/fig4-failures.md:5; paper/results-comparison.md:45 -->

*F2: the price of early-regime policies against sharp tactics.* The
grid arm's shortest loss against the heuristic lasts 19 plies. The
heuristic's dominant queen-liberty term drives it straight at the queen
before the network's policy has consolidated a defence. The game
illustrates why both arms score low against the two strong opponents
after ten generations, since the regime is still early, and why the
comparison's resolution is highest against the random opponent.
<!-- src: paper/figures/fig4-failures.md:11; docs/baselines.md:34 -->

*F3: avoiding defeat without creating threats.* Against the search
opponent, the graph arm's longest draw (79 plies) shows a network that
defends adequately, in that it avoids losing, but never builds a
winning attack. Against this opponent the two arms are statistically
indistinguishable (`@sec:results-main`{=typst}); F3 is a reminder that
"indistinguishable" here means both arms draw or lose, not that either
plays well.
<!-- src: paper/figures/fig4-failures.md:17 -->

## The truncation channel, run by run

![Final-evaluation truncation rate against the legal-random opponent for
each of the ten main runs (final checkpoints; 100 games per run at 400
simulations on the 250 frozen openings; 300-ply cap). Blue: grid arm
seeds 1–5; red: graph arm seeds 1–5. Truncation is reported separately
from draws throughout the study.](figures/fig7-truncation.png){#fig:truncation width=80%}

The graph arm truncated 57%, 20%, 55%, 44% and 23% of its games against
the random opponent at the final checkpoint for seeds 1 to 5; the grid
arm truncated 0%, 1%, 1%, 11% and 0%. Against the heuristic and the
search opponent, no game of either arm reached the cap.
<!-- src: results/comparison/results-same-examples.md:7 -->

The truncation gap is the largest behavioural difference between the
arms, larger than any score gap, and its direction is consistent across
seeds: every graph seed truncates more than every grid seed. Grid seed
4 (11%) exceeds no graph seed, but it shows that the pathology is not
strictly exclusive to one arm. Because truncation was defined as its
own outcome before the first run, the pathology is visible instead of
being absorbed into draws; and because the cap cannot rescue the
hypothesis (`@sec:results-main`{=typst}), the channel is diagnostic
rather than decisive.
<!-- src: results/comparison/results-same-examples.md:7; journal/2026-09-19-h6-comparison-01.md:66 -->

The graph arm's random-opponent score is consequently measured on fewer
decided games (between 43 and 80 per seed), which widens its interval;
the sensitivity analysis bounds this effect without removing it.
<!-- src: paper/ch7-discussion.md:60 -->

## What the training metrics show

![Training metrics by generation for the ten main-campaign runs
(epoch-1 line of each generation): left, policy top-1 agreement with the
MCTS visit distribution on the self-play validation split; right, value
accuracy on non-truncated samples. Blue: grid arm; red: graph arm; one
line per seed. Ablation runs are excluded.](figures/fig6-training-metrics.png){#fig:training width=100%}

Both arms fit their self-play data throughout the ten generations:
policy top-1 rises with generation in every run, and value accuracy on
non-truncated samples rises for both arms. The graph arm's value
accuracy is comparable to the grid arm's, while its policy top-1
trails.
<!-- src: paper/figures/fig6-training-metrics.png; journal/2026-09-16-h6-progress-01.md:74 -->

The gap between the arms is therefore not a plain optimization failure
of the full graph arm (unlike the ablated naive-adjacency variant, which
did not optimize at all). The graph arm learns a usable evaluation of
positions and a weaker policy. The failure positions give the same
picture, adequate judgement of who is better and inadequate generation
of forcing moves, and this motivates the first follow-up in
`@sec:conclusion`{=typst}.
<!-- src: journal/2026-09-16-h6-progress-01.md:74; paper/ch8-conclusion.md:19 -->

Training metrics are computed on each run's own self-play validation
split, whose distribution shifts with the generation and differs
between arms; they are evidence about fitting, not about strength, and
no number from this figure enters any interval or any claim of the main
comparison.

## Per-opponent trajectories

![Score against each frozen opponent at the evaluated generations (5, 8
and 10; 20, 20 and 100 games per opponent respectively) for every main
run. Blue: grid arm; red: graph arm; one line per seed. Scores exclude
truncated games.](figures/fig5-per-opponent.png){#fig:per-opponent width=100%}

The per-opponent trajectories decompose the aggregate curves of
`@sec:results-cost`{=typst}: against the random opponent, grid seeds
approach the ceiling early and stay there, while graph seeds spread
widely and move non-monotonically; against the heuristic and the search
opponent, both arms remain in a low band whose generation-to-generation
movement is of the order of the game-count noise at 20 games (the
intermediate evaluations were sized for monitoring and not for
inference; only the 100-game final evaluations enter the tables).
<!-- src: scripts/make_figures.py; journal/2026-09-16-h6-progress-01.md:58 -->
