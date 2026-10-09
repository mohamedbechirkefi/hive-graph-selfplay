# Architectures, décodeur et formats de données en détail {#sec:app-b}

Cette annexe complète `@sec:representations`{=typst} par des tables couche par couche des deux réseaux et de leurs variantes d'ablation, l'arithmétique exacte du décodeur d'actions partagé, l'interface tensorielle du bras graphe, l'agencement en octets de l'enregistrement d'auto-jeu, et les réglages de recherche partagés par les deux bras. Les totaux de paramètres sont les valeurs mesurées par le compteur de paramètres du code d'entraînement et ont été revérifiés pour cette annexe ; les comptes par couche n'ont pas été enregistrés séparément, de sorte que les tables ne donnent que les formes et les largeurs.

<!-- src: paper/annex-architectures.md:1-6 -->

## HiveNet, le réseau grille

L'entrée est un tenseur de 77 plans × 32 × 32 à valeurs float32 dans [0, 1] (`@tbl:grid-planes`{=typst}). Le corps et les têtes sont listés dans `@tbl:hivenet-layers`{=typst}. L'adjacence hexagonale en coordonnées axiales est un sous-ensemble de 7 cellules du voisinage 3 × 3, de sorte que les noyaux 3 × 3 la couvrent avec deux coins morts apprenables par noyau.

<!-- src: paper/annex-architectures.md:8-26; python/hivenet/model.py:1-19 -->

| Étape | Opération | Largeur | Notes |
| --- | --- | --- | --- |
| Entrée | 77 plans × 32 × 32 | 77 | float32 dans [0, 1] |
| Tronc | Conv 3 × 3 (sans biais), BatchNorm, ReLU | 77 → 96 | remplissage (padding) 1 |
| Bloc 0 | Conv 3 × 3, BatchNorm, ReLU ; Conv 3 × 3, BatchNorm ; addition résiduelle ; ReLU | 96 → 96 | convolutions sans biais |
| Bloc 1 | comme le bloc 0 | 96 → 96 | |
| Bloc 2 | comme le bloc 0, plus un biais de pooling global après le second BatchNorm | 96 → 96 | moyenne ‖ max sur le cadre (2 × 96) → linéaire → 96, ajouté par canal |
| Bloc 3 | comme le bloc 0 | 96 → 96 | |
| Bloc 4 | comme le bloc 0 | 96 → 96 | |
| Bloc 5 | comme le bloc 2 | 96 → 96 | biais de pooling global |
| Bloc 6 | comme le bloc 0 | 96 → 96 | |
| Bloc 7 | comme le bloc 0 | 96 → 96 | |
| Pooling | moyenne sur le cadre 32 × 32 | 96 | alimente le logit de passe et la tête de valeur |
| Politique, spatiale | Conv 1 × 1 (avec biais) | 96 → 28 | aplatie en 28 × 1024 = 28,672 logits, indice emplacement × 1024 + y × 32 + x |
| Politique, passe | Linéaire sur les caractéristiques agrégées | 96 → 1 | ajouté comme indice 28,672 |
| Valeur | Linéaire, ReLU, Linéaire sur les caractéristiques agrégées | 96 → 64 → 3 | logits victoire / nulle / défaite du point de vue du camp au trait |
| Total | | | 1.44 M paramètres |

Table: HiveNet, le réseau du bras grille, couche par couche. Les blocs sont numérotés à partir de 0 comme dans l'implémentation ; les deux blocs à pooling global sont ceux situés au tiers et aux deux tiers de la profondeur. Les largeurs sont des nombres de canaux ; le total est le compte de paramètres mesuré. {#tbl:hivenet-layers}

<!-- src: python/hivenet/model.py:22-83; paper/annex-architectures.md:16-26; docs/action-decoder.md:26-29 -->

## HiveGraphNet, le réseau graphe

Le réseau du bras graphe consomme des tenseurs à formes fixes (`@tbl:graph-tensors`{=typst}) construits à partir d'un enregistrement par le constructeur Python pour l'entraînement et par son miroir Rust pour l'inférence. Les agencements des caractéristiques de nœud et des caractéristiques globales sont donnés dans `@tbl:graph-node-features`{=typst} et `@tbl:graph-globals`{=typst} ; le corps et les têtes sont listés dans `@tbl:hivegraphnet-layers`{=typst}, et les variantes d'ablation dans `@tbl:graph-variants`{=typst}.

<!-- src: python/hivenet/graph_dataset.py:1-41 -->

| Tenseur | Forme | Type | Contenu |
| --- | --- | --- | --- |
| nœuds | 224 × 56 | float32 | caractéristiques de nœud, complétées par des zéros au-delà des nœuds réels |
| voisins | 224 × 6 | int64 | indice du voisin dans chaque direction hexagonale ; 224 = aucun |
| masque de nœuds | 224 | bool | 1 pour un nœud réel |
| globaux | 23 | float32 | caractéristiques globales |
| coups | 321 × 3 | int64 | (emplacement, nœud de destination, nœud source) par coup légal ; source = 224 pour les placements et la passe ; la ligne de passe utilise l'emplacement 28 |
| masque de coups | 321 | bool | 1 pour une ligne légale |
| cible | 321 | float32 | distribution de visites sur les lignes légales (entraînement seulement) |
| issue | scalaire | int64 | 0 défaite / 1 nulle / 2 victoire / 3 tronquée, du point de vue du camp au trait (entraînement seulement) |

Table: Interface tensorielle du bras graphe, par position. Capacités : 224 nœuds (cellules occupées plus l'anneau vide) et 321 lignes de coups (320 coups légaux, le plafond de l'enregistrement, plus une ligne de passe) ; dépasser l'une ou l'autre capacité lève une erreur plutôt que de tronquer. L'ordre des nœuds est déterministe : les cellules occupées d'abord, puis les cellules de l'anneau, chacune triée par (y, x) en coordonnées du cadre. {#tbl:graph-tensors}

<!-- src: python/hivenet/graph_dataset.py:9-41,52-71 -->

| Étape | Opération | Largeur | Notes |
| --- | --- | --- | --- |
| Entrée | caractéristiques de nœud ‖ globaux diffusés | 56 + 23 | par nœud |
| Linéaire d'entrée | Linéaire | 56 + 23 → 152 | masqué aux nœuds réels ; une ligne nulle à l'indice 224 tient lieu de voisin absent |
| Couche 0 | couche relationnelle : $W_{\mathrm{self}}$ (avec biais) + six $W_d$ (sans biais) ; résiduelle ; ReLU ; masque | 152 → 152 | `@eq:relayer`{=typst} |
| Couche 1 | comme la couche 0 | 152 → 152 | |
| Couche 2 | comme la couche 0, plus un biais de pooling global à l'intérieur de la non-linéarité | 152 → 152 | moyenne masquée ‖ max masqué (2 × 152) → linéaire → 152, ajouté à chaque nœud |
| Couche 3 | comme la couche 0 | 152 → 152 | |
| Couche 4 | comme la couche 0 | 152 → 152 | |
| Couche 5 | comme la couche 2 | 152 → 152 | biais de pooling global |
| Couche 6 | comme la couche 0 | 152 → 152 | |
| Couche 7 | comme la couche 0 | 152 → 152 | |
| Lecture (readout) | moyenne masquée ‖ max masqué sur les nœuds réels | 2 × 152 | |
| Valeur | Linéaire, ReLU, Linéaire sur lecture ‖ globaux | 2 × 152 + 23 → 64 → 3 | logits victoire / nulle / défaite du point de vue du camp au trait |
| Plongement d'emplacement | table de plongements | 28 emplacements de pièces + passe → 32 | |
| Vecteur de réserve | vecteur appris | 152 | plongement de source pour les placements et pour la ligne de passe |
| Politique | Linéaire, ReLU, Linéaire par ligne de coup sur destination ‖ source ‖ emplacement | 2 × 152 + 32 → 128 → 1 | lignes illégales remplies d'une grande constante négative avant la softmax |
| Total | | | 1.47 M paramètres |

Table: HiveGraphNet, le réseau du bras graphe, couche par couche. Les couches sont numérotées à partir de 0 comme dans l'implémentation ; les couches à pooling sont une couche sur trois. Les largeurs sont des nombres de canaux ; le total est le compte de paramètres mesuré. {#tbl:hivegraphnet-layers}

<!-- src: python/hivenet/graph_model.py:20-98; paper/annex-architectures.md:28-52 -->

| Variante | Différence par rapport au bras graphe complet | Paramètres |
| --- | --- | ---: |
| Bras graphe complet | aucune | 1.47 M |
| Arêtes non typées | une seule matrice partagée pour les six directions, dans chaque couche | 0.54 M |
| Sans pooling global | aucun biais de pooling dans aucune couche | 1.37 M |
| Arêtes non typées + écrêtage de gradient (supplément) | une seule matrice partagée pour les six directions, plus un écrêtage global de la norme du gradient à 1.0 pendant l'entraînement (une différence à deux composants) | 0.54 M |

Table: Les variantes du réseau graphe utilisées dans les ablations, avec leurs comptes de paramètres mesurés en millions. L'encodeur, le décodeur, les réglages d'entraînement, les budgets et les réglages d'évaluation sont identiques d'une variante à l'autre ; seul le composant nommé change. {#tbl:graph-variants}

<!-- src: paper/annex-architectures.md:54-56; configs/ablations/A1-edge-typing.md; configs/ablations/A2-global-pooling.md; configs/ablations/A1prime-edge-typing-clipped.md; python/hivenet/train_graph.py:54-55,131-132 -->

## Le décodeur d'actions partagé en détail

**Emplacements.** Une pièce est adressée par un emplacement relatif au camp au trait (`@tbl:decoder-slots`{=typst}) : les pièces du joueur au trait dans l'ordre de l'effectif, puis celles de l'adversaire. Dans le jeu de base, qui compte 11 pièces par camp, seuls les 11 premiers emplacements du joueur au trait peuvent jamais être légaux ; les emplacements des extensions et tous les emplacements adverses existent pour l'uniformité du noyau (l'extension Pillbug déplace des pièces ennemies) et restent inertes. Les types d'insectes sont codés 0–7 dans l'ordre Q, S, B, G, A, M, L, P ; ce code indexe les plans de pièces de l'encodage grille (type d'insecte × 4) et le bloc one-hot de l'encodage graphe.

<!-- src: docs/action-decoder.md:15-18; python/hivenet/dataset.py:46-48; paper/ch2-formalisation.md:11-12 -->

| Emplacement | Pièce du joueur au trait | Emplacement | Pièce de l'adversaire |
| --- | --- | --- | --- |
| 0 | Reine | 14 | Reine |
| 1–2 | Araignées | 15–16 | Araignées |
| 3–4 | Scarabées | 17–18 | Scarabées |
| 5–7 | Sauterelles | 19–21 | Sauterelles |
| 8–10 | Fourmis | 22–24 | Fourmis |
| 11 | Moustique | 25 | Moustique |
| 12 | Ladybug | 26 | Ladybug |
| 13 | Pillbug | 27 | Pillbug |

Table: Emplacements de pièces du décodeur d'actions partagé. L'emplacement 28 est l'emplacement de passe dans les lignes de coups du bras graphe ; la passe du bras grille est l'indice plat 28,672. {#tbl:decoder-slots}

<!-- src: python/hivenet/dataset.py:46-48; python/hivenet/graph_dataset.py:37-39; docs/action-decoder.md:26-29 -->

**Indice plat (bras grille).** Avec $(x, y)$ les coordonnées de la destination dans le cadre, l'indice de politique est $\text{emplacement} \times 1024 + y \times 32 + x$ ; la passe est l'indice 28,672 et le vecteur compte 28,673 entrées. C'est ce même indice que stockent les enregistrements, pour le coup joué et pour chaque entrée de la distribution de visites et de la liste légale.

**Lignes par candidat (bras graphe).** Chaque indice légal de l'enregistrement est décodé en une ligne de coup : emplacement = indice div 1024 ; reste = indice mod 1024 ; $x$ = reste mod 32, $y$ = reste div 32 ; le nœud de destination est l'indice de la cellule $(x, y)$ dans l'ordre de l'ensemble candidat ; le nœud source est le nœud où se tient la pièce si elle est sur le plateau, et la sentinelle de réserve 224 sinon ; l'indice de passe devient la ligne (28, 224, 224). L'identité encodage → indice → décodage sur tous les coups légaux à travers les types de partie est la deuxième des sept vérifications automatisées pré-entraînement.

<!-- src: python/hivenet/graph_dataset.py:129-152; docs/action-decoder.md:26-35,52-60 -->

**Propriétés partagées.** Masquage : la softmax s'exécute sur exactement l'ensemble légal (plus la passe lorsqu'elle est légale), implémentée comme un remplissage des entrées illégales par une grande constante négative dans les deux boucles d'entraînement et comme une softmax sur les lignes légales dans les deux évaluateurs d'inférence ; la première vérification automatisée affirme une masse illégale nulle via une vraie passe avant. Indépendance à l'ordre : les scores s'attachent aux paires (emplacement, destination), jamais aux positions de liste. Départage : les égalités d'argmax se résolvent vers l'indice plat le plus bas dans les deux bras. Cibles : les 15 premières entrées (indice, poids de visite) de la distribution de visites à la racine, normalisées sur leur support ; lorsque chaque poids stocké est nul, la cible se replie sur le coup joué. Valeur : une tête victoire/nulle/défaite entraînée avec les enregistrements tronqués exclus ; la recherche consomme P(victoire) − P(défaite) du point de vue du camp au trait, avec des valeurs terminales de +1, −1 et 0.

<!-- src: docs/action-decoder.md:40-77; python/hivenet/train.py:40-43; python/hivenet/dataset.py:117-130; python/hivenet/graph_dataset.py:154-164; journal/2026-09-10-graph-wiring-01.md:27-32 -->

## Format d'enregistrement

Les positions d'auto-jeu sont écrites comme des enregistrements de taille fixe, petit-boutistes (little-endian), dans des shards qui commencent par un en-tête de 16 octets (8 octets magiques identifiant la version du format, 8 réservés). Le format a évolué en trois versions : 112 octets avec une cible de coup joué en one-hot ; 176 octets ajoutant la distribution de visites top-15 ; et la version 3 de l'étude, à 818 octets, ajoutant l'estampille du modèle générateur et la liste d'indices des coups légaux, qui est ce qui permet l'entraînement masqué sur l'ensemble légal dans les deux bras. Seuls les enregistrements de version 3 sont des entrées de l'étude. `@tbl:record-layout`{=typst} en donne l'agencement.

<!-- src: python/hivenet/dataset.py:3-15,34-42,67-80; paper/annex-architectures.md:70-83 -->

| Octets | Champ | Encodage |
| --- | --- | --- |
| 0–83 | 28 pièces × (x, y, niveau) | un octet chacun, coordonnées du cadre, ordre absolu des pièces ; x = 255 signifie en main |
| 84 | camp au trait | 0 blanc, 1 noir |
| 85 | dernière pièce déplacée | identifiant de pièce ; 255 = aucune (état d'étourdissement) |
| 86 | pli | borné à 255 |
| 87 | bits de type de partie | 1 = M, 2 = L, 4 = P |
| 88, 89 | libertés des reines (joueur au trait, adversaire) | 255 = reine non placée |
| 90, 91 | comptes de réserves (joueur au trait, adversaire) | |
| 92–95 | masque de bits des clouages One-Hive | 32 bits, un bit par identifiant de pièce |
| 96–97 | indice de politique du coup joué | indice plat 16 bits |
| 98 | issue du point de vue du joueur au trait | 0 défaite / 1 nulle / 2 victoire / 3 tronquée (jamais une nulle) |
| 99 | version de l'enregistrement | 3 |
| 100–107 | estampille du modèle générateur | génération (32 bits) puis hachage du réseau (32 bits) ; 0 = non estampillé |
| jusqu'à 112 | réservé | zéro |
| 112–175 | distribution de visites à la racine | 15 × (indice de politique 16 bits, poids de visite 16 bits), puis total des visites stockées (32 bits) |
| 176–177 | compte de coups légaux | 16 bits ; 0xFFFF = liste indisponible (débordement) |
| 178–817 | liste des indices de politique légaux | 16 bits × 320 (plafond ; facteur de branchement maximal mesuré 213) ; emplacements inutilisés à zéro |

Table: Agencement en octets de l'enregistrement d'auto-jeu de version 3 (818 octets, petit-boutiste). « Joueur au trait » désigne le camp au trait à la position enregistrée. {#tbl:record-layout}

<!-- src: paper/annex-architectures.md:70-83; python/hivenet/dataset.py:3-15,34-42,83-104; docs/action-decoder.md:52-68 -->

Les deux bras lisent le même enregistrement. Le bras grille en décode les 77 plans ; le bras graphe en construit le graphe de cellules ; tous deux prennent leur cible de politique dans les octets 112–175, leur masque légal dans les octets 176–817, et leur issue dans l'octet 98. L'écrivain Rust et les lecteurs Python des plans et des tenseurs graphe sont épinglés identiques à l'octet près par les tests dorés inter-langages exécutés chaque nuit sur 240 et 160 positions respectivement.

<!-- src: paper/annex-architectures.md:80-83; python/hivenet/dataset.py:114-136; python/hivenet/graph_dataset.py:44-47 -->

## Réglages de recherche

| Réglage | Auto-jeu (données d'entraînement) | Évaluation indépendante |
| --- | --- | --- |
| Recherche | recherche arborescente Monte-Carlo PUCT, c = 1.4, évaluation des feuilles par lots, valeurs terminales remontées exactement | identique |
| Simulations par décision | 128 sur 25% des décisions (enregistrées), 32 sur les 75% restants (non enregistrées) ; randomisation du plafond de simulations | 400 |
| Bruit de Dirichlet à la racine | ε = 0.25 | 0 (la valeur par défaut du code, affirmée par un test ; le binaire du moteur n'expose aucun drapeau de bruit) |
| Sélection du coup | échantillonnage en température pour les 12 premiers plis, puis argmax | argmax déterministe |
| Abandon | en dessous de −0.92, avec 10% des parties n'abandonnant jamais (audit) | ne fait pas partie des réglages épinglés |
| Plafond de plis | 300 ; une partie plafonnée est enregistrée comme tronquée, jamais comme nulle | 300 ; troncature rapportée séparément |
| Ouvertures | aucune | 4 plis d'ouverture, appariés à couleurs échangées, identifiants d'ouverture partagés entre toutes les exécutions et tous les bras |
| Fournisseur d'inférence | le meilleur de chaque bras : CoreML pour le bras grille, CPU pour le bras graphe | identique |

Table: Réglages de recherche partagés par les deux bras. Les réglages d'auto-jeu proviennent du protocole gelé ; les réglages d'évaluation ont été épinglés par configuration le 9 septembre 2026, avant toute exécution d'entraînement, et tout changement ultérieur compterait comme une nouvelle étude. {#tbl:search-settings}

<!-- src: paper/annex-architectures.md:85-92; configs/eval-settings.toml; configs/comparison-matrix.yaml:25-33; state/decisions.md:565-587; docs/representations/comparison-controls.md:19-32 -->

La machinerie d'exploration est structurellement confinée à l'auto-jeu : les valeurs par défaut du chemin d'évaluation portent ε = 0 et aucune température, un test affirme ces valeurs par défaut, et le binaire du moteur n'expose aucun drapeau permettant d'activer le bruit, de sorte que la voie d'évaluation ne peut pas y souscrire. L'auto-jeu active le bruit explicitement. Les deux chemins diffèrent donc par construction plutôt que par convention.

<!-- src: configs/eval-settings.toml:6-9; state/decisions.md:572-582 -->
