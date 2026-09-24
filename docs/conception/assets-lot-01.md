# Assets — lot de référence 01

## Objectif de cette livraison

Traduire les choix de l'entretien en un premier ensemble 3D consultable : minuscules humains légèrement stylisés, vêtements de récupération, objets humains détournés et bois réemployé. Ce lot est une étude artistique v0.1 à commenter, pas une validation de la qualité finale de tous les assets.

La scène de revue utilise un éclairage de studio lisible pour examiner les formes. L'éclairage de la partie sous le plancher devra être évalué séparément lors de l'intégration au jeu.

## Contenu livré

| Modèle | Contenu | État |
| --- | --- | --- |
| `resident_reference` | Humain d'environ 1,60 unité, chemise en lin, gilet sauge, poches, boutons, pantalon rapiécé, bottes et sac ; squelette de 19 os, attaches main droite/dos/tête et animation d'attente | Étude du premier habitant, un seul visage ; rig de référence, pas encore de marche ni de travail |
| `matchbox_bed` | Tiroir de boîte d'allumettes, étui réutilisé en tête de lit, étiquette imprimée, grattoirs, matelas, oreiller et couverture en pièces de tissu cousues | Matières v0.2 ; proposition de mobilier détourné |
| `thimble_bucket` | Dé à coudre ouvert, paroi métallique avec creux modélisés, rebord et anse en fil de fer | Objet de transport ; utilisation par un habitant à intégrer |
| `salvage_crate` | Caisse ouverte en lattes, montants, clous et étiquette de stock | Élément de stockage visuel ; capacité et interactions à définir |
| `floor_module_2x2` | Module de cinq planches, clous et fentes | Pas de placement constructible ajouté ; module géométrique de référence |

Chaque modèle possède un fichier Blender et un GLB distinct. Les textures PNG sont intégrées dans les exports ; elles sont également conservées séparément. Aucun modèle tiers téléchargé. La révision des matières utilise deux atlas créés avec l'outil intégré `image_gen`, puis des cartes de couleur et de normales préparées par cuisson dans Blender.

## Révision des textures v0.2

- Sources générées : `assets/textures/reference_02/matchbox_atlas.png` et `materials_atlas.png`.
- Étiquette française vieillie « ALLUMETTES DE SÛRETÉ », papier et carton fibreux, grattoir abrasif. L'étui conservé en tête de lit expose une étiquette lisible ; des bandes de grattoir identifient également l'objet sur les côtés.
- Bois récupéré, toile écrue déclinée en plusieurs couleurs, cuir usé et métal patiné remplacent les aplats et les motifs réguliers du premier essai.
- Les faces des éléments en bois reçoivent des coordonnées UV orientées suivant leur longueur.
- Les cartes de normales sont une estimation de petits reliefs à partir des images, pas des mesures physiques. Les niveaux de rugosité sont réglés par matériau. Les éléments imprimés ont un relief très faible pour conserver la lisibilité.
- Prompts complets et méthode : `docs/conception/texture-generation-prompts.json`. Le modèle du générateur intégré n'est pas sélectionnable par l'outil ; aucune version « 2.5 » n'est revendiquée.
- Préparation reproductible : `tools/reference_materials.py`, appelé par le générateur principal. Les cartes cuites sont mises en cache dans `reference_02` ; pour modifier une recette de matériau, supprimer uniquement ses deux cartes dérivées avant régénération, en conservant les atlas sources.
- Passer `-- --no-render` au générateur permet de mettre à jour les sources, exports et scène Blender sans recalculer les images de présentation. La scène Godot utilise un ciel de réflexion neutre pour rendre le métal lisible.

## Où examiner le lot

- Scène Godot : `scenes/asset_review.tscn` — ouvrir puis **F6**.
- Commandes : glisser pour tourner, molette pour zoomer, **1** ensemble, **2** habitant, **3** mobilier, **F11** plein écran, **Échap** quitter.
- Scène Blender d'ensemble : `art_source/reference_01/reference_showcase.blend`.
- Sources individuelles : `art_source/reference_01/`.
- Exports : `assets/models/reference_01/`.
- Textures : `assets/textures/reference_02/` (matières actuelles) ; `reference_01/` conserve les premières textures.
- Images de revue : `artifacts/reference_01/` (générées localement et ignorées par Git).
- Dimensions, triangles et nombre de matériaux : `art_source/reference_01/manifest.json`.

Convention : 1 unité Blender = 1 unité Godot. La conversion physique proposée dans le cahier des charges reste à valider ; le mobilier de ce lot est dimensionné pour cet habitant. L'ancien prototype conserve ses propres assets et son échelle actuelle.

## Limites à traiter après la revue

- Le personnage emploie un assemblage de formes et une pondération essentiellement rigide, avec une transition de poids aux genoux. Reprendre la topologie et les déformations pour les gestes de production, avant de considérer le rig comme terminé.
- L'animation `idle_reference` permet de vérifier l'import et une légère respiration. Elle ne remplace pas les animations de marche, transport, construction, escalade ou blessure.
- Un seul visage et une seule tenue : CHR-01 et les lots d'animations ne sont pas clôturés.
- Les matériaux et la géométrie détaillée servent à la revue rapprochée. Prévoir atlas, normales, LOD et budgets mesurés pour une colonie de 30 à 50 habitants. Les creux du dé à coudre pourront passer dans une texture de normales pour les vues éloignées.
- Collisions, points d'interaction, réservations de chantier et déplacements ne sont pas ajoutés à ce lot.
- Le module de plancher devra recevoir des variantes, des raccords et un traitement d'usure plus poussé pour devenir un kit complet.

## Reproduction et contrôle

```powershell
& 'D:\Program\blender2.93\blender.exe' --background --python tools/create_reference_assets.py
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path . --scene res://scenes/asset_review.tscn -- --capture-assets
```

La capture automatique vérifie huit instances de modèles dans la scène, l'import de l'animation de l'habitant et produit quatre captures du moteur Compatibility : ensemble, habitant, dos et lit-allumettes. Les rendus Blender servent de complément, pas de preuve du rendu en jeu.

## Retour attendu sur cette étude

Examiner surtout la silhouette et le visage de l'habitant, le caractère de la tenue, le niveau de stylisation et la lecture des objets détournés. Les corrections retenues sur ce petit ensemble guideront ensuite les variantes de métiers et le kit de refuge. La roadmap générale et le PDF v0.2 restent à consolider avec les décisions de l'entretien.
