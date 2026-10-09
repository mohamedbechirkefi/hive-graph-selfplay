*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Résultats — La comparaison contrôlée (brouillon de section du rapport)

*Rédigé le 2026-09-19 à la clôture de H6 (invariant 14). Master anglais
de travail ; copie française au jalon du rapport (D-006). Chaque nombre
remonte aux journaux `H6-2026-09-19-comparison-01` (analyse à 3
graines) et `H6-2026-10-09-5seed-final-01` (analyse finale à 5 graines)
et se régénère via `scripts/make_results.py` / `make_figures.py` sur
les enregistrements bruts par partie ; affirmations consignées dans
`claims.md`.*

## La question pré-enregistrée et sa réponse

Le protocole (gelé en v1.0 avant toute exécution de comparaison)
demandait : à budget d'entraînement comparable, l'architecture graphe
apprend-elle une meilleure politique que l'architecture grille pour
Hive en jeu de base ? Il fixait, à l'avance, ce qui rejetterait
l'hypothèse : aucun avantage graphe cohérent entre graines sous les
deux lectures de budget, avec des intervalles excluant un avantage
graphe substantiel.

**C'est ce qui s'est produit. H1 est rejetée.** Sous la lecture à
exemples égaux (les deux bras, 10 générations × 500 parties) et la
lecture à temps mural égal (T\* = 18.77 h, calculé par une règle
pré-enregistrée avant l'existence de tout nombre inter-bras), le bras
graphe a obtenu un score plus faible contre deux des trois adversaires
gelés et pas meilleur contre le troisième, sur **cinq graines par
bras** (les graines 4–5 ont été ajoutées après l'analyse à trois
graines, symétriquement et sous un pré-engagement d'utiliser toutes les
graines quelle que soit la direction, D-031 ; l'analyse à trois graines
a abouti au même verdict) :

| graphe − grille | Exemples égaux | Temps mural égal |
| --- | --- | --- |
| vs aléatoire légal | −0.169 [−0.272, −0.062] | −0.161 [−0.278, −0.048] |
| vs heuristique | −0.064 [−0.111, −0.017] | −0.059 [−0.087, −0.029] |
| vs MCTS à 6400 sim | −0.009 [−0.055, +0.028] | −0.018 [−0.066, +0.025] |

(Moyennes au niveau des graines ; bootstrap à 95% sur cinq graines par
bras ; valeurs par graine dans les tables de résultats — aucun rapport
de « meilleure graine » nulle part. La plus grande borne supérieure sur
les six contrastes est +0.028.)

La lecture à temps mural aggrave le résultat : le coût mesuré du bras
graphe était de 2.0× par exécution (35.7 vs 18.2 h), de sorte qu'à
heures égales il ne complète que 4–5 des 10 générations — un déficit
que la lecture par exemple montre déjà et que le temps égal ne fait
qu'élargir.

La fig. 5 décompose les scores agrégés en trajectoires par adversaire
pour les 10 exécutions de la campagne principale ; la fig. 6 rapporte
les métriques d'ajustement d'entraînement (politique et valeur) par
génération — les deux bras ajustent leurs données d'auto-jeu tout du
long, de sorte que l'écart n'est pas un simple échec d'optimisation.

## La troncature, rapportée séparément et mise à l'épreuve

La différence comportementale la plus nette n'est pas un score mais une
catégorie d'issue : contre l'aléatoire légal, le bras graphe a tronqué
20–57% de ses parties au plafond de 300 demi-coups sur les graines
originales et 23–44% sur les graines d'extension (grille : 0–1%, avec
une graine d'extension à 11%) — gagnant du matériel puis échouant à
convertir (fig. 4, F1). Parce que la troncature a été définie dès le
départ comme une issue à part entière, cette pathologie est visible au
lieu d'être blanchie en nulles ; la fig. 7 trace les taux par
exécution contre l'aléatoire légal. La valeur du plafond ne peut pas sauver
l'hypothèse : même en comptant chaque partie tronquée comme une
victoire du graphe — une borne supérieure pour tout plafond plus
grand — le bras graphe reste derrière sur l'adversaire aléatoire sous
les deux lectures (−0.072 / −0.058).

## Ce que cela montre et ne montre pas

Cela montre : pour un réseau relationnel simple à passage de messages,
à capacité appariée (+2.1%), partageant tous les autres composants avec
le bras grille — règles, recherche, décodeur, enregistrements,
conventions d'entraînement, adversaires gelés, ouvertures gelées,
évaluation épinglée — l'encodage en plans de grille a appris davantage
par exemple ET par heure à ce petit budget, et la faiblesse du bras
graphe se concentre dans la conversion tactique locale, en accord avec
l'asymétrie local-vs-longue-portée rapportée pour Hex sous DQN (Keller
et al. 2023), ici observée sous auto-jeu apparié de style AlphaZero
dans un jeu sans cadre, à empilement.

Cela ne montre pas : quoi que ce soit sur les représentations en graphe
à plus grands budgets, sur d'autres architectures de graphe ou sur
d'autres jeux ; ni que les bras ne se réordonneraient pas avec
davantage de générations (10 relève du régime précoce ; tous les scores
contre les lignes de base fortes restent bas). Cinq graines par bras
bornent la statistique ; le rejet est cohérent entre graines, et les
graines d'extension (ajoutées sous pré-engagement) ont resserré quatre
des six intervalles.

## Coûts (dans les deux dénominations, selon plan ch. 6)

Fig. 2 : paramètres 1.44M vs 1.47M ; inférence au meilleur fournisseur
2.62 ms (CoreML) vs 3.67 ms (CPU) ; auto-jeu 13.1 vs 25.7 s/partie ;
score contre la population 0.412 vs 0.327 (exemples égaux), 0.402 vs
0.321 (temps mural égal).

## Provenance

Population gelée le 2026-09-09 (D-017) ; protocole gelé le 2026-09-10
(D-020) ; ouvertures gelées le 2026-09-10 (D-025) — le tout avant toute
exécution de comparaison. Campagne approuvée et lancée le 2026-09-10
(D-026) ; T\* calculé le 2026-09-16 à partir des seuls temps muraux de
la grille ; aucune retouche d'adversaire, d'ouverture ou de protocole
n'est survenue à aucun moment. Résultat négatif conservé et rapporté
selon l'invariant 5 et le protocole §1 : le travail n'a pas besoin que
H1 soit confirmée pour compter.

## Les ablations (H-T3)

Deux ablations à un seul composant contre la méthode graphe complète,
trois graines chacune à pleine parité de budget, plus un supplément
étiqueté. Retirer les relations d'arêtes typées par direction (A1,
adjacence naïve) a détruit d'emblée l'entraînabilité — divergence NaN à
la génération 0 pour chaque graine — de sorte que les arêtes typées
portent, au minimum, la stabilité d'optimisation du bras. Retirer le
biais de pooling global (A2) a produit un résultat nul : des variations
de score de −0.001 [−0.170, +0.165], −0.007 [−0.043, +0.030] et −0.013
[−0.043, +0.013] contre les trois adversaires, avec des modes de
défaillance inchangés. Le supplément A1′ (arêtes non typées plus
écrêtage de gradient — une variante explicitement à deux composants,
jamais attribuée au seul typage) s'entraîne de façon stable et obtient
des scores dans la bande du bras complet contre les trois adversaires,
ce qui suggère que la contribution mesurable des relations typées à
cette échelle se concentre dans la stabilité d'optimisation plutôt que
dans la force finale — un énoncé qui hérite du facteur de confusion de
l'écrêtage et qui est formulé en conséquence partout où il apparaît.
