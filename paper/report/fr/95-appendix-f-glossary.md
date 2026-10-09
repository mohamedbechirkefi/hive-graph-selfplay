# Glossaire {#sec:app-f}

Les tables ci-dessous fixent les termes français utilisés dans cette édition, leur sens dans le périmètre de l'étude, et le terme anglais correspondant du master anglais. La colonne française reproduit la formulation établie dans les chapitres français ; un astérisque marque une forme composée, construite à partir d'éléments établis, que l'édition française utilise ici pour la première fois.

| Terme (français) | Définition | Équivalent anglais |
| --- | --- | --- |
| bras grille / bras graphe | Les deux systèmes comparés, identiques à l'exception de l'encodage d'état et du corps de réseau qui le lit. | grid arm / graph arm |
| encodage d'état\* | La fonction qui transforme une position en les tenseurs qu'un réseau lit ; épinglée à l'octet près entre le moteur et le code d'entraînement. | state encoding |
| décodeur d'actions partagé | Le contrat unique par lequel les deux bras émettent une politique sur les mêmes actions, à savoir (emplacement de pièce, destination) plus la passe, avec un masquage de l'ensemble légal et une normalisation identiques. | shared action decoder |
| population d'adversaires | Les trois adversaires fixes contre lesquels chaque point de contrôle est noté, gelés le 9 septembre 2026. | opponent population |
| aléatoire légal | Tirage uniforme parmi les coups légaux ; le plancher de la population. | B-RND, legal-random |
| heuristique documentée à poids fixes | Argmax glouton à un demi-coup d'une évaluation documentée à poids fixes, avec quiescence ciblant la reine. | B-HEU, heuristic |
| MCTS sans réseau à 6400 simulations | Recherche arborescente PUCT sans réseau, a priori uniformes, l'évaluation construite à la main comme valeur aux feuilles. | B-MCTS, search at 6,400 simulations |
| gelé / gelée | Fixé par une approbation datée et jamais retouché ensuite ; toute retouche ultérieure constituerait une nouvelle étude. | frozen |
| règle de rejet pré-enregistrée\* | La condition inscrite dans le protocole gelé sous laquelle l'hypothèse est rejetée : aucun avantage graphe cohérent entre graines sous les deux lectures, avec des intervalles excluant un avantage substantiel. | pre-registered rejection rule |
| graine (exécution d'entraînement indépendante) | Une exécution d'entraînement complète à partir d'une initialisation à graine fixée ; l'unité de réplication et de rééchantillonnage. | seed (independent training run) |
| génération | Un cycle d'auto-jeu, d'entraînement et d'export de point de contrôle ; dix par exécution. | generation |
| point de contrôle | Le réseau exporté à la fin d'une génération ; identifiants indexés à partir de zéro (gen000 à gen009). | checkpoint |
| parties appariées, à couleurs échangées | Chaque ligne d'ouverture jouée une fois avec chaque couleur, de sorte que tous les bras, graines et adversaires font face à des calendriers identiques. | paired colour-swapped games |
| réglages d'évaluation épinglés | 400 simulations par décision, aucun bruit d'exploration, argmax déterministe ; fixés par fichier et par test. | pinned evaluation settings |

Table: Termes du plan d'étude. {#tbl:f-design}

| Terme (français) | Définition | Équivalent anglais |
| --- | --- | --- |
| One-Hive (conservé en anglais) | Aucun coup ne peut scinder la ruche, y compris en transit ; une pièce dont le retrait la scinderait est clouée. | One-Hive rule |
| liberté de mouvement | Une pièce qui glisse ne peut passer que par un interstice dont les deux cellules adjacentes ne sont pas toutes deux occupées. | freedom to move |
| porte (porte du scarabée) | Deux cellules occupées encadrant un pas, bloquant un glissement ; au-dessus du niveau du sol, la porte du scarabée. | gate |
| empilement | Les scarabées grimpent sur les pièces, formant des piles ; seule la pièce du dessus agit. | stacking |
| étourdissement | Le marqueur porté par une pièce que vient de lancer un Pillbug, et qui ne peut pas bouger au pli suivant ; inerte dans le jeu de base. | stun |
| passe forcée | Sans coup légal, un camp doit passer ; la passe est légale exactement lorsqu'aucun coup n'existe. | forced pass |
| pli / demi-coup | Un coup d'un camp (demi-coup) ; le plafond est de 300 plis. | ply |
| ouverture | Un préfixe de quatre plis joué avant que les agents ne prennent la main ; 250 lignes gelées partagées par chaque affrontement. | opening (frozen line) |

Table: Termes de Hive. {#tbl:f-hive}

| Terme (français) | Définition | Équivalent anglais |
| --- | --- | --- |
| auto-jeu | Les parties que le réseau courant joue contre lui-même, à travers la recherche, pour produire des enregistrements d'entraînement. | self-play |
| recherche arborescente Monte-Carlo (MCTS) | La recherche des deux bras et de B-MCTS ; le réseau fournit les a priori et une valeur aux feuilles. | Monte-Carlo tree search (MCTS) |
| PUCT | La règle de sélection : maximiser Q + c·prior·√N/(1+n), c = 1.4. | PUCT |
| politique | La distribution du réseau sur les actions légales, entraînée vers la distribution de visites enregistrée. | policy |
| valeur | L'estimation par le réseau, dans [−1, 1], de l'issue pour le camp au trait ; une tête à trois classes, enregistrements tronqués exclus. | value |
| distribution de visites | Les comptes de visites à la racine, normalisés, après une recherche ; la cible de politique. | visit distribution |
| randomisation du plafond de simulations | Une fraction 0.25 des décisions d'auto-jeu reçoit 128 simulations et est enregistrée ; le reste en reçoit 32 et ne l'est pas. | playout-cap randomization |
| plis en température | Les 12 premiers plis d'une partie d'auto-jeu, échantillonnés plutôt que pris par argmax. | temperature plies |
| abandon | Une partie d'auto-jeu est abandonnée lorsque la valeur tombe sous −0.92. | resignation |
| audit sans abandon | Une fraction de 10% des parties d'auto-jeu, jouées jusqu'au bout quoi qu'il arrive, pour vérifier que l'abandon ne cache aucune victoire. | resignation audit |
| argmax de politique (top-1)\* | Métrique d'ajustement d'entraînement : part des enregistrements dont l'argmax de la politique coïncide avec l'argmax de la cible. | policy top-1 |
| exactitude de la valeur\* | Métrique d'ajustement d'entraînement : part des enregistrements dont la classe d'issue prédite est la classe enregistrée. | value accuracy |

Table: Termes de recherche et d'auto-jeu. {#tbl:f-selfplay}

| Terme (français) | Définition | Équivalent anglais |
| --- | --- | --- |
| cadre 32×32 ; plans de caractéristiques | La grille fixe dans laquelle le bras grille plonge une position, centrée sur la boîte englobante ; 77 plans de caractéristiques. | frame (32×32) |
| passage de messages | Le calcul du bras graphe : chaque nœud se met à jour à partir de ses voisins, couche par couche. | message passing |
| relations d'arêtes typées par direction | Les six directions hexagonales comme types d'arêtes, chacune avec ses propres poids. | direction-typed relations |
| biais de pooling global (biais d'agrégation globale) | Un résumé agrégé de tous les nœuds, réinjecté dans chaque nœud ; retiré dans l'ablation A2. | global-pooling bias |
| à capacité appariée | Des nombres de paramètres quasi égaux : 1.44 M (grille) et 1.47 M (graphe), +1.5%. | capacity-matched |
| adjacence naïve | Ablation A1 : les six matrices d'arêtes typées remplacées par une seule matrice partagée. | naive adjacency |
| écrêtage de gradient | L'écrêtage de la norme à 1.0 ajouté dans le supplément A1′, qui en fait une variante à deux composants. | gradient clipping |

Table: Termes de représentation et de réseau. {#tbl:f-networks}

| Terme (français) | Définition | Équivalent anglais |
| --- | --- | --- |
| troncature (partie tronquée) | Une partie arrêtée au plafond de 300 plis ; une quatrième issue, jamais repliée dans les nulles. | truncation (never "draw") |
| plafond de coups (plafond de 300 demi-coups) | La limite de 300 plis à laquelle une partie est tronquée. | move cap |
| score | Moyenne de victoire 1 / nulle 0.5 / défaite 0 sur les parties non tronquées d'une cellule (graine, adversaire). | score |
| taux de troncature\* | Part des 100 parties d'une cellule qui ont été tronquées ; toujours rapporté à côté du score. | truncation rate |
| colonne de sensibilité « troncatures à 0.5 » | La moyenne de la cellule sur toutes les parties, les troncatures comptant 0.5. | sensitivity score |
| bornes de traitement du plafond | Le contraste recalculé avec les troncatures comptées comme défaites et comme victoires, encadrant tout autre plafond. | cap-treatment bounds |
| moyenne au niveau des graines | La moyenne simple des scores de cellule par graine d'un bras contre un adversaire. | seed-level mean |
| intervalle bootstrap sur les graines | Un intervalle bootstrap percentile à 95% obtenu en rééchantillonnant les graines (jamais les parties) 10,000 fois. | seed-level bootstrap interval |
| bootstrap percentile | L'intervalle dont les extrémités sont les quantiles 0.025 et 0.975 des statistiques de rééchantillonnage triées ; sans correction de biais. | percentile interval |
| contraste entre bras | La différence graphe moins grille des moyennes au niveau des graines, avec son intervalle issu d'ensembles de graines rééchantillonnés indépendamment. | arm contrast |

Table: Termes d'issue et de statistique. {#tbl:f-statistics}

| Terme (français) | Définition | Équivalent anglais |
| --- | --- | --- |
| budget (temps mural, matériel, états d'entraînement, simulations) | Les ressources d'une exécution en quatre dénominations : temps mural, matériel, états d'entraînement, simulations. | budget |
| temps mural | Le temps réel écoulé sur la machine d'étude, journalisé par génération ; le temps mural d'entraînement d'une exécution exclut ses parties d'évaluation. | wall-clock |
| lecture à exemples égaux | La comparaison à budget d'auto-jeu égal : les points de contrôle de dixième génération des deux bras après 10 générations × 500 parties. | same-examples reading |
| lecture à temps mural égal | La comparaison à temps d'entraînement égal : le dernier point de contrôle de chaque exécution dans le seuil à temps mural égal. | same-wall-clock reading |
| seuil à temps mural égal | 18.77 h, la médiane des temps muraux d'exécution complète des trois exécutions originales du bras grille, fixée par une règle pré-enregistrée le 16 septembre 2026. | equal-time cutoff |
| simulations par décision | Le budget de recherche : 128 complètes / 32 économiques en auto-jeu, 400 en évaluation, 6,400 pour B-MCTS. | simulations per decision |

Table: Termes de budget. {#tbl:f-budget}

<!-- src: paper/fr/results-comparison.md:23-49,115-131 --> <!-- src: paper/fr/ch5-protocol.md:12-72 --> <!-- src: paper/fr/ch2-formalisation.md:24-93 --> <!-- src: paper/fr/method-representations.md:13-60 --> <!-- src: paper/fr/method-pipeline.md:11-38 --> <!-- src: paper/fr/method-baselines.md:12-47 --> <!-- src: paper/fr/annex-reproduction.md:11-21 --> <!-- src: paper/fr/annex-architectures.md:109-111 --> <!-- src: paper/fr/method-validation.md:53 --> <!-- src: paper/fr/annex-corpus.md:9,48,111-114 --> <!-- src: paper/fr/ch7-discussion.md:74-91 --> <!-- src: results/comparison/parameter-counts.md:5-11 --> <!-- src: results/comparison/wallclock-per-run.md:3 -->
