*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Annexe B — Architectures, décodeur et formats de données en détail

*Sources : `python/hivenet/model.py`, `python/hivenet/graph_model.py`,
`crates/hive-nn/` (font autorité) ; docs/representations/ ;
docs/action-decoder.md. Les comptes de paramètres sont mesurés
(`count_params`), non estimés.*

## B.1 Bras grille — HiveNet (1.44 M paramètres)

Entrée : 77 plans × 32 × 32 (float32 dans [0,1]). Groupes de plans :
64 plans de pièces (camp propre/adverse × 8 types d'insectes × niveau
de pile 0–3+), sommets cloués One-Hive, cellule du dernier coup
(étourdissement), régions de placement légales pour les deux camps,
constante du camp au trait, scalaires de libertés des reines (les deux
reines, /6), pli/100, bits de type de partie, comptes de réserves
(/14).

Corps : tronc convolutif 3×3 → 8 blocs résiduels de 96 canaux (deux
conv 3×3 + BatchNorm chacun) ; les blocs 2 et 5 portent un biais de
pooling global de style KataGo (canaux agrégés moyenne‖max → linéaire
→ biais par canal). L'adjacence hexagonale en coordonnées axiales est
un sous-ensemble de 7 cellules du voisinage 3×3, de sorte que de
simples convolutions 3×3 la couvrent ; les deux coins non voisins
deviennent des poids morts apprenables.

Têtes : politique = convolution 1×1 vers 28 plans d'emplacements de
pièces, aplatie en 28,672 logits spatiaux, plus un logit de passe issu
des caractéristiques agrégées (POLICY_SIZE = 28,673) ; valeur =
caractéristiques agrégées → 64 → 3 (victoire/nulle/défaite du point de
vue du camp au trait).

## B.2 Bras graphe — HiveGraphNet (1.47 M paramètres, +1.5%)

Entrée par position : jusqu'à 224 nœuds (cellules occupées + chaque
cellule vide adjacente à la ruche — exactement l'univers de
destinations du décodeur), chacun avec 56 caractéristiques : pour
chaque niveau de pile 0–4, un bloc (présent, propriétaire-au-trait,
type d'insecte en one-hot[8]) ; hauteur de pile/5 ; bits candidat-vide,
cloué One-Hive, dernier coup, et les deux régions de placement. Un
vecteur global de 23 valeurs (trait, pli/100, libertés des reines/6,
réserves par type d'insecte/3 pour les deux camps, bits de type de
partie) est concaténé à l'entrée de chaque nœud.

Corps : linéaire d'entrée vers 152 canaux → 8 couches relationnelles à
passage de messages : h′ᵢ = ReLU(W_self hᵢ + Σ_d W_d h_{n_i(d)} + b)
avec six matrices de poids typées par direction (les six directions
hexagonales comme types d'arêtes), résiduelles, masquées ; une couche
sur trois ajoute un biais de pooling global masqué (moyenne‖max →
linéaire). La structure de voisinage est un tenseur d'indices
(224 × 6) avec une ligne de remplissage à zéro — toutes les formes
sont statiques, de sorte que l'export ONNX est à formes fixes et
s'exécute sous le même chemin d'inférence Rust que le bras grille.

Têtes : valeur = pooling moyenne‖max masqué ‖ globaux → 64 → 3 (même
convention). Politique = notation par candidat via le décodeur
partagé : pour chaque (emplacement, destination) légal, le logit est
MLP(plongement du nœud de destination ‖ plongement de la source ‖
plongement d'emplacement[32]), où le plongement de la source est le
nœud où la pièce se tient pour les mouvements et un vecteur de réserve
appris pour les placements ; un logit de passe appris. Les logits
s'attachent aux coups, jamais aux positions de liste.

**Variantes d'ablation** (H-T3) : `untyped_edges` partage UNE SEULE
matrice entre les six directions (0.54 M — les matrices typées sont le
composant ablaté) ; `no_gpool` retire chaque biais de pooling
(1.37 M).

## B.3 Le décodeur d'actions partagé

Un coup est (emplacement de pièce relatif au camp 0–27, cellule de
destination) plus la passe ; les emplacements 14–27 adressent les
pièces adverses (lancers du Pillbug ; inertes en jeu de base). Le bras
grille matérialise l'espace comme le tenseur plat à 28,673 sorties
(emplacement × cellule du cadre) ; le bras graphe note les paires
identiques par candidat. Les deux bras : masquage identique de
l'ensemble légal, softmax sur exactement l'ensemble légal, cibles de
distribution de visites MCTS identiques, départage déterministe vers
l'indice plat le plus bas. La vérification 1 de la batterie
pré-entraînement affirme une masse de probabilité nulle hors de
l'ensemble légal via une vraie passe avant, pour le bras testé quel
qu'il soit.

## B.4 Format d'enregistrement v3 (818 octets)

Octets 0–83 : 28 × (x, y, niveau) en coordonnées du cadre, 255 = en
main ; 84 camp au trait ; 85 identifiant du dernier coup (état
d'étourdissement) ; 86 pli ; 87 bits de type de partie ; 88–91
libertés des reines et réserves (joueur au trait/adversaire) ; 92–95
masque de bits des clouages One-Hive ; 96–97 indice de politique du
coup joué ; 98 issue du point de vue du joueur au trait — 0 défaite /
1 nulle / 2 victoire / **3 tronquée** (jamais une nulle) ; 99
version ; 100–107 estampille du modèle générateur (génération, hachage
du réseau) ; 112–175 distribution de visites MCTS top-15 + total ;
176–177 compte de coups légaux ; 178–817 la liste des indices de
politique légaux (plafond 320 ; facteur de branchement maximal mesuré
213) qui permet l'entraînement masqué sur l'ensemble légal dans les
deux bras. Les constructeurs Rust et Python des deux encodages — plans
et graphe — sont épinglés identiques à l'octet près par des tests
dorés inter-langages exécutés chaque nuit (240 et 160 positions
respectivement).

## B.5 Recherche (partagée)

MCTS PUCT, c = 1.4, évaluation des feuilles par lots, valeurs
terminales remontées exactement ; l'auto-jeu ajoute du bruit de
Dirichlet à la racine (ε 0.25), un échantillonnage en température sur
les 12 premiers plis, la randomisation du plafond de simulations (25%
des décisions à 128 simulations — enregistrées ; 75% à 32 — non
enregistrées), l'abandon à −0.92 avec un audit sans abandon de 10% ;
l'évaluation exécute 400 simulations, sans bruit, argmax déterministe
(imposé par test, épinglé par config).
