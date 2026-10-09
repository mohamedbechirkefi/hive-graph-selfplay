# Graph representation specification (H5 task 4)

The graph arm's state encoding: a cell-graph over the position's
candidate set with typed geometric edges, fixed-capacity tensors, and
per-candidate policy scoring through the shared H4 decoder (D-015).
Implementation path: decision D-022.

**A GNN does not automatically grant invariance or rule equivalence —
any invariance claim must be tested, not assumed.** Nothing below
asserts translation/rotation invariance of the *learned function*; the
encoding is coordinate-free by construction (no absolute coordinates
appear anywhere), but message passing with directional edge types is NOT
rotation-invariant, receptive fields are depth-limited, and no rule of
Hive is "known" to the network. The time-permitting symmetry question
(protocol §1) is measured, never presumed.

## Concepts: cells, pieces, destinations

Three concepts, deliberately mapped as follows:

- **Nodes = cells of the candidate set**: every occupied cell plus its
  1-ring of empty neighbours — exactly the decoder's destination
  universe, so every scorable destination is a first-class node
  (including *empty* candidate cells, which a piece-only graph would
  miss — the Keller et al. lesson).
- **Pieces are not separate nodes** — justification: the decoder
  addresses moves as (rel_piece slot, destination cell); a piece's
  identity enters the policy through its slot embedding and its
  *location* through the node it stands on. Cell nodes carry the full
  stack composition (below), so no piece information is lost, and the
  graph stays half the size. This is a documented conflation with
  rationale, per the pipeline's requirement.
- **Candidate destinations** are the empty-cell nodes, distinguished
  from occupied nodes by an explicit occupancy feature — never
  conflated featurelessly.

## Node features (fixed layout)

Per node (cell): for each stack level 0..4 — present bit, owner bit
(side-to-move-relative), bug-type one-hot (8) → 5 × 10 = 50; plus stack
height / 5; empty-candidate bit; one-hive-pinned bit (articulation);
last-moved (stun-relevant) bit; stm-legal-placement bit; opponent-legal-
placement bit → **56 features**. Stacking is therefore fully represented
level-by-level up to height 5 (the base+MLP maximum relevant depth;
heights above 5 cannot occur in base game; the height scalar still
records them).

## Edges (typed, geometric)

Directed edges between adjacent cells *within the candidate set*, typed
by the six hex directions — the relative-direction/geometric attribute
the pipeline requires, realised as six relation-specific weight matrices
(RGCN-style). Encoded as a neighbour-index tensor: for each node, the
index of its neighbour in each direction (sentinel = none). Adjacency to
cells outside the candidate set cannot influence legality or value
(those cells are empty and non-adjacent to the hive) and is excluded.

## Global information

A global vector, broadcast to every node at input and concatenated to
the pooled representation at the heads: side-to-move-is-white; ply/100;
queen liberties (stm, opponent)/6; per-bug-type reserve counts
(stm, opponent)/3 → 16 + game-type bits (3) → **23 features**. Reserves
per type (not just totals) because placement legality and material
planning depend on which bugs remain in hand.

## Engine-contract coverage map (H1/plan ch. 4)

| State component (influences legality/outcome) | Graph element |
| --- | --- |
| Piece positions, owners, types | node stack-level features |
| Stacking (beetle climbs, buried pieces) | per-level features + height |
| Empty candidate destinations | empty-candidate nodes |
| Adjacency geometry / directions | typed edges (6 directions) |
| One-hive pins | pinned bit (engine articulation) |
| Stun state (`last_moved`) | last-moved bit |
| Side to move | own/opp-relative features + global bit |
| Queen placement deadline (ply) | ply global + reserve features |
| Reserves | per-type global counts |
| Game type (kernel guard) | global bits |
| Placement legality regions | stm/opp placement bits (engine-derived) |
| Move legality itself | **excluded** — supplied per-position by the engine through the decoder's legal mask, identically to the grid arm; the network never computes legality |
| Absolute board coordinates | **excluded** — coordinate-free by design; anchoring questions do not arise |

## Capacity limits (fixed tensors)

Node capacity **224**, edges implicit via the 6-slot neighbour tensor.
Measured maxima over random long games are well below (see property
tests); like the grid's frame the cap carries an always-on overflow
check — a position exceeding capacity fails loudly, never truncates
silently. Fixed shapes keep the ONNX export static for the CoreML
execution provider, so both arms share the same Rust MCTS inference path.

## Network (graph arm)

`hivenet.graph_model.HiveGraphNet`: input MLP on node features ⊕
globals; **L relational message-passing layers** — h'ᵢ = ReLU(W_self hᵢ
+ Σ_d W_d h_{n_i(d)} + b), with a global-pooling bias every third layer
(queen safety is global; message passing alone is depth-limited);
**value head**: masked mean+max pool ⊕ globals → MLP → 3-way WDL (same
convention as the grid arm); **policy**: per-candidate scoring through
the shared decoder — for each legal (rel_piece slot, destination):
MLP(dest-node embedding ⊕ source embedding ⊕ slot embedding), where
source = the piece's current node embedding for movements and a learned
reserve vector for placements; the pass row is scored by the same MLP
from (zero row ‖ reserve vector ‖ pass-slot embedding), i.e. a learned
constant — immaterial since pass is legal only when it is the sole
action. (Correction 2026-10-09: an earlier version of this sentence said
"from the pooled state"; the code never did that.)
Scores attach to (slot, destination) pairs; list order carries no
meaning (D-015 §3). Capacity is sized to the grid arm's 1.44 M
parameters or the difference is reported (`comparison-controls.md`).

## Behaviour pin (task 5 discipline)

Training builds graphs in Python **from v3 records** — the engine-side
reference, since records are engine-generated and themselves crosschecked.
Property tests over random long games assert no information loss: every
piece, stack level, reserve count, stun state and turn datum in the
record appears in the tensors, and node/edge maxima stay under capacity.
The Rust-side graph builder for MCTS inference must match the Python
builder via a golden crosscheck (`dump_graph` mirror of `dump_planes`)
before any H6 evaluation of the graph arm.
