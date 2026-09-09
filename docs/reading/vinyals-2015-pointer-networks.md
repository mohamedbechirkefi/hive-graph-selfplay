# Vinyals, Fortunato & Jaitly (2015) — Pointer Networks

```yaml
citation:        "Oriol Vinyals, Meire Fortunato, Navdeep Jaitly. Pointer Networks."
venue_year:      "NeurIPS (NIPS) 2015, Advances in Neural Information Processing Systems 28 (peer-reviewed). arXiv:1506.03134."
question:        "How can a neural network output a distribution over a *variable-size* set of candidates — a dictionary whose size and identity depend on the input — instead of a fixed output vocabulary."
game_task:       "Not a game: combinatorial problems over point sets — sorting variable-length sequences, planar convex hulls, Delaunay triangulations, planar Travelling Salesman Problem."
representation:  "Sequence of input elements (2D point coordinates) encoded by an RNN; each candidate output IS an input element, represented by its encoder state."
search_method:   "None (supervised sequence prediction with beam search at inference; no MCTS, no RL)."
compute_budget:  "Not reported (no systematic budget; single-model supervised training on generated data, up to n=50 elements)."
metrics:         "Task accuracy of predicted structures (e.g., correctness/area coverage for convex hulls, triangulation accuracy) and TSP tour quality vs exact/heuristic solvers; generalization to input sizes beyond those seen in training (e.g., hulls trained on n<=50 evaluated on larger n)."
code_available:  no (no official release; many third-party reimplementations)
limits:          "Attention scoring is over encoder states of a *sequence* — order-sensitive encoder for what is really a set; supervised only (needs ground-truth outputs); TSP quality degrades on larger instances; candidates must be input elements (cannot point at things absent from the input)."
difference_from_our_study:  "We keep the core mechanism: the policy is a compatibility score between a query and each element of a variable candidate set, normalized by softmax over exactly the legal candidates — no fixed action lattice, no masking of a huge dead output space. We change everything around it: candidates are (piece, destination) pairs, each embedded from GNN node embeddings (or CNN feature-map cells for the grid arm) rather than RNN encoder states; the scorer is a small shared MLP decoder used identically by both encoder arms; training signal is AlphaZero-style self-play (MCTS visit distributions), not supervised targets. The 'cannot point at absent elements' limit is why our graph must contain empty candidate-destination nodes: a destination has to exist as an element to be scorable."
relevance:       "RQ-H1 — it is the canonical justification for our shared per-action decoder over variable (piece,destination) sets, the component that makes the CNN-vs-GNN comparison fair (same action head, only the state encoder differs)."
date_read:       2026-09-09
version_doi:     "arXiv:1506.03134 (v2, 2017-01-02), https://arxiv.org/abs/1506.03134; NIPS 2015 proceedings https://proceedings.neurips.cc/paper_files/paper/2015/hash/29921001f2f04bd3baee84a12e98098f-Abstract.html."
classification:  bibliography
purpose:         lit-review
```

## Notes

- Mechanism in one line: standard content-based attention u_j = v^T tanh(W1 e_j + W2 d) is used *as the output distribution itself* — p(action = j) = softmax_j(u_j) over the j input elements — rather than to blend a context vector. Output dictionary size = number of candidates in this particular input. This is precisely the shape of a Hive policy head: softmax over however many legal (piece, destination) moves the position has (from a handful in the opening to dozens midgame).
- Consequence for our design: the network never sees or wastes capacity on illegal/nonexistent actions. Contrast with the grid/CNN AlphaZero convention (fixed move planes + legality masking) — for Hive there is no natural fixed plane layout at all (no frame, unbounded coordinates), which is an argument we can make crisply by citing this paper: variable dictionaries need pointer-style scoring, and the grid arm gets the same decoder to keep the comparison clean.
- Their finding that pointer models generalize past training sizes (hulls, sorting) parallels Keller et al.'s GNN board-size transfer and GraphSAGE's inductiveness — the three works triangulate the same claim: candidate-indexed outputs + shared weights = size-extrapolation, which fixed-output CNN heads structurally lack.
- Limitation to inherit knowingly: scores are computed per candidate given a global query; interactions *between* candidate moves are only captured through the encoder, not the decoder. Fine for a small net; noted as a deliberate simplicity choice.
- For (piece, destination) pairs the direct analogue is scoring pair-embeddings, e.g., score = MLP([h_piece ; h_dest]) — a two-pointer factorization; AlphaStar (Vinyals et al. 2019) later used exactly pointer-network action heads over variable unit sets in StarCraft II, which we can cite in passing as the RL-scale validation of the mechanism.
- Peer-reviewed (NIPS 2015); supervised setting, so we cite it for the *decoder mechanism*, not for self-play evidence.
