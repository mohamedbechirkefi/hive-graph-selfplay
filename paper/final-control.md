# Final control record — booklet v1.0-draft (2026-10-09)

Plan ch. 23/28 pre-diffusion checklist, item by item. "✓" = verified
this session with the named evidence; the two "author" items need the
human's eye and are the only ones open.

| Item | Status | Evidence |
| --- | --- | --- |
| Each research question answered or absence motivated | ✓ | RQ-H1 rejected (results ch.); RQ-H2 both readings (fig1/fig2); RQ-H3 H-T3 complete |
| Contributions demonstrated or requalified | ✓ | ch1 contributions each name section + artifact; claim rows exist |
| Numbers match raw results; consistent abstract↔figures↔conclusion | ✓ | tables regenerate byte-identical (fresh-env run); key-number grep across chapters; claims register 33 rows |
| Failed runs, exclusions, seeds, limits declared | ✓ | zero exclusions (ch5 §5.4); A1 divergence journaled & reported; limits in every section + ch7 |
| Sources, licences, contributions, AI use disclosed | ✓ / 1 open | AI declaration in front matter; **OPEN for diffusion: third-party engine licences (A1 task 7, G-RIGHTS) + repo licence review at release (G-PUBLIC)** |
| Bibliography + webographie after conclusion, verified, cited | ✓ | generated from consulted notes; citation↔entry bijection checked |
| Figures legible, captioned, reproducible | ✓ | all four regenerate from scripts; captions carry population/budget/uncertainty; fig4 reproductions verified vs CSV rows |
| No placeholder, secret, personal data, invented result | ✓ | sweep clean (3 staleness items fixed 2026-10-09) |
| Code and report versions compatible | ✓ | booklet assembled from repo state; commit recorded in footer/journals |
| Minimal reproduction runs in a fresh environment | ✓ | `scripts/reproduce_minimal.sh`: clean clone → build → game replay matches shipped row → tables BYTE-IDENTICAL (2026-10-09) |
| PDF visually checked, links work | **author** | PDFs at `paper/build/booklet-{en,fr}.pdf`; structural checks done (7 tables, figures embedded); the human's visual pass is the sign-off |
| French copy: same tag, numbers/claims identical | ✓ | `check_fr_numbers.py` ALL CONSISTENT (13 files) |
| Diffusion gated | **author** | Nothing leaves the machine without G-PUBLIC |

**Deliverable set at this tag:** `paper/build/booklet-en.pdf` + `.md` +
`.html`; same for FR; `paper/synthesis-one-page.md`; claims register;
results manifest = `results/` + per-run manifests; code = this repository.
