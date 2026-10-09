*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 3 — Travaux connexes et positionnement (brouillon du livret, 2026-09-26)

*Sources : `docs/reading/` (notes vérifiées ; une ligne par travail
dans `docs/reading/matrix.md`) ; décision D-009 (affirmation à portée
délimitée). Seules les sources notées et effectivement consultées sont
citées ; les métadonnées complètes vivent dans la
bibliographie/webographie.*

## 3.1 L'apprentissage par renforcement en auto-jeu à grande échelle — et à petite échelle

AlphaZero (Silver et al. 2017/2018) a fixé le gabarit algorithmique
dont hérite cette étude : un réseau politique-valeur guidant un
auto-jeu PUCT-MCTS. Son rapport budgétaire, toutefois, est libellé en
matériel et issu d'une exécution unique — précisément ce qu'une étude
à petit calcul et multi-graines doit améliorer. KataGo (Wu 2020) a
montré que le coût du pipeline est fortement compressible et a établi
le standard de rapport budgétaire (GPU-jours, parties, échantillons)
que suit notre comptabilité ; ses économies agnostiques à la
représentation (randomisation du plafond de simulations) sont
appliquées à l'identique aux deux bras ici. Jones (2021) a démontré que
des expériences de type AlphaZero délibérément petites sur Hex
produisent un signal conforme à des lois et extrapolable — la caution
méthodologique la plus proche de notre cadre — et a fourni le style de
rapport en frontière de calcul, sans jamais faire varier la
représentation. Agarwal et al. (2021) fournissent le cadre
statistique : les régimes à peu d'exécutions exigent un
rééchantillonnage au niveau des graines et un rapport par intervalles,
que notre protocole adopte avec la graine comme unité.

## 3.2 Représentations en graphe et espaces d'actions variables

GraphSAGE (Hamilton et al. 2017) fonde la famille inductive à passage
de messages dont relève notre bras graphe ; GraphSAGE vanille est
dépourvu de sémantique d'arêtes, que nos relations typées par direction
ajoutent. Les Pointer Networks (Vinyals et al. 2015) justifient le
scorage d'un ensemble variable de candidats — notre décodeur partagé
score exactement les paires légales (pièce, destination), les cellules
de destination vides étant des objets scorables à part entière. Les
réseaux MDP-homomorphes (van der Pol et al. 2020) ne motivent que la
question de symétrie *si le temps le permet* ; conformément au
protocole, aucune invariance n'est présumée d'un GNN, et aucune n'a été
revendiquée.

## 3.3 Hive et comparaisons grille-contre-graphe

La littérature savante sur l'IA pour Hive est mince. Kampert et al.
(2021) ont construit des agents heuristiques minimax/MCTS (BeeKeeper)
et documenté le facteur de branchement ~60 de Hive ainsi que la
faiblesse des signaux d'évaluation naïfs. AZ-Hive (de Goede et al.
2022) est le travail antérieur le plus proche : AlphaZero sur Hive à
travers cinq encodages de plateau — tous grille dense/CNN, aucun bras
graphe — avec des moteurs restés en deçà de la recherche pure ; sa
conclusion que le choix d'encodage affecte fortement l'apprentissage
est une motivation directe de RQ-H1. Polygames (Cazenave et al. 2020)
réalise l'invariance à la taille du plateau au sein du paradigme grille
et ne prend pas Hive en charge. Les précédents directs
grille-contre-graphe sont Keller et al. (2023) — CNN-contre-GNN à
paramètres appariés sur Hex, mais sous RainbowDQN (le bras CNN n'a
jamais été entraîné sous auto-jeu MCTS) et avec un graphe de jeu de
Shannon propre à Hex — et Rigaux & Kashima (2024, NeurIPS), un GAT à
caractéristiques d'arêtes pour les échecs rapportant des gains du GNN
dans une boucle de type AlphaZero — à partir d'une seule exécution
d'entraînement par modèle, sans réplication de graines. Ben-Assayag &
El-Yaniv (2021) ont entraîné un GNN-AlphaZero sur Othello pour le
passage à l'échelle en taille, non pour une comparaison de
représentations à budget apparié. Un projet amateur non publié
(hiveGo ; webographie) entraîne un petit GNN sur Hive avec une boucle
AlphaZero, sans comparaison contrôlée.

## 3.4 Positionnement

Aucun travail antérieur n'exécute de comparaison grille-contre-graphe
contrôlée et à budget apparié pour Hive avec les deux bras sous le même
pipeline d'auto-jeu ; c'est la contribution à portée délimitée de cette
étude (D-009) — délibérément *pas* « la première comparaison
grille-contre-graphe dans un jeu de plateau », ce que Keller et al. et
Rigaux & Kashima excluent. La portée se délimite comme suit : une
variante (Hive de base), un réseau grille et un GNN relationnel simple
à capacité appariée, une machine, adversaires/ouvertures/protocole
gelés, deux lectures budgétaires, cinq graines par bras. À l'intérieur
de ce périmètre, la comparaison est tranchée (chapitre 6) ; en dehors,
rien n'est affirmé. Le contraste avec le résultat positif de Rigaux &
Kashima aux échecs et avec l'asymétrie longue-portée-contre-locale de
Keller et al. est repris dans la discussion.
