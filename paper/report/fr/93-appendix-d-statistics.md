# Procédures statistiques et tables de résultats brutes {#sec:app-d}

Cette annexe énonce les estimateurs de l'étude exactement tels qu'ils ont été calculés et reproduit, sans arrondi ni recalcul, chaque nombre par exécution qui sous-tend la comparaison principale et les ablations. Les valeurs sont copiées depuis les fichiers de résultats régénérés et depuis les relevés d'analyse datés ; lorsqu'un relevé n'énonce pas une quantité, la cellule le dit.

## Score, taux de troncature et score de sensibilité

Un affrontement d'évaluation entre un point de contrôle et un adversaire compte 100 parties sur les lignes d'ouverture gelées, chaque ligne étant jouée une fois avec chaque couleur. Une partie se termine par une victoire, une nulle, une défaite ou une troncature au plafond de 300 demi-coups. Des lignes de parties d'une cellule (graine, adversaire) sont dérivées trois statistiques : le **score**, moyenne de victoire = 1, nulle = 0.5, défaite = 0 sur les parties *non tronquées* ; le **taux de troncature**, nombre de parties tronquées divisé par les 100 parties jouées ; et le **score de sensibilité**, moyenne sur *toutes* les 100 parties, chaque partie tronquée comptant 0.5, rapporté comme colonne et jamais utilisé comme métrique primaire. Les parties sont d'abord agrégées en un score par cellule ; la graine est l'unité de chaque étape ultérieure, et aucune partie n'entre dans aucun intervalle comme observation indépendante. <!-- src: scripts/analyze_comparison.py:8-14,48-59 --> <!-- src: scripts/make_results.py:13-16 --> <!-- src: results/comparison/opponents-manifest.md:42-44 -->

## Le bootstrap au niveau des graines

Chaque intervalle du rapport est un bootstrap percentile dont l'unité de rééchantillonnage est la graine, c'est-à-dire une exécution d'entraînement indépendante. Pour une série de cellule $s_1, \dots, s_n$ (un score par graine, avec $n$ = 5 dans l'analyse finale et $n$ = 3 dans l'analyse du 19 septembre 2026), la procédure tire $n$ indices uniformément avec remise, moyenne les scores correspondants, répète cette opération $B$ = 10,000 fois, trie les moyennes de rééchantillonnage et rapporte les éléments situés aux positions (indexées à partir de zéro) $\lfloor 0.025\,B \rfloor$ et $\lfloor 0.975\,B \rfloor$ comme intervalle à 95%. Aucune correction de biais ni accélération n'est appliquée ; l'estimation ponctuelle imprimée à côté de chaque intervalle est la moyenne simple des $n$ scores par graine. Le générateur pseudo-aléatoire est le `random.Random` de Python, initialisé avec la constante 0 à chaque appel, de sorte que chaque intervalle est reproductible au dernier chiffre près à partir des mêmes entrées par graine. <!-- src: scripts/make_results.py:79-84 --> <!-- src: scripts/analyze_comparison.py:87-97 -->

Le contraste entre bras est la différence des moyennes au niveau des graines, graphe moins grille. Dans chacun des $B$ = 10,000 rééchantillonnages, l'ensemble de graines du graphe et l'ensemble de graines de la grille sont rééchantillonnés *indépendamment*, chacun avec sa propre taille, et la différence des deux moyennes de rééchantillonnage est enregistrée ; les différences triées sont coupées aux deux mêmes positions. Les graines sont indépendantes entre bras par construction (la graine $k$ d'un bras ne partage rien avec la graine $k$ de l'autre au-delà des ouvertures et des adversaires gelés), de sorte qu'aucun appariement entre bras n'est imposé. Le même estimateur sert pour des ensembles de graines de tailles inégales : le supplément A1′ (trois graines) contre le bras graphe complet (cinq graines) rééchantillonne respectivement trois et cinq scores. <!-- src: scripts/make_results.py:87-94,145-155 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:22-37 -->

```
procédure PERCENTILE-CI(x[1..n]; B = 10,000; seed = 0)
    rng <- Random(seed)
    for b in 1..B:
        m[b] <- mean of n draws x[rng.randrange(n)]
    sort m ascending
    retourner m[floor(0.025 * B)], m[floor(0.975 * B)]       # positions indexées à partir de zéro

procédure DIFF-CI(a[1..p], c[1..q]; B = 10,000; seed = 0)   # a = graphe, c = grille
    rng <- Random(seed)
    for b in 1..B:
        d[b] <- (mean of p draws a[rng.randrange(p)]) - (mean of q draws c[rng.randrange(q)])
    sort d ascending
    retourner d[floor(0.025 * B)], d[floor(0.975 * B)]
```

<!-- src: scripts/make_results.py:79-94 -->

## Tables brutes par graine : lecture à exemples égaux

La lecture à exemples égaux évalue le point de contrôle de chaque exécution après la dixième et dernière génération (les identifiants de points de contrôle sont indexés à partir de zéro, il s'agit donc de gen009), chaque exécution ayant consommé le même budget d'auto-jeu de 10 générations × 500 parties. Le `@tbl:d-se-scores`{=typst} donne les scores et le taux de troncature contre l'aléatoire légal ; le `@tbl:d-sens`{=typst}, placé après la seconde lecture, donne les scores de sensibilité contre l'aléatoire légal sous les deux lectures ; l'aléatoire légal est le seul adversaire contre lequel une partie a été tronquée. <!-- src: results/comparison/results-same-examples.md:1-16 --> <!-- src: scripts/make_results.py:65-69 -->

| Bras | Graine | Score B-RND | Tronc. B-RND | Score B-HEU | Score B-MCTS |
| --- | --- | ---: | ---: | ---: | ---: |
| grille | 1 | 0.995 | 0 % | 0.150 | 0.125 |
| grille | 2 | 0.975 | 1 % | 0.080 | 0.125 |
| grille | 3 | 0.990 | 1 % | 0.190 | 0.075 |
| grille | 4 | 0.949 | 11 % | 0.105 | 0.085 |
| grille | 5 | 0.995 | 0 % | 0.120 | 0.210 |
| graphe | 1 | 0.733 | 57 % | 0.025 | 0.115 |
| graphe | 2 | 0.981 | 20 % | 0.050 | 0.125 |
| graphe | 3 | 0.722 | 55 % | 0.090 | 0.100 |
| graphe | 4 | 0.688 | 44 % | 0.125 | 0.120 |
| graphe | 5 | 0.935 | 23 % | 0.035 | 0.115 |

Table: Scores par exécution, lecture à exemples égaux : le point de contrôle de dixième génération de chacune des cinq exécutions d'entraînement indépendantes par bras (10 générations × 500 parties d'auto-jeu chacune), 100 parties appariées, à couleurs échangées, par adversaire sur les ouvertures gelées à 400 simulations par décision, contre la population gelée (B-RND aléatoire légal, B-HEU heuristique, B-MCTS recherche à 6,400 simulations). Score = moyenne de victoire 1 / nulle 0.5 / défaite 0 sur les parties non tronquées (une fraction) ; tronc. = part des 100 parties arrêtées au plafond de 300 demi-coups, 0 % contre B-HEU et B-MCTS dans chaque cellule et omise. Valeurs brutes, sans intervalle. {#tbl:d-se-scores}

<!-- src: results/comparison/results-same-examples.md:5-16 -->

## Tables brutes par graine : lecture à temps mural égal

La lecture à temps mural égal évalue le dernier point de contrôle de chaque exécution achevé dans le seuil à temps mural égal (`@sec:app-d-cutoff`{=typst}). Lorsque ce point de contrôle est le dernier de l'exécution, l'ensemble d'évaluation final sert aux deux lectures, de sorte que les lignes grille des graines 1, 2, 4 et 5 sont identiques dans les deux lectures. <!-- src: scripts/make_results.py:47-76 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:22-29 -->

| Bras | Graine | Point de contrôle | Score B-RND | Tronc. B-RND | Score B-HEU | Score B-MCTS |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| grille | 1 | gen009 | 0.995 | 0 % | 0.150 | 0.125 |
| grille | 2 | gen009 | 0.975 | 1 % | 0.080 | 0.125 |
| grille | 3 | gen008 | 0.939 | 1 % | 0.145 | 0.080 |
| grille | 4 | gen009 | 0.949 | 11 % | 0.105 | 0.085 |
| grille | 5 | gen009 | 0.995 | 0 % | 0.120 | 0.210 |
| graphe | 1 | gen003 | 0.798 | 58 % | 0.045 | 0.075 |
| graphe | 2 | gen004 | 0.926 | 39 % | 0.055 | 0.110 |
| graphe | 3 | gen004 | 0.713 | 53 % | 0.060 | 0.105 |
| graphe | 4 | gen002 | 0.631 | 39 % | 0.100 | 0.150 |
| graphe | 5 | gen005 | 0.980 | 24 % | 0.045 | 0.095 |

Table: Scores par exécution, lecture à temps mural égal : pour chacune des cinq exécutions d'entraînement indépendantes par bras, le dernier point de contrôle achevé dans les 18.77 h de temps mural d'entraînement cumulé (identifiants indexés à partir de zéro ; gen009 est la dixième génération), 100 parties appariées, à couleurs échangées, par adversaire sur les ouvertures gelées à 400 simulations par décision, contre la population gelée (B-RND aléatoire légal, B-HEU heuristique, B-MCTS recherche à 6,400 simulations). Score = moyenne de victoire 1 / nulle 0.5 / défaite 0 sur les parties non tronquées (une fraction) ; tronc. = part des 100 parties arrêtées au plafond de 300 demi-coups, 0 % contre B-HEU et B-MCTS dans chaque cellule et omise. Valeurs brutes, sans intervalle. {#tbl:d-swc-scores}

<!-- src: results/comparison/results-same-wallclock.md:5-16 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:26-29 -->

| Bras | Graine | Exemples égaux : sens. B-RND | Temps mural égal : sens. B-RND |
| --- | --- | ---: | ---: |
| grille | 1 | 0.9950 | 0.9950 |
| grille | 2 | 0.9700 | 0.9700 |
| grille | 3 | 0.9850 | 0.9350 |
| grille | 4 | 0.9000 | 0.9000 |
| grille | 5 | 0.9950 | 0.9950 |
| graphe | 1 | 0.6000 | 0.6250 |
| graphe | 2 | 0.8850 | 0.7600 |
| graphe | 3 | 0.6000 | 0.6000 |
| graphe | 4 | 0.6050 | 0.5800 |
| graphe | 5 | 0.8350 | 0.8650 |

Table: Scores de sensibilité contre l'aléatoire légal (B-RND) sous les deux lectures, pour les mêmes exécutions, points de contrôle et volume d'évaluation que les `@tbl:d-se-scores`{=typst} et `@tbl:d-swc-scores`{=typst} : la moyenne sur toutes les 100 parties de la cellule, chaque partie tronquée comptant 0.5, à la précision de quatre décimales des fichiers de résultats à valeurs séparées par des virgules. Contre B-HEU et B-MCTS, aucune partie d'aucune exécution n'a été tronquée sous l'une ou l'autre lecture, de sorte que le score de sensibilité y est égal au score des tables principales dans chaque cellule. Valeurs brutes, sans intervalle. {#tbl:d-sens}

<!-- src: results/comparison/results-same-examples.csv:2-31 --> <!-- src: results/comparison/results-same-wallclock.csv:2-31 -->

## Moyennes au niveau des graines, intervalles et contrastes entre bras

Le `@tbl:d-means`{=typst} donne la moyenne des cinq scores par graine pour chaque bras, adversaire et lecture, avec son intervalle bootstrap sur les graines ; le `@tbl:d-contrast`{=typst} donne les différences graphe moins grille de ces moyennes. Ce sont les nombres finaux de l'étude. <!-- src: results/comparison/results-same-examples.md:18-25 --> <!-- src: results/comparison/results-same-wallclock.md:18-25 --> <!-- src: results/comparison/results-arm-difference.md:1-15 -->

| Lecture | Bras | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | ---: | ---: | ---: |
| exemples égaux | grille | 0.981 [0.964, 0.994] | 0.129 [0.098, 0.165] | 0.124 [0.087, 0.168] |
| exemples égaux | graphe | 0.812 [0.710, 0.920] | 0.065 [0.034, 0.100] | 0.115 [0.107, 0.121] |
| temps mural égal | grille | 0.971 [0.950, 0.991] | 0.120 [0.098, 0.142] | 0.125 [0.090, 0.168] |
| temps mural égal | graphe | 0.810 [0.697, 0.922] | 0.061 [0.047, 0.081] | 0.107 [0.087, 0.130] |

Table: Scores moyens au niveau des graines des deux bras contre chaque adversaire gelé sous les deux lectures de budget (exemples égaux : points de contrôle de dixième génération après 10 générations × 500 parties ; temps mural égal : dernier point de contrôle dans les 18.77 h), cinq exécutions d'entraînement indépendantes par bras, 100 parties appariées, à couleurs échangées, par adversaire et par exécution. Chaque entrée est la moyenne simple des cinq scores par exécution (fraction des parties décidées, troncatures exclues) avec son intervalle bootstrap percentile à 95% sur les graines (10,000 rééchantillonnages). {#tbl:d-means}

<!-- src: results/comparison/results-same-examples.md:20-25 --> <!-- src: results/comparison/results-same-wallclock.md:20-25 -->

| Adversaire | Exemples égaux : graphe − grille | Temps mural égal : graphe − grille |
| --- | ---: | ---: |
| B-RND | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| B-HEU | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| B-MCTS | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

Table: Contraste entre bras : différence des moyennes au niveau des graines du `@tbl:d-means`{=typst}, bras graphe moins bras grille, par adversaire gelé et par lecture de budget, cinq exécutions d'entraînement indépendantes par bras ; unité : différence de score (fraction des parties décidées). Entre crochets : intervalle bootstrap percentile à 95% obtenu à partir des cinq graines du graphe et des cinq graines de la grille rééchantillonnées indépendamment, 10,000 rééchantillonnages. {#tbl:d-contrast}

<!-- src: results/comparison/results-arm-difference.md:5-7,13-15 -->

Les graines ont été collectées en deux étapes : les graines 1–3 des deux bras lors de la campagne du 10 au 17 septembre 2026, analysées le 19 septembre 2026 ; les graines 4–5 des deux bras entre le 27 septembre et le 2 octobre 2026, sous un engagement, pris avant leur exécution, d'utiliser les cinq graines dans l'analyse finale quelle que soit leur direction. Le `@tbl:d-three-seed`{=typst} consigne l'analyse à trois graines afin que les deux étapes figurent au dossier ; l'extension a resserré quatre des six intervalles de contraste, et la plus grande borne supérieure de tout contraste est passée de +0.035 à +0.028. <!-- src: journal/2026-10-09-h6-5seed-final-01.md:4-13,59-67 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:49-62,92-96 -->

| Quantité | Lecture | vs B-RND | vs B-HEU | vs B-MCTS |
| --- | --- | ---: | ---: | ---: |
| moyenne grille | exemples égaux | 0.987 [0.975, 0.995] | 0.140 [0.080, 0.190] | 0.108 [0.075, 0.125] |
| moyenne graphe | exemples égaux | 0.812 [0.722, 0.981] | 0.055 [0.025, 0.090] | 0.113 [0.100, 0.125] |
| moyenne grille | temps mural égal | 0.970 [0.939, 0.995] | 0.125 [0.080, 0.150] | 0.110 [0.080, 0.125] |
| moyenne graphe | temps mural égal | 0.812 [0.713, 0.926] | 0.053 [0.045, 0.060] | 0.097 [0.075, 0.110] |
| graphe − grille | exemples égaux | −0.175 [−0.268, −0.007] | −0.085 [−0.143, −0.025] | +0.005 [−0.020, +0.035] |
| graphe − grille | temps mural égal | −0.158 [−0.254, −0.050] | −0.072 [−0.100, −0.028] | −0.013 [−0.040, +0.015] |

Table: L'analyse originale à trois graines du 19 septembre 2026 (graines 1–3 de chaque bras ; mêmes adversaires, lectures de budget et volume d'évaluation que le `@tbl:d-means`{=typst}) : moyennes au niveau des graines et contrastes graphe moins grille avec intervalles bootstrap percentiles à 95% sur trois graines par bras (10,000 rééchantillonnages ; bras rééchantillonnés indépendamment). Remplacée par les tables à cinq graines ; conservée comme relevé de la première étape de collecte des graines. {#tbl:d-three-seed}

<!-- src: journal/2026-09-19-h6-comparison-01.md:49-62 -->

## Le seuil à temps mural égal et la carte des points de contrôle {#sec:app-d-cutoff}

Le seuil a été fixé par une règle énoncée avant la campagne : la médiane des temps muraux d'entraînement d'exécution complète des trois exécutions originales du bras grille. Ces totaux étaient de 18.77 h, 16.73 h et 19.07 h, de sorte que le seuil est de 18.77 h ; il a été calculé le 16 septembre 2026, avant l'existence de tout nombre inter-bras, et les deux graines grille ultérieures ne sont jamais entrées dans la médiane. Le calcul final prend la médiane exactement à partir des fichiers de chronométrage par génération plutôt qu'à partir de la constante arrondie, de sorte que le point de contrôle final de l'exécution qui définit le seuil se situe au seuil, inclusivement ; la carte résultante pour les graines 1–3 reproduit, point de contrôle pour point de contrôle, celle consignée le 16 septembre 2026. Pour chaque exécution, le point de contrôle retenu est le dernier dont le temps mural d'entraînement cumulé n'excède pas le seuil (`@tbl:d-cutoff`{=typst}). <!-- src: journal/2026-09-16-h6-progress-01.md:36-42 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:22-29 --> <!-- src: scripts/make_results.py:30-62 -->

| Bras | Graine | Point de contrôle au seuil | Temps mural cumulé | Ensemble d'évaluation |
| --- | --- | --- | ---: | --- |
| grille | 1 | gen009 (final) | 18.77 h | ensemble final réutilisé |
| grille | 2 | gen009 (final) | 16.73 h | ensemble final réutilisé |
| grille | 3 | gen008 | 17.22 h | ensemble à temps égal |
| grille | 4 | gen009 (final) | non indiqué | ensemble final réutilisé |
| grille | 5 | gen009 (final) | non indiqué | ensemble final réutilisé |
| graphe | 1 | gen003 | 16.50 h | ensemble à temps égal |
| graphe | 2 | gen004 | 16.06 h | ensemble à temps égal |
| graphe | 3 | gen004 | non indiqué | ensemble à temps égal |
| graphe | 4 | gen002 | non indiqué | ensemble à temps égal |
| graphe | 5 | gen005 | non indiqué | ensemble à temps égal |

Table: Point de contrôle retenu pour la lecture à temps mural égal dans chacune des dix exécutions d'entraînement : le dernier point de contrôle achevé dans le seuil à temps mural égal de 18.77 h de temps mural d'entraînement cumulé (identifiants indexés à partir de zéro ; gen009 est la dixième et dernière génération). Les heures cumulées sont celles indiquées dans les relevés d'analyse ; « non indiqué » signifie que le relevé donne le point de contrôle mais pas les heures. Lorsque le point de contrôle retenu est le dernier, l'ensemble d'évaluation final (100 parties appariées par adversaire) sert aux deux lectures ; sinon, un ensemble à temps égal distinct, de même volume, a été évalué. {#tbl:d-cutoff}

<!-- src: journal/2026-09-16-h6-progress-01.md:36-42 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:26-29 --> <!-- src: scripts/make_results.py:47-62 -->

La carte est le contenu mesuré de la seconde lecture : à temps mural égal, le bras graphe avait achevé 3–6 de ses dix générations (4–5 sur les trois graines originales), le bras grille neuf ou dix. Le `@tbl:d-wallclock`{=typst} donne les temps muraux d'entraînement d'exécution complète qui sous-tendent la carte. Sur les cinq graines, les moyennes sont de 18.00 h (grille) et 36.70 h (graphe), soit un rapport de 2.04× ; sur les trois graines originales, elles étaient de 18.2 h et 35.7 h, soit un rapport de 2.0×. Les ensembles d'évaluation à temps égal des graines 1–3 ont été exécutés le 18 septembre 2026 (environ 11 h), ceux des graines 4 et 5 du bras graphe le 6 octobre 2026 (environ 6 h). <!-- src: paper/claims.md:29 --> <!-- src: results/comparison/wallclock-per-run.md:1-10 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:24-25,71-72 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:3,16 -->

| Bras | Graine 1 | Graine 2 | Graine 3 | Graine 4 | Graine 5 | Moyenne |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| grille | 18.77 | 16.73 | 19.07 | 18.23 | 17.19 | 18.00 |
| graphe | 43.07 | 32.71 | 31.28 | 49.86 | 26.57 | 36.70 |

Table: Temps mural d'entraînement de chacune des dix exécutions de la campagne principale, en heures : les secondes de génération en auto-jeu et d'entraînement par génération, sommées sur les 10 générations de l'exécution (10 × 500 parties), parties d'évaluation exclues, d'après le journal de chronométrage de chaque exécution ; une seule machine, quatre threads de travail, exécutions séquentielles. Les sommes sont de 90.0 h (grille) et 183.5 h (graphe), soit 273.5 h au total. Le seuil à temps mural égal est la médiane des trois valeurs grille des graines 1–3. {#tbl:d-wallclock}

<!-- src: results/comparison/wallclock-per-run.md:1-10 -->

## Bornes de sensibilité au plafond

Le protocole encadre l'estimateur primaire (troncatures exclues) par trois traitements alternatifs de chaque partie tronquée : comptée 0.5 (les scores de sensibilité du `@tbl:d-sens`{=typst}), comptée comme défaite pour le bras testé, et comptée comme victoire pour lui ; ce dernier traitement est une borne supérieure de ce que tout plafond plus grand pourrait apporter à un bras qui tronque. Les bornes ont été calculées à partir des enregistrements par partie dans l'analyse du 19 septembre 2026 (trois graines par bras) : chaque partie tronquée étant comptée comme victoire pour le bras testé, le contraste graphe moins grille contre l'aléatoire légal reste de −0.072 sous la lecture à exemples égaux et de −0.058 sous la lecture à temps mural égal, et sa direction est inchangée sous chaque traitement (exclue, 0.5, défaite, victoire). Contre B-HEU et B-MCTS, aucune partie d'aucun des deux bras n'a été tronquée, de sorte que tous les traitements y coïncident. Le relevé d'analyse final ne réénonce pas les bornes à cinq graines. Parce que le bras graphe a tronqué 20–57% de ses parties contre l'aléatoire légal sur les graines originales et 23–44% sur les graines d'extension (grille : 0–1%, avec une graine d'extension à 11%), son score primaire contre cet adversaire est une moyenne sur moins de parties décidées (43 à 80 par graine) que celui du bras grille. <!-- src: journal/2026-09-19-h6-comparison-01.md:64-70 --> <!-- src: paper/ch5-protocol.md:45-49 --> <!-- src: paper/results-comparison.md:51-61 --> <!-- src: paper/ch7-discussion.md:58-61 -->

## Tables brutes des ablations

Trois variantes du bras graphe ont été entraînées avec trois graines chacune au budget complet (10 générations × 500 parties, réglages d'auto-jeu, d'entraînement et d'évaluation identiques) et évaluées à leur point de contrôle de dixième génération sous la lecture à exemples égaux. Le `@tbl:d-abl-runs`{=typst} résume les variantes ; les `@tbl:d-abl-a2`{=typst} et `@tbl:d-abl-a1prime`{=typst} donnent les scores par graine des deux variantes qui se sont entraînées ; le `@tbl:d-abl-contrast`{=typst} donne les contrastes contre le bras graphe complet. <!-- src: results/ablations/README.md:1-10 -->

| Variante | Composant modifié | Graines | Temps mural d'entraînement | Issue |
| --- | --- | --- | ---: | --- |
| A1 (`graph-untyped`) | les six matrices d'arêtes typées par direction remplacées par une seule matrice partagée | 1, 2, 3 | 7.75 / 8.01 / 7.61 h | entraînement divergé vers NaN à la génération 0, 3 graines sur 3 |
| A2 (`graph-nogpool`) | biais de pooling global retiré de chaque couche (1.37M paramètres vs 1.47M) | 1, 2, 3 | 39.90 / 47.44 / 32.05 h | entraînée ; aucun effet mesurable |
| A1′ (`graph-untyped-clip`) | arêtes non typées *et* écrêtage de la norme du gradient à 1.0 (deux composants) | 1, 2, 3 | 23.89 / 30.35 / 27.68 h | entraînée ; dans la bande du bras complet |

Table: Les trois variantes d'ablation du bras graphe, chacune entraînée avec trois graines indépendantes au budget complet de la comparaison principale (10 générations × 500 parties d'auto-jeu ; mêmes adversaires, ouvertures et réglages d'évaluation gelés). Temps mural d'entraînement en heures par graine, selon la même comptabilité que le `@tbl:d-wallclock`{=typst} (secondes d'auto-jeu et d'entraînement par génération sommées, parties d'évaluation exclues) ; les exécutions graphe de référence des graines 1–3 ont pris 43.07, 32.71 et 31.28 h. Les exécutions courtes de A1 sont un symptôme de sa divergence (une politique NaN joue des parties dégénérées courtes) plutôt qu'une économie. {#tbl:d-abl-runs}

<!-- src: results/comparison/wallclock-per-run.md --> <!-- src: journal/2026-09-23-h7-a1-divergence-01.md:33-40 --> <!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:4-18 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:4-14 -->

Aucune table de scores n'est donnée pour A1 parce qu'il n'en existe aucune qui constitue une mesure de force : chaque passe avant des trois réseaux a renvoyé NaN pour la politique et la valeur dès le premier point de contrôle, et les évaluations finales des trois exécutions à graines indépendantes étaient identiques à la partie près (0 victoire, 0 nulle et 100 défaites contre B-HEU ; 2 victoires et 45 nulles avec 53% de troncature contre B-RND), ce que des entraînements indépendants ne peuvent pas produire. Les journaux d'entraînement portent la signature « policy top-1 100.0%, value acc 0.0% » dès la génération 1, et les parties dégénérées comptaient en moyenne environ 42 demi-coups, sans troncature ni abandon. Les fichiers d'évaluation bruts sont conservés mais exclus de toute table en tant que scores. <!-- src: journal/2026-09-23-h7-a1-divergence-01.md:22-46 -->

| Adversaire | A2 graine 1 | A2 graine 2 | A2 graine 3 | complet graine 1 | complet graine 2 | complet graine 3 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| B-RND | 0.768 (59 %) | 0.714 (65 %) | 0.952 (17 %) | 0.733 (57 %) | 0.981 (20 %) | 0.722 (55 %) |
| B-HEU | 0.050 (0 %) | 0.070 (0 %) | 0.025 (0 %) | 0.025 (0 %) | 0.050 (0 %) | 0.090 (0 %) |
| B-MCTS | 0.070 (0 %) | 0.125 (0 %) | 0.105 (0 %) | 0.115 (0 %) | 0.125 (0 %) | 0.100 (0 %) |

Table: Scores finaux par graine de l'ablation A2 (biais de pooling global retiré) à côté des graines 1–3 du bras graphe complet, lecture à exemples égaux : points de contrôle de dixième génération, 100 parties appariées, à couleurs échangées, par adversaire sur les ouvertures gelées à 400 simulations contre la population gelée. Score = fraction des parties décidées gagnées (nulles 0.5) ; taux de troncature des 100 parties entre parenthèses. Trois exécutions d'entraînement indépendantes par variante ; valeurs brutes, sans intervalle. {#tbl:d-abl-a2}

<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:31-38 -->

| Adversaire | A1′ graine 1 | A1′ graine 2 | A1′ graine 3 |
| --- | ---: | ---: | ---: |
| B-RND | 0.566 (47 %) | 0.671 (59 %) | 0.995 (0 %) |
| B-HEU | 0.035 | 0.135 | 0.110 |
| B-MCTS | 0.090 | 0.195 | 0.060 |

Table: Scores finaux par graine du supplément A1′ (arêtes non typées avec écrêtage de gradient à 1.0, une variante explicitement à deux composants), lecture à exemples égaux : points de contrôle de dixième génération, 100 parties appariées, à couleurs échangées, par adversaire sur les ouvertures gelées à 400 simulations contre la population gelée. Score = fraction des parties décidées gagnées (nulles 0.5) ; le taux de troncature des 100 parties est donné entre parenthèses là où le relevé l'indique (aléatoire légal seulement). Trois exécutions d'entraînement indépendantes ; valeurs brutes, sans intervalle. {#tbl:d-abl-a1prime}

<!-- src: journal/2026-10-09-h7-a1prime-01.md:26-27 -->

| Adversaire | A2 − complet (3 vs 3 graines) | Moyenne A1′ (3 graines) | Moyenne graphe complet (5 graines) | A1′ − complet (3 vs 5 graines) |
| --- | ---: | ---: | ---: | ---: |
| B-RND | −0.001 [−0.170, +0.165] | 0.744 | 0.810 | −0.066 [−0.254, +0.130] |
| B-HEU | −0.007 [−0.043, +0.030] | 0.093 | 0.061 | +0.032 [−0.011, +0.078] |
| B-MCTS | −0.013 [−0.043, +0.013] | 0.115 | 0.107 | +0.008 [−0.040, +0.063] |

Table: Contrastes d'ablation contre le bras graphe complet, lecture à exemples égaux, population gelée, 100 parties appariées par adversaire et par exécution. A2 − complet : différence des moyennes au niveau des graines sur les graines 1–3 des deux variantes. A1′ − complet : différence entre la moyenne de A1′ sur ses trois graines et la moyenne du bras graphe complet sur ses cinq graines. Unité : différence de score (fraction des parties décidées). Entre crochets : intervalle bootstrap percentile à 95%, les deux ensembles de graines étant rééchantillonnés indépendamment avec leurs propres tailles, 10,000 rééchantillonnages. Le contraste A1′ est confondu par l'écrêtage et n'est jamais attribué au seul typage des arêtes. {#tbl:d-abl-contrast}

<!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:34-38 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:28-37 --> <!-- src: results/ablations/README.md:8-10 -->

## Données d'évaluation par génération

Aucune table de scores par génération n'existe dans les fichiers de résultats ni dans les relevés d'analyse. Les figures de score en fonction du temps et de trajectoires par adversaire sont tracées directement à partir des enregistrements d'évaluation de chaque exécution : chaque exécution de la campagne principale a été évaluée, avec les réglages et le volume épinglés, aux points de contrôle des générations 5, 8 et 10 (identifiants gen004, gen007 et gen009) et, lorsqu'il diffère du point de contrôle final, à son point de contrôle à temps égal ; le score contre la population en un point est la moyenne, sur les trois adversaires, des scores de cellule définis ci-dessus, et l'axe du temps est la somme cumulée des durées d'entraînement par génération de l'exécution. Les courbes sont reproductibles à partir des enregistrements par partie et des fichiers de chronométrage publiés ; leurs nombres ne sont pas reproduits ici. <!-- src: scripts/make_figures.py:34-56,357-372 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:36-41 -->
