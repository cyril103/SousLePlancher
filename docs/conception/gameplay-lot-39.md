# Lot 39 — Objectifs de réserve pour les récoltes autonomes

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Réglages

**Travaux → Récoltes du refuge → Objectifs de réserve** propose un objectif commun par ressource : miettes, bois, fibres, eau. Le panneau affiche le stock actuel, le total prévu avec les charges engagées, puis l’état de l’objectif.

- **−1** : sans limite, comportement du lot 38.
- **0** : aucun nouveau départ autonome pour cette ressource.
- **1 à 9999** : stock visé dans l’ensemble des dépôts.

Le réglage ne désigne pas de gisement à lui seul. Les désignations restent nécessaires et la priorité Récolte continue de s’appliquer. Les deux gisements de miettes partagent le même objectif. À chaque départ, la quantité réservée est limitée au manque restant : une dernière caisse peut donc ne contenir qu’une ou deux unités.

L’ordre attend quand le stock et les charges engagées couvrent l’objectif ; il reprend après consommation. Abaisser un objectif laisse finir les travaux déjà engagés, même si leur dépose dépasse le nouveau seuil. Les récoltes manuelles, les collectes urgentes liées aux besoins et les expéditions restent indépendantes : elles peuvent dépasser l’objectif local. Aucun dépôt n’est agrandi et aucune ressource n’est supprimée pour respecter le seuil.

## Comptage

Le stock de tous les dépôts compte, même lorsqu’un dépôt est temporairement inaccessible. S’y ajoutent les réservations d’entrée existantes : récoltes au sol, charges d’expédition, récupération et retours de matériaux. Les matériaux d’un chantier conservant une place de retour sont comptés jusqu’à leur dépose au chantier : le besoin de remplacement apparaît alors. Le stock réservé mais encore au dépôt n’est pas soustrait.

Les transferts internes font exception au cumul des réservations : avant prise, les ressources sont déjà dans le stock source ; pendant le trajet, la caisse compte une fois, malgré les deux places réservées à destination et pour un éventuel retour. Après dépose, seul le stock compte. Cela évite qu’un transfert gonfle artificiellement la réserve prévue.

## Sauvegarde v23

Les quatre objectifs sont sauvegardés et validés comme entiers entre −1 et 9999. Ils sont restaurés avec les désignations et les charges actives. Les anciennes sauvegardes conservent leurs désignations et reçoivent des objectifs sans limite ; aucune restriction nouvelle n’est imposée au chargement. Les versions antérieures du jeu ne lisent pas les fichiers v23.

## Essai

`-- --demo-harvest-targets` prépare les désignations bois et fibres du lot 38, avec 12 bois et 6 fibres en stock, puis des objectifs de 17 bois et 10 fibres. Espace permet de rapporter exactement cinq bois et quatre fibres. Construire un lit consomme ensuite quatre bois et trois fibres et relance les récoltes. Réduire un objectif pendant une prise, rappeler avec H ou sauvegarder/recharger avec F5/F9 permet d’éprouver les transitions.

Fichier distinct : `user://saves/harvest_targets_demo.json`. Aucun nouvel asset ni nouveau gisement.

## Vérifications

- `tests/harvest_targets.gd` : modification UI, derniers chargements partiels, départs concurrents bornés, sauvegarde JSON en charge, reprise après consommation directe et construction physique, objectif partagé entre deux sources, baisse en cours de transport, récolte manuelle indépendante, transferts internes sans double compte, valeurs invalides et migration v22.
- `tests/local_harvest.gd` : cinq sources, suspension, rappel, besoins, priorité, dépôt plein et sauvegardes du lot 38 toujours fonctionnels avec les objectifs sans limite.
- `tests/harvest_targets_visual.gd` : panneau des objectifs avant/après et retour aux désignations, rendu Compatibility, captures `artifacts/harvest_targets_*.png`.
