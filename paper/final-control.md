# Final control record — booklet v1.0-draft, detailed edition (2026-10-09)

Plan ch. 23/28 pre-diffusion checklist, item by item. "✓" = verified
this session with the named evidence; the two "author" items need the
human's eye and are the only ones open. This record supersedes the
short-draft record of the same day (22/25 pages); the detailed edition
(D-032) changed no number and no claim.

| Item | Status | Evidence |
| --- | --- | --- |
| Each research question answered or absence motivated | ✓ | RQ-H1 rejected (results ch.); RQ-H2 both readings (fig1/fig2); RQ-H3 H-T3 complete |
| Contributions demonstrated or requalified | ✓ | ch1 contributions each name section + artifact; claim rows exist |
| Numbers match raw results; consistent abstract↔figures↔conclusion | ✓ | tables regenerate byte-identical (fresh-env run; re-run 2026-10-09 after the generator fix: numeric diff empty); key-number grep across chapters; claims register 27 rows |
| Failed runs, exclusions, seeds, limits declared | ✓ | zero exclusions (ch5 §5.4); A1 divergence journaled & reported; limits in every section + ch7; annex C lists every seed derivation |
| Sources, licences, contributions, AI use disclosed | ✓ / 1 open | AI declaration in front matter + ch. 8 (working methodology, gates quoted); **OPEN for diffusion: third-party engine licences (A1 task 7, G-RIGHTS) + repo licence review at release (G-PUBLIC)** |
| Bibliography + webographie after conclusion, verified, cited | ✓ | generated from consulted notes; citation↔entry bijection checked; ch3 enrichment cites only works with verified reading notes |
| Figures legible, captioned, reproducible | ✓ | 7 figures regenerate from `scripts/make_figures.py`; captions carry population/budget/uncertainty (alt-text captions, no filename captions); fig4 reproductions verified vs CSV rows; page-render pass of every figure page |
| No placeholder, secret, personal data, invented result | ✓ | sweep clean; **1 staleness item found by the render pass and fixed: generated arm-contrast prose said "3 per arm" under 5-seed numbers** (`make_results.py` rewrite; methodology-log entry) |
| Code and report versions compatible | ✓ | booklet assembled from repo state; commit recorded in footer/journals |
| Minimal reproduction runs in a fresh environment | ✓ | `scripts/reproduce_minimal.sh`: clean clone → build → game replay matches shipped row → tables BYTE-IDENTICAL (2026-10-09) |
| Annexes materialised, not only pointed to | ✓ | Annex A (35 corpus cases rendered from the executable TOMLs by `scripts/make_annex_corpus.py`), B (architectures, decoder, record v3, search), C (frozen constants, hyperparameters, seeds, commands, machine profile), D (pointers), E (generated tables + figs 1–7) |
| PDF visually checked, links work | **author** | PDFs at `paper/build/booklet-{en,fr}.pdf` — **47 pp (EN) / 52 pp (FR)**, A4, chapter-per-page; structural checks done (every chapter/annex heading located on its page, 6 embedded images, footer on last page); sample pages rendered and inspected; the human's full visual pass is the sign-off |
| French copy: same tag, numbers/claims identical | ✓ | `scripts/check_fr_numbers.py` ALL CONSISTENT (17 files, 977 numeric tokens) |
| Diffusion gated | **author** | Nothing leaves the machine without G-PUBLIC |

**Deliverable set at this tag:** `paper/build/booklet-en.pdf` + `.md` +
`.html`; same for FR; `paper/synthesis-one-page.md`; claims register;
results manifest = `results/` + per-run manifests; code = this repository.

# Final control record — report v2.0-draft, reference edition (2026-10-09)

The standalone academic report (`paper/report/`, D-033) supersedes the
booklet as the final deliverable; the booklet v1.0-draft remains as the
earlier edition. Checklist (plan ch. 23/28), with the evidence specific to
the report; "author" items are the only open ones.

| Item | Status | Evidence |
| --- | --- | --- |
| Each research question answered or absence motivated | ✓ | RQ-H1 ch. 11 (verdict under the frozen rule); RQ-H2 ch. 12; RQ-H3 ch. 13; the protocol's time-permitting symmetry question declared dropped (ch. 9) |
| Contributions demonstrated or requalified | ✓ | ch. 1 names three contributions with their chapters; ch. 16 restates each against the evidence; software not counted as a contribution |
| Numbers match raw results; consistent abstract↔figures↔conclusion | ✓ | `scripts/check_report_sources.py`: every numeric token of the 25 chapters occurs in the evidence base (1 token to review: a seed written `777_000` in code); two derived artifacts added so that no number is computed in prose (`parameter-counts.md`, `wallclock-per-run.md`); three presentation defects found by the re-derivation and fixed at source (methodology log) |
| Failed runs, exclusions, seeds, limits declared | ✓ | zero exclusions (ch. 9); A1 divergence as a result; two-stage seed collection disclosed (ch. 9, 11, App. D); per-generation re-initialisation of the network stated (ch. 6, 15); limits in every result section |
| Sources, licences, contributions, AI use disclosed | ✓ / 1 open | front matter + ch. 10 (gates, approvals quoted, incidents table); **OPEN for diffusion: third-party engine licences (A1 task 7, G-RIGHTS) + repo licence review (G-PUBLIC)** |
| Bibliography + webography after conclusion, verified, cited | ✓ | ch. 17: 13 scientific entries + 6 web resources, academic style, every entry consulted and cited; no entry in both |
| Figures legible, captioned, reproducible | ✓ | 10 figures, all from scripts (`make_figures.py`, `make_report_figures.py`); captions carry population/budget/runs/uncertainty; list of figures generated |
| No placeholder, secret, personal data, invented result | ✓ | body scan for internal identifiers (paths, scripts, journal/decision ids, phase codes) empty outside ch. 10 / App. E / App. G, where they are the subject |
| Prose reads as written by a human researcher (author's instruction) | ✓ | SPEC rules 7–8: em dashes 0 in all 50 source files except the quoted frozen rule and one cited title; bold run-in result labels removed; recorded approvals summarised formally (original wording in the decision log only); nine copy-editing passes, each verified structurally (comments, labels, snippets, table rows unchanged) |
| Layout: tables readable, no clipped or near-empty pages from unbreakable blocks (author's review of the first build) | ✓ | build rework: breakable table figures, content-proportional column widths, left-aligned cells, sticky headings, equation delimiters fixed, 64-character hashes on two lines, bibliography with hanging indent and clickable links (384 link annotations EN); page-render pass of every flagged table (2, 25, 26, 65, 74), section 4.4 and equation (4) |
| Code and report versions compatible | ✓ | report built from the committed repository state; commits listed in App. E and G |
| Minimal reproduction runs in a fresh environment | ✓ | unchanged scenario (`reproduce_minimal.sh`, PASS 2026-10-09); documented in App. G |
| Standalone readability (no .md references in the body) | ✓ | SPEC rule 1 enforced by scan; cross-references rendered as Section/Figure/Table/Appendix numbers; glossary with French equivalents (App. F) |
| PDF visually checked, links work | **author** | `paper/build/report-en.pdf` **157 pp**, `report-fr.pdf` **172 pp**; A4, Typst: title page, contents, list of figures, numbered parts/chapters, running headers, page numbers, clickable outline and URLs; the author reviewed the first build and the flagged pages were re-rendered after the fixes; the author's full pass of the final build is the sign-off |
| French copy: same numbers | ✓ | `check_fr_numbers.py --dir paper/report`: 25/25 files ALL CONSISTENT; FR build renders thousands separators as thin spaces (stated in its front matter) |
| Diffusion gated | **author** | Nothing leaves the machine without G-PUBLIC |

**Deliverable set at this tag:** `paper/build/report-{en,fr}.pdf` (+ `.typ`
sources and `paper/report/{,fr/}*.md`); booklet v1.0-draft kept;
`paper/synthesis-one-page.md`; claims register; results manifest =
`results/` + per-run manifests; code = this repository.
