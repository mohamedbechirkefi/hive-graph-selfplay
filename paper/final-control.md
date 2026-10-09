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
