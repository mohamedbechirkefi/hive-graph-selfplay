# Conclusion and perspectives {#sec:conclusion}

## The answer to the research question

The tested perimeter is base-game Hive, one capacity-matched simple
relational message-passing network against one grid convolutional
network, ten generations of small-budget self-play, five independent
seeds per arm, a frozen three-opponent population and 250 frozen
openings. Within that perimeter, **the answer to the main research
question is no**: the graph
representation did not learn a better policy than the grid
representation, neither when both arms consumed the same number of
training examples nor when both received the same wall-clock on the same
machine, and the pre-registered rejection rule fired exactly as it had
been frozen. The graph arm's deficit is largest where Hive is most
tactical (against the legal-random opponent, −0.169 and −0.161 under the
two readings) and clear against the heuristic opponent (−0.064 and
−0.059); against the search opponent the two arms are indistinguishable
(−0.009 and −0.018, intervals straddling zero). The graph arm pays
roughly twice the wall-clock per run. Its characteristic failure is to
win material without converting the win; this shows as 20–57% of its
games against the random opponent ending at the move cap, and it is
observable only because truncation was never folded into draws.
<!-- src: results/comparison/results-arm-difference.md; paper/ch8-conclusion.md:5 -->

The result bounds, rather than contradicts, the positive graph findings
reported for Hex under value-based learning and for chess under
self-play. Where short-range surround tactics decide games and budgets are
small, the frame artifacts of a grid encoding turn out to be cheaper than
framelessness. The component analysis adds a mechanistic reading: of the
graph arm's two distinctive components, the direction-typed relations are
necessary for optimization itself (removing them at identical settings
made training diverge in every seed), while the global-pooling bias is
dispensable at this scale.
<!-- src: paper/ch8-conclusion.md:15; results/ablations/README.md -->

## Contributions, as demonstrated

Three contributions were announced in `@sec:introduction`{=typst}; each
is demonstrated in the chapters named there. (1) A controlled,
budget-matched, multi-seed grid-versus-graph comparison for Hive, with
both arms under one self-play pipeline and a pre-registered negative
answer (`@sec:results-main`{=typst}, `@sec:results-cost`{=typst}). (2) A
reproducible comparison harness for frameless, stacking games, released
with the raw records: a rules-validated engine, two encoders pinned
byte-exactly across two languages, a shared variable-action decoder,
truncation-aware evaluation and frozen-artifact discipline
(`@sec:engine`{=typst} to `@sec:protocol`{=typst}). (3) A component
attribution for the graph arm with an honestly labelled two-component
supplement (`@sec:results-ablations`{=typst}).

## Two follow-ups motivated by the data

The first follow-up targets the **conversion pathology**, which the data
isolate as a policy defect rather than a value defect: the graph arm's
value accuracy in training is comparable to the grid arm's while its
policy fails at forcing sequences (`@sec:results-qualitative`{=typst}).
A natural experiment is a search-time remedy applied identically to both
arms under the same frozen evaluation, as a one-component change to the
shared pipeline: a deeper evaluation budget in positions the value head
already judges won, or auxiliary training targets for forcing moves.
The second follow-up concerns the **stability finding**: the
ablation and its supplement showed that direction-typed relations matter
mostly for optimization at this scale, but the supplement's gradient
clipping confounds the attribution. A controlled study of normalisation
and gradient-scale choices for relation-shared graph layers would
decouple trainability from representational content and would say
whether naive adjacency, properly stabilised, is sufficient for Hive.
<!-- src: paper/ch8-conclusion.md:19 -->

## A method that stands regardless of the sign

Pre-registration with frozen artifacts, two budget readings, truncation
as an outcome, seed-level inference and reporting written as the work
progressed turned a negative answer into a usable scientific object on a
single laptop. The same discipline, described in
`@sec:working-method`{=typst} together with the incidents it caught, is
the part of this work most directly transferable to other small-compute
studies.
