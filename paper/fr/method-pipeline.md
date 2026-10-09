*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Méthode — Pipeline politique-valeur et vérifications pré-entraînement (brouillon de section du rapport)

*Rédigé le 2026-09-10 à la clôture de H4 (invariant 14). Master de
travail en anglais ; copie française au jalon du rapport (D-006). Les
nombres sont traçables aux journaux `H4-2026-09-09-coreml-fix-01` et
`H4-2026-09-10-pilot-01` ; les affirmations sont enregistrées dans
`claims.md`.*

## Le décodeur d'actions partagé

Les deux architectures émettent une politique sur le même espace
d'actions — un coup est (emplacement de pièce relatif au camp, cellule de
destination) plus la passe — avec un masquage identique de l'ensemble
légal, une normalisation sur exactement l'ensemble légal, des cibles de
distribution de visites MCTS identiques, et un départage déterministe
(`docs/action-decoder.md`, D-015). Le bras grille matérialise cet espace
comme un tenseur à 28,673 sorties sur son cadre 32×32 ; le bras graphe
(H5) note les paires candidates identiques par position, avec les
cellules de destination vides comme nœuds à part entière. Rien dans
l'interface d'actions ne diffère entre les bras ; seuls l'encodeur d'état
et la fonction de notation diffèrent — c'est le contrôle central des
facteurs de confusion de l'étude.

## Discipline des données

Les enregistrements d'auto-jeu sont versionnés et auto-descriptifs :
chacun porte l'estampille du modèle générateur (génération + hachage du
réseau), la position, la cible de distribution de visites, la liste
d'indices des coups légaux qui permet l'entraînement masqué, et une
issue à quatre valeurs — victoire, nulle, défaite ou **tronquée** (une
partie arrêtée au plafond de demi-coups n'est jamais enregistrée comme
nulle ; les enregistrements tronqués sont exclus de la perte de valeur).
Un manifeste par exécution lie chaque shard à son modèle, et l'agencement
des exécutions sépare `selfplay/` (entrées d'entraînement),
`checkpoints/` et `eval/` (jamais une entrée d'entraînement), le tout
imposé par un script d'audit.

## Sept vérifications pré-entraînement

Toutes automatisées, exécutées en une seule commande contre des shards
réels avant de faire confiance à tout entraînement : (1) la softmax
masquée place une masse exactement nulle sur les actions illégales et
somme à un sur les actions légales, sur des positions réelles via une
vraie passe avant ; (2) encode→id→decode est l'identité sur tous les
coups légaux à travers les types de partie (et les cibles stockées sont
toujours légales) ; (3) les issues sont correctes pour le joueur au
trait, pour les deux couleurs, la troncature restant distincte ; (4) un
petit lot fixe sur-apprend jusqu'à un ajustement quasi parfait
— argmax de politique 15/15, valeur 15/15, KL résiduelle 0.09 contre les
cibles douces (le critère est la KL rapportée au plancher d'entropie de
la cible : les distributions de visites douces ont une entropie
irréductible, donc « perte → 0 » est le mauvais test) ; (5)
sauvegarde/reprise reproduit un état du modèle et de l'optimiseur
identique au bit près, l'interruption préservant le calendrier de taux
d'apprentissage (LR) prévu ; (6) le bruit d'exploration est
structurellement impossible à l'évaluation (les valeurs par défaut du
chemin d'évaluation portent ε = 0, affirmé par test ; réglages épinglés
par configuration + décision D-019) ; (7) aucune partie d'évaluation ne
peut atteindre l'entraînement, par agencement et par audit.

## Pilote à petit budget

Une génération complète à partir d'une initialisation aléatoire à graine
fixée (réseau grille de 1.44M paramètres, 300 parties à 128/32
simulations avec randomisation du plafond de déroulés, playout-cap
randomization) : 17,237 positions, 56.7% des parties gen-0 tronquées
(rapportées, non repliées dans les nulles), entraînement non dégénéré
(politique au-dessus du hasard, valeur au-dessus du taux de base, pertes
décroissantes), et évaluation indépendante contre la population gelée
sous réglages épinglés : **100–0 contre l'aléatoire-légal**, 3.3% contre
l'heuristique documentée, 3.3% contre le MCTS à 6400 simulations. Le
diagnostic est net et suit l'ordre prescrit (règles, signes, recherche,
données — les trois premiers validés indépendamment en H2/H3) : après
une génération, l'écart aux adversaires forts est un écart de données et
d'itérations, et le levier indiqué est davantage de générations, pas
davantage de capacité. Confirmation budgétaire : le coût de génération
dans le pire cas (gen-0) est de ≈12 s/partie en temps horloge à
4 threads, retombant vers ≈3 s/partie à mesure que le jeu s'affine avec
un réseau entraîné.

## Limites

Une seule graine de bout en bout à l'échelle du pilote ; 30 parties
d'évaluation par adversaire ; seul le bras grille existe pour l'instant
(le bras graphe arrive en H5 contre le même contrat de décodeur) ;
l'itération gen-1+ est exercée structurellement, non exécutée.
