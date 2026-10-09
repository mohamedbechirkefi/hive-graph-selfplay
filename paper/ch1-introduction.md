# Chapter 1 — Introduction (booklet draft, 2026-10-09)

*Written last-but-abstract per the plan's order, from final results.*

**The question.** Hive is a boardless hexagonal strategy game: pieces
define the playing surface, stacks form and dissolve, and every move is
a (piece, destination) pair over a set of cells that changes each turn.
Grid-based encodings — the convolutional lingua franca of AlphaZero-style
systems — must bolt a frame onto this frameless game. A graph encoding
needs no frame at all. It is natural to expect the graph to win. Does
it, at a compute budget a single machine can afford?

**Why it is not obvious.** The intuition cuts both ways. Graph networks
match the game's native structure and carry no anchoring artifacts; but
Hive's outcomes hinge on short-range surround tactics — the regime in
which convolutional locality is strongest — and prior evidence splits:
graph arms won in Hex under DQN (Keller et al. 2023) and in chess under
self-play (Rigaux & Kashima 2024, from single runs), while the only
AlphaZero-on-Hive study (de Goede et al. 2022) never tried a graph at
all. The hypothesis was stated falsifiably and frozen before any
comparison run, together with everything that could bend the answer:
opponents, openings, budgets, evaluation settings, and the rejection
rule itself.

**What we did.** We built both encodings behind one shared action
decoder on one rules-validated engine, matched capacity to +2.1%, and
trained five independent seeds per arm under identical self-play
settings, reading the comparison two ways — equal training examples and
equal wall-clock — against a frozen three-opponent population on 250
frozen openings, with truncation as a first-class outcome throughout.

**What we found.** The hypothesis is rejected. The grid arm scores
higher against two of the three opponents under both readings (largest
interval upper bound for a graph advantage: +0.028), at half the
wall-clock cost; the graph arm's deficit concentrates in local tactical
conversion — it wins material against the random opponent and then
fails to close, truncating 20–57% of those games where the grid arm
truncates almost none. Ablations localise the graph arm's machinery:
its direction-typed edge relations are load-bearing for optimization
itself (removing them diverges training in every seed), while its
global pooling is dispensable.

**Contributions.** (1) The first controlled, budget-matched, multi-seed
grid-vs-graph comparison for Hive, both arms under the same
AlphaZero-style pipeline, with a pre-registered negative answer —
Chapter 6 and `results/comparison/`. (2) A reproducible comparison
harness for frameless, stacking games: a validated rules engine with
cross-language golden-pinned encoders, a shared variable-action decoder,
truncation-aware evaluation machinery, and frozen-artifact discipline —
Chapters 4–5 and the released code. (3) A component attribution for the
graph arm (edge typing = trainability; pooling = null) with an honestly
labeled supplement — Chapter 6 (H-T3) and `results/ablations/`.

Each contribution is verifiable from the repository: every number in
this booklet traces to a journal entry and regenerates from scripts over
raw per-game records.
