# Kampert et al. (2021) — Mimicking the Human Approach in the Game of Hive

```yaml
citation:        Duncan Kampert, Ana-Lucia Varbanescu, Matthias Müller-Brockhausen, Aske Plaat. "Mimicking the Human Approach in the Game of Hive." (preprint circulated as "Better AI for Hive: Mimicking human game-play strategies")
venue_year:      IEEE SSCI 2021 (IEEE Symposium Series on Computational Intelligence, Orlando, Dec 2021)
question:        Can state-of-the-art search methods (heuristic minimax, MCTS) plus human domain knowledge produce a competitive Hive agent, and which playing-strength metrics are meaningful for Hive?
game_task:       Hive (base game; BeeKeeper C engine for state tracking and move generation)
representation:  Engine-internal board state (BeeKeeper); hand-crafted heuristic feature vector (tiles-around-queen, unused tiles, movement/blocking value with per-tile weights, later a tile-to-queen distance term), weights tuned with Optuna (100 trials); no neural network, no learned representation
search_method:   Minimax (alpha-beta, transposition table) and MCTS (UCB1 c in {1.4, 100}, random playout guidance, first-move urgency), 0.01-1 s/move
compute_budget:  Experiments on one DAS-5 node (dual 8-core Intel Haswell E5-2630-v3, 64 GB RAM); Elo tournaments ~15h scale for 10 versions; per-move time budgets of 0.01-1 s
metrics:         Win rate vs random agent plus average turns-to-win (e.g. True MCTS 0.7/60.3, UCB1 c=1.4 0.8/57.5, Minimax 0.66/47.0 at 1 s/move); Elo (initialized 1500) round-robin across agent variants; Optuna win-factor for heuristic-weight tuning
code_available:  partial (BeeKeeper engine: https://github.com/Fjf/hive_engine; paper's agents not released separately)
limits:          Agents still lose to human players; tiles-around-queen turns out to be a poor evaluation signal (Optuna assigns it low weight), undermining the MCTS enhancements built on it; playouts are expensive (~400k nodes/s late game, branching factor ~60) so MCTS gets few samples; win-rate-vs-random saturates and cannot separate decent agents
difference_from_our_study:  We keep their evaluation insights (Elo over win-rate-vs-random; turns-to-win as a secondary signal) and their game-complexity numbers (branching factor ~60, ~2x chess). We replace hand-crafted heuristics + classical search entirely with learned policy/value networks under self-play, and we study representation (grid vs graph) rather than heuristic engineering. Their observation that no cheap, reliable hand-crafted state property exists for Hive is direct motivation for learning the evaluation — and their closing suggestion to insert a lightweight neural network is what AZ-Hive and our study take up.
relevance:       RQ-H1 (baseline strength of non-learned Hive agents; evaluation methodology; evidence that hand-crafted Hive heuristics are weak)
date_read:       2026-09-09
version_doi:     IEEE Xplore document 9659999 (https://ieeexplore.ieee.org/document/9659999/); preprint PDF: https://liacs.leidenuniv.nl/~plaata1/papers/IEEE_Conference_Hive_D__Kampert.pdf; dblp: conf/ssci/KampertVMP21
classification:  bibliography
purpose:         lit-review
```

## Notes
- Documents the "dire state" of Hive AI pre-AlphaZero-style learning: earlier attempts (Konz 2012 MCTS ~80% vs random; Blixt & Ye 2013 RL; Bunth 2019 deep RL; McGuile 2020 St Andrews MSc) barely beat random play. Useful related-work map for the report's Hive-AI paragraph — Hive AI is indeed mostly thesis-level work.
- Key numbers to cite: average branching factor stabilizes around 60 (vs ~30 for chess); a highly optimized engine generates only ~400k nodes/s late-game, so depth-4 full minimax ≈ 32 s — search alone does not scale, evaluation quality is the bottleneck.
- Their most robust empirical finding: the intuitive "count tiles around the enemy queen" heuristic is actively misleading as a dominant term (Optuna reruns show high queen-weight correlates with *lower* win factor), while a tile-to-queen distance "convergence" term helps. Any learned network we train can be probed against this: does the GNN rediscover distance-to-queen structure?
- Elo methodology caveats they raise (rock-paper-scissors between strategies, cost of round-robins, side-symmetry checks) apply directly to our evaluation design.
- No neural network, no learned representation, no self-play — this paper cannot preempt RQ-H1; it defines the classical-search baseline our learned agents must beat (their minimax is the strongest agent in the AZ-Hive 2022 tournament too, Elo 1355).
