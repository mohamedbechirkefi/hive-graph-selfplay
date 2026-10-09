*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Méthode — Correction du moteur (brouillon de section du rapport)

*Rédigé le 2026-09-09 (invariant 14 : écrit au fil de la phase). Master de
travail en anglais ; copie française au jalon du rapport (D-006). Chaque
nombre est traçable à une entrée de journal (invariant 4) ; les
affirmations sont enregistrées dans `claims.md`.*

## Pourquoi la validation précède tout

Une étude par auto-jeu s'entraîne sur des positions que le moteur génère
et évalue lui-même ; un défaut de règles ne se contente donc pas d'ajouter
du bruit — il enseigne aux deux bras un jeu systématiquement faux et
invalide silencieusement la comparaison (« faux apprentissage », plan
ch. 4). La règle d'arrêt est absolue : un moteur trouvé incorrect suspend
tout le travail côté entraînement (invariant 11). Nous validons donc selon
quatre lignes de preuve indépendantes avant tout travail sur les
adversaires de base ou l'entraînement, et nous rapportons chaque ligne
avec sa portée exacte.

## Quatre lignes de preuve

**1. Perft contre les tables publiées.** Les comptes de nœuds pour les
8 types de partie correspondent aux tables perft publiées de Mzinga :
profondeur ≤5 dans la suite de tests standard, profondeur 6 dans une
exécution dédiée (8.3 s, tous les types), profondeur 7 dans le script
nocturne. Le perft est exhaustif à sa profondeur : toute divergence de la
génération de coups — un coup manquant, un coup en trop, une règle
d'empilement erronée — décale un compte. (Journal
`H2-2026-09-09-suite-rerun-01`.)

**2. Accord avec les moteurs de référence.** Le moteur passe le harnais
de conformité UHP de nokamute (21/21) et, de manière plus exigeante, le
fuzzing différentiel joue des parties aléatoires à graine fixée en
vérifiant à chaque demi-coup l'*égalité ensembliste* des coups légaux
contre deux moteurs de référence indépendants — MzingaEngine v0.16.0
(l'implémentation de référence UHP) et nokamute 1.0.3 : 27,829 positions
à la graine fixe de la session, 200/100 parties par type chaque nuit. Que
deux moteurs aux bases de code indépendantes s'accordent sur chaque
ensemble de coups légaux borne la probabilité d'une mauvaise lecture
partagée des règles. (Journal `H2-2026-09-09-suite-rerun-01`.)

**3. Corpus critique annoté à la main.** L'accord avec des moteurs de
référence ne peut pas détecter une mauvaise lecture partagée par les
moteurs de la communauté ; 30 positions critiques ont donc été annotées
*à la main à partir des règles de l'éditeur* (feuille de règles Gen42 et
feuille Pillbug, FAQ des World Hive Tournaments ; la règle d'ouverture de
tournoi déclarée comme convention) — glissement et portes, empilement du
scarabée et porte du scarabée au-dessus du sol, couleur de la pile pour le
placement, points d'articulation et anneaux de la règle One-Hive,
terminaison victoire/nulle y compris la nulle par encerclement simultané,
passe forcée, et l'étourdissement (stun) du Pillbug comme garde au niveau
du noyau. Les attendus ont été consignés par commit avant la première
exécution du moteur ; le lanceur compare les ensembles complets de coups
(pièce, destination) via UHP. Première exécution : 29/30, l'unique
désaccord ayant été résolu *contre le corpus* — une ligne de mise en place
violait la règle de transit One-Hive que le moteur applique correctement —
et 30/30 après la correction ; l'investigation est journalisée dans les
deux cas (invariant 2). Limite déclarée : les annotations n'ont pas encore
fait l'objet d'une relecture externe par un connaisseur de Hive. (Journal
`H2-2026-09-09-corpus-run-01`.)

**4. Sessions d'invariants aléatoires.** Des parties aléatoires à graine
fixée, sur l'ensemble des 8 types de partie, vérifient après chaque
transition : chaque coup généré est accepté par le chemin d'application
(et l'annulation restaure exactement la GameString), la ruche reste
connexe, la sérialisation→désérialisation via la GameString UHP reproduit
la position, le résultat et l'ensemble exact des coups valides, et la
passe est acceptée exactement quand aucun coup n'existe. 10,665,686 coups
générés ont été appliqués puis annulés sur 161,546 demi-coups (session
approfondie) avec zéro violation ; une session plus petite s'exécute dans
la suite standard à chaque build. (Journal
`H2-2026-09-09-random-invariants-01`.)

## Portée et lacunes assumées

La couverture de code n'est pas revendiquée comme preuve de correction
(plan ch. 4). Les lignes ci-dessus bornent des modes de défaillance
différents (exhaustivité à profondeur donnée, accord entre moteurs,
fidélité au texte des règles, stabilité des invariants), mais aucune ne
prouve la perfection sur parties complètes. Problèmes connus découverts
pendant le profilage et reportés à la phase pipeline, consignés comme
constats plutôt que corrigés silencieusement : les générateurs d'auto-jeu
des travaux antérieurs (*prior-work*) convertissent leur plafond de 300
demi-coups en nulle (l'invariant 7 l'interdit dans tout code de mesure de
la nouvelle étude), et le fournisseur d'exécution CoreML de ONNX côté Rust
plante actuellement sur la machine d'étude, alors que le même modèle
s'exécute sur CoreML via onnxruntime en Python à 2.62 ms/éval. (Journal
`H2-2026-09-09-throughput-profile-01`.)

## Vérification inter-langages du chemin de données

L'encodeur de plans Rust du bras grille et le décodeur Python côté
entraînement sont maintenus identiques à l'octet près, vérifiés par une
contre-vérification sur fichiers de référence (golden files) (240
positions, accord exact) exécutée dans le script nocturne. (Journal
`H2-2026-09-09-suite-rerun-01`.)
