```yaml
id:            H8-2026-10-09-reference-report-01
date:          2026-10-09
hypothesis:    Report-format measurement, not an experiment. The human
               asked for a final report that explains what/how/when/why
               of the whole study as a standalone academic monograph (EN
               + FR), with no references to internal files in the body
               (D-033). Question: can every number of such a report be
               re-derived from the evidence base with an explicit
               definition — and does the re-derivation hold?
git_commit:    sources at 6f352da + this session's commit
config:        paper/report/SPEC.md (rules); scripts/build_report.py
               (pandoc 3.6.3 -> Typst 0.15 via the typst wheel)
seeds:         n/a
data_version:  results/comparison/, results/ablations/, data/runs/* (read
               only through the generated artifacts)
hardware:      M1 Pro (rendering only)
duration:      one session; 9 drafting agents, 1 figure agent, 9
               translation agents in parallel
cost:          0
```

## Methods

A new source tree `paper/report/` (25 EN chapter/appendix files; FR
copies under `paper/report/fr/`) written against SPEC.md: no file
paths, scripts, journal/decision identifiers or phase codes in the body
(allowed only in the provenance appendix and the reproduction guide);
every paragraph with numbers carries a `<!-- src: path:line -->`
comment, stripped at build; result paragraphs follow observation →
magnitude with uncertainty → interpretation → limit; captions are
self-contained. Three new schematic figures (pipeline, architectures,
timeline) and two derived results artifacts were added so that every
number has a generated source: `results/comparison/parameter-counts.md`
(exact counts from the model code) and `wallclock-per-run.md`
(per-run training wall-clock summed from the clock files, main and
ablation runs). Two mechanical checks gate the text:
`scripts/check_report_sources.py` (every numeric token must occur in
the evidence base — docs, journals, results, configs, tests, code) and
`scripts/check_fr_numbers.py --dir paper/report` (FR/EN numeric
identity). Every chapter was read by me after drafting; three were
corrected on substance (see Failures).

## Raw results + uncertainty

| Measure | Value |
| --- | --- |
| Source files EN / FR | 25 / 25 |
| Words (EN sources incl. tables, comments stripped) | ≈65,000 |
| PDF pages EN / FR (A4, Typst, final build) | 157 / 172 |
| Em dashes in the 50 source files after the style pass | 2 per language (quoted frozen rule; one cited title) |
| Figures / tables (EN) | 10 / ≈75 |
| Traceability check | 1 token to review of ≈3,000 (a seed written `777_000` in code) |
| FR/EN numeric identity | 25/25 files, ALL CONSISTENT (final run recorded in final-control) |
| Unresolved cross-references / duplicate labels at build | 0 / 0 |

## Failures

Re-deriving every number exposed defects that the earlier passes (which
compared files to files) had not caught; each is logged in the
methodology log and corrected at the generator or source:

1. `make_figures.py` cost table: mean run wall-clock computed as
   sum(5 runs)/3 — printed 30.0 h / 61.2 h for true 18.0 h / 36.7 h;
   per-game cost rows inflated the same way. Fixed; the 2.0× ratio and
   every verdict unchanged.
2. The same table's "training throughput ≈770 / ≈195 pos/s" row quoted
   pilot-condition measurements (772 pos/s with loader workers) as
   campaign throughput; the campaign ran with an in-process loader
   (log medians ≈271 / ≈79). Replaced by the journaled benchmark
   274 / 138 pos/s at batch 128 with conditions stated.
3. "+2.1%" capacity difference was the ratio of the rounded millions;
   exact counts 1,443,168 vs 1,465,452 give +1.5%. Corrected everywhere
   except the append-only journals; `scripts/count_params.py` writes the
   exact counts.
4. Undocumented pipeline property surfaced from the driver code: each
   generation trains a fresh seeded initialisation on that generation's
   500 games only (no warm start, no replay window). Identical in both
   arms; now stated in the pipeline chapter and discussed as a limit on
   the absolute regime reached.
5. Journal "duration" fields for ablation runs are elapsed times
   including evaluations; the report uses one accounting (per-generation
   clock sums) for every run and says so.
6. Documentation inaccuracy: `docs/representations/graph.md` said the
   pass logit came from the pooled state; the code scores it as a learned
   constant. Corrected with a dated note.

## Author's review of the first build (same day)

The author read the 165-page first build and asked for two things:
prose without em dashes or other marks of machine writing, and a layout
without clipped or crowded tables, near-empty pages, an empty section
heading, a cramped equation, raw chat approvals in the gate table, or a
bibliography without links. Both were addressed: SPEC rules 7–8 (style;
formal decision records) and nine copy-editing agents over the 50
source files, each verified structurally and numerically; and a rework
of the build (breakable table figures, content-proportional column
widths with a longest-word floor, left-aligned cells, sticky headings,
equation delimiters, hashes on two lines, hanging-indent bibliography
with clickable URLs). The flagged pages were re-rendered and inspected.
Mechanical checks after the pass: FR/EN identity 25/25 files, numeric
traceability unchanged, no duplicate or unresolved labels in either
language.

## Limits / confounders

Page counts are properties of this build (Typst, A4, 11 pt). The FR
edition keeps the figures' internal labels in English (captions in
French) and renders English thousands commas as thin spaces at build
time, decimal points kept — stated in its front matter. The report has
not been read by an external reviewer; the author's full visual pass and
G-PUBLIC remain open.

## Interpretation

The re-derivation held for every score, interval and verdict; it failed
for three presentation numbers (two cost rows, one capacity ratio),
all now corrected. The lesson recorded in the methodology log: a number
being present in a file is not provenance — the file must derive it from
raw data under a stated definition, which the new checker enforces at
token level.

## Decision

**continue** — D-033 recorded; the report v2.0-draft is the final
deliverable; booklet v1.0-draft kept as the earlier edition.

## Artifacts

`paper/report/*.md`, `paper/report/fr/*.md`, `paper/report/SPEC.md`;
`paper/build/report-{en,fr}.pdf` (+ `.typ`); `scripts/build_report.py`,
`check_report_sources.py`, `count_params.py`, `make_report_figures.py`;
`paper/figures/fig{8,9,10}-*.png`; `results/comparison/parameter-counts.md`,
`wallclock-per-run.md`; `paper/final-control.md` (v2.0 section).
