# Lot 37 — Suivi des chantiers

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Résultat visible

**Travaux → Suivi des chantiers** regroupe les chantiers actifs à livraison physique : lits, fabrication et entretien des lanternes/torches, fissure et élargissement, dépôts, brasero et combustible, étape courante des chambres. Les matériaux récupérables après une annulation apparaissent aussi. Les travaux terminés et les plans inactifs ne sont pas listés ; ils restent accessibles dans leurs panneaux habituels.

Chaque ligne donne les matériaux déjà livrés (les caisses en route ne sont pas comptées comme livrées), l’état du chantier et l’habitant engagé avec son activité. Quand aucun habitant n’autorise le métier nécessaire, une indication explicite renvoie aux priorités. Le bandeau distingue pause, rappel et arrêt de la colonie. **Commandes** ouvre le panneau correspondant, sélectionne le bon dépôt ou la bonne chambre ; **Centrer** place la caméra sur le chantier. La liste défile sans reconstruire ses contrôles à chaque rafraîchissement.

Ce suivi ne classe pas les tâches, ne réserve rien et ne modifie pas leur arbitrage. Les statuts de matériaux et de transport proviennent du système logistique existant. Il ne prétend pas diagnostiquer tous les problèmes de trajet ou de disponibilité individuelle. Les réserves de combustible prêtes ne demandent pas de constructeur.

Le pont cuisine utilise des missions spécifiques : un bouton donne accès à son suivi dédié. Les liaisons de transfert et les récoltes restent dans leurs panneaux ; les ateliers et abris au paiement immédiat ne sont pas des chantiers de cette liste. Aucun nouvel asset.

## Essai reproductible

Lancer `-- --demo-construction-board`. Un lit et un entretien de lanterne attendent, avec les priorités à zéro ; dix bois et trois fibres sont disponibles. La réserve automatique vise deux lanternes pleines.

1. Ouvrir les priorités depuis le suivi et autoriser Transport pour un ou plusieurs habitants. Revenir par Travaux → Suivi des chantiers ; Espace lance la simulation.
2. Après livraison, le chantier indique qu’aucun constructeur n’est autorisé. Autoriser Construction pour terminer le lit et les pleins. Il reste deux bois, aucune fibre.
3. H rappelle les habitants ; H à nouveau autorise la reprise. F5/F9 sauvegarde et recharge sur place, en pause. Rouvrir le suivi : les lignes sont reconstruites depuis les travaux restaurés.
4. Pour éprouver une annulation, ouvrir les commandes d’entretien avant sa fin et annuler. Le bois déjà livré apparaît comme matériau récupérable ; une charge en route retourne au dépôt selon les règles existantes.

Le fichier de démo est `user://saves/construction_board_demo.json`, distinct de la partie normale. La sauvegarde reste en **v21** : aucune migration ni donnée persistante ajoutée.

## Vérifications

- `tests/construction_board.gd` : lecture et rafraîchissement sans mutation de la sauvegarde, priorités Transport puis Construction, quantités physiques, habitant et progression, disparition des lignes terminées, restauration JSON, annulation et récupération exacte, rappel, phase de chambre, sélection du dépôt et combustible prêt sans constructeur.
- `tests/automatic_refills.gd` : réserve, interruptions, annulations et migrations du lot précédent toujours fonctionnelles.
- `tests/construction_board_visual.gd` : captures avec priorités bloquées, travail en cours et liste vide ; affichage vérifié en Compatibility, `artifacts/construction_board_*.png`.
