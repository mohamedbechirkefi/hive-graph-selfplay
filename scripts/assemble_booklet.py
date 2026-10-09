#!/usr/bin/env python3
"""Assemble the single-file booklet (EN and FR) from the paper/ sources
per the assembly map in paper/booklet.md. Output: paper/build/
booklet-en.md and booklet-fr.md (then HTML/PDF via make_booklet_pdf.sh).

Each source keeps its content; the assembler adds page breaks, demotes
nothing, and injects a generated footer with the version tag. The
claims register and annex pointers are appended as annex sections.
"""

from datetime import date
from pathlib import Path

PAPER = Path(__file__).resolve().parent.parent / "paper"
BUILD = PAPER / "build"
VERSION = "v1.0-draft"

ORDER = [
    "front-matter.md",
    "ch1-introduction.md",
    "ch2-formalisation.md",
    "ch3-related-work.md",
    "method-validation.md",
    "method-baselines.md",
    "method-pipeline.md",
    "method-representations.md",
    "ch5-protocol.md",
    "results-comparison.md",
    "ch7-discussion.md",
    "ch8-conclusion.md",
    "bibliography.md",
]

ANNEX_EN = """

\\newpage

# Annexes (pointers)

Bulky artifacts live in the repository; each annex names its identifiers
and how to read them (plan ch. 23).

- **A. Position corpora.** `tests/critical_positions/` (30 rules-derived
  cases + README with sources and review status);
  `tests/tactical_positions/` (5 cases + runner).
- **B. Rule and encoding conventions.** `docs/representations/{grid,graph,
  comparison-controls}.md`; `docs/action-decoder.md`.
- **C. Architectures and hyperparameters.** `python/hivenet/model.py`,
  `python/hivenet/graph_model.py`; training flags in each run's
  `train-config.json`.
- **D. Configs, seeds, manifests.** `configs/` (matrix, baselines with
  sha256-pinned weights, pinned eval settings, ablation diffs); per-run
  `*-manifest.json` and `wallclock.json` under `data/runs/`.
- **E. Reproduction.** `scripts/reproduce_minimal.sh` (fresh-environment
  minimal scenario); `scripts/make_results.py` and `make_figures.py`
  regenerate every table and figure from raw per-game records.
- **F. Claims register.** `paper/claims.md` — one row per claim:
  claim, evidence, section, limit. No row, no claim.
- **G. Experiment journal.** `journal/` — every run and measurement,
  negative results included; decision log in `state/decisions.md`
  (workspace repository).
"""

ANNEX_FR = ANNEX_EN  # pointers are repo paths; header translated below.


def generated_sections(lang):
    """Inline the generated result tables and figures so the booklet is
    self-contained (single source of truth: these files regenerate from
    raw records; the assembler never retypes a number)."""
    import shutil
    res = PAPER.parent / "results"
    figs = PAPER / "figures"
    hdr = ("# Result tables and figures (generated)" if lang == "en"
           else "# Tableaux de résultats et figures (générés)")
    note = ("*Pulled verbatim at assembly time from `results/` and "
            "`paper/figures/` — regenerate via `scripts/make_results.py` "
            "and `scripts/make_figures.py`.*" if lang == "en" else
            "*Insérés tels quels à l'assemblage depuis `results/` et "
            "`paper/figures/` — régénérables via `scripts/make_results.py` "
            "et `scripts/make_figures.py`.*")
    parts = [hdr, "", note, ""]
    for f in [res / "comparison" / "results-same-examples.md",
              res / "comparison" / "results-same-wallclock.md",
              res / "comparison" / "results-arm-difference.md",
              res / "ablations" / "README.md",
              figs / "fig2-score-cost.md"]:
        parts.append(f.read_text().rstrip())
        parts.append("")
    for png in ["fig1-score-vs-time.png", "fig3-encodings.png",
                "fig4-failures.png"]:
        shutil.copy(figs / png, BUILD / png)
        parts.append(f"![{png}]({png})")
        parts.append("")
    parts.append((PAPER / "figures" / "fig4-failures.md").read_text().rstrip())
    return "\n".join(parts)


def assemble(lang):
    src = PAPER if lang == "en" else PAPER / "fr"
    parts = []
    for name in ORDER:
        f = src / name
        if not f.exists():  # bibliography is shared (not translated)
            f = PAPER / name
        parts.append(f.read_text().rstrip())
    parts.append(generated_sections(lang))
    body = "\n\n\\newpage\n\n".join(parts)
    annex = ANNEX_EN if lang == "en" else ANNEX_FR.replace(
        "# Annexes (pointers)", "# Annexes (pointeurs)")
    footer = (f"\n\n---\n\n*{VERSION} — assembled {date.today().isoformat()} "
              f"by scripts/assemble_booklet.py; sources in paper/"
              f"{'' if lang == 'en' else 'fr/'} govern.*\n")
    out = BUILD / f"booklet-{lang}.md"
    out.write_text(body + annex + footer)
    print(f"{out.name}: {len(body.splitlines())} lines from {len(ORDER)} sources")


if __name__ == "__main__":
    BUILD.mkdir(parents=True, exist_ok=True)
    assemble("en")
    assemble("fr")
