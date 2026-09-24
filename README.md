# Sous le plancher

Prototype 3D de gestion d'une colonie miniature sous une maison habitée. Projet Godot 4, testé avec Godot 4.7.2 en rendu Compatibility.

## Jouer

Importer `project.godot` dans Godot, puis F6 sur la scène principale ou F5 pour lancer le projet. Cliquer sur « Fonder la colonie ».

Le jeu démarre en plein écran. **F11** bascule entre plein écran et fenêtre. Si Godot intègre le jeu dans l'éditeur, désactiver l'exécution intégrée pour utiliser une fenêtre de jeu indépendante.

La barre d'icônes en bas donne accès aux constructions, affectations, objectifs, rappel au refuge, pause, vitesse, aide et plein écran. Les panneaux sont fermés par défaut ; un seul s'ouvre à la fois. Cliquez à nouveau sur son icône, sur × ou appuyez sur Échap pour le fermer. Le bandeau supérieur garde les réserves et les alertes visibles. Les notifications disparaissent après quelques secondes.

**B** ouvre les constructions, **C** les affectations, **O** les objectifs. Un clic sur un gisement ouvre directement ses affectations ; le menu déroulant permet aussi de choisir un autre gisement. Le nombre sur l'icône des habitants indique ceux sans tâche.

- Cliquer sur un gisement, puis « Affecter un habitant ». Il récolte et rapporte automatiquement ses ressources au refuge.
- Faire fabriquer un lit (4 bois, 3 fibres) ou une alcôve individuelle avec cloisons (6 bois, 5 fibres). Les habitants y récupèrent leur énergie ; aucun nouvel habitant n’apparaît à la construction.
- Construire un atelier (10 bois, 6 fibres) pour améliorer tous les transports.
- Avant le passage humain, appuyer sur H pour rappeler les habitants. Appuyer à nouveau après le danger pour reprendre les tâches.
- Développer les couchages et maintenir les réserves. La partie continue après le premier cycle, sans l’ancienne victoire automatique.
- Les habitants mangent et boivent selon leurs jauges individuelles, et collectent une ressource accessible si le dépôt est vide. Les besoins critiques ralentissent les déplacements. Des soupçons à 100 terminent la partie.

Caméra : flèches ou ZQSD sur clavier français (WASD physique), molette pour zoomer, bouton central maintenu pour tourner. Espace : pause. 1 : lit ; 2 : atelier ; 3 : alcôve. Échap/clic droit : annuler. R : recommencer.

Le **lot 12** introduit le sommeil, les propriétaires de lits, la fabrication et l’intimité. Voir [le détail du lot](docs/conception/gameplay-lot-12.md). `-- --demo-sleep` prépare deux couchages occupés et un chantier ; Espace reprend la démo. **Couchages** gère les propriétaires et les annulations de travaux, **Se reposer** déclenche un repos anticipé. F5 sauvegarde après rappel au refuge ; F9 recharge. Les besoins et les chantiers sont conservés, et les anciennes sauvegardes restent lisibles.

Le **lot 13** ajoute les besoins autonomes de faim et de soif au sommeil : trois jauges individuelles, repas et boissons au refuge, collecte d’urgence de nourriture et d’eau, réveil en cas de besoin critique. La démo `-- --demo-needs` montre ces comportements. Voir [les règles et limites](docs/conception/gameplay-lot-13.md).

## Assets Blender

Les habitants animés sont maintenant utilisés dans la **partie principale**, avec réservation, prise, transport et dépose des caisses. Les affectations affichent l'état des livraisons. **H** rappelle les porteurs avec leur charge ; **Libérer** annule avant la prise ou termine le retour si la caisse est déjà portée. Voir `docs/conception/gameplay-lot-06.md` pour les tests et limites. Le paramètre `-- --demo-deliveries` lance une partie avec quatre affectations préparées.

Le **lot 05** complète `scenes/interaction_review.tscn` avec les pivots de transport et la descente : **1** livraison, **2** montée, **3** descente. Les appuis et raccords sont vérifiés ; voir `docs/conception/assets-lot-05.md` pour les limites et le contrat d'intégration.

Les **interactions du lot 04** se testent dans `scenes/interaction_review.tscn` (**F6**) : **1** pour saisir, transporter et déposer une caisse ; **2** pour entrer sur l'échelle, monter et rejoindre le palier ; **R** pour recommencer. Détails et limites dans `docs/conception/assets-lot-04.md`.

Le **lot d'animations** se teste dans `scenes/animation_review.tscn` (**F6**) : repos, marche, portage de caisse, travail au marteau et échelle. Touches **1–5** pour choisir, **Espace** pour suspendre, **−/+** pour ralentir/accélérer, **D** pour activer le déplacement. Sources Blender, vitesses et limites : `docs/conception/assets-lot-03.md`. Ces animations sont encore indépendantes de l'IA du prototype.

Le **kit de refuge** se visite dans `scenes/refuge_review.tscn` (**F6**) : murs, fenêtre, porte ouvrante, échelle, passerelle et établi assemblés avec le mobilier et l'habitant de référence. **Espace** actionne la porte, **M** masque les murs et **L** change l'éclairage. Sources et limites dans `docs/conception/assets-lot-02.md`.

Un premier lot issu des choix de conception est disponible dans la scène **`scenes/asset_review.tscn`** (ouvrir puis **F6**) : habitant de référence animé, lit en boîte d'allumettes, seau-dé à coudre, caisse et plancher modulaire. Les sources sont dans `art_source/reference_01/`, les GLB dans `assets/models/reference_01/`. Consulter `docs/conception/assets-lot-01.md` pour les commandes, limites et critères de revue. Il s'agit d'une étude indépendante ; les modèles de la partie principale restent ceux du prototype.

Tous les modèles visibles sont créés avec Blender : sol et décor miniature, maison-boîte, établi, habitant au chapeau gland, miettes, bois et fibres. Les sources éditables sont dans `art_source/`, les exports glTF dans `assets/models/`. Le script `tools/create_assets.py` permet de les régénérer avec Blender 2.93 ou compatible :

```powershell
& 'D:\Program\blender2.93\blender.exe' --background --python tools/create_assets.py
```

`art_source/.gdignore` évite l'import automatique des fichiers Blender ; Godot utilise directement les GLB, sans dépendre de Blender au lancement. Aucun asset tiers téléchargé.

## Ambiance sous le plancher

Le décor comporte un bord de plancher supérieur en coupe, des poutres, des fondations, des toiles d'araignée, des échardes, des clous rouillés et des gravats. Ces éléments et les supports des torches sont modélisés dans Blender ; leurs sources sont `art_source/underfloor.blend` et `art_source/torch.blend`. Pour les régénérer :

```powershell
& 'D:\Program\blender2.93\blender.exe' --background --python tools/create_atmosphere.py
```

`scripts/atmosphere.gd` gère la lumière ambiante faible, trois ouvertures de lumière, la poussière en suspension et les torches animées. Les bâtiments anciens reçoivent une torche ; les lits et cloisons n’en ajoutent pas. Le passage des humains atténue momentanément l'éclairage venant du dessus.

Les shaders de `shaders/` produisent l'usure et la saleté du bois, les rais de lumière, les flammes et la poussière. Le plafond est ouvert au-dessus de la zone jouable pour conserver la visibilité. Les faisceaux utilisent une intégration volumétrique locale de 24 échantillons par pixel, limitée par la profondeur de la scène. Leur densité varie avec un bruit 3D lent ; chaque ouverture possède sa largeur, son inclinaison, sa diffusion et son intensité. Les anciens plans croisés et bandes lumineuses au sol sont supprimés. Le rendu reste compatible avec Compatibility.

Les poussières sont des particules douces orientées vers la caméra, distribuées le long de chaque faisceau. Les toiles sont des réseaux de courbes Blender sur des points irréguliers, avec affaissement, déchirures et fils libres. Les graines aléatoires sont fixes pour conserver une composition stable. Les courbes éditables sont conservées dans `art_source/cobweb_73.blend` et `art_source/cobweb_181.blend` ; les maillages assemblés sont inclus dans `underfloor.glb`. Le matériau de soie varie légèrement en intensité et bouge doucement. Le MSAA 4× améliore la lecture des fils fins.

Les effets visuels sont désactivés dans le moteur de rendu factice `--headless` pour éviter du travail inutile. Leur validation se fait par lancement graphique et captures ; les tests de simulation peuvent aussi être exécutés sans `--headless`. Les matériaux sont partagés et conservés en cache pour permettre la libération différée des scènes sans invalider leurs ressources graphiques.

## Validation

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke.gd
```

Le test couvre récolte/livraison, affectation, coût et placement de construction, rappel, poursuite de la colonie après les anciens objectifs et défaite par détection. `tests/sleep.gd` vérifie les lits, travaux et leur persistance ; `tests/needs.gd` vérifie les besoins autonomes, la consommation et la migration des sauvegardes. Le paramètre utilisateur `-- --capture` en mode graphique enregistre une capture de la scène dans `artifacts/prototype.png`.

## Périmètre

Revue visuelle : lancer Godot avec `--script res://tests/visual_review.gd` pour enregistrer trois vues (ensemble, rotation, détail) et mesurer les intervalles de rendu. Mesure indicative sur la scène initiale : 16,61 ms de moyenne, 16,94 ms au 95e percentile, en 1920 × 1080 sur GTX 1650 avec synchronisation verticale. Cette mesure ne couvre pas une colonie développée.

Prototype jouable : habitants animés, livraisons, navigation autour des bâtiments, accès verticaux, exploration d’une réserve, sauvegarde au refuge et premiers besoins de sommeil. Le cahier des charges complet reste à développer. Pas encore d’audio ni de grands humains modélisés ; leur présence est simulée par un cycle et une jauge de soupçons. Les horaires, métiers, pièces modulaires, chaînes de production et territoires procéduraux restent des étapes futures.

