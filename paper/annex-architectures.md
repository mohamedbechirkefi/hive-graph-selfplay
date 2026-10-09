# Annex B — Architectures, decoder and data formats in detail

*Sources: `python/hivenet/model.py`, `python/hivenet/graph_model.py`,
`crates/hive-nn/` (authoritative); docs/representations/;
docs/action-decoder.md. Parameter counts are measured
(`count_params`), not estimated.*

## B.1 Grid arm — HiveNet (1.44 M parameters)

Input: 77 planes × 32 × 32 (float32 in [0,1]). Plane groups: 64 piece
planes (own/opponent × 8 bug types × stack level 0–3+), one-hive-pinned
tops, last-moved (stun) cell, legal placement regions for both sides,
side-to-move constant, queen-liberty scalars (both queens, /6), ply/100,
game-type bits, reserve counts (/14).

Body: 3×3 convolutional stem → 8 residual blocks of 96 channels (two
3×3 conv + BatchNorm each); blocks 2 and 5 carry a KataGo-style
global-pooling bias (mean‖max pooled channels → linear → per-channel
bias). Hex adjacency on axial coordinates is a 7-cell subset of the 3×3
neighbourhood, so plain 3×3 convolutions cover it; the two non-neighbour
corners become learnable dead weights.

Heads: policy = 1×1 convolution to 28 piece-slot planes, flattened to
28,672 spatial logits, plus a pass logit from pooled features
(POLICY_SIZE = 28,673); value = pooled features → 64 → 3 (win/draw/loss
from the side to move).

## B.2 Graph arm — HiveGraphNet (1.47 M parameters, +1.5%)

Input per position: up to 224 nodes (occupied cells + every empty cell
adjacent to the hive — exactly the decoder's destination universe),
each with 56 features: per stack level 0–4 a (present, owner-is-mover,
bug one-hot[8]) block; stack height/5; empty-candidate, one-hive-pinned,
last-moved, and both placement-region bits. A 23-value global vector
(side, ply/100, queen liberties/6, per-bug-type reserves/3 for both
sides, game-type bits) is concatenated to every node's input.

Body: input linear to 152 channels → 8 relational message-passing
layers: h′ᵢ = ReLU(W_self hᵢ + Σ_d W_d h_{n_i(d)} + b) with six
direction-typed weight matrices (the six hex directions as edge types),
residual, masked; every third layer adds a masked global-pooling bias
(mean‖max → linear). Neighbour structure is a (224 × 6) index tensor
with a zero pad row — all shapes static, so the ONNX export is
fixed-shape and runs under the same Rust inference path as the grid arm.

Heads: value = masked mean‖max pooling ‖ globals → 64 → 3 (same
convention). Policy = per-candidate scoring through the shared decoder:
for each legal (slot, destination) the logit is
MLP(dest-node embedding ‖ source embedding ‖ slot embedding[32]), where
the source embedding is the piece's standing node for movements and a
learned reserve vector for placements; one learned pass logit. Logits
attach to moves, never to list positions.

**Ablation variants** (H-T3): `untyped_edges` shares ONE matrix across
the six directions (0.54 M — the typed matrices are the ablated
component); `no_gpool` removes every pooling bias (1.37 M).

## B.3 The shared action decoder

A move is (side-relative piece slot 0–27, destination cell) plus pass;
slots 14–27 address opponent pieces (pillbug throws; inert in base
game). The grid arm materialises the space as the flat 28,673-way
tensor (slot × frame cell); the graph arm scores the identical pairs
per candidate. Both arms: identical legal-set masking, softmax over
exactly the legal set, identical MCTS visit-distribution targets,
deterministic tiebreak toward the lowest flat index. Check 1 of the
pre-training battery asserts zero probability mass outside the legal
set through a real forward pass for whichever arm is under test.

## B.4 Record format v3 (818 bytes)

Bytes 0–83: 28 × (x, y, level) in frame coordinates, 255 = in hand;
84 side to move; 85 last-moved id (stun state); 86 ply; 87 game-type
bits; 88–91 queen liberties and reserves (mover/opponent); 92–95
one-hive-pinned bitmask; 96–97 played-move policy index; 98 outcome
from the mover's perspective — 0 loss / 1 draw / 2 win / **3
truncated** (never a draw); 99 version; 100–107 generating-model stamp
(generation, net hash); 112–175 top-15 MCTS visit distribution +
total; 176–177 legal-move count; 178–817 the legal policy-index list
(cap 320; measured max branching 213) that enables legal-masked
training in both arms. Rust and Python builders for both the plane and
graph encodings are pinned byte-identical by nightly cross-language
golden tests (240 and 160 positions respectively).

## B.5 Search (shared)

PUCT MCTS, c = 1.4, batched leaf evaluation, terminal values backed up
exactly; self-play adds Dirichlet root noise (ε 0.25), temperature
sampling for 12 plies, playout-cap randomization (25% of decisions at
128 simulations — recorded; 75% at 32 — unrecorded), resignation at
−0.92 with a 10% no-resign audit; evaluation runs 400 simulations,
no noise, deterministic argmax (enforced by test, pinned by config).
