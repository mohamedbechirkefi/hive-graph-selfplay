# Training wall-clock per run (derived from wallclock.json)

Per-generation self-play generation + training seconds summed over the 10 generations of each run; evaluation games excluded. Hours.

| Arm | s11 | s12 | s13 | s14 | s15 | mean | sum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| grid | 17.46 | 17.95 | 17.63 | 17.46 | 18.52 | 17.80 | 89.0 |
| graph | 39.28 | 37.33 | 52.85 | 42.20 | 36.27 | 41.59 | 207.9 |

Ratio of means graph/grid: 2.34×; total over the ten runs: 296.9 h.
Population-score gap grid − graph: 0.006 (same-examples), 0.021 (same-wall-clock).
