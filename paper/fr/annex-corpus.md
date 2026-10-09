*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Annexe A — Corpus de positions annotées à la main

Chaque attendu ci-dessous a été écrit à la main à partir des règles de l'éditeur AVANT toute exécution du moteur (oracle avant toute sortie de modèle) ; l'exécution du moteur qui a suivi est journalisée, et l'unique désaccord constaté a été résolu contre le corpus (une erreur de transit One-Hive dans une séquence de mise en place), le moteur ayant eu raison. Ces rendus sont générés à partir des fichiers de cas exécutables par `scripts/make_annex_corpus.py` — les tests et l'annexe ne peuvent pas diverger.

## A.1 Corpus critique de règles (30 cas, H2)

Cas de correction des règles : placement, glissement/liberté de mouvement, portes, empilement, One-Hive, états terminaux, passe forcée, et cas d'étourdissement (stun) du Pillbug comme garde du noyau.

### C001 — La Reine ne peut pas être placée au premier tour (règle de tournoi)

- **Règle :** Règle d'ouverture de tournoi (*Tournament variant of the official rules (README source 4); Gen42 2010 rulesheet p. 3 alone would allow it*)
- **Mise en place :** ``
- **Attente :** move_illegal `{'move': 'wQ'}`
- **Justification manuscrite :** La feuille de règles de base 2010 dit que la Reine « peut être placée à tout moment de votre premier à votre quatrième tour » (p. 3), mais la variante de tournoi — adoptée par l'UHP et par les deux moteurs de référence, et la convention que cette étude fixe — interdit de placer la Reine au premier tour de l'un ou l'autre joueur. Le premier coup des Blancs « wQ » doit donc être rejeté.

### C002 — La Reine doit être placée au quatrième tour si elle ne l'a pas été avant

- **Règle :** Placement de votre Reine (*Gen42 Hive rulesheet p. 3*)
- **Mise en place :** `wS1;bS1 wS1-;wG1 -wS1;bG1 bS1-;wA1 -wG1;bA1 bG1-`
- **Attente :** all_moves_place `{'piece': 'wQ'}`
- **Justification manuscrite :** « Vous devez placer votre Reine à votre quatrième tour si vous ne l'avez pas placée avant. » (p. 3). C'est le quatrième tour des Blancs et wQ est encore en réserve, donc chaque coup légal doit être un placement de wQ. (Les coups de déplacement sont de plus exclus par la règle de Déplacement, p. 3 : aucun déplacement avant que la reine soit placée.) Légalité de la mise en place : chaque placement blanc ne touche que des pièces blanches, chaque placement noir que des pièces noires (Placement, p. 2).

### C003 — Aucune pièce ne peut se déplacer avant que la reine de ce joueur soit placée

- **Règle :** Déplacement (*Gen42 Hive rulesheet p. 3*)
- **Mise en place :** `wS1;bS1 wS1-`
- **Attente :** all_moves_are_placements
- **Justification manuscrite :** « Une fois votre Reine placée (mais pas avant), vous pouvez décider d'utiliser chaque tour suivant pour placer une autre tuile ou pour déplacer l'une des pièces déjà placées. » (p. 3). La reine des Blancs n'est pas placée au tour 2, donc wS1 ne doit avoir aucun coup de déplacement — seuls des placements sont proposés.

### C004 — Après les premières pièces, les placements ne peuvent pas toucher la couleur adverse

- **Règle :** Placement (*Gen42 Hive rulesheet p. 2*)
- **Mise en place :** `wG1;bS1 wG1/`
- **Attente :** moves_for_piece `{'piece': 'wB1', 'moves': ['wB1 wG1\\', 'wB1 /wG1', 'wB1 -wG1']}`
- **Justification manuscrite :** « …à l'exception de la première pièce placée par chaque joueur, les pièces ne peuvent pas être placées à côté d'une pièce de la couleur de l'adversaire. » (p. 2). wG1 est à l'origine avec bS1 à son nord-est. Des cinq voisines vides de wG1 (E, SE, SO, O, NO), les cellules E et NO touchent chacune aussi bS1 (ce sont les deux cellules adjacentes à la fois à wG1 et à sa voisine NE), donc une nouvelle pièce blanche ne peut aller qu'au SE, au SO ou à l'O de wG1. Placements attendus pour wB1 : exactement ces trois cellules. Géométrie à la main : axial E=(1,0), NE=(1,-1) ; les voisines de la cellule NE (1,-1) comprennent (1,0)=E-de-l'origine et (0,-1)=NO-de-l'origine.

### C005 — La première pièce du second joueur rejoint la première pièce (contact ennemi permis)

- **Règle :** Déroulement de la partie / Placement (*Gen42 Hive rulesheet pp. 2-3*)
- **Mise en place :** `wS1`
- **Attente :** moves_for_piece `{'piece': 'bG1', 'moves': ['bG1 wS1-', 'bG1 wS1/', 'bG1 wS1\\', 'bG1 -wS1', 'bG1 /wS1', 'bG1 \\wS1']}`
- **Justification manuscrite :** « La partie commence par un joueur qui place une pièce de sa main au centre de la table, puis le joueur suivant joint l'une de ses propres pièces à celle-ci, bord à bord. » (p. 2) — l'exception de la première pièce à la règle de placement sur sa propre couleur. La première pièce des Noirs doit rejoindre wS1 bord à bord, donc bG1 peut être placée sur n'importe laquelle des six cellules adjacentes à wS1, et nulle part ailleurs.

### C006 — Reine à la pointe de la ruche : exactement les deux glissements qui gardent le contact

- **Règle :** Reine / Liberté de mouvement / One-Hive (contact) (*Gen42 Hive rulesheet pp. 4, 9, 10*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- **Attente :** moves_for_piece `{'piece': 'wQ', 'moves': ['wQ \\wS1', 'wQ /wS1']}`
- **Justification manuscrite :** La Reine « ne peut se déplacer que d'un espace par tour » (p. 4) en un mouvement de glissement (p. 10), et « toutes les pièces doivent toujours toucher au moins une autre pièce » (p. 3 NB). wQ est à la pointe ouest d'une ligne droite de quatre. De ses cinq voisines vides, seules les deux cellules qui sont aussi adjacentes à sa voisine wS1 (les cellules au NO et au SO de wS1) gardent le contact avec la ruche après le glissement ; les trois cellules plus à l'ouest ne touchent plus rien une fois la reine partie. Aucune des deux destinations n'est derrière une porte (pour chaque glissement, des deux cellules flanquantes, l'une est occupée, l'autre vide). Attendu : exactement ces deux coups.

### C007 — Fourmi enfermée dans une poche : la seule sortie est une porte, donc elle ne peut pas bouger

- **Règle :** Liberté de mouvement (*Gen42 Hive rulesheet p. 10*)
- **Mise en place :** `wA1;bS1 wA1-;wQ \wA1;bQ bS1-;wG1 -wA1;bB1 bQ/;wS1 /wA1;bB1 bS1/;wB1 \wQ;bB1 wA1/`
- **Attente :** moves_for_piece `{'piece': 'wA1', 'moves': []}`
- **Justification manuscrite :** « Si une pièce est entourée au point de ne plus pouvoir physiquement glisser hors de sa position, elle ne peut pas être déplacée. » (p. 10). Cinq des six voisines de la fourmi sont occupées. La seule voisine vide (au SE de la fourmi) est flanquée par bS1 (à l'E de la fourmi) et wS1 (au SO de la fourmi) — les deux cellules adjacentes à la fois à la fourmi et à cet espace — donc la fourmi ne peut pas physiquement y glisser. Retirer la fourmi ne scinderait PAS la ruche (l'anneau bB1-wQ-wG1-wS1 plus bS1 reste connexe), donc le blocage relève purement de la liberté de mouvement, pas de One-Hive. La fourmi, normalement la pièce la plus mobile, a zéro coup légal.

### C008 — L'araignée se déplace d'exactement trois espaces le long du bord de la ruche — deux destinations

- **Règle :** Araignée (*Gen42 Hive rulesheet p. 7*)
- **Mise en place :** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wS1 \wQ;bG1 bQ-`
- **Attente :** moves_for_piece `{'piece': 'wS1', 'moves': ['wS1 bS1/', 'wS1 wQ\\']}`
- **Justification manuscrite :** « L'Araignée se déplace de trois espaces par tour — ni plus, ni moins. Elle doit suivre un chemin direct et ne peut pas revenir sur ses pas. Elle ne peut se déplacer qu'autour des pièces avec lesquelles elle est en contact direct à chaque pas. » (p. 7). La ruche moins l'araignée est une ligne droite de cinq pièces dont la frontière est un unique anneau de 14 cellules sans portes ; chaque cellule de l'anneau touche la ligne, et les cellules hors de l'anneau ne touchent rien (exclues par l'exigence de contact). Depuis sa position sur l'anneau, l'araignée a donc exactement deux marches de trois pas — trois cellules dans le sens horaire et trois cellules dans le sens antihoraire : la cellule au NE de bS1, et la cellule au SE de wQ. Les arrêts après un ou deux pas sont exclus (« ni moins »), le retour en arrière est exclu.

### C009 — Sauterelle : ne saute que le long de rangées occupées, pas de glissements d'un espace

- **Règle :** Sauterelle (*Gen42 Hive rulesheet p. 6*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 \wS1;bG1 bQ-`
- **Attente :** moves_for_piece `{'piece': 'wG1', 'moves': ['wG1 wS1\\', 'wG1 /wQ']}`
- **Justification manuscrite :** « Elle saute depuis son espace par-dessus un nombre quelconque de pièces (mais au moins une) jusqu'au premier espace inoccupé le long d'une rangée droite de pièces jointes. » (p. 6). La sauterelle touche des cellules occupées dans exactement deux de ses six directions : SE (par-dessus wS1, atterrissant dans l'espace suivant, au SE de wS1) et SO (par-dessus wQ, atterrissant au SO de wQ). Dans les quatre autres directions, la cellule adjacente est vide, et un saut « par-dessus au moins une » pièce est impossible — en particulier, les quatre cellules vides adjacentes ne sont PAS des destinations : la sauterelle « ne se déplace pas autour de l'extérieur de la Ruche comme les autres créatures ». Attendu : exactement les deux cellules d'atterrissage.

### C010 — La sauterelle saute une rangée complète de cinq pièces jusqu'au premier espace vide

- **Règle :** Sauterelle (*Gen42 Hive rulesheet p. 6*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-`
- **Attente :** moves_for_piece `{'piece': 'wG1', 'moves': ['wG1 bG1-']}`
- **Justification manuscrite :** « …par-dessus un nombre quelconque de pièces (mais au moins une) jusqu'au premier espace inoccupé le long d'une rangée droite de pièces jointes. » (p. 6). Plein est, la sauterelle fait face à la rangée ininterrompue wQ, wS1, bS1, bQ, bG1 ; le premier espace inoccupé au-delà est la cellule à l'E de bG1 — l'unique destination. Elle doit atterrir là, pas avant (chaque cellule plus proche dans la rangée est occupée). Dans les cinq autres directions, la cellule adjacente est vide, donc aucun saut n'existe. La sauterelle est une feuille de la ruche, donc One-Hive ne la restreint pas.

### C011 — La seule voisine ouverte de la reine est derrière une porte : zéro coup

- **Règle :** Liberté de mouvement (*Gen42 Hive rulesheet p. 10*)
- **Mise en place :** `wS1;bS1 -wS1;wB1 wS1/;bQ -bS1;wQ wB1-;bG1 \bQ;wS2 wQ/;bA1 /bQ;wG1 -wS2;bS2 /bS1;wA1 wS2\;bB1 \bG1;wG2 wQ\;bG2 \bB1`
- **Attente :** moves_for_piece `{'piece': 'wQ', 'moves': []}`
- **Justification manuscrite :** « De même, aucune pièce ne peut se déplacer dans un espace où elle ne peut pas physiquement glisser. » (p. 10). Cinq des six voisines de la reine sont des pièces blanches ; la sixième (la cellule à l'O de wG2, également au SE de wB1) est vide, mais les deux cellules adjacentes à la fois à la reine et à cet espace sont wG2 et wB1 — toutes deux occupées — donc la reine ne peut pas physiquement y glisser. Retirer la reine laisse le fer à cheval blanc wS1-wB1-wG1-wS2-wA1-wG2 connexe (et la chaîne noire pend de wS1 via bS1), donc One-Hive autoriserait le coup ; le blocage relève purement de la liberté de mouvement. Attendu : la reine n'a aucun coup légal.

### C012 — La fourmi atteint chaque cellule du périmètre de la ruche (13 destinations)

- **Règle :** Fourmi soldat / Liberté de mouvement (*Gen42 Hive rulesheet pp. 8, 10*)
- **Mise en place :** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wA1 \wQ;bG1 bQ-`
- **Attente :** moves_for_piece `{'piece': 'wA1', 'moves': ['wA1 -wQ', 'wA1 \\wG1', 'wA1 \\bS1', 'wA1 \\bQ', 'wA1 \\bG1', 'wA1 bG1/', 'wA1 bG1-', 'wA1 bG1\\', 'wA1 bQ\\', 'wA1 bS1\\', 'wA1 wG1\\', 'wA1 wQ\\', 'wA1 /wQ']}`
- **Justification manuscrite :** « La Fourmi soldat peut se déplacer de sa position vers n'importe quelle autre position autour de la Ruche, pourvu que les restrictions soient respectées. » (p. 8). La ruche moins la fourmi est une ligne droite de cinq pièces ; sa frontière est un unique anneau de 14 cellules sans portes (chaque pas de glissement est flanqué d'une cellule de la ligne et d'une cellule vide), et chaque cellule de l'anneau touche la ligne. La fourmi part de l'anneau, sur la cellule au NO de wQ, donc elle peut s'arrêter sur n'importe laquelle des 13 autres cellules de l'anneau : le bout ouest (à l'O de wQ), les cinq cellules de l'épaule nord (au NO de chaque pièce de la ligne plus au NE de bG1), le bout est (à l'E de bG1), et les six cellules de l'épaule sud (au SE de chaque pièce de la ligne plus au SO de wQ). Les cellules hors de l'anneau ne touchent aucune pièce et sont exclues (p. 3 NB : les pièces doivent toujours toucher au moins une autre pièce).

### C013 — Scarabée au sol : deux glissements et deux escalades

- **Règle :** Scarabée (*Gen42 Hive rulesheet pp. 4-5, 10*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-`
- **Attente :** moves_for_piece `{'piece': 'wB1', 'moves': ['wB1 wS1', 'wB1 wQ', 'wB1 \\bS1', 'wB1 \\wQ']}`
- **Justification manuscrite :** « Le Scarabée, comme la Reine, ne se déplace que d'un espace par tour. Contrairement à toute autre créature cependant, il peut aussi se déplacer sur le dessus de la Ruche. » (p. 4). Depuis (au NO de wS1), le scarabée peut grimper sur l'une ou l'autre des pièces adjacentes — wS1 ou wQ — ou glisser au sol vers les deux cellules vides qui gardent le contact avec la ruche : au NO de bS1 (touchant wS1 et bS1) et au NO de wQ (touchant wQ). Les deux voisines vides restantes ne touchent aucune pièce après que le scarabée se soulève, donc elles sont exclues (p. 3 NB). Aucune porte ne bloque aucun des quatre coups (chacun est flanqué d'au plus une cellule occupée, et pour les escalades les piles flanquantes ne sont pas plus hautes que la destination). Exactement quatre coups — ce qui correspond au compte de l'exemple de scarabée de la feuille de règles elle-même.

### C014 — Scarabée au sommet de la ruche : les six cellules voisines

- **Règle :** Scarabée (*Gen42 Hive rulesheet p. 5; beetle-gate ruling, World Hive Tournaments Rules FAQ*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-;wB1 wS1;bA1 bG1-`
- **Attente :** moves_for_piece `{'piece': 'wB1', 'moves': ['wB1 bS1', 'wB1 wQ', 'wB1 \\wS1', 'wB1 \\bS1', 'wB1 wS1\\', 'wB1 wQ\\']}`
- **Justification manuscrite :** « Depuis sa position au sommet de la Ruche, le Scarabée peut se déplacer de tuile en tuile sur le dessus de la Ruche. Il peut aussi descendre dans des espaces entourés et donc inaccessibles à la plupart des autres créatures. » (p. 5). Posé sur wS1, le scarabée peut aller sur chacune des six cellules voisines : passer sur bS1 ou wQ (deux piles de hauteur 1), ou descendre sur n'importe laquelle des quatre cellules vides autour de wS1 — chacune touchant encore wS1 lui-même, donc le contact tient. Aucune paire de piles flanquantes n'est plus haute à la fois que l'origine (hauteur 1 sous le scarabée) et la destination, donc aucune porte du scarabée ne s'applique (FAQ). One-Hive ne peut pas être violée : wS1 reste où il est. Exactement six destinations.

### C015 — Porte du scarabée : la descente entre deux piles de hauteur 2 est bloquée

- **Règle :** Liberté de mouvement au-dessus du sol (porte du scarabée) (*World Hive Tournaments Rules FAQ; Gen42 Hive rulesheet p. 10*)
- **Mise en place :** `wS1;bG1 wS1/;wQ /wS1;bQ bG1/;wG1 wS1\;bB1 bQ/;wB1 -wS1;bB1 bQ;wB2 /wQ;bB1 bG1;wB1 wS1;bQ bB1-;wB2 wQ;bQ bB1/;wB2 wG1;bA1 bQ/`
- **Attente :** move_illegal `{'move': 'wB1 bB1\\'}`
- **Justification manuscrite :** « Quand une pièce monte ou descend la ruche, ou se déplace en restant au sommet de la ruche, elle doit pouvoir glisser selon la règle de liberté de mouvement, qui s'applique aux niveaux supérieurs au sol. Si deux piles forment une porte au-dessus du niveau du sol (nous l'appelons porte du scarabée), les pièces ne peuvent pas s'y glisser. » (WHT Rules FAQ). wB1 est posé sur wS1 (son propre niveau : au sommet d'une pièce de hauteur 1) ; la cellule cible au SE de la pile bB1 est vide (hauteur 0). Les deux cellules adjacentes à la fois à l'origine et à la cible portent les piles bG1+bB1 et wG1+wB2, toutes deux de hauteur 2 — strictement plus hautes à la fois que l'origine sans le scarabée (1) et que la destination (0) — donc le scarabée ne peut pas glisser vers le bas entre elles. La descente doit être rejetée. (One-Hive l'autoriserait : wS1 reste en place ; le contact tient via les piles flanquantes.)

### C016 — Une pièce surmontée d'un scarabée ne peut pas bouger

- **Règle :** Scarabée (immobilité sous pile) (*Gen42 Hive rulesheet p. 5*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-;wB1 wS1;bA1 bG1-`
- **Attente :** move_illegal `{'move': 'wS1 bS1\\'}`
- **Justification manuscrite :** « Une pièce avec un scarabée sur elle est incapable de bouger » (p. 5). wS1 est sous wB1, donc toute tentative de déplacer wS1 — ici un coup d'araignée vers la cellule au SE de bS1 — doit être rejetée, que le chemin soit par ailleurs légal ou non pour une araignée.

### C017 — La pile prend la couleur du scarabée : les Blancs peuvent placer à côté d'une reine noire recouverte

- **Règle :** Scarabée (couleur de la pile) / Placement (*Gen42 Hive rulesheet pp. 2, 5*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bA1 bS1\;wB1 \bS1;bG1 bA1\;wB1 \bQ;bG2 bG1\;wB1 bQ;bB1 bG2\`
- **Attente :** move_legal `{'move': 'wG1 wB1-'}`
- **Justification manuscrite :** « …aux fins des règles de placement de la p. 2, la pile prend la couleur du Scarabée. » (p. 5). Le scarabée blanc est posé sur la reine noire à l'extrémité est de la ruche. La cellule à l'E de cette pile ne touche aucune autre pièce, donc un placement blanc à cet endroit n'est adjacent qu'à une pile dont la couleur est — par la règle — blanche. Le placement de wG1 à cet endroit doit être accepté. (Sans la règle de couleur de pile, la cellule serait adjacente à une pièce noire et le placement serait illégal, p. 2.)

### C018 — La pile prend la couleur du scarabée : les Noirs ne peuvent PAS placer à côté de leur propre reine recouverte

- **Règle :** Scarabée (couleur de la pile) / Placement (*Gen42 Hive rulesheet pp. 2, 5*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bA1 bS1\;wB1 \bS1;bG1 bA1\;wB1 \bQ;bG2 bG1\;wB1 bQ;bB1 bG2\;wG1 -wQ`
- **Attente :** move_illegal `{'move': 'bB2 wB1-'}`
- **Justification manuscrite :** Miroir de C017 : la pile bQ+wB1 compte comme BLANCHE (« la pile prend la couleur du Scarabée », p. 5). La cellule à l'E de la pile ne touche que cette pile, donc pour les Noirs elle est adjacente à une pièce blanche et « les pièces ne peuvent pas être placées à côté d'une pièce de la couleur de l'adversaire » (p. 2). La tentative des Noirs de placer bB2 à cet endroit doit être rejetée — même si la pièce enfouie est la propre reine des Noirs.

### C019 — One-Hive : la seule connexion entre deux parties ne peut pas bouger

- **Règle :** Règle One-Hive (*Gen42 Hive rulesheet pp. 3, 9*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- **Attente :** moves_for_piece `{'piece': 'wS1', 'moves': []}`
- **Justification manuscrite :** « Toutes les pièces doivent toujours toucher au moins une autre pièce. Si une pièce est la seule connexion entre deux parties de la Ruche, elle ne peut pas être déplacée. » (p. 3 NB) ; « Les pièces en jeu doivent être reliées à tout moment. À aucun moment vous ne pouvez laisser une pièce isolée (non reliée à la Ruche) ni séparer la Ruche en deux. » (p. 9). wS1 est le lien intérieur entre wQ d'un côté et bS1-bQ de l'autre : la soulever scinde la ruche, donc l'araignée n'a aucun coup légal — chaque destination, si valide soit-elle comme déplacement d'araignée, est exclue par One-Hive.

### C020 — Anneau : une pièce sur une boucle fermée peut bouger (pas un point d'articulation) ; l'œil de l'anneau est derrière une porte

- **Règle :** Règle One-Hive / Liberté de mouvement (*Gen42 Hive rulesheet pp. 9, 10*)
- **Mise en place :** `wS1;bS1 -wS1;wG1 wS1/;bQ -bS1;wQ wS1\;bG1 -bQ;wG2 wG1-;bG2 -bG1;wA1 wQ-;bA1 -bG2;wS2 wG2\;bB1 -bA1`
- **Attente :** moves_for_piece `{'piece': 'wQ', 'moves': ['wQ /wS1', 'wQ /wA1']}`
- **Justification manuscrite :** Les six pièces blanches forment un anneau fermé, donc retirer wQ laisse les cinq autres connexes le long de la boucle (et la queue noire pend de wS1) : One-Hive permet à la reine de bouger. En glissant d'un espace (p. 4), la reine a trois voisines vides : l'œil de l'anneau et deux cellules extérieures. L'œil est flanqué par wS1 et wA1 — toutes deux occupées — donc la reine « ne peut pas se déplacer dans un espace où elle ne peut pas physiquement glisser » (p. 10). Les deux cellules extérieures (au SO de wS1, qui touche wS1 et bS1 ; et au SO de wA1, qui touche wA1) sont des glissements sans obstruction qui gardent le contact. Attendu : exactement ces deux destinations.

### C021 — La partie se termine quand une reine est complètement encerclée — même par sa propre couleur

- **Règle :** Le but de Hive / La fin de la partie (*Gen42 Hive rulesheet pp. 1, 11*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-;wA1 -wG1;bG2 bQ/;wA2 -wA1;bB1 \bQ;wA3 -wA2;bA1 bS1\;wS2 -wA3;bA2 bQ\`
- **Attente :** game_over `{'state': 'WhiteWins'}`
- **Justification manuscrite :** « Les pièces entourant la Reine peuvent être un mélange de vos pièces et de celles de votre adversaire. » (p. 1). « La partie se termine dès qu'une Reine est complètement encerclée par des pièces de n'importe quelle couleur. La personne dont la Reine est encerclée perd la partie. » (p. 11). Le dernier placement des Noirs (bA2, au SE de leur propre reine) remplit la sixième et dernière cellule autour de bQ. Les pièces qui l'entourent sont toutes noires — sans importance selon la p. 1 — et c'est le propre coup des Noirs qui achève l'encerclement : les Noirs perdent, l'état de la GameString doit indiquer WhiteWins immédiatement après ce coup.

### C022 — Un seul coup encercle les deux reines simultanément : nulle

- **Règle :** La fin de la partie (*Gen42 Hive rulesheet p. 11*)
- **Mise en place :** `wS1;bS1 wS1/;wQ wS1\;bB1 bS1-;wA1 -wQ;bQ bB1\;wS2 /wQ;bQ /bB1;wG1 -wS2;bQ wQ-;wB1 -wA1;bA1 bQ\;wG1 wS2-;bG1 \bS1;wB1 \wA1;bA2 bQ-;wB1 \wS1;bA3 bB1\;wG2 -wB1;bG1 bS1\`
- **Attente :** game_over `{'state': 'Draw'}`
- **Justification manuscrite :** « La personne dont la Reine est encerclée perd la partie, sauf si la dernière pièce à encercler sa Reine achève aussi l'encerclement de l'autre Reine. Dans ce cas, la partie est nulle. » (p. 11). Avant le dernier coup des Noirs, chaque reine a exactement une voisine vide — la même cellule (1,0), adjacente aux deux reines (les reines sont côte à côte, wQ à l'épaule NE de wS1, bQ à côté d'elle). La sauterelle noire en (1,-2) saute au SE par-dessus bS1 dans cette cellule, remplissant d'une seule pièce la sixième voisine des deux reines : la partie doit se terminer par une nulle (Draw), pas par une victoire de l'un ou l'autre camp.

### C023 — Un joueur qui ne peut ni placer ni bouger doit passer

- **Règle :** Impossibilité de déplacer ou de placer (*Gen42 Hive rulesheet pp. 2, 5, 10, 11*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bQ bS1/;wA1 /wQ;bQ bS1-;wB1 \bS1;bQ bS1/;wB1 bS1;bQ wB1-;wA1 /bQ;bQ wB1/;wA2 /wQ;bQ wB1-;wA2 bQ\;bQ wB1/;wA3 /wQ;bQ wB1-;wA3 bQ-;bQ wB1/;wG1 /wB1;bQ wB1-;wG1 wB1/`
- **Attente :** must_pass
- **Justification manuscrite :** « Si un joueur ne peut ni placer une nouvelle pièce ni déplacer une pièce existante, le tour passe à son adversaire, qui joue alors de nouveau. » (p. 11). Après le dernier coup des Blancs, les Noirs ont : bS1 sous wB1 — « une pièce avec un scarabée sur elle est incapable de bouger » (p. 5), et la pile compte comme blanche pour le placement (p. 5) ; et bQ, dont les cinq voisines sont la pile, wG1, wA1, wA2 et wA3, sa seule voisine vide n'étant atteignable qu'entre wG1 et wA3 — une porte où la reine « ne peut pas physiquement glisser » (p. 10). Aucun placement n'est possible non plus : la seule cellule adjacente à une pièce à sommet noir est cette même cellule derrière la porte, qui touche aussi des pièces blanches (p. 2). Les Noirs ne sont pas perdus — bQ a une voisine vide, donc elle n'est pas encerclée — mais doivent passer.

### C024 — Capacité spéciale du Pillbug : déplacer une pièce amie adjacente (garde du noyau)

- **Règle :** Capacité spéciale du Pillbug (*Gen42 Pillbug rulesheet (English section)*)
- **Mise en place :** `wP;bS1 wP-;wQ -wP;bQ bS1-`
- **Attente :** move_legal `{'move': 'wQ wP\\'}`
- **Justification manuscrite :** « La capacité spéciale permet au Pillbug de déplacer une pièce adjacente (amie ou ennemie) de deux espaces ; vers le haut sur lui-même, puis vers le bas dans un autre espace vide adjacent à lui-même. » (feuille Pillbug). wQ est adjacente à wP ; la cellule cible au SE de wP est vide et adjacente à wP. Aucune des quatre exceptions ne s'applique : wQ ne vient pas d'être déplacée par l'autre joueur (le dernier coup des Noirs était le placement de bQ), wQ n'est pas dans une pile, retirer wQ ne scinde pas la ruche (c'est une feuille), et aucune pièce empilée ne forme de porte sur le chemin de montée et de descente. NOTE : ceci est un cas de garde du noyau étiqueté variante (protocole §2) — la variante de l'étude est le jeu de base ; les cas Pillbug ne protègent que le noyau de règles partagé.

### C025 — Une pièce que le Pillbug ennemi vient de déplacer est étourdie pour un tour (garde du noyau)

- **Règle :** Capacité spéciale du Pillbug (immobilité de la pièce déplacée) (*Gen42 Pillbug rulesheet (English section); World Hive Tournaments Rules FAQ*)
- **Mise en place :** `wS1;bP wS1-;wQ -wS1;bQ bP-;wA1 \wQ;bG1 bQ-;wA1 \bP;bG1 -wQ;wG1 -wA1;wA1 bP\`
- **Attente :** move_illegal `{'move': 'wA1 bP/'}`
- **Justification manuscrite :** « De plus, toute pièce déplacée par le Pillbug ne peut pas du tout être déplacée (directement ou via une action du Pillbug) au tour du joueur suivant. » (feuille Pillbug) ; FAQ : « toute pièce qui vient de bouger, au tour de l'autre joueur immédiatement après, est incapable de : bouger, être déplacée ou utiliser la capacité du pillbug. » Le Pillbug noir vient de lancer wA1 par-dessus lui-même jusqu'à la cellule au SE de bP (un usage légal : wA1 avait bougé pour la dernière fois deux plis plus tôt, donc l'exception du dernier-déplacé ne bloquait pas le lancer ; son retrait gardait la ruche entière puisque wG1 touche aussi wS1 et wQ). Au tour immédiatement suivant des Blancs, la fourmi lancée est étourdie : la tentative de coup de fourmi vers le NE de bP doit être rejetée. Cas de garde du noyau étiqueté variante (protocole §2).

### C026 — Le Pillbug ne peut pas déplacer la pièce que l'adversaire vient de déplacer (garde du noyau)

- **Règle :** Capacité spéciale du Pillbug (exceptions) (*Gen42 Pillbug rulesheet (English section)*)
- **Mise en place :** `wS1;bP wS1-;wQ -wS1;bQ bP-;wA1 \wQ;bG1 bQ-;wA1 \bP`
- **Attente :** move_illegal `{'move': 'wA1 bP\\'}`
- **Justification manuscrite :** « Le Pillbug ne peut pas déplacer la pièce qui vient d'être déplacée par l'autre joueur. » (feuille Pillbug, première exception). La fourmi des Blancs s'est déplacée vers la cellule au NO de bP au pli immédiatement précédent ; la tentative des Noirs d'utiliser la capacité du Pillbug sur cette même fourmi — la lancer au SE de bP — doit être rejetée. (Le même lancer devient légal deux plis plus tard, ce qui constitue la mise en place du cas C025.) Cas de garde du noyau étiqueté variante (protocole §2).

### C027 — One-Hive lie même la sauterelle : un point d'articulation ne peut pas sauter

- **Règle :** Règle One-Hive / Sauterelle (*Gen42 Hive rulesheet pp. 3, 6, 9*)
- **Mise en place :** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-`
- **Attente :** moves_for_piece `{'piece': 'wG1', 'moves': []}`
- **Justification manuscrite :** La sauterelle est exemptée de la restriction de glissement (p. 10 : elle « peut sauter dans un espace ou hors d'un espace »), mais pas de One-Hive : « Si une pièce est la seule connexion entre deux parties de la Ruche, elle ne peut pas être déplacée. » (p. 3 NB). wG1 est entre wQ et la paire noire ; la soulever pour n'importe quel saut scinde la ruche en deux, donc malgré des lignes de saut dans les directions E et O, la sauterelle n'a aucun coup légal.

### C028 — Un scarabée ne peut pas être PLACÉ directement au sommet de la ruche

- **Règle :** Scarabée (NB de placement) (*Gen42 Hive rulesheet p. 5*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-`
- **Attente :** move_illegal `{'move': 'wB1 wS1'}`
- **Justification manuscrite :** « Lorsqu'il est placé pour la première fois, le Scarabée est placé de la même manière que toutes les autres pièces. Il ne peut pas être placé directement sur le dessus de la Ruche, même s'il peut y être déplacé plus tard. » (p. 5 NB). wB1 est encore en réserve ; la tentative de l'introduire au sommet de wS1 doit être rejetée. (C013/C014 vérifient que le même scarabée peut y grimper par un coup une fois placé.)

### C029 — L'araignée ne peut pas s'arrêter après un pas (« ni plus, ni moins »)

- **Règle :** Araignée (*Gen42 Hive rulesheet p. 7*)
- **Mise en place :** `wG1;bS1 wG1-;wQ -wG1;bQ bS1-;wS1 \wQ;bG1 bQ-`
- **Attente :** move_illegal `{'move': 'wS1 \\wG1'}`
- **Justification manuscrite :** « L'Araignée se déplace de trois espaces par tour — ni plus, ni moins. » (p. 7). La cellule au NO de wG1 est à exactement un pas de glissement de la position de l'araignée, et aucun chemin légal de trois pas sans retour en arrière ne s'y termine (les deux marches de trois pas se terminent au NE de bS1 et au SE de wQ — cas C008) ; un chemin passant par cette cellule la traverse au premier pas et ne peut pas s'y arrêter. Le coup d'un seul pas doit être rejeté.

### C030 — Reine entre deux pièces : deux glissements le long de l'épaule

- **Règle :** Reine / One-Hive / Liberté de mouvement (*Gen42 Hive rulesheet pp. 4, 9, 10*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wB1 \wS1;bG1 bQ-`
- **Attente :** moves_for_piece `{'piece': 'wQ', 'moves': ['wQ -wB1', 'wQ /wS1']}`
- **Justification manuscrite :** La reine touche wS1 (E) et wB1 (NE). La retirer garde la ruche entière (wB1 touche encore wS1), donc One-Hive autorise un coup. Glissements d'un espace (p. 4) : de ses quatre voisines vides, seules la cellule à l'O de wB1 (gardant le contact avec wB1) et la cellule au SO de wS1 (gardant le contact avec wS1) touchent encore la ruche après qu'elle se soulève ; les deux cellules plus à l'ouest ne touchent rien et sont exclues (p. 3 NB). Aucun des deux glissements n'est derrière une porte (chacun est flanqué d'exactement une cellule occupée). Attendu : exactement ces deux destinations.

## A.2 Ensemble de vérification tactique (5 cas, H3)

Cas de correction de la recherche : mat en 1 par marche et par saut, pour les deux couleurs, et évitement d'auto-encerclement ; résolus 5/5 par la base MCTS à 400, 1600 et 6400 simulations.

### T001 — Les Blancs font mat en 1 : occuper la dernière liberté de la reine noire (SE de bQ)

- **Règle :** La fin de la partie (*Gen42 Hive rulesheet pp. 1, 11*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ-;wA1 -wG1;bG2 bQ/;wA2 -wA1;bB1 \bQ;wA3 -wA2;bA1 bS1\`
- **Attente :** bestmove_to_cell `{'target': 'bQ\\'}`
- **Justification manuscrite :** La reine noire a exactement une voisine vide, la cellule au SE de bQ. Toute pièce blanche qui s'y pose achève l'encerclement et gagne immédiatement (« la partie se termine dès qu'une Reine est complètement encerclée par des pièces de n'importe quelle couleur », p. 11 ; mélange de couleurs permis, p. 1). La cellule est atteignable : une fourmi blanche peut parcourir le périmètre sud en un coup (l'entrée au-delà de bA1 n'est pas fermée par une porte), donc un coup gagnant existe. Aucun autre coup unique ne termine la partie. La recherche doit jouer sur cette cellule.

### T002 — Les Noirs font mat en 1 : occuper la dernière liberté de la reine blanche (SE de wQ)

- **Règle :** La fin de la partie (*Gen42 Hive rulesheet pp. 1, 11*)
- **Mise en place :** `wS1;bS1 -wS1;wQ wS1-;bQ -bS1;wG1 wQ-;bG1 -bQ;wG2 wQ/;bG2 -bG1;wB1 \wQ;bA1 -bG2;wA1 wS1\;bA2 -bA1;wA2 wG1-`
- **Attente :** bestmove_to_cell `{'target': 'wQ\\'}`
- **Justification manuscrite :** Miroir de T001 avec les couleurs échangées et les Noirs au trait — cette paire est la vérification d'alternance des joueurs au niveau du coup : le motif gagnant doit être trouvé des deux côtés. La seule voisine vide de la reine blanche est la cellule au SE de wQ ; une fourmi noire l'atteint le long du périmètre sud (route via le SE de la colonne de bS1 : le pas d'entrée dans la cellule est flanqué par la cellule occupée wA1, donc le contact tient et aucune porte ne bloque). S'y poser achève l'encerclement : les Noirs gagnent (p. 11).

### T003 — Les Blancs font mat en 1 par saut de sauterelle par-dessus quatre pièces (E de bQ)

- **Règle :** Sauterelle / La fin de la partie (*Gen42 Hive rulesheet pp. 6, 11*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 -wQ;bG1 bQ/;wA1 \wQ;bB1 \bQ;wA2 \wA1;bA1 bS1\;wA3 \wA2;bA2 bQ\`
- **Attente :** bestmove_to_cell `{'target': 'bQ-'}`
- **Justification manuscrite :** La seule voisine vide de la reine noire est la cellule à l'E de bQ. Plein est depuis wG1, au bout ouest, court la rangée occupée ininterrompue wQ, wS1, bS1, bQ ; le premier espace inoccupé le long de cette rangée est exactement la cellule gagnante, donc la sauterelle saute par-dessus quatre pièces et achève l'encerclement (p. 6 : « par-dessus un nombre quelconque de pièces … jusqu'au premier espace inoccupé le long d'une rangée droite de pièces jointes » ; p. 11 : l'encerclement termine la partie). Les fourmis blanches peuvent aussi entrer en marchant autour du périmètre — l'attendu est la cellule de destination, quelle que soit la pièce que la recherche envoie.

### T004 — Les Noirs font mat en 1 par saut de sauterelle par-dessus quatre pièces (O de wQ)

- **Règle :** Sauterelle / La fin de la partie (*Gen42 Hive rulesheet pp. 6, 11*)
- **Mise en place :** `wS1;bS1 wS1-;wQ -wS1;bQ bS1-;wG1 \wQ;bG1 bQ-;wG2 \wS1;bA1 bQ\;wA1 wQ\;bA2 bA1\;wA2 /wQ;bA3 bA2\;wB1 \wG1`
- **Attente :** bestmove_to_cell `{'target': '-wQ'}`
- **Justification manuscrite :** Miroir d'alternance de T003 avec le saut noir. Les voisines de la reine blanche : E wS1, NO wG1 (placé au NO de wQ), NE wG2 (placé au NO de wS1 = NE de wQ), SE wA1, SO wA2 — cinq occupées, seule la cellule à l'O de wQ est vide. Plein est de ce trou court la rangée ininterrompue wQ, wS1, bS1, bQ avec bG1 au bout est (3,0) : depuis bG1, le premier espace inoccupé vers l'ouest le long de la rangée est exactement le trou, donc la sauterelle saute par-dessus quatre pièces et achève l'encerclement (pp. 6, 11). La queue sud des Noirs (bA1..bA3 au SE de bG1) garde les placements noirs antérieurs légaux et à l'écart des Blancs.

### T005 — Ne pas remplir la dernière liberté de sa propre reine

- **Règle :** La fin de la partie (*Gen42 Hive rulesheet p. 11*)
- **Mise en place :** `wS1;bS1 -wS1;wQ wS1-;bQ -bS1;wG1 wQ-;bG1 -bQ;wG2 wQ/;bG2 -bG1;wB1 \wQ;bA1 -bG2;wA1 wS1\;bA2 -bA1`
- **Attente :** bestmove_avoid_cell `{'target': 'wQ\\'}`
- **Justification manuscrite :** La cellule au SE de wQ est la dernière liberté de la reine blanche. Que les Blancs y placent ou y déplacent n'importe quelle pièce achève l'encerclement de leur propre reine — « la personne dont la Reine est encerclée perd la partie » (p. 11), quel que soit le camp qui a fourni la sixième pièce. Le placement est parfaitement légal (la cellule ne touche que des pièces blanches), donc seul le jugement de la recherche l'empêche. Tout coup sauf un coup atterrissant sur cette cellule convient ; la recherche ne doit pas y jouer. (Ceci n'affirme pas que les Blancs survivent à long terme — les Noirs menacent la même cellule — seulement que l'auto-encerclement immédiat est évité.)
