# Front matter (booklet v1, 2026-10-09)

**Title.** Grid vs. Graph Representations for Self-Play Learning in
Hive: a Pre-Registered Comparison under Limited Compute

*(Descriptive, no presumed result, per plan ch. 20.)*

**Author.** Mohamed Bechir Kefi

**Status.** Independent research report — not peer-reviewed, not a
publication of any institution. Version 1.0-draft, 2026-10-09.

**Code and artifacts.** Repository `hive-graph-selfplay` (release tag
and access to be fixed at diffusion time, G-PUBLIC); results manifest
under `results/`; every figure and table regenerates from scripts over
raw per-game records.

**AI assistance declaration.** This study was executed under a
human-as-PI methodology in which an AI research assistant (Claude,
Anthropic) implemented code, ran campaigns, and drafted text under a
gate system reserving all scientific decisions — freezes, budgets,
spending, publication — to the human author, who owns every claim.
Chapter 8 documents this working methodology in full; the source
document lives in the repository (`docs/methodology.md`).

**Abstract (164 words).** Hive is a boardless hexagonal strategy game
whose moves are (piece, destination) pairs over an ever-changing set of
cells — a natural candidate, in principle, for graph neural encodings
over the convolutional grid encodings standard in AlphaZero-style
systems. We test that intuition under a pre-registered protocol frozen
before any comparison run: one grid CNN and one capacity-matched
(+1.5%) relational message-passing network share a rules-validated
engine, one action decoder, identical training settings, a frozen
three-opponent population and 250 frozen openings, evaluated under two
budget readings (equal training examples; equal wall-clock at a
pre-registered cutoff) with five independent seeds per arm and
truncation reported as its own outcome. The hypothesis is rejected: the
graph arm scores lower against two of three opponents under both
readings, at twice the wall-clock cost, with its deficit concentrated
in converting won positions. Ablations show the graph arm's typed edge
relations are load-bearing for optimization stability, while its global
pooling is dispensable. Negative, pre-registered, and fully
reproducible from released records.

**Keywords.** Hive; AlphaZero; graph neural networks; representation
learning; pre-registration; negative result

**Table of contents.** 1 Introduction · 2 Formalisation · 3 Related
work · 4 Method (engine validation; baselines; pipeline;
representations) · 5 Protocol · 6 Results (comparison; ablations) ·
7 Discussion and threats · 8 Working methodology (gated human–AI) ·
9 Conclusion · Bibliography · Webographie · Annex A Position corpora ·
Annex B Architectures, decoder, formats · Annex C Hyperparameters,
seeds, commands · Annex D Repository pointers · Annex E Result tables
and figures (generated)
