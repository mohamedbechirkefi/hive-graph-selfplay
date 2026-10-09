```yaml
id:            H8-2026-10-09-detailed-edition-01
date:          2026-10-09
hypothesis:    Report-scope measurement, not an experiment. The human
               judged the 22/25-page v1.0-draft too thin for a research
               report and approved a detailed edition (D-032). Question:
               can the booklet be expanded to a research-grade volume
               using ONLY existing verified material — no new runs, no
               frozen artifact touched, no number or claim changed — and
               keep the mechanical FR/EN identity?
git_commit:    paper sources at 90b9eda + this session's commit
config:        n/a (editorial); figure/table generators unchanged except
               the make_results.py prose fix recorded below
seeds:         n/a (all figures/tables read the existing 5-seed records)
data_version:  data/runs/cmp-*-s{1..5}, results/comparison/, results/ablations/
hardware:      M1 Pro (rendering only)
duration:      one session (3 translation agents in parallel)
cost:          0
```

## Methods

Additions, all sourced from artifacts already in the repository:
(1) annex A materialised — `scripts/make_annex_corpus.py` renders the 35
executable TOML cases (30 critical + 5 tactical) with rule, setup,
expectation and the hand-written justification, so the annex cannot
drift from the tests; (2) annex B — both architectures layer by layer,
the shared decoder, record v3 byte layout, search settings (from the
code and `docs/`); (3) annex C — frozen-constants table with hashes and
gates, training hyperparameters, seed derivation, command sheet,
measured machine profile, journal/decision index; (4) three figures from
`make_figures.py`: fig5 per-opponent trajectories, fig6 epoch-1 training
metrics parsed from the 10 main-campaign logs, fig7 truncation per run
vs legal-random; (5) chapter 8 — the gated human–AI working methodology,
condensed from `docs/methodology.md` (conclusion renumbered 9);
(6) chapter 3 deepened from the verified reading notes (budgets,
architectures, evaluation methods and single-run caveats per work);
(7) generated tables moved to annex E with demoted headings; CSS
chapter-per-page; pandoc `pagetitle` instead of `title` (removed a
spurious "booklet-en" header on page 1); alt-text captions for all 7
figures. French copies of the 4 new files + the enriched ch3 by three
agents under D-006 rules; booklet maps and front-matter TOC updated in
both languages.

## Raw results + uncertainty

| Measure | Before | After |
| --- | --- | --- |
| Pages EN / FR (A4, Chrome print) | 22 / 25 | **47 / 52** |
| Sources assembled | 13 | 17 |
| Figures | 4 | 7 |
| FR/EN file pairs numerically identical | 13 (ALL CONSISTENT) | **17 (ALL CONSISTENT, 977 tokens)** |
| Claims register rows | 26 | 27 (ch. 8 process claim) |
| Embedded images in each HTML | 3 | 6 |

Structural check of both PDFs: every chapter/annex heading located on
its own page (EN: ch1 p2 … ch8 p21, ch9 p23, bibliography p24, annexes
A p27, B p37, C p39, D p41, E p42; FR: ch1 p3 … E p47); figure pages
44–47 (EN); footer on the last page; sample pages rasterised and
inspected (front matter, method, ch7, corpus annex, tables, all figure
pages).

## Failures

One staleness defect found by the render pass and fixed:
`results/comparison/results-arm-difference.md` said "bootstrap 95% over
seeds (3 per arm, independent)" under the 5-seed numbers. Root cause:
`make_results.py` wrote the file append-only and skipped the block once
its heading existed; the 5-seed regeneration therefore never refreshed
that prose. Fix: seed count from `SEEDS`, file rewritten whole each run.
`git diff results/` after regeneration: the two prose lines only; every
numeric table byte-identical. Methodology-log entry written.

Two layout defects found and fixed before the final build: no page
breaks at all in the HTML→PDF path (`\newpage` is dropped by pandoc's
HTML writer; chapters ran into one another), and pandoc's `title`
metadata rendering a "booklet-en" title block above the front matter.

## Limits / confounders

Page counts depend on the CSS and the print engine (Chrome headless,
A4, 2.2 cm margins) — they are a property of this build, not of the
text. The FR booklet still carries annex E's generated tables in
English (established convention: inserted verbatim). The visual pass of
every page remains the author's (final-control "author" item).

## Interpretation

Yes: the detailed edition roughly doubles the volume with verifiable
content only — rendered test cases, measured architecture/format
details, the full reproduction sheet, three additional views of the same
frozen records, and the process chapter. No number, claim, frozen
artifact or protocol value changed; the FR/EN numeric identity holds for
all 17 pairs.

## Decision

**continue** — D-032 recorded; final-control updated; author's visual
pass and G-PUBLIC remain the only open items.

## Artifacts

`paper/build/booklet-{en,fr}.{md,html,pdf}`; new sources
`paper/{annex-corpus,annex-architectures,annex-reproduction,ch-methodology}.md`
and `paper/fr/` copies; `paper/figures/fig{5,6,7}-*.png`;
`scripts/make_annex_corpus.py`; `scripts/assemble_booklet.py`,
`scripts/make_booklet_pdf.sh`, `scripts/make_results.py` (changed);
`paper/final-control.md`; `paper/claims.md` (+1 row).
