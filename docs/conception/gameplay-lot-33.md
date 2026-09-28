# Lot 33 — Recette du chapitre depuis une nouvelle partie

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Correction visible

Un rappel pendant la sortie du refuge pour une inspection ou une prise de lanterne pouvait supprimer les points restants du franchissement. L’habitant restait dans le bâtiment avec un état extérieur, puis ne trouvait plus le chemin du refuge ni ses besoins.

Le trajet de porte dispose maintenant de sa propre copie, indépendante du trajet de travail annulé. Le franchissement engagé se termine avant le retour ; ni déplacement instantané ni libération prématurée du passage. Le format de sauvegarde v18 reste inchangé.

## Parcours complet éprouvé

`tests/chapter_campaign.gd` commence sur la scène normale, sans préparation de démo, stocks ajoutés, besoins remontés, capacité de dépôt augmentée ou soupçons remis à zéro. Son joueur scripté utilise les commandes existantes : affectations bois/fibres, lit, atelier, commandes de lanternes, inspection, passage, alcôve, élargissement, cuisine, pont et récolte. Il rappelle la colonie pendant les passages humains lorsque les soupçons dépassent 50, puis reprend les sorties après leur passage.

Les dix objectifs sont atteints après **850,8 secondes de simulation (14 min 11 s à vitesse ×1)**. Trois rappels ; soupçons maximaux 67,43. Une véritable sauvegarde JSON est chargée pendant le transport des provisions, puis cette partie restaurée termine la livraison. Les besoins, réservations et stocks continuent normalement. Ce résultat mesure une stratégie automatisée précise, pas la durée d’une première découverte par un joueur.

Les matériaux de départ et les gisements locaux suffisent à ce parcours, mais la fabrication répétée de lanternes consomme une part importante du bois et des fibres. Aucune augmentation de ressources ni modification des recettes dans ce lot ; l’équilibrage et l’ergonomie restent à apprécier en jeu.

## Vérifications

- `tests/door_task_recall.gd` : inspection et prise de lanterne depuis le refuge, rappel en plein franchissement, conservation du trajet et de la position, sauvegarde/rechargement à cet instant, retour à la place intérieure et libération des missions.
- `tests/chapter_campaign.gd` : parcours des dix objectifs sans démo, survie aux cycles humains, sauvegarde chargée puis livraison effective.
- `tests/doors.gd` : file, six habitants, rappels inversés, pause, charges et reprise des affectations.
- Régressions : `tests/live_checkpoint.gd` et `tests/smoke.gd`.

## Essai joueur

En partie normale, utiliser Objectifs [O] pour suivre le chapitre. Pour reproduire le cas corrigé : rappeler les habitants au refuge, reprendre les sorties, commander immédiatement une inspection ou l’équipement d’une lanterne, puis rappeler pendant le passage de porte. L’habitant termine son franchissement et revient à l’intérieur ; F5/F9 pendant ce retour reste possible.

La recette technique de 11C est maintenant couverte depuis zéro. Publication de cette livraison autorisée par le joueur ; l’appréciation de l’équilibrage reste distincte de cette réussite automatisée.
