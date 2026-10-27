# Abstract {.unnumbered}

Hive is a boardless hexagonal strategy game whose moves are (piece,
destination) pairs over an ever-changing set of cells, which makes it,
in principle, a natural candidate for graph neural encodings in place of
the convolutional grid encodings standard in AlphaZero-style systems. We test
that intuition under a pre-registered protocol frozen before any
comparison run: one grid CNN and one capacity-matched (+1.5%) relational
message-passing network share a rules-validated engine, one action
decoder, identical training settings, a frozen three-opponent population
and 250 frozen openings, evaluated under two budget readings (equal
training examples; equal wall-clock at a pre-registered cutoff) with five
independent seeds per arm and truncation reported as its own outcome. The
hypothesis is rejected: the graph arm scores lower against two of three
opponents under both readings, at twice the wall-clock cost, with its
deficit concentrated in converting won positions. Ablations show that
the graph arm's typed edge relations are necessary for optimization
stability, while its global pooling is dispensable. A second study,
pre-registered separately (protocol frozen on 13 October 2026) and run
on five new seeds per arm under a warm-started loop with a
three-generation replay window, tested the main objection to that
verdict: no graph advantage was detected under either reading, every
graph−grid interval includes zero (largest upper bounds +0.090 and
+0.055), the first study's deficit is no longer visible at equal
examples and reduced at equal wall-clock, and the conversion pathology
persists in three graph seeds of five at 2.34 times the cost. Both
results are pre-registered and reproducible from the released records.
<!-- src: paper/front-matter.md:26; results/study2/results-arm-difference.md; journal/2026-10-27-h9-analysis-01.md:95-123,186-205 -->

**Keywords.** Hive; AlphaZero; graph neural networks; representation
learning; pre-registration; negative result.

# Résumé {.unnumbered}

Hive est un jeu de stratégie hexagonal sans plateau dont les coups sont
des paires (pièce, destination) sur un ensemble de cellules en perpétuel
changement, ce qui en fait, en principe, un candidat naturel pour des
encodages par réseaux de neurones en graphe plutôt que pour les encodages convolutifs
en grille standards des systèmes de type AlphaZero. Nous testons cette
intuition sous un protocole pré-enregistré, gelé avant toute exécution
comparative : un CNN en grille et un réseau relationnel à passage de
messages de capacité appariée (+1.5%) partagent un moteur validé côté
règles, un décodeur d'actions unique, des réglages d'entraînement
identiques, une population gelée de trois adversaires et 250 ouvertures
gelées, évalués sous deux lectures budgétaires (à exemples
d'entraînement égaux ; à temps mural égal à un seuil pré-enregistré),
avec cinq graines indépendantes par bras et la troncature rapportée
comme un résultat à part entière. L'hypothèse est rejetée : le bras
graphe obtient un score inférieur contre deux des trois adversaires sous
les deux lectures, à un coût en temps mural double, son déficit se
concentrant dans la conversion des positions gagnées. Les ablations
montrent que les relations d'arêtes typées du bras graphe sont
nécessaires à la stabilité de l'optimisation, tandis que son agrégation
globale (global pooling) est dispensable. Une seconde étude,
pré-enregistrée séparément (protocole gelé le 13 octobre 2026) et menée
sur cinq nouvelles graines par bras sous une boucle à démarrage à chaud
avec une fenêtre de rejeu de trois générations, a testé la principale
objection à ce verdict : aucun avantage du graphe n'a été détecté sous
l'une ou l'autre lecture, chaque intervalle graphe−grille inclut zéro
(plus grandes bornes supérieures +0.090 et +0.055), le déficit de la
première étude n'est plus visible à exemples égaux et est réduit à temps
mural égal, et la pathologie de conversion persiste dans trois graines
graphe sur cinq, à 2.34 fois le coût. Les deux résultats sont
pré-enregistrés et reproductibles à partir des enregistrements publiés.
<!-- src: paper/fr/front-matter.md:33; results/study2/results-arm-difference.md; journal/2026-10-27-h9-analysis-01.md:95-123,186-205 -->

**Mots-clés.** Hive ; AlphaZero ; réseaux de neurones en graphe ;
apprentissage de représentations ; pré-enregistrement ; résultat négatif.

# Status, code and declaration of assistance {.unnumbered}

**Status.** Independent research report prepared in view of a doctoral
application. It is not peer-reviewed and is not a publication of any
institution. Version 2.1-draft, October 2026; the experimental content
is final and no number differs from the frozen raw results of 9 October
2026 (first study) and 27 October 2026 (second study).
<!-- src: paper/front-matter.md:10; journal/2026-10-27-h9-analysis-01.md:1-30 -->

**Code and artifacts.** The engine, the training pipeline, both
encoders, the frozen configurations, the raw per-game evaluation records
and the scripts that regenerate every table and figure of this report
form one public repository, https://github.com/mohamedbechirkefi/hive-graph-selfplay,
released at tag v2.0-report on 9 October 2026 for the first study (the
records archive is attached to that release); the second study's
records and this revision accompany the release tagged v2.1-report. A fresh-environment reproduction scenario is described in
`@sec:app-g`{=typst}; the provenance of every result is tabulated in
`@sec:app-e`{=typst}.

**Declaration of assistance by an artificial-intelligence system.** This
study was executed under a human-as-principal-investigator methodology
in which an AI research assistant (Claude, Anthropic) implemented code,
ran the computational campaigns, kept the experiment journals and
drafted text, under a system of six decision gates reserving every
scientific commitment to the human author: the freezing of protocol,
opponents and openings, every expenditure of compute, anything made
public and the deletion of any data. The human author chose the
question, approved each gated decision in writing, verified the
conclusions and owns every claim. `@sec:working-method`{=typst} documents this working
methodology, its rationale and its record.
<!-- src: paper/front-matter.md:18 -->

**Conventions.** Scores are means over decided games (win 1, draw 0.5,
loss 0) against a fixed opponent population; games stopped at the
experimental move cap are *truncated* and are reported as a separate
outcome, never as draws. Intervals in brackets are 95% percentile
bootstrap intervals with the independent training run (seed) as the
resampling unit. The arm trained on the grid encoding is the *grid arm*;
the arm trained on the graph encoding is the *graph arm*. A glossary
with the French equivalents of all technical terms is given in
`@sec:app-f`{=typst}.
