# Study 2 (H9) results — same-wallclock reading

Score = mean over non-truncated games (win 1 / draw 0.5 / loss 0); trunc = truncation rate; sens = truncations scored 0.5.

| Arm | Seed | B-RND score / trunc | B-HEU score / trunc | B-MCTS score / trunc |
| --- | --- | --- | --- | --- |
| grid | s11 | 0.984 / 5% | 0.040 / 0% | 0.100 / 0% |
| grid | s12 | 0.984 / 5% | 0.060 / 0% | 0.110 / 0% |
| grid | s13 | 0.995 / 1% | 0.105 / 0% | 0.175 / 0% |
| grid | s14 | 0.990 / 2% | 0.120 / 0% | 0.260 / 0% |
| grid | s15 | 0.973 / 7% | 0.065 / 0% | 0.075 / 0% |
| graph | s11 | 0.995 / 1% | 0.110 / 0% | 0.160 / 0% |
| graph | s12 | 0.984 / 4% | 0.115 / 0% | 0.095 / 0% |
| graph | s13 | 0.762 / 58% | 0.140 / 0% | 0.140 / 0% |
| graph | s14 | 0.965 / 28% | 0.065 / 0% | 0.120 / 0% |
| graph | s15 | 0.958 / 40% | 0.025 / 0% | 0.080 / 0% |

## Seed-level means (bootstrap 95%, unit = seed)

- grid vs B-RND: mean 0.985 [0.979, 0.992] (seeds: 0.984, 0.984, 0.995, 0.990, 0.973)
- grid vs B-HEU: mean 0.078 [0.053, 0.105] (seeds: 0.040, 0.060, 0.105, 0.120, 0.065)
- grid vs B-MCTS: mean 0.144 [0.092, 0.206] (seeds: 0.100, 0.110, 0.175, 0.260, 0.075)
- graph vs B-RND: mean 0.933 [0.846, 0.986] (seeds: 0.995, 0.984, 0.762, 0.965, 0.958)
- graph vs B-HEU: mean 0.091 [0.056, 0.124] (seeds: 0.110, 0.115, 0.140, 0.065, 0.025)
- graph vs B-MCTS: mean 0.119 [0.094, 0.144] (seeds: 0.160, 0.095, 0.140, 0.120, 0.080)
