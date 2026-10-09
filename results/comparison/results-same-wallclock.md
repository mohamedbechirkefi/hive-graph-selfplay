# H6 results — same-wallclock reading

Score = mean over non-truncated games (win 1 / draw 0.5 / loss 0); trunc = truncation rate; sens = truncations scored 0.5.

| Arm | Seed | B-RND score / trunc | B-HEU score / trunc | B-MCTS score / trunc |
| --- | --- | --- | --- | --- |
| grid | s1 | 0.995 / 0% | 0.150 / 0% | 0.125 / 0% |
| grid | s2 | 0.975 / 1% | 0.080 / 0% | 0.125 / 0% |
| grid | s3 | 0.939 / 1% | 0.145 / 0% | 0.080 / 0% |
| grid | s4 | 0.949 / 11% | 0.105 / 0% | 0.085 / 0% |
| grid | s5 | 0.995 / 0% | 0.120 / 0% | 0.210 / 0% |
| graph | s1 | 0.798 / 58% | 0.045 / 0% | 0.075 / 0% |
| graph | s2 | 0.926 / 39% | 0.055 / 0% | 0.110 / 0% |
| graph | s3 | 0.713 / 53% | 0.060 / 0% | 0.105 / 0% |
| graph | s4 | 0.631 / 39% | 0.100 / 0% | 0.150 / 0% |
| graph | s5 | 0.980 / 24% | 0.045 / 0% | 0.095 / 0% |

## Seed-level means (bootstrap 95%, unit = seed)

- grid vs B-RND: mean 0.971 [0.950, 0.991] (seeds: 0.995, 0.975, 0.939, 0.949, 0.995)
- grid vs B-HEU: mean 0.120 [0.098, 0.142] (seeds: 0.150, 0.080, 0.145, 0.105, 0.120)
- grid vs B-MCTS: mean 0.125 [0.090, 0.168] (seeds: 0.125, 0.125, 0.080, 0.085, 0.210)
- graph vs B-RND: mean 0.810 [0.697, 0.922] (seeds: 0.798, 0.926, 0.713, 0.631, 0.980)
- graph vs B-HEU: mean 0.061 [0.047, 0.081] (seeds: 0.045, 0.055, 0.060, 0.100, 0.045)
- graph vs B-MCTS: mean 0.107 [0.087, 0.130] (seeds: 0.075, 0.110, 0.105, 0.150, 0.095)
