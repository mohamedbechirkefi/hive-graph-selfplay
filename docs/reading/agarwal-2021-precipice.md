# Agarwal et al. (2021) — Statistical Precipice

```yaml
citation: >
  Rishabh Agarwal, Max Schwarzer, Pablo Samuel Castro, Aaron Courville,
  Marc G. Bellemare. "Deep Reinforcement Learning at the Edge of the
  Statistical Precipice."
venue_year: "NeurIPS 2021 (peer-reviewed; Outstanding Paper Award); arXiv:2108.13264"
question: >
  How should deep RL results be reported and compared when only a handful of
  training runs per method is affordable, so that conclusions are statistically
  reliable rather than artifacts of point estimates?
game_task: >
  Meta-evaluation across RL benchmarks: Atari 100k, ALE, Procgen, DeepMind
  Control Suite (re-analysis of published results, not a new agent).
representation: "n/a (evaluation methodology paper, no agent/state representation)"
search_method: "none (statistical analysis: stratified bootstrap, rank/aggregate statistics)"
compute_budget: >
  Not the object of study; explicitly targets the few-runs regime (3-10 seeds)
  typical of limited compute. Re-analysis itself is cheap.
metrics: >
  Proposes: interquartile mean (IQM) of normalized scores as the main aggregate
  (robust, more sample-efficient than median); stratified bootstrap confidence
  intervals over runs; performance profiles (score distributions across
  runs/tasks); probability of improvement P(X>Y); avoids point-estimate
  mean/median comparisons.
code_available: "yes — rliable library, https://github.com/google-research/rliable (docs: https://agarwl.github.io/rliable)"
limits: >
  Recommendations calibrated on multi-task benchmark suites; with a single task
  (one game) stratification collapses to bootstrap over seeds, so more seeds
  matter; IQM needs a handful of runs to be meaningful; does not solve
  evaluation-opponent choice for two-player games.
difference_from_our_study: >
  We adopt their protocol rather than reproduce their experiments: multi-seed
  training (both arms, same seed count), report IQM and stratified-bootstrap 95%
  CIs of our head-to-head metric (Elo / win-rate vs the fixed frozen opponent
  population), performance profiles across seeds, and probability of improvement
  GNN-over-CNN — instead of one-run Elo curves as in AlphaZero-style papers.
  Single game (Hive) instead of a task suite; our "tasks" axis is
  seeds x budget readings (same-examples, same-wall-clock).
relevance: >
  RQ-H1 — supplies the decision rule: "GNN learns a better policy" will be claimed
  only if the probability-of-improvement / IQM CIs support it at our seed count.
date_read: 2026-09-09
version_doi: >
  arXiv:2108.13264 (v1 Aug 30, 2021; v4 Jan 5, 2022), DOI 10.48550/arXiv.2108.13264;
  NeurIPS 2021 proceedings. Code: google-research/rliable (pip package rliable).
classification: bibliography
purpose: lit-review
```

## Notes

- Core empirical claim: on Atari 100k, conclusions from point estimates frequently reverse under proper interval analysis; published comparisons with 3-5 runs are often not supported by their own data.
- Concrete recommendations we implement:
  1. Report interval estimates everywhere (stratified bootstrap CIs), never bare means.
  2. Use IQM as primary aggregate; mean and median as secondary.
  3. Show performance profiles instead of tables of finals.
  4. Report P(GNN > CNN) with CI — this is exactly the RQ-H1 statistic.
  5. More runs per config beats more configs; they show uncertainty is badly underestimated below ~10 runs — with our budget we should push for 5+ seeds per arm at small scale rather than 3 at larger scale.
- Adaptation needed for two-player self-play: their normalized-score aggregation assumes per-task scalar scores. For us, the per-seed scalar is Elo (or mean win-rate) against the *fixed frozen opponent population* evaluated with enough games that per-seed measurement noise is small relative to across-seed variance; then bootstrap over seeds. Keep the opponent population identical across arms and budget readings, and never include an arm's own checkpoints in its evaluation pool (avoids self-play bias in the metric).
- Budget-reporting relevance: the few-run regime they target is precisely the limited-compute setting of our study; citing them justifies spending compute on seeds instead of on a single longer run.
