# Lot 16 — Torches individuelles

24 septembre 2026. **Étape 4 validée par le joueur, publication autorisée.** Base publiée : `930dfb3` (dépôts locaux).

## Essayer

Lancer le projet avec `-- --demo-torches`. La démo prépare un atelier, fait réellement livrer et fabriquer une torche, équipe H1 et met sa première sortie en pause. **Espace** lance le trajet vers le bord sombre près de la bobine. **H** rappelle la colonie. La scène normale propose les mêmes commandes sans préparation gratuite.

Dans **Travaux → Torches et éclaireurs** :

1. Commander une torche dans un atelier libre. Un ordre actif par atelier ; les besoins restent prioritaires.
2. Observer les livraisons de bois/fibres, puis les huit secondes d’assemblage.
3. Sélectionner un habitant disponible et cliquer **Équiper**. Il va prendre une torche physiquement à son lieu de rangement.
4. Une fois équipé, **Destination…** puis clic sur un point du sol. Échap/clic droit annule le choix. La flamme s’allume au départ.
5. L’habitant observe douze secondes à destination puis rentre. **Rappeler / ranger au refuge** interrompt la sortie. La torche revient dans la réserve du refuge avec son combustible restant ; les mains redeviennent disponibles.

La démo reste soumise au cycle humain, à la faim, à la soif et au sommeil. Elle n’enregistre rien automatiquement. F5 attend le retour et la stabilisation des tâches ; F9 charge le point de refuge.

## Règles livrées

| Paramètre provisoire | Valeur |
| --- | --- |
| Recette | 2 bois + 1 fibre |
| Assemblage après livraison | 8 secondes simulées |
| Combustible initial | 90 secondes allumées |
| Portée lumineuse | 4,5 unités Godot |
| Observation | 12 secondes |
| Marge de retour | 12 secondes, en plus du trajet estimé |
| Remplacement | Fabriquer une nouvelle torche ; aucun plein gratuit |

Les transports d’ingrédients utilisent les réservations, files de dépôt et animations déjà validées. Les matériaux livrés sont visibles sur l’établi. Un rappel pendant le transport restitue la charge selon les règles des chantiers ; pendant l’assemblage, il conserve les matériaux et le travail. Les lits gardent leur priorité d’approvisionnement.

Un habitant avec une torche ne reçoit pas de caisse et ne prend pas l’échelle. L’ancienne reconnaissance de la réserve orientale ignore les habitants déjà occupés par une torche. Le trajet choisi est vérifié avant départ, y compris le retour, le ralentissement dû aux besoins et la marge. Un chemin sans issue ou une autonomie insuffisante produit un refus expliqué.

Correction après essai du joueur : le choix de destination distingue désormais le sol, les deux plateformes et la passerelle. Cliquer le texte « Réserve inexplorée » cible son point de reconnaissance à l’étage. L’ordre avec torche est refusé avec l’explication des deux mains nécessaires à l’échelle, au lieu d’envoyer l’habitant sous la passerelle. `tests/destination_picking.gd` vérifie les surfaces, le texte, plusieurs rotations/zooms et le chemin complet de traitement du clic, puis un départ au sol valide.

Le combustible, la flamme portée, le vacillement et les petites braises utilisent l’horloge de simulation. Pause et x1/x2/x3 sont cohérents ; être hors caméra ne suspend pas la consommation. La fabrication et les sorties s’interrompent pour les besoins personnels et le rappel.

La réserve de sécurité est réévaluée pendant la marche et l’observation. Une route de retour bloquée produit une attente expliquée : aucun déplacement instantané. Si la torche s’épuise, l’habitant s’arrête. On peut envoyer un autre éclaireur près de lui ; une proximité éclairée et une ligne dégagée permettent le retour. Le compagnon accompagne alors automatiquement le résident, reste à proximité et le rejoint aux angles. Si son propre combustible s’épuise, l’attente reprend. La petite zone dégagée devant la torche fixe du refuge reste utilisable à l’arrivée.

## Assets et rendu

- Source de torche : `art_source/torches_16/hand_torch.blend`, générateur `tools/create_torch_assets.py`, export dans `assets/models/torches_16/`.
- Écharde en bois texturé, fibre enroulée et pointe carbonisée ; origine à la prise, attachée à `socket_tool`.
- Poses `torch_walk` et `torch_idle` créées dans Blender et ajoutées au GLB animé existant. La pose immobile sert à l’observation ; pas de troisième animation de fouille annoncée.
- Flamme déformée par shader, quatre petites braises, lumière Omni avec ombres. Icône SVG et jauge d’autonomie dans le panneau.
- La poussière existante reçoit désormais l’éclairage local, tout en conservant une faible visibilité ambiante.

Captures de contrôle dans `artifacts/torches/` : ensemble, main rapprochée, dos, zéro/une/quatre lumières. Main et sac vérifiés visuellement. Le test isolant la torche montre les ombres des habitants et des caisses : la contribution directe est occultée par ces géométries. La lumière ambiante et les effets de faisceaux préexistants restent présents ; ce n’est pas une simulation physique de toute la lumière indirecte.

Mesure indicative : Compatibility, GTX 1650, 1920 × 1080, VSync désactivée, caméra fixe, autres lumières masquées, 150 images après préchauffage. Zéro lumière portée : **9,96 ms/image** ; une : **10,22 ms** ; quatre : **12,22 ms**. Les torches conservent leurs ombres dans ce lot. Ce test de rendu isolé ne valide ni 30–50 habitants ni une grande carte. Avant d’augmenter ces cibles, remesurer et définir le budget des sources visibles ; ne pas supprimer les ombres en laissant les torches éclairer à travers les murs.

## Persistance et vérifications

Format **v6**, lecture conservée des versions v1–v5. Le point stable contient les torches rangées, leur emplacement et leur combustible, ainsi que les recettes inachevées, ingrédients livrés et avancement. Les anciennes parties n’obtiennent pas de torches gratuites. Les valeurs, positions de rangement, ateliers et doublons d’ordres actifs sont validés. La sauvegarde libre en expédition reste prévue à l’étape 6.

`tests/torches.gd` couvre la conservation pendant la fabrication, commande concurrente, coût, assemblage, équipement physique, refus d’échelle/caisse, autonomie aller-retour, pause/x3, marge, retour, besoin de boire, rappel pendant livraison et travail, v6, ancien format, données corrompues, reprise d’assemblage, obstacle ajouté, épuisement, assistance et retour complet à deux. Les suites existantes vérifient la non-régression des autres systèmes.

`tests/torches_visual.gd` produit les vues de jeu et les gros plans ; `tests/torches_render.gd` produit la comparaison lumineuse et les mesures dans `artifacts/torches/render-metrics.json`.

## Limites assumées

Un seul secteur, destination choisie au sol et observation simple : pas de brouillard de guerre, de découverte mémorisée ni de nouveau butin. Pas encore d’effet sur les insectes. Pas de lanterne de ceinture, de recharge en résine, de recyclage des torches épuisées ni de file de recettes générale. La prise et le rangement de la petite torche utilisent un changement d’attache au point d’interaction, sans animation dédiée de doigts. Le compagnon porte une lumière ; le transport de caisse accompagné dans une nouvelle zone sera traité avec la liaison des secteurs. La fissure de l’étape 5 n’est pas commencée.


## Décision après essai

Le joueur valide le lot corrigé et la progression torche à main → lanterne fermée de ceinture → éclairage fixe. La lanterne devient la prochaine démonstration (étape 4 bis), avant la fissure : elle permettra de grimper avec les mains libres, puis de transporter une caisse avec une lumière portée. Sa fabrication, son autonomie et son intégration restent à réaliser et feront l’objet d’une validation séparée.
