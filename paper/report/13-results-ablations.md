# Results: component ablations (RQ-H3) {#sec:results-ablations}

This chapter answers the third research question: which of the graph
arm's two distinctive components, its six direction-typed relations and
its global-pooling bias, carry its behaviour. Each ablation removes one
component and nothing else, at the full method's settings (same budgets,
same seeds, same frozen opponents and openings, same evaluation), with
three seeds per cell; a third run, explicitly labelled as a
two-component change, supplements the first ablation. Throughout,
nothing is attributed beyond the single component that changed.
<!-- src: configs/ablations/A1-edge-typing.md; configs/ablations/A2-global-pooling.md; results/ablations/README.md -->

## Design of the three cells

| Cell | What changes relative to the full graph arm | Parameters | Seeds | Status |
| --- | --- | ---: | ---: | --- |
| A1: naive adjacency | the six direction-typed message matrices are replaced by a single shared matrix | 0.54 M | 3 | one-component, at parity |
| A2: no global pooling | the global-pooling bias is removed from every layer | 1.37 M | 3 | one-component, at parity |
| A1′: naive adjacency, stabilised | as A1, plus gradient-norm clipping at 1.0 | 0.54 M | 3 | **two-component**, never attributed to typing alone |
| Reference: full graph arm | none | 1.47 M | 5 | main comparison |

Table: The ablation cells. Parameter counts are measured; the parameter
differences are inherent to the removed components and are reported
rather than compensated. {#tbl:ablation-cells}
<!-- src: results/ablations/README.md; journal/2026-09-23-h7-a1-divergence-01.md:4; journal/2026-10-09-h7-a1prime-01.md:4; docs/representations/comparison-controls.md:17 -->

## A1: removing the typed relations removes trainability

With one shared message matrix in place of six typed ones, training
diverged to non-finite values in generation 0 for all three seeds;
every later generation self-played and trained on non-finite network
outputs. The symptom that triggered the diagnosis was statistical rather
than numerical. The three seeds' final evaluations were identical down
to the game count (for instance 0 wins, 0 draws and 100 losses against
the heuristic for each seed), which independent seeded trainings cannot
produce. The checkpoints have distinct hashes, but every forward pass
returns non-finite policy and value from the first checkpoint onward.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:22 -->

The cell's evaluation tables are therefore not strength measurements,
since a non-finite policy plays a deterministic, degenerate game
independent of its weights; they are excluded as scores, and the H-T3
cell reads "training diverged (3/3 seeds)". The runs took 7.75, 8.01
and 7.61 hours of training wall-clock against a graph-arm mean of 36.70
hours, because non-finite priors degrade the search into short games of
about 42 plies with no truncations and no resignations; the configured
budget in games and simulations was fully consumed.
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-09-23-h7-a1-divergence-01.md:36 -->

At parity settings, the naive-adjacency variant cannot be trained at
all, so the typed relations contribute, at minimum, the optimization
stability of the whole arm. Nothing about their contribution to playing
strength can be measured at parity, because the variant never trains.
The explanation offered here, a reasoned argument rather than a measured
decomposition, is that a single shared matrix receives the summed
gradient of six neighbour terms, roughly six times the per-matrix
gradient scale of the typed variant, at an identical learning rate and
momentum. The protocol had stated, before any run, that a naive
adjacency graph "may not suffice"; under these conditions it does not
even optimize.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:59; docs/protocol.md:24 -->

No learning-rate sweep was run, because changing the learning rate
would have made A1 a two-component difference. The silent passage of
non-finite values for ten generations was a tooling gap: the training
loops had no non-finite guard, and their loss print cadence (every 100
steps) never fired on epochs of about 20 steps. The gap was closed on
23 September 2026 by halting both training loops loudly on a non-finite
loss; the behaviour of healthy runs is unchanged, and the ablation
result stands.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:47 -->

## A2: removing global pooling changes nothing measurable

| Opponent | A2 (no pooling), seeds 1/2/3 | Full graph arm, seeds 1/2/3 | Difference A2 − full [95% interval] |
| --- | --- | --- | --- |
| B-RND | 0.768 (59%) / 0.714 (65%) / 0.952 (17%) | 0.733 (57%) / 0.981 (20%) / 0.722 (55%) | −0.001 [−0.170, +0.165] |
| B-HEU | 0.050 / 0.070 / 0.025 | 0.025 / 0.050 / 0.090 | −0.007 [−0.043, +0.030] |
| B-MCTS | 0.070 / 0.125 / 0.105 | 0.115 / 0.125 / 0.100 | −0.013 [−0.043, +0.013] |

Table: Ablation A2: final-checkpoint scores per seed (same-examples
reading; truncation rate in parentheses where non-zero; 100 games per
opponent per seed on the 250 frozen openings) and the seed-bootstrap
interval on the difference against the full graph arm's three original
seeds (10,000 resamples, independent seed sets). {#tbl:a2}
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:34 -->

All three A2 runs trained healthily (finite outputs, distinct per-seed
results); their training wall-clocks of 39.90, 47.44 and 32.05 hours
lie within the full graph arm's band (26.57–49.86 h).
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-10-02-h7-a2-nogpool-01.md:23 -->

Removing the global-pooling bias changed the score by −0.001 [−0.170,
+0.165] against the random opponent, −0.007 [−0.043, +0.030] against
the heuristic and −0.013 [−0.043, +0.013] against the search opponent.
Every interval straddles zero, and the random-opponent cell is dominated
by seed variance in both variants (truncation rates between 17% and 65%
across seeds).
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:36; journal/2026-10-02-h7-a2-nogpool-01.md:46 -->

The hypothesis that pooling carried the graph arm's value learning is
not supported. Eight layers of directional message passing alone
reproduce the full arm's behaviour, including its failure mode: the
conversion pathology against the random opponent is present in both
variants. At this scale the global-pooling bias is dispensable.
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:53 -->

The cell has three seeds; the 0.10 M parameter difference is inherent
to the removed component; and "no measurable effect" is bounded by
intervals of width ±0.17 against the random opponent, where a small
effect could hide.
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:46 -->

## A1′: the stabilised naive-adjacency variant (two-component supplement)

| Opponent | A1′ seeds 1/2/3 (truncation) | A1′ mean (3 seeds) | Full graph mean (5 seeds) | Difference [95% interval] |
| --- | --- | ---: | ---: | --- |
| B-RND | 0.566 (47%) / 0.671 (59%) / 0.995 (0%) | 0.744 | 0.810 | −0.066 [−0.254, +0.130] |
| B-HEU | 0.035 / 0.135 / 0.110 | 0.093 | 0.061 | +0.032 [−0.011, +0.078] |
| B-MCTS | 0.090 / 0.195 / 0.060 | 0.115 | 0.107 | +0.008 [−0.040, +0.063] |

Table: Supplement A1′, untyped relations plus gradient clipping at 1.0
(two components differ from the full method). Final-checkpoint scores per
seed, three-seed means, the full graph arm's five-seed means, and the
seed-bootstrap interval on the difference over the two unequal seed sets.
{#tbl:a1prime}
<!-- src: journal/2026-10-09-h7-a1prime-01.md:26 -->

With a single added stabiliser, all three trainings stayed finite and
the non-finite guard never fired, which confirms the remedy implied by
the divergence diagnosis. Training wall-clocks of 23.89, 30.35 and
27.68 hours lie at the fast end of the graph arm's band.
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-10-09-h7-a1prime-01.md:19 -->

The stabilised variant scores within the full graph arm's band against
all three opponents: −0.066 [−0.254, +0.130], +0.032 [−0.011, +0.078]
and +0.008 [−0.040, +0.063]; every interval straddles zero.
<!-- src: journal/2026-10-09-h7-a1prime-01.md:30 -->

Taken together with A1, the most that can be said is that at this scale
the measurable contribution of direction-typed relations lies in
optimization stability; no strength contribution beyond it is
detectable.
<!-- src: journal/2026-10-09-h7-a1prime-01.md:53 -->

Every number in this cell is confounded by the gradient clip by
construction and is never attributed to edge typing alone. The cell has
three seeds and wide intervals, and seed 3's 0% truncation against
47–59% for seeds 1–2 shows that the conversion pathology remains
seed-volatile in this variant too.
<!-- src: journal/2026-10-09-h7-a1prime-01.md:45 -->

## Summary table H-T3

| Ablation | Component removed | Outcome |
| --- | --- | --- |
| A1 naive adjacency | direction-typed relation matrices → one shared matrix | training diverged (non-finite, generation 0, 3/3 seeds); untrainable at parity; typed relations ⇒ at minimum optimization stability |
| A2 no global pooling | global-pooling bias in all layers | null effect: −0.001 / −0.007 / −0.013 against the three opponents, all intervals straddling zero; failure modes unchanged; pooling dispensable |
| A1′ supplement (two-component) | untyped relations + gradient clipping 1.0 | trains; scores within the full arm's band (−0.066 / +0.032 / +0.008); never attributed to typing alone |

Table: Component attribution for the graph arm (H-T3). Differences are
variant minus full graph arm, seed-level means, three seeds per ablation
cell. {#tbl:ht3}
<!-- src: results/ablations/README.md -->

Within the tested perimeter, the answer to RQ-H3 is that of the graph
arm's two distinctive components, one is necessary for trainability
itself and the other is dispensable. Whether the typed relations also
contribute playing strength beyond stability cannot be decided from
these cells.
