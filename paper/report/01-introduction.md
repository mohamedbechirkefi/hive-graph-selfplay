# Introduction {#sec:introduction}

## Context: learning to play from self-play, and the cost of representation

Since AlphaZero, the dominant recipe for learning to play a board game
without human examples has been stable: a neural network estimates, for
a position, a probability distribution over moves (the *policy*) and an
expected outcome (the *value*); a Monte-Carlo tree search guided by the
network produces stronger decisions than the network alone; the games
the search plays against itself become the training data of the next
network (Silver et al., 2018). The recipe is general, but one of its
ingredients is not: the way a position is presented to the network. For
chess, shogi and Go the answer was natural: the board is a fixed
rectangular array, and a position becomes a stack of image-like planes
read by a convolutional network. The success of this *grid* encoding
rests on a property these games share: every square exists at every
moment, at a fixed place.

Hive does not have that property. It is a two-player game of perfect
information played with hexagonal tiles and no board: the tiles
themselves form the playing surface (the *hive*), the surface changes
shape every turn, tiles can climb on top of one another, and a move is
best described as "this piece goes to that cell" over a set of cells
that exists only relative to the current hive. The natural
mathematical object for such a position is a graph rather than an image,
with cells as nodes, adjacency as edges and stacks as node attributes;
the natural network is then a graph neural network, which reads a
variable-size graph directly and needs no frame. Grid encodings can still be applied
to Hive by unfolding the hive into a large fixed frame, as every
learning system for the game has done so far; but doing so introduces
anchoring choices, empty space and a very large discrete move space
whose structure the network must learn from scratch.
<!-- src: paper/ch1-introduction.md:5; docs/representations/grid.md -->

## The problem: an intuition that cuts both ways

It is tempting to conclude that a graph encoding must learn Hive better.
This study was designed because the intuition is genuinely uncertain.
On one side, a graph network matches the game's native structure and
carries no anchoring artifacts. On the other side, Hive's outcomes
hinge on short-range *surround* tactics (a queen bee loses when its six
neighbouring cells are occupied), and short-range pattern recognition is
precisely the regime in which convolutional locality is strongest.
Moreover, a graph over the *occupied* cells alone cannot express the
legal destinations of a move, which are properties of empty space;
the graph must therefore carry empty candidate cells, and it is not
known whether a simple message-passing network, given such a graph,
learns the sliding, climbing and connectivity constraints of the rules
better than a convolutional network given the unfolded frame.
<!-- src: docs/protocol.md:24; paper/ch1-introduction.md:13 -->

The prior evidence does not settle the question. The only published
AlphaZero-style study of Hive compared five board encodings and found
that the choice of encoding measurably changes learning, but all five
were grid encodings and the resulting engines remained weaker than
plain search (de Goede et al., 2022). The two direct grid-versus-graph
comparisons in other games point in opposite directions: in Hex, under
a value-based learner rather than self-play, a graph network dominated
on long-range dependencies while the convolutional network stayed
sharper at local patterns (Keller et al., 2023); in chess, under
self-play, a graph-attention network out-learned convolutional baselines,
although from a single training run per model and without seed
replication (Rigaux & Kashima, 2024). None of these studies ran both arms under one
self-play pipeline, at matched capacity, under a matched budget, with
several independent training runs per arm, on Hive.
`@sec:related`{=typst} develops this positioning.
<!-- src: paper/ch3-related-work.md; docs/reading/matrix.md:26 -->

## Research questions and hypothesis

The study asks one main question and two secondary ones.

- **RQ-H1 (representation).** At comparable training budget, does a
  graph architecture learn a better policy than a grid architecture for
  base-game Hive, within an AlphaZero-style self-play pipeline?
- **RQ-H2 (efficiency).** How do the two representations compare when
  the budget is read as the number of training examples, and when it is
  read as wall-clock time on the same hardware?
- **RQ-H3 (components).** Which components of the graph architecture
  carry its behaviour, in particular its direction-typed relations and
  its global pooling?
<!-- src: docs/protocol.md:15; paper/ch5-protocol.md -->

The hypothesis under test, **H1**, states that a simple message-passing
graph network, receiving the hive as a graph, reaches a higher mean score
against a fixed opponent population than a grid convolutional network
receiving a 32×32 unfolded frame, at equal training budget. H1 was not
presumed true: the protocol (`@sec:protocol`{=typst}) states explicitly
that a negative or null result is a publishable outcome, and it fixed,
before any comparison run, the opponents, the openings, the budgets,
the evaluation settings, the statistical unit and the rule by which H1
would be rejected.
<!-- src: docs/protocol.md:19 -->

## What was done

Both encodings were built behind one shared action decoder on one
rules-validated engine; the two networks were matched in capacity to
within +1.5% (1.44 M against 1.47 M parameters); five independent seeds
per arm were trained under identical self-play settings for ten
generations of 500 games each; the comparison was read in two ways, at
equal training examples and at equal wall-clock at a pre-registered
cutoff, against a frozen population of three opponents (legal-random,
a documented heuristic, and a search agent without network at 6,400
simulations) on 250 frozen openings, with truncation treated as a
first-class outcome throughout. Two ablations removed one component each
of the graph arm at full parity, and a third, explicitly two-component
run supplemented the first ablation after it proved untrainable.
<!-- src: paper/ch1-introduction.md:25; docs/representations/comparison-controls.md:14 -->

## What was found

The hypothesis is rejected. The grid arm scores higher against two of
the three opponents under both budget readings, at roughly half the
wall-clock cost; the largest upper bound of any interval on a graph
advantage is +0.028. The graph arm's deficit concentrates in local
tactical conversion: it wins material against the random opponent and
then fails to close, truncating 20–57% of those games where the grid arm
truncates almost none. The ablations localise the graph arm's machinery:
its direction-typed relations are necessary for optimization itself
(removing them made training diverge in every seed), while its global
pooling is dispensable.
<!-- src: paper/ch1-introduction.md:32; results/comparison/results-arm-difference.md -->

## Contributions

Three contributions are claimed, each verifiable from the released
repository.

1. **The first controlled, budget-matched, multi-seed grid-versus-graph
   comparison for Hive**, with both arms under the same AlphaZero-style
   pipeline, read under two budget equalisations, and a pre-registered
   negative answer (`@sec:results-main`{=typst},
   `@sec:results-cost`{=typst}; raw records released).
2. **A reproducible comparison harness for frameless, stacking games**:
   a rules engine validated independently of learning; two encoders
   pinned byte-exactly across two implementation languages; a shared
   decoder over a variable action set; truncation-aware evaluation; and
   a frozen-artifact discipline (`@sec:engine`{=typst} to
   `@sec:protocol`{=typst}).
3. **A component attribution for the graph arm**, in which the typed
   relations determine trainability and the pooling has a null effect,
   with an honestly labelled two-component supplement
   (`@sec:results-ablations`{=typst}).

The construction of software, however substantial, is not counted as a
scientific contribution in itself; it is reported because the result
cannot be evaluated without it.

## How this report is organised

Part I states the problem: `@sec:background`{=typst} gives the rules of
Hive, the formalisation used, and the elements of self-play learning,
state representation and small-sample evaluation a reader needs;
`@sec:related`{=typst} positions the study against prior work. Part II
describes how the system was built and when
(`@sec:chronology`{=typst}): the engine and its validation
(`@sec:engine`{=typst}), the learning pipeline
(`@sec:pipeline`{=typst}), the two representations and networks
(`@sec:representations`{=typst}), and the frozen opponent population
(`@sec:baselines`{=typst}). Part III explains the methodology and why it
was chosen: the pre-registered experimental protocol
(`@sec:protocol`{=typst}) and the gated human-AI working method
(`@sec:working-method`{=typst}). Part IV reports the results by
question: the main comparison (`@sec:results-main`{=typst}), cost and
efficiency (`@sec:results-cost`{=typst}), ablations
(`@sec:results-ablations`{=typst}) and a qualitative analysis of failure
positions and training behaviour (`@sec:results-qualitative`{=typst}).
Part V discusses mechanisms and threats to validity
(`@sec:discussion`{=typst}) and concludes (`@sec:conclusion`{=typst}).
The bibliography and webography follow the conclusion. The appendices
contain the annotated position corpora, the architectures and data
formats in full, every hyperparameter and seed, the statistical
procedures with the raw per-seed tables, the provenance of every result,
a glossary with French equivalents, and the reproduction guide.

## How to read the numbers

Every score in this report is a mean over *decided* games against one
frozen opponent, with win = 1, draw = 0.5 and loss = 0; games stopped at
the 300-ply experimental cap are counted separately as *truncations* and
are never scored as draws. Every interval is a 95% percentile bootstrap
interval whose resampling unit is the independent training run (the
*seed*), not the game: a thousand games played by one network are one
observation of that network, not a thousand observations of the method.
Differences between arms are written as graph minus grid, so a negative
number favours the grid arm. All numbers trace to raw per-game records
through the chain documented in `@sec:app-e`{=typst}.
<!-- src: docs/protocol.md:79; docs/protocol.md:124 -->
