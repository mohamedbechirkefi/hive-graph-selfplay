*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 1 — Introduction (brouillon du livret, 2026-10-09)

*Rédigé en dernier hormis le résumé, selon l'ordre du plan, à partir
des résultats finaux.*

**La question.** Hive est un jeu de stratégie hexagonal sans plateau :
les pièces définissent la surface de jeu, des piles se forment et se
défont, et chaque coup est une paire (pièce, destination) sur un
ensemble de cellules qui change à chaque tour. Les encodages en
grille — la lingua franca convolutive des systèmes de type
AlphaZero — doivent plaquer un cadre sur ce jeu sans cadre. Un encodage
en graphe n'a besoin d'aucun cadre. Il est naturel de s'attendre à ce
que le graphe l'emporte. Est-ce le cas, à un budget de calcul qu'une
seule machine peut se permettre ?

**Pourquoi ce n'est pas évident.** L'intuition coupe dans les deux
sens. Les réseaux en graphe épousent la structure native du jeu et ne
portent aucun artefact d'ancrage ; mais l'issue d'une partie de Hive se
joue sur des tactiques d'encerclement à courte portée — le régime où la
localité convolutive est la plus forte — et les résultats antérieurs
divergent : des bras graphe l'ont emporté à Hex sous DQN (Keller et al.
2023) et aux échecs sous auto-jeu (Rigaux & Kashima 2024, à partir
d'exécutions uniques), tandis que la seule étude AlphaZero-sur-Hive
(de Goede et al. 2022) n'a jamais essayé de graphe. L'hypothèse a été
énoncée de façon falsifiable et gelée avant toute exécution
comparative, avec tout ce qui pouvait infléchir la réponse :
adversaires, ouvertures, budgets, réglages d'évaluation et la règle de
rejet elle-même.

**Ce que nous avons fait.** Nous avons construit les deux encodages
derrière un décodeur d'actions partagé unique, sur un moteur validé
côté règles, apparié la capacité à +2.1%, et entraîné cinq graines
indépendantes par bras sous des réglages d'auto-jeu identiques, en
lisant la comparaison de deux façons — à exemples d'entraînement égaux
et à temps mural égal — contre une population gelée de trois
adversaires sur 250 ouvertures gelées, la troncature étant traitée tout
du long comme un résultat de premier ordre.

**Ce que nous avons trouvé.** L'hypothèse est rejetée. Le bras grille
obtient un score supérieur contre deux des trois adversaires sous les
deux lectures (plus grande borne supérieure d'intervalle pour un
avantage du graphe : +0.028), pour la moitié du coût en temps mural ;
le déficit du bras graphe se concentre dans la conversion tactique
locale — il gagne du matériel contre l'adversaire aléatoire puis échoue
à conclure, tronquant 20–57% de ces parties là où le bras grille n'en
tronque presque aucune. Les ablations localisent la machinerie du bras
graphe : ses relations d'arêtes typées par direction sont porteuses
pour l'optimisation elle-même (les retirer fait diverger l'entraînement
pour chaque graine), tandis que son agrégation globale est dispensable.

**Contributions.** (1) La première comparaison grille-contre-graphe
contrôlée, à budget apparié et multi-graines pour Hive, les deux bras
sous le même pipeline de type AlphaZero, avec une réponse négative
pré-enregistrée — chapitre 6 et `results/comparison/`. (2) Un harnais
de comparaison reproductible pour les jeux sans cadre et à
empilement : un moteur de règles validé avec des encodeurs
inter-langages épinglés par fichiers dorés (golden-pinned), un décodeur
partagé à actions variables, une machinerie d'évaluation consciente de
la troncature et une discipline d'artefacts gelés — chapitres 4–5 et le
code publié. (3) Une attribution par composant pour le bras graphe
(typage des arêtes = entraînabilité ; agrégation globale = effet nul)
avec un supplément honnêtement étiqueté — chapitre 6 (H-T3) et
`results/ablations/`.

Chaque contribution est vérifiable depuis le dépôt : chaque nombre de
ce livret remonte à une entrée de journal et se régénère par scripts à
partir des enregistrements bruts par partie.
