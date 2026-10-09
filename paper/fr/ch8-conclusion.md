*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 9 — Conclusion (brouillon du livret, 2026-10-09)

*Aucun résultat nouveau ici, conformément au plan.*

À l'intérieur du périmètre testé — Hive en jeu de base, un réseau
relationnel simple à passage de messages à capacité appariée contre un
CNN grille, dix générations d'auto-jeu à petit budget, cinq graines par
bras, une population gelée de trois adversaires — **la réponse à RQ-H1
est non** : la représentation en graphe n'a pas appris une meilleure
politique que la représentation en grille, ni sous la lecture à
exemples égaux ni sous la lecture à temps mural égal, et la règle de
rejet pré-enregistrée s'est déclenchée exactement telle que gelée. Le
déficit est le plus grand là où Hive est le plus tactique, le bras
graphe paie deux fois le temps mural, et son mode de défaillance —
gagner du matériel sans convertir — est visible précisément parce que
la troncature n'a jamais été repliée en nulles. Le résultat ne
contredit pas les constats positifs pour les graphes sur Hex et aux
échecs ; il les borne : là où la tactique à courte portée décide des
parties et où les budgets sont petits, les artefacts de cadre coûtent
moins cher que l'absence de cadre.

Deux suites sont motivées par les données plutôt que par l'espoir.
Premièrement, **la pathologie de conversion est un défaut ciblable** :
la tête de valeur du bras graphe apprend honorablement tandis que sa
politique échoue sur les séquences forcées, ce qui suggère une
expérience sur des remèdes au moment de la recherche (budgets
d'évaluation plus profonds dans les positions gagnées, ou cibles
auxiliaires pour les coups forçants) sous la même évaluation gelée —
un changement à un seul composant du pipeline partagé, applicable aux
deux bras. Deuxièmement, **le constat de stabilité mérite d'être
isolé** : A1/A1′ ont montré que les relations typées par direction
importent surtout pour l'optimisation à cette échelle ; une étude
contrôlée des choix de normalisation et d'échelle de gradient pour des
couches de graphe à relations partagées pourrait découpler
l'entraînabilité du contenu représentationnel — et dirait si
l'adjacence naïve, correctement stabilisée, est véritablement
suffisante pour Hive.

La méthode plus large tient indépendamment du signe du résultat : le
pré-enregistrement avec artefacts gelés, les doubles lectures de
budget, la troncature comme issue, l'inférence au niveau des graines et
la rédaction au fil de l'eau ont transformé une réponse négative en un
objet scientifique utilisable sur un seul ordinateur portable.
