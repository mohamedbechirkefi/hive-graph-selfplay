*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 5 — Protocole expérimental (brouillon du livret, 2026-09-26)

*Source d'autorité : le protocole gelé v1.0 (D-020, sha256
f340a6b6…aefeb5) et les décisions de gel et d'épinglage D-017, D-019,
D-025, D-026, D-027. Ce chapitre les reformule pour le lecteur ; le
document gelé prévaut en cas de divergence.*

## 5.1 Discipline de pré-enregistrement

Tout ce qui pouvait biaiser la comparaison a été gelé avant l'existence
de toute exécution de comparaison, dans cet ordre : population
d'adversaires (D-017), protocole avec sa règle de rejet et ses budgets
mesurés (D-020), ouvertures fixes partagées (D-025) ; les réglages
d'évaluation ont été épinglés par configuration et par test (D-019). Le
seuil à temps mural égal T\* a été calculé selon une règle énoncée dans
la matrice pré-enregistrée — la médiane des temps muraux d'exécution
complète des trois exécutions du bras grille — à partir des seuls
chronomètres de la grille, avant l'assemblage de tout nombre
inter-bras. Aucun artefact gelé n'a été modifié à aucun moment ;
l'historique du dépôt le documente.

## 5.2 Matrice, graines, matériel, budgets

2 architectures × 3 graines d'entraînement (1–3 ; espaces de graines
disjoints), 10 générations × 500 parties d'auto-jeu par exécution à 128
simulations complètes / 32 simulations économiques par décision (choix
mesurés, et non les valeurs de substitution du plan), plafond de 300
demi-coups. Une seule machine (Apple M1 Pro, 10 cœurs, 16 Go), quatre
threads de travail par exécution, exécutions séquentielles ; chaque
bras utilise son meilleur fournisseur d'inférence mesuré (grille :
CoreML à 2.62 ms/eval ; graphe : CPU à 3.67 ms/eval) — une interaction
matérielle réelle, rapportée et imputée, non neutralisée par
égalisation. Chaque exécution journalise le temps mural par génération,
les états et les simulations ; les points de contrôle sont conservés à
chaque génération.

## 5.3 Adversaires, ouvertures, appariement

La population d'évaluation est gelée : un adversaire aléatoire légal à
graine fixée (B-RND), une heuristique documentée à poids fixes (B-HEU ;
poids épinglés par hachage et imposés par test), et un MCTS sans réseau
à 6400 simulations (B-MCTS). Le point de contrôle gen-19 de la boucle
de démonstration antérieure est exclu (D-016/17). Les ouvertures sont
250 ouvertures de 4 demi-coups pré-générées, uniques et légales
(générateur à graine fixée, hachage de contenu enregistré) ; chaque
affrontement joue la paire *i* sur la ligne d'ouverture *i* avec les
couleurs inversées, de sorte que tous les bras, graines et adversaires
font face à des calendriers d'ouvertures et de couleurs identiques
(vérifié par le test de hachage du calendrier).

## 5.4 Métriques, intervalles, exclusions

Métrique primaire : le score moyen (victoire 1 / nulle 0.5 / défaite 0)
contre la population, par cellule (graine, adversaire), **en excluant
les parties tronquées**, dont le taux est toujours rapporté séparément,
avec une colonne de sensibilité « troncatures à 0.5 » et des bornes de
traitement du plafond (troncatures comptées comme défaites et comme
victoires) encadrant tout plafond alternatif. L'unité de
rééchantillonnage est la **graine** : les cellules agrègent d'abord les
parties ; les intervalles sont des bootstrap percentiles (10,000
rééchantillonnages) sur les trois graines ; le contraste entre bras
applique le bootstrap indépendamment aux ensembles de graines des deux
bras. Les parties ne sont jamais agrégées comme i.i.d. ; l'Elo, là où
l'outillage l'imprime, est descriptif seulement. La sélection des
points de contrôle est mécanique : les points de contrôle de la
génération 10 pour la lecture à exemples égaux ; le dernier point de
contrôle achevé à ≤ T\* pour la lecture à temps mural égal. **Critères
d'exclusion :** aucun n'a été nécessaire — aucune exécution n'a
échoué, aucune n'a été exclue, et un mauvais score n'est pas un critère
d'exclusion selon le protocole.

## 5.5 Matrice RQ → expérience → résultat

| RQ | Expérience | Artefact de résultat |
| --- | --- | --- |
| RQ-H1 : le bras graphe bat-il le bras grille à budget comparable ? | La matrice H6 sous les deux lectures contre la population gelée | Tables de scores par graine + contraste entre bras avec intervalles bootstrap sur les graines (results-same-examples / results-same-wallclock / results-arm-difference) ; verdict via la règle de rejet gelée |
| RQ-H2 (secondaire) : lecture par exemple vs par heure | La même campagne lue aux points de contrôle de la génération 10 vs aux points de contrôle T\* | Courbes score-vs-temps (fig1) ; table score/coût (fig2) |
| RQ-H3 (secondaire) : que contribuent les composants du graphe ? | Deux ablations à un composant à parité (A1 typage des arêtes ; A2 pooling global, substitution D-028) | Table d'ablation H-T3 (`results/ablations/`) ; supplément A1' (deux composants, clairement étiqueté) s'il est exécuté |

## 5.6 Reproduction

Chaque table et chaque figure se régénèrent par scripts à partir des
enregistrements bruts par partie (`scripts/make_results.py`,
`make_figures.py`) ; les réglages de générateur, graines et empreintes
de modèle de chaque exécution résident dans des manifestes par
exécution ; commandes, configurations et graines sont en annexe. Le
scénario de reproduction minimal (annexe) rejoue de manière
déterministe une seule partie d'évaluation enregistrée et régénère les
tables de résultats à partir des enregistrements livrés.
