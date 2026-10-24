## La seconde étude : constantes gelées, régime et graines {#sec:app-c-study2}

La seconde étude (`@sec:study2`{=typst}) réutilise toutes les constantes du `@tbl:app-c-frozen`{=typst} sauf là où le `@tbl:app-c-study2`{=typst} en dispose autrement, et tous les hyperparamètres du `@tbl:app-c-hyper`{=typst} sauf les données d'entraînement par génération. Son protocole a été gelé en version 2.0 le 13 octobre 2026 sous l'empreinte de contenu donnée au `@tbl:app-c-study2-hash`{=typst} ; les deux bras sont les configurations des deux premières lignes du `@tbl:app-c-configs`{=typst}, exécutées avec les graines 11 à 15, et aucune variante d'ablation n'a été exécutée.
<!-- src: docs/protocol-v2.md:3-12, 88-101 -->

| Constante | Valeur | Fixée le (2026) | Approuvée par |
| --- | --- | --- | --- |
| Régime d'entraînement | démarrage à chaud : le réseau de la génération $g$ est initialisé depuis le point de contrôle final de la génération $g-1$ (poids du modèle seulement ; l'optimiseur et le calendrier cosinus redémarrent à chaque génération) ; la génération 0 part de l'initialisation aléatoire ensemencée | 13 oct. (protocole v2) | l'auteur |
| Fenêtre de rejeu | 3 générations : la génération $g$ s'entraîne sur les enregistrements des générations $\max(0, g-2)$ à $g$, soit 500, 1,000, puis 1,500 parties à partir de la génération 2 ; 2 époques par génération | 13 oct. | l'auteur |
| Politique d'hyperparamètres | option A : les réglages de la première étude dans les deux bras, sans ajustement ; option B (trois taux d'apprentissage sur une graine par bras) examinée et écartée | 13 oct. | l'auteur |
| Graines d'entraînement | 11–15 par bras ; graine de base 100,000 × graine ; aucun flux aléatoire partagé avec les graines 1–5 | 13 oct. | l'auteur |
| Seuil à temps mural égal de la seconde étude | médiane du temps mural total d'entraînement des cinq runs grille de la seconde étude (somme des dix horloges par génération ; évaluations exclues), calculée une seule fois depuis les fichiers d'horloge avant tout nombre inter-bras, jamais recalculée | règle 13 oct. ; valeur après le cinquième run grille | règle : l'auteur ; valeur : calcul mécanique |
| Calendrier d'évaluation | générations 5 et 8 à 20 parties appariées par adversaire (descriptif seulement) ; point de contrôle final à 100 ; points de contrôle au seuil à 100 avec graine de réseau 9500 et graine d'appariement 888,000 | 13 oct. (comme dans la première étude) | l'auteur |
| Actifs gelés réutilisés | population d'adversaires, 250 ouvertures, réglages d'évaluation épinglés, les deux réseaux et le décodeur partagé, intouchés | 13 oct. (réutilisation déclarée) | l'auteur |
| Ordre d'exécution | dix runs séquentiels sur la machine de l'étude, en alternant grille puis graphe pour les graines 11 à 15 ; aucun autre processus lourd pendant la campagne | 13 oct. | l'auteur |
| Document de protocole | version 2.0 ; tout changement ultérieur est une nouvelle étude | 13 oct. | l'auteur |

Table: Constantes gelées de la seconde étude, avec la date à laquelle chacune a été fixée et l'approbation sous laquelle elle l'a été ; tout ce qui n'est pas listé est celui de la première étude. {#tbl:app-c-study2}
<!-- src: docs/protocol-v2.md:3-12, 53-75, 88-130, 152-166 -->

| Artefact | SHA-256 |
| --- | --- |
| Protocole, version 2.0 | e296a12e8d1e3dee36c3b210ececced62314e64657aede1cb91b1ea452b461eb |

Table: Empreinte de contenu du protocole gelé de la seconde étude ; les empreintes des artefacts réutilisés sont celles du `@tbl:app-c-hashes`{=typst}. {#tbl:app-c-study2-hash}
<!-- src: ../state/decisions.md (D-038) -->

La dérivation des graines du `@tbl:app-c-seeds`{=typst} s'applique sans changement avec $s$ = 11 à 15 : la graine de base est 100,000 × $s$, la génération $g$ utilise base + $g$ pour l'auto-jeu et l'entraînement, le réseau de la génération 0 est initialisé depuis la graine de base, et les graines d'évaluation (9000 + $g$ en cours de run, 9500 pour les ensembles au seuil ; appariement 777,000 + $g$ en cours de run, 888,000 pour les ensembles au seuil) sont celles de la première étude. Le pilote de campagne enregistre le régime de chaque run (démarrage à chaud actif, fenêtre 3) dans un fichier de configuration conservé avec le run, et la configuration d'entraînement de chaque génération liste le point de contrôle d'initialisation et les fragments effectivement lus.
<!-- src: docs/protocol-v2.md:88-101, 105-120; journal/2026-10-09-h9-driver-01.md:30-45 -->
