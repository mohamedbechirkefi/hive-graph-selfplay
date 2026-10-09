# Report v2 — specification for authors (internal; never shipped)

The final report "Grid vs. Graph Representations for Self-Play Learning in
Hive: a Pre-Registered Comparison under Limited Compute" is a standalone
academic research report (target ≈ 55–65 pages of body + ≈ 25 pages of
appendices, A4). English is the master; a full French copy follows, numbers
identical. Sources live in `paper/report/*.md` (EN) and `paper/report/fr/*.md`
(FR); `scripts/build_report.py` turns them into `paper/build/report-{en,fr}.pdf`
through pandoc → Typst.

## 1. Non-negotiable rules

1. **No internal plumbing in the body.** The body text never mentions file
   paths, script names, journal identifiers, decision identifiers (D-0xx),
   phase codes (H1–H8, T*, "task 4"), "plan ch. N", "invariant N", "booklet",
   "draft", "session", "runtime", or the names of AI tools — EXCEPT in Chapter
   10 (working methodology) where the gate system is the subject, and in
   Appendix E (provenance), where identifiers are the point. Say what was
   done, how, when and why, in plain academic prose: "the opponent population
   was frozen on 9 September 2026, before any training run", not "D-017".
2. **Every number is traceable.** Every numeric statement comes from one of
   the source files listed for the chapter (§5). After each paragraph that
   carries numbers, add an HTML comment `<!-- src: path[:line] -->` naming the
   source (comments are stripped at build time and used by the checker). No
   number may be computed, rounded differently, or "remembered".
3. **No invented facts.** If a source does not state it, the report does not
   state it. Prefer "not measured" to a guess. Never cite a work that is not
   in `paper/bibliography.md`.
4. **Negative and limiting statements are first-class.** Every result
   paragraph has four elements, in order: observation (what the table shows);
   magnitude with unit and uncertainty; interpretation within the tested
   perimeter; limit (what prevents a broader conclusion).
5. **Human-readable.** A reader who has never seen the repository must
   understand every table and figure from the caption alone. Captions state:
   what is compared, the opponent population, the budget, the number of
   independent runs, the uncertainty definition, and the unit.
6. **Honesty about provenance of the system.** The rules engine and the
   classical search predate the study (built July 2026 as an engine project);
   the prior 19-generation self-play loop is a demonstration, not evidence;
   the study-specific pipeline, both encoders, the graph network, the
   baselines, the protocol and all campaigns were built from September 2026.
   Say so, with dates.

7. **Prose style (author's instruction, 2026-10-09).** The text must read
   as written by a human researcher. No em dashes (—) anywhere in prose,
   captions, headings or table cells; use commas, parentheses, colons,
   semicolons or separate sentences, chosen for the sentence at hand. En
   dashes stay only in numeric and date ranges; the minus sign stays in
   numbers. Avoid the mannerisms of machine prose: "not X but Y"
   constructions, stacked triplets, rhetorical colons, openers such as
   "crucially", "notably", "importantly", "in other words", "it is worth
   noting", metaphors such as "load-bearing" repeated across a chapter,
   and bold run-in labels in result paragraphs (the four elements of a
   result paragraph are written as ordinary prose, in order). Verbatim
   quotations of frozen documents are reproduced exactly, whatever
   punctuation they contain.
8. **Recorded decisions (author's instruction, 2026-10-09).** The author's
   gate approvals are summarised in a formal register (what was decided,
   on what basis, under what conditions, with which identifiers
   recorded); their original wording is kept in the decision log only and
   never quoted in the body.

## 2. Markdown conventions (pandoc → Typst)

- One chapter per file; the chapter heading is `# Title {#sec:slug}`;
  sections `##`, subsections `###`; nothing deeper. Appendix files use
  `# Appendix A — Title {#sec:app-a}` (the build script switches numbering).
- Cross-references use raw Typst inline snippets:
  figure `` `@fig:slug`{=typst} ``, table `` `@tbl:slug`{=typst} ``,
  section `` `@sec:slug`{=typst} ``, equation `` `@eq:slug`{=typst} ``.
  They render as "Figure 3", "Table 2", "Section 4.1", "(5)". Never write
  "Figure 3" by hand.
- Figures: `![Caption text.](figures/name.png){#fig:slug width=90%}` on its
  own paragraph. Available figure files are listed in §4.
- Tables: pipe tables with a caption line right after the table:
  `Table: Caption text. {#tbl:slug}`. Right-align numeric columns with `---:`.
  At most 7 columns; split wide tables.
- Equations: display math `$$ ... $$` in LaTeX syntax, followed on the next
  line by `{#eq:slug}` when the equation is referenced. Inline math `$...$`.
- Citations: author–year in prose, e.g. "Silver et al. (2018)" or
  "(Wu, 2020; Jones, 2021)". The bibliography chapter lists entries.
- Footnotes `[^n]` sparingly. Block quotes `>` for verbatim quoted rules
  (the frozen rejection rule, gate approvals).
- No HTML, no raw Typst beyond the cross-reference snippets, no `\newpage`.
- Numbers exactly as in the sources: `0.995`, `28,673`, `18.77 h`, `−0.169`
  (Unicode minus in prose and tables), `[−0.272, −0.062]`. Percent vs
  percentage points are distinguished explicitly.

## 3. Terminology (EN master; FR equivalents fixed in the glossary appendix)

grid arm / graph arm; state encoding; shared action decoder; opponent
population (B-RND legal-random, B-HEU heuristic, B-MCTS search at 6,400
simulations); same-examples reading / same-wall-clock reading; equal-time
cutoff T\* (write "the equal-time cutoff"); generation; checkpoint;
seed (independent training run); truncation (never "draw"); frozen
(protocol, population, openings, evaluation settings); pre-registered
rejection rule; seed-level bootstrap interval; capacity-matched;
direction-typed relations; global-pooling bias; message passing;
playout-cap randomization; policy top-1; value accuracy.

## 4. Figures available (PNG under `paper/figures/`; regenerated by script)

| File | Content |
| --- | --- |
| fig1-score-vs-time.png | mean score vs training wall-clock, all seeds, both arms, T\* marked |
| fig3-encodings.png | one position: grid planes (left) vs cell graph with 6 typed relations (right) |
| fig4-failures.png | three commented failure positions F1–F3 |
| fig5-per-opponent.png | per-opponent score trajectories by generation, 5 seeds, min–max bands |
| fig6-training-metrics.png | epoch-1 policy top-1 and value accuracy by generation, 10 runs |
| fig7-truncation.png | final-evaluation truncation rate vs legal-random per run |
| fig8-pipeline.png | self-play → records → training → export → evaluation schematic |
| fig9-architectures.png | HiveNet and HiveGraphNet block diagrams side by side |
| fig10-timeline.png | project chronology (July–October 2026) |

## 5. Chapter plan, length targets, and sources

Common sources for every chapter: `paper/claims.md` (claim–evidence
register), `docs/protocol.md` (frozen protocol), `docs/baselines.md`,
`docs/representations/*.md`, `docs/action-decoder.md`, `docs/inventory.md`,
`docs/methodology.md` and `docs/methodology-log.md` (workspace `docs/`),
`state/decisions.md` (workspace), all `journal/*.md`, `results/**`,
`configs/**`, `paper/figures/*.md`, the existing verified chapters
`paper/*.md` (useful phrasing, already number-checked), and the 14 reading
notes `docs/reading/*.md` + `docs/reading/matrix.md`.

| File | Chapter | Pages | Primary sources |
| --- | --- | ---: | --- |
| 00-front.md | Abstract (EN) + Résumé (FR) + keywords + status and AI-assistance statement | 2 | paper/front-matter.md, docs/methodology.md |
| 01-introduction.md | Context; the representation problem; limits of closest works; RQ-H1/H2/H3 and H1; contributions; reading guide | 4 | paper/ch1-introduction.md, docs/protocol.md §1, matrix.md |
| 02-background.md | Hive rules and formalisation (state, actions, transition, outcome, truncation); why Hive is hard; AlphaZero-style self-play (PUCT, targets, loss); grid vs graph representations and message passing; budgets; evaluating agents (fixed populations, seeds, bootstrap) | 7 | paper/ch2-formalisation.md, docs/action-decoder.md, python/hivenet/{model,graph_model,train,train_graph}.py (equations as implemented), reading notes silver/wu/hamilton/agarwal |
| 03-related-work.md | By problem: Hive agents; network-guided search; game representations; graphs and symmetries; comparison under constrained compute; matrix table; positioning paragraph | 5 | paper/ch3-related-work.md, docs/reading/*.md, matrix.md |
| 04-chronology.md | How and when the system and the study were built: July 2026 engine project; August prior loop (demonstration); September research programme (dates of inventory, protocol freeze, population freeze, pipeline, encoders, campaigns, ablations, extension, analysis, report) with a timeline table and figure | 3 | docs/PLAN.md (engine plan + status addendum), docs/inventory.md, state/decisions.md, journal/*.md headers, git log dates |
| 05-engine.md | The engine built from scratch: design goals; architecture (rules kernel, protocol server, search, neural interface, MCTS, arena, self-play); board representation and hashing; move generation and rule edge cases; validation campaign (perft table, conformance, differential fuzzing, hand-annotated corpora, invariant sessions) with results tables; throughput profile | 7 | docs/PLAN.md, docs/inventory.md, paper/method-validation.md, journal 2026-09-09-*, tests/critical_positions/README.md, tests/tactical_positions/, crates/ (read-only for facts) |
| 06-pipeline.md | The learning pipeline: self-play workers and search settings; record format; training (loss, masking, truncation exclusion); export and inference; evaluation arena and paired openings; the seven automated checks; pilot results; pipeline figure | 6 | paper/method-pipeline.md, docs/action-decoder.md, journal 2026-09-10-h4-pilot.md, python/hivenet/*.py, scripts/run_h4_checks.sh |
| 07-representations.md | Grid encoding (frame, planes table); HiveNet; graph encoding (nodes, features, relations, globals); HiveGraphNet; shared decoder; capacity matching; measured cost asymmetries; golden tests; ablation variants; figures 3 and 9 | 7 | paper/method-representations.md, docs/representations/*.md, paper/annex-architectures.md, journal 2026-09-10-encoders-01, graph-wiring-01 |
| 08-baselines.md | The three opponents; heuristic features/weights table; characterisation results; tactical verification; freeze | 3 | docs/baselines.md, paper/method-baselines.md, journal 2026-09-09-baselines-01 |
| 09-experimental-methodology.md | Why pre-registration and frozen artifacts; the protocol: matrix, budgets, two readings, equal-time cutoff, seeds and pairing, statistics, rejection rule (quoted), exclusion criteria, truncation policy and sensitivity; what was fixed before vs. after (extension pre-commitments, A1′ supplement); resources consumed; question→experiment→result matrix | 6 | docs/protocol.md, paper/ch5-protocol.md, configs/comparison-matrix.yaml, configs/eval-settings.toml, state/decisions.md (D-026, D-027, D-030, D-031), journal 2026-09-16-h6-progress-01 |
| 10-working-methodology.md | Why a gated human–AI method; division of labour; the six gates with the approvals quoted; file-based state and invariants; incidents table (date, what, how caught, consequence); what the AI did not do | 4 | docs/methodology.md, docs/methodology-log.md, state/decisions.md, paper/ch-methodology.md |
| 11-results-main.md | RQ-H1: per-seed table both readings; seed means and intervals; arm contrast; figures 1, 5, 7; cap sensitivity; checkpoints at the cutoff; four-element paragraphs | 6 | results/comparison/*.md/csv, journal 2026-09-19-h6-comparison-01, 2026-10-09-h6-5seed-final-01, paper/results-comparison.md |
| 12-results-cost.md | RQ-H2: cost table; score vs time; per-example vs per-hour | 2 | paper/figures/fig2-score-cost.md, docs/representations/comparison-controls.md, wallclock figures in journals |
| 13-results-ablations.md | RQ-H3: H-T3 table; A1 divergence; A2 null; A1′ supplement; training metrics figure | 4 | results/ablations/README.md, journals 2026-09-23, 2026-10-02, 2026-10-09-h7-a1prime |
| 14-results-qualitative.md | Three failure positions with selection criteria; the conversion/truncation pathology; what the training curves show | 3 | paper/figures/fig4-failures.md, fig6/fig7, journal entries |
| 15-discussion.md | Reading the result; mechanisms (plausible vs demonstrated); comparison with Keller, Rigaux & Kashima, AZ-Hive; threats to validity (internal, measurement, statistical, external); lessons | 5 | paper/ch7-discussion.md, journals, matrix.md |
| 16-conclusion.md | Answer to RQ-H1 in perimeter; contributions; two motivated follow-ups | 1.5 | paper/ch8-conclusion.md |
| 17-bibliography.md | Bibliography (scientific) and Webography, academic style, alphabetical | 2 | paper/bibliography.md, docs/reading/*.md metadata |
| 90-appendix-a-corpus.md | Hive rules reference and the 35 annotated positions (generated) | 10 | tests/*/cases/*.toml via scripts/make_annex_corpus.py |
| 91-appendix-b-architectures.md | Layer-by-layer tables; record format; search settings | 4 | paper/annex-architectures.md, python/hivenet |
| 92-appendix-c-hyperparameters.md | Frozen constants; hyperparameters; seed derivation; configurations; machine profile | 3 | paper/annex-reproduction.md, configs/** |
| 93-appendix-d-statistics.md | Bootstrap procedure; raw per-seed tables including truncation and sensitivity columns; cutoff checkpoint map; ablation raw tables | 5 | results/**, scripts/make_results.py (procedure), journals |
| 94-appendix-e-provenance.md | Table/figure → artifact → journal entry; decision log index; claims–evidence register | 4 | paper/claims.md, journals, state/decisions.md |
| 95-appendix-f-glossary.md | Glossary EN/FR | 2 | this spec §3 |
| 96-appendix-g-reproduction.md | Fresh-environment reproduction scenario and commands | 2 | scripts/reproduce_minimal.sh, paper/annex-reproduction.md C.4 |

## 6. Verification before any chapter is accepted

1. `scripts/check_report_sources.py` — every numeric token in a chapter must
   appear in at least one of its cited sources (or the common sources);
   unmatched tokens are listed for manual review.
2. An adversarial read by a second agent: every factual sentence checked
   against the named sources; unsupported sentences removed or softened.
3. `scripts/check_fr_numbers.py --dir paper/report` after translation.
4. Build, page-render pass, final-control record.
