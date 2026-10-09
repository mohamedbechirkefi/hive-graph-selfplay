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
    "ch-methodology.md",
    "ch8-conclusion.md",
    "bibliography.md",
    "annex-corpus.md",
    "annex-architectures.md",
    "annex-reproduction.md",
]

ANNEX_EN = """# Annex D — Repository pointers

Everything not materialised in annexes A–C lives in the repository;
each pointer names its identifiers and how to read them (plan ch. 23).

- **D.1 Configs, seeds, manifests.** `configs/` (matrix, baselines with
  sha256-pinned weights, pinned eval settings, ablation diffs); per-run
  `*-manifest.json` and `wallclock.json` under `data/runs/`.
- **D.2 Encoding conventions in full.** `docs/representations/{grid,graph,
  comparison-controls}.md`; `docs/action-decoder.md` — the normative
  prose behind annex B.
- **D.3 Claims register.** `paper/claims.md` — one row per claim:
  claim, evidence, section, limit. No row, no claim.
- **D.4 Experiment journal.** `journal/` — every run and measurement,
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
    hdr = ("# Annex E — Result tables and figures (generated)" if lang == "en"
           else "# Annexe E — Tableaux de résultats et figures (générés)")
    note = ("*Pulled verbatim at assembly time from `results/` and "
            "`paper/figures/` — regenerate via `scripts/make_results.py` "
            "and `scripts/make_figures.py`.*" if lang == "en" else
            "*Insérés tels quels à l'assemblage depuis `results/` et "
            "`paper/figures/` — régénérables via `scripts/make_results.py` "
            "et `scripts/make_figures.py`.*")
    parts = [hdr, "", note, ""]

    def demote(text):
        # Included files are standalone documents with their own h1;
        # inside the annex they are sections (keeps them from forcing a
        # page break each, as h1 does in the booklet CSS).
        return "\n".join(("#" + l) if l.startswith("#") else l
                         for l in text.splitlines())

    for f in [res / "comparison" / "results-same-examples.md",
              res / "comparison" / "results-same-wallclock.md",
              res / "comparison" / "results-arm-difference.md",
              res / "ablations" / "README.md",
              figs / "fig2-score-cost.md"]:
        parts.append(demote(f.read_text().rstrip()))
        parts.append("")
    # Alt text renders as the figure caption (pandoc <figcaption>).
    caps_en = {
        "fig1-score-vs-time.png":
            "Fig. 1 — Mean score against the frozen population vs "
            "training wall-clock, all seeds, both arms (evaluations at "
            "generations 5, 8, 10; dashed line = T*).",
        "fig3-encodings.png":
            "Fig. 3 — The two encodings of one position: grid planes in "
            "the 32×32 frame (left) and the cell graph with its six "
            "direction-typed relations (right).",
        "fig4-failures.png":
            "Fig. 4 — Three commented failure positions F1–F3 (details "
            "and reproduction status below).",
        "fig5-per-opponent.png":
            "Fig. 5 — Per-opponent score trajectories (mean over 5 "
            "seeds, min–max band; final checkpoints per generation; "
            "100 games/opponent at 400 simulations).",
        "fig6-training-metrics.png":
            "Fig. 6 — Training metrics by generation (epoch-1 policy "
            "top-1 and value accuracy, 10 main-campaign runs; ablation "
            "runs excluded).",
        "fig7-truncation.png":
            "Fig. 7 — Final-evaluation truncation rate against "
            "legal-random, per run (final checkpoints, 5 seeds per arm; "
            "truncation reported separately from draws per invariant 7).",
    }
    caps_fr = {
        "fig1-score-vs-time.png":
            "Fig. 1 — Score moyen contre la population gelée vs temps "
            "mural d'entraînement, toutes graines, les deux bras "
            "(évaluations aux générations 5, 8, 10 ; pointillé = T*).",
        "fig3-encodings.png":
            "Fig. 3 — Les deux encodages d'une même position : plans en "
            "grille dans le cadre 32×32 (gauche) et graphe de cellules "
            "avec ses six relations typées par direction (droite).",
        "fig4-failures.png":
            "Fig. 4 — Trois positions d'échec commentées F1–F3 (détails "
            "et statut de reproduction ci-dessous).",
        "fig5-per-opponent.png":
            "Fig. 5 — Trajectoires de score par adversaire (moyenne "
            "sur 5 graines, bande min–max ; points de contrôle finaux par "
            "génération ; 100 parties/adversaire à 400 simulations).",
        "fig6-training-metrics.png":
            "Fig. 6 — Métriques d'entraînement par génération "
            "(top-1 politique et exactitude valeur à l'époque 1, 10 "
            "exécutions de la campagne principale ; exécutions "
            "d'ablation exclues).",
        "fig7-truncation.png":
            "Fig. 7 — Taux de troncature en évaluation finale contre "
            "l'aléatoire légal, par exécution (points de contrôle finaux, "
            "5 graines par bras ; troncature rapportée séparément des "
            "nulles, invariant 7).",
    }
    caps = caps_en if lang == "en" else caps_fr
    for png in ["fig1-score-vs-time.png", "fig3-encodings.png",
                "fig4-failures.png"]:
        shutil.copy(figs / png, BUILD / png)
        parts.append(f"![{caps[png]}]({png})")
        parts.append("")
    parts.append(demote((PAPER / "figures" / "fig4-failures.md").read_text().rstrip()))
    parts.append("")
    for png in ["fig5-per-opponent.png", "fig6-training-metrics.png",
                "fig7-truncation.png"]:
        shutil.copy(figs / png, BUILD / png)
        parts.append(f"![{caps[png]}]({png})")
        parts.append("")
    return "\n".join(parts)


def assemble(lang):
    src = PAPER if lang == "en" else PAPER / "fr"
    parts = []
    for name in ORDER:
        f = src / name
        if not f.exists():  # bibliography is shared (not translated)
            f = PAPER / name
        parts.append(f.read_text().rstrip())
    annex = ANNEX_EN if lang == "en" else ANNEX_FR.replace(
        "# Annex D — Repository pointers",
        "# Annexe D — Pointeurs vers le dépôt")
    parts.append(annex.strip())
    parts.append(generated_sections(lang))
    body = "\n\n\\newpage\n\n".join(parts)
    footer = (f"\n\n---\n\n*{VERSION} — assembled {date.today().isoformat()} "
              f"by scripts/assemble_booklet.py; sources in paper/"
              f"{'' if lang == 'en' else 'fr/'} govern.*\n")
    out = BUILD / f"booklet-{lang}.md"
    out.write_text(body + footer)
    print(f"{out.name}: {len(body.splitlines())} lines from {len(ORDER)} sources")


if __name__ == "__main__":
    BUILD.mkdir(parents=True, exist_ok=True)
    assemble("en")
    assemble("fr")
