*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Carte d'assemblage du livret v1 (2026-10-09)

Le livret est assemblé à partir de ces sources, dans l'ordre. Chaque
partie est un brouillon daté ; le registre des affirmations
(`../claims.md`) gouverne chaque affirmation dans chacune d'elles.

| Chapitre du livret | Fichier(s) source |
| --- | --- |
| Pages liminaires + résumé | `front-matter.md` |
| 1 Introduction | `ch1-introduction.md` |
| 2 Formalisation | `ch2-formalisation.md` |
| 3 Travaux connexes | `ch3-related-work.md` |
| 4 Méthode | `method-validation.md` + `method-baselines.md` + `method-pipeline.md` + `method-representations.md` |
| 5 Protocole | `ch5-protocol.md` |
| 6 Résultats | `results-comparison.md` (incl. H-T3) |
| 7 Discussion et menaces | `ch7-discussion.md` |
| 8 Méthodologie de travail (humain–IA sous portes) | `ch-methodology.md` |
| 9 Conclusion | `ch8-conclusion.md` |
| Bibliographie + Webographie | `../bibliography.md` (générée ; bibliographie partagée, les références ne sont pas traduites) |
| Annexe A — Corpus de positions (matérialisée) | `annex-corpus.md` (générée par `scripts/make_annex_corpus.py` depuis les cas TOML exécutables) |
| Annexe B — Architectures, décodeur, formats | `annex-architectures.md` |
| Annexe C — Hyperparamètres, graines, commandes | `annex-reproduction.md` |
| Annexe D — Pointeurs vers le dépôt | injectée par `scripts/assemble_booklet.py` (configs/manifestes, conventions complètes, registre des affirmations, journal) |
| Annexe E — Tableaux de résultats et figures (générés) | injectée par `scripts/assemble_booklet.py` tels quels depuis `results/` et `figures/` |
| Figures | `../figures/fig1–fig7` (toutes se régénèrent via `scripts/make_figures.py`) |

Les fichiers de chapitre ci-dessus désignent les copies françaises de
ce répertoire (`fr/`).

**Version :** v1.0-draft (2026-10-09, édition détaillée). Master
anglais. La copie française (`fr/`, D-006) est produite à partir de
cet assemblage au même tag. **Toute diffusion, sous quelque forme que
ce soit, requiert G-PUBLIC.**
