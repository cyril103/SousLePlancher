# Lot 35 — Entretenir les lanternes

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Résultat jouable

**Travaux → Éclairage et éclaireurs → Ravitailler une lanterne · 2 bois** commande un plein sur la lanterne rangée la moins chargée. Un atelier est requis. L’équipement reste à son point de rangement : le combustible est livré physiquement, puis un artisan y effectue huit secondes de travail. Le plein remet son autonomie à 180 secondes, sans créer une autre lanterne ni consommer de fibres.

Une lanterne portée, réservée par un porteur, allumée ou déjà pleine ne peut pas être entretenue. Un seul ravitaillement est commandé à la fois. Pendant cet ordre, la lanterne reste indisponible pour les sorties manuelles et autonomes. Les priorités Transport et Construction gouvernent les livraisons et le travail. Manque de bois : l’ordre attend. Rappel ou besoin urgent : l’habitant interrompt, le travail et les matériaux restent disponibles pour la reprise. La pause fige la progression.

Le plein coûte toujours 2 bois, même sur une lanterne partiellement chargée ; le combustible final est plafonné à 180 secondes. Le bouton sélectionne automatiquement la lanterne admissible la moins chargée. Les torches à main restent consommables. Il n’y a pas encore de ravitaillement automatique permanent ni d’annulation propre de l’ordre d’entretien ; le rappel suspend son exécution.

## Correction associée

Les ordres manuels de récolte avec lanterne restaient en attente : l’arbitrage autonome excluait les habitants équipés, et leur mission ne lançait plus la réservation de caisse. La mission lumineuse lance maintenant son unique récolte avant de laisser la livraison ordinaire gérer la charge. Une priorité Récolte désactivée provoque le rangement de la lanterne sans prélèvement. Les trajets vers la réserve à l’étage et leurs rappels sont de nouveau couverts par les tests existants.

## Essai

`-- --demo-lantern-refill` prépare un atelier, une lanterne épuisée au refuge, deux bois et un ordre d’entretien, en pause. Espace lance la livraison et le travail. H interrompt ; H à nouveau reprend. F5/F9 pendant livraison ou entretien conserve la situation. Une fois prête, équiper la lanterne et choisir une sortie. Le fichier de sauvegarde de cette démo est séparé de la partie normale.

## Sauvegarde v20

L’ordre mémorise l’identité de la lanterne, son emplacement, ses matériaux et son travail. La validation croise cet ordre avec l’inventaire et l’artisan ; les cibles invalides et les doubles usages sont rejetés. La lanterne n’est pas déplacée au chargement et le plein n’est appliqué qu’à la fin du travail. Les anciennes sauvegardes restent chargeables sans ajouter d’ordre d’entretien. Les versions précédentes du jeu ne lisent pas les nouveaux fichiers v20.

## Vérifications

- `tests/lantern_refill.gd` : vrai approvisionnement, coût exact, aucune duplication, équipement protégé, pause, rappel, JSON pendant livraison/travail/après plein, réutilisation, refus porté/plein, attente faute de bois, validation et migration v19.
- `tests/lanterns.gd` : fabrication historique, échelle, passerelle, récolte à la lanterne, charge rappelée et priorité Récolte désactivée.
- `tests/chapter_campaign.gd -- --reuse-lanterns` : nouvelle partie normale, entretien en priorité lorsqu’une lanterne est récupérable, dix objectifs et reprise d’une caisse sauvegardée. Résultat observé : **840,45 secondes simulées**, cinq lanternes fabriquées, quinze fibres encore en dépôt. Ce parcours scripté ne mesure pas la durée d’une première découverte humaine.
- `tests/lantern_refill_visual.gd` : captures de la commande, du travail et de la lanterne prête dans `artifacts/lantern_refill_*.png`.

Les animations et modèles existants sont réutilisés. L’artisan utilise l’animation de travail générique ; pas encore de geste spécifique de remplissage.
