*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Méthode — Les deux représentations (brouillon de section du rapport)

*Rédigé le 2026-09-10 à la clôture de H5 (invariant 14). Master de
travail en anglais ; copie française au jalon du rapport (D-006). Les
nombres sont traçables aux journaux `H5-2026-09-10-encoders-01` et
`H5-2026-09-10-graph-wiring-01` ; les affirmations sont enregistrées dans
`claims.md`.*

## Ce qui varie, et ce qui, de manière démontrable, ne varie pas

La variable indépendante de l'étude est la représentation d'état et son
corps de réseau — rien d'autre. Les deux bras partagent le moteur, la
recherche, les adversaires gelés et les réglages d'évaluation épinglés,
les enregistrements d'auto-jeu, les cibles d'entraînement et les
conventions d'issue, l'espace d'actions avec sa normalisation sur
l'ensemble légal, et la machinerie de la boucle d'entraînement. Chaque
élément partagé est imposé plutôt qu'affirmé : le décodeur est un contrat
unique avec masquage identique ; les enregistrements sont un format
unique ; chaque encodeur est épinglé par un test inter-langages sur
fichiers de référence (240 positions pour les plans grille, 160 pour les
tenseurs graphe, exact à l'octet près, exécuté chaque nuit) ; et les deux
bras s'évaluent via la même recherche arborescente Monte-Carlo (MCTS) en
Rust, par des exports ONNX.

## Le bras grille

La représentation de base plonge la position dans un cadre fixe 32×32 :
dépliée par BFS depuis le tore du moteur, centrée sur la boîte
englobante, avec 77 plans de caractéristiques (pièce/propriétaire/type/
hauteur conjointement, clouages, étourdissement, régions de placement, et
scalaires globaux en plans constants). Une ruche de 28 pièces plus son
anneau complet de destinations candidates tient dans le cadre par
construction ; cet argument est imposé par une assertion toujours active
et des tests extrémaux (lignes droites de 28 pièces : correspondance
complète, sans repliement) — aucune pièce ne peut disparaître
silencieusement, y compris dans les builds release. Le réseau est un
ResNet type KataGo allégé (1.44 M paramètres) avec une tête de politique
plate (emplacement de pièce × cellule du cadre).

## Le bras graphe

La représentation graphe est sans coordonnées : les nœuds sont les
cellules de l'ensemble candidat — chaque cellule occupée et chaque
cellule vide de l'anneau 1, de sorte que chaque destination pouvant être
notée est un nœud à part entière ; les arêtes sont typées par les six
directions hexagonales ; les caractéristiques de nœud portent la pile
niveau par niveau (propriétaire et type d'insecte par niveau), les
clouages, l'étourdissement et les régions de placement ; les réserves, le
trait, le numéro de demi-coup et le type de partie entrent comme vecteur
global. Les pièces ne sont pas des nœuds séparés : le décodeur partagé
adresse les coups comme (emplacement de pièce, cellule de destination),
de sorte que l'identité de la pièce entre dans la politique par un
plongement d'emplacement et par le nœud où la pièce se tient — un choix
de conception documenté, pas un accident. Le réseau est un petit réseau
relationnel à passage de messages (poids propres à chaque direction,
biais d'agrégation globale, agrégation masquée pour la tête de valeur,
notation des coups par candidat) de 1.47 M paramètres — une différence
de capacité de +1.5%, rapportée.

**Un réseau de graphe n'offre gratuitement ni invariance ni équivalence de règles.**
L'encodage ne contient aucune coordonnée absolue, mais la
fonction apprise n'en est pas pour autant invariante par translation ou
par rotation, et aucune règle de Hive n'y est câblée ; toute affirmation
de ce type dans cette étude est mesurée, jamais supposée.

## Asymétries de coût mesurées (rapportées, non égalisées)

Sur la machine d'étude, le meilleur chemin d'inférence disponible diffère
selon le bras : le réseau grille convolutif s'exécute sur l'accélérateur
CoreML à 2.62 ms/évaluation, tandis que le réseau graphe, riche en
opérations de collecte (gather), s'exécute le plus vite sur CPU à
3.67 ms (CoreML est plus lent pour lui) — un coût par décision de ≈1.4×
au détriment du bras graphe. L'entraînement montre le motif inverse selon
le périphérique (le CPU favorise le graphe 3.5× ; le chemin MPS utilisé
pour l'entraînement favorise la grille ≈2×). Ce sont de véritables
interactions matérielles des représentations ; les deux lectures
budgétaires du protocole (mêmes-exemples et même-temps-horloge) les
facturent honnêtement plutôt que de les cacher.

## Augmentation par symétries

Exclue de la méthode complète pour les deux bras (D-023) : l'exclusion
rend trivialement vraie la règle du protocole de données identiques,
évite d'implémenter les symétries hexagonales différemment selon la
représentation, et laisse l'augmentation comme une question d'ablation
additive propre.

## Limites

Les coûts sont mesurés sur une seule machine ; la validation du câblage
n'a entraîné le bras graphe qu'à l'échelle d'un test de fumée (son profil
d'apprentissage sur les données gen-0 a correspondu à celui du bras
grille, comme attendu pour des bras appariés sur données partagées — ce
n'est pas un résultat de comparaison) ; la comparaison contrôlée
elle-même est H6, sous le protocole v1.0.
