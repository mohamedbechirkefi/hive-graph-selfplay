# Wu (2019/2020) — KataGo

```yaml
citation: >
  David J. Wu. "Accelerating Self-Play Learning in Go."
venue_year: >
  arXiv preprint (arXiv:1902.10565; v1 Feb 27, 2019, v5 Nov 9, 2020); presented at
  the AAAI-20 Workshop on Reinforcement Learning in Games (not a full peer-reviewed
  proceedings paper)
question: >
  How much can the compute cost of AlphaZero-style self-play learning be reduced
  through targeted training-pipeline and architecture improvements, at equal or
  better final strength?
game_task: Go (19x19 primarily; multiple board sizes and rulesets in one net)
representation: >
  Spatial CNN input: b x b x 18 binary feature planes (stones, liberties, ko
  legality, last 5 moves, ladders, pass-alive regions) plus a 10-value global
  feature vector (komi, rules, parity); residual CNN with global pooling in some
  blocks and in policy/value heads.
search_method: >
  MCTS (PUCT) self-play with playout cap randomization (full searches 600-1000
  visits on ~25% of turns, fast 100-200 visit searches otherwise) and forced
  playouts + policy target pruning at the root.
compute_budget: >
  Explicitly reported: fewer than 30 (avg ~26-27) V100 GPUs for 19 days
  (~1.4 GPU-years), 4.2M self-play games, ~241M training samples; claims ~50x
  efficiency gain vs ELF OpenGo (~74 GPU-years) at equal strength.
metrics: >
  Bayesian Elo from ~147k test games at 1600 visits/move vs a ladder of Leela Zero
  networks (LZ30-LZ225) and the final ELF OpenGo model; learning curves of Elo vs
  self-play cost; ablation runs for each technique.
code_available: "yes — https://github.com/lightvector/KataGo (code + trained models, actively maintained)"
limits: >
  Author notes infrastructure differences muddy exact efficiency comparisons with
  ELF/AlphaZero; some gains come from Go-specific input features (ladders,
  liberties) and auxiliary ownership/score targets that need redesign for other
  games; single main training run (ablations are shorter runs, no multi-seed CIs).
difference_from_our_study: >
  We borrow the compute-efficiency toolbox, not the scale: playout cap
  randomization and (optionally) an auxiliary opponent-move-prediction target are
  representation-agnostic and applied identically to BOTH arms so the CNN-vs-GNN
  comparison stays fair; we skip Go-specific features/targets. Unlike KataGo we
  hold architecture class as the experimental variable, use a fixed frozen
  opponent population instead of an external engine ladder, run multi-seed, and
  match budgets by examples and wall-clock. KataGo's Elo-vs-cost curves are the
  template for our budget-accounting plots.
relevance: >
  RQ-H1 — the key compute-efficiency reference: shows which pipeline knobs
  dominate cost at small scale, and sets the reporting standard (GPU-days,
  games, samples) our budget accounting follows.
date_read: 2026-09-09
version_doi: >
  arXiv:1902.10565v5, DOI 10.48550/arXiv.1902.10565.
  Code: github.com/lightvector/KataGo (our reference reading: v5 paper; cite a
  specific release tag if we import any technique implementation).
classification: bibliography
purpose: lit-review
```

## Notes

- Headline: ~50x cost reduction over comparable reproductions (ELF OpenGo, Leela Zero) — proof that AlphaZero-style pipelines have huge inefficiency headroom, which is what makes a limited-compute study feasible at all.
- Technique inventory (non-domain-specific, transferable to Hive, apply to both arms):
  - **Playout cap randomization**: value head needs many games, policy head needs deep searches; randomizing the visit cap per move (few full searches, many cheap ones) buys much more data per GPU-hour. Directly applicable to our self-play generator.
  - **Forced playouts + policy target pruning**: guarantees minimum exploration of low-prior root moves without polluting policy targets.
  - **Global pooling**: gives a CNN global context — note this partially compensates the CNN arm's locality; a GNN gets global context via message passing depth. Worth an explicit note in our architecture-fairness discussion.
  - **Auxiliary policy target** (predict opponent reply, 0.15x weight): cheap regularizer, representation-agnostic.
- Domain-specific parts we do NOT copy: ladder/liberty input features, ownership and score auxiliary targets (no Hive analogue of territory; a possible analogue — predicting piece mobility or queen-surrounding count — would be a separate ablation, out of scope for RQ-H1).
- Budget-reporting practice to copy: state hardware type and count, wall-clock, number of self-play games AND training samples; plot strength vs cumulative self-play cost, not vs iterations. This is the most complete budget accounting among the self-play papers reviewed.
- Evaluation caution relevant to us: KataGo evaluates against an external ladder (Leela Zero nets) — Hive has no such public ladder, hence our fixed frozen opponent population (shared across arms/seeds/budgets) as a substitute; KataGo's Bayesian Elo fitting over a game graph is still the right estimator.
