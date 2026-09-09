# Baseline opponents (H3 — plan ch. 5 étape A)

The fixed evaluation population the protocol's primary metric refers to
(protocol §4). Three agents, one engine binary, all seeded and driven over
UHP; frozen under G-FREEZE at the end of H3 (freeze record referenced here
once approved). **After the freeze, no opponent is touched — no retuning,
no re-versioning** (any touch = a new study).

## B-RND — legal-random

Uniform over the legal moves of the validated engine
(`hive-engine --random --seed N`). Deterministic given (seed, game
history): the RNG state advances per query mixed with the position hash,
so identical seeds replay identically and distinct seeds give distinct
games. Config: `configs/baselines/random.toml`.

Rationale: the floor of the population — any learned or heuristic agent
must dominate it; it also anchors the score scale.

## B-HEU — documented heuristic

Greedy argmax of the handcrafted evaluation (`hive-engine` default
backend pinned to `bestmove depth 1`, single thread), with the searcher's
quiescence on enemy-queen-targeting moves. Config:
`configs/baselines/heuristic.toml`.

Features and weights (`hive_eval::Weights::default()`, mirrored in
`configs/baselines/heuristic-weights.toml`, sha256
`d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a`,
pinned by the hive-eval test `weights_pinned_for_h3_baselines`):

| Feature | Weight(s) | Rationale |
| --- | --- | --- |
| Queen liberties (empty cells around own queen, 0..6) | −2000, −700, −350, −150, −50, 0, +20 | Dominant term: surround distance to loss is the game's objective (rulesheet p. 11); steeply convex as liberties vanish. |
| Enemy piece adjacent to own queen | −90 each | Enemy neighbours are permanent surround material. |
| Friendly piece adjacent to own queen | −20 each | Own pieces crowd escape squares and can be pinned there. |
| Enemy piece on top of own queen | −180 | A covered queen cannot flee and the cell counts against it. |
| Piece free to move (per bug: Q,S,B,G,A,M,L,P) | 15, 35, 55, 40, 80, 55, 50, 40 | Mobility ≈ material in Hive; the ant is the most valuable mover (rulesheet p. 8). |
| Piece pinned/immobile (same order) | 0, 4, 8, 6, 10, 6, 6, 4 | A pinned piece is nearly dead material; small residual for latent value. |
| Piece in hand | +6 each | Placement flexibility / tempo. |
| Own pillbug adjacent to own queen | +40 | Rescue-throw availability (kernel term; inert in base game). |

Score convention: centipawn-like, positive = good for the side to move
(negamax; alternation identity pinned by
`value_negates_under_player_alternation`). **Weights were inherited as-is
from the prior engine's defaults and are fixed for the study — no tuning
occurred in H3 and none may occur after final tests** (plan ch. 5).

## B-MCTS — MCTS without network

PUCT MCTS on the validated engine with uniform priors and the
tanh-squashed handcrafted eval as leaf value (`hive_mcts::EvalNet`); no
neural network, no exploration noise in match play (Dirichlet ε = 0 by
default). Budget: **6400 simulations per decision** (`--sims 6400`,
`bestmove depth 1`), measured at ≈27 ms/decision single-thread on the
study machine — an honest, reproducible budget set from measurement, not
from the plan's placeholders (D-014). Config:
`configs/baselines/mcts-nonet.toml`.

## Search verification (task 4)

`tests/tactical_positions/` (5 hand-annotated cases, rules-derived,
committed before any run): B-MCTS solves 5/5 at 400, 1600 and 6400 sims —
mate-in-1 by walk and by grasshopper jump, from both colours, and no
self-surround. Value signs under player alternation are pinned by
automated tests: hive-eval negamax identity, hive-search mate-score signs
(both colours), hive-mcts root-value signs (both colours).

## Characterisation (journal H3-2026-09-09-baselines-01)

100 paired colour-swapped games per pairing, common seeded openings,
truncations reported separately (zero occurred):

| Pairing | Result | Score | Elo (descriptive) |
| --- | --- | --- | --- |
| B-HEU vs B-RND | 100/0/0 | 100.0% | ≈+2400 |
| B-MCTS vs B-RND | 99/1/0 | 99.5% | +920 [+730, +1200] |
| B-MCTS vs B-HEU | 23/29/48 | 37.5% | −89 [−150, −32] |

**Ordering finding (discussed, not retuned):** B-MCTS(6400) sits slightly
below B-HEU — uniform priors spread the budget thin over Hive's ~60-move
branching while the greedy agent's queen-targeting quiescence is
tactically sharp; a 4×-budget probe (25,600 sims, 24 games) reached 56.2%,
confirming budget scaling. Consistent with AZ-Hive's and Kampert et al.'s
observations that plain search/heuristics are strong in Hive. The
population reads: R = floor; H and M a mid band ~90 Elo apart with
different styles.

## Freeze

The population freeze (G-FREEZE, human) is presented with: the three
configs + weight hash, engine commit, this characterisation, the B-MCTS
budget choice (6400 as configured and characterised, or 25,600 near-parity
at 4× cost, needing re-characterisation), and the gen-19 question (D-016
proposes exclusion). Freeze record lands in `state/decisions.md`; after
it, no opponent is touched.
