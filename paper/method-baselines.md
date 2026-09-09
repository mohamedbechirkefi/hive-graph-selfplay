# Method — Baseline opponents and evaluation population (report section draft)

*Drafted 2026-09-09 at the H3 close (invariant 14). English working
master; French copy at the report milestone (D-006). Numbers trace to
journal `H3-2026-09-09-baselines-01`; claims registered in `claims.md`.*

## Why a frozen population

Both architectures are scored by mean result against a **fixed opponent
population frozen before any training run** (protocol §4): win = 1, draw
= 0.5, loss = 0, truncations excluded and reported as their own rate. A
population fixed in advance is what makes scores comparable across arms,
seeds and budgets; touching an opponent afterwards would silently move
the measuring stick, so the population is under freeze discipline — it
was frozen on 2026-09-09 with explicit approval (D-017: agent configs and
weight file by sha256, engine code commit) and no member may be added,
removed or retuned since. If an Elo-style number is ever quoted it is
descriptive and relative to this population only.

## The three agents

All three run on the validated engine (the same rules kernel as both
study arms) over UHP, fully seeded:

- **B-RND — legal-random.** Uniform over legal moves; deterministic given
  (seed, game history). The floor and score anchor.
- **B-HEU — documented heuristic.** Greedy one-ply argmax of a
  handcrafted evaluation (queen-safety dominant, mobility-as-material,
  small tempo terms — every feature and weight tabulated in
  `docs/baselines.md`), plus the searcher's quiescence on
  enemy-queen-targeting moves. The weights were inherited unchanged from
  the prior engine and are pinned by an automated test: no tuning
  occurred during H3 and any later change breaks the suite. This closes
  the tune-after-observing-results path by construction.
- **B-MCTS — search without network.** PUCT MCTS with uniform priors and
  the same handcrafted evaluation (tanh-squashed) as leaf value; no
  exploration noise at evaluation. Budget: 6400 simulations per decision
  — chosen from measured cost (≈27 ms/decision single-thread on the study
  machine), not from the plan's placeholder figures.

## Search verification before use

The MCTS baseline was verified on a hand-annotated tactical set written
from the publisher's rules (same discipline as the engine-validation
corpus, committed before any run): mate-in-1 by perimeter walk and by
grasshopper jump, from both colours, and an avoid-self-surround case —
5/5 at 400, 1600 and 6400 simulations. Value signs under player
alternation are pinned by automated tests at three levels: the evaluation
negates exactly when the side to move flips; alpha-beta scores a
mate-in-1 above the mate threshold for the mover, whichever colour moves;
the MCTS root value is strongly positive for the winning mover, whichever
colour moves.

## Characterisation

100 paired, colour-swapped games per pairing from common seeded random
openings, truncations reported separately (none occurred in 300 games):

| Pairing | W/D/L | Score | Elo (descriptive) |
| --- | --- | --- | --- |
| B-HEU vs B-RND | 100/0/0 | 100.0% | ≈+2400 |
| B-MCTS vs B-RND | 99/1/0 | 99.5% | +920 [+730, +1200] |
| B-MCTS vs B-HEU | 23/29/48 | 37.5% | −89 [−150, −32] |

One ordering surprised us and is reported as found: the 6400-sim search
sits *below* the one-ply heuristic. Diagnosis (supported by a 4×-budget
probe reaching 56.2%): with uniform priors, 6400 simulations spread over
Hive's ~60-move branching yield an effectively shallow search, while the
greedy agent's queen-targeting quiescence is tactically sharp — an echo
of the literature, where plain search and heuristics are strong in Hive
(de Goede et al. 2022; Kampert et al. 2021). No retuning followed the
observation; the population deliberately spans a floor plus two mid-band
opponents of different styles roughly 90 Elo apart.

## Limits

Characterisation volume is the pilot's 100 games per pairing with an
unpaired-approximation interval; the tactical set (5 cases) and its
annotations are unreviewed by an external Hive-literate reader — the same
declared limit as the engine-validation corpus.
