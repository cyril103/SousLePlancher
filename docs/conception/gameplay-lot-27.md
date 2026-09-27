# Lot 27 — Chambre construite (8A)

27 septembre 2026 — **Validé par le joueur ; commit et push autorisés.**

## Résultat jouable

**Construire → Construire une chambre → Tracer une chambre sur la grille** place un plan compact au sol. La chambre possède un plancher, des cloisons physiques et une porte coulissante. Chaque étape attend ses matériaux, réellement portés depuis un dépôt, puis un artisan disponible. Le lit se commande séparément une fois l’enveloppe terminée.

Le plan a une taille et une orientation fixes : largeur 3,4 unités, profondeur 3,9, porte vers +Z. Il se déplace sur la grille d’une unité. Ce premier lot n’est pas un éditeur libre de murs ou de pièces rectangulaires redimensionnables. Au maximum huit plans, dans les emplacements compatibles avec la carte et les accès.

## Coûts et travaux

| Étape | Bois | Fibres | Fabrication |
| --- | ---: | ---: | ---: |
| Plancher | 4 | 2 | 10 s |
| Cloisons | 6 | 4 | 18 s |
| Porte coulissante | 2 | 1 | 8 s |
| Lit séparé | 4 | 3 | 12 s |
| Total avec lit | 16 | 10 | 48 s, hors livraisons |

Les étapes s’ouvrent successivement. Aucun prélèvement à distance lors du tracé. Les priorités Transport et Construction, la faim, la soif, le sommeil, les rappels et les réservations existantes restent utilisés.

Avant achèvement complet, **Annuler le chantier** démonte les étapes de l’enveloppe et laisse leurs matériaux à récupérer ; les charges en transit reviennent au dépôt. Le plan reste visible et peut reprendre. La chambre terminée n’est pas démolissable dans ce lot. Les coûts de chaque étape sont conservés séparément, sans duplication à la reprise.

## Navigation et porte

- Le placement refuse les emprises occupées et les plans qui couperaient les accès nécessaires. Il vérifie également l’accès intérieur prévu pour le lit.
- Les cloisons deviennent des obstacles lors de leur fabrication. Une nouvelle vérification empêche de les matérialiser sur un habitant ou en coupant un trajet indispensable ; l’artisan attend si nécessaire.
- Les futurs bâtiments respectent l’emprise de la chambre et ses accès. Le lit simple dispose de son emplacement intérieur réservé ; sa fabrication reste soumise à un chemin réellement accessible.
- **Porte auto** : ouverture coulissante à l’approche, fermeture lorsque le passage se dégage. Les artisans inactifs quittent l’embrasure après leur travail.
- **Ouverte** : maintient la porte ouverte.
- **Condamner** : ajoute un obstacle réel au seuil. Autorisé pour une chambre vide ; refusé si cela isole un habitant, un lit ou un chantier. La réservation d’un lit protège aussi sa sortie pendant les animations de sommeil.
- Réouvrir restaure la navigation. Aucun habitant n’est téléporté à travers les cloisons ou la porte ; les raccords d’entrée/sortie du lit restent ceux du système de couchage existant.

## Assets Blender

Nouveaux modèles : `rooms_27/floor`, `rooms_27/walls`, `rooms_27/door`. Planches récupérées, carton renforcé, montants et rail de porte ; pas de toit pour garder l’intérieur visible. Textures approuvées de `reference_02` réutilisées. Les fichiers `.blend`, exports `.glb` et le script reproductible `tools/create_room_assets.py` sont conservés. Le lit et les animations existants sont réutilisés.

## Sauvegarde

Format **v14** : emplacement, trois étapes, matériaux, tâches, état et ouverture de la porte. Les obstacles sont reconstruits à partir des éléments bâtis et les tâches reliées à leurs chantiers. Les checkpoints v13 se chargent sans chambre supplémentaire. F5 sauvegarde sur place, F9 recharge en pause, Espace reprend.

## Démonstration

Lancer `-- --demo-room`. Le plan est tracé devant le fond du secteur, avec les matériaux nécessaires au refuge. H1 construit, les autres peuvent transporter puis construire ; aucune étape n’est préfabriquée.

1. **Espace**, éventuellement **×3** : observer les livraisons et les trois fabrications.
2. **Voir la chambre** pour cadrer le résultat.
3. Avant de commander le lit, tester **Condamner**, puis **Porte auto** : la chambre vide peut être fermée, son intérieur devient inaccessible.
4. **Fabriquer le lit à l’intérieur** : attendre son approvisionnement et sa fabrication.
5. **Propriétaires des lits et repos**, ou la fiche de H1 → **Se reposer** : vérifier le trajet par la porte, le sommeil et la sortie. Les habitants fatigués choisissent aussi le lit automatiquement.
6. **Condamner** est désormais refusé pour préserver l’accès au lit.
7. Tester F5/F9 pendant une livraison, les travaux ou le sommeil.

Sauvegarde séparée : `user://saves/room_demo.json`.

## Vérifications

Sous Godot 4.7.2 :

- `tests/rooms.gd` : plan valide/invalide, matériaux conservés à chaque pas, trois étapes construites, sauvegardes et reprise réelle des travaux, porte condamnée physiquement bloquante, lit inaccessible refusé, porte automatique, fabrication du lit, sommeil/sortie, fermeture dangereuse refusée, annulation/récupération/reprise, migration v13.
- Régressions : `construction`, `navigation`, `live_checkpoint`, `fixed_lighting`.
- `tests/rooms_visual.gd` : captures plan/enveloppe/sommeil ; contrôle des modèles et de l’interface. Corrections du panneau et du dégagement de l’embrasure après inspection.

## Limites et suite

La chambre n’accorde pas encore de nouveau bonus d’intimité : son lit reste un lit simple. La propriété existante porte sur le lit. Il n’y a pas de protection supplémentaire contre les humains, de toit simulé, d’étage construit, de murs librement dessinés ni de démolition après achèvement.

**Prochaine livraison : 8B — détection des pièces, propriété et intimité selon l’occupation.** Les anciens lits/alcôves et le couchage au sol restent disponibles. Toute extension de l’outil de plan compact sera précisée séparément ; aucun secteur ou insecte engagé en parallèle.
