# Method — Policy-value pipeline and pre-training checks (report section draft)

*Drafted 2026-09-10 at the H4 close (invariant 14). English working
master; French copy at the report milestone (D-006). Numbers trace to
journals `H4-2026-09-09-coreml-fix-01` and `H4-2026-09-10-pilot-01`;
claims registered in `claims.md`.*

## The shared action decoder

Both architectures emit a policy over the same action space — a move is
(side-relative piece slot, destination cell) plus pass — with identical
legal-set masking, normalisation over exactly the legal set, identical
MCTS visit-distribution targets, and a deterministic tiebreak
(`docs/action-decoder.md`, D-015). The grid arm materialises this space
as a 28,673-way tensor over its 32×32 frame; the graph arm (H5) scores
the identical candidate pairs per position with empty destination cells
as first-class nodes. Nothing about the action interface differs between
arms; only the state encoder and scoring function do — this is the
study's central confounder control.

## Data discipline

Self-play records are versioned and self-describing: each carries the
generating model's stamp (generation + net hash), the position, the
visit-distribution target, the legal-move index list that enables
masked training, and a four-valued outcome — win, draw, loss, or
**truncated** (a ply-cap game is never recorded as a draw; truncated
records are excluded from the value loss). A per-run manifest ties every
shard to its model, and the run layout separates `selfplay/` (training
inputs), `checkpoints/`, and `eval/` (never training input), enforced by
an audit script.

## Seven pre-training checks

All automated, run as one command against real shards before any
training is trusted: (1) the masked softmax puts exactly zero mass on
illegal actions and sums to one over legal actions, on real positions
through a real forward pass; (2) encode→id→decode is the identity on all
legal moves across game types (and stored targets are always legal);
(3) outcomes are correct for the player to move, both colours, with
truncation distinct; (4) a fixed tiny batch overfits to near-perfect fit
— policy argmax 15/15, value 15/15, residual KL 0.09 against soft
targets (the criterion is KL to the target-entropy floor: soft visit
distributions have irreducible entropy, so "loss → 0" is the wrong
test); (5) save/resume reproduces bitwise-identical model and optimizer
state, with the interruption preserving the planned LR schedule; (6)
exploration noise is structurally evaluation-impossible (the eval path's
defaults carry ε = 0, asserted by test; settings pinned by config +
decision D-019); (7) no evaluation game can reach training, by layout
and audit.

## Small-budget pilot

One full generation from a seeded random initialisation (1.44M-param
grid net, 300 games at 128/32 simulations with playout-cap
randomization): 17,237 positions, 56.7% of gen-0 games truncated
(reported, not folded into draws), training non-degenerate (policy above
chance, value above base rate, losses decreasing), and independent
evaluation against the frozen population under pinned settings:
**100–0 vs legal-random**, 3.3% vs the documented heuristic, 3.3% vs
6400-sim MCTS. The diagnosis is clean and follows the mandated order
(rules, signs, search, data — the first three independently validated in
H2/H3): after one generation the gap to strong opponents is a data and
iteration gap, and the indicated lever is more generations, not more
capacity. Budget confirmation: worst-case (gen-0) generation cost is
≈12 s/game wall at 4 threads, falling toward ≈3 s/game as play sharpens
with a trained net.

## Limits

Single seed end-to-end at pilot scale; 30 evaluation games per opponent;
only the grid arm exists yet (the graph arm arrives in H5 against the
same decoder contract); gen-1+ iteration exercised structurally, not run.
