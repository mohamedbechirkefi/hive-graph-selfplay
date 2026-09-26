# Literature matrix — RQ-H1 (plan ch. 3)

Generated from the reading notes in this directory (one row per
`purpose: lit-review` note; full details, quotes and verified metadata live in
the per-work notes). Date: 2026-09-09; extended 2026-09-26. 14 works.

| Work (note) | Question | Game/task | Representation | Search | Budget | Metrics | Code | Limits (for us) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Silver et al. 2017/18, AlphaZero ([note](silver-2017-alphazero.md)) | One general self-play RL algorithm across games? | Chess, shogi, Go | Stacked board planes → residual CNN (the canonical grid baseline) | PUCT-MCTS, 800 sims/move | 5000 TPUs; hardware-denominated, not normalized | Elo vs reference engines, single run | no | Single run, loose budget accounting; plane encoding game-specific |
| Wu 2020, KataGo ([note](wu-2020-katago.md)) | How far can self-play cost be cut? | Go | CNN planes + global features/pooling | PUCT-MCTS, playout-cap randomization | ~1.4 GPU-years; explicit games/samples; ~50× vs ELF | Bayesian Elo vs LZ/ELF ladder; per-technique ablations | yes | Some gains Go-specific; single main run |
| Jones 2021, Scaling board games ([note](jones-2021-scaling.md)) | Do small AlphaZero runs extrapolate? | Hex 3×3–9×9 | Fully-connected resnets (no CNN/GNN comparison) | AlphaZero-style MCTS | ~500 GPU-hours total; FLOPs/GPU-h/samples sweeps | Elo anchored to perfect play; compute frontiers | yes | Hex-only simplicity; FC nets only |
| Agarwal et al. 2021, Precipice ([note](agarwal-2021-precipice.md)) | Reliable conclusions from few runs? | RL benchmark meta-analysis | n/a | none | targets 3–10-seed regime | IQM, stratified bootstrap CIs, performance profiles, P(X>Y) | yes (rliable) | Calibrated on task suites; single-game use = bootstrap over seeds |
| Hamilton et al. 2017, GraphSAGE ([note](hamilton-2017-graphsage.md)) | Inductive node embeddings for unseen nodes/graphs? | Citation/Reddit/PPI graphs (not games) | Sampled-neighborhood aggregation, learned aggregators | none | not systematic | Micro-F1 inductive classification | yes | No edge attributes in vanilla form; shallow K |
| Vinyals et al. 2015, Pointer Networks ([note](vinyals-2015-pointer-networks.md)) | Distribution over variable-size candidate sets? | Convex hull/Delaunay/TSP (not games) | Encoder states as candidate reprs; attention as pointer | none (supervised) | not reported | Structure accuracy / tour quality | no | Sequence encoder for sets; supervised only |
| van der Pol et al. 2020, MDP homomorphic ([note](vanderpol-2020-mdp-homomorphic.md)) | Does built-in state–action equivariance speed RL? | CartPole/grid/Pong | Equivariant MLP/CNN over joint state–action group | none (model-free RL) | learning curves at equal env steps | Sample efficiency vs same-size baselines | yes | Needs known, small, exact symmetry group |
| de Goede et al. 2022, AZ-Hive ([note](degoede-2022-azhive.md)) | Cost of AlphaZero for a new game (Hive); encoding sensitivity | **Hive (base)** | 5 grid/array hex-lattice encodings × 2 action encodings — all CNN, **no graph** | AlphaZero-style MCTS | 4 h/config × 5 repeats; 24 h tournament engine; energy in J | Loss curves; win vs random; BayesElo round-robin | partial | Never beats plain MCTS/minimax; 4 h caps ⇒ early-learning-speed conclusions only |
| Kampert et al. 2021, Mimicking Hive ([note](kampert-2021-mimicking-hive.md)) | Competitive Hive agent from search + human heuristics? | **Hive (base)** | Hand-crafted heuristic features (BeeKeeper engine) | Minimax (αβ+TT), MCTS variants | one DAS-5 node; 0.01–1 s/move | Win rate vs random; turns-to-win; Elo round-robin | partial | No neural nets; agents below human level |
| Keller et al. 2023, GraphDQN/GraphAra ([note](keller-2023-graphdqn-hex.md)) | Direct CNN-vs-GNN comparison in Hex | Hex 8×8–25×25 (Shannon-game graph) | GNN (15×SAGEConv, ~487K params) vs Gao-ResNet & U-Net (~481K) | RainbowDQN for the comparison; AlphaZero-style (800 sims) for GNN only | ~110 A100-hours/model (comparison); 3×A100 ~6 days (GraphAra) | Long-range test suite; size transfer; supervised acc; vs MoHex | yes | Comparison is DQN, not self-play, and CNN arm never ran under MCTS; graph formulation Hex-specific; preprint |
| Cazenave et al. 2020, Polygames ([note](cazenave-2020-polygames.md)) | Boardsize-invariant zero learning across games | Hex/Havannah/Othello/… (**not** Hive) | Fully-conv nets + global pooling (grid paradigm) | AlphaZero-style MCTS | not comparable per-run units | Competition results; beat strong humans 19×19 Hex | yes (archived) | Handles scaled grids, not boardless/dynamic topologies |
| Rigaux & Kashima 2024, AlphaGateau ([note](rigaux-2024-chess-graph-rl.md)) | Does a graph representation help AlphaZero-style chess RL? | Chess | Edge-featured GAT (GATEAU), edge-based policy readout | AlphaZero-style MCTS | 8×A5000 ≈13.7 d (+fine-tune) | Jeffreys-prior Elo, delta-method CIs | yes | **Single run per model, no seeds**; loose capacity match (1.0M vs 2.2M); representation+decoder confounded |
| Ben-Assayag & El-Yaniv 2021 ([note](benassayag-2021-scalable-alphazero.md)) | Train small, play large with GNN-AlphaZero | Othello/Gomoku/Go | 3-GIN lattice graph + global dummy node, node policy | AlphaZero-style MCTS | 1×TITAN X; deliberately asymmetric (3 d vs 30 d) | Win rate vs AZ baselines, 5 runs + SE | no (promised, absent) | Transfer claim, not equal-budget representation comparison |
| Pfeifer 2018–2025, hiveGo ([note](pfeifer-2025-hivego.md)) | Hobby Hive AI (webographie) | **Hive** | Hand-crafted features → FNN; a "tiny GNN" | Alpha-beta; AlphaZero-style loop | not reported | Anecdotal only | yes (commit d6ff954) | No controlled comparison of any kind |

## Novelty positioning (protocol §10 cites this section)

**What exists.** (a) AlphaZero on Hive exists: AZ-Hive (de Goede et al. 2022)
compared five board encodings — all dense grid/CNN; no graph arm; the trained
engines stayed below plain MCTS/minimax. (b) A parameter-matched CNN-vs-GNN
comparison on a hex-grid game exists: Keller et al. 2023 on Hex — but under
RainbowDQN (the CNN arm never trained under MCTS self-play), with a
Hex-specific Shannon-game graph, and per-node actions. (c) A GNN-vs-CNN
AlphaZero-style result exists for chess: Rigaux & Kashima 2024 —
**NeurIPS 2024** (dedicated note; single training run per model, no
seed replication — noted for the discussion). (d) An unpublished hobby project trains a small GNN
on Hive with an AlphaZero loop (janpfeifer/hiveGo, GitHub; webographie item)
— no CNN comparison, no controlled budget, no systematic evaluation.

**Consequently the study does NOT claim** "first grid-vs-graph comparison in
a board game". The scoped contribution: the first **controlled, budget-matched
(same-examples AND same-wall-clock), multi-seed grid-vs-graph comparison for
Hive** — a frameless, stacking game where actions are (piece, destination)
pairs and the graph must carry empty candidate destinations — with **both**
arms trained under the same AlphaZero-style pipeline. AZ-Hive's finding that
encoding choice strongly affects learning is direct motivation for RQ-H1;
Keller et al.'s Hex results (GNN wins long-range/transfer, CNN wins local
patterns) plus Rigaux & Kashima's positive chess result make H1 plausible but
genuinely open for Hive's locally-tactical play. No pivot to
reproduce-then-extend is triggered (decision D-009).

**Follow-ups:** all closed 2026-09-26 (Rigaux & Kashima, hiveGo and
Ben-Assayag notes added; AZ-Hive full text was read by the original agent
from the SPEC PDF — no graph encoding present).
