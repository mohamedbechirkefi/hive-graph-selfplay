*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 2 — Formalisation (brouillon du livret, 2026-09-26)

*Sources : protocole gelé v1.0 (D-020) ; `docs/action-decoder.md`
(D-015) ; `docs/representations/` ; notes d'architecture du moteur.
Aucun nombre ici au-delà de ceux enregistrés.*

## 2.1 Le jeu et la variante étudiée

Hive est un jeu à deux joueurs, à information parfaite et à somme
nulle, joué sur un pavage hexagonal non borné : il n'y a pas de
plateau — les pièces en jeu définissent la surface de jeu. Nous
étudions le **jeu de base uniquement** (reine, araignées, scarabées,
sauterelles, fourmis ; 11 pièces par camp), décision D-007. Le moteur
implémente les extensions Mosquito/Ladybug/Pillbug ainsi que la
restriction d'ouverture de tournoi (pas de reine au premier tour d'un
joueur) ; le noyau est exercé par des tests sur les huit types de
partie, mais aucun résultat de l'étude ne fait intervenir une
extension.

## 2.2 État, actions, transition, résultat

Un état s comprend : les pièces placées avec leurs cellules et leurs
niveaux de pile (les scarabées peuvent grimper, produisant des piles),
les réserves, le camp au trait, le compte de plis et le marqueur
d'étourdissement `last_moved` (pertinent uniquement sous l'extension
Pillbug ; conservé pour l'uniformité du noyau — il fait partie de la
position hachée). Le moteur expose s via le Universal Hive Protocol
(UHP) ; la correction de ses règles est établie indépendamment de tout
composant d'apprentissage (chapitre 4).

Une **action** est (pièce, cellule de destination), ce qui identifie
tout coup de Hive de manière unique — les collisions
marche-contre-lancer produisent des états successeurs identiques —
plus un *passe* distingué, légal exactement lorsqu'aucun coup n'existe.
L'ensemble d'actions légales A(s) est produit par le générateur du
moteur ; les deux architectures apprises le reçoivent et normalisent
leurs politiques exactement sur A(s) (le décodeur partagé, chapitre 4).
Les transitions sont le `play` du moteur ; la partie se termine quand
une reine est entièrement encerclée (victoire pour l'adversaire ;
encerclement simultané = nulle), avec nulle additionnelle par triple
répétition.

**Résultat officiel vs troncature expérimentale.** Les parties
d'auto-jeu et d'évaluation sont arrêtées à un plafond de 300 plis. Une
partie plafonnée n'est **pas** une nulle : c'est une quatrième classe
de résultat, *tronquée*, portée à travers le format de données
(enregistrements), la perte d'entraînement (les parties tronquées sont
exclues de la cible de valeur), le lanceur de matchs, toutes les tables
(colonne de taux séparée) et l'analyse. La récompense pour
l'apprentissage est le résultat terminal du point de vue du camp au
trait : victoire +1, défaite −1, nulle 0 ; la troncature ne contribue
à aucune cible de valeur.

## 2.3 Notation de la recherche et de l'apprentissage

Les deux bras utilisent la même recherche arborescente Monte-Carlo
(MCTS) PUCT : à un nœud, un évaluateur renvoie des a priori sur A(s) et
une valeur scalaire v ∈ [−1, 1] (point de vue du camp au trait) ; la
sélection maximise Q + c·prior·√N/(1+n) avec c = 1.4 ; les valeurs
terminales remontent exactement. L'auto-jeu utilise la randomisation du
plafond de simulations (playout-cap randomization : une fraction 0.25
des décisions reçoit 128 simulations et est enregistrée ; le reste en
reçoit 32 et ne l'est pas), du bruit de Dirichlet à la racine (ε 0.25),
un échantillonnage en température sur les 12 premiers plis, et
l'abandon sous −0.92 avec une fraction d'audit sans abandon de 10%.
**L'évaluation n'applique rien de cette machinerie d'exploration**
(ε = 0, argmax déterministe ; imposé par test et épinglé par config,
D-019) et exécute 400 simulations par décision.

L'entraînement minimise une entropie croisée de politique contre les
distributions de visites MCTS enregistrées, normalisée sur l'ensemble
légal pour les deux bras, plus une perte de valeur à 3 classes
pondérée (poids 0.6) sur victoire/nulle/défaite, les échantillons
tronqués étant exclus. Les budgets sont comptabilisés en quatre
dénominations par exécution — temps mural, matériel, états
d'entraînement, simulations — et la comparaison est lue sous deux
égalisations (exemples égaux, temps mural égal), chapitre 5.

## 2.4 Vue jeu vs vue encodage

Le même état s est encodé de deux façons (figure fig3-encodings) : la
*vue grille* plonge la position dans un cadre fixe 32×32 (déroulé par
BFS depuis le plateau torique du moteur, centré sur la boîte
englobante) avec 77 plans de caractéristiques ; la *vue graphe* est
sans coordonnées — les nœuds sont les cellules occupées plus chaque
cellule vide adjacente à la ruche (exactement l'univers de destinations
du décodeur), les arêtes portent les six directions hexagonales comme
types, les piles apparaissent niveau par niveau comme caractéristiques
de nœud, et réserves/camp/pli entrent comme vecteur global. Le
chapitre 4 spécifie les deux ; rien d'autre dans le système ne diffère
entre les bras.
