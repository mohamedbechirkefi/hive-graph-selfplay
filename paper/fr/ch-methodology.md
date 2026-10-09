*Copie française (D-006) — version 1.0-draft 2026-10-09; les nombres et affirmations sont identiques au master anglais.*

# Chapitre 8 — Méthodologie de travail : une recherche humain–IA à portes (livret, 2026-10-09)

*Condensé de `docs/methodology.md` (espace de travail, v1.0) et du
journal méthodologique en ajout seul ; ce chapitre est aussi la
déclaration d'usage de l'IA du rapport, sous forme développée.*

## Division du travail

Cette étude a été exécutée sous **délégation au niveau des objectifs
avec autorité humaine mécanique**. L'auteur humain est le chercheur
principal : il détient les questions de recherche, chaque engagement
scientifique, chaque dépense, tout ce qui est public, et le dernier mot
sur chaque affirmation — une responsabilité qui n'est pas délégable.
L'assistant IA (Claude, Anthropic — opérant en sessions Claude Code)
est l'exécutant (*runtime*) : à partir du plan de recherche, il se
route lui-même, construit, mesure, journalise et rédige vers l'état
final du plan, sans instruction tâche par tâche.

La frontière est imposée par six **portes** énumérant les décisions que
seul l'humain prend : geler un protocole, une partition ou un ensemble
de test (G-FREEZE) ; dépenser ou lancer un calcul long (G-SPEND) ; tout
ce qui quitte la machine (G-PUBLIC) ; la réutilisation de matériel aux
droits non établis (G-RIGHTS) ; le contact institutionnel (G-ADMIN) ;
la destruction de données ou de résultats (G-DESTRUCTIVE). Chaque
franchissement de porte dans cette étude est consigné dans le journal
des décisions avec l'approbation de l'humain citée verbatim — le gel du
protocole, le gel de la population d'adversaires avec son sous-choix
budgétaire, le gel des ouvertures, quatre approbations de calcul avec
dimensionnement explicite, et les pré-engagements d'extension de
graines.

## Pourquoi l'état vit dans des fichiers

Les sessions sont sans état par conception : une session lit le fichier
de routage, exécute le document de pipeline de la phase active (tâches
ordonnées, chacune avec une vérification d'acceptation, closes par des
critères de sortie), journalise tout ce qui est mesuré, et met à jour
les fichiers d'état en dernier. La qualité de la recherche est ainsi
une propriété d'**artefacts de processus** — les journaux, le journal
des décisions, les documents gelés avec leurs hachages, le registre des
affirmations — et non de la mémoire ou de la compétence d'une session.
Tout ce que contient ce livret remonte à ces artefacts.

## Ce que la discipline a attrapé

Le journal méthodologique consigne chaque incident où la discipline a
changé une issue. Pendant cette étude, elle a attrapé, entre autres :
un interblocage de protocole dans les documents de pipeline avant toute
exécution ; un désaccord moteur-contre-corpus résolu *contre* le corpus
écrit à la main (le moteur avait raison, et la trace de l'erreur a été
conservée) ; un défaut du harnais d'évaluation détecté parce que trois
adversaires « différents » produisaient des résultats identiques ; un
chemin de perte silencieuse d'enregistrements dans le lanceur de
matchs, trouvé grâce à la règle selon laquelle chaque position d'échec
sélectionnée doit être *reproduite et vérifiée* avant publication ; et
une ablation qui avait silencieusement divergé vers NaN pendant dix
générations, attrapée par la même alarme de résultats identiques et
convertie en la découverte d'ablation la plus nette de l'étude. Le
motif est l'affirmation centrale de la méthodologie : **à petite
échelle, l'erreur de harnais est une menace plus grande que le bruit
statistique, et seule la vérification mécanique l'attrape.**

## Ce que l'IA n'a pas fait

L'IA n'a choisi aucune hypothèse, n'a rien gelé, n'a rien dépensé, n'a
rien publié et n'a décidé d'aucune affirmation. Là où ses brouillons
contenaient des erreurs, le processus — passes de traduction,
vérifications mécaniques de cohérence, relectures adversariales — en a
fait remonter plusieurs (comptes de graines périmés, limites
d'affirmations périmées) avant cette version ; le dossier de contrôle
final liste les vérifications. L'auteur humain a personnellement
vérifié les conclusions qu'il signe.
