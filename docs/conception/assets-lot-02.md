# Lot 02 — kit de refuge

**Validation artistique : acceptée par le joueur après revue de la scène (« ok je valide »).** Le kit et son assemblage sont retenus comme référence pour la suite. Les limites d'intégration décrites ci-dessous restent à traiter : cette validation ne clôture pas les collisions, la navigation, les animations de franchissement ni les états de chantier.

Suite du lot de référence validé dans la conversation : construction modulaire à l'échelle des minuscules humains, bois et tissu récupérés, assemblages visibles et matières du lot 01 révisées. Le lot produit les formes et leurs raccords ; il n'ajoute pas encore la construction au gameplay.

## Modèles livrés

| Asset | Usage et dimensions nominales | Détail |
| --- | --- | --- |
| `wall_solid_2m` | Mur de 2 unités de large et 2,2 de haut | Lattes irrégulières, contreventement, clous et ligatures |
| `wall_window_2m` | Même grille ; fenêtre de 0,9 unité environ | Appui, croisillons et store de tissu enroulé |
| `wall_doorway_2m` | Même grille ; passage de 1,02 × 1,95 | Montants, linteau et seuil |
| `door_leaf_1m` | Vantail indépendant ; pivot au gond | Traverses, charnières métalliques et poignée en fil de fer |
| `ladder_2m` | Dessert un plancher à 2,2 ; montants prolongés pour la sortie | Neuf barreaux liés et légère inclinaison |
| `bridge_2m` | Portée de 2 unités, largeur utile d'environ 0,9 | Tablier, longerons, poteaux et cordages |
| `salvage_workbench` | Plateau de 1,72 × 0,87 ; hauteur 0,94 | Bobine, fil, aiguille, marteau bricolé et réserve de tissus |

Le suffixe `2m` est un identifiant de module en unités de scène, pas une affirmation d'échelle physique en mètres : une unité Godot conserve la convention provisoire du dossier. Les ligatures et débords peuvent dépasser les dimensions nominales. Les dimensions exactes, triangles et matériaux sont dans le manifeste.

## Pièce témoin

Ouvrir `scenes/refuge_review.tscn` puis **F6** dans Godot. La scène assemble un refuge de 6 × 4 unités, un couchage, un atelier, une plateforme haute desservie par l'échelle et un dépôt extérieur accessible par une passerelle. L'habitant de référence sert de repère d'échelle.

- Glisser : orbite ; molette : zoom.
- **1** : ensemble ; **2** : atelier ; **3** : accès.
- **Espace** : ouvrir/fermer la porte, y compris en inversant un mouvement en cours.
- **M** : masquer/afficher les murs pour inspecter l'aménagement.
- **L** : éclairage de revue ou essai d'ambiance chaude. Les lumières d'ambiance sont des sources de présentation, pas des torches fonctionnelles.
- **F11** : plein écran ; **Échap** : quitter.

## Sources et intégration

- Blender : `art_source/refuge_02/`, un fichier par modèle.
- Godot : `assets/models/refuge_02/`, GLB avec textures intégrées.
- Matières : famille existante dans `assets/textures/reference_02/` ; aucune nouvelle génération d'image pour ce lot.
- Générateur : `tools/create_refuge_assets.py` ; réutilise les fonctions du générateur précédent sans relancer sa production complète.
- `art_source/refuge_02/manifest.json` : grille, géométrie et coordonnées des ancrages en axes Godot, notamment pivot de porte, opérateur de l'établi et extrémités des accès.

```powershell
& 'D:\Program\blender2.93\blender.exe' --background --python tools/create_refuge_assets.py
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path . --scene res://scenes/refuge_review.tscn -- --capture-refuge
```

## Critères de revue et limites

Vérifier les raccords sur grille, la taille de la porte et de l'établi par rapport à l'habitant, la lisibilité de l'échelle, du store et des cordages, et la place laissée aux circulations. La revue automatique contrôle les 24 instances, l'animation d'attente et les positions ouverte/fermée de la porte ; elle produit trois captures dans `artifacts/refuge_02/`.

Les états de chantier et de dégâts, les collisions de production, le maillage de navigation, les liens réservables et les animations de franchissement restent à réaliser. La plateforme haute est une étude de volume ; garde-corps et soutien structurel complet restent à détailler. Les assets ont un niveau de détail de présentation et nécessiteront des LOD et une réduction des matériaux pour les grandes colonies. Les lots BLD-03, BLD-05, BLD-06 et BLD-13 de l'inventaire général ne sont donc pas marqués terminés.
