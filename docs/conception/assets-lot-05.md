# Lot 05 — Pivots avec charge et descente d'échelle

Première passe validée par le joueur (« je valide, tu peux commit et pousser »), après présentation des pivots avec charge et de la descente complète. Les sources Blender et le GLB du personnage existant reçoivent cinq actions supplémentaires. Les neuf animations des lots précédents sont conservées. Les limites et travaux d'intégration décrits ci-dessous restent à traiter.

| Clip | Durée | Fonction |
| --- | --- | --- |
| `carry_turn_right` | 1,2 s | Pivot de +90°, avec transfert successif des pieds, de la pose de prise vers la marche |
| `carry_turn_left` | 1,2 s | Pivot de −90°, de la marche vers la pose de dépose |
| `descend_enter` | 1,4 s | Recul depuis le palier et recherche des appuis sur l'échelle |
| `climb_down` | 1,8 s | Descente de 0,51 unité par cycle, avec regard vers le bas |
| `descend_exit` | 1,2 s | Retour des pieds au sol et redressement |

## Revue

Ouvrir `scenes/interaction_review.tscn`, puis F6. **1** livraison avec pivots, **2** montée, **3** descente, **R** recommencer, **Espace** pause, **−/+** vitesse. Le paramètre utilisateur `--review-descent` ouvre directement la descente.

La livraison parcourt maintenant trois cycles entiers de marche, soit environ 1,545 unité en 4,2 s. Cela permet d'accorder les poses de sortie et d'entrée des pivots sans saut des jambes. La caisse reste le même objet tout au long de la livraison.

Les pivots sont enregistrés dans Blender : le corps tourne et chaque pied est levé puis reposé séparément. Ils remplacent la rotation uniforme du personnage entier utilisée dans le lot 04. La rotation de l'os racine est transférée à l'orientation du personnage lors du passage au clip suivant ; elle ne doit pas être appliquée une seconde fois pendant le pivot.

La descente est une séquence indépendante de 8 s, démarrant sur le palier : entrée, trois cycles, sortie. Le cycle est dérivé des appuis de montée, rejoués dans l'ordre inverse et enregistrés dans une action dédiée plus lente, avec un mouvement de tête ajouté. Ses raccords réemploient également les trajectoires des raccords de montée en sens inverse. Il ne s'agit donc pas d'une nouvelle chorégraphie entièrement indépendante.

Le sol de la scène de revue est remis à Y=0, conformément à la face supérieure des planches. Les placements debout compensent l'écart entre l'origine du personnage et le dessous de ses semelles. La correction du palier validée au lot 04 est conservée.

## Contrat technique

- Générateur : `tools/create_resident_animations.py` ; sources et export restent dans les dossiers `animations_03` pour conserver les références existantes.
- `climb_down` est bouclé et se lit vers l'avant. Sa vitesse de translation verticale nominale est −0,28333 unité/s. Ne pas utiliser une vitesse de lecture négative pour descendre avec ce clip.
- Les deux pivots et les raccords sont non bouclés. Les rotations finales des pivots valent +90° et −90°.
- `descend_enter` commence avec le déplacement local d'os racine `(0, 0.51, 0.45)` du palier et se termine sans ce déplacement. Le repère du personnage reste placé au dernier appui de l'échelle pendant ce raccord.
- La chronologie de revue est toujours indépendante de l'IA et de la navigation du jeu.
- L'optimisation des clés à l'import du personnage est désactivée sur `PATH:AnimationPlayer` dans son fichier `.glb.import`. Elle introduisait un déplacement d'environ 0,003 unité sur un pied pourtant fixe dans Blender. Avec les clés conservées, les contrôles d'appui passent à la tolérance de 0,002. Le réglage est celui de l'[importeur de scènes Godot](https://github.com/godotengine/godot/blob/master/editor/import/3d/resource_importer_scene.cpp) ; ce choix augmente le nombre de clés conservées et devra être réévalué lors du profilage d'une colonie complète.

## Contrôles

Le contrôle `--capture-interactions` vérifie les positions des os de part et d'autre des six nouveaux raccords (tolérance de 0,004 unité), l'immobilité des pieds en appui pendant les deux pivots (0,002), la conservation de la caisse, sa dépose, et le contact des deux semelles au palier puis au sol après descente (0,002). Il produit 17 captures dans `artifacts/interactions_04/`. Le contrôle `--capture-animations` reste celui des cinq cycles initialement validés.

## Limites et suite

Les pivots sont conçus pour les angles et les poses de cette livraison, pas encore pour une direction ou une distance quelconque. La descente reste calibrée pour l'échelle et le palier du kit. Les mains sont stylisées et les doigts ne sont pas articulés. Il n'y a pas de réservation d'accès, de navigation, d'évitement d'habitants ou d'interruption contextuelle dans ces démonstrations.

Après examen, prochaine étape : intégrer les états d'interaction à une tâche de livraison réelle avec destinations, réservation de la charge, progression et annulation propre. L'accès vertical devra ensuite être raccordé au parcours et réservé pendant la traversée.
