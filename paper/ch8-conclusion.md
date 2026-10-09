# Chapter 8 — Conclusion (booklet draft, 2026-10-09)

*No new results here, per the plan.*

Within the tested perimeter — base-game Hive, one capacity-matched
simple relational message-passing network against one grid CNN, ten
generations of small-budget self-play, five seeds per arm, a frozen
three-opponent population — **the answer to RQ-H1 is no**: the graph
representation did not learn a better policy than the grid
representation, under the same-examples reading or the same-wall-clock
reading, and the pre-registered rejection rule fired exactly as frozen.
The deficit is largest where Hive is most tactical, the graph arm pays
twice the wall-clock, and its failure mode — winning material without
converting — is visible precisely because truncation was never folded
into draws. The result does not contradict the positive graph findings
in Hex and chess; it bounds them: where short-range tactics decide games
and budgets are small, frame artifacts are cheaper than framelessness.

Two follow-ups are motivated by the data rather than by hope. First,
**the conversion pathology is a targetable defect**: the graph arm's
value head learns respectably while its policy fails at forcing
sequences, suggesting an experiment on search-time remedies (deeper
evaluation budgets in won positions, or auxiliary targets for forcing
moves) under the same frozen evaluation — a one-component change to the
shared pipeline, applicable to both arms. Second, **the stability
finding deserves isolation**: A1/A1′ showed direction-typed relations
matter mostly for optimization at this scale; a controlled study of
normalisation and gradient-scale choices for relation-shared graph
layers could decouple trainability from representational content — and
would say whether naive adjacency, properly stabilised, is genuinely
sufficient for Hive.

The broader method stands regardless of the sign of the result:
pre-registration with frozen artifacts, dual budget readings, truncation
as an outcome, seed-level inference, and write-as-you-go reporting
turned a negative answer into a usable scientific object on a single
laptop.
