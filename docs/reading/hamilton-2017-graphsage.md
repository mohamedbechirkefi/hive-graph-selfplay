# Hamilton, Ying & Leskovec (2017) — GraphSAGE

```yaml
citation:        "William L. Hamilton, Rex Ying, Jure Leskovec. Inductive Representation Learning on Large Graphs."
venue_year:      "NeurIPS 2017 (peer-reviewed; NIPS at the time). arXiv:1706.02216."
question:        "How to compute node embeddings inductively — for nodes (and whole graphs) never seen during training — instead of transductively learning one embedding per known node."
game_task:       "Not a game. Inductive node classification: evolving citation graph (paper subject prediction), Reddit post community prediction, and cross-graph generalization on protein-protein interaction (PPI) graphs."
representation:  "Graph with node features; embeddings produced by sampling a fixed-size neighborhood per node and aggregating neighbor features over K layers (K=2 typical). Learns aggregator functions (mean, LSTM, max-pooling; GCN-style variant as baseline), not per-node embedding tables."
search_method:   "None (representation learning; downstream classifiers). No MCTS/RL component."
compute_budget:  "Not reported as a systematic budget; designed for large graphs via fixed-size neighborhood sampling (constant per-batch cost); experiments on single-machine setups."
metrics:         "Micro-F1 on inductive node classification (unseen nodes / entirely unseen graphs for PPI), against transductive and feature-only baselines; both unsupervised (random-walk proximity loss) and supervised training."
code_available:  yes (https://github.com/williamleif/GraphSAGE — official, TensorFlow, by Hamilton & Ying)
limits:          "Fixed-size uniform neighbor sampling introduces variance and ignores edge semantics — vanilla GraphSAGE has no edge attributes/edge features; depth K kept small (2), so receptive field is limited; aggregator choice matters (pooling/LSTM beat mean on some tasks); benchmarks are static-feature classification, not sequential decision-making."
difference_from_our_study:  "We keep the core idea identical: an inductive message-passing encoder whose weights are shared across arbitrary board graphs, which is exactly what a variable, frameless Hive board needs (any position, any size, is 'unseen nodes'). We change: (1) we add edge attributes (hex-direction / adjacency type) which vanilla GraphSAGE lacks; (2) we aggregate over full 1-hop neighborhoods (Hive graphs are small, degree <= 6, so no sampling); (3) the encoder feeds a policy/value head trained by AlphaZero-style self-play rather than a classification loss. Our 'simple message-passing GNN' is essentially a SAGEConv-with-edge-attributes stack; Keller et al. 2023 also used SAGEConv for Hex, supporting this choice for small nets."
relevance:       "RQ-H1 — justifies why a GNN encoder can, in principle, beat a grid/CNN encoder for Hive: inductive generalization across board configurations/sizes is the property the 32x32 BFS-unwrapped CNN frame only approximates."
date_read:       2026-09-09
version_doi:     "arXiv:1706.02216 (v4, 2018-09-10), DOI 10.48550/arXiv.1706.02216; NeurIPS 2017 proceedings. Code: github.com/williamleif/GraphSAGE (no specific release pinned)."
classification:  bibliography
purpose:         lit-review
```

## Notes

- Core mechanism relevant to us: node embedding h_v^k = sigma(W · concat(h_v^{k-1}, AGG({h_u^{k-1}: u in N(v)}))). Weights are per-layer, not per-node, so the same trained network embeds any graph — this is the formal basis for our claim that a Hive GNN needs no fixed board frame, no bbox-centering, and no BFS unwrapping.
- Aggregators studied: mean, GCN-style (no concat), LSTM (over randomly permuted neighbors — not permutation invariant, a caveat), and max-pooling over a per-neighbor MLP. Pooling and LSTM were strongest empirically. For a small net on degree-≤6 Hive graphs, mean or max aggregation over an edge-conditioned message MLP is the natural minimal choice.
- Neighborhood sampling (e.g., 25 then 10 neighbors at layers 1–2) exists purely for scalability on massive graphs; irrelevant at Hive scale — we use exact neighborhoods, which removes their main source of variance.
- K=2 layers already gave most of the gain on their benchmarks; useful when arguing our "small net" regime — but Hive tactics (rings, pinning chains) may need more hops or a global readout; Keller et al. needed 15 SAGEConv layers for Hex long-range dependencies. Depth-vs-budget is a real axis for RQ-H1, not a free choice.
- Nothing here about action spaces, stacking, or games. Stacked Hive pieces have no analogue; our options (stack encoded as node features, e.g., top-piece one-hot + height, vs. explicit vertical stack nodes) are a design decision GraphSAGE does not constrain.
- Peer-reviewed venue (NeurIPS 2017); one of the standard citations for inductive/message-passing GNNs, so it anchors the "graph representation" side of the related-work section.
