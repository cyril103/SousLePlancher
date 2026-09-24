# Lot 03 — Animations de l'habitant

24 septembre 2026. Première passe validée par le joueur (« ok je valide, tu peux commit et pousser »), après présentation de la scène de démonstration. Cette validation porte sur le lot d'animations ; les travaux d'intégration et limites décrits ci-dessous restent à traiter.

## Contenu livré

| Clip | Durée | Déplacement nominal | Intention |
| --- | --- | --- | --- |
| `idle` | 4 s | Aucun | Respiration discrète et léger mouvement du buste |
| `walk` | 1,2 s | 0,55556 unité/s | Pas alternés, levée du pied et balancement des bras |
| `carry_walk` | 1,4 s | 0,36797 unité/s | Pas plus courts, caisse tenue à deux mains |
| `work` | 1,2 s | Aucun | Marteau : levée, frappe puis récupération |
| `climb` | 1,6 s | 0,31875 unité/s verticale | Progression de 0,51 unité par cycle, deux barreaux |

Les animations sont bouclées et enregistrées à 30 images/s dans Blender. Elles restent sur place dans le fichier : le contrôleur de déplacement doit appliquer la vitesse nominale multipliée par la vitesse de lecture. Les unités servent à la cohérence du kit miniature ; elles ne représentent pas des mètres à l'échelle humaine.

## Fichiers et architecture

- Source éditable : `art_source/animations_03/resident_animated.blend`, avec cinq actions et pistes NLA nommées. Les pistes sont désactivées dans le fichier pour permettre de consulter une action seule.
- Export : `assets/models/animations_03/resident_animated.glb` ; 21 os, textures du personnage de référence conservées.
- Marteau de main : `hand_hammer.blend` et `hand_hammer.glb` dans les mêmes dossiers respectifs. Origine au point de prise, manche gainé de cuir et tête métallique.
- Générateur : `tools/create_resident_animations.py`. Il ouvre la source validée, corrige les influences des membres, résout les poses dans Blender et exporte les clips. Le manifeste dans `art_source/animations_03/manifest.json` conserve les paramètres exacts.
- `scripts/resident_animator.gd` expose `set_action()` et `sync_motion_speed()`. Transition par défaut de 0,16 s ; aucun calcul de navigation dans ce composant.
- `socket_carry` porte la caisse existante à l'échelle 0,52. `socket_tool` suit la main droite. Les accessoires apparaissent uniquement dans leurs états respectifs.

Les anciennes attaches basées sur les noms des objets étaient fragiles lorsque Blender renommait des pièces dupliquées. La copie animée est corrigée par îlots de géométrie ; les chevilles reçoivent un mélange d'influences. Le générateur du personnage de référence conserve désormais aussi le nom de l'os dans une propriété de chaque objet pour les prochaines régénérations.

## Revue dans Godot 4.7.2

Ouvrir `scenes/animation_review.tscn`, puis F6. La scène propose une piste, l'établi et l'échelle du kit validé, avec éclairage de contrôle. Elle ne remplace pas l'ambiance sombre du jeu.

| Commande | Effet |
| --- | --- |
| 1 à 5 | Repos, marche, transport, travail, échelle |
| Espace | Pause et reprise |
| − / + | Vitesse de 0,25 à 2 fois la vitesse nominale |
| D | Déplacement ou animation sur place |
| Glisser / molette | Rotation de caméra / zoom |
| F11 / Échap | Plein écran / quitter |

La piste de marche ramène le personnage à son début lorsqu'il atteint le bord. Ce retour est un dispositif de revue, pas une animation de demi-tour. L'échelle alterne trois cycles de montée et leur lecture inversée pour la descente. La caméra suit l'habitant.

## Vérifications réalisées

Export Blender, import puis rendu graphique Godot 4.7.2 Compatibility sur GTX 1650. Contrôle des cinq noms de clips, des durées, des 21 os et de la visibilité des accessoires. Le test compare également deux positions du pied gauche pendant l'appui, après compensation du déplacement : tolérance de 0,012 unité, marche et transport. Dix captures de poses ont été examinées, notamment après correction des influences gauche/droite.

Relancer la vérification graphique :

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --path . scenes/animation_review.tscn -- --capture-animations
```

Les captures sont écrites dans `artifacts/animations_03/`, ignoré par Git. Le journal doit contenir `ANIMATION_REVIEW_CHECKS_OK` sans erreur. Le mode graphique est nécessaire aux captures.

## Limites et prochaine intégration

**Mise à jour :** le lot 04 ajoute une première passe de prise/dépose et d'entrée/sortie d'échelle, à examiner dans `interaction_review.tscn`. Voir `assets-lot-04.md`. Le paragraphe suivant décrit le périmètre initial validé du lot 03.

Cette passe donne les cinq cycles et leur banc de revue. Elle n'inclut pas encore la prise et la dépose de caisse, les entrées/sorties d'échelle, les demi-tours, les départs et arrêts dédiés, ni les transitions contextuelles entre ces actions. La descente est une lecture inversée de la montée. Les doigts ne sont pas articulés ; la prise reste stylisée. Les vêtements conservent une géométrie de référence composée de pièces : une retopologie sera utile pour les flexions extrêmes et les gros plans.

L'échelle demande encore un alignement contextuel des mains/pieds sur les barreaux au raccordement à la navigation. Les contacts ont été construits pour ce kit ; aucune adaptation automatique aux terrains, aux hauteurs d'établis ou aux autres échelles. Le test d'appui ne constitue pas une validation de tous les contacts sur tout le cycle. Les collisions, réservations d'échelle et interactions avec les autres habitants ne sont pas implémentées ici.

Suite prévue : valider les rythmes et silhouettes, ajouter prise/dépose et entrée/sortie d'échelle, puis relier les états aux tâches réelles avec navigation, réservations et interruptions. Ajouter ensuite les événements de pas/frappe et les sons.
