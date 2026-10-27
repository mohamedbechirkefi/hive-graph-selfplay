# Une seconde étude : la comparaison sous une boucle à démarrage à chaud avec fenêtre de rejeu {#sec:study2}

La première étude a répondu à sa question dans un pipeline qui entraînait le réseau de chaque génération depuis une initialisation nouvelle, sur les seules parties de cette génération (`@sec:pipeline`{=typst}, `@sec:discussion`{=typst}). Ce chapitre rend compte d'une seconde étude, pré-enregistrée séparément, qui applique les deux remèdes usuels, poids transmis d'une génération à la suivante et entraînement sur une fenêtre de générations récentes, à l'identique aux deux bras, et demande si l'ordre des deux représentations y survit. Son protocole a été gelé le 13 octobre 2026, avant toute exécution ; sa campagne a démarré le même jour. Tout ce que la première étude avait gelé (adversaires, ouvertures, réglages d'évaluation, réseaux, décodeur) est réutilisé sans modification, de sorte que les deux études diffèrent par le régime d'entraînement et par rien d'autre.
<!-- src: docs/protocol-v2.md:3-12 -->

## Pourquoi une seconde étude {#sec:study2-why}

La réinitialisation à chaque génération de la première étude est neutre pour la comparaison, puisque les deux encodeurs ont vu exactement les mêmes enregistrements sous les mêmes conventions, mais elle borne le régime atteint : chaque réseau a appris sur les positions de 500 parties, et la force absolue après dix générations est restée proche du plafond contre l'adversaire aléatoire et autour de 0.1 contre les deux adversaires forts. La première objection d'un relecteur à la généralité d'un verdict négatif est donc que la représentation en graphe pourrait avoir besoin de plus de données par réseau, ou d'une trajectoire d'optimisation plus longue, avant que son a priori structurel ne paie. Les grands systèmes d'auto-jeu transmettent les poids de génération en génération et s'entraînent sur une fenêtre de rejeu de parties récentes ; une seconde étude sous ce régime est le test direct de l'objection. La question posée est celle de la première étude sous le nouveau régime (RQ-H1′), avec la même hypothèse (H1′) : le bras graphe atteint un score moyen plus élevé que le bras grille contre la population gelée, à budget égal. Une question secondaire, descriptive, demande si le contraste graphe−grille se rapproche de zéro ou change de signe par rapport à la première étude ; les deux études sont comparées côte à côte et jamais agrégées.
<!-- src: docs/protocol-v2.md:14-45; paper/report/16-discussion.md:205-229 -->

## Ce qui change, et ce qui ne change pas {#sec:study2-protocol}

Exactement deux choses changent, dans les deux bras. D'abord, le réseau de la génération $g$ est initialisé depuis le point de contrôle final de la génération $g-1$ (poids du modèle seulement ; l'optimiseur et le calendrier cosinus du taux d'apprentissage redémarrent à chaque génération, comme avant), la génération 0 partant de l'initialisation aléatoire ensemencée. Ensuite, la génération $g$ s'entraîne sur les enregistrements des générations $\max(0, g-2)$ à $g$, une fenêtre de rejeu de trois générations : 500 parties à la génération 0, 1,000 à la génération 1 et 1,500 à partir de la génération 2, toujours pour deux époques, de sorte que le nombre de pas de gradient croît avec la fenêtre.
<!-- src: docs/protocol-v2.md:53-60 -->

La politique d'hyperparamètres a été décidée par l'auteur au gel et enregistrée avec lui. Les deux bras conservent sans changement les réglages d'entraînement de la première étude (taux d'apprentissage 0.02, lot 256, décroissance des poids $10^{-4}$, poids de la perte de valeur 0.6, deux époques par génération, perte de politique masquée par la légalité ; 96 canaux et 8 blocs pour le réseau grille, 152 unités cachées et 8 couches pour le réseau graphe). L'alternative examinée était un budget identique et pré-enregistré de trois taux d'apprentissage (0.02, 0.01 et 0.005) pour les deux bras sur la première graine seulement, le meilleur taux par bras servant ensuite aux graines restantes. Elle a été écartée parce qu'elle aurait triplé le coût d'une graine par bras (environ quatre jours de calcul de plus), sélectionné sur une seule graine, et parce que le pilote décrit plus bas n'a montré aucun signe d'instabilité d'optimisation sous le régime à démarrage à chaud. L'objection selon laquelle les deux bras tournent sous des réglages par défaut non ajustés reste donc ouverte pour les deux études et est énoncée comme une limite.
<!-- src: docs/protocol-v2.md:62-75 -->

Tout le reste est celui de la première étude : le moteur et ses réglages de recherche (128 et 32 simulations avec randomisation du plafond de simulations, bruit d'exploration, 12 plis de température, abandon sous −0.92 avec l'audit à 10%, plafond de 300 plis), le format des enregistrements, la perte et le masquage, les deux encodeurs et réseaux à 1,443,168 et 1,465,452 paramètres, le décodeur partagé, les trois adversaires gelés, les 250 ouvertures gelées, l'évaluation épinglée (400 simulations, sans bruit, 100 parties appariées à couleurs échangées par adversaire), les statistiques (la graine comme unité, bootstrap percentile à 10,000 rééchantillonnages, ensembles de graines indépendants pour le contraste, la troncature comme issue à part entière) et la règle de rejet, qui est celle de la première étude mot pour mot dans sa forme : aucun avantage du graphe cohérent entre graines sous les deux lectures du budget, et des intervalles au niveau des graines sur la différence graphe−grille excluant un avantage graphe substantiel, la plus grande borne supérieure étant rapportée pour que le lecteur applique le seuil de son choix. Les évaluations intermédiaires sont descriptives et n'entrent dans aucun verdict. Les nouvelles exécutions utilisent les graines 11 à 15, de sorte qu'aucun flux aléatoire n'est partagé avec les graines 1 à 5 de la première étude.
<!-- src: docs/protocol-v2.md:40-51, 88-101 -->

Le plan est de nouveau deux bras, cinq graines, dix générations de 500 parties, lues deux fois. La lecture à exemples égaux compare les points de contrôle finaux. La lecture à temps mural égal compare, pour chaque exécution, le dernier point de contrôle achevé au plus tard à un seuil à temps égal défini, comme dans la première étude, par une règle indépendante des scores et écrite avant toute exécution : la médiane du temps mural total d'entraînement des cinq exécutions grille de cette étude, chaque total étant la somme des dix horloges par génération (auto-jeu, entraînement et export ; évaluations exclues), calculée une seule fois depuis les fichiers d'horloge quand les cinq exécutions grille existent et avant qu'aucun nombre inter-bras ne soit assemblé, et jamais recalculée. Le seuil de la seconde étude est sa propre valeur, mesurée sous le nouveau régime ; ce n'est pas les 18.77 h de la première.
<!-- src: docs/protocol-v2.md:105-120 -->

Les pré-engagements reprennent ceux de la première étude : les cinq graines par bras entrent dans l'analyse finale quelle que soit leur direction ; une graine n'est exclue que pour un plantage, une corruption ou une erreur du moteur, chacun consigné ; aucun adversaire, ouverture, réglage d'évaluation, hyperparamètre ou architecture n'est touché ; le chapitre est écrit depuis les tables gelées. Les règles d'arrêt sont inchangées, avec un ajout rendu explicite : une campagne en cours n'est jamais interrompue ni relancée sans l'auteur.
<!-- src: docs/protocol-v2.md:152-166, 180-184 -->

## Implémentation et vérification avant le gel {#sec:study2-implementation}

Les deux changements ont été implémentés comme deux options du pilote de campagne, identiques pour les deux bras et désactivées par défaut, de sorte que le pilote de campagne avec ses options par défaut produit toujours les commandes de la première étude. Cette propriété a été épinglée par un test de non-régression avant le gel du protocole : pour quatre exécutions de la première étude (deux par bras) et leurs dix générations chacune, la commande d'entraînement produite par défaut a été comparée à la configuration d'entraînement enregistrée de chaque génération (liste des segments, graine, nombre d'époques, absence de point de contrôle d'initialisation), et la commande d'auto-jeu au manifeste enregistré (graine, nombre de parties, budgets de simulation, indice de génération) ; les quarante générations concordent. Le même test vérifie qu'avec les deux options actives, seules la liste des segments et le point de contrôle d'initialisation changent, que la génération 0 ne démarre jamais à chaud, et que la génération $g$ s'initialise depuis la génération $g-1$. Les exécutions de la seconde étude sont écrites dans leurs propres répertoires, et chaque exécution enregistre son régime dans un fichier de configuration, de sorte que les enregistrements de la première étude ne peuvent être ni touchés ni confondus avec les nouveaux.
<!-- src: journal/2026-10-09-h9-driver-01.md:30-62 -->

Un pilote approuvé par l'auteur le 12 octobre 2026 a ensuite parcouru le chemin complet sur les deux bras, une graine hors des ensembles de graines des deux études, deux générations de 200 parties, démarrage à chaud et fenêtre de trois générations, avec une évaluation finale réduite à 20 parties par adversaire qui servait de contrôle du chemin et n'entre dans aucune analyse. Le `@tbl:study2-pilot`{=typst} donne les phases mesurées. Sur les deux bras, la seconde génération s'est entraînée depuis les poids de la première sur les segments des deux générations, comme l'enregistrent les fichiers de configuration et les journaux d'entraînement ; le temps d'entraînement a crû en proportion du nombre d'enregistrements (facteur 2.15 sur le bras grille et 2.02 sur le bras graphe à l'entrée de la seconde génération dans la fenêtre) et est resté une petite part d'une génération, parce que l'auto-jeu domine : dans la première étude, l'entraînement occupait 3% d'une exécution grille (194 à 250 s par génération) et 5% d'une exécution graphe (516 à 833 s). La fenêtre atteignant trois générations à partir de la génération 2, le temps d'entraînement sur une exécution vaut environ 2.7 fois celui de la première étude, ce qui ajoute environ une heure à une exécution grille et trois heures à une exécution graphe. Le coût projeté de la campagne est donc celui de la première étude plus cet incrément : environ 18 à 20 h par exécution grille, 30 à 53 h par exécution graphe, environ 295 h soit 12 à 13 jours de calcul séquentiel sur portable pour les dix exécutions, plus environ un jour d'évaluations.
<!-- src: journal/2026-10-12-h9-pilot-01.md:48-110; docs/protocol-v2.md:121-130 -->

| Bras | Génération | Auto-jeu (s) | Entraînement (s) | Enregistrements d'entraînement (segments) |
| --- | --- | ---: | ---: | ---: |
| grille | 0 | 2,196 | 78 | 10,188 (4) |
| grille | 1 | 2,584 | 168 | 22,399 (8) |
| graphe | 0 | 5,821 | 303 | 10,655 (4) |
| graphe | 1 | 5,800 | 613 | 21,386 (8) |

Table: Pilote de la seconde étude (12 octobre 2026) : temps mural des phases d'auto-jeu et d'entraînement de chaque génération, une graine par bras, 200 parties par génération, démarrage à chaud et fenêtre de rejeu de trois générations, sur le même portable que les campagnes. La génération 1 s'entraîne sur les enregistrements des générations 0 et 1 ; le nombre d'enregistrements d'entraînement exclut la partie de validation. L'export a pris 2 s par génération sur les deux bras. Le pilote a mesuré des coûts et exercé le chemin ; son évaluation à 20 parties n'a aucune signification statistique et n'est pas rapportée. {#tbl:study2-pilot}
<!-- src: journal/2026-10-12-h9-pilot-01.md:48-60, 80-86 -->

Les sept vérifications automatiques du pipeline (`@sec:pipeline`{=typst}) ont ensuite été passées sur l'ensemble de segments fenêtré de chaque exécution du pilote. Une vérification a échoué comme prévu. La vérification d'estampille exigeait que chaque enregistrement d'un jeu d'entraînement porte l'estampille génération-réseau d'un seul manifeste, ce qui encode l'hypothèse d'une génération par entraînement de la première étude ; sur l'ensemble fenêtré, elle a signalé des enregistrements de deux générations face à un seul manifeste. La vérification a été généralisée plutôt qu'assouplie : elle prend désormais les manifestes de chaque génération de la fenêtre et exige que l'ensemble des estampilles des enregistrements soit égal à l'ensemble des estampilles listées, de sorte que chaque enregistrement provient d'une génération listée et que chaque génération listée est présente ; elle passe toujours sur un ensemble de segments de la première étude avec un seul manifeste et échoue toujours avec un mauvais manifeste. Avec cette généralisation, toutes les vérifications ont passé sur les deux bras (normalisation de la politique sous le masque de légalité sur une passe avant réelle, légalité de toutes les cibles stockées, domaine des issues avec 17,054 des 22,856 enregistrements grille et 11,298 des 21,822 enregistrements graphe tronqués et exclus de la perte de valeur, estampilles des enregistrements, sauvegarde et reprise identiques au bit près, et séparation des entrées d'entraînement d'avec les fichiers d'évaluation).
<!-- src: journal/2026-10-12-h9-pilot-01.md:88-120; ../docs/methodology-log.md -->

## Exécution {#sec:study2-execution}

Le protocole a été gelé le 13 octobre 2026 sous son empreinte de contenu, avec la politique d'hyperparamètres, la fenêtre de trois générations et la règle de seuil décidées par l'auteur, et la campagne a été approuvée et lancée le même jour à 15:02 CET, après vérification que la machine était inoccupée, que 161 GB de disque étaient libres pour une garde de 20 GB, et que l'empreinte du protocole gelé était inchangée. Les dix exécutions se déroulent séquentiellement sur le même portable que la première étude, en alternant grille puis graphe pour chaque graine de 11 à 15, de sorte qu'une interruption laisserait aux deux bras un nombre égal de graines ; chaque exécution est reprenable à la granularité de la génération depuis ses manifestes enregistrés, et des évaluations intermédiaires de 20 parties par adversaire aux générations 5 et 8 ne servent qu'aux figures de trajectoire. Aucun autre processus lourd ne tourne sur la machine pendant la campagne, puisque les horloges par génération sont la mesure de la lecture à temps mural égal. Le `@tbl:study2-runs`{=typst} enregistre chaque exécution à son achèvement.
<!-- src: ../state/decisions.md (D-038, D-039); journal/2026-10-13-h9-campaign-01.md:40-56 -->

| Exécution | Début | Fin | Horloge d'entraînement (h) |
| --- | --- | --- | ---: |
| grille, graine 11 | 13 oct. 2026 15:02 | 14 oct. 2026 09:33 | 17.46 |
| graphe, graine 11 | 14 oct. 2026 09:33 | 16 oct. 2026 02:39 | 39.28 |
| grille, graine 12 | 16 oct. 2026 02:39 | 16 oct. 2026 21:46 | 17.95 |
| graphe, graine 12 | 16 oct. 2026 21:46 | 18 oct. 2026 13:40 | 37.33 |
| grille, graine 13 | 18 oct. 2026 13:40 | 19 oct. 2026 08:19 | 17.63 |
| graphe, graine 13 | 19 oct. 2026 08:19 | 21 oct. 2026 17:55 | 52.85 |
| grille, graine 14 | 21 oct. 2026 17:55 | 22 oct. 2026 12:18 | 17.46 |
| graphe, graine 14 | 22 oct. 2026 12:18 | 24 oct. 2026 10:44 | 42.20 |
| grille, graine 15 | 24 oct. 2026 10:44 | 25 oct. 2026 06:27 | 18.52 |
| graphe, graine 15 | 25 oct. 2026 06:27 | 26 oct. 2026 23:00 | 36.27 |

Table: Registre d'exécution de la campagne de la seconde étude : début et fin de chaque exécution (CET) et son temps mural total d'entraînement, somme des dix horloges par génération (auto-jeu, entraînement et export ; temps d'évaluation exclu). Dix générations de 500 parties par exécution, démarrage à chaud et fenêtre de rejeu de trois générations, en séquence sur un portable. {#tbl:study2-runs}
<!-- src: journal/2026-10-13-h9-campaign-01.md:58-72 -->

## Résultats {#sec:study2-results}

Chaque table de cette section montre chaque graine ; les scores excluent les parties tronquées, rapportées dans leur propre colonne ; les intervalles sont des intervalles bootstrap percentiles à 95% sur les graines (10,000 rééchantillonnages), les deux bras étant rééchantillonnés indépendamment pour les contrastes. Les tables brutes avec les colonnes de sensibilité se trouvent dans `@sec:app-d-study2`{=typst} ; la provenance de chaque nombre dans `@sec:app-e`{=typst}.
<!-- src: journal/2026-10-27-h9-analysis-01.md:34-51 -->

### Le verdict en un paragraphe

Sous les deux lectures de budget, le bras graphe ne montre aucun avantage cohérent entre graines contre aucun adversaire, et chaque intervalle sur la différence de score graphe−grille inclut zéro : les six contrastes ponctuels se situent entre −0.052 et +0.013, et les plus grandes bornes supérieures sont +0.090 à exemples égaux, contre l'adversaire de recherche, et +0.055 à temps mural égal. La première condition de la règle gelée est donc remplie sous les deux lectures. Sa seconde condition parle, comme dans la première étude, d'un avantage « substantiel » sans en chiffrer le seuil ; les bornes sont donc énoncées plutôt qu'un seuil choisi après coup : la règle rejette H1′ pour tout seuil supérieur à +0.090 ; pour les seuils compris entre +0.055 et +0.090, la lecture à temps mural égal rejette tandis que la lecture à exemples égaux laisse non exclu un avantage du graphe contre l'adversaire de recherche ; la borne réalisée de la première étude était +0.028. **H1′ n'est pas étayée** : aucun avantage du graphe n'a été détecté sous l'une ou l'autre lecture, et les données ne peuvent pas en exclure un petit, inférieur à environ 0.09, contre l'adversaire de recherche à exemples égaux. Le reste de la section présente la preuve graine par graine.
<!-- src: journal/2026-10-27-h9-analysis-01.md:95-112,186-205; results/study2/results-arm-difference.md -->

### Lecture 1 : nombre égal d'exemples d'entraînement

Les deux bras sont comparés à leurs points de contrôle de la génération 10, chaque exécution ayant engendré dix générations de 500 parties sous des budgets de simulation identiques et s'étant entraînée dessus ; sous le régime à démarrage à chaud, chaque point de contrôle a de plus hérité des poids des neuf qui le précèdent.
<!-- src: docs/protocol-v2.md:53-60,105-108 -->

| Bras | Graine | Score B-RND | Troncature B-RND | Score B-HEU | Score B-MCTS |
| --- | --- | ---: | ---: | ---: | ---: |
| grille | 11 | 0.984 | 5% | 0.040 | 0.100 |
| grille | 12 | 0.984 | 4% | 0.055 | 0.075 |
| grille | 13 | 0.995 | 1% | 0.105 | 0.175 |
| grille | 14 | 0.990 | 2% | 0.120 | 0.260 |
| grille | 15 | 0.989 | 7% | 0.065 | 0.045 |
| graphe | 11 | 1.000 | 0% | 0.125 | 0.245 |
| graphe | 12 | 0.995 | 4% | 0.030 | 0.070 |
| graphe | 13 | 0.940 | 42% | 0.080 | 0.145 |
| graphe | 14 | 0.928 | 24% | 0.030 | 0.100 |
| graphe | 15 | 0.992 | 41% | 0.105 | 0.110 |

Table: Seconde étude, lecture à exemples égaux. Score au point de contrôle final (génération 10) de chaque exécution contre chaque adversaire gelé, cinq exécutions d'entraînement indépendantes à démarrage à chaud par bras (graines 11 à 15, dix générations de 500 parties, fenêtre de rejeu de trois générations) ; 100 parties appariées à couleurs échangées par adversaire et par exécution sur les 250 ouvertures gelées, à 400 simulations par coup sans bruit d'exploration. Score = moyenne sur les parties décidées (victoire 1, nulle 0.5, défaite 0). Troncature = part des 100 parties arrêtées au plafond de 300 demi-coups ; aucune partie contre B-HEU ou B-MCTS n'a été tronquée par l'un ou l'autre bras. {#tbl:study2-same-examples}
<!-- src: results/study2/results-same-examples.md:7-16 -->

Contre l'adversaire aléatoire légal, les graines grille obtiennent de 0.984 à 0.995 et les graines graphe de 0.928 à 1.000 ; contre l'heuristique, les graines grille de 0.040 à 0.120 et les graines graphe de 0.030 à 0.125 ; contre l'adversaire de recherche, les graines grille de 0.045 à 0.260 et les graines graphe de 0.070 à 0.245. Le bras graphe tronque de 0 à 42% de ses parties contre l'adversaire aléatoire, trois graines entre 24 et 42% et deux entre 0 et 4% ; le bras grille de 1 à 7%. Les plages par graine des deux bras se recouvrent contre chaque adversaire, et la dispersion entre les graines d'un même bras contre l'adversaire de recherche (0.045 à 0.260 pour le bras grille) dépasse toute différence entre les bras. Cinq graines par bras ne peuvent pas résoudre des différences à l'intérieur d'une telle dispersion.
<!-- src: results/study2/results-same-examples.md:7-16 -->

| Bras | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grille | 0.989 [0.985, 0.992] | 0.077 [0.051, 0.104] | 0.131 [0.068, 0.200] |
| graphe | 0.971 [0.943, 0.996] | 0.074 [0.040, 0.108] | 0.134 [0.090, 0.196] |

Table: Seconde étude, lecture à exemples égaux. Score moyen au niveau des graines par bras et par adversaire, avec l'intervalle bootstrap à 95% sur les cinq graines (10,000 rééchantillonnages) ; mêmes exécutions, adversaires et volume d'évaluation que le `@tbl:study2-same-examples`{=typst}. {#tbl:study2-same-examples-means}
<!-- src: results/study2/results-same-examples.md:20-25 -->

### Lecture 2 : temps mural égal sur la même machine

Chaque exécution est prise au dernier point de contrôle qu'elle avait achevé dans le seuil à temps mural égal propre à la seconde étude, 17.63 heures, la médiane du temps mural total d'entraînement des cinq exécutions grille (17.46, 17.95, 17.63, 17.46 et 18.52 heures), calculée le 25 octobre 2026 à partir des seuls fichiers d'horloge, avant qu'aucun score de l'étude n'ait été lu, et jamais recalculée. Le seuil sélectionne les générations 10, 9, 10, 10 et 9 pour les graines grille 11 à 15, et les générations 4, 5, 3, 3 et 4 pour les graines graphe 11 à 15 (en comptant le réseau initial comme génération 1 ; dans les journaux d'exécution, ces points de contrôle sont étiquetés gen009/gen008/gen009/gen009/gen008 et gen003/gen004/gen002/gen002/gen003). Lorsque le point de contrôle au seuil est le dernier, l'évaluation finale est réutilisée ; les sept autres ensembles ont été joués après la campagne, au même volume et avec les graines de seuil épinglées.
<!-- src: journal/2026-10-25-h9-tstar-01.md:38-66; journal/2026-10-27-h9-analysis-01.md:40-46 -->

| Bras | Graine | Score B-RND | Troncature B-RND | Score B-HEU | Score B-MCTS |
| --- | --- | ---: | ---: | ---: | ---: |
| grille | 11 | 0.984 | 5% | 0.040 | 0.100 |
| grille | 12 | 0.984 | 5% | 0.060 | 0.110 |
| grille | 13 | 0.995 | 1% | 0.105 | 0.175 |
| grille | 14 | 0.990 | 2% | 0.120 | 0.260 |
| grille | 15 | 0.973 | 7% | 0.065 | 0.075 |
| graphe | 11 | 0.995 | 1% | 0.110 | 0.160 |
| graphe | 12 | 0.984 | 4% | 0.115 | 0.095 |
| graphe | 13 | 0.762 | 58% | 0.140 | 0.140 |
| graphe | 14 | 0.965 | 28% | 0.065 | 0.120 |
| graphe | 15 | 0.958 | 40% | 0.025 | 0.080 |

Table: Seconde étude, lecture à temps mural égal. Score de chaque exécution à son dernier point de contrôle achevé dans le seuil de 17.63 heures (graines grille aux générations 10, 9, 10, 10, 9 ; graines graphe aux générations 4, 5, 3, 3, 4), contre chaque adversaire gelé ; même évaluation que le `@tbl:study2-same-examples`{=typst} (100 parties appariées par adversaire, 250 ouvertures gelées, 400 simulations, sans bruit). Troncature = part des parties au plafond de 300 demi-coups ; aucune contre B-HEU ou B-MCTS. {#tbl:study2-same-wallclock}
<!-- src: results/study2/results-same-wallclock.md:7-16 -->

| Bras | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | --- | --- |
| grille | 0.985 [0.979, 0.992] | 0.078 [0.053, 0.105] | 0.144 [0.092, 0.206] |
| graphe | 0.933 [0.846, 0.986] | 0.091 [0.056, 0.124] | 0.119 [0.094, 0.144] |

Table: Seconde étude, lecture à temps mural égal. Score moyen au niveau des graines par bras et par adversaire, avec l'intervalle bootstrap à 95% sur les cinq graines (10,000 rééchantillonnages) ; mêmes exécutions et volume d'évaluation que le `@tbl:study2-same-wallclock`{=typst}. {#tbl:study2-same-wallclock-means}
<!-- src: results/study2/results-same-wallclock.md:20-25 -->

À temps égal, le bras graphe est lu à ses troisième à cinquième points de contrôle et le bras grille à son neuvième ou dixième. La moyenne du bras graphe contre l'adversaire aléatoire tombe à 0.933 [0.846, 0.986] contre 0.985 [0.979, 0.992], un écart porté par la graine 13 (0.762 avec 58% de troncature) et par les graines 14 et 15 (28% et 40% de troncature) ; contre l'heuristique, sa moyenne est de 0.091 [0.056, 0.124] contre 0.078 [0.053, 0.105], et contre l'adversaire de recherche de 0.119 [0.094, 0.144] contre 0.144 [0.092, 0.206], chaque intervalle recouvrant son homologue. Trois à cinq générations à démarrage à chaud du bras graphe atteignent donc, contre les deux adversaires forts, le niveau qu'atteignent neuf ou dix générations grille, et l'écart contre l'adversaire aléatoire est de nouveau le canal de troncature. La lecture impute au bras graphe son coût mesuré sur cette machine, 2.34 fois celui du bras grille par exécution, ce qui est son rôle ; ce qu'elle ne peut pas faire avec cinq graines, c'est séparer des moyennes dont les intervalles se recouvrent sur plus de la moitié de leur largeur.
<!-- src: results/study2/results-same-wallclock.md:7-25; results/study2/wallclock-per-run.md:7-10 -->

### Le contraste entre bras

| Adversaire | Exemples égaux : graphe − grille | Temps mural égal : graphe − grille |
| --- | ---: | ---: |
| B-RND (aléatoire légal) | −0.018 [−0.045, +0.008] | −0.052 [−0.140, +0.002] |
| B-HEU (heuristique) | −0.003 [−0.046, +0.039] | +0.013 [−0.032, +0.055] |
| B-MCTS (recherche, 6,400 simulations) | +0.003 [−0.082, +0.090] | −0.025 [−0.091, +0.034] |

Table: Seconde étude, le contraste pré-enregistré : différence des scores moyens au niveau des graines (bras graphe moins bras grille), avec l'intervalle bootstrap à 95% sur les graines (cinq graines indépendantes à démarrage à chaud par bras, rééchantillonnées indépendamment, 10,000 rééchantillonnages), par adversaire gelé et par lecture de budget. Une valeur négative favorise le bras grille. {#tbl:study2-contrast}
<!-- src: results/study2/results-arm-difference.md -->

Aucun des six contrastes n'exclut zéro. Contre l'adversaire aléatoire légal, la différence graphe−grille est de −0.018 [−0.045, +0.008] à exemples égaux et de −0.052 [−0.140, +0.002] à temps égal ; contre l'heuristique, −0.003 [−0.046, +0.039] et +0.013 [−0.032, +0.055] ; contre l'adversaire de recherche, +0.003 [−0.082, +0.090] et −0.025 [−0.091, +0.034]. Les contrastes ponctuels sont à moins de 0.05 de zéro dans cinq cellules sur six, et la sixième touche zéro à sa borne supérieure. Les intervalles sont plus larges que ceux de la première étude dans quatre des six cellules, le plus large s'étendant sur 0.17 contre l'adversaire de recherche, où les graines des deux bras s'étalent de 0.045 à 0.260.
<!-- src: results/study2/results-arm-difference.md; journal/2026-10-27-h9-analysis-01.md:95-104 -->

La première condition de la règle gelée demande l'absence d'un ordre cohérent entre graines en faveur du bras graphe. Les graines graphe surpassent les graines grille dans 3, 2 et 2 des 5 paires de même indice contre les trois adversaires à exemples égaux (13, 11 et 13 des 25 paires croisées), et dans 2, 3 et 2 sur 5 (7, 15 et 11 sur 25) à temps égal : aucun adversaire n'ordonne les graines en faveur du bras graphe sous l'une ou l'autre lecture. La seconde condition demande des intervalles excluant un avantage graphe substantiel, sans nombre attaché : la plus grande borne supérieure est +0.090 à exemples égaux et +0.055 à temps égal. Le verdict est celui énoncé en tête de la section, dans ces termes ; l'étude ne revendique aucun seuil qu'elle n'a pas pré-enregistré, et le lecteur peut appliquer celui de son choix.
<!-- src: journal/2026-10-27-h9-analysis-01.md:106-112,186-199; docs/protocol-v2.md:40-51 -->

### Troncature et lecture de sensibilité

![Seconde étude : part des 100 parties d'évaluation finale contre l'adversaire aléatoire légal (B-RND) arrêtées au plafond de 300 demi-coups, par exécution ; en bleu, les cinq graines grille (11 à 15, de gauche à droite) ; en rouge, les cinq graines graphe. Points de contrôle finaux (génération 10) de dix exécutions à démarrage à chaud, 100 parties appariées à couleurs échangées chacune sur les 250 ouvertures gelées à 400 simulations.](figures/fig7-truncation-study2.png){#fig:study2-truncation width=85%}

La troncature ne survient de nouveau que contre l'adversaire aléatoire, dans aucune des 20 cellules contre l'heuristique et l'adversaire de recherche. Aux points de contrôle finaux, le bras graphe tronque 0%, 4%, 42%, 24% et 41% de ses parties contre l'adversaire aléatoire pour les graines 11 à 15, le bras grille 5%, 4%, 1%, 2% et 7% (`@fig:study2-truncation`{=typst}) ; aux points de contrôle au seuil, 1%, 4%, 58%, 28% et 40% contre 5%, 5%, 1%, 2% et 7%. La pathologie de conversion de la première étude, présente là dans chaque graine graphe (20 à 57%), persiste dans trois graines graphe sur cinq et est absente dans deux, dont les taux se situent dans la bande du bras grille. Le score qui exclut les troncatures est proche entre les bras, mais sous le traitement de sensibilité, chaque partie tronquée comptée 0.5, la différence graphe−grille contre l'adversaire aléatoire est de −0.101 [−0.187, −0.012] à exemples égaux et de −0.131 [−0.256, −0.015] à temps égal, et les deux intervalles excluent zéro ; les quatre autres contrastes sont inchangés sous tout traitement, n'ayant aucune troncature. Sous le régime à démarrage à chaud, le déficit du bras graphe contre l'adversaire le plus faible n'est donc plus un déficit dans les parties décidées ; c'est un déficit à les décider, concentré dans trois graines.
<!-- src: journal/2026-10-27-h9-analysis-01.md:114-123; results/study2/results-same-examples.csv; results/study2/results-same-wallclock.csv -->

### Trajectoires et coût

![Seconde étude : score moyen contre la population gelée (moyenne des trois adversaires, troncatures exclues) en fonction du temps mural d'entraînement cumulé, pour les dix exécutions à démarrage à chaud ; évaluations aux générations 5, 8 et 10 (20, 20 et 100 parties par adversaire). Bleu : bras grille ; rouge : bras graphe ; une ligne par graine, étiquetée à son extrémité. La ligne verticale en pointillés marque le seuil à temps mural égal de la seconde étude, 17.63 heures.](figures/fig1-score-vs-time-study2.png){#fig:study2-score-time width=90%}

![Seconde étude : score contre chaque adversaire gelé aux générations 5, 8 et 10 (20, 20 et 100 parties appariées par adversaire), une ligne par exécution, cinq graines à démarrage à chaud par bras ; en bleu, le bras grille ; en rouge, le bras graphe ; troncatures exclues. Les points intermédiaires reposent sur 20 parties et ne servent qu'à la trajectoire.](figures/fig5-per-opponent-study2.png){#fig:study2-per-opponent width=100%}

La `@fig:study2-score-time`{=typst} place les dix exécutions sur un axe de temps commun : les exécutions grille s'achèvent entre 17.46 et 18.52 heures de temps mural d'entraînement, les exécutions graphe entre 36.27 et 52.85 heures, et au seuil les deux nuages se recouvrent en score. La `@fig:study2-per-opponent`{=typst} montre les trajectoires par adversaire ; les points intermédiaires reposent sur 20 parties et ne se lisent que pour leur forme. Les profils d'horloge d'entraînement des exécutions graphe ont pris deux formes, une montée jusqu'à un pic vers la génération 4 suivie d'une descente vers des durées proches de celles de la grille à la génération 10 pour les graines 11 et 14, et un profil plat pour les graines 12, 13 et 15 ; l'horloge par génération de la graine 13 a crû de façon monotone de 14,456 s à 21,112 s et en a fait l'exécution la plus lente de la campagne, à 52.85 heures.
<!-- src: journal/2026-10-13-h9-campaign-01.md:56-75; results/study2/wallclock-per-run.md:7-10 -->

| Métrique | Bras grille | Bras graphe |
| --- | ---: | ---: |
| Temps mural d'entraînement par exécution, graines 11 à 15 | 17.46 / 17.95 / 17.63 / 17.46 / 18.52 h | 39.28 / 37.33 / 52.85 / 42.20 / 36.27 h |
| Temps mural d'entraînement par exécution, moyenne de 5 graines | 17.80 h | 41.59 h (2.34×) |
| Coût moyen d'auto-jeu | 12.8 s/partie | 29.9 s/partie |
| Score contre la population, lecture à exemples égaux | 0.399 | 0.393 |
| Score contre la population, lecture à temps mural égal (seuil 17.63 h) | 0.402 | 0.381 |

Table: Seconde étude, résumé des coûts et des scores par bras. Le temps mural d'entraînement couvre la génération en auto-jeu, l'entraînement et l'export pour les dix générations d'une exécution, parties d'évaluation exclues, sur la machine d'étude (Apple M1 Pro, quatre threads de travail, exécutions séquentielles) ; coût d'auto-jeu = ce temps mural divisé par 5,000 parties. Score contre la population = moyenne, sur les trois adversaires gelés, du score moyen au niveau des graines, troncatures exclues. Les paramètres, l'inférence et les mesures de référence du débit sont inchangés par rapport à la première étude. {#tbl:study2-cost}
<!-- src: results/study2/wallclock-per-run.md:7-10; paper/figures/fig2-score-cost-study2.md:7-11 -->

Les dix exécutions ont consommé 296.9 heures de temps mural d'entraînement (grille 89.0 h, graphe 207.9 h), contre une projection d'environ 295 heures issue du pilote, sur un seul ordinateur portable, sans calcul payant. Le bras graphe a coûté 2.34 fois le bras grille par exécution, contre 2.04 dans la première étude : la fenêtre de rejeu ajoute du temps d'entraînement en proportion du nombre d'enregistrements sur les deux bras, et l'entraînement du bras graphe est le plus coûteux des deux. Les scores contre la population diffèrent de 0.006 à exemples égaux et de 0.021 à temps égal en faveur du bras grille, contre 0.081 et 0.079 dans la première étude.
<!-- src: results/study2/wallclock-per-run.md:7-12; paper/figures/fig2-score-cost-study2.md:7-11; paper/figures/fig2-score-cost.md:10-11; journal/2026-10-13-h9-campaign-01.md:72-75 -->

## Les deux études côte à côte {#sec:study2-interaction}

La comparaison entre les études est descriptive. Les deux études utilisent des ensembles de graines différents, deux changements de régime ont été appliqués à la fois, et aucun intervalle n'est calculé d'une étude à l'autre ; les deux jeux d'intervalles sont placés l'un à côté de l'autre et lus comme tels.
<!-- src: docs/protocol-v2.md:32-35,152-158 -->

| Adversaire | Lecture | Première étude : graphe − grille | Seconde étude : graphe − grille |
| --- | --- | ---: | ---: |
| B-RND | exemples égaux | −0.169 [−0.272, −0.062] | −0.018 [−0.045, +0.008] |
| B-HEU | exemples égaux | −0.064 [−0.111, −0.017] | −0.003 [−0.046, +0.039] |
| B-MCTS | exemples égaux | −0.009 [−0.055, +0.028] | +0.003 [−0.082, +0.090] |
| B-RND | temps mural égal | −0.161 [−0.278, −0.048] | −0.052 [−0.140, +0.002] |
| B-HEU | temps mural égal | −0.059 [−0.087, −0.029] | +0.013 [−0.032, +0.055] |
| B-MCTS | temps mural égal | −0.018 [−0.066, +0.025] | −0.025 [−0.091, +0.034] |

Table: Le contraste graphe−grille des deux études, par adversaire gelé et par lecture de budget : différence des scores moyens au niveau des graines avec l'intervalle bootstrap à 95% sur les graines (cinq graines indépendantes par bras dans chaque étude, rééchantillonnées indépendamment, 10,000 rééchantillonnages). Première étude : graines 1 à 5, le réseau de chaque génération entraîné depuis une initialisation nouvelle sur les parties de cette génération (seuil 18.77 h). Seconde étude : graines 11 à 15, démarrage à chaud et fenêtre de rejeu de trois générations (seuil 17.63 h). Les études ne sont pas agrégées. {#tbl:study1-vs-study2}
<!-- src: results/study2/study1-vs-study2.md:7-25 -->

Le contraste s'est rapproché de zéro contre chaque adversaire sous les deux lectures. Contre l'adversaire aléatoire, il est passé de −0.169 à −0.018 à exemples égaux et de −0.161 à −0.052 à temps égal ; contre l'heuristique, de −0.064 à −0.003 et de −0.059 à +0.013 ; contre l'adversaire de recherche, de −0.009 à +0.003 et de −0.018 à −0.025. Quatre contrastes qui excluaient zéro dans la première étude l'incluent dans la seconde, et le signe a changé dans deux cellules, toutes deux à l'intérieur d'intervalles qui incluent zéro. Le déficit du bras graphe de la première étude n'est plus visible à exemples égaux et est réduit à temps mural égal, où il survit sous la forme d'un intervalle touchant zéro contre l'adversaire aléatoire. Ce que la seconde étude ne montre pas, c'est un avantage quelconque du bras graphe : ses deux contrastes ponctuels positifs (+0.003 et +0.013) sont les plus petits nombres de leurs lignes.
<!-- src: results/study2/study1-vs-study2.md:7-25 -->

Les niveaux absolus des bras ont bougé dans des directions différentes. La moyenne du bras graphe contre l'adversaire aléatoire est montée de 0.812 à 0.971 à exemples égaux, là où logeait son déficit de la première étude ; ses moyennes contre l'heuristique et l'adversaire de recherche sont passées de 0.065 à 0.074 et de 0.115 à 0.134. La moyenne du bras grille contre l'heuristique est descendue de 0.129 [0.098, 0.165] à 0.077 [0.051, 0.104], deux intervalles qui ne se recouvrent pas, tandis que ses moyennes contre l'adversaire aléatoire et l'adversaire de recherche sont restées à moins de 0.01 (0.981 à 0.988 ; 0.124 à 0.131). Lu de façon descriptive, le régime à démarrage à chaud avec fenêtre de trois générations n'a pas élevé la force atteinte contre les adversaires forts en dix générations à ces réglages ; il a resserré l'écart entre les bras, et pour le bras grille contre l'heuristique il a coïncidé avec un niveau plus bas. Que ce niveau plus bas soit un effet du régime (un réseau transmis de génération en génération s'entraîne sur une fenêtre qui comprend ses propres parties antérieures) ou de l'ensemble de graines ne peut être tranché à partir de deux études de cinq graines, et l'étude ne le tranche pas.
<!-- src: results/study2/study1-vs-study2.md:7-25; results/comparison/results-same-examples.md:20-25; results/study2/results-same-examples.md:20-25 -->

![Seconde étude : exactitude top-1 de la politique en validation (à gauche) et exactitude de la valeur sur les échantillons non tronqués (à droite) après la première époque de chaque génération, telles qu'imprimées par l'entraîneur sur la partition de validation de l'ensemble d'entraînement fenêtré de la génération ; une ligne par exécution, cinq graines à démarrage à chaud par bras ; en bleu, le bras grille ; en rouge, le bras graphe. Diagnostics d'entraînement, non mesures de force.](figures/fig6-training-metrics-study2.png){#fig:study2-training width=100%}

Les diagnostics d'entraînement (`@fig:study2-training`{=typst}) séparent une exécution des neuf autres. Neuf exécutions terminent la dixième génération avec une exactitude de la valeur comprise entre 73.3% et 92.1% sur leur partition de validation ; la graine graphe 15 ne dépasse jamais 45% et termine à 35.2%, avec un top-1 de la politique qui descend de 7.9% à 4.7%, et pourtant son point de contrôle final obtient 0.992 contre l'adversaire aléatoire (41% de troncature), 0.105 contre l'heuristique et 0.110 contre l'adversaire de recherche, à l'intérieur des bandes des autres graines. Dans la première étude, l'exactitude de la valeur de chaque exécution graphe était montée dans la bande du bras grille. L'exécution est conservée, comme l'exigent les pré-engagements ; elle montre que sous ce régime un réseau peut jouer au niveau de ses pairs tout en ajustant mal ses propres données fenêtrées, et l'étude ne dispose d'aucune mesure qui l'explique.
<!-- src: journal/2026-10-27-h9-analysis-01.md:206-232 -->

Trois limites bornent cette section. Le mouvement d'une étude à l'autre n'est pas attribuable séparément au démarrage à chaud ou à la fenêtre, puisque les deux ont été appliqués à la fois, par construction. Les hyperparamètres sont les réglages par défaut non ajustés de la première étude dans les deux bras, un choix fait au gel et énoncé comme une limite des deux études ; un bras graphe ajusté, ou un bras grille ajusté, pourrait se situer ailleurs. Et dix générations restent un régime précoce : la seconde étude a rapproché le pipeline de la pratique courante des systèmes d'auto-jeu, et la force absolue contre les adversaires forts n'a pas bougé avec lui, ce qui dit que le budget, et non seulement le régime, borne ce que l'une ou l'autre représentation montre ici.
<!-- src: docs/protocol-v2.md:62-75; journal/2026-10-27-h9-analysis-01.md:166-184 -->

Dans ces limites, la seconde étude répond à l'objection qu'elle a été conçue pour tester. L'ordre de la première étude ne survit pas au régime à démarrage à chaud sous la forme d'un déficit : la représentation en graphe, transmise de génération en génération et entraînée sur une fenêtre de parties récentes, joue contre la population gelée aussi bien que la représentation en grille à exemples égaux, dans les limites d'intervalles à cinq graines, et à moins de 0.05 d'elle à temps égal, pour 2.34 fois le coût. Elle ne joue pas mieux. L'hypothèse d'origine, selon laquelle la représentation en graphe apprend une meilleure politique à budget égal, n'est étayée dans aucun des deux régimes ; ce qui a changé de l'un à l'autre est la taille de l'écart, d'un net avantage de la grille à aucun que cinq graines puissent détecter, avec une pathologie de conversion que le régime a fait disparaître dans deux graines graphe et laissée dans trois.
<!-- src: journal/2026-10-27-h9-analysis-01.md:186-205; results/study2/study1-vs-study2.md:7-25 -->
