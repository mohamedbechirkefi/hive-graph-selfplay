# Results — The controlled comparison (report section draft)

*Drafted 2026-09-19 at the H6 close (invariant 14). English working
master; French copy at the report milestone (D-006). Every number traces
to journals `H6-2026-09-19-comparison-01` (3-seed analysis) and
`H6-2026-10-09-5seed-final-01` (final 5-seed analysis) and regenerates from
`scripts/make_results.py` / `make_figures.py` over the raw per-game
records; claims registered in `claims.md`.*

## The pre-registered question and its answer

The protocol (frozen at v1.0 before any comparison run) asked: at
comparable training budget, does the graph architecture learn a better
policy than the grid architecture for base-game Hive? It fixed, in
advance, what would reject the hypothesis: no seed-consistent graph
advantage under both budget readings, with intervals excluding a
meaningful graph advantage.

**That is what happened. H1 is rejected.** Under the same-examples
reading (both arms, 10 generations × 500 games) and the same-wall-clock
reading (T\* = 18.77 h, computed by a pre-registered rule before any
cross-arm number existed), the graph arm scored lower against two of the
three frozen opponents and no better against the third, across **five
seeds per arm** (seeds 4–5 were added after the three-seed analysis,
symmetrically and under a pre-commitment to use all seeds regardless of
direction, D-031; the three-seed analysis reached the same verdict):

| graph − grid | Same-examples | Same-wall-clock |
| --- | --- | --- |
| vs legal-random | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| vs heuristic | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| vs 6400-sim MCTS | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

(Seed-level means; bootstrap 95% over five seeds per arm; per-seed
values in the results tables — no best-seed reporting anywhere. The
largest upper bound across all six contrasts is +0.028.)

The wall-clock reading compounds the result: the graph arm's measured
cost was 2.0× per run (35.7 vs 18.2 h), so at equal hours it completes
only 4–5 of 10 generations — a deficit the per-example reading already
shows and equal time only widens.

## Truncation, reported separately and stress-tested

The clearest behavioural difference is not a score but an outcome
category: against legal-random, the graph arm truncated 20–57% of its games at
the 300-ply cap across the original seeds and 23–44% in the extension
seeds (grid: 0–1%, with one extension seed at 11%) — winning material and then
failing to convert (fig. 4, F1). Because truncation was defined as its
own outcome from the start, this pathology is visible rather than
laundered into draws. The cap value cannot rescue the hypothesis: even
scoring every truncated game as a graph win — an upper bound on any
larger cap — leaves the graph arm behind on the random opponent under
both readings (−0.072 / −0.058).

## What this does and does not show

It shows: for a capacity-matched (+2.1%), simple relational
message-passing network sharing every other component with the grid arm
— rules, search, decoder, records, training conventions, frozen
opponents, frozen openings, pinned evaluation — grid-plane encoding
learned more per example AND per hour at this small budget, and the
graph arm's weakness concentrates in local tactical conversion,
matching the local-vs-long-range asymmetry reported for Hex under DQN
(Keller et al. 2023) now observed under matched AlphaZero-style
self-play in a frameless, stacking game.

It does not show: anything about graph representations at larger
budgets, other graph architectures, or other games; nor that the arms
would not reorder with more generations (10 is early-regime; all scores
against the strong baselines remain low). Five seeds per arm bound the
statistics; the rejection is seed-consistent, and the extension seeds
(added under pre-commitment) tightened four of the six intervals.

## Costs (both denominations, per plan ch. 6)

Fig. 2: parameters 1.44M vs 1.47M; best-provider inference 2.62 ms
(CoreML) vs 3.67 ms (CPU); self-play 13.1 vs 25.7 s/game; population
score 0.412 vs 0.327 (same-examples), 0.402 vs 0.321 (same-wall-clock).

## Provenance

Population frozen 2026-09-09 (D-017); protocol frozen 2026-09-10
(D-020); openings frozen 2026-09-10 (D-025) — all before any comparison
run. Campaign approved and launched 2026-09-10 (D-026); T\* computed
2026-09-16 from grid wall-clocks only; no opponent, opening, or protocol
touch occurred at any point. Negative result retained and reported per
invariant 5 and protocol §1: the work does not need H1 confirmed to
count.

## The ablations (H-T3)

Two single-component ablations against the graph full method, three
seeds each at full budget parity, plus one labeled supplement. Removing
the direction-typed edge relations (A1, naive adjacency) destroyed
trainability outright — NaN divergence in generation 0 for every seed —
so typed edges carry, at minimum, the arm's optimization stability.
Removing the global-pooling bias (A2) produced a null: score changes of
−0.001 [−0.170, +0.165], −0.007 [−0.043, +0.030] and −0.013 [−0.043,
+0.013] against the three opponents, with the failure modes unchanged.
The supplementary A1′ (untyped edges plus gradient clipping — an
explicitly two-component variant, never attributed to typing alone)
trains stably and scores within the full arm's band against all three
opponents, suggesting the typed relations' measurable contribution at
this scale is concentrated in optimization stability rather than final
strength — a statement that inherits the clip confound and is phrased
accordingly wherever it appears.

