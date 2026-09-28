# Lot 51 — Suivre le pont cuisine avec les autres chantiers

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Un tableau commun

Le **Suivi des chantiers** affiche désormais une carte **Pont de la cuisine** dès sa commande. Elle présente les matériaux physiquement livrés, le pourcentage de construction et les habitants chargés de son approvisionnement ou de sa fabrication.

Les matériaux réservés pour le pont sont indiqués séparément des matériaux livrés. Les charges qui reviennent au dépôt après suspension ne sont plus présentées comme de futurs apports au pont. Les porteurs et le constructeur restent visibles tant que leur mission de chantier existe. Les commandes **Commandes** et **Centrer** ouvrent le panneau cuisine et positionnent la caméra sur le pont.

Le pont suspendu reste dans le tableau, même après le retour des habitants, afin de retrouver la commande de reprise. Lorsque les matériaux sont prêts mais qu’aucun habitant n’a Construction autorisée, le tableau l’explique ; il signale de même Transport à zéro pendant l’approvisionnement. Les autres attentes renvoient aux conditions de disponibilité, d’éclairage et d’accès, sans lancer de mission.

Le pont terminé reste affiché pour les derniers retours de ses missions de chantier, puis disparaît. La reconnaissance et les missions de provisions ne constituent pas des chantiers et gardent leur suivi cuisine.

## Démo et sauvegarde

Lancer `-- --demo-kitchen-board`. La cuisine est reconnue, le passage élargi et les lanternes fournis ; le pont est commandé, avec Transport et Construction à zéro. Autoriser ces deux priorités, puis reprendre avec Espace. Ouvrir **Commandes** pour suspendre pendant une livraison, observer le retour de la caisse dans le tableau, puis reprendre le chantier.

F5/F9 permet de reprendre pendant le retour chargé. Sauvegarde distincte : `user://saves/kitchen_board_demo.json`.

**Format v27 inchangé** : le tableau lit les missions existantes. Les coûts, les réservations, la suspension et les règles de construction restent inchangés.

## Vérifications

- `tests/kitchen_board.gd` : présence unique du pont commandé, quantités livrées/réservées/en retour, lien vers les commandes, absence de mutation, porteur réel, suspension chargée, restauration exacte du suivi, conservation des matériaux, reprise, priorité Construction, progression, derniers retours et retrait de la carte.
- `tests/kitchen_board_visual.gd` : chantier en attente, retour après suspension et panneau des commandes ; captures `artifacts/construction_board_kitchen_*.png` contrôlées.
- Régression : `tests/construction_board.gd`, chantiers ordinaires, entretien, récupération et liens vers les commandes.
