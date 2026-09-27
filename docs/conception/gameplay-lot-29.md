# Lot 29 — Soins et secours minimaux (étape 10)

27 septembre 2026 — **Validé par le joueur ; commit et push autorisés.**

## Résultat jouable

Un habitant immobilisé au rez-de-chaussée attend un secours. Un autre habitant disponible et autorisé réserve ce patient ainsi qu’un lit, le rejoint, prépare une petite civière traînée et le transporte jusqu’au couchage. Le secouriste va ensuite chercher **deux fibres dans un dépôt accessible au sol**, les apporte au lit et réalise **12 secondes de soin**. La santé passe ensuite de 30 à 100 à raison de 1,2 point par seconde, soit environ 58 secondes de convalescence. Le patient se lève et retrouve ses activités.

La blessure de cette démonstration est une condition initiale. Les déplacements, le choix du secouriste, les réservations, l’approvisionnement et la reprise sont exécutés par les systèmes ordinaires, sans itinéraire ni chronologie imposés.

## Règles

- Secours à la prochaine disponibilité, avant un nouveau travail ordinaire ; une transaction déjà engagée reste prioritaire jusqu’à son terme.
- Sommeil, faim, soif et rappel du secouriste restent prioritaires. Le panneau **Habitants → Santé et secours** permet d’autoriser ou désactiver chaque habitant.
- Le patient utilise son propre lit, ou un lit collectif libre. Un lit appartenant à un autre habitant n’est pas réquisitionné. La réservation empêche le sommeil concurrent et la réattribution.
- Les lits non construits ou inaccessibles sont exclus ; l’interface indique la cause de l’attente. Rétablir l’accès ou libérer un lit permet une nouvelle tentative autonome.
- Chaque patient et chaque secouriste ont une seule mission. Deux patients peuvent être secourus en parallèle, avec des lits distincts.
- Deux fibres sont réservées au dépôt, retirées physiquement, transportées puis déposées au lit. Elles sont consommées une seule fois à l’achèvement du bandage. Il faut deux fibres disponibles dans un même dépôt ; pas de collecte fractionnée dans ce lot.
- Sans fibres, le patient reste au lit sans guérison gratuite. Une livraison au dépôt permet la reprise.
- Une interruption du transport laisse le blessé au sol à la position atteinte et libère le lit. Un autre habitant peut reprendre.
- Une interruption avec les fibres en main laisse un lot récupérable à cet endroit, comme les matériaux des chantiers. Une interruption pendant le soin conserve au lit les deux fibres et le temps de soin déjà réalisé.
- Pendant la convalescence, confort, intimité et énergie utilisent les règles des chambres. Faim et soif continuent de diminuer. Le patient ne marche pas pour satisfaire ses besoins tant qu’il est immobilisé ; il n’y a pas encore d’alimentation par le soignant ni de décès lié à cette attente.

## Assets et animation

Création dans Blender, sources dans `art_source/health_29`, exports dans `assets/models/health_29` :

- Civière traînée à patins de bois, toile et poignées inclinées.
- Rouleau de bandage en tissu, visible pendant l’approvisionnement et près du lit.
- Animations supplémentaires `health_pull`, `health_care`, `health_place`, ajoutées au squelette existant. Pas de remplacement des animations antérieures ni des textures du personnage.

Scripts de reproduction : `tools/create_health_assets.py` et `tools/create_health_animations.py`. La civière est un accessoire fourni avec l’action de secours, comme les outils d’animation actuels ; elle n’a pas encore de chantier, de stock ou de durabilité. Le bandage consomme des fibres, sans introduire une nouvelle chaîne textile.

## Sauvegarde

Format **v16**. Sont conservés : patients, phases, santé, lit réservé, soignant, progression, fibres au lit/en main, réservation de dépôt, autorisations individuelles et compteur des fibres consommées. Les positions, animations, besoins et horloges restent inclus dans la sauvegarde sur place. Les accessoires sont reconstruits après chargement ; la partie reprend en pause.

Les sauvegardes v15 et antérieures restent compatibles, avec des habitants sains si elles n’ont pas d’état médical. Le validateur refuse notamment les soignants orphelins, les phases incompatibles, les lits dupliqués et les réservations de fibres incohérentes.

## Démonstration validée

Lancement : `-- --demo-health`. Sauvegarde séparée : `user://saves/health_demo.json`.

1. La scène démarre **en pause**, avec les quatre chambres du lot 28 et H1 blessé dans l’espace central ouest.
2. **Espace** : un habitant libre vient secourir H1 et le ramène à son lit.
3. Dans **Santé et secours**, désactiver le secouriste pendant le trajet pour observer la dépose au sol et la relève. Le bouton « Voir le blessé / convalescent » recentre la caméra.
4. Après installation au lit, observer le prélèvement de deux fibres au dépôt, leur transport, puis le soin et la convalescence. Le stock passe normalement de six à quatre fibres pour un soin non interrompu.
5. **F5 puis F9** pendant un transport ou un soin pour vérifier la reprise exacte. Le panneau Santé reste accessible via Habitants après rechargement.
6. Attendre le rétablissement : le lit est libéré et H1 retrouve les règles ordinaires de besoins et de travail.

Le panneau est défilant pour rester utilisable sur un écran moins haut.

## Vérifications

- `tests/health.gd` : boucle complète, deux patients, réservations, conservation des fibres incluant les lots récupérables, interruptions pendant transport/approvisionnement/soin, absence de fibres, lit inaccessible puis débloqué, propriété, sauvegardes JSON aux phases transport/installation/prélèvement/retour/soin, migration v15.
- `tests/health_visual.gd` : captures de la scène initiale, de la civière en trajet, du soin, de la convalescence et du rétablissement.
- Régressions : besoins autonomes et chambres/intimité du lot 28.

## Limites assumées et suite

Pas de blessure aléatoire, de combat, de maladie, de saignement ni de mort ajoutés. L’entrée `health.injure()` accepte ici un habitant disponible, sans charge ni passage engagé, au rez-de-chaussée. Le cas d’une blessure au milieu d’un travail ou dans un secteur distant reste à définir avec les futurs dangers.

Le secours utilise la navigation au sol existante et un accessoire de transport léger ; il ne simule pas un véhicule articulé ni un brancard à deux porteurs. Aucun transport sur l’échelle, la passerelle ou la fissure n’est proposé. Le soin est un traitement unique, sans compétence médicale ni diagnostic multiple.

**Prochaine livraison : étape 11A, accès cuisine et pont approvisionné physiquement.** La fourmi reste à l’étape 11B ; aucune extension de bestiaire n’est engagée ici.
