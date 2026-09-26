# Chapter 2 — Formalisation (booklet draft, 2026-09-26)

*Sources: frozen protocol v1.0 (D-020); `docs/action-decoder.md` (D-015);
`docs/representations/`; engine architecture notes. No numbers here
beyond registered ones.*

## 2.1 The game and the studied variant

Hive is a two-player, perfect-information, zero-sum game played on an
unbounded hexagonal tiling: there is no board — the pieces in play define
the playing surface. We study the **base game only** (queen, spiders,
beetles, grasshoppers, ants; 11 pieces per side), decision D-007. The
engine implements the Mosquito/Ladybug/Pillbug expansions and the
tournament opening restriction (no queen on a player's first turn); the
kernel is exercised by tests across all eight game types, but no study
result involves an expansion.

## 2.2 State, actions, transition, result

A state s comprises: the placed pieces with their cells and stack levels
(beetles may climb, producing stacks), the reserves, the side to move,
the ply count, and the stun marker `last_moved` (relevant only under the
Pillbug expansion; carried for kernel uniformity — it is part of the
hashed position). The engine exposes s through the Universal Hive
Protocol (UHP); its rules correctness is established independently of
any learning component (Chapter 4).

An **action** is (piece, destination cell), which identifies any Hive
move uniquely — walk-vs-throw collisions produce identical successor
states — plus a distinguished *pass*, legal exactly when no move exists.
The legal-action set A(s) is produced by the engine's generator; both
learned architectures receive it and normalise their policies over
exactly A(s) (the shared decoder, Chapter 4). Transitions are the
engine's `play`; the game ends when a queen is fully surrounded (win for
the opponent; simultaneous surround = draw), with additional draw by
threefold repetition.

**Official result vs experimental truncation.** Self-play and evaluation
games are stopped at a 300-ply cap. A capped game is **not** a draw: it
is a fourth outcome class, *truncated*, carried through the data format
(records), the training loss (truncated games are excluded from the
value target), the match runner, all tables (separate rate column) and
the analysis. The reward for learning is the terminal result from the
side-to-move perspective: win +1, loss −1, draw 0; truncation
contributes no value target.

## 2.3 Search and learning notation

Both arms use the same PUCT Monte-Carlo tree search: at a node, an
evaluator returns priors over A(s) and a scalar value v ∈ [−1, 1]
(side-to-move perspective); selection maximises Q + c·prior·√N/(1+n)
with c = 1.4; terminal values back up exactly. Self-play uses playout-cap
randomization (a fraction 0.25 of decisions get 128 simulations and are
recorded; the rest get 32 and are not), Dirichlet root noise (ε 0.25),
temperature sampling for the first 12 plies, and resignation below −0.92
with a 10% no-resign audit fraction. **Evaluation applies none of the
exploration machinery** (ε = 0, deterministic argmax; enforced by test
and pinned by config, D-019) and runs 400 simulations per decision.

Training minimises a policy cross-entropy against the recorded MCTS
visit distributions, normalised over the legal set for both arms, plus a
weighted 3-class value loss (weight 0.6) over win/draw/loss with
truncated samples excluded. Budgets are accounted in four denominations
per run — wall-clock, hardware, training states, simulations — and the
comparison is read under two equalisations (same-examples,
same-wall-clock), Chapter 5.

## 2.4 Game view vs encoding view

The same state s is encoded two ways (figure fig3-encodings): the *grid
view* embeds the position in a fixed 32×32 frame (BFS-unwrapped from the
engine's toroidal board, bounding-box-centred) with 77 feature planes;
the *graph view* is coordinate-free — nodes are the occupied cells plus
every empty cell adjacent to the hive (exactly the decoder's destination
universe), edges carry the six hex directions as types, stacks appear
level-by-level as node features, and reserves/side/ply enter as a global
vector. Chapter 4 specifies both; nothing else in the system differs
between the arms.
