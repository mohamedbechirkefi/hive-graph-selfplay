# H6 results — same-examples reading

Score = mean over non-truncated games (win 1 / draw 0.5 / loss 0); trunc = truncation rate; sens = truncations scored 0.5.

| Arm | Seed | B-RND score / trunc | B-HEU score / trunc | B-MCTS score / trunc |
| --- | --- | --- | --- | --- |
| grid | s1 | 0.995 / 0% | 0.150 / 0% | 0.125 / 0% |
| grid | s2 | 0.975 / 1% | 0.080 / 0% | 0.125 / 0% |
| grid | s3 | 0.990 / 1% | 0.190 / 0% | 0.075 / 0% |
| grid | s4 | 0.949 / 11% | 0.105 / 0% | 0.085 / 0% |
| grid | s5 | 0.995 / 0% | 0.120 / 0% | 0.210 / 0% |
| graph | s1 | 0.733 / 57% | 0.025 / 0% | 0.115 / 0% |
| graph | s2 | 0.981 / 20% | 0.050 / 0% | 0.125 / 0% |
| graph | s3 | 0.722 / 55% | 0.090 / 0% | 0.100 / 0% |
| graph | s4 | 0.688 / 44% | 0.125 / 0% | 0.120 / 0% |
| graph | s5 | 0.935 / 23% | 0.035 / 0% | 0.115 / 0% |

## Seed-level means (bootstrap 95%, unit = seed)

- grid vs B-RND: mean 0.981 [0.964, 0.994] (seeds: 0.995, 0.975, 0.990, 0.949, 0.995)
- grid vs B-HEU: mean 0.129 [0.098, 0.165] (seeds: 0.150, 0.080, 0.190, 0.105, 0.120)
- grid vs B-MCTS: mean 0.124 [0.087, 0.168] (seeds: 0.125, 0.125, 0.075, 0.085, 0.210)
- graph vs B-RND: mean 0.812 [0.710, 0.920] (seeds: 0.733, 0.981, 0.722, 0.688, 0.935)
- graph vs B-HEU: mean 0.065 [0.034, 0.100] (seeds: 0.025, 0.050, 0.090, 0.125, 0.035)
- graph vs B-MCTS: mean 0.115 [0.107, 0.121] (seeds: 0.115, 0.125, 0.100, 0.120, 0.115)
