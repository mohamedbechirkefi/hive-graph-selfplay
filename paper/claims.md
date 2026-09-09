# Claims register — Hive report (plan ch. 28; invariant 12)

**Rule: no row, no claim.** Every claim in the report has a row here; a
claim without evidence is removed or reworded. Numbers must match raw
results across abstract, figures, and conclusion before diffusion.

| Claim | Evidence (journal id / result table) | Report section | Limit |
| --- | --- | --- | --- |
| The rules engine reproduces Mzinga's published perft tables for all 8 game types to depth 6 (depth ≤5 in the standard suite, depth 7 in nightly runs). | journal `H2-2026-09-09-suite-rerun-01` | Method / engine validation | depth-bounded node-count equality; d7 re-run not repeated on 2026-09-09 (d≤6 confirmed) |
| The engine passes the UHP conformance harness of the nokamute reference (21/21). | journal `H2-2026-09-09-suite-rerun-01` | Method / engine validation | conformance = protocol behaviour, not full rules proof |
| Per-ply legal-move sets are identical to both reference engines (MzingaEngine v0.16.0, nokamute 1.0.3) over seeded random games (27,829 positions at seed 20260909; 200/100 games/type in nightly). | journal `H2-2026-09-09-suite-rerun-01` | Method / engine validation | agreement with references, not with the rulesheet directly; random-walk coverage |
| The engine agrees with a 30-case corpus of hand-annotated critical positions whose expectations were derived from the publisher's rules and committed before any engine run (30/30 after one setup-side correction). | journal `H2-2026-09-09-corpus-run-01`; `tests/critical_positions/` | Method / engine validation | corpus annotations not yet externally reviewed (declared limit); 30 cases at the low end of the 30–50 proposal |
| Seeded random-game sessions across all 8 game types show zero invariant violations over 10.9M applied transitions (apply-accepts-generated, one-hive connectivity, GameString round-trip, forced pass). | journal `H2-2026-09-09-random-invariants-01` | Method / engine validation | pseudo-random breadth, not adversarial depth; serialisation via UHP GameString only |
| The Rust and Python plane encoders agree exactly (240 positions, byte-identical planes). | journal `H2-2026-09-09-suite-rerun-01` | Method / data pipeline | grid-arm encoder only; GNN-arm encoder does not exist yet |
| A UHP subprocess round-trip costs ~22 µs — negligible against measured per-decision costs — so the Python↔Rust binding uses subprocess/UHP (no PyO3). | journal `H2-2026-09-09-throughput-profile-01`; D-010 | Method / infrastructure | one machine (M1 Pro); revisit if Python ever enters a per-move loop |
| At the measured inference costs (2.62 ms/eval CoreML, 23.5 ms CPU, gen-19 net as workload), 128/32 sims with playout-cap randomization and a 300-ply cap are feasible budget/cap choices for this study's compute envelope. | journal `H2-2026-09-09-throughput-profile-01`; D-011 | Protocol / budget | proposals pending pilot + G-FREEZE; CoreML EP currently broken in the Rust pipeline; costs are net-specific |
