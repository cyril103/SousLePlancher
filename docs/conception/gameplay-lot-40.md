# Lot 40 — Diagnostic des objectifs de réserve

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Résultat visible

Dans **Récoltes du refuge → Objectifs de réserve**, chaque ressource garde son réglage et ses quantités, puis affiche un diagnostic de ses conditions de départ. Le panneau devient défilant pour conserver une hauteur utilisable.

Les états distinguent objectif 0, réserve couverte, rappel, sauvegarde en cours, colonie arrêtée, absence de désignation, gisements désignés épuisés, affectations manuelles de toute la population, priorité Récolte à zéro, filtres fermés, dépôts pleins ou places réservées, postes de prélèvement réservés, habitants occupés ou en besoin, accès aux sources et trajet vers un dépôt bloqués. Lorsque les conditions sont réunies, le texte rappelle que l’attribution dépend des priorités et, le cas échéant, de la reprise de la simulation.

Les boutons ouvrent les désignations, priorités, affectations ou dépôts selon le diagnostic. Ils ne changent aucun réglage. L’état est recalculé au clic : un problème résolu depuis le dernier affichage ne déclenche pas une navigation obsolète.

Un diagnostic principal est affiché à la fois. Après sa résolution, une autre contrainte peut apparaître. « Conditions réunies » ne garantit pas le prochain travail : les tâches de rang supérieur, les missions cuisine/alcôve et les soins conservent leur arbitrage. Les diagnostics portent sur les récoltes autonomes au sol, pas sur les missions d’expédition ni sur la totalité des tâches de la colonie.

## Lecture sans effet sur les travaux

Le panneau lit les stocks, réservations, filtres et trajets. Il ne tente jamais un départ pour déterminer sa possibilité. Le contrôle de disponibilité commun aux priorités est exposé en lecture et réutilisé, sans changer l’ordre des tâches. Les besoins de repos et les patients sont exclus des candidats au diagnostic de trajet.

Aucune nouvelle donnée sauvegardée : format **v23 inchangé**, diagnostics reconstruits depuis la situation restaurée. Aucun nouvel asset.

## Essai

`-- --demo-harvest-status` prépare un objectif de 30 miettes sans gisement désigné, du bois et des fibres désignés mais Récolte à zéro, et un objectif eau à zéro.

1. Dans la ligne des miettes, **Désigner** ouvre les sources. Désigner un gisement de miettes.
2. Revenir aux objectifs, ouvrir **Priorités** et autoriser Récolte pour au moins un habitant.
3. Revenir aux objectifs puis Espace : la lecture suit les réservations et l’atteinte des objectifs. H affiche le rappel tant qu’un objectif reste à remplir.
4. Un filtre fermé ou un dépôt plein produit un accès aux commandes de dépôt. F5/F9 conserve la situation, et les diagnostics se reconstruisent en pause.

Fichier de démonstration distinct : `user://saves/harvest_status_demo.json`.

## Vérifications

- `tests/harvest_status.gd` : diagnostics de désignation, priorités, objectif 0/couvert, rappel, sauvegarde, arrêt, épuisement, affectations manuelles, filtres, capacité, repos, réservation réelle, accès source et dépôt ; boutons et action obsolète ; absence de mutation de l’état sauvegardé ; restauration JSON ; récolte réelle avec panneau ouvert jusqu’à l’objectif exact.
- `tests/priorities.gd` : arbitrage existant inchangé après extraction du contrôle de disponibilité.
- `tests/harvest_status_visual.gd` : panneau bloqué puis prêt, rendu Compatibility ; captures `artifacts/harvest_targets_diagnostics*.png`.
