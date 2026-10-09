# Résultats : la comparaison principale (RQ-H1) {#sec:results-main}

Ce chapitre rapporte la comparaison pré-enregistrée exactement comme le
protocole gelé l'a définie : deux bras, cinq graines indépendantes
chacun, évalués contre la population gelée de trois adversaires sur les
250 ouvertures gelées, sous deux lectures de budget. Chaque table montre
chaque graine. Les scores excluent les parties tronquées, qui sont
rapportées dans leur propre colonne ; les intervalles sont des
intervalles bootstrap percentiles à 95% sur les graines (10,000
rééchantillonnages). Les procédures statistiques et les tables brutes
avec toutes les colonnes auxiliaires se trouvent dans
`@sec:app-d`{=typst} ; la provenance de chaque nombre est dans
`@sec:app-e`{=typst}.
<!-- src: docs/protocol.md:122; journal/2026-09-19-h6-comparison-01.md:38 -->

## Le verdict en un paragraphe

Sous les deux lectures de budget, le bras graphe ne montre aucun
avantage cohérent entre graines contre aucun adversaire, et chaque
intervalle sur la différence de score graphe−grille exclut un avantage
graphe substantiel : la plus grande borne supérieure sur les six
contrastes est +0.028. La règle de rejet pré-enregistrée se déclenche
donc, et **H1 est rejetée**. À ce budget, sur Hive en jeu de base, la
représentation en graphe n'a pas aidé : elle a obtenu un score plus
faible contre deux des trois adversaires gelés sous les deux lectures,
et pas meilleur contre le troisième. Le reste du chapitre présente la
preuve derrière ce paragraphe, graine par graine.
<!-- src: journal/2026-10-09-h6-5seed-final-01.md:61; results/comparison/results-arm-difference.md -->

## Lecture 1 : nombre égal d'exemples d'entraînement

Dans la première lecture, les deux bras sont comparés à leurs points de
contrôle de la génération 10 : chaque exécution a alors engendré dix
générations de 500 parties d'auto-jeu sous des budgets de simulation
identiques et s'est entraînée dessus, de sorte que les deux bras ont
consommé le même nombre d'exemples d'entraînement.
<!-- src: docs/protocol.md:106; configs/comparison-matrix.yaml -->

| Bras | Graine | Score B-RND | Troncature B-RND | Score B-HEU | Score B-MCTS |
| --- | --- | ---: | ---: | ---: | ---: |
| grille | 1 | 0.995 | 0% | 0.150 | 0.125 |
| grille | 2 | 0.975 | 1% | 0.080 | 0.125 |
| grille | 3 | 0.990 | 1% | 0.190 | 0.075 |
| grille | 4 | 0.949 | 11% | 0.105 | 0.085 |
| grille | 5 | 0.995 | 0% | 0.120 | 0.210 |
| graphe | 1 | 0.733 | 57% | 0.025 | 0.115 |
| graphe | 2 | 0.981 | 20% | 0.050 | 0.125 |
| graphe | 3 | 0.722 | 55% | 0.090 | 0.100 |
| graphe | 4 | 0.688 | 44% | 0.125 | 0.120 |
| graphe | 5 | 0.935 | 23% | 0.035 | 0.115 |

Table: Lecture à exemples égaux. Score au point de contrôle final
(génération 10) de chaque exécution contre chaque adversaire gelé ;
100 parties appariées à couleurs échangées par adversaire et par
exécution sur les 250 ouvertures gelées, à 400 simulations par coup
sans bruit d'exploration. Score = moyenne sur les parties décidées
(victoire 1, nulle 0.5, défaite 0). Troncature = part des 100 parties
arrêtées au plafond de 300 demi-coups ; aucune partie contre B-HEU ou
B-MCTS n'a été tronquée par l'un ou l'autre bras. {#tbl:same-examples}
<!-- src: results/comparison/results-same-examples.md:7 -->

Contre l'adversaire aléatoire légal, chaque graine
grille obtient au moins 0.949 tandis que les graines graphe s'étendent
de 0.688 à 0.981 ; contre l'heuristique, les graines grille s'étendent
de 0.080 à 0.190 et les graines graphe de 0.025 à 0.125 ; contre
l'adversaire de recherche, les deux bras se recouvrent (0.075–0.210
contre 0.100–0.125). Le bras graphe tronque 20–57% de ses parties
contre l'adversaire aléatoire ; le bras grille 0–11%.
<!-- src: results/comparison/results-same-examples.md:7 -->

| Bras | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grille | 0.981 [0.964, 0.994] | 0.129 [0.098, 0.165] | 0.124 [0.087, 0.168] |
| graphe | 0.812 [0.710, 0.920] | 0.065 [0.034, 0.100] | 0.115 [0.107, 0.121] |

Table: Lecture à exemples égaux. Score moyen au niveau des graines par
bras et par adversaire, avec l'intervalle bootstrap à 95% sur les cinq
graines. {#tbl:same-examples-means}
<!-- src: results/comparison/results-same-examples.md:20 -->

## Lecture 2 : temps mural égal sur la même machine

Dans la seconde lecture, chaque exécution est prise au dernier point de
contrôle qu'elle avait achevé dans le seuil à temps mural égal de
18.77 heures, la médiane du temps mural total des trois exécutions
grille originales, calculée le 16 septembre 2026 avant toute
comparaison inter-bras. Parce que les générations du bras graphe sont
environ deux fois plus coûteuses sur cette machine, le seuil sélectionne
la génération 9 ou 10 pour les exécutions grille (le point de contrôle
de la génération 10 est atteint dans le seuil par quatre des cinq) et
les générations 3 à 6 pour les exécutions graphe : les graines grille
1–5 sont lues aux générations 10, 10, 9, 10 et 10 ; les graines graphe
1–5 aux générations 4, 5, 5, 3 et 6 (en comptant le réseau initial
comme génération 1 ; dans les journaux d'exécution, ces points de
contrôle sont étiquetés gen009/gen009/gen008/gen009/gen009 et
gen003/gen004/gen004/gen002/gen005).
<!-- src: journal/2026-09-16-h6-progress-01.md:36; journal/2026-10-09-h6-5seed-final-01.md:22 -->

| Bras | Graine | Score B-RND | Troncature B-RND | Score B-HEU | Score B-MCTS |
| --- | --- | ---: | ---: | ---: | ---: |
| grille | 1 | 0.995 | 0% | 0.150 | 0.125 |
| grille | 2 | 0.975 | 1% | 0.080 | 0.125 |
| grille | 3 | 0.939 | 1% | 0.145 | 0.080 |
| grille | 4 | 0.949 | 11% | 0.105 | 0.085 |
| grille | 5 | 0.995 | 0% | 0.120 | 0.210 |
| graphe | 1 | 0.798 | 58% | 0.045 | 0.075 |
| graphe | 2 | 0.926 | 39% | 0.055 | 0.110 |
| graphe | 3 | 0.713 | 53% | 0.060 | 0.105 |
| graphe | 4 | 0.631 | 39% | 0.100 | 0.150 |
| graphe | 5 | 0.980 | 24% | 0.045 | 0.095 |

Table: Lecture à temps mural égal. Score de chaque exécution à son
dernier point de contrôle achevé dans le seuil de 18.77 heures, contre
chaque adversaire gelé ; même évaluation que `@tbl:same-examples`{=typst}
(100 parties appariées par adversaire, 250 ouvertures gelées,
400 simulations, sans bruit). Troncature = part des parties au plafond
de 300 demi-coups ; aucune contre B-HEU ou B-MCTS. {#tbl:same-wallclock}
<!-- src: results/comparison/results-same-wallclock.md:7 -->

| Bras | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grille | 0.971 [0.950, 0.991] | 0.120 [0.098, 0.142] | 0.125 [0.090, 0.168] |
| graphe | 0.810 [0.697, 0.922] | 0.061 [0.047, 0.081] | 0.107 [0.087, 0.130] |

Table: Lecture à temps mural égal. Score moyen au niveau des graines
par bras et par adversaire, avec l'intervalle bootstrap à 95% sur les
cinq graines. {#tbl:same-wallclock-means}
<!-- src: results/comparison/results-same-wallclock.md:20 -->

Le tableau de la première lecture persiste à temps
égal : les moyennes du bras grille sont plus élevées contre les
adversaires aléatoire et heuristique et se recouvrent contre
l'adversaire de recherche ; la troncature du bras graphe contre
l'adversaire aléatoire est de 24–58%.
<!-- src: results/comparison/results-same-wallclock.md:7 -->

## Le contraste entre bras

| Adversaire | Exemples égaux : graphe − grille | Temps mural égal : graphe − grille |
| --- | ---: | ---: |
| B-RND (aléatoire légal) | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| B-HEU (heuristique) | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| B-MCTS (recherche, 6,400 simulations) | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

Table: Le contraste pré-enregistré, soit la différence des scores moyens
au niveau des graines (bras graphe moins bras grille), avec l'intervalle
bootstrap à 95% sur les graines (cinq graines indépendantes par bras,
rééchantillonnées indépendamment, 10,000 rééchantillonnages). Une
valeur négative favorise le bras grille. {#tbl:contrast}
<!-- src: results/comparison/results-arm-difference.md -->

Quatre des six contrastes excluent zéro, tous en
faveur du bras grille ; les deux contrastes contre l'adversaire de
recherche chevauchent zéro.

Contre l'adversaire aléatoire légal, la différence
graphe−grille est de −0.169 [−0.272, −0.062] à exemples égaux et de
−0.161 [−0.278, −0.048] à temps égal ; contre l'heuristique, −0.064
[−0.111, −0.017] et −0.059 [−0.087, −0.029] ; contre l'adversaire de
recherche, −0.009 [−0.055, +0.028] et −0.018 [−0.066, +0.025].
La plus grande borne supérieure de tout intervalle est +0.028, soit le
plus grand avantage graphe que les données laissent possible sous la
lecture et l'adversaire les plus favorables.
<!-- src: results/comparison/results-arm-difference.md -->

La règle de rejet gelée exigeait, sous les deux
lectures, l'absence d'un avantage graphe cohérent entre graines ainsi
que des intervalles excluant un avantage graphe substantiel. Les deux
conditions sont remplies : aucun adversaire ne montre un ordre par
graine cohérent en faveur du bras graphe (`@tbl:same-examples`{=typst},
`@tbl:same-wallclock`{=typst}), et aucun intervalle n'admet un avantage
supérieur à +0.028. H1 est rejetée. Le résultat est cohérent entre
graines et tient sous les deux égalisations de budget ; il ne repose
pas sur un seul intervalle.
<!-- src: docs/protocol.md:32 -->

Cinq graines par bras bornent la statistique : contre
l'adversaire de recherche, où les deux bras obtiennent un score autour
de 0.1, les données ne peuvent pas distinguer les bras. Le rejet
concerne ce réseau relationnel simple à passage de messages, à cette
capacité et à ce budget ; il ne dit rien des représentations en graphe
à plus grands budgets ou avec d'autres architectures.

## Comment l'analyse à cinq graines se rapporte à l'analyse à trois graines

Le protocole pré-enregistrait trois graines par bras avec une option de
cinq. L'analyse à trois graines du 19 septembre 2026 rejetait déjà H1
sous les deux lectures (contrastes contre l'adversaire aléatoire −0.175
[−0.268, −0.007] et −0.158 [−0.254, −0.050] ; contre l'heuristique
−0.085 [−0.143, −0.025] et −0.072 [−0.100, −0.028] ; contre
l'adversaire de recherche +0.005 [−0.020, +0.035] et −0.013 [−0.040,
+0.015]). Les graines 4 et 5 ont ensuite été ajoutées aux deux bras
sous des pré-engagements écrits pris le 26 septembre 2026 : l'analyse
finale utiliserait les cinq graines selon la même règle, le seuil
resterait inchangé, et la collecte en deux étapes serait divulguée. L'extension a
resserré quatre des six intervalles, absorbé l'unique paire de graines
où le graphe faisait mieux observée contre l'heuristique (graine graphe
4 à 0.125 contre graine grille 4 à 0.105) et le meilleur score contre
l'adversaire de recherche de toute exécution (graine grille 5 à 0.210),
et n'a pas changé le verdict. Les tables à cinq graines ci-dessus sont
les nombres finaux de l'étude.
<!-- src: journal/2026-09-19-h6-comparison-01.md:56; journal/2026-10-09-h6-5seed-final-01.md:34 -->

## Le plafond de coups peut-il sauver l'hypothèse ?

La troncature a été définie comme une issue distincte avant la première
exécution, et le protocole exigeait que le résultat primaire soit
recalculé sous des traitements alternatifs des parties tronquées. Le
traitement le plus favorable au bras graphe compte chaque partie
tronquée comme une victoire pour le bras testé, ce qui constitue une
borne supérieure de ce que tout plafond plus grand pourrait apporter. Sous cette borne,
calculée à partir des enregistrements par partie des trois graines
originales, la différence graphe−grille contre l'adversaire aléatoire
est encore de −0.072 à exemples égaux et de −0.058 à temps égal ; la
direction du contraste est inchangée sous chaque traitement (exclues,
comptées 0.5, comptées comme défaites, comptées comme victoires). La
valeur du plafond ne peut donc pas renverser le verdict ; elle ne peut
qu'en changer l'ampleur.
<!-- src: journal/2026-09-19-h6-comparison-01.md:66; docs/protocol.md:69 -->

## Où se loge le déficit

Mettre les trois adversaires côte à côte montre où se loge le déficit :
il est le plus grand contre l'adversaire le plus faible et absent
contre le plus fort. Contre l'aléatoire légal, où la force
consiste surtout à achever un encerclement auquel rien ne résiste, le
bras graphe gagne du matériel puis échoue à convertir ; la colonne de
troncature est la trace de cet échec. Contre l'heuristique, qui attaque
directement la reine, la défense du bras graphe est plus faible que
celle du bras grille. Contre l'adversaire de recherche, les deux bras
sont dans un régime de scores bas où dix générations d'auto-jeu à petit
budget n'ont pas produit une attaque que l'un ou l'autre bras puisse
soutenir. `@sec:results-qualitative`{=typst} examine ces mécanismes sur
des parties individuelles ; `@sec:discussion`{=typst} pèse les
explications.
<!-- src: paper/ch7-discussion.md:7 -->

![Score moyen contre la population gelée (moyenne des trois
adversaires, troncatures exclues) en fonction du temps mural
d'entraînement cumulé, pour les dix exécutions principales ;
évaluations aux générations 5, 8 et 10 (20, 20 et 100 parties par
adversaire). Bleu : bras grille ; rouge : bras graphe ; une ligne par
graine. La ligne verticale en pointillés marque le seuil à temps mural
égal de 18.77 heures.](figures/fig1-score-vs-time.png){#fig:score-vs-time width=92%}

<!-- src: scripts/make_figures.py:68 -->

`@fig:score-vs-time`{=typst} montre les deux lectures à la fois : à
tout temps mural donné, le bras grille se situe au-dessus du bras
graphe, et au seuil les exécutions graphe ont achevé moins de la moitié
de leurs générations. `@sec:results-cost`{=typst} quantifie le volet
coût.
