# Working methodology: gated human–AI research {#sec:working-method}

This chapter describes how the study was conducted, as a collaboration between one human researcher and an AI assistant under written operating rules that reserve every irreversible or scientific decision to the human, and why that arrangement was chosen. It is the expanded form of the AI-assistance statement in the front matter; the identifiers behind every statement made here are listed in `@sec:app-e`{=typst}.

## Why a gated method

The study was carried out by a single researcher with limited time and a single laptop (Apple M1 Pro, 10 cores, 16 GB) as its only compute. An AI coding assistant multiplies throughput under those constraints but introduces a specific hazard: generated text and code fail *plausibly*, in that they look right at exactly the places nobody checks, and an assistant has no persistent memory worth trusting between working sessions. A study produced this way can accumulate fluent but untraceable claims. The response was to make research quality a property of **process artifacts** rather than of memory or trust: a journal entry for every measurement, frozen documents identified by cryptographic hash, a register pairing every claim with its evidence and its limit, and an append-only decision log in which a reversed decision is never edited but superseded by an entry that links back. Working sessions are stateless; each rebuilds its understanding from these files, so a crashed session loses nothing.
<!-- src: /Users/bechir/research/docs/methodology.md:45-61,120-128 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/annex-reproduction.md:70 -->

Three further choices follow. The assistant is routed by *goals*: the plan defines end states, each phase is an executable document with ordered tasks, acceptance checks and exit criteria, and the assistant optimises for "the phase's evidence exists" rather than "the requested edit was made". The irreversible categories of action are enumerated as **gates** and reserved for the human, keeping the assistant's autonomy where mistakes are cheap and reversible. And commitments precede the observations that could bias them (annotations before engine output, behavioural pins before code changes, measurements before budgets), while the assistant's substantial outputs, the operating documents included, pass through verification passes prompted to *refute* them. Report sections are written while the work happens, because a report assembled afterwards turns memory into narrative.
<!-- src: /Users/bechir/research/docs/methodology.md:102-132 -->

## Division of labour

**The human is the principal investigator.** He owns the research questions, every scientific commitment (protocol, population and opening freezes), every expenditure of compute, everything that leaves the machine, and the final word on every claim. The scientific responsibility for this report is his alone and cannot be delegated.
<!-- src: /Users/bechir/research/docs/methodology.md:27-31 -->

**The AI assistant executes the plan.** The assistant is Claude (Anthropic), operating as Claude Code sessions. Given the plan and the state files, it plans, implements, tests, measures, journals and drafts toward the plan's end state; sessions start from an intent ("continue", or a phase name) rather than from a task list. It implemented the encoders, the graph network, the training pipeline, the baselines and the evaluation harness inside the perimeter each phase document fixes; pinned existing behaviour before changing it; profiled before proposing budgets and piloted before campaigns; journaled every experiment with hypothesis, commit, configuration, seeds, data version, hardware, duration, cost, metrics, failures and interpretation; and drafted the report as it went. Its own decisions are logged with the same discipline, and several are explicit *proposals* that became binding only through the author's approval at a gate; the proposal to exclude the prior demonstration checkpoint from the opponent population is one example.
<!-- src: /Users/bechir/research/docs/methodology.md:33-37,63-83 -->
<!-- src: /Users/bechir/research/state/decisions.md:459-490 -->

What the assistant never decides is listed in the operating rules: it never crosses a gate (no freezing, spending, publishing, contacting or destroying without a recorded human decision); never writes an oracle after seeing model output, because that contamination is irreversible; never produces an untraceable number; never touches a frozen artifact, since any post-freeze change is by definition a new study; and never makes a claim without a row in the claims register.
<!-- src: /Users/bechir/research/docs/methodology.md:85-100 -->

## The six gates

The boundary is drawn mechanically rather than left to judgement. **G-FREEZE**: freezing a protocol, split or test set, and any later touch of a frozen artifact. **G-SPEND**: paid calls, purchases, budget caps, starting or restarting long compute jobs. **G-PUBLIC**: anything leaving the machine (pushes, licence choices, publication). **G-RIGHTS**: reuse of material whose ownership is not established. **G-ADMIN**: institutional contact. **G-DESTRUCTIVE**: deleting data, models or results, overwriting raw results, killing running jobs. At a gate the assistant records the pending request, parks that phase and routes to other work; a phase document saying "do X" is never authorisation to cross. `@tbl:gates`{=typst} lists every gate decision the author took and summarises the basis of each; the decision log holds the author's approvals in their original wording.
<!-- src: /Users/bechir/research/CLAUDE.md (operating rules, Gates) -->
<!-- src: /Users/bechir/research/docs/methodology.md:39-43 -->

| Date | Gate | Decision | Basis and conditions recorded |
| --- | --- | --- | --- |
| 2026-09-09 | G-PUBLIC | Licence chosen (MIT, copyright 2026); remotes created, kept **private** until the research is finished | Decided on the author's written instruction; the remotes to become public only through a further decision at this gate, once the research is finished |
| 2026-09-09 | G-SPEND / G-DESTRUCTIVE | Prior self-play loop permanently stopped; never restarted | Decided on the author's written instruction; the loop's checkpoint preserved in the research copy; no restart permitted without a new decision |
| 2026-09-09 | G-FREEZE (review) | Protocol freeze deferred until the pilots had re-measured the proposed budgets with the study's own networks | Decided on a draft carrying measured values labelled as proposals; the freeze scheduled after the pilots so that it would consume confirmed values rather than proposals |
| 2026-09-09 | G-FREEZE | Opponent population frozen: legal-random, heuristic, search at 6,400 simulations; prior checkpoint excluded; hashes and engine commit recorded | Approved after the characterisation round-robin; the search opponent fixed at 6,400 simulations; the prior checkpoint excluded; configuration and weight hashes and the engine commit recorded |
| 2026-09-10 | G-FREEZE | Protocol frozen as version 1.0, hash and commit recorded, no placeholders | Approved on the pilot's measured values; protocol hash and commit recorded; no placeholder left |
| 2026-09-10 | G-DESTRUCTIVE | Pre-study workspace archive deleted by the author directly; the research copy became the sole copy of the prior work | Carried out by the author himself; the research copy declared the sole copy of the prior work, its pre-study files placed under the destructive-action gate |
| 2026-09-10 | G-FREEZE | 250 shared 4-ply openings frozen, generated blind from a documented seed | Approved on a file generated blind with nothing tunable; content and file hashes and the generator seed recorded |
| 2026-09-10 | G-SPEND | Main campaign: 2 arms × 3 seeds, 10 generations × 500 games, ≈4.6 days estimated | Approved at the full sizing among the options presented from measured per-game costs; runs sequential and resumable; raw results never overwritten |
| 2026-09-20 | G-SPEND | Ablation campaign: A1 and A2, 3 seeds each at full parity, ≈9 days estimated | Approved at full three-seed parity with the main comparison, among the sizings presented from measured graph-arm run costs |
| 2026-09-26 | G-SPEND | Supplementary two-component A1′ run at a corrected ≈4-day sizing | Approved at a corrected sizing of about four days, after the initial estimate had been revised; queued after the extension; its results confined to a labelled two-component supplement |
| 2026-09-26 | G-SPEND | Main comparison extended to 5 seeds per arm, ≈4.8 days, under three pre-commitments stated before any new run | Approved with three written pre-commitments (all-seeds analysis, cutoff unchanged, two-stage collection disclosed); seeds added symmetrically to both arms under identical settings |

Table: Gate decisions taken by the author during the study, in the order recorded in the decision log. G-RIGHTS and G-ADMIN were not crossed; nothing has left the machine, so G-PUBLIC remains open for diffusion. {#tbl:gates}
<!-- src: /Users/bechir/research/state/decisions.md:95-156,316-343,492-527,598-633,729-753,755-785,787-820,888-915,917-935,938-959 -->

Two entries deserve more comment than the table gives. The deferral of 9 September shows a gate working against haste: offered a protocol with measured values, the author waited for pilot confirmation so that the freeze would consume confirmed numbers rather than proposals. The 5-seed extension shows a post-hoc power decision kept from becoming a tuning channel: before any new run it was recorded that (a) the final analysis would use all five seeds per arm regardless of the new seeds' direction, (b) the equal-time cutoff would stay at the value computed on 16 September, never recomputed after seeing results, and (c) the report would disclose that seeds 4–5 were collected after the 3-seed analysis. The results chapters honour all three. The scope of this report was itself an authorial decision, recorded on 9 October 2026 with the constraint that no frozen artifact, number or claim could change.
<!-- src: /Users/bechir/research/state/decisions.md:316-343,938-959,961-983 -->

## Scientific principles enforced in every phase

Beyond the gates, the operating rules bind every phase regardless of who executes it.

1. **Oracles before model output.** Test positions and benchmark cases are annotated before any engine or model sees them; afterwards an unbiased expectation can no longer be written.
2. **Characterise before changing.** Existing behaviour is pinned with tests before modification; a failing pin is recorded as a finding rather than fixed silently.
3. **Everything is journaled**: identifier, date, hypothesis, commit, configuration, seed, data version, hardware, duration, cost, metrics, artifact paths, failures, interpretation.
4. **No untraceable numbers.** Every figure links to a journal entry or raw result; numbers inherited from the plan are labelled planning proposals until measured.
5. **Negative results are kept** and reported alongside the best runs.
6. **Fair baselines.** Compared methods receive the same model, budget and attempt count; a strawman baseline invalidates a study.
7. **Truncation is not a draw.** A game stopped at the move cap is a separate outcome, reported separately and sensitivity-tested.
8. **Multi-seed honesty.** No conclusion rests on one seed; per-seed results and uncertainty are reported, with the seed as the unit of resampling.
9. **Prior work is read-only.** Pre-study material is never edited in place; imports carry a provenance note; unclear rights go to G-RIGHTS.
10. **A claims register.** Every claim has a row (claim, evidence, section, limit) or it does not appear.
11. **Write as you go.** A phase is not closed until its report section exists: protocol before experiments, method during implementation, results only from frozen raw tables.

<!-- src: /Users/bechir/research/CLAUDE.md (operating rules, Scientific invariants) -->

## What the discipline caught

The operating rules require an append-only log of every incident in which the method caught something, missed something, changed an outcome through a gate, or cost real overhead; entries are never forced. `@tbl:incidents`{=typst} assembles those entries with incidents recorded in the experiment journals.

| Date | Incident | How it was caught | Consequence |
| --- | --- | --- | --- |
| 2026-09-09 | First draft of the phase documents held 33 defects, including a validation↔freeze deadlock and two unexecutable tasks | refutation-prompted verification pass | 28 fixes, re-verified clean before any research ran |
| 2026-09-09 | A hand-annotated critical position disagreed with the engine | expectations committed before the run | resolved *against* the corpus (One-Hive transit case); record kept |
| 2026-09-09 | Prior self-play generators mapped the 300-ply cap to a draw | truncation principle applied retroactively at review | fixed before the pipeline phase; truncation a separate outcome everywhere |
| 2026-09-09 | Python–Rust boundary about to become a preference debate | measurement first: 21.7 µs per round-trip against ≥40 ms per decision | no in-process binding built |
| 2026-09-09 | Setup slip (piece ordering) in the tactical test set | five cases hand-annotated and committed before being run | engine right, setup wrong; journaled |
| 2026-09-09 | Search opponent scored only 37.5% against the heuristic; a 4× budget probe reached 56.2% | diagnosed at characterisation | deliberately **not** retuned: the population freeze forbids post-hoc tuning |
| 2026-09-09 | Two concurrent working sessions allocated the same decision identifier (**missed** at the time) | later cross-check | entry renumbered; single-writer rule for shared state files |
| 2026-09-09 | Overhead: the operating documents consumed a full working session (≈1M agent tokens, 17 subagents) before any research work | none | front-loaded fixed cost, accepted |
| 2026-09-10 | First pilot evaluation returned identical 0/2/28 against all three opponents, legal-random included | identical-results alarm; diagnosis order rules → signs → search → data | a shell loop had passed each opponent's flags as one argument: every match was against the heuristic; rerun |
| 2026-09-18 | Reproducing an all-truncated pair for a failure figure returned no records | every selected position must be reproduced and verified against its record | latent record-loss path fixed; audit: no campaign evaluation affected |
| 2026-09-23 | All three A1 ablation seeds returned game-count-identical evaluations | the same identical-results alarm | training had diverged to NaN at generation 0 and self-played on NaN for nine more generations; non-finite guards added; divergence kept as the finding |
| 2026-10-09 | Regenerated equal-time checkpoint map for seeds 1–3 differed from the journaled original | regenerated outputs checked against the journal before use | a rounded cutoff constant had broken an inclusive boundary; fixed, original reproduced exactly |
| 2026-10-09 | Generated arm-contrast caption still read "3 per arm" under 5-seed numbers | page-by-page render pass | generator derives the seed count and rewrites the file whole; every number byte-identical |
| 2026-10-09 | Stale seed counts in two chapters; stale "pending" limits in the claims register | placeholder sweep before assembly | fixed in both languages together |
| 2026-10-09 | Cost-table generator divided five runs' wall-clock by 3 (printing 30.0 h / 61.2 h for 18.0 h / 36.7 h) and carried a training-throughput row (≈770 / ≈195 pos/s) measured under pilot conditions but presented as campaign throughput | every number re-derived from its raw source with an explicit definition while writing this report | generator fixed (journaled benchmark 274 / 138 pos/s at batch 128, conditions stated); no score, interval or claim affected; per-paragraph source citations and a token-level traceability checker now gate the report |
| 2026-10-09 | The capacity difference "+2.1%" quoted in every document was the ratio of the rounded parameter counts (1.47/1.44 M); the exact counts give +1.5% | layer-by-layer tabulation of the architectures recounted the parameters from the code | corrected everywhere except the append-only journals; exact counts now a generated results artifact; no verdict depends on it |

Table: Incidents recorded by the methodology log and the experiment journals during the study: what happened, which rule or check caught it, and what followed. {#tbl:incidents}
<!-- src: /Users/bechir/research/docs/methodology-log.md:13-111 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-09-10-h4-pilot.md:70-81 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/journal/2026-10-09-h6-5seed-final-01.md:22-29,48-52 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/ch-methodology.md:57-65 -->

None of these catches required insight; each came from a mechanical check. One alarm (independent conditions cannot agree to the game count) found a harness defect in the pilot and a silent numerical divergence in an ablation; one rule (commit the expectation, then run) found an annotation error and a setup error on the same day; the reproduce-and-verify step behind a figure found a record-loss path before the equal-time evaluations (where early graph checkpoints genuinely can truncate every game) would have tripped it. Two entries are *gate effects*: the population freeze visibly prevented a results-flattering retuning of the search opponent, and measure-before-commit dissolved an architecture argument with one number. At this scale, harness error was a larger threat than statistical noise, and only mechanical verification found it; the claims register carries this as a process observation from one study, whose stated limit is that no counterfactual exists for what an ungated workflow would have caught.
<!-- src: /Users/bechir/research/docs/methodology-log.md:31-46,60-79 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/claims.md:36 -->

The cost side is recorded with the same honesty: the method's fixed cost was front-loaded, and the "missed" entry shows the first failure mode of multi-session operation: shared state files need write discipline as well as read discipline. The method did not prevent errors in drafts; it surfaced them before this version through translation passes, numeric identity checks between the two language versions, page renders and adversarial re-reads. A check comparing two languages cannot, however, see a staleness shared by both. The last incident sharpened the standard: a number present in a file is not thereby provenanced; the file must itself derive it from raw data under a stated definition, which is why every paragraph of this report carries a source citation that is checked mechanically.
<!-- src: /Users/bechir/research/docs/methodology-log.md:47-58,81-111 -->

## What the assistant did not do, and the author's responsibility

The assistant chose no hypothesis, froze nothing, spent nothing, published nothing, deleted nothing, and decided no claim; it wrote no test expectation after seeing engine output and did not recompute the equal-time cutoff after results were known. The limits of the arrangement are recorded too: the assistant can misread the plan, and the phase documents are its interpretation (the decision log records where reality corrected them); adversarial self-verification remains self-verification at the level of the programme, so the external human review of a subset of annotations and of the report, foreseen in the plan, is not replaced by it; and the assistant's training data may overlap the public Hive literature, so no claim of the form "unseen by the model" is made anywhere in this report.
<!-- src: /Users/bechir/research/docs/methodology.md:144-157 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/ch-methodology.md:57-65 -->

**AI-assistance declaration.** Implementation, experiment execution, journaling and drafting for this study were carried out with substantial assistance from an AI coding agent (Claude Code, Anthropic), operating under the gated methodology described in this chapter. Every scientific decision, every frozen commitment and every expenditure was made by the author at a gate, as recorded in `@tbl:gates`{=typst}; every claim was made or verified by the author, who has personally checked the conclusions he signs and takes full responsibility for the results. The exact wording of this declaration will follow the rules of any venue at diffusion time.
<!-- src: /Users/bechir/research/docs/methodology.md:134-142 -->
<!-- src: /Users/bechir/research/hive-graph-selfplay/paper/front-matter.md:18-24 -->
