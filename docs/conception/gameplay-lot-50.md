# Lot 50 — Lire les récoltes sur la carte

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Étiquettes contextuelles

Les cinq gisements au sol du refuge portent une étiquette sur deux lignes : ressource et quantité restante, puis état de la récolte automatique. Les états distinguent l’absence d’ordre, la désignation, l’objectif à zéro, la réserve couverte, le rappel, la sauvegarde en cours, l’arrêt de la colonie et l’épuisement.

Le nombre de porteurs engagés est ajouté tant que leur tâche existe, même après suspension de l’ordre ou couverture du quota. Ce nombre inclut les affectations manuelles : il décrit les tâches du gisement et ne promet pas de nouveau départ automatique. Les diagnostics détaillés restent dans les panneaux de réserve.

Cliquer sur le texte ouvre **Gisement du refuge**, comme le clic sur la ressource. La zone de sélection suit la projection de la caméra, le zoom et les deux lignes du texte. Une étiquette cachée ou un gisement inconnu n’est pas sélectionnable par ce raccourci. En cas de chevauchement, l’étiquette dont le centre est le plus proche du clic est choisie. Les modes construction et destination d’éclaireur conservent la priorité.

Les gisements en hauteur gardent leurs étiquettes existantes. Aucun nouvel asset, règle de travail ou champ de sauvegarde n’est ajouté : **format v27 inchangé**.

## Démo

Lancer `-- --demo-harvest-markers`. Le bois vise le stock déjà disponible, les fibres attendent une récolte et l’eau a un objectif à zéro. Les miettes restent sans ordre. Cliquer sur les étiquettes pour ouvrir les commandes ; Espace reprend et fait apparaître les porteurs. H rappelle sans supprimer les désignations. F5/F9 permet de vérifier la restitution de l’état.

Sauvegarde distincte : `user://saves/harvest_markers_demo.json`.

## Vérifications

- `tests/harvest_markers.gd` : états affichés, clics sur cinq étiquettes à trois angles et trois zooms, lecture sans mutation, sources masquées/inconnues, rappel, réservation réelle, suspension avec porteur engagé, reconstruction après sauvegarde, épuisement et priorité de la construction.
- `tests/harvest_markers_visual.gd` : carte initiale, porteur engagé et gisement sélectionné ; captures `artifacts/harvest_targets_markers_*.png` contrôlées.
- Régressions : `tests/harvest_source.gd` et `tests/destination_picking.gd`.
