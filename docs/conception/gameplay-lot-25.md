# Lot 25 — Transferts réguliers entre dépôts (7B)

27 septembre 2026 — **Validé par le joueur ; commit et push autorisés.**

## Résultat jouable

Dans **Stocks → Transferts réguliers entre dépôts**, choisir une source, une destination et une ressource, puis créer la liaison. Les habitants disponibles prennent les rotations avec leur priorité **Transport**. Aucun habitant n’est à sélectionner pour chaque trajet. La liaison reste en attente si le stock manque, puis repart lorsque des ressources arrivent.

Les trajets utilisent les accès existants, y compris l’échelle et la passerelle vers la réserve de l’Est. Les modèles, animations de caisses et dépôts Blender existants sont réutilisés.

## Règles

- Ressources : miettes, eau, bois, fibres. Source et destination différentes ; au maximum 32 liaisons, deux porteurs engagés par liaison.
- Un trajet transporte jusqu’à 3 unités, augmenté par les ateliers existants. Les demandes sont réparties entre liaisons éligibles. L’approvisionnement et la récupération des chantiers passent avant ces transferts au sein de la catégorie Transport.
- Les deux dépôts doivent être construits et reliés. Les filtres de destination, les ressources disponibles et les places libres sont contrôlés avant départ. Une réservation déjà accordée reste valable si un filtre change ensuite.
- Réserver les ressources au départ et la place à destination empêche les doubles affectations. Après la prise, réserver aussi la place libérée à la source permet d’y ramener toute charge rappelée.
- Les caisses sont réellement prises, portées et déposées. Les stocks changent à la prise et à la dépose, jamais lors de la création de l’ordre.
- **Pause** suspend les nouveaux départs et laisse finir les trajets engagés. **Reprendre** réactive la liaison.
- **Arrêter et rappeler** suspend la liaison, annule les prises non effectuées et ramène les charges à leur source. Une traversée engagée se termine avant de faire demi-tour.
- Besoins urgents et rappel général passent par la même protection des charges. L’habitant satisfait ensuite son besoin de manière autonome.
- Les doublons et les boucles actives pour une même ressource sont refusés pour éviter les allers-retours sans utilité. La reprise d’une liaison vérifie également ce point.
- Si un accès devient impraticable, les ressources chargées restent réservées et le blocage est indiqué ; elles ne sont ni détruites ni téléportées.

## Sauvegarde

Format **v12** : ordres, compteurs livrés, porteurs, phase, charge, trajet et réservations sont enregistrés avec le checkpoint sur place. Le chargement vérifie notamment l’identité du porteur et la concordance des réservations. Les sauvegardes antérieures se restaurent sans liaisons de transfert. F5 sauvegarde et met en pause, F9 recharge, Espace reprend.

## Démonstration

Lancement : `-- --demo-transfers`. La scène démarre en pause, panneau ouvert. Un dépôt déjà construit à l’étage contient 12 bois ; H1 et H2 ont Transport prioritaire, une liaison vers le refuge est préparée.

1. **Espace** : observer plusieurs rotations sur la passerelle et l’échelle, puis la dépose au refuge.
2. **Pause** sur la liaison : les trajets engagés finissent, aucun nouveau départ.
3. **Reprendre**, puis **Arrêter et rappeler** pendant un trajet chargé : la caisse revient au dépôt source.
4. Tester **F5**, **F9**, puis **Espace** pendant un transport.
5. Après épuisement de la source, la liaison reste active et attend un réapprovisionnement.

La démo utilise `user://saves/transfers_demo.json`, séparé de la partie normale. Elle prépare l’infrastructure pour isoler ce test ; les mêmes ordres fonctionnent dans une partie ordinaire avec des dépôts construits par le joueur.

## Vérifications

Sous Godot 4.7.2 :

- `tests/transfers.gd` : rotations complètes, bilan de bois à chaque pas, doublons/boucles, sauvegarde à l’attente et chargé sur la passerelle, arrêt avec charge, soif urgente, filtre fermé, capacité pleine, réapprovisionnement, pause et reprise.
- Régressions : `priorities`, `depot_build`, `live_checkpoint`, `needs`.
- `tests/transfers_visual.gd` : captures du panneau et d’une traversée chargée, inspection visuelle en rendu Compatibility.

## Limites et suite

Pas de quota minimum/maximum de stock, de programmation horaire, de suppression des liaisons ni de véhicules. Une liaison arrêtée peut être reprise. Le dépôt distant reste celui de la réserve à l’étage ; aucun dépôt générique dans l’alcôve sud. Ses missions lumineuses spécialisées restent distinctes. Le bilan global du bandeau exclut les caisses temporairement en main : leur contenu reste visible dans le suivi des porteurs.

**Prochaine livraison : 7C — éclairage fixe construit et entretenu**, avec recette minimale et règles de ravitaillement à définir avant développement. Ne pas ouvrir en parallèle faune, génération de secteurs ou refonte des assets.
