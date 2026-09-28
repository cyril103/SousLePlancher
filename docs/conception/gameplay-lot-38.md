# Lot 38 — Récoltes autonomes du refuge

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Commandes et comportement

**Travaux → Récoltes du refuge**, ou **Habitants → Récoltes autonomes du refuge**, ouvre la liste des cinq gisements au sol : deux sources de miettes, le bois, les fibres et l’eau. **Désigner** autorise la récolte, **Suspendre** empêche les prochains départs ; les travaux et caisses déjà engagés se terminent. **Centrer** montre le gisement. Les étiquettes sur la carte portent la mention « Récolte désignée ».

Les habitants sans affectation manuelle prennent ces travaux à leur priorité Récolte. La valeur 0 les interdit. Besoins, soins et rappel gardent leurs règles prioritaires ; une affectation manuelle reste indépendante et garde son gisement. À priorité égale, les missions cuisine et alcôve existantes sont examinées avant les nouvelles récoltes locales. Parmi les gisements locaux, le numéro le plus bas est examiné en premier ; un poste réservé ou une destination indisponible permet de chercher le suivant.

Les transports utilisent les réservations physiques existantes : un poste de prélèvement par gisement, capacité réservée au dépôt, prélèvement, caisse portée, dépose. Plusieurs habitants peuvent transporter depuis une même source dès que le poste est libéré. Un dépôt plein bloque les départs et l’ordre reprend quand une place se libère. Aucun quota de stock n’est ajouté : une désignation dure jusqu’à suspension ou épuisement, sous réserve de place. La désignation reste affichée après épuisement, avec l’état terminé.

Le panneau montre les quantités restantes, charges engagées (y compris manuelles), rappel et absence d’habitant sans affectation autorisé. Les autres attentes sont regroupées : disponibilité, accès et place au dépôt. Les gisements à l’étage, la réserve de l’Est, l’alcôve et la cuisine conservent leurs commandes et contraintes actuelles. Le menu Travaux est désormais défilant : son titre et ses premières commandes restent visibles quand la liste s’allonge. Aucun nouveau modèle ni ressource.

## Sauvegarde v22

Chaque gisement conserve son indicateur de désignation, dans les données de carte et l’état de simulation. Leur cohérence est contrôlée ; un ordre sur une source à l’étage est refusé. Les caisses et réservations restent celles du système existant.

Les anciennes sauvegardes se chargent avec ces désignations désactivées ; les affectations manuelles sont conservées. Les versions précédentes du jeu ne peuvent pas lire les sauvegardes v22. Rechargement en pause, sans rappeler ni supprimer les charges.

## Démonstration

`-- --demo-local-harvest` prépare le bois et les fibres désignés, quatre habitants sans affectation et Récolte en priorité 1. Espace lance les rotations. Suspendre une source pendant un portage laisse terminer les charges ; désigner à nouveau reprend. H rappelle puis autorise la reprise. Mettre Récolte à 0 arrête les prochains travaux de l’habitant. F5/F9 conserve les ordres et les charges sur place.

Le fichier `user://saves/local_harvest_demo.json` est distinct de la partie normale. La réserve finit par se remplir : construire ou consommer libère de la place et relance les récoltes.

## Vérifications

- `tests/local_harvest.gd` : boutons de désignation, ressources conservées, absence d’affectation permanente, récoltes des cinq sources au sol, refus de l’étage, sauvegarde JSON en charge et achèvement après reprise, priorités à zéro, soif prioritaire, suspension en charge, rappel/reprise, affectation manuelle prioritaire, dépôt plein puis libéré, champs invalides et migration v21.
- `tests/priorities.gd` : arbitrage et interruptions antérieurs toujours fonctionnels.
- `tests/automatic_refills.gd` : réserve de lanternes et sauvegardes antérieures sans régression.
- `tests/chapter_campaign.gd -- --auto-refills` : chapitre ordinaire toujours achevé, dix étapes et rechargement en charge ; 522,1 secondes simulées, deux lanternes. Ce scénario garde ses affectations manuelles et ne mesure pas une partie humaine.
- `tests/local_harvest_visual.gd` : panneau, accès Habitants et Travaux en rendu Compatibility ; captures `artifacts/local_harvest_*.png`.
