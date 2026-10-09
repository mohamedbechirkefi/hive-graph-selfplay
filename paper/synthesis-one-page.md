# One-page synthesis — Grid vs. Graph Representations for Self-Play Learning in Hive

**Question.** Hive has no board: pieces define the surface, stack, and
move as (piece, destination) pairs over an ever-changing cell set. Does
a graph neural encoding — the structurally natural choice — beat the
standard grid/CNN encoding under AlphaZero-style self-play at a budget
one machine can afford?

**Design (all frozen before any comparison run).** One grid CNN (1.44M
parameters) vs one relational message-passing GNN (1.47M, +1.5%,
reported) sharing a rules-validated engine (perft vs published tables;
21/21 UHP conformance; 27,829-position differential agreement with two
reference engines; hand-annotated corpus committed before first run),
one action decoder, identical training; five seeds per arm, 10
generations × 500 self-play games at measured budgets (128/32
simulations, 300-ply cap); evaluation on 250 frozen openings against a
frozen population (random / fixed heuristic / 6400-sim MCTS) at pinned
settings; two budget readings — equal examples and equal wall-clock at
a pre-registered cutoff (T\* = 18.77 h); truncation a first-class
outcome everywhere; rejection rule pre-registered.

**Result: the hypothesis is rejected.** Graph − grid (seed-level means,
bootstrap 95% over seeds):

| | Same-examples | Same-wall-clock |
| --- | --- | --- |
| vs random | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| vs heuristic | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| vs MCTS | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

The graph arm also costs 2.0× the wall-clock, and its failure mode is
specific: it wins material against random and fails to convert,
truncating 20–57% of those games (grid: ~0–1%). The verdict is
cap-robust (scoring all truncations as graph wins leaves it negative)
and strengthened, not weakened, by the pre-committed extension from
three to five seeds.

**Ablations.** Removing the graph's direction-typed edge relations
destroys trainability outright (NaN at generation 0, every seed);
removing its global pooling changes nothing measurable. A clipped,
trainable naive-adjacency supplement (explicitly two-component) scores
within the full arm's band — the typed relations' measurable
contribution at this scale is optimization stability.

**Reading.** The result bounds, rather than contradicts, positive graph
findings in Hex (DQN) and chess (single-run self-play): where
short-range tactics decide games and budgets are small, the grid's
frame artifacts are cheaper than the graph's framelessness.

**Integrity.** Pre-registered rejection rule; frozen opponents,
openings, protocol; seed-level inference only; negative result reported
as designed; every number traceable to journals and regenerable from
raw per-game records; AI assistance under a gated human-as-PI
methodology, declared.

*Independent research report, v1.0-draft, 2026-10-09 — Mohamed Bechir
Kefi. Full booklet, code, and results manifest in the repository.*
