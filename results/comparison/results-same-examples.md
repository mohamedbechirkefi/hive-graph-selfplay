# H6 results — same-examples reading

Score = mean over non-truncated games (win 1 / draw 0.5 / loss 0); trunc = truncation rate; sens = truncations scored 0.5.

| Arm | Seed | B-RND score / trunc | B-HEU score / trunc | B-MCTS score / trunc |
| --- | --- | --- | --- | --- |
| grid | s1 | 0.995 / 0% | 0.150 / 0% | 0.125 / 0% |
| grid | s2 | 0.975 / 1% | 0.080 / 0% | 0.125 / 0% |
| grid | s3 | 0.990 / 1% | 0.190 / 0% | 0.075 / 0% |
| graph | s1 | 0.733 / 57% | 0.025 / 0% | 0.115 / 0% |
| graph | s2 | 0.981 / 20% | 0.050 / 0% | 0.125 / 0% |
| graph | s3 | 0.722 / 55% | 0.090 / 0% | 0.100 / 0% |

## Seed-level means (bootstrap 95%, unit = seed)

- grid vs B-RND: mean 0.987 [0.975, 0.995] (seeds: 0.995, 0.975, 0.990)
- grid vs B-HEU: mean 0.140 [0.080, 0.190] (seeds: 0.150, 0.080, 0.190)
- grid vs B-MCTS: mean 0.108 [0.075, 0.125] (seeds: 0.125, 0.125, 0.075)
- graph vs B-RND: mean 0.812 [0.722, 0.981] (seeds: 0.733, 0.981, 0.722)
- graph vs B-HEU: mean 0.055 [0.025, 0.090] (seeds: 0.025, 0.050, 0.090)
- graph vs B-MCTS: mean 0.113 [0.100, 0.125] (seeds: 0.115, 0.125, 0.100)
