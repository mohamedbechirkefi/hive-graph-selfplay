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
globale (global pooling) est dispensable. Le résultat est négatif,
pré-enregistré et entièrement reproductible à partir des enregistrements publiés.
<!-- src: paper/fr/front-matter.md:33 -->

**Mots-clés.** Hive ; AlphaZero ; réseaux de neurones en graphe ;
apprentissage de représentations ; pré-enregistrement ; résultat négatif.

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
stability, while its global pooling is dispensable. The result is
negative, pre-registered and fully reproducible from the released records.
<!-- src: paper/front-matter.md:26 -->

**Keywords.** Hive; AlphaZero; graph neural networks; representation
learning; pre-registration; negative result.

# Statut, code et déclaration d'assistance {.unnumbered}

**Statut.** Rapport de recherche indépendant préparé en vue d'une
candidature au doctorat. Il n'est pas évalué par les pairs et n'est la
publication d'aucune institution. Version 2.0-draft, octobre 2026 ; le
contenu expérimental est définitif et aucun nombre ne diffère des
résultats bruts gelés du 9 octobre 2026.
<!-- src: paper/front-matter.md:10 -->

**Code et artefacts.** Le moteur, le pipeline d'entraînement, les deux
encodeurs, les configurations gelées, les enregistrements bruts
d'évaluation par partie et les scripts qui régénèrent chaque table et
chaque figure de ce rapport forment un seul dépôt public, publié à
l'étiquette v2.0-report :
https://github.com/mohamedbechirkefi/hive-graph-selfplay (l'archive des
enregistrements est jointe à cette publication). Un scénario de
reproduction en environnement vierge est décrit en
`@sec:app-g`{=typst} ; la provenance de chaque résultat est tabulée en
`@sec:app-e`{=typst}.

**Déclaration d'assistance par un système d'intelligence artificielle.**
Cette étude a été exécutée selon une méthodologie « l'humain comme
chercheur principal », dans laquelle un assistant de recherche IA
(Claude, Anthropic) a implémenté le code, mené les campagnes de calcul,
tenu les journaux d'expériences et rédigé le texte, sous un système de
six portes de décision réservant chaque engagement scientifique à
l'auteur humain : le gel du protocole, des adversaires et des
ouvertures, chaque dépense de calcul, tout ce qui est rendu public et la
suppression de toute donnée. L'auteur humain a choisi la question,
approuvé par écrit chaque décision soumise à une porte, vérifié les
conclusions et assume chaque affirmation. `@sec:working-method`{=typst} documente cette méthodologie
de travail, sa justification et son historique.
<!-- src: paper/front-matter.md:18 -->

**Conventions.** Les scores sont des moyennes sur les parties décidées
(victoire 1, nulle 0.5, défaite 0) contre une population d'adversaires
fixe ; les parties arrêtées au plafond de coups expérimental sont
*tronquées* et sont rapportées comme une issue distincte, jamais comme
des nulles. Les intervalles entre crochets sont des intervalles
bootstrap percentile à 95% ayant pour unité de rééchantillonnage
l'exécution d'entraînement indépendante (la graine). Le bras entraîné
sur l'encodage en grille est le *bras grille* ; le bras entraîné sur
l'encodage en graphe est le *bras graphe*. Un glossaire donnant les
équivalents français de tous les termes techniques figure en
`@sec:app-f`{=typst}. Les figures conservent leurs annotations internes
en anglais ; leurs légendes sont en français. Les nombres suivent la
typographie du master anglais afin que leur identité entre les deux
éditions soit vérifiable mécaniquement : le point est le séparateur
décimal ; les séparateurs de milliers sont rendus par une espace fine.
