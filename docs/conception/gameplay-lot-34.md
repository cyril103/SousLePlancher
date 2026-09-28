# Lot 34 — Transferts avec réserves et objectifs de stock

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur. Ce lot prolonge la gestion des stocks prévue au cahier des charges, après la recette du premier chapitre.

## Résultat visible

Dans **Stocks → Transferts réguliers entre dépôts**, chaque liaison possède deux réglages par ressource :

- **Garder** : quantité disponible à conserver dans le dépôt source, de 0 à 9999.
- **Viser** : stock souhaité dans le dépôt destination, de 0 à 9999 ; **−1** signifie sans limite.

Les porteurs prennent seulement la quantité nécessaire. Les réservations de tous les systèmes comptent dans le stock attendu à destination, y compris les autres liaisons et les retours de charges. Deux porteurs ne réservent pas chacun la même quantité manquante. Le texte indique si le seuil est couvert ou si la réserve source empêche le départ. Après consommation à destination ou réapprovisionnement de la source, la liaison reprend automatiquement.

Les seuils gouvernent les nouveaux départs. Une modification conserve les transports déjà engagés, qui peuvent donc terminer au-dessus d’un objectif abaissé. **Pause** termine les transports engagés ; **Arrêter et rappeler** ramène leurs charges. Filtres, capacité, construction des dépôts, éclairage et priorités restent applicables.

## Démo

Lancer avec `-- --demo-transfer-limits`, puis Espace. La réserve à l’étage contient 12 bois et le refuge 12. Garder 5 / Viser 17 envoie exactement 5 bois ; le refuge atteint 17 et l’étage garde 7. Le bandeau supérieur affiche le total des dépôts, donc reste à 24 bois.

Essais : porter Viser à 20 pour voir la réserve source arrêter la livraison à 19 ; mettre Garder à 0 pour autoriser la suite. Abaisser Viser pendant une caisse en route laisse cette caisse terminer. F5/F9 permet de reprendre la liaison en cours. Cette démo utilise un fichier séparé de la partie normale.

## Sauvegarde v19

Les deux seuils sont enregistrés et validés, avec les réservations et charges existantes. Les sauvegardes v18 et antérieures restent lisibles : chaque ancienne liaison reçoit Garder 0 / Viser −1, sans modification des stocks. Une ancienne version du jeu ne peut pas charger les nouvelles sauvegardes v19.

## Vérifications

- `tests/transfer_limits.gd` : commandes UI, deux porteurs et quantité exacte, conservation, JSON avec réservations actives, arrêt au seuil, reprise après consommation, réserve source, modification en charge, rappel, réservations entrantes externes, données invalides et migration v18.
- `tests/transfers.gd` : transports historiques sans limite, filtres, dépôts pleins, pause, rappel chargé, besoins et sauvegarde.
- `tests/chapter_campaign.gd` : parcours complet inchangé, dix étapes et rechargement d’une caisse en v19.
- `tests/transfer_limits_visual.gd` : captures graphiques avant départ et objectif atteint, dans `artifacts/transfer_limits_start.png` et `artifacts/transfer_limits_target.png`.

## Limites

Ce sont des seuils de liaison, pas une interdiction globale de consommation du stock : besoins, chantiers et autres liaisons gardent leurs règles. Viser régule ce transfert sans bloquer les autres sources de livraison. Une réserve plus haute sur une autre liaison ne s’impose pas à toutes. Pas de quota automatique de fabrication ni de recharge des lanternes dans ce lot.
