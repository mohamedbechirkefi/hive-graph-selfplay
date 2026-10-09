# Constantes gelées, hyperparamètres, graines et configurations {#sec:app-c}

Chaque valeur de cette annexe est celle que les campagnes ont réellement exécutée ; les fichiers de configuration et de manifeste conservés avec chaque exécution font autorité, et rien ici n'est une recommandation. Les dates sont celles de l'approbation de l'auteur ou du calcul mécanique qui a fixé une valeur ; `@sec:app-e`{=typst} indexe les enregistrements correspondants, et `@sec:protocol`{=typst} explique pourquoi chaque valeur a été fixée au moment où elle l'a été.

## Constantes gelées {#sec:app-c-constants}

| Constante | Valeur | Fixée le (2026) | Approuvée par |
| --- | --- | --- | --- |
| Variante de jeu | jeu de base (reine, araignée, scarabée, sauterelle, fourmi), règle d'ouverture de tournoi ; extensions hors du périmètre | 9 sept. (périmètre) ; gelée dans le protocole le 10 sept. | l'auteur |
| Plafond de coups et troncature | 300 demi-coups ; une partie tronquée est une issue en propre, jamais une nulle ; taux rapporté séparément | 9 sept. (convention et valeur mesurée) ; gelés le 10 sept. | l'auteur |
| Budget de recherche de l'auto-jeu | 128 simulations complètes / 32 économiques par décision ; fraction complète 0.25 | 10 sept. (protocole) | l'auteur |
| Exploration de l'auto-jeu | échantillonnage en température pendant 12 plis ; bruit de Dirichlet à la racine ε = 0.25 ; abandon à −0.92 avec un audit sans abandon de 10% | 10 sept. (matrice pré-enregistrée) | l'auteur |
| Recherche d'évaluation | 400 simulations par décision ; sans bruit à la racine ; argmax déterministe | 9 sept. | l'auteur |
| Volume d'évaluation | 100 parties appariées par adversaire aux points de contrôle finaux et au seuil ; 20 par adversaire aux générations 4 et 7 | 10 sept. ; confirmé inchangé le 16 sept. | l'auteur |
| Population d'adversaires | B-RND (aléatoire légal), B-HEU (heuristique, poids épinglés par hachage), B-MCTS (recherche, 6,400 simulations) ; point de contrôle antérieur exclu | 9 sept. | l'auteur |
| Ouvertures | 250 ouvertures uniques et légales de 4 demi-coups ; graine du générateur 20260910 ; la paire *i* joue la ligne *i* avec les deux couleurs | 10 sept. | l'auteur |
| Seuil à temps mural égal | 18.77 h = médiane du temps mural total des trois exécutions grille originales ; règle dans la matrice | règle le 10 sept. ; valeur le 16 sept. | règle : l'auteur ; valeur : calculée mécaniquement |
| Graines d'entraînement | 1–3 par bras ; 4–5 ajoutées sous trois pré-engagements écrits | 10 sept. ; extension le 26 sept. | l'auteur |
| Document de protocole | version 1.0 ; tout changement ultérieur est une nouvelle étude | 10 sept. | l'auteur |

Table: Constantes expérimentales gelées avec la date à laquelle chacune a été fixée et l'approbation sous laquelle elle l'a été. Aucune constante n'a été changée après sa date. {#tbl:app-c-frozen}
<!-- src: paper/annex-reproduction.md:7-19; configs/comparison-matrix.yaml:27-59; configs/eval-settings.toml:10-17; paper/annex-architectures.md:87-92; ../state/decisions.md:499-521, 572-591, 605-618, 763-771, 795-806, 823-849, 946-956; journal/2026-09-16-h6-progress-01.md:36-37 -->

Les artefacts gelés sont identifiés par hachage de contenu (`@tbl:app-c-hashes`{=typst}). Le fichier du protocole portait son hachage au gel et le porte inchangé ; le hachage des ouvertures couvre les 250 lignes d'ouverture indépendamment de l'en-tête du fichier ; les poids de l'heuristique sont en outre épinglés par un test automatisé qui échoue si un poids quelconque change.

| Artefact | SHA-256 |
| --- | --- |
| Protocole, version 1.0 | f340a6b64db0f5f0bf126ffb251c3de339450bde192fd54b719036a8a3aefeb5 |
| Ouvertures, contenu (250 lignes) | 63b318d071dfc3ecfae3585636c8e6f7327ddc08e7aed86a466f915f8005af7b |
| Poids de l'heuristique (B-HEU) | d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a |
| Configuration B-RND | f2fc4a06441d3c1a7922838a6693dbb48ec54543bc34fd814d41c9a742514cd7 |
| Configuration B-HEU | 7210a0a349c5bad5dcd2df099cc6865ee3cb5d8a2c30e106ce58137804818999 |
| Configuration B-MCTS | 3fc8f75cf2b4f21012dd61e9924408fbfc32c8ea561aa96eb44f1091ba07364e |

Table: Hachages de contenu des artefacts gelés ; ce sont les identifiants scientifiques du protocole, des ouvertures et de la population d'adversaires. {#tbl:app-c-hashes}
<!-- src: ../state/decisions.md:606-607, 766-769; results/comparison/opponents-manifest.md:10-17, 34-35; docs/baselines.md:27-30 -->

## Hyperparamètres d'entraînement {#sec:app-c-hyper}

La boucle d'entraînement et chaque hyperparamètre sont identiques pour les deux bras et pour toutes les variantes d'ablation, à la seule exception notée dans la dernière ligne.

| Hyperparamètre | Valeur (les deux bras) |
| --- | --- |
| Optimiseur | SGD, momentum 0.9, décroissance de poids 1e-4 |
| Taux d'apprentissage | 0.02, recuit en cosinus jusqu'à lr/100 sur les pas de chaque génération |
| Taille de lot | 256 |
| Époques par génération | 2 |
| Perte de politique | entropie croisée contre la distribution de visites MCTS, softmax exactement sur l'ensemble des coups légaux |
| Perte de valeur | victoire/nulle/défaite du point de vue du camp au trait, poids 0.6 ; enregistrements tronqués exclus |
| Données d'entraînement par génération | les 500 parties d'auto-jeu de la génération ; seules les décisions à plein budget (128 simulations) sont enregistrées |
| Écrêtage de gradient | aucun, sauf dans le supplément A1′ (norme globale 1.0) |
| Recherche d'hyperparamètres | aucune, pour l'un ou l'autre bras |

Table: Hyperparamètres d'entraînement, identiques pour le bras grille, le bras graphe et les variantes d'ablation ; l'écrêtage de gradient du supplément A1′ est le seul changement d'optimiseur de l'étude. {#tbl:app-c-hyper}
<!-- src: paper/annex-reproduction.md:21-31; configs/comparison-matrix.yaml:36-40; paper/annex-architectures.md:87-92 -->

## Dérivation des graines {#sec:app-c-seeds}

Chaque choix aléatoire de l'étude descend d'une graine enregistrée, de sorte qu'une exécution, un ensemble d'évaluation ou un intervalle bootstrap se régénère à l'identique.

| Quantité | Graine |
| --- | --- |
| Exécution d'entraînement (bras, graine *s*) | graine de base = 100,000 × *s* ; espaces de graines disjoints entre exécutions |
| Génération *g* (0–9) | graine d'auto-jeu = base + *g* ; graine d'entraînement = base + *g* |
| Réseau de la génération 0 | initialisation aléatoire à graine fixée avec la graine de base, exporté avant tout auto-jeu |
| Réseau en cours d'évaluation | 9000 + *g* pour les évaluations en cours d'exécution (générations 4, 7 et 9) ; 9500 pour les ensembles de points de contrôle au seuil |
| Adversaires | B-RND 9101 ; B-MCTS 9201 ; B-HEU déterministe (sans graine) |
| Lanceur d'affrontements | 777,000 + *g* pour les évaluations en cours d'exécution ; 888,000 pour les ensembles au seuil ; avec des ouvertures fixes, le calendrier d'ouvertures et de couleurs est indépendant de la graine (hachage du calendrier 8cd84b6564440666 reproduit entre exécutions avec des agents et des graines d'affrontement différents) |
| Générateur d'ouvertures | 20260910 |
| Bootstrap | graine de rééchantillonnage fixe ; 10,000 rééchantillonnages |

Table: Dérivation de chaque graine utilisée dans l'entraînement, l'évaluation et l'analyse. {#tbl:app-c-seeds}
<!-- src: paper/annex-reproduction.md:33-41; ../state/decisions.md:948; results/comparison/opponents-manifest.md:39-44; journal/2026-09-19-h6-comparison-01.md:39; scripts/run_comparison.py:86, 148, 155; scripts/tstar_evals.sh:24-26 -->

## Configuration de chaque bras et variante {#sec:app-c-configs}

Les cinq configurations partagent les constantes gelées de `@tbl:app-c-frozen`{=typst} et les hyperparamètres de `@tbl:app-c-hyper`{=typst} ; elles ne diffèrent que comme indiqué dans la table. Les comptes de paramètres sont des comptes exacts obtenus sur les modèles instanciés ; la différence de capacité de +1.5% entre les bras est le rapport exact. Les différences de capacité des variantes d'ablation sont inhérentes au composant retiré et sont rapportées plutôt qu'égalisées.
<!-- src: results/comparison/parameter-counts.md:1-12 -->

| Variante | Corps | Paramètres | Différence par rapport au bras graphe complet | Graines | Fournisseur d'inférence |
| --- | --- | ---: | --- | --- | --- |
| Bras grille | CNN résiduel, 96 canaux × 8 blocs, sur 77 plans × 32 × 32 | 1,443,168 | sans objet (l'autre bras) | 1–5 | CoreML |
| Bras graphe (méthode complète) | passage de messages relationnel, 152 canaux cachés × 8 couches, plongement d'emplacement 32, capacité de nœuds 224, six relations typées par direction, biais de pooling global | 1,465,452 (+1.5%) | référence | 1–5 | CPU |
| A1 (adjacence naïve) | une seule matrice d'arêtes partagée à la place des six matrices typées par direction | 541,292 (−62.5%) | typage des arêtes retiré | 1–3 | CPU |
| A2 (sans pooling global) | biais de pooling global retiré de chaque couche | 1,372,732 (−4.9%) | pooling retiré | 1–3 | CPU |
| A1′ (supplément) | comme A1 plus écrêtage global de la norme du gradient à 1.0 | comme A1 | deux composants : typage des arêtes retiré et écrêtage ajouté | 1–3 | CPU |

Table: Configuration des deux bras et des trois variantes d'ablation, avec les comptes exacts de paramètres et, entre parenthèses, la différence par rapport au bras grille. Tout ce qui n'est pas listé est identique sur les cinq lignes. Le fournisseur d'inférence est le meilleur disponible mesuré par bras sur la machine d'étude. {#tbl:app-c-configs}
<!-- src: results/comparison/parameter-counts.md:5-10; configs/comparison-matrix.yaml:13-25; paper/annex-architectures.md:8-10, 28-33, 54-56; configs/ablations/A1-edge-typing.md:10-13; configs/ablations/A2-global-pooling.md:9-10; configs/ablations/A1prime-edge-typing-clipped.md:1-11 -->

## Profil machine mesuré {#sec:app-c-machine}

Tous les chiffres de temps mural de ce rapport ont été mesurés sur un seul Apple M1 Pro (10 cœurs, 16 Go, macOS 15.3.1), avec 4 threads de travail par exécution, des exécutions séquentielles et la machine maintenue éveillée. Le fournisseur d'inférence utilisé pour l'auto-jeu et l'évaluation de chaque bras est le meilleur disponible mesuré sur cette machine ; les opérations riches en collecte du réseau graphe ne sont que partiellement prises en charge par l'accélérateur (147 nœuds sur 287, 15 partitions), ce pour quoi son chemin CPU l'emporte.
<!-- src: docs/representations/comparison-controls.md:1-10, 19-27 -->

| Chemin (lot 1, par évaluation de décision) | Grille | Graphe |
| --- | ---: | ---: |
| PyTorch, CPU | 11.03 ms | 10.51 ms |
| ONNX, fournisseur CPU | 23.5 ms | 3.67 ms |
| ONNX, fournisseur CoreML | 2.62 ms | 9.84 ms |
| Meilleur disponible (utilisé) | 2.62 ms (CoreML) | 3.67 ms (CPU) |

Table: Coût d'inférence par évaluation du réseau sur la machine d'étude, mesuré le 10 septembre 2026 ; le meilleur chemin disponible par bras est celui utilisé en auto-jeu et en évaluation. {#tbl:app-c-inference}
<!-- src: docs/representations/comparison-controls.md:19-27 -->

Le débit d'entraînement a été mesuré le 10 septembre 2026 au lot 128, passes avant et arrière, sur le backend GPU de la machine : 274 positions/s pour le réseau grille et 138 positions/s pour le réseau graphe (passe avant seule sur le CPU : 138 et 478 positions/s ; le réseau graphe est plus rapide par position sur le CPU et plus lent sur le GPU). Les exécutions de campagne ont chargé leurs données en processus et se sont entraînées à ces chiffres ou en dessous ; la génération des parties en auto-jeu, et non l'entraînement, domine le temps mural d'une génération dans l'un et l'autre bras. Le temps mural d'entraînement par exécution (auto-jeu, entraînement et export sur 10 générations × 500 parties, parties d'évaluation exclues) était de 16.7–19.1 h pour les exécutions grille et de 26.6–49.9 h pour les exécutions graphe, avec des moyennes de 18.0 h et 36.7 h (valeurs par graine dans `@tbl:d-wallclock`{=typst}). Une partie d'évaluation à 400 simulations prenait ≈23–32 s ; l'adversaire de recherche à 6,400 simulations décide en ≈27 ms sur un seul thread ; un aller-retour par sous-processus vers le moteur coûte 21.7 µs. L'usage disque a été estimé à ≈3–5 Go par campagne à trois graines, contre une garde de 20 Go d'espace libre.
<!-- src: docs/representations/comparison-controls.md:34-44; results/comparison/wallclock-per-run.md:3-8; scripts/run_comparison.py:126-129; paper/annex-reproduction.md:70-75; docs/baselines.md:54-56; journal/2026-09-09-throughput-profile-01.md:72-73; journal/2026-09-10-h6-matrix-01.md:50-55; configs/comparison-matrix.yaml:62 -->
