# Lot 04 — Prise, dépose et raccords d'échelle

Première passe validée par le joueur (« ok, je valide, tu peux commit et pousser »), après correction du contact des pieds sur le palier. Elle prolonge les cinq cycles validés du lot 03 avec quatre actions Blender non bouclées dans le même personnage exporté. Les limites et travaux d'intégration décrits ci-dessous restent à traiter.

| Action | Durée | Particularité |
| --- | --- | --- |
| `pick_up` | 1,8 s | Accroupissement, contact à 0,72 s, redressement avec la caisse |
| `put_down` | 1,8 s | Abaissement, libération à 1,08 s, redressement sans charge |
| `climb_enter` | 1,2 s | Transition de la station debout aux premiers appuis |
| `climb_exit` | 1,4 s | Transfert successif des pieds sur le palier |

## Essayer

**Évolution du lot 05 :** la même scène ajoute désormais la touche **3** pour descendre, des pivots animés avec transferts d'appuis et une livraison sur trois cycles complets. Voir `assets-lot-05.md`. Les durées, distances et limites ci-dessous décrivent le lot 04 initialement validé.

Ouvrir `scenes/interaction_review.tscn` puis F6. **1** lance la livraison, **2** lance l'échelle, **R** recommence la séquence courante, **Espace** suspend, **−/+** change la vitesse. Glisser pour tourner la caméra, molette pour zoomer, F11 pour le plein écran.

La livraison prend la caisse sur un support, tourne, parcourt 1,8 unité et dépose la même caisse sur le second support. Les deux supports unis sont des gabarits techniques de hauteur, pas de nouveaux assets définitifs. La caisse est un seul objet : changement de parent au contact, maintien dans le repère de portage, puis retour dans le monde à la dépose. Les changements de vitesse et la pause affectent la chronologie entière.

L'autre séquence enchaîne l'entrée, trois cycles de montée et la sortie sur un palier de 2,04 unités. Elle s'arrête au terme de l'action pour permettre l'examen de la pose finale. Elle n'inclut pas encore la descente avec ses propres raccords.

## Sources et contrat d'intégration

- Génération : `tools/create_resident_animations.py` ; les actions sont conservées dans `art_source/animations_03/resident_animated.blend` et exportées dans `assets/models/animations_03/resident_animated.glb`.
- `ResidentAnimator.ONE_SHOTS` distingue les quatre actions non bouclées des cinq cycles précédents. `manage_cargo_visibility = false` confie la visibilité de la charge au contrôleur d'interaction.
- `scripts/interaction_review.gd` est une chronologie de démonstration déterministe. Elle n'est pas un ordonnanceur de tâches et n'intègre pas encore la navigation de la colonie.
- La caisse utilisée est à l'échelle 0,52. La prise est conçue pour la hauteur du support présenté, pas pour toutes les hauteurs possibles ni pour une prise au sol.
- `climb_exit` contient un déplacement de l'os racine local Godot `(0, 0.51, 0.45)`. Un futur contrôleur doit transférer ce déplacement au personnage avant de revenir à un cycle sur place. La revue conserve la dernière pose du clip à l'arrivée.
- Les rotations sur place de la livraison sont encore pilotées par la scène ; elles ne constituent pas des animations dédiées de pivot des pieds. Les départs/arrêts de marche, les prises avec doigts articulés et l'adaptation automatique aux autres supports restent à affiner.

## Vérification

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path . scenes/interaction_review.tscn -- --capture-interactions
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path . scenes/animation_review.tscn -- --capture-animations
```

Le premier contrôle conserve l'identité de la caisse, vérifie son parent et sa destination après livraison ainsi que le contact final des deux semelles avec le palier (tolérance de 0,002 unité, positions comprises dans la surface). La sonde utilise la pose finale avec pieds à plat et l'écart géométrique entre cheville et dessous de semelle. Il produit neuf captures dans `artifacts/interactions_04/`. Le second contrôle les cinq cycles précédents, leurs durées, le rig, les accessoires et l'appui du pied. Les captures et journaux restent hors Git.

Correction après retour du joueur : la face supérieure des planches est à Y=0 dans le modèle, et non à +0,055. Le palier est désormais placé directement à la hauteur cible ; la sortie compense progressivement la marge de 0,0105 sous l'origine du personnage jusqu'aux semelles. Vérification Godot : écart final de 0,000916 unité pour chacun des deux pieds.

Suite : examiner ces interactions, affiner les pivots/départs/arrêts et les raccords de descente, puis raccorder la livraison et les accès verticaux aux tâches réelles, avec réservations, collisions et interruptions.
