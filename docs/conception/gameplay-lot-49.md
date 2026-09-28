# Lot 49 — Désigner les récoltes depuis la carte

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Commande contextuelle

Cliquer sur l’un des cinq gisements au sol du refuge ouvre **Gisement du refuge**. Le panneau indique la ressource, le numéro du gisement, la quantité restante, les réservations, les affectations manuelles et l’état de la récolte. **Désigner la récolte** confie le travail aux habitants sans affectation, selon leurs priorités. **Suspendre la récolte** empêche les nouveaux départs automatiques ; les charges engagées terminent leur livraison.

Des boutons ouvrent les objectifs et diagnostics de réserve, les priorités, les affectations manuelles et la liste de tous les gisements. Cette liste possède également un bouton **Détails** pour retrouver le panneau contextuel sans viser la carte.

La sélection seule ne donne aucun ordre. Les gisements épuisés ne peuvent pas recevoir de nouvelle désignation. Les gisements en hauteur conservent leurs commandes manuelles ; les ressources inconnues ne sont pas dévoilées. Les modes construction et destination d’un éclaireur conservent la priorité sur le clic de sélection.

Les affectations manuelles et les récoltes urgentes restent indépendantes des désignations. Les objectifs de réserve, les besoins et les règles de livraison conservent leur comportement.

## Démo et sauvegarde

Lancer `-- --demo-harvest-source` : bois sélectionné, aucune récolte désignée, objectif de 17 bois depuis un stock de 12. Désigner, reprendre avec Espace, puis suspendre pendant le portage. Sauvegarder avec F5, recharger avec F9 et constater la livraison de la caisse engagée. Désigner à nouveau pour terminer le quota. Cliquer sur les autres gisements pour consulter leur panneau.

Sauvegarde distincte : `user://saves/harvest_source_demo.json`. **Format v27 inchangé** : aucune nouvelle donnée persistante. Les désignations et missions existantes sont utilisées.

## Vérifications

- `tests/harvest_source.gd` : clics sur les cinq sources, désignation/suspension, sélection sans mutation, source en hauteur et inconnue, épuisement, portage réel, sauvegarde chargée après suspension, livraison sans nouveau prélèvement et reprise au quota exact.
- `tests/harvest_source_visual.gd` : panneau initial, suspension pendant portage et liste avec boutons Détails ; captures `artifacts/harvest_targets_source_*.png` contrôlées.
- Régressions : `tests/destination_picking.gd` et `tests/harvest_status.gd`.
