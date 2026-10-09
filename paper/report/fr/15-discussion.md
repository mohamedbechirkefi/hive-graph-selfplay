# Discussion et menaces à la validité {#sec:discussion}

L'hypothèse a été rejetée exactement comme le protocole gelé définissait
le rejet. Ce chapitre demande ce que le résultat signifie, quelles
explications les données soutiennent et lesquelles elles ne font que
suggérer, comment le résultat se rapporte aux travaux antérieurs qui
l'ont motivé, et ce qui pourrait être erroné en lui. Les menaces sont
organisées comme le plan de recherche le prescrit : internes, de mesure,
statistiques et externes.

## Lire le résultat

Trois observations déterminent la manière dont le résultat doit être lu.

Premièrement, le déficit est modelé par l'adversaire. Il est le plus
grand contre l'adversaire aléatoire légal, net contre l'heuristique et
absent contre l'adversaire de recherche (`@tbl:contrast`{=typst}). Un bras
graphe qui serait simplement plus faible partout montrerait un déficit
uniforme ; un déficit concentré là où les parties se décident en
achevant un encerclement auquel rien ne résiste désigne la
*conversion tactique locale* plutôt que le jugement positionnel.
<!-- src: paper/ch7-discussion.md:7; results/comparison/results-arm-difference.md -->

Deuxièmement, le canal de troncature porte le mécanisme. Le bras
graphe gagne du matériel contre l'adversaire aléatoire puis échoue à
conclure : 20–57% de ces parties se terminent au plafond de 300
demi-coups, contre 0–11% pour le bras grille (`@fig:truncation`{=typst},
`@fig:failures`{=typst} F1). Ce motif est invisible dans toute étude qui
compte les parties plafonnées comme des nulles, et c'est pourquoi le
protocole a exigé, avant la première exécution, que la troncature soit
une issue à part entière.
<!-- src: results/comparison/results-same-examples.md:7 -->

Troisièmement, les ablations affinent la lecture. Aux réglages de
parité, retirer les relations typées par direction a fait plus
qu'affaiblir le bras graphe ; cela a détruit d'emblée l'entraînabilité
(divergence non finie à la génération 0 pour les trois graines), de
sorte que les relations typées portent au minimum la stabilité
d'optimisation du bras entier. Retirer le biais de pooling global a
modifié les scores de ≈0.00 ± 0.17, −0.01 ± 0.04 et −0.01 ± 0.03 contre
les trois adversaires, avec des modes de défaillance inchangés. La
machinerie distinctive du bras réside donc dans ses relations
directionnelles plutôt que dans son pooling. Une fois la variante naïve
stabilisée par écrêtage de gradient, cependant, elle joue dans la bande
du bras complet, de sorte que la contribution mesurable des relations
typées à cette échelle se concentre dans l'optimisation plutôt que dans
la représentation (`@sec:results-ablations`{=typst}).
<!-- src: paper/ch7-discussion.md:15; results/ablations/README.md -->

## Quelles explications sont démontrées, et lesquelles sont plausibles

Le plan de recherche distingue une explication démontrée par ablation
d'une explication simplement plausible. Quatre explications candidates
de l'écart méritent ce traitement.

*Géométrie (plausible, non démontrée).* La tactique de Hive est
dominée par la géométrie d'encerclement à courte portée, le régime dans
lequel Keller et al. (2023) ont trouvé les réseaux convolutifs plus
forts que les réseaux de graphes sur Hex. Une convolution 3×3 sur le
cadre déplié voit tout le voisinage d'une cellule, et les blocs
résiduels empilés voient le voisinage du voisinage, sans coût
d'apprentissage ; le réseau à passage de messages doit composer les
mêmes motifs à partir de six relations typées, un saut à la fois. Cela
est cohérent avec chacune des observations ci-dessus, mais aucune
ablation de cette étude n'isole la composition du champ récepteur, de
sorte que cela reste une hypothèse.
<!-- src: paper/ch7-discussion.md:30; docs/reading/keller-2023-graphdqn-hex.md -->

*Capacité (contrôlée).* Les deux réseaux diffèrent de +1.5% en nombre
de paramètres (1.44 M contre 1.47 M), en faveur du bras graphe. La
capacité n'explique pas un déficit du graphe.
<!-- src: docs/representations/comparison-controls.md:14 -->

*Décodeur (contrôlé).* Les deux bras scorent l'ensemble identique de
paires légales (pièce, destination) avec un masquage, une
normalisation, des cibles et un départage identiques ; le décodeur ne
peut favoriser aucun bras. Ce qui diffère est la *paramétrisation*
derrière l'interface partagée : un tenseur plat à 28,673 voies pour le
bras grille, une fonction de scorage par candidat pour le bras graphe.
Cette différence fait partie de ce que « représentation » signifie
dans cette étude plutôt que d'en être un facteur de confusion.
<!-- src: docs/action-decoder.md:40 -->

*Vitesse (démontrée pour la seconde lecture seulement).* Les
générations du bras graphe coûtent environ deux fois plus de temps mural
sur cette machine, de sorte qu'à temps égal il achève moins de la moitié
de ses générations (`@sec:results-cost`{=typst}). Cela élargit de façon
démontrable l'écart dans la lecture à temps mural égal ; cela ne joue
aucun rôle dans la lecture à exemples égaux, où le déficit existe déjà.
<!-- src: journal/2026-09-16-h6-progress-01.md:36 -->

*Optimisation (partiellement démontrée).* Les ablations montrent que
l'optimisation du bras graphe complet est fragile d'une manière précise
(elle dépend des relations typées pour sa stabilité), mais les courbes
d'entraînement du bras complet (`@fig:training`{=typst}) le montrent
ajustant ses données pour chaque graine. Rien n'indique que le bras
complet ait échoué à s'optimiser ; l'écart est un écart entre deux
réseaux entraînés. La question de savoir si un taux d'apprentissage ou
une normalisation différents auraient favorisé le bras graphe n'a pas
été testée, parce qu'aucun des deux bras n'a reçu de réglage. La
politique de réglage nul est symétrique, mais elle n'est pas neutre si
une architecture est plus sensible à ses valeurs par défaut, un point
repris sous la validité externe.
<!-- src: journal/2026-09-23-h7-a1-divergence-01.md:59; docs/representations/comparison-controls.md:52 -->

## Rapport aux travaux antérieurs

Le résultat ne contredit ni les constats positifs de Rigaux et Kashima
(2024) sur les graphes aux échecs, ni l'avantage à longue portée que
Keller et al. (2023) ont mesuré sur Hex. Il borne là où leur optimisme
se transfère. Le résultat aux échecs repose sur une seule exécution
d'entraînement par modèle avec des intervalles couvrant la seule
estimation Elo, un appariement de capacité lâche et des décodeurs
propres à chaque bras ; le résultat sur Hex a été obtenu avec un
apprenant fondé sur la valeur, avec une construction de graphe propre
au jeu, et a trouvé le bras convolutif plus aigu sur les motifs locaux,
c'est-à-dire le régime qui décide des parties de Hive aux petits budgets. Le
présent rejet est cohérent entre graines sur cinq exécutions par bras
sous deux lectures de budget pré-enregistrées, à capacité appariée et
avec le décodeur partagé. Lues ensemble, les trois études suggèrent que
le signe de la comparaison grille-contre-graphe dépend de la portée
tactique du jeu et du standard de preuve, plutôt que du paradigme des
graphes en tant que tel. L'unique étude antérieure de Hive de type
AlphaZero (de Goede et al., 2022) avait déjà montré que le choix
d'encodage change l'apprentissage au sein de la famille grille ; cette
étude étend le constat d'une famille à l'autre et trouve le côté grille
en avance.
<!-- src: paper/ch7-discussion.md:23; docs/reading/matrix.md:26 -->

## Validité interne : bogues et comparabilité

Le moteur est validé indépendamment de l'apprentissage : égalité perft
avec les tables publiées jusqu'à la profondeur 6 pour les huit types de
jeu, conformité de protocole 21/21, accord différentiel des ensembles de
coups légaux sur 27,829 positions avec deux moteurs de référence, un
corpus de 30 cas dérivé des règles et annoté avant toute exécution, et
10.9 millions de transitions aléatoires sans violation d'invariant
(`@sec:engine`{=typst}). Les deux encodeurs sont épinglés à l'octet près
contre des tests dorés (golden tests) inter-langages exécutés chaque
nuit (240 et 160 positions). Les bras partagent le décodeur, les
enregistrements, les fonctions de perte, les budgets, la recherche et
l'évaluation gelée ; la capacité diffère de +1.5% et est rapportée.
<!-- src: paper/ch7-discussion.md:36; docs/representations/comparison-controls.md:57 -->

Des risques résiduels demeurent. L'architecture graphe est un point de
l'espace de conception ; un réseau de graphes différent pourrait se
comporter différemment, et rien n'est affirmé au-delà de celui-ci. Des
défauts d'outillage ont été trouvés *pendant* l'étude : un chemin du
lanceur de matchs qui perdait des enregistrements lorsque chaque partie
d'un match était tronquée, une boucle d'entraînement qui laissait passer
silencieusement des valeurs non finies pendant dix générations, et un
générateur de résultats dont la moyenne de temps mural par exécution
divisait encore par les trois exécutions originales après l'extension à
cinq. Chacun a été attrapé par la discipline de vérification
(`@sec:working-method`{=typst}), corrigé et audité : le premier n'a
touché aucune donnée de campagne ; le second n'a affecté que l'ablation
qui l'a révélé et est devenu le résultat de cette ablation ; le
troisième a affecté deux lignes de la table des coûts et aucun score,
intervalle ni affirmation. Ils illustrent la leçon la plus pratique de
l'étude : à cette échelle, le mode de défaillance dominant est l'erreur
de harnais plutôt que le hasard, et seule la vérification mécanique
l'attrape.
<!-- src: paper/ch7-discussion.md:42; docs/methodology-log.md -->

## Validité de mesure : adversaires et troncature

Les scores sont relatifs à une population de trois adversaires fixes
couvrant une force du plancher au niveau intermédiaire ; aucune
affirmation de force universelle n'est faite. Tous les bras entraînés
perdent encore lourdement contre les deux lignes de base fortes après
dix générations, de sorte que la comparaison vit dans un régime de
scores bas où les différences contre l'adversaire de recherche ne
peuvent pas être résolues. La troncature est traitée comme une issue à
part entière avec des bornes de sensibilité : le plafond ne peut pas
renverser le verdict, mais les taux de troncature élevés du bras graphe
signifient que son score contre l'adversaire aléatoire est mesuré sur
moins de parties décidées (43–80 par graine), ce qui élargit son
intervalle. Les ouvertures d'évaluation sont gelées et partagées, de
sorte qu'un effet de l'ensemble d'ouvertures affecterait les deux bras
de la même manière ; il pourrait néanmoins modeler les scores absolus.
<!-- src: paper/ch7-discussion.md:53 -->

## Validité statistique : graines et dépendances

Cinq graines par bras bornent les statistiques. Le rejet repose sur
plus qu'un seul intervalle : sur la cohérence entre graines à travers
deux adversaires et deux lectures simultanément, sur quatre des six
intervalles excluant zéro, et sur une analyse des bornes du plafond.
L'extension pré-engagée de trois à cinq graines a resserré quatre des
six intervalles et absorbé les graines les plus favorables au graphe
observées sans changer le verdict ; le contraste contre l'adversaire de
recherche reste indiscernable de zéro sous les deux lectures et est
rapporté comme tel. Le contraste entre bras applique le bootstrap aux
graines plutôt qu'aux parties, de sorte qu'aucune pseudo-réplication au
niveau des parties n'entre dans aucun intervalle, et les ensembles de
graines des deux bras sont rééchantillonnés indépendamment, ce qui est
conservateur pour un plan apparié dans lequel les deux bras jouent les
mêmes ouvertures.
<!-- src: paper/ch7-discussion.md:65; journal/2026-10-09-h6-5seed-final-01.md:61 -->

## Validité externe : variante, matériel et budget

Une variante (Hive de base, sans extensions), une machine, un petit
budget (dix générations de 500 parties ; entre 16.7 et 19.1 heures de
temps mural d'entraînement par exécution grille et entre 26.6 et 49.9
heures par exécution graphe), auto-jeu en régime précoce tout du long.
L'asymétrie de fournisseur d'inférence est une propriété authentique du
matériel de déploiement : le réseau convolutif s'exécute le plus vite
sur l'accélérateur neuronal de la machine, le réseau de graphes riche en
opérations de collecte (gather) le plus vite sur le CPU. Elle
est rapportée et imputée, et sur d'autres accélérateurs la lecture à
temps mural pourrait se déplacer tandis que la lecture à exemples égaux
ne le ferait pas. La politique de réglage nul est symétrique mais peut
ne pas être neutre : les réseaux de graphes sont communément plus
sensibles aux valeurs par défaut de l'optimiseur que les réseaux
convolutifs résiduels, et la première ablation a montré que cette
famille est fragile sous ces valeurs par défaut ; un bras graphe réglé
pourrait réduire l'écart, au prix de la rupture de la symétrie de la
comparaison. Rien ici ne se généralise à d'autres jeux, à de plus grands
budgets ou à des architectures de graphes plus riches. L'étude répond à
sa question pré-enregistrée à l'intérieur de son périmètre
pré-enregistré, et la réponse négative est le constat. Le choix
d'encodage importe, comme l'étude antérieure sur Hive l'avait montré,
et pour Hive à petit budget il favorise la grille.
<!-- src: paper/ch7-discussion.md:75; data/runs wallclock totals (see sec:results-cost) -->

## Une propriété du pipeline qui borne la force absolue atteinte

Une propriété du pipeline partagé mérite d'être énoncée aussi
clairement que possible, parce qu'elle conditionne la manière dont les
« dix générations » de cette étude doivent être lues. Le pilote de
campagne entraîne le réseau de chaque génération à partir d'une
initialisation fraîche issue de la graine, pendant deux époques, sur les
seuls enregistrements de cette génération ; il ne transmet à
l'entraîneur ni point de contrôle de démarrage à chaud ni fenêtre de
rejeu (`@sec:pipeline`{=typst}). La boucle s'améliore néanmoins de
génération en génération, parce que le réseau de la génération $g$ est
entraîné sur des parties jouées par la recherche guidée par le réseau de
la génération $g-1$, et que cette recherche est plus forte que le réseau
brut ; mais aucun poids n'est reporté et aucun enregistrement n'est
réutilisé. Chaque réseau voit donc les positions de 500 parties, ce qui
est un petit ensemble d'entraînement au regard des standards de
l'apprentissage par auto-jeu, et la force absolue atteinte après dix
générations (près du plafond de score contre l'adversaire aléatoire,
autour de 0.1 contre les deux adversaires forts) doit être lue à la
lumière de ce fait. Pour la *comparaison*, la propriété est neutre :
elle est identique dans les deux bras, les deux encodeurs voient
exactement les mêmes enregistrements, et le protocole gelé spécifiait
des conventions d'entraînement identiques plutôt qu'une politique
particulière de démarrage à chaud. Pour la *généralisation* du résultat,
c'est une limite qui s'ajoute à celles déjà énumérées : un pipeline qui
accumulerait les données et reporterait les poids atteindrait un régime
différent, dans lequel l'ordre des bras est une question ouverte. Une
étude successeur devrait reporter les poids d'une génération à l'autre
et s'entraîner sur une fenêtre de générations récentes, comme le font
les grands systèmes d'auto-jeu, les deux changements étant appliqués à
l'identique aux deux bras.
<!-- src: scripts/run_comparison.py:119-129; python/hivenet/train.py:112-123; configs/comparison-matrix.yaml:36-41 -->

## Ce que nous ferions différemment

Quatre changements renforceraient une étude successeur sans changer sa
logique. Le premier est le démarrage à chaud et la fenêtre de rejeu qui
viennent d'être décrits. Les évaluations intermédiaires (20 parties par
adversaire aux générations 5 et 8) ont été dimensionnées pour le suivi
et sont trop bruitées pour porter une inférence ; une étude successeur
devrait évaluer chaque génération au volume final si les courbes doivent
être analysées. La lecture à temps égal devrait être accompagnée d'une
lecture à *énergie* égale sur des accélérateurs hétérogènes, puisque le
temps mural seul cache l'asymétrie de fournisseur. Et la symétrie du
réglage nul devrait être complétée par un petit budget de réglage
identique et pré-enregistré pour les deux bras, de sorte que la
fragilité sous valeurs par défaut soit mesurée plutôt qu'héritée.
