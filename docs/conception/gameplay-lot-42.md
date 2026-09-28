# Lot 42 — Fabrication automatique des lanternes

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Réglage joueur

**Travaux → Éclairage et éclaireurs → Entretien des lanternes → Fabrication automatique** permet de viser de 0 à 8 lanternes au total. Le premier chapitre propose ce panneau après la construction de l’atelier et le réglage des récoltes.

Toutes les lanternes possédées comptent, même portées, réservées, vides ou en entretien. Les commandes de fabrication en cours comptent aussi. L’automatisme engage une fabrication à la fois, dans un atelier libre, avec les livraisons et priorités ordinaires : **4 bois, 3 fibres et 16 secondes de travail**. Aucun équipement ni matériau n’est créé gratuitement.

La réserve de lanternes pleines reste un réglage distinct : elle entretient les équipements existants pour 2 bois, sans en fabriquer. Une lanterne vide compte toujours dans l’objectif total et ne provoque donc pas son remplacement.

Mettre l’objectif à zéro suspend les futures commandes ; une fabrication engagée se termine. Baisser l’objectif ne supprime aucun équipement. Les commandes manuelles restent possibles au-delà du seuil. Le rappel, la sauvegarde et la fin de partie empêchent de nouvelles commandes automatiques. Le panneau indique le nombre possédé, les commandes engagées et l’attente d’un atelier.

## Sauvegarde et essai

Le format **v24** conserve l’objectif de fabrication. Les anciennes sauvegardes restent lisibles et démarrent avec cet automatisme désactivé ; leur réglage d’entretien est conservé.

`-- --demo-lantern-production` prépare un atelier, 10 bois, 6 fibres et un objectif de deux lanternes. Espace reprend la simulation. Après les deux fabrications, il reste 2 bois et aucune fibre. La démo utilise sa propre sauvegarde utilisateur.

## Vérifications

- `tests/lantern_production.gd` : coûts exacts, commandes manuelles comptées, fabrication séquentielle, arrêt et reprise, lanternes vides ou portées, entretien, sauvegarde JSON pendant le travail, migration v23 et validation du réglage.
- `tests/automatic_refills.gd` : régression de l’entretien automatique et de son annulation.
- `tests/chapter_logistics.gd` : raccourci de fabrication, respect des réglages personnalisés et conseils sans modification automatique des objectifs.
- `tests/lantern_production_visual.gd` : panneaux de production et d’entretien ; captures `artifacts/harvest_targets_lantern_production_*.png` contrôlées.
- `tests/chapter_campaign.gd -- --auto-equipment` : dix étapes depuis une nouvelle partie, récoltes autonomes, fabrication et entretien automatiques de deux lanternes, sans commande manuelle d’équipement. Rechargement JSON pendant une expédition chargée, avec vérification du réglage avant la reprise du joueur scripté.

Le parcours complet atteint les provisions livrées à **699,7 secondes simulées**, avec **deux lanternes**, **un rappel** et un maximum de **54,04 soupçons**. Besoins et passages humains restent actifs. Cette durée est celle d’un joueur scripté qui connaît les commandes ; l’évaluation humaine de l’équilibrage reste ouverte.
