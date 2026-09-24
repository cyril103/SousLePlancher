# Lot 17 — Lanterne de ceinture

Étape 4 bis de la roadmap, réalisée le 24 septembre 2026. **Validée par le joueur : « je valide ». Commit et publication autorisés.**

## Résultat jouable

L’habitant fabrique une lanterne, la prend à l’atelier et la porte à la ceinture. Ses mains restent disponibles pour monter l’échelle, traverser la passerelle et transporter une caisse. La torche à main conserve ses restrictions : parcours au sol, sans charge.

Dans **Travaux → Éclairage et éclaireurs**, choisir le type d’éclairage et l’habitant. **Fabriquer** crée une commande approvisionnée physiquement. **Équiper** réserve un objet accessible, en privilégiant celui qui possède le plus de combustible. **Destination…** permet de cliquer le sol ou un palier ; **Réserve Est** vise directement la zone à reconnaître.

Après 12 secondes d’observation sur la réserve orientale, les ressources sont découvertes et l’éclaireur rentre. Une fois équipé à nouveau, **Rapporter du bois** lance un seul trajet de récolte : prise d’une caisse, traversée, descente, dépôt et retour au refuge. Les affectations individuelles autorisent également une récolte avec une lanterne prête. La charge utilise les réservations et animations habituelles.

## Paramètres proposés

| Paramètre | Valeur |
| --- | --- |
| Matériaux livrés | 4 bois, 3 fibres |
| Assemblage après livraison | 16 secondes de simulation |
| Autonomie initiale | 180 secondes de simulation |
| Marge de retour | 24 secondes |
| Portée lumineuse | 4,5 unités |
| Transport | Une caisse par ordre, puis rangement |

Les estimations tiennent compte du trajet, de la vitesse de marche, des durées d’échelle et de passerelle, des attentes connues et du travail de récolte. Un départ trop long est refusé. La consommation continue pendant les traversées et les attentes, selon l’horloge de simulation. La pause fige cette horloge.

Les besoins prioritaires, le rappel global **H** et la marge de combustible provoquent le retour. Une traversée engagée se termine avant de changer de route. Une caisse déjà retirée reste dans la transaction de livraison et rejoint le dépôt. Les rappels répétés ne réinitialisent pas son déchargement. Si le combustible est totalement épuisé loin du refuge, l’assistance lumineuse reste nécessaire.

## Démonstration

Lancer Godot avec `-- --demo-lanterns`. La préparation fabrique deux lanternes par les systèmes de livraison et d’assemblage, équipe H1 et prépare son départ. La scène démarre en pause.

1. **Espace** : suivre H1 vers l’échelle, la passerelle et la réserve. Il observe puis rentre.
2. Après son retour, **Équiper** sélectionne la seconde lanterne pleine ; laisser l’habitant la chercher.
3. **Rapporter du bois** : observer le retour chargé et la dépose au refuge.
4. **H** permet de tester le rappel. **F5** rappelle les habitants avant le point de sauvegarde ; **F9** recharge.

La démo utilise des réserves initiales adaptées à l’essai. Elle ne modifie pas les conditions de départ d’une partie normale.

## Assets et intégration

Source : `art_source/lanterns_17/belt_lantern.blend`. Export : `assets/models/lanterns_17/belt_lantern.glb`, avec textures. Générateur : `tools/create_lantern_assets.py`, exécuté dans Blender 2.93.

Boîtier miniature en laiton récupéré, montants en bois, boucle de cuir, panneaux de mica ambré, mèche et cire. Attache sur le bassin, côté arrière gauche, sous le sac. Flamme animée et lumière chaude dans Godot. Les petites pièces du boîtier ne projettent pas d’ombre sur leur propre source ; les ombres sur le décor restent actives. Les animations de marche, portage et échelle sont réutilisées avec les mains libres.

Le générateur des anciennes torches reçoit aussi une correction de son argument de couleur ; leurs modèles ne sont pas régénérés.

## Sauvegarde et vérification

Format v7 : type d’équipement, autonomie restante, ingrédients et progression des fabrications. Les équipements des sauvegardes v6 restent des torches. Les valeurs hors capacité et types inconnus sont refusés. La sauvegarde demeure un point stabilisé au refuge, pas une sauvegarde libre en expédition.

`tests/lanterns.gd` couvre fabrication physique et conservation des matériaux, équipement, autonomie insuffisante, reconnaissance réelle par l’échelle et la passerelle, livraison chargée, rappel en montée et descente chargée, libération des passages, sauvegarde et reprise d’un assemblage interrompu. `tests/lanterns_visual.gd` capture la vue générale, l’attache et les poses avec et sans caisse. Les suites de navigation, livraisons, besoins, sauvegarde, interface et torches complètent ces contrôles.

## Limites assumées

La recette bois/fibres est provisoire : métal récupéré, mica, cire et chaîne de combustible ne sont pas encore des ressources simulées. Une lanterne usée ne se recharge pas gratuitement : fabriquer un remplacement. Pas de nouvelle animation de manipulation de lanterne, ni de réseau d’éclairage fixe dans ce lot. La réserve est toujours un palier de la carte actuelle, pas un nouveau secteur. Pas de mesure de performance à l’échelle d’une grande colonie ; la validation visuelle porte sur la scène d’essai.
