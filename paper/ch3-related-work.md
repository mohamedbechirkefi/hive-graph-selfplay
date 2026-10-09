# Chapter 3 — Related work and positioning (booklet draft, 2026-09-26)

*Sources: `docs/reading/` (verified notes; one row per work in
`docs/reading/matrix.md`); decision D-009 (scoped claim). Only noted,
actually-consulted sources are cited; full metadata lives in the
bibliography/webographie.*

## 3.1 Self-play reinforcement learning at scale — and small scale

AlphaZero (Silver et al. 2017/2018) fixed the algorithmic template this
study inherits: a policy-value network guiding PUCT-MCTS self-play, with
the state presented as stacked spatial planes (8×8×119 for chess) and
the policy itself expressed spatially — the canonical grid
parameterisation our grid arm descends from. Its evidence style,
however, is what a small-compute study must *depart* from: a single
training run per game, budgets denominated in hardware (5,000
first-generation TPUs) rather than in comparable units, and evaluation
against one reference engine. KataGo (Wu 2020) showed the pipeline's
cost is compressible by roughly 50× at equal strength (under 30 V100s
for 19 days versus ELF OpenGo's ≈74 GPU-years) and set the
budget-reporting standard — GPU-days, games, samples, with per-technique
ablations — that our accounting follows; of its economies we adopt
exactly one, playout-cap randomization, because it is
representation-agnostic and can be applied identically to both arms,
and we deliberately skip the Go-specific input features and auxiliary
targets that would smuggle domain knowledge into one encoding. Jones
(2021) trained AlphaZero-style agents across Hex board sizes on ≈500
GPU-hours total and found smooth compute-performance frontiers —
the closest methodological licence for drawing conclusions at our
scale — and contributed a warning we encode in the protocol: train-time
and test-time compute trade off, so evaluation visit counts must be
pinned, not floated. Agarwal et al. (2021) supply the statistical
frame: in few-run regimes, point estimates over single runs frequently
reverse under proper interval analysis; their prescriptions —
aggregate per run first, resample the run, report intervals, never pool
games as independent observations — are implemented here with the seed
as the resampling unit throughout.

## 3.2 Graph representations and variable action spaces

GraphSAGE (Hamilton et al. 2017) grounds the inductive message-passing
family our graph arm belongs to; vanilla GraphSAGE lacks edge semantics,
which our direction-typed relations add. Pointer Networks (Vinyals et
al. 2015) justify scoring a variable candidate set — our shared decoder
scores exactly the legal (piece, destination) pairs, with empty
destination cells as first-class scorable objects. MDP-homomorphic
networks (van der Pol et al. 2020) motivate the *time-permitting*
symmetry question only; per the protocol, no invariance is assumed of a
GNN, and none was claimed.

## 3.3 Hive and grid-vs-graph comparisons

Scholarly Hive AI is thin. Kampert et al. (2021) built heuristic
minimax/MCTS agents on the BeeKeeper engine, documented Hive's ≈60
branching factor, and found that an intuitively central feature
(tiles around the queen) carries surprisingly little evaluation signal
once tuned — an early warning that Hive's value structure is not where
intuition puts it; their agents, like every scholarly Hive agent before
ours, remained below strong human play. AZ-Hive (de Goede et al. 2022)
is the closest prior work and the study's direct motivation: AlphaZero
on Hive across a 5 × 2 design space of board and action encodings —
all dense hex-lattice arrays into a CNN, no graph option anywhere in
the space (confirmed against the full text) — with the stark result
that after 24 h of training their best engine still lost to plain MCTS
and minimax (BayesElo 1063 vs 1181/1355), while encoding choice
measurably changed early learning speed. That is precisely RQ-H1's
premise: in Hive, the encoding is load-bearing. Polygames (Cazenave et
al. 2020) achieves boardsize invariance — fully convolutional bodies
with global pooling — but within the grid paradigm and without Hive
support: it scales fixed-topology boards, which a boardless, stacking
game does not offer. The direct grid-vs-graph precedents are two. Keller
et al. (2023) ran a parameter-matched CNN-vs-GNN comparison on Hex
(≈487K vs ≈481K parameters, ≈110 A100-hours per model) and found the
asymmetry our result extends: the GNN dominated long-range-dependency
tests and transferred across board sizes, while the CNN remained
sharper at local patterns — but their controlled comparison ran under
RainbowDQN, their CNN arm never trained under MCTS self-play, their
graph is a Hex-specific Shannon-game reduction (played cells are
contracted away; actions biject to nodes), and they state themselves
that the construction does not generalise to other games. Rigaux &
Kashima (2024, NeurIPS) report the opposite sign for chess: an
edge-featured graph-attention network (GATEAU) with an edge-based
policy readout out-learns CNN baselines in an AlphaZero-style loop and
transfers across board sizes — but from a single training run per
model (intervals cover Elo estimation only, not run variance), with
loose capacity matching (1.0M vs 2.2M parameters) and a decoder that
differs between arms, confounding representation with action
parameterisation; our design removes exactly those three confounds.
Ben-Assayag & El-Yaniv (2021) trained a GIN-based AlphaZero on Othello
lattice graphs to scale small-board training to larger boards — a
transfer claim under deliberately asymmetric budgets, not an
equal-budget representation comparison, though notably with the best
replication hygiene of the three (five runs with standard errors). An
unpublished hobby project (hiveGo; webographie) trains a small GNN on
Hive with an AlphaZero-style loop and reports only anecdotal
evaluation — no controlled comparison of any kind.

## 3.4 Positioning

No prior work runs a controlled, budget-matched grid-vs-graph comparison
for Hive with both arms under the same self-play pipeline; that is this
study's scoped contribution (D-009) — deliberately *not* "the first
grid-vs-graph comparison in a board game", which Keller et al. and
Rigaux & Kashima preclude. The scope closes as follows: one variant
(base Hive), one grid net and one simple relational GNN at matched
capacity, one machine, frozen opponents/openings/protocol, two budget
readings, five seeds per arm. Within that perimeter the comparison is
answered (Chapter 6); outside it, nothing is claimed. The contrast with
Rigaux & Kashima's positive chess result and Keller et al.'s
long-range-vs-local asymmetry is taken up in the discussion.
