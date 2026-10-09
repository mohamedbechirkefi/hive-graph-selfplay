# Conclusion et perspectives {#sec:conclusion}

## La réponse à la question de recherche

Le périmètre testé est Hive en jeu de base, un réseau relationnel simple
à passage de messages à capacité appariée contre un réseau convolutif en
grille, dix générations d'auto-jeu à petit budget, cinq graines
indépendantes par bras, une population gelée de trois adversaires et 250
ouvertures gelées. À l'intérieur de ce périmètre, **la réponse à la
question de recherche principale est non** : la représentation en graphe n'a pas
appris une meilleure politique que la représentation en grille, ni
lorsque les deux bras ont consommé le même nombre d'exemples
d'entraînement, ni lorsque les deux ont reçu le même temps mural sur la
même machine, et la règle de rejet pré-enregistrée s'est déclenchée
exactement telle qu'elle avait été gelée. Le déficit du bras graphe est
le plus grand là où Hive est le plus tactique (contre l'adversaire
aléatoire légal, −0.169 et −0.161 sous les deux lectures) et net contre
l'adversaire heuristique (−0.064 et −0.059) ; contre l'adversaire de
recherche, les deux bras sont indiscernables (−0.009 et −0.018,
intervalles chevauchant zéro). Le bras graphe paie environ deux fois le
temps mural par exécution. Son mode de défaillance caractéristique
consiste à gagner du matériel sans convertir le gain ; il se manifeste
en ce que 20–57% de ses parties contre l'adversaire aléatoire se
terminent au plafond de coups, et il n'est observable que parce que la
troncature n'a jamais été repliée en nulles.
<!-- src: results/comparison/results-arm-difference.md; paper/ch8-conclusion.md:5 -->

Le résultat borne, plutôt qu'il ne contredit, les constats positifs
rapportés pour les graphes à Hex sous apprentissage fondé sur la valeur
et aux échecs sous auto-jeu. Là où les tactiques d'encerclement à courte
portée décident des parties et où les budgets sont petits, les artefacts
de cadre d'un encodage en grille se révèlent moins coûteux que l'absence
de cadre. L'analyse par composant ajoute une lecture mécaniste : des
deux composants distinctifs du bras graphe, les relations typées par
direction sont nécessaires à l'optimisation elle-même (les retirer à
réglages identiques a fait diverger l'entraînement pour chaque graine),
tandis que le biais de pooling global est dispensable à cette échelle.
<!-- src: paper/ch8-conclusion.md:15; results/ablations/README.md -->

## Contributions, telles que démontrées

Trois contributions ont été annoncées en `@sec:introduction`{=typst} ;
chacune est démontrée dans les chapitres qui y sont nommés. (1) Une
comparaison grille-contre-graphe contrôlée, à budget apparié et
multi-graines pour Hive, les deux bras sous un même pipeline d'auto-jeu,
avec une réponse négative pré-enregistrée (`@sec:results-main`{=typst},
`@sec:results-cost`{=typst}). (2) Un harnais de comparaison
reproductible pour les jeux sans cadre et à empilement, publié avec les
enregistrements bruts : un moteur validé côté règles, deux encodeurs
épinglés à l'octet près entre deux langages, un décodeur partagé à
actions variables, une évaluation consciente de la troncature et une
discipline d'artefacts gelés (`@sec:engine`{=typst} à
`@sec:protocol`{=typst}). (3) Une attribution par composant pour le bras
graphe, avec un supplément à deux composants honnêtement étiqueté
(`@sec:results-ablations`{=typst}).

## Deux suites motivées par les données

La première suite vise la **pathologie de conversion**, que les données
isolent comme un défaut de politique plutôt qu'un défaut de valeur :
l'exactitude de la valeur du bras graphe en entraînement est comparable
à celle du bras grille, tandis que sa politique échoue sur les séquences
forcées (`@sec:results-qualitative`{=typst}). Une expérience naturelle
est un remède au moment de la recherche, appliqué à l'identique aux deux
bras sous la même évaluation gelée, en tant que changement à un seul
composant du pipeline partagé : un budget d'évaluation plus profond dans
les positions que la tête de valeur juge déjà gagnées, ou des cibles
d'entraînement auxiliaires pour les coups forçants. La seconde suite
concerne le **constat de stabilité** : l'ablation et son supplément ont
montré que les relations typées par direction importent surtout pour
l'optimisation à cette échelle, mais l'écrêtage de gradient du
supplément confond l'attribution. Une étude contrôlée des choix de
normalisation et d'échelle de gradient pour des couches de graphe à
relations partagées découplerait l'entraînabilité du contenu
représentationnel et dirait si l'adjacence naïve, correctement
stabilisée, est suffisante pour Hive.
<!-- src: paper/ch8-conclusion.md:19 -->

## Une méthode qui tient indépendamment du signe

Le pré-enregistrement avec artefacts gelés, les deux lectures
budgétaires, la troncature comme issue, l'inférence au niveau des
graines et la rédaction au fil de l'avancement des travaux ont
transformé une réponse négative en un objet scientifique utilisable sur
un seul ordinateur portable. La même discipline, décrite en
`@sec:working-method`{=typst} avec les incidents qu'elle a détectés,
est la part de ce travail la plus directement transférable à d'autres
études à petit budget de calcul.
