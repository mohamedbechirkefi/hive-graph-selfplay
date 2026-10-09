# Introduction {#sec:introduction}

## Contexte : apprendre à jouer par auto-jeu, et le coût de la représentation

Depuis AlphaZero, la recette dominante pour apprendre à jouer à un jeu
de plateau sans exemples humains est restée stable : un réseau de
neurones estime, pour une position, une distribution de probabilité sur
les coups (la *politique*) et une issue attendue (la *valeur*) ; une
recherche arborescente Monte-Carlo guidée par le réseau produit des
décisions plus fortes que le réseau seul ; les parties que la recherche
joue contre elle-même deviennent les données d'entraînement du réseau
suivant (Silver et al., 2018). La recette est générale, mais l'un de ses
ingrédients ne l'est pas : la manière dont une position est présentée au
réseau. Pour les échecs, le shogi et le Go, la réponse allait de soi :
le plateau est un tableau rectangulaire fixe, et une position devient
une pile de plans semblables à une image, lus par un réseau convolutif.
Le succès de cet encodage en *grille* repose sur une propriété que ces
jeux partagent : chaque case existe à chaque instant, à une place fixe.

Hive ne possède pas cette propriété. C'est un jeu à deux joueurs et à
information parfaite, joué avec des tuiles hexagonales et sans
plateau : les tuiles elles-mêmes forment la surface de jeu (la
*ruche*), cette surface change de forme à chaque tour, les tuiles
peuvent grimper les unes sur les autres, et un coup se décrit au mieux
par « cette pièce va vers cette cellule » sur un ensemble de cellules
qui n'existe que relativement à la ruche courante. L'objet mathématique
naturel pour une telle position est un graphe plutôt qu'une image, avec
les cellules comme nœuds, l'adjacence comme arêtes et les piles comme
attributs de nœud ; le réseau naturel est alors un réseau de neurones en
graphe, qui lit directement un graphe de taille variable et n'a besoin
d'aucun cadre. Les encodages en grille peuvent néanmoins s'appliquer à
Hive en dépliant la ruche dans un grand cadre fixe, comme l'ont fait
jusqu'ici tous les systèmes d'apprentissage pour ce jeu ; mais cela
introduit des choix d'ancrage, de l'espace vide et un très grand espace
de coups discret dont le réseau doit apprendre la structure à partir de
zéro.
<!-- src: paper/ch1-introduction.md:5; docs/representations/grid.md -->

## Le problème : une intuition qui coupe dans les deux sens

Il est tentant de conclure qu'un encodage en graphe doit nécessairement
mieux apprendre Hive. Cette étude a été conçue parce que l'intuition est
véritablement incertaine. D'un côté, un réseau en graphe épouse la
structure native du jeu et ne porte aucun artefact d'ancrage. De
l'autre, l'issue d'une partie de Hive se joue sur des tactiques
d'*encerclement* à courte portée (une abeille reine perd lorsque ses
six cellules voisines sont occupées), et la reconnaissance de motifs à
courte portée est précisément le régime où la localité convolutive est
la plus forte. De plus, un graphe sur les seules cellules *occupées* ne
peut exprimer les destinations légales d'un coup, qui sont des
propriétés de l'espace vide ; le graphe doit donc porter des cellules
candidates vides, et l'on ne sait pas si un réseau simple à passage de
messages, recevant un tel graphe, apprend les contraintes de glissement,
d'escalade et de connexité des règles mieux qu'un réseau convolutif
recevant le cadre déplié.
<!-- src: docs/protocol.md:24; paper/ch1-introduction.md:13 -->

Les résultats antérieurs ne tranchent pas la question. La seule étude
publiée de type AlphaZero sur Hive a comparé cinq encodages de plateau
et constaté que le choix de l'encodage modifie mesurablement
l'apprentissage, mais les cinq étaient des encodages en grille et les
moteurs obtenus restaient plus faibles qu'une recherche classique sans
apprentissage (de Goede et al., 2022). Les deux comparaisons directes
grille-contre-graphe menées sur d'autres jeux pointent dans des
directions opposées : à Hex, sous un apprenant fondé sur la valeur
plutôt que par auto-jeu, un réseau en graphe a dominé sur les
dépendances à longue portée tandis que le réseau convolutif restait plus
affûté sur les motifs locaux (Keller et al., 2023) ; aux échecs, sous
auto-jeu, un réseau à attention sur graphe a surpassé les lignes de base
convolutives, bien qu'à partir d'une seule exécution d'entraînement par
modèle et sans réplication par graines (Rigaux & Kashima, 2024). Aucune de ces
études n'a fait tourner les deux bras sous un même pipeline d'auto-jeu,
à capacité appariée, sous un budget apparié, avec plusieurs exécutions
d'entraînement indépendantes par bras, sur Hive.
`@sec:related`{=typst} développe ce positionnement.
<!-- src: paper/ch3-related-work.md; docs/reading/matrix.md:26 -->

## Questions de recherche et hypothèse

L'étude pose une question principale et deux questions secondaires.

- **RQ-H1 (représentation).** À budget d'entraînement comparable, une
  architecture en graphe apprend-elle une meilleure politique qu'une
  architecture en grille pour Hive en jeu de base, au sein d'un pipeline
  d'auto-jeu de type AlphaZero ?
- **RQ-H2 (efficacité).** Comment les deux représentations se
  comparent-elles lorsque le budget est lu comme un nombre d'exemples
  d'entraînement, et lorsqu'il est lu comme un temps mural sur le même
  matériel ?
- **RQ-H3 (composants).** Quels composants de l'architecture en graphe
  portent son comportement, en particulier ses relations typées par
  direction et son pooling global ?
<!-- src: docs/protocol.md:15; paper/ch5-protocol.md -->

L'hypothèse testée, **H1**, énonce qu'un réseau en graphe simple à
passage de messages, recevant la ruche sous forme de graphe, atteint un
score moyen plus élevé contre une population d'adversaires fixe qu'un
réseau convolutif en grille recevant un cadre déplié de 32×32, à budget
d'entraînement égal. H1 n'a pas été présumée vraie : le protocole
(`@sec:protocol`{=typst}) énonce explicitement qu'un résultat négatif ou
nul est une issue publiable, et il a fixé, avant toute exécution
comparative, les adversaires, les ouvertures, les budgets, les réglages
d'évaluation, l'unité statistique et la règle par laquelle H1 serait
rejetée.
<!-- src: docs/protocol.md:19 -->

## Ce qui a été fait

Les deux encodages ont été construits derrière un décodeur d'actions
partagé unique, sur un moteur validé côté règles ; les deux réseaux ont
été appariés en capacité à +1.5% près (1.44 M contre 1.47 M
paramètres) ; cinq graines indépendantes par bras ont été entraînées
sous des réglages d'auto-jeu identiques pendant dix générations de 500
parties chacune ; la comparaison a été lue de deux façons, à exemples
d'entraînement égaux et à temps mural égal à un seuil pré-enregistré,
contre une population gelée de trois adversaires (aléatoire légal, une
heuristique documentée et un agent de recherche sans réseau à 6,400
simulations) sur 250 ouvertures gelées, la troncature étant traitée tout
du long comme une issue de premier ordre. Deux ablations ont retiré
chacune un composant du bras graphe à parité complète, et une troisième
exécution, explicitement à deux composants, a complété la première
ablation après que celle-ci s'est révélée inentraînable.
<!-- src: paper/ch1-introduction.md:25; docs/representations/comparison-controls.md:14 -->

## Ce qui a été trouvé

L'hypothèse est rejetée. Le bras grille obtient un score supérieur
contre deux des trois adversaires sous les deux lectures budgétaires,
pour environ la moitié du coût en temps mural ; la plus grande borne
supérieure de tout intervalle sur un avantage du graphe est +0.028. Le
déficit du bras graphe se concentre dans la conversion tactique locale :
il gagne du matériel contre l'adversaire aléatoire puis échoue à
conclure, tronquant 20–57% de ces parties là où le bras grille n'en
tronque presque aucune. Les ablations localisent la machinerie du bras
graphe : ses relations typées par direction sont nécessaires à
l'optimisation elle-même (les retirer a fait diverger l'entraînement
pour chaque graine), tandis que son pooling global est dispensable.
<!-- src: paper/ch1-introduction.md:32; results/comparison/results-arm-difference.md -->

## Contributions

Trois contributions sont revendiquées, chacune vérifiable à partir du
dépôt publié.

1. **La première comparaison grille-contre-graphe contrôlée, à budget
   apparié et multi-graines pour Hive**, les deux bras étant placés sous
   le même pipeline de type AlphaZero, lus sous deux égalisations de
   budget, avec une réponse négative pré-enregistrée
   (`@sec:results-main`{=typst}, `@sec:results-cost`{=typst} ;
   enregistrements bruts publiés).
2. **Un harnais de comparaison reproductible pour les jeux sans cadre et
   à empilement** : un moteur de règles validé indépendamment de
   l'apprentissage ; deux encodeurs épinglés à l'octet près entre deux
   langages d'implémentation ; un décodeur partagé sur un ensemble
   d'actions variable ; une évaluation consciente de la troncature ; et
   une discipline d'artefacts gelés (`@sec:engine`{=typst} à
   `@sec:protocol`{=typst}).
3. **Une attribution par composant pour le bras graphe**, dans laquelle
   les relations typées déterminent l'entraînabilité et le pooling a un
   effet nul, avec un supplément à deux composants honnêtement étiqueté
   (`@sec:results-ablations`{=typst}).

La construction de logiciel, si substantielle soit-elle, n'est pas
comptée comme une contribution scientifique en soi ; elle est rapportée
parce que le résultat ne peut être évalué sans elle.

## Organisation de ce rapport

La partie I pose le problème : `@sec:background`{=typst} donne les
règles de Hive, la formalisation utilisée et les éléments d'apprentissage
par auto-jeu, de représentation d'état et d'évaluation sur petits
échantillons dont un lecteur a besoin ; `@sec:related`{=typst}
positionne l'étude par rapport aux travaux antérieurs. La partie II
décrit comment le système a été construit, et quand
(`@sec:chronology`{=typst}) : le moteur et sa validation
(`@sec:engine`{=typst}), le pipeline d'apprentissage
(`@sec:pipeline`{=typst}), les deux représentations et leurs réseaux
(`@sec:representations`{=typst}) et la population d'adversaires gelée
(`@sec:baselines`{=typst}). La partie III expose la méthodologie et les
raisons de son choix : le protocole expérimental pré-enregistré
(`@sec:protocol`{=typst}) et la méthode de travail humain-IA à portes
(`@sec:working-method`{=typst}). La partie IV rapporte les résultats
par question : la comparaison principale (`@sec:results-main`{=typst}),
le coût et l'efficacité (`@sec:results-cost`{=typst}), les ablations
(`@sec:results-ablations`{=typst}) et une analyse qualitative des
positions d'échec et du comportement d'entraînement
(`@sec:results-qualitative`{=typst}). La partie V discute les
mécanismes et les menaces à la validité (`@sec:discussion`{=typst}) et
conclut (`@sec:conclusion`{=typst}). La bibliographie et la webographie
suivent la conclusion. Les annexes contiennent les corpus de positions
annotées, les architectures et les formats de données en entier, chaque
hyperparamètre et chaque graine, les procédures statistiques avec les
tables brutes par graine, la provenance de chaque résultat, un glossaire
avec les équivalents français et le guide de reproduction.

## Comment lire les nombres

Chaque score de ce rapport est une moyenne sur les parties *décidées*
contre un adversaire gelé, avec victoire = 1, nulle = 0.5 et
défaite = 0 ; les parties arrêtées au plafond expérimental de 300 plis
sont comptées séparément comme *troncatures* et ne sont jamais comptées
comme des nulles. Chaque intervalle est un intervalle bootstrap
percentile à 95% dont l'unité de rééchantillonnage est l'exécution
d'entraînement indépendante (la *graine*), et non la partie : mille
parties jouées par un réseau sont une observation de ce réseau, non
mille observations de la méthode. Les différences entre bras s'écrivent
graphe moins grille, de sorte qu'un nombre négatif favorise le bras
grille. Tous les nombres remontent aux enregistrements bruts par partie
par la chaîne documentée en `@sec:app-e`{=typst}.
<!-- src: docs/protocol.md:79; docs/protocol.md:124 -->
