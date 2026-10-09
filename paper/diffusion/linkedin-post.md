# LinkedIn post drafts (for the author to post; nothing is published by the runtime)

Both drafts state the result as the report states it: a pre-registered
negative result inside a stated perimeter, no claim beyond it. Numbers
are those of the final five-seed analysis. Replace `<link>` with the
arXiv or repository link once diffusion is approved (G-PUBLIC).

## Version française

J'ai terminé une étude de recherche indépendante que je prépare en vue
d'une candidature doctorale, et je la rends publique aujourd'hui :
« Représentations en grille et en graphe pour l'apprentissage par
auto-jeu à Hive : une comparaison pré-enregistrée sous budget de calcul
limité ».

La question : pour un jeu sans plateau comme Hive, où les pièces forment
elles-mêmes la surface de jeu, un réseau de neurones en graphe
apprend-il mieux qu'un réseau convolutif sur grille, à budget égal, dans
une boucle d'auto-jeu de type AlphaZero ? L'intuition dit oui. Le
protocole, gelé avant toute exécution comparative, disait aussi qu'un
résultat négatif serait publié tel quel.

Le résultat est négatif. Sur cinq graines indépendantes par bras, sous
deux lectures du budget (mêmes exemples d'entraînement, même temps
mural), le bras graphe obtient un score inférieur contre deux des trois
adversaires gelés, à un coût en temps double, et son déficit se
concentre dans la conversion des positions gagnées. Les ablations
montrent que ses relations typées par direction sont nécessaires à la
stabilité de l'optimisation, et que son pooling global est dispensable.

Ce qui m'importe autant que le résultat, c'est la méthode : protocole et
adversaires gelés avec leurs empreintes, troncature traitée comme une
issue à part entière, la graine comme unité statistique, reproduction
en environnement neuf octet-identique, et un rapport de 157 pages (172
en français) où chaque nombre remonte à un enregistrement brut. L'étude
a été menée avec un assistant IA sous un système de portes qui me
réservait chaque décision scientifique ; le rapport documente cette
méthode de travail et ce qu'elle a permis d'attraper.

Perimètre et limites sont écrits noir sur blanc : une variante, une
architecture de graphe, un petit budget sur un seul ordinateur
portable, dix générations en régime précoce. Une étude complémentaire
avec démarrage à chaud et fenêtre de rejeu est la suite logique.

Rapport et code : https://github.com/mohamedbechirkefi/hive-graph-selfplay/releases/tag/v2.0-report (prépublication arXiv à suivre)

## English version

I have completed an independent research study, prepared in view of a
doctoral application, and I am making it public today: "Grid vs. Graph
Representations for Self-Play Learning in Hive: a Pre-Registered
Comparison under Limited Compute".

The question: for a boardless game like Hive, where the pieces
themselves form the playing surface, does a graph neural network learn
better than a convolutional network over a grid, at equal budget, in an
AlphaZero-style self-play loop? Intuition says yes. The protocol, frozen
before any comparison run, also said that a negative result would be
published as is.

The result is negative. Over five independent seeds per arm and under
two readings of the budget (same training examples, same wall-clock),
the graph arm scores lower against two of the three frozen opponents, at
twice the time cost, and its deficit concentrates in converting won
positions. Ablations show that its direction-typed relations are
necessary for optimization stability, and that its global pooling is
dispensable.

The method matters to me as much as the result: a frozen protocol and
frozen opponents identified by hash, truncation treated as an outcome of
its own, the seed as the statistical unit, a byte-identical
fresh-environment reproduction, and a 157-page report (172 in French)
in which every number traces to a raw record. The study was carried out
with an AI assistant under a gate system that reserved every scientific
decision to me; the report documents that working method and what it
caught.

Scope and limits are stated plainly: one variant, one graph
architecture, a small budget on a single laptop, ten generations in an
early regime. A follow-up study with warm starts and a replay window is
the natural next step.

Report and code: https://github.com/mohamedbechirkefi/hive-graph-selfplay/releases/tag/v2.0-report (arXiv preprint to follow)
