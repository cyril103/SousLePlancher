# Lot 48 — Comprendre les attentes des expéditions

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Diagnostics par provenance

**Objectifs de réserve** conserve le diagnostic du refuge et ajoute une ligne pour les fibres de l’alcôve ou les provisions de la cuisine, lorsque ces parcours sont découverts. Une récolte distante peut ainsi être prête alors qu’aucun gisement du refuge n’est désigné.

Les messages expliquent le quota suspendu ou couvert, le rappel, la reconnaissance, le passage à élargir, le pont à terminer, la désignation, l’épuisement, les ressources réservées, les priorités, les besoins des habitants, les filtres et la capacité des dépôts. Ils distinguent une lanterne absente, indisponible et insuffisamment remplie, ainsi que les accès bloqués. Une expédition engagée renvoie vers le suivi des porteurs.

Les boutons ouvrent la commande adaptée et recalculent leur destination au clic. « Conditions préalables réunies » reste soumis à l’arbitrage des priorités. Le diagnostic indique la première condition bloquante ; il ne constitue pas une attribution de mission et ne réserve rien. Les règles de récolte et les quotas restent inchangés.

## Démo et sauvegarde

Lancer `-- --demo-remote-harvest-status`. La cuisine, le pont et les lanternes sont fournis ; les récoltes sont désignées, mais les lanternes presque vides empêchent le départ. Ouvrir l’entretien avec le bouton du diagnostic. Faire défiler les réserves pour comparer les fibres et les miettes. La démonstration utilise `user://saves/remote_harvest_status_demo.json`.

**Format v27 inchangé** : les informations sont calculées à partir de l’état courant, sans nouveau champ sauvegardé.

## Vérifications

- `tests/remote_harvest_status.gd` : sources masquées avant découverte, quotas, rappel, reconnaissance, passage, pont, désignation, priorités, repos, filtres, capacité, équipements absents/réservés/vides, source épuisée/réservée, accès bloqué, raccourcis recalculés, absence de mutation, rechargement JSON et expédition réelle.
- `tests/remote_harvest_status_visual.gd` : diagnostics cuisine et alcôve, défilement et accès à l’entretien ; captures `artifacts/harvest_targets_remote_*.png`.
- Régressions : `tests/harvest_status.gd` et `tests/kitchen_target.gd`.
