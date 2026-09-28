# Lot 46 — Réguler les fibres de l’alcôve

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Objectif partagé

La récolte désignée de l’alcôve respecte désormais l’objectif **Fibres** des réserves, déjà utilisé par les gisements du refuge. Le panneau **Ordre · Fibres de l’alcôve → Objectif commun de fibres** ouvre ce réglage. Il affiche le seuil, les stocks et charges engagées, ainsi que l’attente lorsque l’objectif est couvert.

Le calcul compte les fibres de tous les dépôts et les caisses réservées, avant même le prélèvement. Deux porteurs ne peuvent donc pas réserver chacun le même manque. La dernière caisse peut être partielle. Les récoltes locales et distantes partagent ce calcul ; les transferts internes restent comptés une seule fois selon les règles existantes.

Une fois le seuil couvert, aucun nouveau trajet de récolte n’est lancé. Un habitant qui préparait sa lanterne la range sans partir inutilement. L’ordre reste désigné et reprend après consommation de fibres, si la source, l’accès, les lanternes et les habitants le permettent. Le gisement reste fini.

**0** suspend les nouveaux départs. **−1** garde la récolte sans limite jusqu’à épuisement. Une baisse du seuil laisse les caisses déjà engagées être livrées, même si elles dépassent le nouveau seuil. Le bouton d’annulation garde son comportement de rappel. Les voyages commandés manuellement ne sont pas plafonnés par cet objectif.

## Sauvegarde et essai

**Format v27 inchangé** : objectifs, désignations et quantités réservées sont déjà sauvegardés. Les sauvegardes avec un objectif de fibres réglé appliquent maintenant ce même seuil à l’alcôve ; −1 conserve le comportement sans limite.

Démo `-- --demo-alcove-target` : passage élargi, lanternes préparées, lit en attente de fibres et objectif de cinq fibres au dépôt. Espace lance la récolte ; les livraisons au lit relancent l’approvisionnement jusqu’à constituer la réserve. Essayer ensuite 0 ou une baisse pendant le transport, puis F5/F9 pour reprendre sur place. La démo utilise une sauvegarde utilisateur distincte.

## Vérifications

- `tests/alcove_target.gd` : deux caisses de trois et deux fibres, conservation physique, sauvegarde pendant portage, cinq fibres livrées exactement, reprise après consommation réelle de trois fibres par un lit, baisse à zéro avec caisses engagées, récoltes locales et distantes simultanées.
- `tests/designations.gd` : comportement sans limite, épuisement, rappel, besoins, annulation et réservations d’équipement.
- `tests/harvest_targets.gd` : régression des objectifs locaux, caisses partielles, transferts internes et reprise sauvegardée.
- `tests/alcove_target_visual.gd` : panneau au départ, avec porteurs engagés et à l’objectif couvert ; captures `artifacts/harvest_targets_alcove_target_*.png` contrôlées. Le résumé défile pour garder les commandes accessibles.
