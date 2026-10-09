*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Pages liminaires (livret v1, 2026-10-09)

**Titre.** Représentations en grille et en graphe pour l'apprentissage
par auto-jeu à Hive : une comparaison pré-enregistrée sous budget de
calcul limité *(Grid vs. Graph Representations for Self-Play Learning
in Hive: a Pre-Registered Comparison under Limited Compute)*

*(Descriptif, sans résultat présumé, selon plan ch. 20.)*

**Auteur.** Mohamed Bechir Kefi

**Statut.** Rapport de recherche indépendant — non évalué par les
pairs, et qui n'est la publication d'aucune institution. Version
1.0-draft, 2026-10-09.

**Code et artefacts.** Dépôt `hive-graph-selfplay` (étiquette de
publication et accès à fixer au moment de la diffusion, G-PUBLIC) ;
manifeste des résultats sous `results/` ; chaque figure et chaque table
se régénèrent par scripts à partir des enregistrements bruts par
partie.

**Déclaration d'assistance par IA.** Cette étude a été exécutée selon
une méthodologie « l'humain comme chercheur principal » (human-as-PI)
dans laquelle un assistant de recherche IA (Claude, Anthropic) a
implémenté le code, mené les campagnes et rédigé le texte sous un
système de portes réservant toutes les décisions scientifiques — gels,
budgets, dépenses, publication — à l'auteur humain, qui assume chaque
affirmation. Le chapitre 8 documente cette méthodologie de travail en
entier ; le document source vit dans le dépôt (`docs/methodology.md`).

**Résumé (164 mots dans la version anglaise).** Hive est un jeu de
stratégie hexagonal sans plateau dont les coups sont des paires (pièce,
destination) sur un ensemble de cellules en perpétuel changement — un
candidat naturel, en principe, pour des encodages par réseaux de
neurones en graphe plutôt que pour les encodages convolutifs en grille
standards des systèmes de type AlphaZero. Nous testons cette intuition
sous un protocole pré-enregistré, gelé avant toute exécution
comparative : un CNN en grille et un réseau relationnel à passage de
messages de capacité appariée (+2.1%) partagent un moteur validé côté
règles, un décodeur d'actions unique, des réglages d'entraînement
identiques, une population gelée de trois adversaires et 250 ouvertures
gelées, évalués sous deux lectures budgétaires (à exemples
d'entraînement égaux ; à temps mural égal à un seuil pré-enregistré),
avec cinq graines indépendantes par bras et la troncature rapportée
comme un résultat à part entière. L'hypothèse est rejetée : le bras
graphe obtient un score inférieur contre deux des trois adversaires
sous les deux lectures, à un coût en temps mural double, son déficit se
concentrant dans la conversion des positions gagnées. Les ablations
montrent que les relations d'arêtes typées du bras graphe sont
porteuses pour la stabilité de l'optimisation, tandis que son
agrégation globale (global pooling) est dispensable. Négatif,
pré-enregistré et entièrement reproductible à partir des
enregistrements publiés.

**Mots-clés.** Hive ; AlphaZero ; réseaux de neurones en graphe ;
apprentissage de représentations ; pré-enregistrement ; résultat
négatif

**Table des matières.** 1 Introduction · 2 Formalisation · 3 Travaux
connexes · 4 Méthode (validation du moteur ; lignes de base ;
pipeline ; représentations) · 5 Protocole · 6 Résultats (comparaison ;
ablations) · 7 Discussion et menaces · 8 Méthodologie de travail
(humain–IA sous portes) · 9 Conclusion · Bibliographie · Webographie ·
Annexe A Corpus de positions · Annexe B Architectures, décodeur,
formats · Annexe C Hyperparamètres, graines, commandes · Annexe D
Pointeurs vers le dépôt · Annexe E Tableaux de résultats et figures
(générés)
