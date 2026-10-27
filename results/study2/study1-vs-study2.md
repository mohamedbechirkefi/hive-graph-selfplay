# Study 1 vs Study 2 (descriptive, no pooling)

Seed-level mean score per arm and graph-grid contrast with bootstrap 95% over seeds, per reading and opponent. Study 1: seeds 1-5, fresh initialisation per generation (protocol v1.0). Study 2: seeds 11-15, warm start + replay window (protocol v2).

## same-examples

| Opponent | Study | grid mean | graph mean | graph-grid [95% CI] |
| --- | --- | --- | --- | --- |
| B-RND | 1 | 0.981 | 0.812 | -0.169 [-0.272, -0.062] |
| B-HEU | 1 | 0.129 | 0.065 | -0.064 [-0.111, -0.017] |
| B-MCTS | 1 | 0.124 | 0.115 | -0.009 [-0.055, +0.028] |
| B-RND | 2 | 0.988 | 0.971 | -0.018 [-0.045, +0.008] |
| B-HEU | 2 | 0.077 | 0.074 | -0.003 [-0.046, +0.039] |
| B-MCTS | 2 | 0.131 | 0.134 | +0.003 [-0.082, +0.090] |

## same-wallclock

| Opponent | Study | grid mean | graph mean | graph-grid [95% CI] |
| --- | --- | --- | --- | --- |
| B-RND | 1 | 0.971 | 0.810 | -0.161 [-0.278, -0.048] |
| B-HEU | 1 | 0.120 | 0.061 | -0.059 [-0.087, -0.029] |
| B-MCTS | 1 | 0.125 | 0.107 | -0.018 [-0.066, +0.025] |
| B-RND | 2 | 0.985 | 0.933 | -0.052 [-0.140, +0.002] |
| B-HEU | 2 | 0.078 | 0.091 | +0.013 [-0.032, +0.055] |
| B-MCTS | 2 | 0.144 | 0.119 | -0.025 [-0.091, +0.034] |
