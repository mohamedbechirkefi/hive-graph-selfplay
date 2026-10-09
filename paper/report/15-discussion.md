# Discussion and threats to validity {#sec:discussion}

The hypothesis was rejected exactly as the frozen protocol defined
rejection. This chapter asks what the result means, which explanations
the data support and which they merely suggest, how the result relates
to the prior work that motivated it, and what could be wrong with it. The
threats are organised as the research plan prescribes: internal,
measurement, statistical and external.

## Reading the result

Three observations shape how the result should be read.

First, the deficit is opponent-shaped. It is largest against the
legal-random opponent, clear against the heuristic and absent against
the search opponent (`@tbl:contrast`{=typst}). A graph arm that was
simply weaker everywhere would show a uniform deficit; a deficit
concentrated where games are decided by finishing a surround that
nothing resists points at *local tactical conversion* rather than
positional judgement.
<!-- src: paper/ch7-discussion.md:7; results/comparison/results-arm-difference.md -->

Second, the truncation channel carries the mechanism. The graph arm
wins material against the random opponent and then fails to close: 20–57%
of those games end at the 300-ply cap, against 0–11% for the grid arm
(`@fig:truncation`{=typst}, `@fig:failures`{=typst} F1). This pattern is
invisible in any study that scores capped games as draws, and it is why
the protocol insisted, before the first run, that truncation be an
outcome of its own.
<!-- src: results/comparison/results-same-examples.md:7 -->

Third, the ablations sharpen the reading. At parity settings, removing
the direction-typed relations did more than weaken the graph arm; it
destroyed trainability outright (non-finite divergence in generation 0
for all three seeds), so the typed relations carry at minimum the
optimization stability of the whole arm. Removing the global-pooling
bias changed the scores by ≈0.00 ± 0.17, −0.01 ± 0.04 and −0.01 ± 0.03
against the three opponents, with failure modes unchanged. The arm's
distinctive machinery therefore lives in its directional relations
rather than in its pooling. Once the naive variant is stabilised by
gradient clipping, however, it plays within the full arm's band, so the
measurable contribution of the typed relations at this scale is
concentrated in optimization rather than in representation
(`@sec:results-ablations`{=typst}).
<!-- src: paper/ch7-discussion.md:15; results/ablations/README.md -->

## Which explanations are demonstrated, and which are plausible

The research plan distinguishes an explanation demonstrated by ablation
from one that is merely plausible. Four candidate explanations of the
gap deserve this treatment.

*Geometry (plausible, not demonstrated).* Hive's tactics are dominated
by short-range surround geometry, the regime in which Keller et al.
(2023) found convolutional networks stronger than graph networks in Hex.
A 3×3 convolution over the unfolded frame sees a cell's whole
neighbourhood, and stacked residual blocks see the neighbourhood of the
neighbourhood, at no learning cost; the message-passing network must
compose the same patterns from six typed relations one hop at a time.
This is consistent with every observation above, but no ablation in this
study isolates receptive-field composition, so it remains a hypothesis.
<!-- src: paper/ch7-discussion.md:30; docs/reading/keller-2023-graphdqn-hex.md -->

*Capacity (controlled).* The two networks differ by +1.5% in parameter
count (1.44 M against 1.47 M), in the graph arm's favour. Capacity does
not explain a graph deficit.
<!-- src: docs/representations/comparison-controls.md:14 -->

*Decoder (controlled).* Both arms score the identical set of legal
(piece, destination) pairs with identical masking, normalisation,
targets and tie-breaking; the decoder cannot favour one arm. What does
differ is the *parameterisation* behind the shared interface: a flat
28,673-way tensor for the grid arm, a per-candidate scoring function
for the graph arm. That difference is part of what "representation"
means in this study rather than a confound of it.
<!-- src: docs/action-decoder.md:40 -->

*Speed (demonstrated for the second reading only).* The graph arm's
generations cost roughly twice as much wall-clock on this machine, so at
equal time it completes fewer than half of its generations
(`@sec:results-cost`{=typst}). This demonstrably widens the gap in the
same-wall-clock reading; it plays no role in the same-examples reading,
where the deficit already exists.
<!-- src: journal/2026-09-16-h6-progress-01.md:36 -->

*Optimization (partly demonstrated).* The ablations show that the full
graph arm's optimization is fragile in one specific way (it depends on
typed relations for stability), but the training curves of the full arm
(`@fig:training`{=typst}) show it fitting its data in every seed. Nothing
indicates that the full arm failed to optimize; the gap is a gap between
two trained networks. Whether a different learning rate or normalisation
would have favoured the graph arm was not tested, because neither arm
received any tuning. The zero-tuning policy is symmetric, but it is not
neutral if one architecture is more sensitive to its defaults, a point
taken up under external validity.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:59; docs/representations/comparison-controls.md:52 -->

## Relation to prior work

The result does not contradict the positive graph findings of Rigaux
and Kashima (2024) in chess or the long-range advantage Keller et al.
(2023) measured in Hex. It bounds where their optimism transfers. The
chess result rests on a single training run per model with intervals
covering Elo estimation only, a loose capacity match and arm-specific
decoders; the Hex result was obtained under a value-based learner, with
a game-specific graph construction, and found the convolutional arm
sharper at local patterns, which is the regime that decides Hive games
at small budgets. The present rejection is seed-consistent across five runs
per arm under two pre-registered budget readings, with capacity matched
and the decoder shared. Read together, the three studies suggest that
the sign of the grid-versus-graph comparison depends on the game's
tactical range and on the evidence standard, rather than on the graph
paradigm as such. The one prior AlphaZero study of Hive (de Goede et
al., 2022) had already shown that encoding choice changes learning
within the grid family; this study extends the finding across families
and finds the grid side ahead.
<!-- src: paper/ch7-discussion.md:23; docs/reading/matrix.md:26 -->

## Internal validity: bugs and comparability

The engine is validated independently of learning: perft equality with
published tables to depth 6 for all eight game types, 21/21 protocol
conformance, 27,829-position differential agreement of legal-move sets
with two reference engines, a 30-case rules-derived corpus annotated
before any run, and 10.9 million random transitions without an invariant
violation (`@sec:engine`{=typst}). Both encoders are pinned byte-exactly
against cross-language golden tests run nightly (240 and 160 positions).
The arms share the decoder, the records, the losses, the budgets, the
search and the frozen evaluation; capacity differs by +1.5% and is
reported.
<!-- src: paper/ch7-discussion.md:36; docs/representations/comparison-controls.md:57 -->

Residual risks remain. The graph architecture is one point in design
space; a different graph network might behave differently, and nothing
is claimed beyond this one. Tooling defects were found *during* the
study: a match-runner path that dropped records when every game of a
match was truncated, a training loop that let non-finite values pass
silently for ten generations, and a results generator whose per-run
wall-clock average still divided by the original three runs after the
extension to five. Each was caught by the verification discipline
(`@sec:working-method`{=typst}), fixed, and audited: the first touched
no campaign data; the second affected only the ablation it exposed and
became that ablation's result; the third affected two cost-table rows
and no score, interval or claim. They illustrate the study's most
practical lesson: at this scale the dominant failure mode is harness
error rather than chance, and only mechanical verification catches it.
<!-- src: paper/ch7-discussion.md:42; docs/methodology-log.md -->

## Measurement validity: opponents and truncation

Scores are relative to a population of three fixed opponents spanning
floor-to-mid strength; no universal strength claim is made. All trained
arms still lose heavily to the two strong baselines after ten
generations, so the comparison lives in a low-score regime in which
differences against the search opponent cannot be resolved. Truncation
is handled as its own outcome with sensitivity bounds: the cap cannot
reverse the verdict, but the graph arm's high truncation rates mean its
random-opponent score is measured on fewer decided games (43–80 per
seed), which widens its interval. The evaluation openings are frozen and
shared, so an opening-set effect would affect both arms alike; it could
still shape absolute scores.
<!-- src: paper/ch7-discussion.md:53 -->

## Statistical validity: seeds and dependencies

Five seeds per arm bound the statistics. The rejection rests on more
than a single interval: on seed-consistency across two opponents and
two readings simultaneously, on four of six intervals excluding zero,
and on a bounds analysis of the cap. The pre-committed extension from
three to five seeds tightened four of the six intervals and absorbed the
most graph-favourable seeds observed without changing the verdict; the
contrast against the search opponent remains indistinguishable from
zero under both readings and is reported as such. The arm contrast
bootstraps seeds rather than games, so no game-level pseudo-replication
enters any interval, and the two arms' seed sets are resampled
independently, which is conservative for a paired design in which both
arms play the same openings.
<!-- src: paper/ch7-discussion.md:65; journal/2026-10-09-h6-5seed-final-01.md:61 -->

## External validity: variant, hardware and budget

One variant (base Hive without expansions), one machine, one small
budget (ten generations of 500 games; between 16.7 and 19.1 hours of
training wall-clock per grid run and between 26.6 and 49.9 hours per
graph run), early-regime self-play throughout. The inference-provider
asymmetry is a genuine property of the deployment hardware: the
convolutional network runs fastest on the machine's neural accelerator,
the gather-heavy graph network fastest on the CPU. It is reported and
charged, and on different accelerators the wall-clock reading could
shift while the same-examples reading would not. The zero-tuning policy
is symmetric but may not be neutral: graph networks are commonly more
sensitive to optimizer defaults than residual convolutional networks,
and the first ablation showed that this family is fragile under these
defaults; a tuned graph arm might narrow the gap, at the cost of
breaking the symmetry of the comparison. Nothing here generalises to
other games, larger budgets or richer graph architectures. The study
answers its pre-registered question inside its pre-registered perimeter,
and the negative answer is the finding. Encoding choice matters, as the
earlier Hive study found, and for Hive at small budget it favours the
grid.
<!-- src: paper/ch7-discussion.md:75; data/runs wallclock totals (see sec:results-cost) -->

## A property of the pipeline that bounds the absolute strength reached

One property of the shared pipeline deserves to be stated as plainly as
possible, because it shapes how the "ten generations" of this study
should be read. The campaign driver trains the network of each
generation from a fresh seeded initialisation, for two epochs, on the
records of that generation alone; it passes neither a warm-start
checkpoint nor a replay window to the trainer (`@sec:pipeline`{=typst}).
The loop still improves across generations, because the network of
generation $g$ is trained on games played by the search guided by the
network of generation $g-1$, and that search is stronger than the raw
network; but no weights are carried forward and no record is reused.
Each network therefore sees the positions of 500 games, which is a small
training set by the standards of self-play learning, and the absolute
strength reached after ten generations (near the ceiling against the
random opponent, around 0.1 against the two strong opponents) must be
read against that fact. For the *comparison* the property is neutral:
it is identical in both arms, both encoders see exactly the same
records, and the frozen protocol specified identical training
conventions rather than a particular warm-start policy. For the
*generalisation* of the result it is a limit in addition to those
already listed: a pipeline that accumulated data and carried weights
would reach a different regime, in which the ordering of the arms is an
open question. A successor study should carry weights across
generations and train on a window of recent generations, as the large
self-play systems do, with both changes applied identically to both
arms.
<!-- src: scripts/run_comparison.py:119-129; python/hivenet/train.py:112-123; configs/comparison-matrix.yaml:36-41 -->

## What we would do differently

Four changes would strengthen a successor study without changing its
logic. The first is the warm-start and replay window just described.
The intermediate evaluations (20 games per opponent at generations 5
and 8) were sized for monitoring and are too noisy to carry inference;
a successor should evaluate every generation at the final volume if the
curves are to be analysed. The equal-time reading
should be accompanied by an equal-*energy* reading on heterogeneous
accelerators, since wall-clock alone hides the provider asymmetry. And
the zero-tuning symmetry should be complemented by a small, identical,
pre-registered tuning budget for both arms, so that fragility under
defaults is measured rather than inherited.
