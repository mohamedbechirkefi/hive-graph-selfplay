# Chapter 7 — Discussion and threats to validity (booklet draft, 2026-09-26)

*Four-way split per plan ch. 21. Grounded in the claims register; the
ablation paragraphs cite H7 artifacts and will absorb A2's final numbers
when its third seed lands.*

## 7.1 Reading the result

H1 was rejected exactly as the frozen protocol defined rejection. Three
observations give the result its texture. First, the deficit is
opponent-shaped: largest against legal-random, clear against the
heuristic, absent against the search-heavy B-MCTS — consistent with a
graph arm that is weakest at *local tactical conversion* rather than at
positional judgment. Second, the truncation channel carries the
mechanism: the graph arm wins material against random and then fails to
close (20–57% capped games; fig4-F1), a pattern invisible in studies
that fold caps into draws. Third, the ablations sharpen the reading:
removing geometric edge typing does not merely weaken the graph arm — at
parity settings it destroys trainability outright (NaN divergence,
generation 0, 3/3 seeds), so the typed relations carry at minimum the
optimization stability of the whole arm. This contrasts instructively
with the positive chess result of Rigaux & Kashima (2024, NeurIPS) and
Keller et al.'s (2023) Hex asymmetry: our result does not contradict
them — it bounds where their optimism transfers, and the comparison of
evidence standards matters: the chess result rests on a single training
run per model with intervals covering Elo estimation only, whereas the
present rejection is seed-consistent across three runs per arm under
two pre-registered budget readings. Hive's tactics are dominated by
short-range surround geometry, the regime Keller et al. found CNNs
stronger in; at small budgets that regime decides games.

## 7.2 Internal validity (bugs, comparability)

The engine is validated independently of learning (perft to depth 6+
against published tables, 21/21 UHP conformance, 27,829-position
differential agreement with two reference engines, a rules-derived
hand-annotated corpus, 10.9M-transition invariant sessions). Both
encoders are pinned byte-exactly against cross-language goldens run
nightly. Arms share the decoder, records, losses, budgets and search;
capacity differs by +2.1% (reported). Residual risks: the graph
architecture is ONE point in design space — a stronger GNN might behave
differently (we claim nothing beyond this net); tooling defects found
during the study (an arena record-loss path on all-truncated matches; a
silent NaN passage in ablation training) were caught by the
verification discipline, fixed, and audited to have left campaign data
untouched — but they illustrate that harness error, not chance, is the
dominant failure mode at this scale.

## 7.3 Measurement validity (opponents, truncation)

The population is three fixed opponents spanning floor-to-mid strength;
all trained arms still lose heavily to the two strong baselines, so the
comparison lives in a low-score regime where differences against
B-MCTS are hard to resolve. Scores are relative to THIS population —
no universal strength claim is made. Truncation is handled as its own
outcome with sensitivity bounds; the 300-ply cap itself cannot reverse
the verdict (truncations-as-wins bound stays negative), but the high
graph truncation rates mean its random-opponent score is measured on
fewer decided games (43–80 per seed).

## 7.4 Statistical validity (seeds, dependencies)

Three seeds per arm is the floor of honest multi-seed work; intervals
are correspondingly wide, and the B-MCTS contrast is indistinguishable
from zero. The rejection does not rest on a single interval: it rests
on seed-consistency across two opponents and two readings
simultaneously, plus bounds analysis. Openings are shared across arms
(pairing respected in the design); the arm contrast bootstraps seeds,
not games; no game-level pseudo-replication enters any interval. A
5-seed extension (matrix option) would narrow intervals and remains
open; it could not overturn seed-consistent deficits of this size in
the other direction without extraordinary draws.

## 7.5 External validity (variant, hardware, budget)

One variant (base Hive), one machine, one small budget (10 generations
× 500 games; ~18–48 h/run), early-regime self-play throughout. The
provider asymmetry (CoreML favours the convolutional net; the
gather-heavy GNN runs fastest on CPU) is a genuine property of the
deployment hardware, reported and charged — on different accelerators
the wall-clock reading could shift. Nothing here generalises to other
games, larger budgets, or richer graph architectures; the study answers
its pre-registered question inside its pre-registered perimeter, and
the negative answer is the product: encoding choice matters (as AZ-Hive
found), and for Hive at small budget it favours the grid.
