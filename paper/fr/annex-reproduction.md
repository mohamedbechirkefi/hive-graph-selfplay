*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Annexe C — Hyperparamètres, graines, commandes : fiche de reproduction complète

*Chaque valeur ci-dessous est celle que les campagnes ont réellement
exécutée (les fichiers `train-config.json` et `*-manifest.json` par
exécution font autorité) ; rien ici n'est une recommandation.*

## C.1 Constantes expérimentales gelées

| Constante | Valeur | Gelée par |
| --- | --- | --- |
| Variante | jeu de base, règle d'ouverture de tournoi | D-007 / protocole v1.0 |
| Plafond de coups | 300 demi-coups ; troncature = issue à part entière | D-008/D-011 / protocole §3 |
| Simulations d'auto-jeu (complètes/économiques) | 128 / 32, fraction complète 0.25 | protocole §5 |
| Plis en température / abandon / audit | 12 / −0.92 / 10% | matrice (pré-enregistrée) |
| Simulations d'évaluation / bruit / volume | 400 / aucun / 100 parties/adversaire | D-019, D-027 |
| Population d'adversaires | B-RND, B-HEU (poids sha256 d0602f18…0b97a), B-MCTS@6400 | D-017 |
| Ouvertures | 250 × 4 demi-coups, contenu sha256 63b318d0…5af7b | D-025 |
| T\* (seuil à temps mural égal) | 18.77 h (médiane des totaux grille s1–s3) | règle pré-enregistrée, calculé le 2026-09-16 |
| Graines | 1–5 par bras (4–5 ajoutées sous pré-engagement) | D-026 / D-031 |

## C.2 Hyperparamètres d'entraînement (identiques pour les deux bras)

SGD, lr 0.02 en recuit cosinus jusqu'à lr/100 sur la durée de
l'exécution, momentum 0.9, décroissance de poids 1e-4, lot 256,
2 époques par génération, poids de la perte de valeur 0.6, entropie
croisée de politique masquée sur l'ensemble légal contre les
distributions de visites MCTS, enregistrements tronqués exclus de la
perte de valeur. Grille : 96 canaux × 8 blocs. Graphe : 152 canaux
cachés × 8 couches, plongement d'emplacement 32. Aucune recherche
d'hyperparamètres n'a été effectuée pour l'un ou l'autre bras (même
budget de réglage nul, plan ch. 6) ; le seul changement d'optimiseur
post hoc de toute l'étude est l'écrêtage de gradient du supplément
A1′, explicitement à deux composants.

## C.3 Dérivation des graines

Exécution d'entraînement (bras, graine) : base_seed = 100,000 ×
graine ; la génération g utilise base_seed + g pour l'auto-jeu et
l'entraînement ; le réseau gen-0 est une initialisation aléatoire à
graine fixée exportée vers ONNX (torch.manual_seed = base_seed).
Évaluation : graine du réseau 9000+gen (finales) / 9500 (ensembles
T\*), graines des adversaires 9101 (B-RND) et 9201 (B-MCTS), graines
d'arène telles que journalisées ; avec des ouvertures fixes, le
calendrier est indépendant de la graine (prouvé par le test de hachage
du calendrier).

## C.4 Commandes

```sh
# one training run of the matrix (resumable per generation)
python3 scripts/run_comparison.py --arm grid  --seed 1 --gens 10 --games 500
python3 scripts/run_comparison.py --arm graph --seed 1 --gens 10 --games 500
# ablations: --arm graph-untyped | graph-nogpool | graph-untyped-clip

# regenerate every table and figure from raw per-game records
python3 scripts/make_results.py
python/.venv/bin/python scripts/make_figures.py

# pre-training check battery on any shard set
bash scripts/run_h4_checks.sh '<abs>/gen000-*.bin' '<abs>/gen000-manifest.json'

# fresh-environment minimal reproduction (clone, build, replay, compare)
bash scripts/reproduce_minimal.sh /tmp/repro

# booklet (assembly -> HTML -> PDF)
python3 scripts/assemble_booklet.py && bash scripts/make_booklet_pdf.sh

# French/English numeric-identity check
python3 scripts/check_fr_numbers.py
```

## C.5 Profil machine mesuré (tous les chiffres de temps mural)

Apple M1 Pro (10 cœurs, 16 Go, macOS 15.3.1) ; 4 threads de travail
par exécution, exécutions séquentielles sous `caffeinate`. Inférence :
grille CoreML 2.62 ms/eval, graphe CPU 3.67 ms/eval (CoreML plus lent
pour le réseau graphe riche en opérations de collecte — mesuré,
rapporté, imputé). Entraînement ≈770 (grille) / ≈195 (graphe) pos/s
sur MPS. Totaux par exécution : grille 16.7–19.8 h, graphe
30.0–54.9 h par exécution de 10 × 500 parties ; évaluation ≈23–32
s/partie à 400 simulations.

## C.6 Index des journaux et des décisions de cette étude

Protocole et gels : D-007/008/011/012/017/019/020/025. Campagnes :
D-026 (principale), D-029 (ablations), D-030 (A1′), D-031 (extension à
5 graines avec pré-engagements). Journaux d'analyse :
H6-2026-09-19-comparison-01 (3 graines), H6-2026-10-09-5seed-final-01
(finale), H7-2026-09-23 / 10-02 / 10-09 (A1, A2, A1′). Validation du
moteur : l'ensemble H2-2026-09-09. Chaque cellule de table de ce
livret est atteignable depuis l'un de ces éléments.
