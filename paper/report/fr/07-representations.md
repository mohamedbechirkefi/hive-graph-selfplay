# Les deux représentations d'état et leurs réseaux {#sec:representations}

La variable indépendante de l'étude est la représentation d'état accompagnée du corps de réseau qui la lit, et rien d'autre. Ce chapitre spécifie les deux bras tels qu'ils ont été exécutés : encodages, réseaux, décodeur d'actions partagé, appariement de capacité, asymétries de coût mesurées plutôt que supprimées, tests qui épinglent chaque encodeur, et variantes d'ablation. `@fig:encodings`{=typst} montre une position sous les deux encodages, `@fig:architectures`{=typst} les deux réseaux, et `@sec:app-b`{=typst} les tables de couches, l'arithmétique du décodeur et l'agencement de l'enregistrement.

Les deux côtés n'ont pas la même histoire. Le cadre grille, ses plans et le réseau convolutif ont été construits en juillet 2026 au sein du projet de moteur et ont porté la démonstration d'auto-jeu antérieure de 19 générations ; le 10 septembre 2026, ils ont été réutilisés sans modification comme représentation de référence, avec un seul durcissement de la vérification de débordement du cadre. Tout ce qui est du côté graphe (encodage, réseau, constructeurs de tenseurs dans les deux langages d'implémentation, et leurs tests) a été construit le 10 septembre 2026 pour cette étude, contre un contrat de décodeur fixé la veille.

<!-- src: state/decisions.md:636-658; docs/inventory.md:17; docs/protocol.md:136-143; journal/2026-09-10-encoders-01.md:1-20 -->

## Ce qui varie entre les bras, et ce qui, de manière démontrable, ne varie pas

Les deux bras partagent le moteur de règles, la recherche, la population d'adversaires gelée et les réglages d'évaluation épinglés, le format d'enregistrement, les cibles d'entraînement et les conventions d'issue (la troncature comme quatrième issue, exclue de la perte de valeur), l'espace d'actions avec sa normalisation sur l'ensemble légal, et la boucle d'entraînement (deux époques par génération, lot 256, taux d'apprentissage 0.02, poids de la perte de valeur 0.6, descente de gradient stochastique avec momentum 0.9 sous un calendrier cosinus). Aucun des deux bras n'a été réglé au-delà de l'appariement de capacité. Chaque élément partagé est imposé plutôt qu'affirmé : un seul contrat de décodeur avec masquage identique, un seul format d'enregistrement, un test doré inter-langages par encodeur, et une seule recherche arborescente Monte-Carlo en Rust évaluant les deux bras à travers des exports ONNX à formes statiques. Ce qui diffère est exactement énumérable : la représentation, le corps du réseau, et leurs interactions matérielles mesurées.

<!-- src: paper/method-representations.md:8-19; docs/representations/comparison-controls.md:47-55; configs/comparison-matrix.yaml:36-41; python/hivenet/train.py:105-107; python/hivenet/train_graph.py:75-78 -->

### Le décodeur d'actions partagé

Un coup de Hive est identifié de manière unique par (pièce, cellule de destination) : une marche et un lancer amenant la même pièce sur la même cellule produisent des états successeurs identiques. Le décodeur adresse la pièce par un emplacement relatif au camp au trait : les 14 pièces du joueur au trait dans l'ordre de l'effectif, puis les 14 de l'adversaire aux emplacements 14–27 (ils existent parce que l'extension Pillbug déplace les pièces ennemies ; dans le jeu de base, ils ne sont jamais légaux). Il adresse la destination par une cellule de l'ensemble candidat, chaque cellule occupée plus l'anneau des cellules vides adjacentes à la ruche, qui contient chaque destination légale par construction. Une action supplémentaire, la passe, est légale exactement lorsqu'aucun coup n'existe. Le bras grille matérialise cet espace comme un vecteur plat de 28,673 logits indexé par emplacement × 1024 + y × 32 + x sur son cadre 32 × 32, le dernier indice étant la passe. Le bras graphe ne matérialise aucun vecteur de ce type : pour chaque paire (emplacement, destination) légale, il calcule un logit à partir des plongements du nœud de destination, de la source de la pièce et de l'emplacement, et note une ligne de passe de la même façon. L'action à laquelle un logit se réfère est la paire identique dans les deux bras ; c'est le mécanisme du réseau pointeur (Vinyals et al., 2015) qui note chaque élément d'un ensemble candidat variable et normalise sur exactement cet ensemble.

<!-- src: docs/action-decoder.md:9-38; paper/annex-architectures.md:58-62; docs/reading/vinyals-2015-pointer-networks.md:14-16 -->

Quatre propriétés sont partagées mot pour mot. Masquage : les logits n'existent que pour l'ensemble légal que le moteur génère, la softmax s'exécute sur exactement cet ensemble, et la masse de probabilité sur les actions illégales est identiquement nulle ; la première des sept vérifications automatisées pré-entraînement l'affirme par une vraie passe avant pour le bras testé, quel qu'il soit. Indépendance à l'ordre : les scores s'attachent aux paires (emplacement, destination), jamais aux positions dans la liste légale. Départage : les égalités d'argmax se départagent vers l'indice plat le plus bas, l'indexation de la grille définissant le départage pour les deux bras. Cibles : la distribution de visites à la racine de la recherche sur le même espace, stockée sous forme de ses 15 premières entrées (indice, poids de visites) avec le compte total de visites ; la cible de valeur est un scalaire dans [−1, 1] du point de vue du camp au trait (victoire +1, défaite −1, nulle 0), et la troncature ne contribue à aucune cible de valeur dans l'un ou l'autre bras. Le contrat a été fixé le 9 septembre 2026, avant que l'un ou l'autre encodeur ne soit construit pour l'étude. La justification est que le facteur de confusion est contrôlé par l'identité de l'espace d'actions, du masque et des cibles plutôt que par la production du même tenseur par les deux bras ; imposer le tenseur plat au réseau graphe aurait transporté le cadre, un artefact de la grille, dans le bras graphe.

<!-- src: docs/action-decoder.md:40-87; paper/annex-architectures.md:62-68; state/decisions.md:423-445 -->

## L'encodage grille

### Cadre, ancrage et débordement

Le plateau du moteur est une grille d'octets 64 × 64 à enroulement (un tore) en coordonnées axiales absolues. Pour l'encodage, une position est dépliée depuis le tore par un parcours en largeur à partir d'une cellule occupée arbitraire (l'enroulement ne peut pas scinder la ruche, qui est connexe par règle) et translatée de sorte que le centre de la boîte englobante occupée tombe en (16, 16) d'un cadre fixe 32 × 32. L'adjacence hexagonale en coordonnées axiales est un sous-ensemble de 7 cellules du voisinage 3 × 3, de sorte que des convolutions 3 × 3 ordinaires la couvrent, les deux coins non voisins de chaque noyau devenant des poids morts apprenables. L'ancrage se fait par le centre de la boîte englobante seulement : aucune canonicalisation par rotation ou réflexion, et aucune augmentation par symétries (voir la fin de ce chapitre).

<!-- src: docs/representations/grid.md:8-20; python/hivenet/model.py:7-9 -->

Une ruche de 28 pièces s'étend sur au plus 28 cellules par axe après dépliage, de sorte que la boîte occupée plus l'anneau complet des destinations candidates tient dans le cadre avec marge, par construction. L'argument est aussi imposé à l'exécution : le constructeur du cadre porte une assertion toujours active, présente dans les builds release, de sorte que toute cellule projetée hors du cadre arrête bruyamment le programme et qu'aucune pièce ni destination ne peut disparaître ou se replier silencieusement. Jusqu'au 10 septembre 2026, c'était une assertion de débogage seulement, retirée à la compilation des builds release, un risque de corruption silencieuse que la revue de débordement a clos. Des tests extrémaux placent les 28 pièces en ligne droite le long de chaque axe et prouvent que chaque cellule occupée et chaque cellule de l'anneau se projette sans repliement ; un long test de dérive sur parties aléatoires couvre le jeu ordinaire.

<!-- src: docs/representations/grid.md:22-36; state/decisions.md:641-647; journal/2026-09-10-encoders-01.md:24-27 -->

### Les 77 plans de caractéristiques

| Plans | Contenu |
| --- | --- |
| 0–63 | Plans de pièces : propriétaire (joueur au trait = 0, adversaire = décalage 32) + type d'insecte (8 types : Q, S, B, G, A, M, L, P) × 4 + min(niveau de pile, 3) ; propriétaire, type et hauteur sont encodés conjointement, un plan par combinaison |
| 64 | Pièces de sommet clouées par la règle One-Hive (cellules d'articulation de la ruche) |
| 65 | Cellule de la dernière pièce déplacée (état pertinent pour l'étourdissement) |
| 66 | Cellules de placement légal pour le camp au trait |
| 67 | Cellules de placement légal pour l'adversaire |
| 68 | Le camp au trait est blanc (plan constant) |
| 69, 70 | Libertés des reines (joueur au trait, adversaire) / 6 (plans constants ; 0 si la reine n'est pas placée) |
| 71 | Pli / 100 (plan constant) |
| 72–74 | Bits de type de partie M, L, P (plans constants) |
| 75, 76 | Comptes de réserves (joueur au trait, adversaire) / 14 (plans constants) |

Table: Les 77 plans d'entrée de l'encodage grille. Chaque plan est une carte 32 × 32 en float32 à valeurs dans [0, 1] ; un plan « constant » diffuse un scalaire sur tout le cadre. Le propriétaire est relatif au camp au trait, en accord avec les emplacements du décodeur et la perspective de la tête de valeur. {#tbl:grid-planes}

Les plans de pièces conjoints enregistrent, par cellule, qui possède la pièce à chaque niveau de pile, ce qu'elle est et à quelle hauteur elle se trouve, les niveaux 3 et supérieurs étant fusionnés. Les plans de placement suivent la règle d'adjacence standard (une cellule vide adjacente à au moins une pièce de sommet du joueur et à aucune de l'adversaire) sans les exceptions des tours d'ouverture ; ce sont seulement des indices, puisque la légalité elle-même est fournie aux deux bras par le masque du moteur. L'encodeur graphe utilise la même règle simplifiée.

<!-- src: docs/representations/grid.md:38-54; python/hivenet/dataset.py:17-27,171-183; journal/2026-09-10-graph-wiring-01.md:22-25 -->

### Le réseau grille

HiveNet est un réseau convolutif résiduel dans le style de KataGo (Wu, 2020), dimensionné à 96 canaux et 8 blocs résiduels. Un tronc convolutif 3 × 3 fait passer les 77 plans à 96 canaux (normalisation par lots, ReLU) ; chaque bloc résiduel applique deux convolutions 3 × 3 avec normalisation par lots, une addition résiduelle et une ReLU ; les blocs 2 et 5 (en comptant à partir de 0) ajoutent un biais de pooling global avant l'addition résiduelle : la moyenne et le maximum par canal sur le cadre sont concaténés, passés par une couche linéaire et réinjectés par canal. Cela injecte deux fois un signal global, la sécurité de la reine étant une propriété globale. La tête de politique est une convolution 1 × 1 vers 28 plans d'emplacements de pièces, aplatie en 28,672 logits spatiaux, plus un logit de passe issu des caractéristiques agrégées par moyenne : 28,673 sorties. La tête de valeur fait passer les caractéristiques agrégées par moyenne par une couche cachée de 64 unités vers trois logits (victoire, nulle, défaite du point de vue du camp au trait). Le réseau compte 1.44 M paramètres, comptés par le code d'entraînement.

<!-- src: paper/annex-architectures.md:8-26; python/hivenet/model.py:53-83; docs/representations/comparison-controls.md:14-17; docs/reading/wu-2020-katago.md -->

## L'encodage graphe

### Nœuds, pièces et destinations

L'encodage graphe est sans coordonnées : aucune coordonnée absolue n'y apparaît. Ses nœuds sont les cellules de l'ensemble candidat (chaque cellule occupée et chaque cellule vide adjacente à la ruche), qui est exactement l'univers de destinations du décodeur, de sorte que chaque destination pouvant être notée est un nœud à part entière. Le choix découle des règles : les destinations et les contraintes de glissement de Hive sont des propriétés de l'espace vide, et un graphe sur les seules cellules occupées n'aurait rien à noter pour la plupart des coups. Keller et al. (2023) sont parvenus à la conclusion analogue pour Hex, dont la formulation ne conserve que les cellules vides comme nœuds, et un décodeur de type pointeur ne peut pointer que vers des éléments qui existent (Vinyals et al., 2015). Une caractéristique d'occupation explicite distingue les candidats vides des nœuds occupés. Les pièces ne sont pas des nœuds séparés : puisque le décodeur adresse un coup comme (emplacement, cellule de destination), l'identité d'une pièce entre dans la politique par son plongement d'emplacement et sa localisation par le nœud sur lequel elle se tient ; les nœuds de cellule portent la composition complète de la pile niveau par niveau, de sorte qu'aucune information de pièce n'est perdue et que le graphe reste deux fois plus petit qu'il ne le serait avec des nœuds de pièces. C'est un choix de conception documenté.

<!-- src: docs/representations/graph.md:17-35; docs/reading/keller-2023-graphdqn-hex.md:35-36; docs/reading/vinyals-2015-pointer-networks.md:14 -->

### Caractéristiques de nœud, relations typées et caractéristiques globales

| Caractéristiques | Contenu |
| --- | --- |
| 0–49 | Cinq niveaux de pile (0–4), dix caractéristiques chacun : bit de présence, bit propriétaire-au-trait, one-hot du type d'insecte sur les 8 types |
| 50 | Hauteur de pile / 5 |
| 51 | Bit candidat-vide (1 pour une cellule vide de l'anneau) |
| 52 | Bit cloué One-Hive (la pièce de sommet est un point d'articulation de la ruche) |
| 53 | Bit dernier-coup (pertinent pour l'étourdissement) |
| 54 | Bit de placement légal pour le camp au trait |
| 55 | Bit de placement légal pour l'adversaire |

Table: Les 56 caractéristiques de nœud de l'encodage graphe, un vecteur par cellule de l'ensemble candidat. L'empilement est représenté niveau par niveau jusqu'à la hauteur 5 (les hauteurs supérieures à 5 ne peuvent pas survenir dans le jeu de base ; le scalaire de hauteur les enregistre néanmoins). Le propriétaire est relatif au camp au trait. {#tbl:graph-node-features}

Les arêtes sont les adjacences dirigées entre cellules de l'ensemble candidat, typées par les six directions hexagonales (est, nord-est, nord-ouest, ouest, sud-ouest, sud-est), stockées sous forme d'un tenseur d'indices de voisins (par nœud, l'indice de son voisin dans chaque direction, avec une sentinelle en l'absence de voisin) et réalisées dans le réseau comme six matrices de poids propres à chaque relation. L'inverse de la direction d est (d + 3) mod 6, une symétrie que les tests de propriétés vérifient. L'adjacence aux cellules hors de l'ensemble candidat est exclue : ces cellules sont vides et non adjacentes à la ruche, de sorte qu'elles ne peuvent influencer ni la légalité ni la valeur.

<!-- src: docs/representations/graph.md:48-56; journal/2026-09-10-encoders-01.md:31-34; python/hivenet/dataset.py:50-51 -->

| Caractéristiques | Contenu |
| --- | --- |
| 0 | Le camp au trait est blanc |
| 1 | Pli / 100 |
| 2, 3 | Libertés des reines (joueur au trait, adversaire) / 6 ; 0 si la reine n'est pas placée |
| 4–11 | Compte de réserves du joueur au trait par type d'insecte / 3 (8 types) |
| 12–19 | Compte de réserves de l'adversaire par type d'insecte / 3 (8 types) |
| 20–22 | Bits de type de partie M, L, P |

Table: Les 23 caractéristiques globales de l'encodage graphe. Le vecteur est concaténé à l'entrée de chaque nœud et de nouveau à la représentation agrégée dans la tête de valeur. {#tbl:graph-globals}

Les réserves entrent par type d'insecte parce que la légalité des placements et la planification du matériel dépendent des insectes qui restent en main ; le bras grille porte les deux totaux comme plans constants et peut retrouver les comptes par type à partir de ses plans de pièces, de sorte qu'aucun bras ne reçoit une information que l'autre ne peut reconstruire.

<!-- src: docs/representations/graph.md:58-65; python/hivenet/graph_dataset.py:113-127 -->

### Capacités fixes et débordement bruyant

Les tenseurs ont des formes fixes, 224 nœuds et 321 lignes de coups (320 coups légaux, le plafond de l'enregistrement, plus une ligne de passe), et, comme le cadre, une vérification de débordement toujours active : une position dépassant l'une ou l'autre capacité échoue bruyamment plutôt que silencieusement. Les maxima mesurés sur 300 enregistrements d'auto-jeu réels étaient de 67 nœuds et 124 coups légaux, bien en deçà de la capacité. Les formes fixes gardent l'export ONNX statique, de sorte que le bras graphe s'exécute sous la même recherche Rust et le même chemin d'inférence que le bras grille ; des formes dynamiques auraient imposé une voie d'inférence différente et une asymétrie par bras là où la conception doit être identique.

<!-- src: docs/representations/graph.md:85-92; journal/2026-09-10-encoders-01.md:42-45; python/hivenet/graph_dataset.py:36-41; state/decisions.md:674-677 -->

### Couverture de l'état du moteur, et ce qui n'est pas donné au réseau

| Composant de l'état (influence la légalité ou l'issue) | Élément du graphe |
| --- | --- |
| Positions, propriétaires et types des pièces | caractéristiques de nœud par niveau de pile |
| Empilement (montées de scarabée, pièces enfouies) | caractéristiques par niveau et hauteur |
| Destinations candidates vides | nœuds candidats vides |
| Géométrie d'adjacence et directions | arêtes typées (6 directions) |
| Clouages One-Hive | bit de clouage (articulation calculée par le moteur) |
| État d'étourdissement (dernière pièce déplacée) | bit dernier-coup |
| Camp au trait | caractéristiques relatives au joueur au trait et bit global |
| Échéance de placement de la reine | pli global et caractéristiques de réserves |
| Réserves | comptes globaux par type |
| Type de partie | bits globaux |
| Régions de légalité de placement | bits de placement (règle dérivée du moteur) |
| La légalité des coups elle-même | exclue : fournie par position par le moteur à travers le masque légal du décodeur, identiquement au bras grille ; le réseau ne calcule jamais la légalité |
| Coordonnées absolues du plateau | exclues : sans coordonnées par conception, de sorte que les questions d'ancrage ne se posent pas |

Table: Carte de couverture des composants de l'état de jeu du moteur vers les éléments de l'encodage graphe. Les deux dernières lignes énoncent ce qui est délibérément absent. {#tbl:graph-coverage}

Aucune invariance et aucune règle ne sont accordées gratuitement. L'encodage ne contient aucune coordonnée absolue, mais la fonction apprise n'en est pas pour autant invariante par translation ou par rotation : le passage de messages avec relations typées par direction n'est pas invariant par rotation, les champs réceptifs sont limités par la profondeur (un saut par couche), et aucune règle de Hive n'est connue du réseau ; la légalité arrive du moteur par le masque, pour les deux bras de la même façon. Le protocole traite toute invariance comme une question à mesurer plutôt qu'à présumer, et ce chapitre n'en affirme aucune.

<!-- src: docs/representations/graph.md:7-15,67-83; docs/protocol.md:41-44 -->

### Le réseau graphe

HiveGraphNet commence par une couche linéaire qui fait passer les 56 caractéristiques de chaque nœud, concaténées aux 23 caractéristiques globales, à 152 canaux, masquée aux nœuds réels ; une ligne nulle à l'indice 224 tient lieu de voisin absent. Huit couches relationnelles à passage de messages suivent, chacune calculant

$$ h'_i = \mathrm{ReLU}\!\left(h_i + W_{\mathrm{self}}\, h_i + b + \sum_{d=1}^{6} W_d\, h_{n_i(d)}\right) $$
{#eq:relayer}

où $n_i(d)$ est le voisin du nœud $i$ dans la direction $d$ (la ligne nulle en son absence), $W_{\mathrm{self}}$ porte le biais $b$, et les six $W_d$ sont les matrices typées par direction, sans biais ; la sortie est masquée aux nœuds réels. Les couches 2 et 5 (en comptant à partir de 0), soit une couche sur trois, ajoutent un biais de pooling global à l'intérieur de la non-linéarité : la moyenne masquée et le maximum masqué sur les nœuds réels sont concaténés, passés par une couche linéaire et ajoutés à chaque nœud. Le passage de messages seul est limité par la profondeur, alors que la sécurité de la reine est une propriété globale.

<!-- src: python/hivenet/graph_model.py:20-64; paper/annex-architectures.md:38-44 -->

La tête de valeur concatène la moyenne masquée, le maximum masqué et le vecteur global et les fait passer par une couche cachée de 64 unités vers les trois mêmes logits victoire/nulle/défaite que le bras grille. La tête de politique est la fonction de notation par candidat du décodeur : pour chaque ligne (emplacement, destination) légale, elle concatène le plongement du nœud de destination, un plongement de source et un plongement d'emplacement de dimension 32 et les fait passer par une couche cachée de 128 unités vers un logit ; le plongement de source est le nœud sur lequel la pièce se tient pour un mouvement et un vecteur de réserve appris pour un placement. La ligne de passe est notée par la même fonction de notation à partir du plongement de l'emplacement de passe, du vecteur de réserve et de la ligne nulle ; c'est une constante apprise et sans incidence, parce que la passe n'est légale que lorsqu'aucun coup n'existe et remporte alors seule la softmax. Les lignes illégales sont masquées avant la softmax, qui s'exécute sur les lignes légales dans la perte et dans l'évaluateur d'inférence exactement comme la softmax masquée du bras grille. Le réseau compte 1.47 M paramètres, +1.5 % par rapport au réseau grille. C'est un encodeur inductif à passage de messages au sens de Hamilton et al. (2017), étendu avec des poids propres à chaque relation par direction sur des voisinages exacts de degré au plus six, ce qui est exactement ce que le protocole prescrit.

<!-- src: python/hivenet/graph_model.py:65-98; paper/annex-architectures.md:46-52; docs/representations/comparison-controls.md:14-17; docs/reading/hamilton-2017-graphsage.md:14-16; docs/protocol.md:138-143 -->

![Schémas par blocs des deux réseaux. À gauche, HiveNet (bras grille) : tronc convolutif 3 × 3, 8 blocs résiduels de 96 canaux avec un biais de pooling global dans les blocs 2 et 5, une tête de politique plate à 28,673 sorties et une tête de valeur à 3 classes, 1.44 M paramètres au total. À droite, HiveGraphNet (bras graphe) : couche linéaire d'entrée vers 152 canaux, 8 couches relationnelles à passage de messages avec six matrices typées par direction et un biais de pooling global une couche sur trois, une fonction de notation de politique par candidat sur les plongements de destination, de source et d'emplacement, et une tête de valeur moyenne‖max masquée, 1.47 M paramètres au total. Les deux réseaux alimentent le décodeur d'actions partagé ; seuls l'encodeur et le corps diffèrent.](figures/fig9-architectures.png){#fig:architectures width=90%}

<!-- src: paper/annex-architectures.md:8-52; docs/representations/comparison-controls.md:14-17 -->

## Appariement de capacité et asymétries de coût mesurées

La capacité a été appariée en dimensionnant la largeur et la profondeur du réseau graphe (152 canaux, 8 couches) sur le compte de paramètres du réseau grille (96 canaux, 8 blocs) : 1.47 M contre 1.44 M, +1.5 %, rapporté. Ce qui n'a pas pu être apparié est le coût d'exécution de chaque réseau sur la machine d'étude, où les deux représentations interagissent avec le matériel de façons opposées.

<!-- src: docs/representations/comparison-controls.md:12-17; journal/2026-09-10-encoders-01.md:46 -->

| Chemin d'inférence | Grille (HiveNet) | Graphe (HiveGraphNet) |
| --- | ---: | ---: |
| PyTorch, CPU | 11.03 ms | 10.51 ms |
| Inférence ONNX, fournisseur CPU | 23.5 ms | 3.67 ms |
| Inférence ONNX, fournisseur CoreML | 2.62 ms | 9.84 ms |
| Meilleur fournisseur disponible | 2.62 ms (CoreML) | 3.67 ms (CPU) |

Table: Coût d'inférence par évaluation de position à une taille de lot de 1 pour les deux réseaux, mesuré le 10 septembre 2026 sur la machine d'étude (Apple M1 Pro, 10 cœurs, 16 Go, macOS 15.3.1). Millisecondes par évaluation ; une seule configuration de mesure, aucun intervalle. {#tbl:inference-cost}

Le réseau convolutif s'exécute le plus vite sur l'accélérateur CoreML ; le réseau graphe s'exécute le plus vite sur le CPU, parce que sous CoreML seuls 147 de ses 287 opérateurs sont pris en charge, les opérations riches en collecte (gather) se rabattent sur 15 partitions, et le chemin de l'accélérateur finit par être plus lent que le chemin CPU. Au meilleur fournisseur de chaque bras, le rapport de coût par évaluation est de ≈1.4× au détriment du bras graphe. L'auto-jeu et l'évaluation ont donc exécuté chaque bras sur son meilleur fournisseur à travers la même recherche.

<!-- src: docs/representations/comparison-controls.md:19-32; journal/2026-09-10-encoders-01.md:47-54 -->

| Chemin d'entraînement | Grille (HiveNet) | Graphe (HiveGraphNet) |
| --- | ---: | ---: |
| PyTorch, CPU, passe avant seulement | 138 pos/s | 478 pos/s |
| PyTorch, MPS, passe avant + arrière | 274 pos/s | 138 pos/s |

Table: Débit d'entraînement à une taille de lot de 128 sous conditions appariées pour les deux réseaux, en positions par seconde, mêmes machine et date que la table d'inférence. L'étude entraîne sur le chemin MPS. {#tbl:training-throughput}

L'entraînement montre le motif inverse : sur le CPU, le réseau graphe est ~3.5× plus rapide par position, sur le chemin MPS utilisé pour l'entraînement ~2× plus lent, les opérations de collecte (gather) et de dispersion (scatter) y dominant. L'entraînement est de toute façon une part mineure du temps mural d'une génération (dans le pilote, ≈3.5 min d'entraînement contre ≈60 min d'auto-jeu pour la génération 0), de sorte que l'asymétrie d'inférence pilote la différence de coût à l'échelle de la campagne. Les chiffres proviennent d'une seule machine et d'une seule configuration, excluent le coût de construction en Python du chargeur de données graphe, et les nombres MPS sont une simple passe avant et arrière sans le pas de l'optimiseur. Ces asymétries sont rapportées plutôt qu'égalisées. Ce sont de véritables interactions entre une représentation et le matériel, et les égaliser, que ce soit en bridant le bras grille ou en forçant le bras graphe sur un fournisseur plus lent, fabriquerait une parité qu'aucun utilisateur de l'une ou l'autre représentation ne rencontrerait. Le protocole lit plutôt la comparaison deux fois : sous la lecture à exemples égaux, les asymétries sont sans objet, les deux bras jouant le même nombre de parties avec les mêmes réglages de générateur ; sous la lecture à temps mural égal, chaque bras se voit imputer son coût réel sur cette machine. La conséquence à l'échelle de la campagne est rapportée avec les résultats de coût.

<!-- src: docs/representations/comparison-controls.md:28-44; journal/2026-09-10-encoders-01.md:50-51,60-65; paper/method-representations.md:55-65; docs/protocol.md:103-110 -->

## Épinglage des encodeurs : tests dorés et tests de propriétés

Chaque encodeur existe deux fois, en Rust dans le moteur et la recherche et en Python dans la boucle d'entraînement, et l'accord entre les deux est prouvé plutôt que supposé. Pour le bras grille, l'encodeur Rust et le décodeur Python sont identiques à l'octet près par contrat, ce qu'impose une vérification croisée dorée nocturne sur 240 positions ; après le durcissement de l'assertion, la vérification croisée a réussi et la suite du crate d'interface s'établissait à 7/7, y compris les nouveaux tests extrémaux ; tout changement ultérieur doit la maintenir au vert ou être enregistré comme un résultat.

<!-- src: docs/representations/grid.md:56-63; journal/2026-09-10-encoders-01.md:39-41 -->

Pour le bras graphe, l'entraînement construit les tenseurs en Python à partir des enregistrements générés par le moteur (et eux-mêmes contre-vérifiés). Une batterie de propriétés sur 300 enregistrements réels a réussi intégralement : aucune perte d'information (chaque pièce, niveau de pile, compte de réserves, état d'étourdissement et donnée de trait de l'enregistrement apparaît dans les tenseurs) ; capacités respectées, avec une sonde de débordement levant une erreur bruyamment ; symétrie des arêtes ; validité du tenseur de coups légaux, chaque cible stockée étant dans la liste légale ; et masse de probabilité illégale nulle par une vraie passe avant. Une seule correction du constructeur a été nécessaire : le plateau vide au pli 0 a un ensemble candidat vide, et le constructeur reflète désormais la première cellule canonique du cadre, (16, 16). Le constructeur Rust utilisé à l'inférence reflète le constructeur Python (même ordre des cellules, même agencement des caractéristiques, même ordre des directions, même règle de placement simplifiée et même débordement bruyant), et une vérification croisée dorée sur 160 positions pseudo-aléatoires couvrant les 8 types de partie a trouvé 160/160 exactement égales dès sa première exécution ; elle s'exécute chaque nuit à côté de la vérification croisée des plans. L'évaluateur graphe à l'intérieur de la recherche construit les tenseurs et les lignes de coups dans l'ordre des coups de la recherche, exécute l'export à formes statiques sur le fournisseur CPU, applique la softmax sur les lignes légales et convertit la sortie à trois classes en P(win) − P(loss), ce qui est le contrat de sortie de l'évaluateur grille.

<!-- src: journal/2026-09-10-encoders-01.md:28-45; journal/2026-09-10-graph-wiring-01.md:22-32; python/hivenet/graph_dataset.py:69 -->

Une validation du câblage (deux époques sur les données du pilote de la génération 0, une graine) a tourné à 194 positions par seconde sur MPS, chargeur de données inclus, avec un argmax de politique (top-1) en validation de 4.7 % et une exactitude de la valeur de 40.4 %, le même profil que le bras grille sur les données identiques (4–5 %, ~43 %) ; un match de fumée de 6 parties à 200 simulations contre l'adversaire aléatoire légal a donné 2 victoires, 0 défaite et 4 troncatures sans aucune réponse illégale. Ces chiffres établissent seulement que le câblage est sain ; ils ne constituent pas un résultat de comparaison.

<!-- src: journal/2026-09-10-graph-wiring-01.md:36-47,54-57 -->

## Les deux variantes d'ablation

| Variante | Composant unique modifié | Paramètres |
| --- | --- | ---: |
| Bras graphe complet (référence) | aucun | 1.47 M |
| Arêtes non typées (« adjacence naïve ») | les six matrices typées par direction remplacées par une seule matrice partagée | 0.54 M |
| Sans pooling global | le biais de pooling global retiré de chaque couche | 1.37 M |

Table: Les variantes d'ablation du bras graphe. Chacune diffère du bras graphe complet par exactement un composant du réseau ; l'encodeur, le décodeur, les réglages d'entraînement, les budgets, les réglages d'évaluation, les adversaires et les ouvertures sont identiques. Paramètres en millions, mesurés par le compteur de paramètres du code d'entraînement. {#tbl:ablation-variants}

Les différences de paramètres sont inhérentes aux composants retirés et sont rapportées plutôt qu'égalisées ; élargir le réseau non typé pour compenser modifierait un second composant. La variante à adjacence naïve est l'ablation que le plan de recherche demandait ; elle teste la prémisse, inscrite dans le protocole avant toute exécution, selon laquelle un graphe à adjacence naïve pourrait ne pas suffire. La variante sans pooling global a été substituée le 19 septembre 2026 à l'ablation prévue de retrait de l'augmentation, qui n'avait plus rien à retirer une fois l'augmentation exclue de la méthode complète ; elle a été choisie parce que le signal de mécanisme de la comparaison principale (la force relative du bras graphe résidait dans sa tête de valeur tandis que sa politique restait localement faible) faisait du signal agrégé la question à composant unique la plus nette qui restait. Une variante supplémentaire à deux composants, arêtes non typées plus un écrêtage global de la norme du gradient à 1.0, a été approuvée le 26 septembre 2026 après que la variante non typée se fut révélée non entraînable aux réglages de parité, divergeant vers des valeurs non finies à la génération 0 pour 3 graines sur 3 ; ses nombres sont étiquetés comme une différence à deux composants partout où ils apparaissent et rien de ce qu'elle montre n'est attribué au seul typage des arêtes. Les issues sont rapportées avec les résultats d'ablation.

<!-- src: configs/ablations/A1-edge-typing.md; configs/ablations/A2-global-pooling.md; configs/ablations/A1prime-edge-typing-clipped.md; state/decisions.md:856-877,917-934; results/ablations/README.md -->

## Augmentation par symétries : exclue par décision

Aucun des deux bras ne s'entraîne avec augmentation par symétries, par une décision du 10 septembre 2026 prise avant toute exécution de comparaison. L'exclusion rend trivialement vraie la règle des données identiques : implémenter les symétries hexagonales de manière cohérente à travers deux représentations (rotations et réflexions du cadre d'un côté, permutations des types de direction de l'autre) est subtil, et une asymétrie à cet endroit contaminerait la comparaison principale. Elle garde aussi la question secondaire des symétries séparable comme ablation additive, et elle correspond à la référence caractérisée : le pipeline antérieur avait documenté une augmentation par 12 symétries comme intention mais ne l'avait jamais implémentée. Le protocole gelé n'a jamais spécifié d'augmentation ; les deux bras voient donc chaque position dans l'orientation que la partie a produite.

<!-- src: state/decisions.md:700-722; paper/method-representations.md:67-72 -->

## Limites de ce que ce chapitre établit

Ce chapitre établit l'identité de tout sauf la représentation ; il ne dit rien du mérite de l'une ou l'autre représentation. Les chiffres de coût proviennent d'une seule machine dans une seule configuration ; un autre accélérateur pourrait inverser l'asymétrie d'inférence. L'appariement de capacité, à +1.5 %, est un appariement des comptes de paramètres plutôt que du calcul. Le bras graphe est un point dans un vaste espace de conception (nœuds de cellule, six types de direction, un biais agrégé une couche sur trois, une fonction de notation par candidat), et l'étude compare un réseau grille à un réseau graphe à une seule capacité et un seul budget ; rien ici ne dit qu'une autre conception de graphe se comporterait de même. Enfin, les symétries hexagonales ne sont ni canonicalisées ni augmentées dans l'un ou l'autre bras, de sorte que toute différence liée aux symétries entre les bras est une propriété des fonctions apprises plutôt que des encodages.

<!-- src: paper/method-representations.md:74-79; docs/representations/comparison-controls.md:12-17 -->
