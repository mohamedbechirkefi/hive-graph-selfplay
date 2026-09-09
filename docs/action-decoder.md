# Shared action decoder (H4 task 1 — plan ch. 5)

The central confounder control of the study: **both architectures (grid CNN
and graph net) emit a policy over the *same* action space, built, masked,
normalised and trained the same way.** Only the state encoder and the
scoring function differ. This document is the contract; H5 implements both
arms against it, identically (decision D-015).

## 1. Move identity

A Hive move is uniquely identified by **(piece, destination cell)** —
walk-vs-throw collisions produce identical successor states (proof in the
`GameState::last_moved` doc comment), so no further attributes are needed.

- **Piece** is addressed by its side-to-move-relative slot
  `rel_piece ∈ 0..28`: own pieces 0..14 in roster order, opponent's 14..28
  (opponent slots exist because pillbug throws move enemy pieces; inert in
  base game but kept for kernel uniformity).
- **Destination** is a cell of the position's *candidate set*: occupied
  cells plus their 1-ring of empty neighbours — every legal destination
  lies in this set by construction (`hive_nn::Frame`).
- **Pass** is one extra action, legal exactly when no move exists.

## 2. The two realisations (same space, different parameterisation)

- **Grid arm** — the existing flat head: index
  `rel_piece × 1024 + y × 32 + x` over the 32×32 BFS-unwrapped,
  bbox-centered frame; `POLICY_SIZE = 28 673` (28 672 = pass). Reused
  as-is from `hive-nn`.
- **Graph arm** — per-candidate scoring: for each legal (piece, dest) the
  head scores `g(embedding of dest node, embedding of rel_piece slot)`;
  destination candidates (including *empty* 1-ring cells) are first-class
  graph nodes so every legal move has a scorable object. A learned scalar
  scores pass. No 28 673-way tensor exists in this arm — but the action a
  score refers to is the identical (rel_piece, dest cell) pair.

Both arms therefore expose the same interface to search and training:
`score(position) → logits over {legal (rel_piece, dest)} ∪ {pass if legal}`.

## 3. Masking and normalisation (identical in both arms)

- Logits are computed or gathered **only for the legal move set** the
  engine generates; the softmax runs over exactly that set (plus pass when
  legal). Probability mass on illegal actions is identically zero — H4
  check 1 asserts this on real positions for whichever arm is under test.
- The legal set's *order* carries no meaning: scores attach to
  (rel_piece, dest) pairs, never to list positions (the graph arm must be
  order-invariant; the grid arm is by construction).
- Argmax ties break deterministically toward the lowest flat policy index
  (grid indexing defines the tiebreak for both arms).

## 4. Training targets and records (shared)

- Self-play targets are MCTS root visit distributions over the same
  (rel_piece, dest) space — record v2: top-15 (policy index u16, visit
  weight u16) + total visits, magic `HIVEREC2`.
- Records store absolute piece coordinates, so any consumer (either arm)
  reconstructs the state, its frame, and its candidate set exactly; the
  stored flat indices decode to (rel_piece, dest cell) pairs for the graph
  arm. Round-trip stability encode→id→decode is H4 check 2.
- **Truncation is a distinct outcome in data** (D-008/D-011): the WDL
  byte gains value 3 = truncated (0 L, 1 D, 2 W, 3 T, side-to-move
  perspective). Prior records (all 0/1/2, with cap games mislabeled D)
  are prior work and are not training inputs for the new study.
- **Model-version stamping** (H4 task 2): reserved bytes 100..108 of the
  base record carry the generating model id (u32 generation + u32 config
  hash); 0 = pre-H4 record. Every shard answers "which model generated
  this?".

## 5. Value head convention (shared)

Value is a scalar in [−1, 1] **from the side-to-move's perspective**
(negamax, matching `hive_eval` and the MCTS tree convention). Terminal
values: win for the mover = +1, loss = −1, draw = 0; truncation is not a
terminal value (games truncated in generation contribute per the training
config, never silently as draws). Sign-under-alternation is pinned by the
H3 test battery and re-asserted for networks by H4 check 3.

## 6. Reuse decision

Recorded as D-015: the (rel_piece, dest) identification, frame, flat
index, and v2 record format are REUSED as the shared contract; the
28 673-way tensor is recognised as the grid arm's parameterisation, not
imposed on the graph arm, whose head scores the identical candidate pairs.
The shared-decoder requirement of plan ch. 5 is satisfied at the action
level (same space, same mask, same targets, same tiebreak), which is what
controls the confounder.
