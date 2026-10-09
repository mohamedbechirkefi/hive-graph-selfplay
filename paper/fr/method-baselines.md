*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Méthode — Adversaires de base et population d'évaluation (brouillon de section du rapport)

*Rédigé le 2026-09-09 à la clôture de H3 (invariant 14). Master de
travail en anglais ; copie française au jalon du rapport (D-006). Les
nombres sont traçables au journal `H3-2026-09-09-baselines-01` ; les
affirmations sont enregistrées dans `claims.md`.*

## Pourquoi une population gelée

Les deux architectures sont notées par leur résultat moyen contre une
**population d'adversaires fixe, gelée avant toute exécution
d'entraînement** (protocole §4) : victoire = 1, nulle = 0.5, défaite = 0,
les troncatures étant exclues et rapportées comme un taux à part. Une
population fixée à l'avance est ce qui rend les scores comparables entre
bras, graines et budgets ; toucher un adversaire après coup déplacerait
silencieusement l'étalon de mesure, aussi la population est-elle sous
discipline de gel — elle a été gelée le 2026-09-09 avec approbation
explicite (D-017 : configurations des agents et fichier de poids par
sha256, commit du code du moteur) et aucun membre ne peut être ajouté,
retiré ou réajusté depuis. Si un nombre de type Elo est cité, il est
descriptif et relatif à cette population uniquement.

## Les trois agents

Les trois s'exécutent sur le moteur validé (le même noyau de règles que
les deux bras de l'étude) via UHP, entièrement contrôlés par graine :

- **B-RND — aléatoire-légal.** Uniforme sur les coups légaux ;
  déterministe étant donné (graine, historique de la partie). Le plancher
  et l'ancre du score.
- **B-HEU — heuristique documentée.** Argmax glouton à un demi-coup d'une
  évaluation construite à la main (sécurité de la reine dominante,
  mobilité-comme-matériel, petits termes de tempo — chaque caractéristique
  et chaque poids sont tabulés dans `docs/baselines.md`), plus la
  quiescence du moteur de recherche sur les coups ciblant la reine
  adverse. Les poids ont été hérités inchangés du moteur antérieur et
  sont épinglés par un test automatisé : aucun réglage n'a eu lieu
  pendant H3 et tout changement ultérieur casse la suite. Cela ferme par
  construction la voie du réglage-après-observation-des-résultats.
- **B-MCTS — recherche sans réseau.** Recherche arborescente Monte-Carlo
  (MCTS) PUCT avec a priori uniformes et la même évaluation construite à
  la main (écrasée par une tanh) comme valeur aux feuilles ; aucun bruit
  d'exploration à l'évaluation. Budget : 6400 simulations par décision —
  choisi à partir du coût mesuré (≈27 ms/décision en mono-thread sur la
  machine d'étude), et non des chiffres provisoires du plan.

## Vérification de la recherche avant usage

La base MCTS a été vérifiée sur un ensemble tactique annoté à la main,
écrit à partir des règles de l'éditeur (même discipline que le corpus de
validation du moteur, consigné par commit avant toute exécution) : mat en
1 par marche sur le périmètre et par saut de sauterelle, pour les deux
couleurs, et un cas d'évitement d'auto-encerclement —
5/5 à 400, 1600 et 6400 simulations. Les signes de la valeur sous
alternance des joueurs sont épinglés par des tests automatisés à trois
niveaux : l'évaluation se nie exactement quand le trait change de camp ;
l'alpha-bêta note un mat en 1 au-dessus du seuil de mat pour le joueur au
trait, quelle que soit la couleur qui joue ; la valeur à la racine du MCTS
est fortement positive pour le joueur au trait gagnant, quelle que soit la
couleur qui joue.

## Caractérisation

100 parties appariées, à couleurs échangées, par confrontation, à partir
d'ouvertures aléatoires communes à graine fixée, les troncatures étant
rapportées séparément (aucune sur 300 parties) :

| Confrontation | V/N/D | Score | Elo (descriptif) |
| --- | --- | --- | --- |
| B-HEU vs B-RND | 100/0/0 | 100.0% | ≈+2400 |
| B-MCTS vs B-RND | 99/1/0 | 99.5% | +920 [+730, +1200] |
| B-MCTS vs B-HEU | 23/29/48 | 37.5% | −89 [−150, −32] |

Un ordre nous a surpris et est rapporté tel que constaté : la recherche à
6400 simulations se situe *en dessous* de l'heuristique à un demi-coup.
Diagnostic (étayé par un sondage à budget 4× atteignant 56.2%) : avec des
a priori uniformes, 6400 simulations réparties sur le facteur de
branchement de ~60 coups de Hive produisent une recherche effectivement
peu profonde, tandis que la quiescence de l'agent glouton ciblant la
reine est tactiquement tranchante — un écho de la littérature, où la
recherche simple et les heuristiques sont fortes à Hive
(de Goede et al. 2022 ; Kampert et al. 2021). Aucun réajustement n'a
suivi l'observation ; la population couvre délibérément un plancher plus
deux adversaires de bande intermédiaire, de styles différents, séparés
d'environ 90 Elo.

## Limites

Le volume de caractérisation est celui du pilote, 100 parties par
confrontation, avec un intervalle en approximation non appariée ;
l'ensemble tactique (5 cas) et ses annotations n'ont pas été relus par un
lecteur externe connaisseur de Hive — la même limite déclarée que pour le
corpus de validation du moteur.
