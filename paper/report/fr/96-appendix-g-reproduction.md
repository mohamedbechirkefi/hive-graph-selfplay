# Guide de reproduction {#sec:app-g}

C'est le seul endroit du rapport où commandes, noms de fichiers et identifiants apparaissent tels quels, parce que la reproduction de l'étude les exige : ce qui est publié, le scénario minimal exécuté dans un environnement vierge le 9 octobre 2026, l'ensemble complet des commandes, les durées à prévoir et les identifiants qu'une reproduction doit retrouver.

## Ce qui est publié

L'ensemble publié (release) est le dépôt `hive-graph-selfplay` et les enregistrements qu'il contient. La première étude a été publiée le 9 octobre 2026 à l'étiquette `v2.0-report` du dépôt public https://github.com/mohamedbechirkefi/hive-graph-selfplay, avec le rapport dans les deux langues, l'article court et une archive des enregistrements jointe à la publication ; les enregistrements de la seconde étude et la présente révision accompagnent la publication étiquetée `v2.1-report`. Les moteurs de référence tiers utilisés uniquement pour la validation des règles sont sous licence MIT et ne sont pas redistribués. <!-- src: ../state/decisions.md (D-034, D-036) --> <!-- src: paper/final-control.md:15,24-28 -->

- **Code.** Le moteur Rust (noyau de règles, serveur de protocole, recherche, arène, travailleurs d'auto-jeu), le code Python d'entraînement et d'export sous `python/hivenet/`, les scripts sous `scripts/`.
- **Configurations gelées.** `configs/comparison-matrix.yaml`, `configs/eval-settings.toml`, les configurations des adversaires et le fichier de poids de l'heuristique sous `configs/baselines/`, les spécifications d'ablation sous `configs/ablations/`.
- **Ouvertures gelées et manifeste de la population.** `results/comparison/openings-v1.txt` (250 lignes de quatre plis) et `opponents-manifest.md`, qui consigne les hachages du `@tbl:g-identifiers`{=typst}.
- **Tables de résultats.** `results/comparison/results-same-examples.{md,csv}`, `results-same-wallclock.{md,csv}`, `results-arm-difference.md`, `wallclock-per-run.md` ; `results/ablations/README.md` ; pour la seconde étude, les quatre mêmes tables plus `study1-vs-study2.md` sous `results/study2/`.
- **Enregistrements par exécution**, sous `data/runs/cmp-<arm>-s<seed>/` (première étude, graines 1–5) et `data/runs/cmp2-<arm>-s<seed>/` (seconde étude, graines 11–15, chacune avec un `driver-config.json` consignant le régime) : `eval/` (un fichier à valeurs séparées par des virgules par point de contrôle et par adversaire, une ligne par partie : `opening_id, a_is_white, score_a, truncated, plies, outcome`, métadonnées dans les lignes d'en-tête `#`) ; `wallclock.json` (secondes par génération) ; les manifestes `selfplay/` liant chaque shard à son réseau générateur, et les shards ; `checkpoints/gen000-b1.onnx` à `gen009-b1.onnx`. Les tables et les figures n'ont besoin que de `eval/` et de `wallclock.json` ; le rejeu n'a besoin que d'un point de contrôle.

Les moteurs tiers utilisés dans la validation des règles (Mzinga, nokamute) ne sont pas livrés et ne sont pas nécessaires : aucun nombre de l'étude n'en dérive. <!-- src: scripts/analyze_comparison.py:3-6 --> <!-- src: scripts/reproduce_minimal.sh:20-31 --> <!-- src: results/comparison/opponents-manifest.md:25-28 --> <!-- src: paper/annex-reproduction.md:3-5 -->

## Le scénario minimal en environnement vierge

`scripts/reproduce_minimal.sh <workdir>` effectue, à partir d'un clone propre et des enregistrements livrés, la plus petite vérification de bout en bout qui touche chaque maillon de la chaîne : construire, jouer, enregistrer, agréger. Elle a réussi le 9 octobre 2026, puis de nouveau le même jour après une correction de prose du générateur de tables, avec une différence numérique vide. Ses quatre étapes : <!-- src: scripts/reproduce_minimal.sh:1-9 --> <!-- src: paper/final-control.md:13,20 -->

1. **Cloner et construire.** `git clone` dans `<workdir>/clone`, puis `cargo build --release -p hive-engine -p hive-arena` ; le binaire du moteur doit exister ensuite. Le crate d'inférence télécharge le binaire ONNX Runtime à la première construction, de sorte que la première construction nécessite un accès réseau. <!-- src: scripts/reproduce_minimal.sh:14-18 --> <!-- src: CLAUDE.md:93-94 -->
2. **Livrer les enregistrements.** Copier `results/comparison/`, le `eval/` et le `wallclock.json` de chaque exécution, et l'unique point de contrôle `cmp-grid-s2/checkpoints/gen009-b1.onnx` dans le clone, comme le ferait l'agencement de publication. <!-- src: scripts/reproduce_minimal.sh:20-31 -->
3. **Rejouer une partie enregistrée de manière déterministe.** La partie est la position d'échec F2 des résultats qualitatifs : le point de contrôle final de la graine 2 du bras grille contre B-HEU sur la ligne d'ouverture 2, le bras jouant les Noirs, perdue en 19 plis. L'arène joue la paire de couleurs de cette ouverture (`--games 2 --depth 1 --seed 1 --threads 1`), le réseau à 400 simulations avec la graine 9009 (la règle de l'évaluation finale, 9000 + indice de génération), B-HEU à la profondeur 1 sur un seul thread ; le script vérifie que les champs `score_a`, `truncated` et `plies` de la ligne du côté noir sont égaux à ceux de la ligne livrée dans `cmp-grid-s2/eval/gen009-vs-B-HEU.csv` et imprime `replay matches shipped row: plies 19, score 0`. <!-- src: scripts/reproduce_minimal.sh:33-49 --> <!-- src: paper/figures/fig4-failures.md:11-14 --> <!-- src: paper/annex-reproduction.md:35-41 -->
4. **Régénérer et comparer.** `python3 scripts/make_results.py` (bibliothèque standard de Python uniquement) reconstruit les tables des deux lectures à partir des enregistrements livrés ; `cmp` contre les fichiers livrés `results-same-examples.md` et `results-same-wallclock.md` doit les déclarer identiques à l'octet près. Le script se termine par `MINIMAL REPRODUCTION: PASS`. <!-- src: scripts/reproduce_minimal.sh:51-57 -->

Le scénario vérifie que le code publié se construit à partir d'une copie propre du dépôt, qu'une partie enregistrée est rejouée exactement par le point de contrôle publié contre l'adversaire publié sous les réglages épinglés, et que les tables publiées sont une fonction pure des enregistrements publiés. Il ne vérifie pas l'entraînement ; c'est l'objet de la reproduction complète ci-dessous.

## Commandes de reproduction complète

```sh
# toolchain: Rust (cargo) and Python 3; the project virtual environment is python/.venv
cargo build --release                      # engine, arena, self-play and fuzz binaries
cargo test                                 # rules kernel: unit tests, perft to depth 5 for all 8 game types, UHP server tests
cargo test --release -p hive-core --test perft_tables -- --ignored   # perft to depth 6

# one training run of the matrix (resumable per generation); repeat for --seed 2 … 5
python3 scripts/run_comparison.py --arm grid  --seed 1 --gens 10 --games 500
python3 scripts/run_comparison.py --arm graph --seed 1 --gens 10 --games 500
# ablations (seeds 1–3): --arm graph-untyped | graph-nogpool | graph-untyped-clip

# equal-time checkpoint evaluations for runs whose cutoff checkpoint is not the final one
bash scripts/tstar_evals.sh                # seeds 1–3
bash scripts/tstar_evals2.sh               # graph seeds 4–5

# regenerate every table and figure from raw per-game records
python3 scripts/make_results.py
python/.venv/bin/python scripts/make_figures.py

# second study (protocol v2): driver defaults reproduce the first study (regression test),
# then the ten warm-started runs, the cutoff evaluations and the analysis
python3 scripts/test_driver_equivalence.py
bash scripts/campaign2.sh                  # seeds 11–15, --warm-start --window 3 --run-prefix cmp2
python3 scripts/tstar_evals_study2.py      # T*' from the five grid clocks, then the seven cutoff sets
python3 scripts/make_results.py --study 2
python/.venv/bin/python scripts/make_figures.py --study 2

# pre-training check battery on any shard set
bash scripts/run_h4_checks.sh '<abs>/gen000-*.bin' '<abs>/gen000-manifest.json'

# fresh-environment minimal reproduction (clone, build, replay, compare)
bash scripts/reproduce_minimal.sh /tmp/repro

# French/English numeric-identity check; report build
python3 scripts/check_fr_numbers.py
python/.venv/bin/python scripts/build_report.py all
```

<!-- src: paper/annex-reproduction.md:43-66 --> <!-- src: scripts/run_comparison.py:11-25 --> <!-- src: scripts/campaign2.sh:1-9 --> <!-- src: scripts/tstar_evals_study2.py:1-20 --> <!-- src: scripts/test_driver_equivalence.py:1-11 --> <!-- src: scripts/run_h4_checks.sh:3 --> <!-- src: scripts/build_report.py:3 --> <!-- src: scripts/tstar_evals.sh:2-4 --> <!-- src: scripts/tstar_evals2.sh:2-3 --> <!-- src: CLAUDE.md:33-35,41 -->

Le pilote d'entraînement est reprenable par génération : une ré-exécution saute les générations achevées et poursuit avec le même calendrier de taux d'apprentissage, et chaque exécution écrit ses réglages de générateur, ses graines et ses empreintes de modèle dans ses manifestes. Les graines dérivent du numéro de graine de l'exécution : graine de base = 100,000 × graine, la génération $g$ utilisant la graine de base + $g$ ; l'évaluation utilise la graine de réseau 9000 + génération (ensembles finaux) ou 9500 (ensembles à temps égal), et les graines d'adversaire 9101 (B-RND) et 9201 (B-MCTS). <!-- src: scripts/run_comparison.py:2-10 --> <!-- src: paper/annex-reproduction.md:33-41 -->

## Durées attendues et disque

Toutes les durées du `@tbl:g-durations`{=typst} ont été mesurées sur la machine d'étude (Apple M1 Pro, 10 cœurs, 16 Go, macOS 15.3.1) avec quatre threads de travail par exécution et des exécutions séquentielles ; l'inférence du bras grille s'exécute sur CoreML (2.62 ms par évaluation), celle du bras graphe sur CPU (3.67 ms), chacun étant le fournisseur le plus rapide mesuré pour ce réseau. <!-- src: paper/annex-reproduction.md:68-77 -->

| Étape | Durée mesurée |
| --- | ---: |
| Une exécution d'entraînement grille (10 générations × 500 parties) : temps mural d'entraînement, parties d'évaluation exclues | 16.7–19.1 h |
| Une exécution d'entraînement graphe (même budget) : temps mural d'entraînement, parties d'évaluation exclues | 26.6–49.9 h |
| Les dix exécutions de la campagne principale, temps mural d'entraînement sommé | 273.5 h (grille 90.0 h, graphe 183.5 h) |
| Campagne originale de six exécutions (graines 1–3, les deux bras, séquentielles), temps écoulé | 10–17 septembre 2026, ≈7.4 jours ; ≈163 h de temps machine |
| Exécutions d'extension (graines 4–5, les deux bras), temps écoulé par exécution tel que consigné | 18.0–54.9 h, du 27 septembre au 2 octobre 2026 |
| Une partie d'évaluation à 400 simulations | ≈23–32 s |
| Ensembles d'évaluation à temps égal, graines 1–3 (quatre points de contrôle × trois adversaires) | ≈11 h, 18 septembre 2026 |
| Ensembles d'évaluation à temps égal, graines 4–5 du graphe (deux points de contrôle × trois adversaires) | ≈6 h, 6 octobre 2026 |
| Exécutions d'ablation A1 / A2 / A1′ (par graine), temps mural d'entraînement | 7.61–8.01 h (un symptôme de divergence) / 32.05–47.44 h / 23.89–30.35 h |
| Seconde étude, une exécution grille (démarrage à chaud, fenêtre 3) : temps mural d'entraînement | 17.46–18.52 h |
| Seconde étude, une exécution graphe (même régime) : temps mural d'entraînement | 36.27–52.85 h |
| Seconde étude, les dix exécutions, temps mural d'entraînement sommé | 296.9 h (grille 89.0 h, graphe 207.9 h) |
| Seconde campagne (graines 11–15, les deux bras, séquentielles), temps écoulé | 13–26 octobre 2026, 13 jours 8 h |
| Seconde étude, ensembles d'évaluation à temps égal (sept points de contrôle × trois adversaires) | ≈ 14 h, 26–27 octobre 2026 |
| Seconde étude, pilote (2 générations × 200 parties, évaluation à 20 parties par adversaire) | grille 1 h 35 min ; graphe 4 h 17 min |
| Construction du moteur ; scénario minimal | non mesuré |

Table: Durées mesurées des calculs de l'étude sur la machine d'étude (Apple M1 Pro, quatre threads de travail par exécution, exécutions séquentielles), telles que consignées dans les relevés d'exécution et d'analyse ; les plages couvrent les exécutions de l'étape. Le temps mural d'entraînement est la somme des secondes d'auto-jeu et d'entraînement par génération d'une exécution, parties d'évaluation exclues ; les chiffres de campagne, d'extension et d'ablation sont des temps écoulés tels que consignés. Les exécutions courtes de A1 reflètent sa divergence (une politique NaN joue des parties dégénérées courtes) plutôt qu'un coût moindre. La construction du moteur et le scénario minimal n'ont pas été chronométrés. {#tbl:g-durations}

<!-- src: paper/annex-reproduction.md:75-77 --> <!-- src: results/comparison/wallclock-per-run.md:1-10 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:24-26 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:3,12-16 --> <!-- src: journal/2026-09-23-h7-a1-divergence-01.md:15-17 --> <!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:16-17 --> <!-- src: journal/2026-10-09-h7-a1prime-01.md:13 --> <!-- src: results/study2/wallclock-per-run.md:7-11 --> <!-- src: journal/2026-10-13-h9-campaign-01.md:67-78 --> <!-- src: journal/2026-10-27-h9-analysis-01.md:26-29 --> <!-- src: journal/2026-10-12-h9-pilot-01.md:17-19 -->

Disque : avant la campagne, la matrice de six exécutions a été dimensionnée à environ 3–5 Go de shards, de points de contrôle et d'enregistrements, pour 164 Go libres avec une garde de 20 Go ; à mi-campagne, la machine indiquait 200 Go libres. L'empreinte finale des répertoires d'exécution de la première étude n'a pas été consignée ; les dix répertoires d'exécution de la seconde étude totalisent 4.8 Go. <!-- src: journal/2026-09-10-h6-matrix-01.md:50-55 --> <!-- src: journal/2026-09-16-h6-progress-01.md:28-29 --> <!-- src: journal/2026-10-13-h9-campaign-01.md:72-75 -->

## Identifiants qu'une reproduction doit retrouver

Une reproduction est fidèle lorsqu'elle utilise les artefacts gelés identifiés ci-dessous et, pour le scénario minimal, reproduit la ligne de partie livrée et les tables identiques à l'octet près. Les constantes expérimentales gelées que chaque commande doit laisser intactes sont tabulées dans l'`@sec:app-c`{=typst} : jeu de base avec la règle d'ouverture de tournoi, plafond de 300 plis, 128/32 simulations d'auto-jeu avec une fraction complète de 0.25, 12 plis en température, abandon à −0.92 avec un audit de 10%, 400 simulations d'évaluation sans bruit, 100 parties par adversaire, 250 ouvertures, le seuil de 18.77 h, graines 1–5 par bras ; pour la seconde étude, les mêmes constantes avec le démarrage à chaud, la fenêtre de trois générations, les graines 11–15 et le seuil de 17.63 h du protocole version 2.0 (`@sec:app-c-study2`{=typst}). <!-- src: results/comparison/opponents-manifest.md:3-44 --> <!-- src: paper/annex-reproduction.md:7-19 -->

| Artefact | Identifiant |
| --- | --- |
| Fichier de poids de l'heuristique (`configs/baselines/heuristic-weights.toml`), SHA-256 | `d0602f1895fbed70b6f84ac2a3eb87bd68e811e53acf24d4d7814a1495b0b97a` |
| Configuration de B-RND (`configs/baselines/random.toml`), SHA-256 | `f2fc4a06441d3c1a7922838a6693dbb48ec54543bc34fd814d41c9a742514cd7` |
| Configuration de B-HEU (`configs/baselines/heuristic.toml`), SHA-256 | `7210a0a349c5bad5dcd2df099cc6865ee3cb5d8a2c30e106ce58137804818999` |
| Configuration de B-MCTS (`configs/baselines/mcts-nonet.toml`), SHA-256 | `3fc8f75cf2b4f21012dd61e9924408fbfc32c8ea561aa96eb44f1091ba07364e` |
| Ouvertures gelées, contenu des 250 lignes, SHA-256 | `63b318d071dfc3ecfae3585636c8e6f7327ddc08e7aed86a466f915f8005af7b` |
| Ouvertures gelées, fichier tel que gelé, SHA-256 | `538497390a3787299c67c3ca138b8feacb369d55dc562881d1aee45200cbccb2` |
| Calendrier d'ouvertures et de couleurs de chaque affrontement de 100 parties (ensembles finaux et au seuil, les deux études) | `3bf5d3e51cea0c0d` |
| Calendrier d'ouvertures et de couleurs de chaque affrontement intermédiaire de 20 parties (les deux études) | `8cd84b6564440666` |
| Document de protocole gelé | `f340a6b6…aefeb5` (consigné sous forme abrégée), commit `44a74ff` |
| Document de protocole gelé, version 2.0 (seconde étude) | `e296a12e8d1e3dee36c3b210ececced62314e64657aede1cb91b1ea452b461eb`, commit `4a22a24` |
| Code du moteur au gel de la population | commit `b94e7c1` |
| Code de campagne (comparaison principale) | commit `ac58773` |
| Code d'ablation ; garde contre les pertes non finies | commits `216fded` ; `bffeea9` |
| Code d'analyse (tables finales à cinq graines) | commit `7db074d` |
| Seconde étude : options du pilote de campagne ; script de campagne ; commutateur d'analyse ; commutateur de figures | commits `008aaee` ; `dc0b6c2` ; `b0f1598` ; `32297fe` |

Table: Identifiants des artefacts gelés et des états du code de l'étude. Les hachages sont des condensés hexadécimaux SHA-256 du contenu des fichiers tels que consignés au gel ; les hachages du calendrier sont les préfixes des condensés imprimés par l'outil d'analyse pour le calendrier (ouverture, couleur), identiques pour chaque affrontement d'un volume donné dans les deux études (la première édition de ce rapport attribuait le hachage des 20 parties aux affrontements de 100 parties) ; les commits sont des identifiants de commit abrégés du dépôt. {#tbl:g-identifiers}

<!-- src: results/comparison/opponents-manifest.md:10-44 --> <!-- src: journal/2026-09-19-h6-comparison-01.md:10-11 --> <!-- src: journal/2026-10-02-h7-a2-nogpool-01.md:9-11 --> <!-- src: journal/2026-10-09-h6-5seed-final-01.md:9-10 --> <!-- src: journal/2026-10-27-h9-analysis-01.md:234-246 -->
