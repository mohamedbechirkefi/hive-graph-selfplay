# Résultats : positions d'échec et comportement d'entraînement {#sec:results-qualitative}

Les scores agrégés disent que le bras graphe a moins appris ; ils ne
disent pas comment il échoue. Ce chapitre examine trois parties
individuelles sélectionnées par des critères mécaniques, le canal de
troncature qui porte le mécanisme, et ce que montrent les métriques
d'entraînement des dix exécutions principales.

## Trois positions d'échec, sélectionnées mécaniquement

Le plan de recherche demande trois positions d'échec commentées avec des
critères de sélection explicites. Les critères sont mécaniques et ont
été appliqués aux enregistrements bruts par partie : F1 est la plus
longue partie tronquée du bras graphe contre l'adversaire aléatoire
légal ; F2 est la plus courte défaite décidée du bras grille contre
l'adversaire heuristique ; F3 est la plus longue partie nulle du bras
graphe contre l'adversaire à recherche. Chaque partie sélectionnée a été
reproduite de façon déterministe à partir de son ouverture enregistrée
et de ses graines par partie, et vérifiée coup par coup contre sa ligne
de résultat enregistrée avant d'être rendue ; les trois reproductions
ont concordé. Cette étape de vérification a révélé un défaut latent du
lanceur d'affrontements (un chemin qui omettait d'écrire les
enregistrements lorsque chaque partie d'un affrontement était
tronquée) ; le défaut a été corrigé avant les évaluations à temps égal,
et un audit a établi qu'il n'avait affecté aucune donnée de campagne
(`@sec:working-method`{=typst}).
<!-- src: paper/figures/fig4-failures.md:3; docs/methodology-log.md -->

![Trois positions d'échec commentées, reproduites et vérifiées contre
leurs lignes de résultat enregistrées. F1 (à gauche) : bras graphe,
graine 1, contre l'aléatoire légal, ouverture 2, blancs ; la partie
atteint le plafond de 300 plis avec le bras graphe matériellement en
avance mais incapable d'achever l'encerclement. F2 (au centre) : bras
grille, graine 2, contre l'heuristique, ouverture 2, noirs ; une défaite
décidée en 19 plis face à la tactique de ciblage de la reine de
l'heuristique. F3 (à droite) : bras graphe, graine 3, contre
l'adversaire à recherche, ouverture 19, blancs ; une nulle en 79 plis
dans laquelle le bras graphe ne génère jamais de menace
gagnante.](figures/fig4-failures.png){#fig:failures width=100%}

<!-- src: paper/figures/fig4-failures.md:7 -->

*F1 : une position gagnée que le bras graphe ne parvient pas à
conclure.* Le bras graphe gagne du matériel tôt, puis déplace ses
pièces autour d'une reine ennemie partiellement encerclée jusqu'au
plafond. L'échec est tactique plutôt qu'évaluatif : le bras est en
avance et le reste, mais il ne trouve pas, ou ne préfère pas, la
séquence forçante qui achève l'encerclement. C'est le motif derrière le
taux de troncature de 20–57% du bras contre l'adversaire aléatoire, et
il est invisible dans toute évaluation qui compte les parties
plafonnées comme des nulles.
<!-- src: paper/figures/fig4-failures.md:5; paper/results-comparison.md:45 -->

*F2 : le prix des politiques de régime précoce face à une tactique
tranchante.* La plus courte défaite du bras grille contre l'heuristique
dure 19 plis. Le terme dominant de libertés de la reine de
l'heuristique la dirige droit sur la reine avant que la politique du
réseau n'ait consolidé une défense. La partie illustre pourquoi les
deux bras obtiennent des scores bas contre les deux adversaires forts
après dix générations, puisque le régime est encore précoce, et
pourquoi la résolution de la comparaison est la plus élevée contre
l'adversaire aléatoire.
<!-- src: paper/figures/fig4-failures.md:11; docs/baselines.md:34 -->

*F3 : éviter la défaite sans créer de menaces.* Contre l'adversaire à
recherche, la plus longue nulle du bras graphe (79 plis) montre un
réseau qui se défend convenablement, en ce qu'il évite de perdre, mais
ne construit jamais d'attaque gagnante. Contre cet adversaire, les deux
bras sont statistiquement indiscernables (`@sec:results-main`{=typst}) ;
F3 rappelle qu'« indiscernables » signifie ici que les deux bras
annulent ou perdent, et non que l'un ou l'autre joue bien.
<!-- src: paper/figures/fig4-failures.md:17 -->

## Le canal de troncature, exécution par exécution

![Taux de troncature à l'évaluation finale contre l'adversaire aléatoire
légal pour chacune des dix exécutions principales (points de contrôle
finaux ; 100 parties par exécution à 400 simulations sur les 250
ouvertures gelées ; plafond de 300 plis). Bleu : bras grille, graines
1–5 ; rouge : bras graphe, graines 1–5. La troncature est rapportée
séparément des nulles tout au long de
l'étude.](figures/fig7-truncation.png){#fig:truncation width=80%}

Le bras graphe a tronqué 57%, 20%, 55%, 44% et 23% de ses parties
contre l'adversaire aléatoire au point de contrôle final pour les
graines 1 à 5 ; le bras grille a tronqué 0%, 1%, 1%, 11% et 0%. Contre
l'heuristique et l'adversaire à recherche, aucune partie de l'un ou
l'autre bras n'a atteint le plafond.
<!-- src: results/comparison/results-same-examples.md:7 -->

L'écart de troncature est la plus grande différence comportementale
entre les bras, plus grande que tout écart de score, et sa direction
est cohérente entre graines : chaque graine graphe tronque plus que
chaque graine grille. La graine grille 4 (11%) ne dépasse aucune graine
graphe, mais elle montre que la pathologie n'est pas strictement
exclusive à un bras. Parce que la troncature a été définie comme une
issue à part entière avant la première exécution, la pathologie est
visible au lieu d'être absorbée dans les nulles ; et parce que le
plafond ne peut pas sauver l'hypothèse (`@sec:results-main`{=typst}),
le canal est diagnostique plutôt que décisif.
<!-- src: results/comparison/results-same-examples.md:7; journal/2026-09-19-h6-comparison-01.md:66 -->

Le score du bras graphe contre l'adversaire aléatoire est par
conséquent mesuré sur moins de parties décidées (entre 43 et 80 par
graine), ce qui élargit son intervalle ; l'analyse de sensibilité borne
cet effet sans le supprimer.
<!-- src: paper/ch7-discussion.md:60 -->

## Ce que montrent les métriques d'entraînement

![Métriques d'entraînement par génération pour les dix exécutions de la
campagne principale (ligne de l'époque 1 de chaque génération) : à
gauche, accord top-1 de la politique avec la distribution de visites
MCTS sur la partition de validation d'auto-jeu ; à droite, exactitude de
la valeur sur les échantillons non tronqués. Bleu : bras grille ;
rouge : bras graphe ; une ligne par graine. Les exécutions d'ablation
sont exclues.](figures/fig6-training-metrics.png){#fig:training width=100%}

Les deux bras ajustent leurs données d'auto-jeu tout au long des dix
générations : l'argmax de politique (top-1) monte avec la génération
dans chaque exécution, et l'exactitude de la valeur sur les
échantillons non tronqués monte pour les deux bras. L'exactitude de la
valeur du bras graphe est comparable à celle du bras grille, tandis que
son argmax de politique (top-1) reste en retrait.
<!-- src: paper/figures/fig6-training-metrics.png; journal/2026-09-16-h6-progress-01.md:74 -->

L'écart entre les bras n'est donc pas un simple échec d'optimisation du
bras graphe complet (contrairement à la variante ablatée à adjacence
naïve, qui n'a pas optimisé du tout). Le bras graphe apprend une
évaluation utilisable des positions et une politique plus faible. Les
positions d'échec donnent la même image, un jugement adéquat de qui est
mieux et une génération inadéquate de coups forçants, et cela motive le
premier prolongement proposé dans `@sec:conclusion`{=typst}.
<!-- src: journal/2026-09-16-h6-progress-01.md:74; paper/ch8-conclusion.md:19 -->

Les métriques d'entraînement sont calculées sur la partition de
validation d'auto-jeu propre à chaque exécution, dont la distribution
se déplace avec la génération et diffère entre les bras ; elles
constituent une preuve sur l'ajustement, non sur la force, et aucun
nombre de cette figure n'entre dans aucun intervalle ni dans aucune
affirmation de la comparaison principale.

## Trajectoires par adversaire

![Score contre chaque adversaire gelé aux générations évaluées (5, 8 et
10 ; 20, 20 et 100 parties par adversaire respectivement) pour chaque
exécution principale. Bleu : bras grille ; rouge : bras graphe ; une
ligne par graine. Les scores excluent les parties
tronquées.](figures/fig5-per-opponent.png){#fig:per-opponent width=100%}

Les trajectoires par adversaire décomposent les courbes agrégées de
`@sec:results-cost`{=typst} : contre l'adversaire aléatoire, les graines
grille approchent tôt du plafond et y restent, tandis que les graines
graphe se dispersent largement et bougent de façon non monotone ;
contre l'heuristique et l'adversaire à recherche, les deux bras restent
dans une bande basse dont le mouvement d'une génération à l'autre est de
l'ordre du bruit lié au nombre de parties à 20 parties (les évaluations
intermédiaires ont été dimensionnées pour le suivi et non pour
l'inférence ; seules les évaluations finales à 100 parties entrent dans
les tables).
<!-- src: scripts/make_figures.py; journal/2026-09-16-h6-progress-01.md:58 -->
