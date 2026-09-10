# Grid representation specification (H5 task 1)

The grid arm's state encoding — the existing `hive-nn` frame and planes,
**reused as-is** (decision D-021): it is already engine-validated, pinned
by the Rust↔Python crosscheck, and is the study's baseline representation
(protocol §7). This document makes its conventions explicit.

## Coordinates and anchoring

The engine's board is a 64×64 wrapping byte grid (torus) with absolute
axial coordinates. For encoding, positions are **BFS-unwrapped** from the
torus starting at an arbitrary occupied cell (wrapping can never split
the hive) and translated so the **occupied bounding-box centre lands at
(16,16)** of a fixed **32×32 frame**. Hex adjacency on axial coordinates
is a 7-cell subset of the 3×3 neighbourhood, so plain 3×3 convolutions
cover it (two corners become learnable dead weights).

Anchoring is bbox-centre, not symmetry-canonical: no rotation/reflection
canonicalisation is applied (symmetry augmentation is excluded from the
full method by D-023; H7 ablates it).

## Window and overflow policy (task 2)

A 28-piece hive spans at most 28 cells per axis after unwrapping, so the
occupied box plus the full 1-ring of candidate destinations fits 32×32
with margin **by construction**. This argument is enforced, not trusted:

- `Frame::new` carries an **always-on assert** (not `debug_assert`) — any
  cell mapping outside the frame, ever, panics loudly. **No piece or
  candidate destination can vanish or alias silently, in release builds
  included.**
- Extremal tests construct the worst case (all 28 pieces in a straight
  line along each axis) and prove: every occupied cell and every 1-ring
  cell maps, and no two cells alias to one frame coordinate
  (`frame_extremal_line_positions_fit_without_aliasing`), plus long
  random-game drift coverage (`frame_never_overflows`).

## Channel list (77 planes, 32×32, float32 in [0,1])

| Planes | Content |
| --- | --- |
| 0–63 | Piece planes: (own = 0 / opponent = 32 offset) + bug type (Q,S,B,G,A,M,L,P) × 4 + min(stack level, 3) — owner, type and height jointly |
| 64 | One-hive-pinned top pieces (articulation cells) |
| 65 | Last-moved piece cell (stun-relevant state) |
| 66 | Side-to-move legal placement cells |
| 67 | Opponent legal placement cells |
| 68 | Side-to-move-is-white (constant) |
| 69, 70 | Queen liberties (stm, opponent) / 6 (constant; 0 if unplaced) |
| 71 | Ply / 100 (constant) |
| 72–74 | Game-type bits M, L, P (constant) |
| 75, 76 | Reserve counts (stm, opponent) / 14 (constant) |

Own/opponent is side-to-move-relative, matching the decoder's rel_piece
slots and the value head's negamax convention.

## Behaviour pin

The Rust encoder (`hive_nn::planes`) and the Python decoder
(`hivenet.dataset.decode_planes`) are byte-identical by contract,
enforced by the golden crosscheck (`dump_planes` +
`scripts/crosscheck_planes.py`, in `scripts/nightly.sh`). Any grid change
must keep this green or be recorded as a finding (invariant 2) — never
silently re-pinned.

## Network (grid arm)

`hivenet.model.HiveNet`: KataGo-lite ResNet — 3×3 conv stem, N residual
blocks (global-pooling bias in two middle blocks), 28,673-way flat policy
head over (rel_piece × frame cell) + pass logit from pooled features,
3-way WDL value head. Study capacity: channels 96 × blocks 8 = 1.44 M
parameters (comparability table: `comparison-controls.md`).
