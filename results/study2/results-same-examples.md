# Study 2 (H9) results — same-examples reading

Score = mean over non-truncated games (win 1 / draw 0.5 / loss 0); trunc = truncation rate; sens = truncations scored 0.5.

| Arm | Seed | B-RND score / trunc | B-HEU score / trunc | B-MCTS score / trunc |
| --- | --- | --- | --- | --- |
| grid | s11 | 0.984 / 5% | 0.040 / 0% | 0.100 / 0% |
| grid | s12 | 0.984 / 4% | 0.055 / 0% | 0.075 / 0% |
| grid | s13 | 0.995 / 1% | 0.105 / 0% | 0.175 / 0% |
| grid | s14 | 0.990 / 2% | 0.120 / 0% | 0.260 / 0% |
| grid | s15 | 0.989 / 7% | 0.065 / 0% | 0.045 / 0% |
| graph | s11 | 1.000 / 0% | 0.125 / 0% | 0.245 / 0% |
| graph | s12 | 0.995 / 4% | 0.030 / 0% | 0.070 / 0% |
| graph | s13 | 0.940 / 42% | 0.080 / 0% | 0.145 / 0% |
| graph | s14 | 0.928 / 24% | 0.030 / 0% | 0.100 / 0% |
| graph | s15 | 0.992 / 41% | 0.105 / 0% | 0.110 / 0% |

## Seed-level means (bootstrap 95%, unit = seed)

- grid vs B-RND: mean 0.989 [0.985, 0.992] (seeds: 0.984, 0.984, 0.995, 0.990, 0.989)
- grid vs B-HEU: mean 0.077 [0.051, 0.104] (seeds: 0.040, 0.055, 0.105, 0.120, 0.065)
- grid vs B-MCTS: mean 0.131 [0.068, 0.200] (seeds: 0.100, 0.075, 0.175, 0.260, 0.045)
- graph vs B-RND: mean 0.971 [0.943, 0.996] (seeds: 1.000, 0.995, 0.940, 0.928, 0.992)
- graph vs B-HEU: mean 0.074 [0.040, 0.108] (seeds: 0.125, 0.030, 0.080, 0.030, 0.105)
- graph vs B-MCTS: mean 0.134 [0.090, 0.196] (seeds: 0.245, 0.070, 0.145, 0.100, 0.110)
