# de Goede, Kampert & Varbanescu (2022) — The AZ-Hive Case-study

```yaml
citation:        Danilo de Goede, Duncan Kampert, Ana Lucia Varbanescu. "The Cost of Reinforcement Learning for Game Engines: The AZ-Hive Case-study."
venue_year:      ICPE 2022 (13th ACM/SPEC International Conference on Performance Engineering, Beijing), pp. 145-152
question:        What does it cost (compute, energy, design effort) to build an AlphaZero-style engine for a new game (Hive), and how strongly do game-encoding choices affect the resulting engine's strength?
game_task:       Hive (base game, via the BeeKeeper C engine compiled as a shared library, ctypes bridge to Python)
representation:  Hex grid mapped to a skewed-axis 26x26 2D array (padded; widest legal hive spans 22 tiles). Five board encodings compared — original (concatenated tile digits, handles beetle stacks), symmetric (top-view only, signed integers in [-5,5]), simple (type-abstracted), binary planes (10 planes, one per player per tile type), hybrid (queen planes + integer planes) — crossed with two action encodings (absolute coordinate vs tile-relative). All are array/grid encodings fed to a CNN; NO graph representation is considered.
search_method:   AlphaZero-style self-play — MCTS + neural network (4-layer CNN); board symmetries (6 rotations x reflection = 12x data augmentation) exploited
compute_budget:  4h training per configuration (5 repeats) for the encoding comparison; one 24h run for the tournament engine; energy measured at ~6.6e6 J (CPU+GPU) per typical 20-iteration training; full design-space exploration estimated at 20+ compute-years ("tens of training-years")
metrics:         Policy/value loss curves; win rate vs random agent (50 games per accepted model iteration, 5 repeats); BayesElo round-robin tournament (400 matches/engine, first-move advantage zeroed): Untrained 704, Random 778, Self-Play(4h) 919, Self-Play(24h) 1063, Classic MCTS 1181, Minimax 1355; Thinking Time per Move vs number of MCTS simulations
code_available:  partial (builds on BeeKeeper, https://github.com/Fjf/hive_engine; no explicit AZ-Hive release stated in the paper)
limits:          No AZ-Hive version reaches superhuman (or even minimax-beating) strength; encoding comparison capped at 4h/config so conclusions are about early learning speed; no principled way to prune the encoding design space; only CNN architectures considered — the "dynamic, board-less" nature of Hive is handled by forcing it into a fixed 26x26 array
difference_from_our_study:  We reproduce the AlphaZero-style self-play setup, the win-rate-vs-random and Elo evaluation protocol, and (as our grid baseline) essentially their skewed-axis hex-grid + CNN encoding (binary-planes/hybrid variants). We change the representation axis itself: we add a graph (GNN) encoding of the hive as a node/edge structure, which they never test, and we compare grid vs graph at matched training budget — directly answering the question their design space leaves open. Their budget numbers (4h/config, ~20 compute-years for full exploration) motivate our limited-compute framing.
relevance:       RQ-H1 (primary prior work: AlphaZero on Hive with explicit encoding comparison — but grid-only)
date_read:       2026-09-09
version_doi:     DOI 10.1145/3489525.3511685; open PDF at https://research.spec.org/icpe_proceedings/2022/proceedings/p145.pdf; BeeKeeper engine repo commit not pinned in paper
classification:  bibliography
purpose:         lit-review
```

## Notes
- This is the closest existing work to our study and the key novelty check for RQ-H1. It shows that **encoding choice dominates outcome quality** in AlphaZero-for-Hive: with tile-relative action encoding, the hybrid board representation clearly wins, while original/simple representations show *no* win-rate improvement at all within 4h. With absolute-coordinate actions, the original representation is best. That interaction between board and action encoding is exactly the kind of representational sensitivity our grid-vs-graph comparison targets.
- Crucially, every representation they consider is a fixed-size dense array over a skewed hex lattice (26x26, tile integers or binary planes); beetle stacking is handled by digit concatenation (original) or discarded (symmetric/simple/binary planes). **No graph/GNN representation appears anywhere in the paper**, and the sparsity/translation-drift problems of embedding a floating hive in a 26x26 array are not analyzed — they are our opening.
- Strength results are sobering: after 24h of self-play the engine (Elo 1063) still loses to plain MCTS (1181) and minimax (1355) from BeeKeeper. So the published state of the art for *learned* Hive policies is weak, and any consistent improvement from a better representation is a meaningful contribution.
- Useful protocol details to reuse: 50 eval games vs random per model iteration, 5 experiment repeats, BayesElo with first-move advantage set to 0, 12-fold symmetry augmentation, TTM budget argument (~15 s/move is human-comparable; fewer than ~1800 MCTS sims keeps AZ-Hive under that).
- Companion/origin work: Danilo de Goede, "Enhancing a Hive Playing Engine with Reinforcement Learning," BSc thesis, University of Amsterdam, July 2021 (cited as [6] in the paper) — same line of work; the ICPE paper is the citable archival version.
