# Silver et al. (2017/2018) — AlphaZero

```yaml
citation: >
  David Silver, Thomas Hubert, Julian Schrittwieser, Ioannis Antonoglou, Matthew Lai,
  Arthur Guez, Marc Lanctot, Laurent Sifre, Dharshan Kumaran, Thore Graepel,
  Timothy Lillicrap, Karen Simonyan, Demis Hassabis.
  "Mastering Chess and Shogi by Self-Play with a General Reinforcement Learning Algorithm."
  Also published as: "A general reinforcement learning algorithm that masters chess,
  shogi, and Go through self-play," Science 362(6419):1140-1144, 2018.
venue_year: >
  arXiv preprint 2017 (arXiv:1712.01815, v1 Dec 5, 2017);
  peer-reviewed version in Science 2018 (vol. 362, issue 6419, pp. 1140-1144)
question: >
  Can a single, general self-play RL algorithm (deep net + MCTS, no human game data,
  no domain-specific heuristics beyond the rules) reach superhuman strength across
  structurally different board games?
game_task: Chess, shogi, Go (superhuman play vs Stockfish, Elmo, AlphaGo Zero)
representation: >
  Stacked spatial binary/scalar planes over the fixed rectangular board grid, with
  8-step move history: chess 8x8x119 planes (piece positions, repetitions, castling,
  move/no-progress counters), shogi 362 planes (incl. prisoner counts), Go 17 planes.
  Policy also expressed as spatial planes (e.g. 8x8x73 move encoding for chess).
  This is the canonical "grid/CNN" baseline representation.
search_method: >
  MCTS with PUCT guided by a policy/value residual CNN; 800 simulations per move
  during self-play; Dirichlet noise at the root (alpha scaled per game).
compute_budget: >
  5,000 first-generation TPUs for self-play generation + 64 second-generation TPUs
  for training; 700k mini-batch steps (batch 4096); ~9h (chess), 12h (shogi),
  34h (Go) wall-clock; 44M/24M/21M self-play games respectively. Budget stated in
  hardware terms, not FLOPs; no cost-normalized comparison across architectures.
metrics: >
  Elo via Bayesian logistic regression (c=1/400) from tournament matches at
  1 min/move vs Stockfish (chess), Elmo (shogi), AlphaGo Zero (Go); learning curves
  of Elo vs training steps.
code_available: no (closed source; many third-party reproductions exist)
limits: >
  Enormous, loosely-accounted compute; single training run per game (no seed
  variance reported); evaluation vs specific engine versions/configs (later
  criticized); draws compress Elo scale in chess; grid-plane representation is
  game-specific despite the "general" algorithm claim.
difference_from_our_study: >
  We keep the algorithmic core identical (policy+value net, PUCT-MCTS self-play,
  same loss form) but apply it to Hive (base variant, hexagonal, boardless/expanding
  layout). Our grid/CNN arm is the direct analogue of AlphaZero's plane
  representation (hex grid embedded in a fixed array); the GNN arm replaces the
  representation only. Unlike AlphaZero we: run at tiny compute, use multi-seed
  runs, evaluate vs a fixed frozen opponent population rather than a single
  reference engine, and account budget two ways (same training examples AND same
  wall-clock).
relevance: >
  RQ-H1 — defines the baseline algorithm and the grid/CNN representation we compare
  against; its evaluation style (single run, hardware-denominated budget) is what
  our statistical/budget protocol deliberately improves on.
date_read: 2026-09-09
version_doi: >
  arXiv:1712.01815v1, DOI 10.48550/arXiv.1712.01815;
  Science version DOI 10.1126/science.aar6404. No official code release.
classification: bibliography
purpose: lit-review
```

## Notes

- Cite both versions: the arXiv preprint (2017) is the commonly-cited "AlphaZero paper"; the Science 2018 paper is the peer-reviewed record (adds full pseudocode and revised, fairer Stockfish/Elmo match conditions). Use Science as the primary citation in the report, arXiv for details only in the preprint.
- Key claims: tabula-rasa self-play generalizes across chess/shogi/Go; exceeded Stockfish after ~4h (chess) of its pipeline's wall-clock; searches ~80k positions/s vs Stockfish's ~70M — the net concentrates search.
- Representation detail that motivates RQ-H1: everything is forced through fixed-size rectangular planes, including move encodings. Hive has no fixed board — pieces stack, the layout is an unbounded hex tessellation, and the natural adjacency structure is a graph. The grid embedding for Hive (what AZ-Hive did, see Goede et al. 2022) requires an arbitrary bounding box and wastes capacity on empty cells; a GNN consumes adjacency directly. AlphaZero itself offers no evidence on which is better — it never varies representation while holding budget fixed.
- Budget reporting practice to avoid copying: hardware counts (TPUs) and wall-clock only, generation and training hardware disjoint and unaccounted jointly; no seeds, no CIs. Our protocol: identical data pipeline for both arms, budget matched on (a) number of training examples/self-play moves and (b) wall-clock on identical hardware, ≥3 seeds, CIs per Agarwal et al. 2021.
- What we copy exactly: PUCT formula and root Dirichlet noise (scale alpha to Hive's typical branching factor, as they scaled per game: 0.3 chess / 0.15 shogi / 0.03 Go), 800-sim self-play as an upper anchor (we will use far fewer, cf. KataGo playout-cap ideas), joint policy+value loss.
