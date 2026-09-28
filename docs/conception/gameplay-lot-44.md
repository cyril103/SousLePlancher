# Lot 44 — Désigner l’inspection de la fissure

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Commande joueur

Dans **Fissure du plancher → Désigner l’inspection**, enregistrer l’ordre sans choisir d’habitant. Le premier chapitre ouvre directement ce panneau à l’étape d’inspection. Le repère du passage indique que l’inspection est désignée.

Un seul habitant part, selon sa priorité **Construction**. Il doit être disponible, sans affectation de récolte ni équipement déjà engagé, avec une énergie supérieure à 35, ses besoins satisfaits et un chemin vers la fissure. Les tâches en cours se terminent avant une nouvelle attribution. À priorité égale, cette inspection précède les chantiers ordinaires ; les tâches cuisine gardent leur place dans l’arbitrage existant.

L’habitant rejoint physiquement l’entrée, observe cinq secondes puis revient. Aucun matériau ni éclairage n’est nécessaire. La reconnaissance n’ouvre pas le passage : dégagement, étaiement et exploration restent des commandes distinctes. Les commandes manuelles restent accessibles dans le panneau du passage, désormais défilant.

**H** interrompt le déplacement et conserve la désignation pour la reprise. **Annuler l’inspection et rappeler** retire l’ordre et rappelle l’inspecteur ; aucun départ automatique ne suit. Une inspection déjà engagée manuellement peut satisfaire l’ordre ; son annulation depuis ce panneau rappelle aussi cet inspecteur. Une fois la reconnaissance terminée, la désignation s’efface.

Le statut indique l’inspecteur engagé, un rappel, l’absence d’habitant autorisé ou l’attente de disponibilité et d’accès. Il ne modifie aucun réglage de priorité.

## Sauvegarde et essai

Le format **v26** conserve la désignation en attente ou engagée. Les anciennes sauvegardes restent lisibles, avec cette désignation désactivée par défaut ; leurs missions manuelles sont conservées.

Démo `-- --demo-inspection` : colonie initiale, ordre désigné, simulation en pause et sauvegarde utilisateur séparée. Espace lance la prise de tâche. Essayer H puis H, ou annuler avant la fin de l’observation. F5/F9 permet de reprendre une inspection en cours. Le passage reste bloqué après sa reconnaissance, jusqu’à une commande de travaux.

## Vérifications

- `tests/inspection_designation.gd` : priorité Construction désactivée, affectation de récolte, fatigue, rappel, attribution unique, reprise après rappel, annulation depuis l’interface, sauvegarde JSON en attente/en mission/après annulation, lecture v25, validation du champ et absence de coût ou d’ouverture automatique.
- `tests/inspection_designation_visual.gd` : panneau en attente, inspection terminée et commandes manuelles ; captures `artifacts/harvest_targets_inspection_*.png` contrôlées.
- Régressions : `tests/chapter.gd` et `tests/priorities.gd`.
- `tests/chapter_campaign.gd -- --auto-inspection` : variante du parcours ordinaire avec récoltes, équipements et inspection désignés ; l’exploration à la lanterne reste une commande manuelle. Les besoins et passages humains restent actifs.

Ce parcours atteint les dix étapes à **787,15 secondes simulées**, avec deux lanternes, un rappel et un maximum de 54,04 soupçons. La sauvegarde chargée est rechargée avant la livraison finale. Il s’agit d’un joueur scripté qui connaît les commandes, pas d’une mesure de durée pour une première partie humaine.
