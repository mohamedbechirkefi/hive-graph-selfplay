```yaml
id:            H5-2026-09-10-graph-wiring-01
date:          2026-09-10
hypothesis:    The D-022c items close H5: a Rust graph builder can match
               the Python builder exactly (golden crosscheck), the graph
               arm trains under the same loop conventions as the grid arm,
               and it evaluates through the same Rust MCTS via ONNX.
git_commit:    62dcc6d (+ this session's commit)
config:        hive-nn graph module; dump_graph + crosscheck_graph.py;
               GraphOrtEvaluator (CPU provider); train_graph.py (2-epoch
               smoke, seed 20260910); engine flag --mcts --graph-net
seeds:         crosscheck generator 0x6EA9^type; train 20260910; smoke
               arena 777, agents 5/6
data_version:  pilot0 gen000 shards (v3)
hardware:      Apple M1 Pro; MPS training; ORT CPU inference
duration:      ~20 min incl. 2-epoch training
cost:          0
```

## Methods

Rust `hive_nn::graph` mirrors `graph_dataset.build_graph` (same cell
ordering, feature layout, HEX_DELTAS direction order, Python's simplified
placement rule, loud overflow); `dump_graph` writes (v3 record, tensors)
pairs over 160 pseudo-random positions across all 8 game types;
`scripts/crosscheck_graph.py` rebuilds each graph in Python and asserts
exact equality — wired into `scripts/nightly.sh` beside the plane
crosscheck. `GraphOrtEvaluator` (hive-mcts) builds per-position tensors +
move rows in the search's move order, runs the static-shape ONNX export
on the CPU provider (measured faster than CoreML for this net), softmaxes
over the legal rows and converts WDL to P(W)−P(L) — the identical output
contract as the grid evaluator. `train_graph.py` mirrors `train.py`
(same value-loss truncation exclusion, bitwise-resume checkpointing,
per-epoch seeded shuffles); `export_onnx.py` gained a graph mode.

## Raw results + uncertainty

- **Golden crosscheck: PASS, 160/160 positions exactly equal** (nodes,
  nbrs, nmask, glob, moves, mmask) on the first run.
- 2-epoch smoke training on pilot0: 194 pos/s end-to-end on MPS
  (dataloader included); val policy top-1 4.7%, value acc 40.4% — the
  same profile as the grid arm on the identical gen-0 data (4–5%,
  ~43%), as expected for matched arms on matched data.
- Engine smoke: `--mcts --graph-net … bestmove depth 1` returns a legal
  move over UHP; arena smoke vs B-RND (6 games, 200 sims): 2 wins, 0
  losses, 4 truncations, no illegal replies, truncations reported
  separately.
- Full Rust suite: 30 result blocks, all green.

## Failures

None.

## Limits / confounders

Smoke-scale training (2 epochs, one seed) — a wiring validation, not a
strength or comparison result; arena smoke is 6 games.

## Interpretation

All D-022c items are closed and every H5 exit criterion holds: both
representations exist behind the byte-shared decoder, both are pinned by
cross-language golden tests, both train under identical conventions, and
both evaluate through the identical Rust MCTS with only the
representation, network body and their measured hardware costs differing
(comparison-controls table). H5 exits; H6 (controlled comparison under
frozen protocol v1.0) is unblocked.

## Decision

**continue** — H5 done; route to H6.

## Artifacts

- `crates/hive-nn/src/graph.rs`, `crates/hive-selfplay/src/bin/dump_graph.rs`,
  `crates/hive-mcts/src/graph_eval.rs`, engine `--graph-net`
- `python/hivenet/train_graph.py`, export graph mode,
  `scripts/crosscheck_graph.py` (nightly-wired)
- Smoke checkpoint/export under `data/runs/pilot0/checkpoints-graph/`
