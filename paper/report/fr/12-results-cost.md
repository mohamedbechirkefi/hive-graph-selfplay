# Résultats : coût et efficacité (RQ-H2) {#sec:results-cost}

La deuxième question de recherche demande comment les deux
représentations se comparent lorsque le budget est lu comme un nombre
d'exemples d'entraînement et lorsqu'il est lu comme un temps sur le même
matériel. Le protocole exigeait les deux lectures et exigeait de chaque
exécution qu'elle rapporte son temps mural, son matériel, le nombre
d'états d'entraînement consommés et les simulations par décision. Ce
chapitre rapporte ces coûts et met les deux lectures côte à côte.
<!-- src: docs/protocol.md:99 -->

## Ce que coûte chaque bras sur la machine d'étude

| Métrique | Bras grille | Bras graphe |
| --- | ---: | ---: |
| Paramètres | 1.44 M | 1.47 M (+1.5%) |
| Inférence au meilleur fournisseur, lot 1 | 2.62 ms (accélérateur neuronal) | 3.67 ms (CPU) |
| Temps mural d'entraînement par exécution, moyenne de 5 graines (10 générations × 500 parties) | 18.0 h | 36.7 h (2.0×) |
| Coût d'auto-jeu équivalent | 13.0 s/partie | 26.4 s/partie |
| Référence de débit d'entraînement (lot 128, avant + arrière) | 274 pos/s | 138 pos/s |
| Score contre la population, lecture à exemples égaux | 0.411 | 0.331 |
| Score contre la population, lecture à temps mural égal (seuil 18.77 h) | 0.405 | 0.326 |

Table: Résumé des coûts et des scores par bras (H-T2). Le temps mural
d'entraînement couvre la génération en auto-jeu et l'entraînement pour
les dix générations d'une exécution, parties d'évaluation exclues,
moyenné sur les cinq graines ; le coût d'auto-jeu équivalent le divise
par les 5,000 parties d'une exécution. Les chiffres d'inférence et de
débit d'entraînement sont des mesures de référence du 10 septembre
2026 sur la machine d'étude (Apple M1 Pro, 10 cœurs, 16 Go). Score
contre la population = moyenne, sur les trois adversaires gelés, du
score moyen au niveau des graines (troncatures exclues). {#tbl:cost}
<!-- src: paper/figures/fig2-score-cost.md; docs/representations/comparison-controls.md:14 -->

Les deux réseaux sont appariés en taille. L'évaluation unitaire du bras
graphe est 1.4× plus lente à son meilleur fournisseur, son débit
d'entraînement est la moitié de celui du bras grille, et une exécution
complète lui coûte le double de temps mural. Par exécution, les cinq
graines grille ont pris 18.77, 16.73, 19.07, 18.23 et 17.19 heures de
temps mural d'entraînement ; les cinq graines graphe ont pris 43.07,
32.71, 31.28, 49.86 et 26.57 heures.
<!-- src: results/comparison/wallclock-per-run.md; docs/representations/comparison-controls.md:28 -->

Le rapport de temps mural mesuré est de 2.0× (36.7 h contre 18.0 h en
moyenne). Au stade du dimensionnement, le rapport avait été estimé à
1.7× ; le rapport mesuré sur les cinq premières exécutions achevées
était de 2.1×, et l'estimation a été remplacée par le chiffre mesuré
dans toute la comptabilité budgétaire avant le calcul de toute
comparaison.
<!-- src: journal/2026-09-16-h6-progress-01.md:31 -->

La génération en auto-jeu domine le temps mural des deux bras ; dans le
pilote, la génération 0 a pris environ 60 minutes d'auto-jeu contre
environ 3.5 minutes d'entraînement. Le surcoût du bras graphe se paie
donc surtout dans la recherche, par son inférence par position plus
lente et son exécution sur CPU. L'asymétrie est une propriété du
matériel de déploiement : le réseau convolutif se projette proprement
sur l'accélérateur neuronal de la machine (2.62 ms par évaluation),
tandis que le réseau graphe, riche en opérations de collecte (gather),
se replie sur le CPU pour une large part de ses opérations et s'y
exécute le plus vite (3.67 ms sur CPU contre 9.84 ms sur
l'accélérateur, avec 147 nœuds d'opérateurs pris en charge sur 287). Le
protocole a choisi de rapporter et d'imputer cette asymétrie plutôt que
de la neutraliser par égalisation. La lecture à temps mural égal reflète
ainsi ce que chaque représentation coûte sur cette machine, tandis que
la lecture à exemples égaux n'en est pas affectée.
<!-- src: docs/representations/comparison-controls.md:19; docs/representations/comparison-controls.md:43 -->

Sur un autre accélérateur, le rapport pourrait changer dans l'une ou
l'autre direction ; sur CPU seul, le réseau graphe est le plus rapide
des deux à l'inférence (3.67 ms contre 23.5 ms). Les chiffres de coût de
ce chapitre sont donc spécifiques à ce matériel par construction ; les
comptes de paramètres et les chiffres de débit en sont la partie
portable.
<!-- src: docs/representations/comparison-controls.md:24 -->

## Les deux lectures côte à côte

Sous la lecture à exemples égaux, les deux bras sont comparés après dix
générations ; le score du bras grille contre la population est de 0.411
et celui du bras graphe de 0.331. Sous la lecture à temps mural égal,
chaque exécution est prise à son dernier point de contrôle dans les
18.77 heures (génération 9 ou 10 pour les exécutions grille,
génération 3 à 6 pour les exécutions graphe), et les scores contre la
population sont de 0.405 et 0.326. Les deux lectures donnent donc le
même ordre et presque le même écart : 0.081 à exemples égaux et 0.079 à
temps égal, en faveur du bras grille.
<!-- src: paper/figures/fig2-score-cost.md; results/comparison/wallclock-per-run.md; journal/2026-10-09-h6-5seed-final-01.md:22 -->

La raison pré-enregistrée de lire le budget deux fois était la
possibilité d'une représentation qui apprend davantage par exemple mais
moins par heure, auquel cas les deux lectures seraient en désaccord et
toutes deux devraient être rapportées. Ici elles concordent : le bras
graphe apprend moins par exemple et aussi moins par heure. La lecture à
temps égal ne crée pas le déficit ; elle accentue un déficit que la
lecture par exemple montre déjà, puisqu'à l'intérieur du seuil le bras
graphe achève moins de la moitié de ses générations.
<!-- src: docs/protocol.md:103; paper/results-comparison.md:38 -->

Le score contre la population moyenne trois adversaires de difficulté
très différente ; il n'est donc qu'un résumé pour cette comparaison et
masque la structure par adversaire du résultat ; les tables par
adversaire de `@sec:results-main`{=typst} constituent la preuve
primaire. Les scores aux générations intermédiaires (5 et 8) proviennent
d'évaluations à 20 parties dimensionnées pour le suivi et n'entrent dans
aucun intervalle.
<!-- src: journal/2026-09-16-h6-progress-01.md:58 -->

## Le score en fonction du temps

`@fig:score-vs-time`{=typst} dans `@sec:results-main`{=typst} trace le
score contre la population de chaque exécution en fonction de son temps
mural d'entraînement cumulé. Deux traits des courbes répondent
directement à RQ-H2. Premièrement, à chaque temps mural auquel les deux
bras disposent d'une évaluation, chaque exécution grille se situe
au-dessus de chaque exécution graphe ; les bandes des bras ne se
croisent pas. Deuxièmement, les courbes des exécutions grille
s'aplatissent après leurs premières évaluations (contre l'adversaire
aléatoire, elles sont près du plafond dès la génération 5), tandis que
les courbes des exécutions graphe continuent de bouger de façon non
monotone tout au long de leurs exécutions plus longues ; au seuil, les
exécutions graphe ont eu 3 à 6 générations et sont encore dans le régime
où la variation d'une graine à l'autre domine. Dans ce budget, le temps
supplémentaire a donné au bras graphe davantage de générations sans
produire de croisement.
<!-- src: scripts/make_figures.py:68; results/comparison/results-same-wallclock.md -->

## Ressources consommées par l'étude

La comparaison principale a consommé dix exécutions d'entraînement
totalisant environ 274 heures de temps mural d'entraînement (cinq
exécutions grille, 90.0 h ; cinq exécutions graphe, 183.5 h), plus les
parties d'évaluation (100 parties par adversaire et par point de
contrôle à environ 23–32 secondes par partie à 400 simulations, pour les
points de contrôle final et au seuil de chaque exécution) et les
évaluations de suivi aux générations 5 et 8. Les trois cellules
d'ablation ont ajouté neuf exécutions du bras graphe (temps mural
d'entraînement sous la même comptabilité : A1 7.61–8.01 h chacune parce
que les réseaux divergents jouaient des parties courtes ; A2
32.05–47.44 h ; A1′ 23.89–30.35 h). Tout le calcul s'est exécuté
séquentiellement sur un seul ordinateur portable maintenu éveillé, sans
ressources infonuagiques ni ressources payantes ; les campagnes
s'étendent du 10 septembre au 6 octobre 2026.
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-09-23-h7-a1-divergence-01.md:15; paper/annex-reproduction.md:70 -->
