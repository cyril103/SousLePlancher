# Lot 19 — Reconnaissance à la lanterne, étape 6A

27 septembre 2026. **Validé par le joueur ; commit et push autorisés.**

## Résultat jouable

Une lanterne de ceinture permet maintenant de franchir la fissure ouverte, reconnaître le fond de l’alcôve puis rentrer au refuge avec son équipement. L’alcôve est une zone artisanale plus profonde, toujours chargée avec le refuge. Les personnages, animations, fissure et matériaux existants sont réutilisés.

En partie normale : construire un atelier, fabriquer une lanterne (4 bois, 3 fibres), inspecter la fissure puis la dégager et l’étayer (6 bois, 4 fibres). Dans **Travaux → Fissure et passage**, sélectionner un habitant libre, l’équiper et attendre qu’il récupère la lanterne. Cliquer **Explorer à la lanterne**. Le bouton de suivi caméra suit le personnage ; les flèches ou ZQSD reprennent la caméra libre.

Le panneau indique le secteur du personnage et son combustible restant, indépendamment du défilement du résumé. Le passage refuse les caisses, les habitants occupés, les besoins urgents et les équipements incompatibles. Une torche tenue à la main ne remplace pas la lanterne pour cette sortie.

## Déplacement et sécurité

- Secteurs stables : `refuge_south`, `alcove_north`. Accès : `south_fissure`. Mission active identifiée par accès et habitant ; une seule mission par habitant. Ces identifiants sont des clés internes, distinctes des numéros de conception de l’atlas.
- La fissure dirige le déplacement pendant la mission lumineuse `sector`. La lanterne garde son propriétaire et consomme du combustible durant marche, observation, attente et traversée.
- Le calcul avant départ inclut l’aller, les deux traversées, l’observation de 12 secondes, le retour au refuge, les autres visiteurs et la marge de 24 secondes. Le budget de retour est réévalué pendant la sortie.
- File commune aux deux directions. Le seuil reste réservé jusqu’à ce que le personnage ait dégagé la sortie de l’alcôve.
- Un rappel personnel ou global, une demande F5, la soif, la faim ou le sommeil interrompent la reconnaissance. Une traversée engagée se termine physiquement avant le demi-tour. Le manque de combustible prévu provoque un retour anticipé.
- Au retour, le personnage retrouve le secteur refuge puis range sa lanterne avec son combustible restant. Les besoins reprennent leur traitement habituel.

La zone conserve un couloir libre : déplacement local direct entre seuil, points d’attente et point d’observation. Il n’y a pas de placement de construction dans l’alcôve, ni de graphe universel de navigation entre secteurs. L’extension vers des zones plus complexes devra ajouter les obstacles et routes appropriés.

## Connaissance et sauvegarde

Avant l’arrivée d’un éclaireur, le décor de l’alcôve est caché. Il apparaît pendant la traversée éclairée et l’observation. Après 12 secondes au fond, la reconnaissance est terminée et le décor demeure mémorisé. Un rappel avant la fin ne valide pas la reconnaissance.

Cette première zone ne contient que du **décor statique** : aucun stock distant, animal ni événement mutable n’est montré hors observation. Il ne s’agit pas encore d’un brouillard de guerre cellule par cellule. Le résumé distingue inconnue, observée et mémorisée.

Le format v8 conserve déjà `fissure.visited` : aucune migration supplémentaire n’est nécessaire. F5 rappelle et stabilise toujours tous les habitants au refuge avant écriture. La reprise au milieu d’une expédition reste prévue en 6C.

## Assets

Extension du module de sol et des bordures dans Blender 2.93, circulation centrale dégagée, fragments placés sur les côtés.

- Générateur : `tools/create_alcove_assets.py`.
- Source éditable : `art_source/alcove_19/alcove_sector.blend`.
- Export : `assets/models/alcove_19/alcove_sector.glb`, avec textures.

Il ne s’agit pas d’une refonte artistique générale. La finition des autres assets reste au calendrier de production.

## Démo et vérifications

Lancer Godot avec `-- --demo-alcove`. La démo prépare l’inspection et les travaux par simulation, fournit une lanterne à H1, puis se met en pause. Cet équipement gratuit est propre à la démo. Cliquer **Explorer à la lanterne**, puis **Espace**. Le fichier F5 de démo est `user://saves/alcove_demo.json` ; la sauvegarde normale est préservée.

Tests exécutés sous Godot 4.7.2 :

- `tests/alcove.gd` : refus sans équipement et combustible insuffisant, pause/x3, rappel sur seuil, retour et rangement, connaissance interrompue/complète, sauvegarde/rechargement, sommeil, soif, combustible faible, circulation bidirectionnelle et consommation en file.
- `tests/fissure.gd` : chantier et conservation des matériaux, visites équipées en file, rappels, interruption, migration v7 et entrée inaccessible.
- `tests/lanterns.gd`, `tests/torches.gd`, `tests/checkpoint.gd` : non-régression des équipements et sauvegardes.
- `tests/alcove_visual.gd` : captures de la démo et du personnage éclairé dans le secteur adjacent, inspectées visuellement.

Les captures sont dans `artifacts/alcove/` (dossier non versionné).

## Validation joueur

Le joueur a validé cette étape le 27 septembre 2026. Prochaine livraison : **6B : prélèvement et retour chargé**, avec adaptation du passage. Aucune récolte, ressource supplémentaire, fourmi ou génération procédurale n’est ajoutée ici.
