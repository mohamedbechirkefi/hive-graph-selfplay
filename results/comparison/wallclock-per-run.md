# Training wall-clock per run (derived from wallclock.json)

Per-generation self-play generation + training seconds summed over the 10 generations of each run; evaluation games excluded. Hours.

| Arm | s1 | s2 | s3 | s4 | s5 | mean | sum |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| grid | 18.77 | 16.73 | 19.07 | 18.23 | 17.19 | 18.00 | 90.0 |
| graph | 43.07 | 32.71 | 31.28 | 49.86 | 26.57 | 36.70 | 183.5 |

Ratio of means graph/grid: 2.04×; total over the ten runs: 273.5 h.
Population-score gap grid − graph: 0.081 (same-examples), 0.079 (same-wall-clock).

## Ablation runs (same accounting)

| Variant | s1 | s2 | s3 | mean |
| --- | ---: | ---: | ---: | ---: |
| A1 untyped | 7.75 | 8.01 | 7.61 | 7.79 |
| A2 no-gpool | 39.90 | 47.44 | 32.05 | 39.80 |
| A1' untyped+clip | 23.89 | 30.35 | 27.68 | 27.31 |
