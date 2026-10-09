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
auto-jeu PUCT-MCTS, l'état étant présenté sous forme de plans spatiaux
empilés (8×8×119 pour les échecs) et la politique elle-même exprimée
spatialement — la paramétrisation grille canonique dont descend notre
bras grille. Son style de preuve, en revanche, est précisément ce dont
une étude à petit calcul doit *s'écarter* : une seule exécution
d'entraînement par jeu, des budgets libellés en matériel (5,000 TPU de
première génération) plutôt qu'en unités comparables, et une évaluation
contre un seul moteur de référence. KataGo (Wu 2020) a montré que le
coût du pipeline est compressible d'environ 50× à force égale (moins de
30 V100 pendant 19 jours contre ≈74 GPU-années pour ELF OpenGo) et a
établi le standard de rapport budgétaire — GPU-jours, parties,
échantillons, avec ablations par technique — que suit notre
comptabilité ; de ses économies nous en adoptons exactement une, la
randomisation du plafond de simulations, parce qu'elle est agnostique à
la représentation et peut être appliquée à l'identique aux deux bras,
et nous écartons délibérément les caractéristiques d'entrée propres au
go et les cibles auxiliaires qui feraient entrer en contrebande de la
connaissance du domaine dans un seul encodage. Jones (2021) a entraîné
des agents de type AlphaZero à travers plusieurs tailles de plateau de
Hex pour un total de ≈500 GPU-heures et a trouvé des frontières
calcul-performance lisses — la caution méthodologique la plus proche
pour tirer des conclusions à notre échelle — et a apporté un
avertissement que nous encodons dans le protocole : le calcul à
l'entraînement et le calcul au test s'arbitrent l'un contre l'autre,
donc les nombres de visites en évaluation doivent être épinglés, et non
laissés flottants. Agarwal et al. (2021) fournissent le cadre
statistique : dans les régimes à peu d'exécutions, les estimations
ponctuelles sur exécutions uniques s'inversent fréquemment sous une
analyse par intervalles rigoureuse ; leurs prescriptions — agréger
d'abord par exécution, rééchantillonner l'exécution, rapporter des
intervalles, ne jamais regrouper les parties comme observations
indépendantes — sont mises en œuvre ici avec, tout du long, la graine
comme unité de rééchantillonnage.

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
(2021) ont construit des agents heuristiques minimax/MCTS sur le moteur
BeeKeeper, documenté le facteur de branchement ≈60 de Hive, et constaté
qu'une caractéristique intuitivement centrale (les tuiles autour de la
reine) porte étonnamment peu de signal d'évaluation une fois réglée —
un avertissement précoce que la structure de valeur de Hive n'est pas
là où l'intuition la place ; leurs agents, comme tout agent savant pour
Hive avant les nôtres, sont restés en deçà du jeu humain fort. AZ-Hive
(de Goede et al. 2022) est le travail antérieur le plus proche et la
motivation directe de l'étude : AlphaZero sur Hive à travers un espace
de conception 5 × 2 d'encodages de plateau et d'action — tous des
tableaux denses en treillis hexagonal alimentant un CNN, aucune option
graphe nulle part dans l'espace (confirmé sur le texte intégral) — avec
ce résultat saisissant qu'après 24 h d'entraînement leur meilleur
moteur perdait encore contre un MCTS nu et un minimax (BayesElo 1063
contre 1181/1355), tandis que le choix d'encodage changeait
mesurablement la vitesse d'apprentissage initiale. C'est précisément la
prémisse de RQ-H1 : à Hive, l'encodage est porteur. Polygames (Cazenave
et al. 2020) réalise l'invariance à la taille du plateau — corps
entièrement convolutifs avec agrégation globale — mais au sein du
paradigme grille et sans prise en charge de Hive : il met à l'échelle
des plateaux à topologie fixe, ce qu'un jeu sans plateau, à empilement,
n'offre pas. Les précédents directs grille-contre-graphe sont au nombre
de deux. Keller et al. (2023) ont mené une comparaison CNN-contre-GNN à
paramètres appariés sur Hex (≈487K contre ≈481K paramètres, ≈110
A100-heures par modèle) et trouvé l'asymétrie que notre résultat
prolonge : le GNN dominait les tests de dépendances à longue portée et
transférait d'une taille de plateau à l'autre, tandis que le CNN
restait plus affûté sur les motifs locaux — mais leur comparaison
contrôlée s'est déroulée sous RainbowDQN, leur bras CNN n'a jamais été
entraîné sous auto-jeu MCTS, leur graphe est une réduction propre à Hex
au jeu de Shannon (les cellules jouées sont contractées ; les actions
sont en bijection avec les nœuds), et ils affirment eux-mêmes que la
construction ne se généralise pas à d'autres jeux. Rigaux & Kashima
(2024, NeurIPS) rapportent le signe opposé pour les échecs : un réseau
d'attention sur graphe à caractéristiques d'arêtes (GATEAU) avec une
lecture de politique fondée sur les arêtes apprend mieux que les
références CNN dans une boucle de type AlphaZero et transfère d'une
taille de plateau à l'autre — mais à partir d'une seule exécution
d'entraînement par modèle (les intervalles ne couvrent que l'estimation
Elo, pas la variance entre exécutions), avec un appariement de capacité
lâche (1.0M contre 2.2M paramètres) et un décodeur qui diffère entre
les bras, confondant la représentation avec la paramétrisation de
l'action ; notre conception élimine exactement ces trois facteurs de
confusion. Ben-Assayag & El-Yaniv (2021) ont entraîné un AlphaZero
fondé sur GIN sur des graphes de treillis d'Othello pour porter un
entraînement sur petit plateau vers des plateaux plus grands — une
affirmation de transfert sous budgets délibérément asymétriques, non
une comparaison de représentations à budget égal, quoique, de façon
notable, avec la meilleure hygiène de réplication des trois (cinq
exécutions avec erreurs types). Un projet amateur non publié (hiveGo ;
webographie) entraîne un petit GNN sur Hive avec une boucle de type
AlphaZero et ne rapporte qu'une évaluation anecdotique — aucune
comparaison contrôlée d'aucune sorte.

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
