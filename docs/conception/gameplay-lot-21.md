# Lot 21 — Sauvegarder et reprendre en expédition (6C)

**Réalisé et validé par le joueur ; commit et push autorisés.**

## Comportement

**F5 sauvegarde la situation actuelle et met le jeu en pause.** Il ne rappelle plus les habitants, ne termine pas leurs livraisons et n’avance pas l’horloge. **F9** propose de remplacer la partie actuelle par la sauvegarde ; après confirmation, celle-ci revient en pause. **Espace** reprend les tâches conservées. **H** reste une commande indépendante de rappel.

Un habitant peut donc sauvegarder avant le départ, en file, pendant la traversée de la fissure, en reconnaissance, pendant la préparation/prise de caisse, au retour chargé ou pendant la dépose. Les autres habitants ne sont pas déplacés au refuge pour permettre cette opération.

## État conservé

- Positions, orientations, secteur, état du contrôleur, progression des déplacements et de l’animation, caisse visible et attachement aux mains ou au monde.
- Missions d’expédition, propriétaire du seuil et ordre de la file ; réservations de fibres, quantité encore présente et connaissance du secteur.
- Propriétaires des éclairages, équipement en attente, combustible, état allumé et missions lumineuses.
- Stocks, réservations d’entrée/sortie et files des dépôts ; livraisons locales, travaux et matériaux en transit, liens vers leur chantier ou leur tas de récupération.
- Besoins individuels, repas/repos en cours, attribution et occupation des lits ; passages de porte, échelle et passerelle.
- Horloge de simulation, menace humaine, vitesse, état du rappel et vue. Le chargement reste volontairement en pause.

Le snapshot est pris dans le fil principal entre deux pas de simulation. Les événements de prise et dépose gardent leurs indicateurs : une caisse déjà comptabilisée, dont l’animation se termine encore, ne doit pas être prélevée ou livrée une deuxième fois.

## Format v10 et reconstruction

`colony_save.gd` garde les données durables et la validation des versions précédentes. `live_checkpoint.gd` ajoute un graphe de données de simulation. Il ne sauvegarde pas les objets Godot, les identifiants mémoire ou les scripts. Les références de transport vers les chantiers et tas utilisent des indices de tables reconstruits dans la nouvelle scène.

Les nombres flottants du graphe sont encodés sur leurs 64 bits afin de conserver exactement les minuteries et avancements, y compris les sentinelles de navigation. Les clés entières des registres restent entières après le passage en JSON. L’intégrité du bloc, sa structure et plusieurs invariants sont vérifiés : secteur/mission, propriétaire du seuil, file, équipement, quantité portée, réservation de source et capacité du dépôt.

Le chargement construit une scène candidate. Une erreur de validation ou de reconstruction conserve la partie active. L’écriture vérifie un fichier temporaire puis remplace la sauvegarde, avec copie de secours du fichier précédent. Le test d’intégrité détecte une altération ; ce n’est pas une signature de sécurité.

Les sauvegardes **v1 à v9** conservent leur migration historique vers une colonie abritée et en pause. Elles n’inventent pas une expédition qui n’était pas enregistrée. Les nouvelles sauvegardes utilisent v10.

## Démo à essayer

Lancer avec `-- --demo-live-save`. La démo prépare la boucle du lot 20 puis s’arrête **pendant le retour de H1 dans la fissure, avec trois fibres dans sa caisse**.

1. **F5** : enregistrer cette traversée, sans déplacement de H1.
2. **Espace** : laisser avancer le porteur quelques secondes.
3. **F9**, puis confirmer : retrouver H1 dans la fissure avec la même caisse et le combustible sauvegardé.
4. **Espace** : finir la livraison ; le lit reçoit ses fibres et se termine.

Fichier séparé de la partie normale : `user://saves/live_expedition_demo.json`. La préparation scénarisée appartient à cette démonstration ; la sauvegarde fonctionne aussi dans une partie ordinaire.

## Vérifications

- `tests/live_checkpoint.gd` : fichiers JSON réellement écrits puis relus ; avant départ, attente, deux directions de traversée, prélèvement avant/après prise, retour chargé, dépose, approvisionnement du lit et deux expéditions en file. Comparaison des positions, secteurs, charges, réservations et horloge ; reprise jusqu’au lit terminé avec conservation des fibres.
- Reprise d’un repas et du sommeil sur la même chronologie sans deuxième ration ; fabrication de lanterne interrompue puis terminée une seule fois.
- F5 répété et en pause ; absence de rappel, d’avance du temps et de téléportation ; corruption refusée avant remplacement ; seuil incohérent refusé même avec une empreinte recalculée ; migration v9.
- `tests/checkpoint.gd` adapté : sauvegarde pendant une traversée chargée de passerelle avec d’autres tâches locales, reprise des affectations, protection du fichier précédent, secours et scène candidate invalide.
- Non-régression : récolte distante, alcôve, fissure, élargissement, lanternes, torches, chantiers, dépôts, faim/soif et sommeil.
- `tests/live_checkpoint_visual.gd` : capture avant, rechargement au même endroit avec la caisse et livraison après reprise. Images inspectées dans `artifacts/live_checkpoint/` (non versionné).

Aucun nouvel asset 3D. Ce lot sécurise la persistance ; il n’ajoute pas encore le système général de tâches autonomes.

## Prochaine livraison

Prochaine livraison : **désignations sur la carte et attribution autonome des tâches**, avant les nouveaux secteurs et la faune. La progression doit rapprocher le jeu de la gestion indirecte confirmée par le joueur, avec priorités et besoins des habitants.
