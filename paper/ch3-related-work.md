# Chapter 3 — Related work and positioning (booklet draft, 2026-09-26)

*Sources: `docs/reading/` (verified notes; one row per work in
`docs/reading/matrix.md`); decision D-009 (scoped claim). Only noted,
actually-consulted sources are cited; full metadata lives in the
bibliography/webographie.*

## 3.1 Self-play reinforcement learning at scale — and small scale

AlphaZero (Silver et al. 2017/2018) fixed the algorithmic template this
study inherits: a policy-value network guiding PUCT-MCTS self-play. Its
budget reporting, however, is hardware-denominated and single-run —
precisely what a small-compute, multi-seed study must improve on. KataGo
(Wu 2020) showed the pipeline's cost is highly compressible and set the
budget-reporting standard (GPU-days, games, samples) our accounting
follows; its representation-agnostic economies (playout-cap
randomization) are applied identically to both arms here. Jones (2021)
demonstrated that deliberately small AlphaZero-style experiments on Hex
yield lawful, extrapolatable signal — the closest methodological
licence for our setting — and supplied the compute-frontier reporting
style, while never varying the representation. Agarwal et al. (2021)
provide the statistical frame: few-run regimes demand seed-level
resampling and interval reporting, which our protocol adopts with the
seed as the unit.

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
minimax/MCTS agents (BeeKeeper) and documented Hive's ~60 branching
factor and the weakness of naive evaluation signals. AZ-Hive (de Goede
et al. 2022) is the closest prior work: AlphaZero on Hive across five
board encodings — all dense grid/CNN, no graph arm — with engines that
remained below plain search; its finding that encoding choice strongly
affects learning is direct motivation for RQ-H1. Polygames (Cazenave et
al. 2020) achieves boardsize invariance within the grid paradigm and
does not support Hive. The direct grid-vs-graph precedents are Keller
et al. (2023) — parameter-matched CNN-vs-GNN on Hex, but under
RainbowDQN (the CNN arm never trained under MCTS self-play) and with a
Hex-specific Shannon-game graph — and Rigaux & Kashima (2024, NeurIPS), an
edge-featured GAT for chess reporting GNN gains in an AlphaZero-style
loop — from a single training run per model, without seed replication. Ben-Assayag & El-Yaniv (2021) trained a GNN-AlphaZero on Othello
for size scaling, not for a budget-matched representation comparison.
An unpublished hobby project (hiveGo; webographie) trains a small GNN on
Hive with an AlphaZero loop, with no controlled comparison.

## 3.4 Positioning

No prior work runs a controlled, budget-matched grid-vs-graph comparison
for Hive with both arms under the same self-play pipeline; that is this
study's scoped contribution (D-009) — deliberately *not* "the first
grid-vs-graph comparison in a board game", which Keller et al. and
Rigaux & Kashima preclude. The scope closes as follows: one variant
(base Hive), one grid net and one simple relational GNN at matched
capacity, one machine, frozen opponents/openings/protocol, two budget
readings, three seeds per arm. Within that perimeter the comparison is
answered (Chapter 6); outside it, nothing is claimed. The contrast with
Rigaux & Kashima's positive chess result and Keller et al.'s
long-range-vs-local asymmetry is taken up in the discussion.
