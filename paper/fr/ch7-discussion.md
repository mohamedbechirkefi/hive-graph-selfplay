*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 7 — Discussion et menaces à la validité (brouillon du livret, 2026-09-26)

*Découpage en quatre volets selon plan ch. 21. Ancré dans le registre
des affirmations.*

## 7.1 Lire le résultat

H1 a été rejetée exactement comme le protocole gelé définissait le
rejet. Trois observations donnent au résultat sa texture. Premièrement,
le déficit est modelé par l'adversaire : le plus grand contre
l'aléatoire légal, net contre l'heuristique, absent contre le B-MCTS
riche en recherche — cohérent avec un bras graphe qui est le plus
faible en *conversion tactique locale* plutôt qu'en jugement
positionnel. Deuxièmement, le canal de troncature porte le mécanisme :
le bras graphe gagne du matériel contre l'aléatoire puis échoue à
conclure (20–57% de parties plafonnées ; fig4-F1), un motif invisible
dans les études qui replient les plafonds en nulles. Troisièmement, les
ablations affinent la lecture : retirer le typage géométrique des
arêtes n'affaiblit pas simplement le bras graphe — aux réglages de
parité, cela détruit d'emblée l'entraînabilité (divergence NaN,
génération 0, 3/3 graines), de sorte que les relations typées portent
au minimum la stabilité d'optimisation du bras entier — tandis que la
seconde ablation a trouvé le biais de pooling global entièrement
dispensable (variations de score ≈0.00 ± 0.17, −0.01 ± 0.04, −0.01 ±
0.03 contre les trois adversaires ; modes de défaillance inchangés),
localisant la machinerie distinctive du bras dans les relations
directionnelles, non dans le pooling. Cela contraste de manière
instructive avec le résultat positif aux échecs de Rigaux & Kashima
(2024, NeurIPS) et l'asymétrie de Keller et al. (2023) sur Hex : notre
résultat ne les contredit pas — il borne là où leur optimisme se
transfère, et la comparaison des standards de preuve importe : le
résultat aux échecs repose sur une seule exécution d'entraînement par
modèle avec des intervalles couvrant la seule estimation Elo, tandis
que le présent rejet est cohérent entre graines sur cinq exécutions
par bras sous deux lectures de budget pré-enregistrées. La tactique de
Hive est dominée par la géométrie d'encerclement à courte portée, le
régime où Keller et al. ont trouvé les CNN plus forts ; aux petits
budgets, ce régime décide des parties.

## 7.2 Validité interne (bogues, comparabilité)

Le moteur est validé indépendamment de l'apprentissage (perft jusqu'à
la profondeur 6+ contre des tables publiées, conformité UHP 21/21,
accord différentiel sur 27,829 positions avec deux moteurs de
référence, un corpus annoté à la main dérivé des règles, des sessions
d'invariants à 10.9M transitions). Les deux encodeurs sont épinglés à
l'octet près contre des goldens inter-langages exécutés chaque nuit.
Les bras partagent le décodeur, les enregistrements, les fonctions de
perte, les budgets et la recherche ; la capacité diffère de +2.1%
(rapporté). Risques résiduels : l'architecture graphe est UN point de
l'espace de conception — un GNN plus fort pourrait se comporter
différemment (nous n'affirmons rien au-delà de ce réseau) ; des défauts
d'outillage trouvés pendant l'étude (un chemin de perte
d'enregistrements d'arène sur les affrontements entièrement tronqués ;
un passage NaN silencieux dans l'entraînement d'ablation) ont été
attrapés par la discipline de vérification, corrigés, et audités comme
ayant laissé les données de campagne intactes — mais ils illustrent
que l'erreur de harnais, et non le hasard, est le mode de défaillance
dominant à cette échelle.

## 7.3 Validité de mesure (adversaires, troncature)

La population est constituée de trois adversaires fixes couvrant une
force du plancher au niveau intermédiaire ; tous les bras entraînés
perdent encore lourdement contre les deux lignes de base fortes, de
sorte que la comparaison vit dans un régime de scores bas où les
différences contre B-MCTS sont difficiles à résoudre. Les scores sont
relatifs à CETTE population — aucune affirmation de force universelle
n'est faite. La troncature est traitée comme une issue à part entière
avec des bornes de sensibilité ; le plafond de 300 demi-coups lui-même
ne peut pas renverser le verdict (la borne « troncatures comptées
comme victoires » reste négative), mais les taux élevés de troncature
du graphe signifient que son score contre l'adversaire aléatoire est
mesuré sur moins de parties décidées (43–80 par graine).

## 7.4 Validité statistique (graines, dépendances)

Cinq graines par bras bornent les statistiques — l'extension
pré-engagée de trois à cinq graines (D-031) a resserré quatre des six
intervalles et absorbé les graines les plus favorables au graphe
observées sans changer le verdict ; le contraste B-MCTS reste
indiscernable de zéro sous les deux lectures. Le rejet ne repose pas
sur un seul intervalle : il repose sur la cohérence entre graines à
travers deux adversaires et deux lectures simultanément, plus l'analyse
des bornes.
Les ouvertures sont partagées entre les bras (l'appariement est
respecté dans le plan d'expérience) ; le contraste entre bras applique
le bootstrap aux graines, non aux parties ; aucune pseudo-réplication
au niveau des parties n'entre dans aucun intervalle.

## 7.5 Validité externe (variante, matériel, budget)

Une variante (Hive de base), une machine, un petit budget (10
générations × 500 parties ; ~18–48 h/exécution), auto-jeu en régime
précoce tout du long. L'asymétrie de fournisseur (CoreML favorise le
réseau convolutif ; le GNN riche en opérations de collecte (gather)
s'exécute le plus vite sur CPU) est une propriété authentique du
matériel de déploiement, rapportée et imputée — sur d'autres
accélérateurs, la lecture à temps mural pourrait se déplacer. Rien ici
ne se généralise à d'autres jeux, de plus grands budgets ou des
architectures de graphe plus riches ; l'étude répond à sa question
pré-enregistrée à l'intérieur de son périmètre pré-enregistré, et la
réponse négative est le produit : le choix d'encodage importe (comme
AZ-Hive l'a constaté), et pour Hive à petit budget il favorise la
grille.
