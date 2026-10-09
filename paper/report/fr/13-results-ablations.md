# Résultats : ablations par composant (RQ-H3) {#sec:results-ablations}

Ce chapitre répond à la troisième question de recherche : lequel des
deux composants distinctifs du bras graphe, ses six relations d'arêtes
typées par direction et son biais de pooling global, porte son
comportement. Chaque ablation retire un composant et rien d'autre, aux
réglages de la méthode complète (mêmes budgets, mêmes graines, mêmes
adversaires et ouvertures gelés, même évaluation), avec trois graines
par cellule ; une troisième exécution, explicitement étiquetée comme un
changement à deux composants, complète la première ablation. Tout du
long, rien n'est attribué au-delà du seul composant qui a changé.
<!-- src: configs/ablations/A1-edge-typing.md; configs/ablations/A2-global-pooling.md; results/ablations/README.md -->

## Conception des trois cellules

| Cellule | Ce qui change par rapport au bras graphe complet | Paramètres | Graines | Statut |
| --- | --- | ---: | ---: | --- |
| A1 : adjacence naïve | les six matrices de messages typées par direction sont remplacées par une seule matrice partagée | 0.54 M | 3 | à un composant, à parité |
| A2 : sans pooling global | le biais de pooling global est retiré de chaque couche | 1.37 M | 3 | à un composant, à parité |
| A1′ : adjacence naïve, stabilisée | comme A1, plus un écrêtage de la norme du gradient à 1.0 | 0.54 M | 3 | **à deux composants**, jamais attribué au seul typage |
| Référence : bras graphe complet | aucun | 1.47 M | 5 | comparaison principale |

Table: Les cellules d'ablation. Les comptes de paramètres sont
mesurés ; les différences de paramètres sont inhérentes aux composants
retirés et sont rapportées plutôt que compensées. {#tbl:ablation-cells}
<!-- src: results/ablations/README.md; journal/2026-09-23-h7-a1-divergence-01.md:4; journal/2026-10-09-h7-a1prime-01.md:4; docs/representations/comparison-controls.md:17 -->

## A1 : retirer les relations typées retire l'entraînabilité

Avec une seule matrice de messages partagée à la place de six matrices
typées, l'entraînement a divergé vers des valeurs non finies à la
génération 0 pour les trois graines ; chaque génération ultérieure a
joué en auto-jeu et s'est entraînée sur des sorties de réseau non
finies. Le symptôme qui a déclenché le diagnostic était statistique
plutôt que numérique. Les évaluations finales des trois graines étaient
identiques jusque dans le nombre de parties (par exemple 0 victoire,
0 nulle et 100 défaites contre l'heuristique pour chaque graine), ce que
des entraînements indépendants à graines distinctes ne peuvent produire.
Les points de contrôle ont des hachages distincts, mais chaque passe
avant renvoie une politique et une valeur non finies dès le premier
point de contrôle.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:22 -->

Les tables d'évaluation de la cellule ne sont donc pas des mesures de
force, puisqu'une politique non finie joue une partie déterministe et
dégénérée, indépendante de ses poids ; elles sont exclues en tant que
scores, et la cellule H-T3 indique « entraînement divergé (3/3
graines) ». Les exécutions ont pris 7.75, 8.01 et 7.61 heures de temps
mural d'entraînement contre une moyenne de 36.70 heures pour le bras
graphe, parce que des a priori non finis dégradent la recherche en
parties courtes d'environ 42 plis, sans troncature ni abandon ; le
budget configuré en parties et en simulations a été entièrement
consommé.
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-09-23-h7-a1-divergence-01.md:36 -->

Aux réglages de parité, la variante à adjacence naïve ne peut pas être
entraînée du tout, de sorte que les relations typées apportent, au
minimum, la stabilité d'optimisation du bras entier. Rien de leur
contribution à la force de jeu ne peut être mesuré à parité, puisque la
variante ne s'entraîne jamais. L'explication proposée ici, un argument
raisonné plutôt qu'une décomposition mesurée, est qu'une seule matrice
partagée reçoit le gradient sommé de six termes de voisinage, soit
environ six fois l'échelle de gradient par matrice de la variante typée,
à taux d'apprentissage et à momentum identiques. Le protocole avait
énoncé, avant toute exécution, qu'un graphe à adjacence naïve « peut ne
pas suffire » ; dans ces conditions, il n'optimise même pas.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:59; docs/protocol.md:24 -->

Aucun balayage du taux d'apprentissage n'a été exécuté, parce que
changer le taux d'apprentissage aurait fait de A1 une différence à deux
composants. Le passage silencieux de valeurs non finies pendant dix
générations était une lacune d'outillage : les boucles d'entraînement
n'avaient aucune garde contre les valeurs non finies, et leur cadence
d'impression de la perte (tous les 100 pas) ne se déclenchait jamais
sur des époques d'environ 20 pas. La lacune a été comblée le 23
septembre 2026 par un arrêt explicite des deux boucles d'entraînement
sur perte non finie ; le comportement des exécutions saines est
inchangé, et le résultat de l'ablation tient.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:47 -->

## A2 : retirer le pooling global ne change rien de mesurable

| Adversaire | A2 (sans pooling), graines 1/2/3 | Bras graphe complet, graines 1/2/3 | Différence A2 − complet [intervalle à 95%] |
| --- | --- | --- | --- |
| B-RND | 0.768 (59%) / 0.714 (65%) / 0.952 (17%) | 0.733 (57%) / 0.981 (20%) / 0.722 (55%) | −0.001 [−0.170, +0.165] |
| B-HEU | 0.050 / 0.070 / 0.025 | 0.025 / 0.050 / 0.090 | −0.007 [−0.043, +0.030] |
| B-MCTS | 0.070 / 0.125 / 0.105 | 0.115 / 0.125 / 0.100 | −0.013 [−0.043, +0.013] |

Table: Ablation A2 : scores au point de contrôle final par graine
(lecture à exemples égaux ; taux de troncature entre parenthèses
lorsqu'il est non nul ; 100 parties par adversaire et par graine sur
les 250 ouvertures gelées) et intervalle bootstrap sur les graines de
la différence avec les trois graines originales du bras graphe complet
(10,000 rééchantillonnages, ensembles de graines indépendants). {#tbl:a2}
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:34 -->

Les trois exécutions A2 se sont entraînées sainement (sorties finies,
résultats distincts par graine) ; leurs temps muraux d'entraînement de
39.90, 47.44 et 32.05 heures se situent dans la bande du bras graphe
complet (26.57–49.86 h).
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-10-02-h7-a2-nogpool-01.md:23 -->

Retirer le biais de pooling global a changé le score de −0.001
[−0.170, +0.165] contre l'adversaire aléatoire, de −0.007 [−0.043,
+0.030] contre l'heuristique et de −0.013 [−0.043, +0.013] contre
l'adversaire à recherche. Chaque intervalle chevauche zéro, et la
cellule de l'adversaire aléatoire est dominée par la variance entre
graines dans les deux variantes (taux de troncature entre 17% et 65%
selon les graines).
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:36; journal/2026-10-02-h7-a2-nogpool-01.md:46 -->

L'hypothèse selon laquelle le pooling portait l'apprentissage de la
valeur du bras graphe n'est pas soutenue. Huit couches de passage de
messages directionnel reproduisent à elles seules le comportement du
bras complet, y compris son mode de défaillance : la pathologie de
conversion contre l'adversaire aléatoire est présente dans les deux
variantes. À cette échelle, le biais de pooling global est dispensable.
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:53 -->

La cellule compte trois graines ; la différence de 0.10 M paramètres
est inhérente au composant retiré ; et « aucun effet mesurable » est
borné par des intervalles de largeur ±0.17 contre l'adversaire
aléatoire, où un petit effet pourrait se cacher.
<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:46 -->

## A1′ : la variante à adjacence naïve stabilisée (supplément à deux composants)

| Adversaire | A1′ graines 1/2/3 (troncature) | Moyenne A1′ (3 graines) | Moyenne graphe complet (5 graines) | Différence [intervalle à 95%] |
| --- | --- | ---: | ---: | --- |
| B-RND | 0.566 (47%) / 0.671 (59%) / 0.995 (0%) | 0.744 | 0.810 | −0.066 [−0.254, +0.130] |
| B-HEU | 0.035 / 0.135 / 0.110 | 0.093 | 0.061 | +0.032 [−0.011, +0.078] |
| B-MCTS | 0.090 / 0.195 / 0.060 | 0.115 | 0.107 | +0.008 [−0.040, +0.063] |

Table: Supplément A1′, relations non typées plus écrêtage de gradient
à 1.0 (deux composants diffèrent de la méthode complète). Scores au
point de contrôle final par graine, moyennes sur trois graines,
moyennes sur cinq graines du bras graphe complet, et intervalle
bootstrap sur les graines de la différence sur les deux ensembles de
graines de tailles inégales.
{#tbl:a1prime}
<!-- src: journal/2026-10-09-h7-a1prime-01.md:26 -->

Avec un seul stabilisateur ajouté, les trois entraînements sont restés
finis et la garde contre les valeurs non finies ne s'est jamais
déclenchée, ce qui confirme le remède impliqué par le diagnostic de
divergence. Les temps muraux d'entraînement de 23.89, 30.35 et 27.68
heures se situent à l'extrémité rapide de la bande du bras graphe.
<!-- src: results/comparison/wallclock-per-run.md; journal/2026-10-09-h7-a1prime-01.md:19 -->

La variante stabilisée obtient des scores dans la bande du bras graphe
complet contre les trois adversaires : −0.066 [−0.254, +0.130], +0.032
[−0.011, +0.078] et +0.008 [−0.040, +0.063] ; chaque intervalle
chevauche zéro.
<!-- src: journal/2026-10-09-h7-a1prime-01.md:30 -->

Combiné avec A1, le plus que l'on puisse dire est qu'à cette échelle la
contribution mesurable des relations typées par direction réside dans
la stabilité d'optimisation ; aucune contribution à la force au-delà de
celle-ci n'est détectable.
<!-- src: journal/2026-10-09-h7-a1prime-01.md:53 -->

Chaque nombre de cette cellule est confondu par l'écrêtage de gradient
par construction et n'est jamais attribué au seul typage des arêtes. La
cellule compte trois graines et des intervalles larges, et la
troncature à 0% de la graine 3 contre 47–59% pour les graines 1–2
montre que la pathologie de conversion reste volatile selon la graine
dans cette variante aussi.
<!-- src: journal/2026-10-09-h7-a1prime-01.md:45 -->

## Table de synthèse H-T3

| Ablation | Composant retiré | Résultat |
| --- | --- | --- |
| A1 adjacence naïve | matrices de relations typées par direction → une seule matrice partagée | entraînement divergé (non fini, génération 0, 3/3 graines) ; inentraînable à parité ; relations typées ⇒ au minimum la stabilité d'optimisation |
| A2 sans pooling global | biais de pooling global dans toutes les couches | effet nul : −0.001 / −0.007 / −0.013 contre les trois adversaires, tous les intervalles chevauchant zéro ; modes de défaillance inchangés ; pooling dispensable |
| Supplément A1′ (à deux composants) | relations non typées + écrêtage de gradient 1.0 | s'entraîne ; scores dans la bande du bras complet (−0.066 / +0.032 / +0.008) ; jamais attribué au seul typage |

Table: Attribution par composant pour le bras graphe (H-T3). Les
différences sont variante moins bras graphe complet, moyennes au niveau
des graines, trois graines par cellule d'ablation. {#tbl:ht3}
<!-- src: results/ablations/README.md -->

Dans le périmètre testé, la réponse à RQ-H3 est que, des deux
composants distinctifs du bras graphe, l'un est nécessaire à
l'entraînabilité elle-même et l'autre est dispensable. La question de
savoir si les relations typées contribuent aussi à la force de jeu
au-delà de la stabilité ne peut être tranchée à partir de ces cellules.
