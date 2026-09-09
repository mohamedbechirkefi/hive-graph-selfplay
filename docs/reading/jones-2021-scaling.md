# Jones (2021) — Scaling Scaling Laws with Board Games

```yaml
citation: >
  Andy L. Jones. "Scaling Scaling Laws with Board Games."
venue_year: "arXiv preprint 2021 (arXiv:2104.03113; v1 Apr 7, 2021, v2 Apr 15, 2021; not peer-reviewed)"
question: >
  Can the outcomes of large AlphaZero-style experiments be extrapolated from many
  small, cheap ones — scaling not only model size but problem size — and how do
  train-time and test-time compute trade off at fixed performance?
game_task: >
  Hex (hexagonal connection game) at board sizes 3x3 through 9x9 (9x9 = largest
  MoHex can play perfectly), trained with an AlphaZero-style pipeline.
representation: >
  Fully-connected residual networks over the board state (not CNNs); sizes swept
  from 1 layer x 1 neuron up to 8 layers x 1024 neurons, per board size.
search_method: "MCTS self-play, AlphaZero-style"
compute_budget: >
  Explicitly measured and swept: reported in FLOPs-seconds, GPU-hours, and
  samples; total ~500 GPU-hours on RTX 2080 Ti class hardware across the whole
  sweep — a deliberately small-lab budget.
metrics: >
  Elo anchored to perfect play (MoHex) fixed at 0 Elo; round-robin tournaments of
  1024 games per pairing among agent snapshots; "compute frontiers" (best Elo
  attainable vs compute).
code_available: "yes — https://andyljones.com/boardlaw/ (boardlaw: code, models, and data on GitHub, github.com/andyljones/boardlaw)"
limits: >
  Author explicitly unsure the clean scaling behavior generalizes beyond Hex's
  very simple ruleset; fully-connected nets only (no CNN/GNN architecture
  comparison); perfect-play anchor only exists for small boards; single pipeline,
  hyperparameters shared across scales.
difference_from_our_study: >
  Closest methodological neighbor: small-compute AlphaZero on a hexagonal-grid
  game with rigorous budget accounting. We differ in: game (Hive — boardless,
  stacking, piece-movement rules far richer than Hex's placement-only), the
  experimental variable (representation/architecture CNN-grid vs GNN, which Jones
  never varies), evaluation anchor (no perfect player exists for Hive, so we use
  a fixed frozen opponent population instead of a MoHex-style 0-Elo anchor),
  and multi-seed statistics per Agarwal et al. We copy: compute-frontier plots,
  reporting budget in both samples and wall-clock/FLOPs, round-robin Elo
  tournaments among snapshots.
relevance: >
  RQ-H1 — justifies that small-compute self-play experiments yield meaningful,
  extrapolatable signal, and supplies the budget-accounting template (frontiers,
  dual denominations) for our two budget readings.
date_read: 2026-09-09
version_doi: >
  arXiv:2104.03113v2, DOI 10.48550/arXiv.2104.03113.
  Code/data: boardlaw project (andyljones.com/boardlaw, github.com/andyljones/boardlaw).
classification: bibliography
purpose: lit-review
```

## Notes

- Chosen as the 4th cluster work over ELF OpenGo and OLIVAW because: (a) full text and code are openly consultable; (b) it is the only one designed *for* the small-compute regime rather than being a scaled-down reproduction, and its budget accounting (FLOPs-seconds + GPU-hours + samples, compute frontiers) is exactly what our two-reading budget protocol needs; (c) it studies a hexagonal board game.
- Key quantitative findings worth citing:
  - ~500 Elo per order of magnitude of training compute (within a board size), predictable across board sizes.
  - Train/test compute tradeoff: ~10x more training compute can replace ~15x test-time (search) compute at constant strength — implies our evaluation must fix MCTS visit counts identically across arms, or the comparison confounds representation quality with search budget.
  - Minimum compute for perfect play grows ~7x per board-size increment — problem size is a compute axis; supports our choice of base-Hive-only (no expansions) as budget control.
- Important distinction for our related-work section: Hex is played ON a hexagonal grid but is a fixed-board placement game, so fully-connected/CNN encodings are natural. Hive's hexagonal adjacency emerges from piece placement (unbounded, sparse, stackable) — the case for a graph representation is structurally stronger. Jones provides no grid-vs-graph evidence; no pivot triggered.
- What a small-compute study should copy from Jones: sweep small and extrapolate rather than one big run; publish frontier curves rather than single endpoints; anchor Elo to something reproducible (for us: the frozen opponent population, versioned and released with the code); release models + game records so others can re-anchor.
