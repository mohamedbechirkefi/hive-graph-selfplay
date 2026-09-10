# Method — The two representations (report section draft)

*Drafted 2026-09-10 at the H5 close (invariant 14). English working
master; French copy at the report milestone (D-006). Numbers trace to
journals `H5-2026-09-10-encoders-01` and `H5-2026-09-10-graph-wiring-01`;
claims registered in `claims.md`.*

## What varies, and what provably does not

The study's independent variable is the state representation and its
network body — nothing else. Both arms share the engine, the search, the
frozen opponents and pinned evaluation settings, the self-play records,
the training targets and outcome conventions, the action space with its
legal-set normalisation, and the training-loop machinery. Each shared
element is enforced rather than asserted: the decoder is one contract
with identical masking; the records are one format; each encoder is
pinned by a cross-language golden test (240 positions for the grid
planes, 160 for the graph tensors, byte-exact, run nightly); and both
arms evaluate through the same Rust MCTS via ONNX exports.

## The grid arm

The baseline representation embeds the position in a fixed 32×32 frame:
BFS-unwrapped from the engine's torus, bounding-box-centred, with 77
feature planes (piece/owner/type/height jointly, pins, stun, placement
regions, and global scalars as constant planes). A 28-piece hive plus
its full ring of candidate destinations fits the frame by construction;
that argument is enforced by an always-on assert and extremal tests
(28-piece straight lines: complete, alias-free mapping) — no piece can
vanish silently, in release builds included. The network is a
KataGo-lite ResNet (1.44 M parameters) with a flat
(piece-slot × frame-cell) policy head.

## The graph arm

The graph representation is coordinate-free: nodes are the cells of the
candidate set — every occupied cell and every empty 1-ring cell, so each
scorable destination is a first-class node; edges are typed by the six
hex directions; node features carry the stack level-by-level (owner and
bug type per level), pins, stun, and placement regions; reserves,
side-to-move, ply and game type enter as a global vector. Pieces are not
separate nodes: the shared decoder addresses moves as (piece slot,
destination cell), so piece identity enters the policy through a slot
embedding and the piece's standing node — a documented design choice,
not an accident. The network is a small relational message-passing net
(direction-specific weights, global-pooling bias, masked pooling for the
value head, per-candidate move scoring) at 1.47 M parameters — a +2.1%
capacity difference, reported.

**A graph network grants no invariance or rule equivalence for free.**
The encoding contains no absolute coordinates, but the learned function
is not thereby translation- or rotation-invariant, and no rule of Hive
is built in; any such claim in this study is measured, never assumed.

## Measured cost asymmetries (reported, not equalised)

On the study machine, the best available inference path differs per arm:
the convolutional grid net runs on the CoreML accelerator at 2.62
ms/evaluation, while the gather-heavy graph net runs fastest on CPU at
3.67 ms (CoreML is slower for it) — a ≈1.4× per-decision cost against
the graph arm. Training shows the reverse pattern per device (CPU
favours graph 3.5×; the MPS path used for training favours grid ≈2×).
These are genuine hardware interactions of the representations; the
protocol's two budget readings (same-examples and same-wall-clock)
charge them honestly rather than hiding them.

## Symmetry augmentation

Excluded from the full method for both arms (D-023): exclusion makes the
identical-data-protocol rule trivially true, avoids implementing hex
symmetries differently per representation, and leaves augmentation as a
clean additive ablation question.

## Limits

Costs are single-machine; the wiring validation trained the graph arm at
smoke scale only (its learning profile on gen-0 data matched the grid
arm's, as expected for matched arms on shared data — not a comparison
result); the controlled comparison itself is H6, under protocol v1.0.
