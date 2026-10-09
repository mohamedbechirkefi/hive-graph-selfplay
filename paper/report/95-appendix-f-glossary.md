# Glossary {#sec:app-f}

The tables below fix the English terms used in this report, their meaning within the perimeter of the study, and the French equivalent used in the French edition. The French column reproduces the phrasing established in the French chapters; an asterisk marks a composed form, built from established pieces, that the French edition uses for the first time here.

| Term | Definition | French equivalent |
| --- | --- | --- |
| grid arm / graph arm | The two compared systems, identical except for the state encoding and the network body reading it. | bras grille / bras graphe |
| state encoding | The function turning a position into the tensors a network reads; pinned byte-for-byte between engine and training code. | encodage d'état\* |
| shared action decoder | The single contract by which both arms emit a policy over the same actions, namely (piece slot, destination) plus pass, with identical legal-set masking and normalisation. | décodeur d'actions partagé |
| opponent population | The three fixed opponents every checkpoint is scored against, frozen on 9 September 2026. | population d'adversaires |
| B-RND, legal-random | Uniform draw over the legal moves; the floor of the population. | aléatoire légal |
| B-HEU, heuristic | Greedy one-ply argmax of a documented fixed-weight evaluation with queen-targeting quiescence. | heuristique documentée à poids fixes |
| B-MCTS, search at 6,400 simulations | PUCT tree search without a network, uniform priors, the handcrafted evaluation as leaf value. | MCTS sans réseau à 6400 simulations |
| frozen | Fixed by a dated approval and never touched afterwards; any later touch would be a new study. | gelé / gelée |
| pre-registered rejection rule | The condition written into the frozen protocol under which the hypothesis is rejected: no seed-consistent graph advantage under both readings, intervals excluding a meaningful advantage. | règle de rejet pré-enregistrée\* |
| seed (independent training run) | One complete training run from a seeded initialisation; the unit of replication and resampling. | graine (exécution d'entraînement indépendante) |
| generation | One cycle of self-play, training and checkpoint export; ten per run. | génération |
| checkpoint | The exported network at the end of a generation; identifiers zero-based (gen000 to gen009). | point de contrôle |
| paired colour-swapped games | Each opening line played once with each colour, so all arms, seeds and opponents face identical schedules. | parties appariées, à couleurs échangées |
| pinned evaluation settings | 400 simulations per decision, no exploration noise, deterministic argmax; fixed by file and test. | réglages d'évaluation épinglés |

Table: Study-design terms. {#tbl:f-design}

| Term | Definition | French equivalent |
| --- | --- | --- |
| One-Hive rule | No move may split the hive, including in transit; a piece whose removal would split it is pinned. | One-Hive (kept in English) |
| freedom to move | A sliding piece may only pass through a gap whose two flanking cells are not both occupied. | liberté de mouvement |
| gate | Two occupied cells flanking a step, blocking a slide; above ground level, the beetle gate. | porte (porte du scarabée) |
| stacking | Beetles climb onto pieces, forming stacks; only the top piece acts. | empilement |
| stun | The marker on a piece just thrown by a pillbug, which cannot move next ply; inert in the base game. | étourdissement |
| forced pass | With no legal move a side must pass; pass is legal exactly when no move exists. | passe forcée |
| ply | One move by one side (half-move); the cap is 300 plies. | pli / demi-coup |
| opening (frozen line) | A four-ply prefix played before the agents take over; 250 frozen lines shared by every match. | ouverture |

Table: Hive terms. {#tbl:f-hive}

| Term | Definition | French equivalent |
| --- | --- | --- |
| self-play | Games the current network plays against itself, through the search, to produce training records. | auto-jeu |
| Monte-Carlo tree search (MCTS) | The search of both arms and of B-MCTS; the network supplies priors and a leaf value. | recherche arborescente Monte-Carlo (MCTS) |
| PUCT | The selection rule: maximise Q + c·prior·√N/(1+n), c = 1.4. | PUCT |
| policy | The network's distribution over legal actions, trained towards the recorded visit distribution. | politique |
| value | The network's estimate in [−1, 1] of the outcome for the side to move; a three-class head, truncated records excluded. | valeur |
| visit distribution | Normalised root visit counts after a search; the policy target. | distribution de visites |
| playout-cap randomization | A fraction 0.25 of self-play decisions gets 128 simulations and is recorded; the rest get 32 and are not. | randomisation du plafond de simulations |
| temperature plies | The first 12 plies of a self-play game, sampled rather than taken by argmax. | plis en température |
| resignation | A self-play game is abandoned when the value falls below −0.92. | abandon |
| resignation audit | A 10% fraction of self-play games played to the end regardless, to check that resignation hides no wins. | audit sans abandon |
| policy top-1 | Training-fit metric: share of records whose policy argmax matches the target's argmax. | argmax de politique (top-1)\* |
| value accuracy | Training-fit metric: share of records whose predicted outcome class is the recorded one. | exactitude de la valeur\* |

Table: Search and self-play terms. {#tbl:f-selfplay}

| Term | Definition | French equivalent |
| --- | --- | --- |
| frame (32×32) | The fixed grid into which the grid arm embeds a position, centred on the bounding box; 77 feature planes. | cadre 32×32 ; plans de caractéristiques |
| message passing | The graph arm's computation: each node updates from its neighbours, layer by layer. | passage de messages |
| direction-typed relations | The six hexagonal directions as edge types, each with its own weights. | relations d'arêtes typées par direction |
| global-pooling bias | A pooled summary of all nodes added back into every node; removed in ablation A2. | biais de pooling global (biais d'agrégation globale) |
| capacity-matched | Near-equal parameter counts: 1.44 M (grid) and 1.47 M (graph), +1.5%. | à capacité appariée |
| naive adjacency | Ablation A1: the six typed edge matrices replaced by one shared matrix. | adjacence naïve |
| gradient clipping | The norm clip at 1.0 added in the A1′ supplement, making it a two-component variant. | écrêtage de gradient |

Table: Representation and network terms. {#tbl:f-networks}

| Term | Definition | French equivalent |
| --- | --- | --- |
| truncation (never "draw") | A game stopped at the 300-ply cap; a fourth outcome, never folded into draws. | troncature (partie tronquée) |
| move cap | The 300-ply limit at which a game is truncated. | plafond de coups (plafond de 300 demi-coups) |
| score | Mean of win 1 / draw 0.5 / loss 0 over the non-truncated games of a (seed, opponent) cell. | score |
| truncation rate | Share of a cell's 100 games that were truncated; always reported beside the score. | taux de troncature\* |
| sensitivity score | The cell's mean over all games with truncations counted 0.5. | colonne de sensibilité « troncatures à 0.5 » |
| cap-treatment bounds | The contrast recomputed with truncations as losses and as wins, bracketing any other cap. | bornes de traitement du plafond |
| seed-level mean | The plain mean of the per-seed cell scores of one arm against one opponent. | moyenne au niveau des graines |
| seed-level bootstrap interval | A 95% percentile bootstrap interval from resampling seeds (never games) 10,000 times. | intervalle bootstrap sur les graines |
| percentile interval | The interval whose ends are the 0.025 and 0.975 quantiles of the sorted resample statistics; no bias correction. | bootstrap percentile |
| arm contrast | The graph-minus-grid difference of seed-level means, with its interval from independently resampled seed sets. | contraste entre bras |

Table: Outcome and statistics terms. {#tbl:f-statistics}

| Term | Definition | French equivalent |
| --- | --- | --- |
| budget | A run's resources in four denominations: wall-clock, hardware, training states, simulations. | budget (temps mural, matériel, états d'entraînement, simulations) |
| wall-clock | Elapsed real time on the study machine, logged per generation; a run's training wall-clock excludes its evaluation games. | temps mural |
| same-examples reading | The comparison at equal self-play budget: both arms' tenth-generation checkpoints after 10 generations × 500 games. | lecture à exemples égaux |
| same-wall-clock reading | The comparison at equal training time: each run's last checkpoint within the equal-time cutoff. | lecture à temps mural égal |
| equal-time cutoff | 18.77 h, the median full-run wall-clock of the grid arm's three original runs, fixed by a pre-registered rule on 16 September 2026. | seuil à temps mural égal |
| simulations per decision | The search budget: 128 full / 32 cheap in self-play, 400 in evaluation, 6,400 for B-MCTS. | simulations par décision |

Table: Budget terms. {#tbl:f-budget}

<!-- src: paper/fr/results-comparison.md:23-49,115-131 --> <!-- src: paper/fr/ch5-protocol.md:12-72 --> <!-- src: paper/fr/ch2-formalisation.md:24-93 --> <!-- src: paper/fr/method-representations.md:13-60 --> <!-- src: paper/fr/method-pipeline.md:11-38 --> <!-- src: paper/fr/method-baselines.md:12-47 --> <!-- src: paper/fr/annex-reproduction.md:11-21 --> <!-- src: paper/fr/annex-architectures.md:109-111 --> <!-- src: paper/fr/method-validation.md:53 --> <!-- src: paper/fr/annex-corpus.md:9,48,111-114 --> <!-- src: paper/fr/ch7-discussion.md:74-91 --> <!-- src: results/comparison/parameter-counts.md:5-11 --> <!-- src: results/comparison/wallclock-per-run.md:3 -->
