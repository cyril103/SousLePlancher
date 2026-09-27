# Lot 31 — 11B : première fourmi dans la cuisine

27 septembre 2026 — validé par le joueur, correction des animations comprise ; commit et push autorisés.

## Résultat et périmètre

Une fourmi ouvrière partage le biscuit avec les habitants. Elle attend près de son point de retour, rejoint la nourriture, cherche pendant trois secondes, prélève une miette libre et la rapporte physiquement. Elle recommence après quatorze secondes au nid tant que la source contient des miettes non réservées. Son activité commence après reconnaissance de la cuisine. Aucun nouvel insecte ni nouveau secteur.

Le joueur conserve la gestion indirecte : désigner la récolte du biscuit, puis choisir dans **Travaux → Accès cuisine** l’approche directe prudente ou le détour ouest. Le choix s’applique aux prochaines entrées dans la cuisine ; les trajets déjà engagés continuent. Le détour allonge le chemin et réduit le passage sur le trajet de la fourmi sans garantir une absence de rencontre.

Un habitant s’arrête à proximité de la fourmi, avant de la traverser pendant l’approche ou de poursuivre une récolte trop proche. Son compteur de travail n’avance pas pendant cette attente. Après huit secondes bloquées, il rentre ; la désignation subsiste. Les besoins, rappels et réserves de lumière gardent la priorité. Le retour d’une charge acquise conserve le contrat du lot 30.

## Perception et réaction

Rayon local de 3,3 unités, habitants visibles du secteur cuisine uniquement. Les segments de visibilité tiennent compte de trois volumes physiques fixes : nouvelle chute de plinthe dressée, chute au sol et biscuit. La plinthe dressée et ses limites de perception partagent les mêmes dimensions dans Blender et dans la simulation. Les routes locales contournent cette plinthe.

Lors d’une rencontre en recherche, prélèvement ou transport : orientation vers l’habitant, animation et libellé d’alerte pendant 1,6 seconde, puis repli vers le nid. Aucune poursuite ni morsure. La fourmi conserve sa miette lors d’un repli. Le joueur peut mettre en pause et utiliser **Observer la fourmi** pour rapprocher la caméra.

Cette première perception utilise des empreintes 2D adaptées aux obstacles fixes de cette poche ; elle ne constitue pas encore un système universel de perception en 3D. Les antennes ne simulent pas encore les phéromones. Le point de retour représente un nid hors champ de la simulation, pas une colonie de fourmis complète.

## Ressources et concurrence

Source partagée : les 36 provisions initiales du biscuit. Une miette est soustraite à la source uniquement au prélèvement, portée par la fourmi, puis ajoutée au compteur du nid au dépôt. Aucun vol à distance dans les dépôts humains. Les réservations existantes des habitants priment : la fourmi ne prélève jamais la part réservée, même si la réservation apparaît pendant son approche.

Le compteur du nid conserve le bilan des miettes retirées ; elles ne sont pas récupérables dans ce lot. Les aller-retour des habitants restent limités à deux missions et empruntent les files L01/L02 existantes. Le chantier du pont reste inchangé.

## Assets Blender

Référence : planche 03 du catalogue approuvé. Sources modifiables dans `art_source/ant_31`, exports dans `assets/models/ant_31`, génération reproductible par `tools/create_ant_assets.py`.

- Fourmi : tête, thorax, pétiole et abdomen ; six pattes à deux segments articulés, antennes coudées, mandibules dentées, yeux et soies fines.
- Armature avec pondération rigide par segment ; marche en trépied calculée puis enregistrée dans les animations.
- Quatre clips glTF : `search`, `walk`, `carry`, `alert`. Animation pilotée par le temps de simulation, cohérente avec pause, vitesses et reprise.
- Texture de chitine mouchetée intégrée ; miette portée séparée, visible uniquement quand elle existe dans le bilan.
- Chute de plinthe usée, texture de bois existante réutilisée, obstacle de perception visible.

Les assets constituent une première version intégrée à valider visuellement, pas une refonte générale de la direction artistique.

## Sauvegarde v18

Position, orientation, état, horloges, route, étape de route, charge, compteur du nid, rencontres et politique d’approche sont conservés. Les attentes des habitants font partie des tâches cuisine sauvegardées. Validation des types, bornes, routes et charges avant restauration.

Les sauvegardes v17 restent chargeables : une nouvelle fourmi est initialisée au point de retour, sans retirer de miettes du stock sauvegardé. Le rechargement reste en pause. Les versions antérieures conservent leurs migrations existantes.

## Démo à valider

Lancement : `-- --demo-ant`. Partie en pause, cuisine déjà reconnue, pont terminé et lanternes fournies pour isoler cet essai. Aucun ordre de récolte automatique.

1. Appuyer sur **Espace**, puis **Observer la fourmi** : recherche, prélèvement, miette aux mandibules et retour au nid.
2. Désigner la récolte : les habitants s’équipent et partent selon leurs priorités normales. Observer l’attente et, lors d’une rencontre assez proche, l’alerte et le repli.
3. Basculer l’approche vers le détour ouest pour les prochains trajets ; comparer le parcours.
4. **F5 / F9** pendant le portage de la fourmi ou l’attente d’un habitant : reprise exacte, en pause.
5. Arrêter la récolte pendant une rencontre : retour et libération des réservations, sans disparition de caisse.

## Vérifications

- `tests/ant.gd` : perception bloquée par la plinthe, portée locale, déclenchement et repli d’alerte, conservation source/charge/nid, réservations prioritaires, JSON exact en prélèvement/transport/repos/alerte, deux approches, rappel lors d’attente ou transport, charge invalide rejetée, migration v17.
- `tests/ant_visual.gd` : captures graphiques de recherche, prélèvement, transport, repos et interface sous Godot 4.7.2 Compatibility.
- Régressions `tests/kitchen.gd` et `tests/kitchen_edges.gd` : chantier approvisionné, collecte, charges, files, rappels et reprises.

## Limites et suite

Trajets locaux artisanaux, une espèce et un seul individu. Pas de combat, blessure animale, nid visitable, reproduction, élevage ou navigation procédurale. Les lanternes restent obligatoires pour les expéditions, indépendamment des rais de lumière décoratifs. Attendre le retour du joueur sur ce lot avant d’engager la suite de la roadmap.


### Correction après premier essai : pattes figées

Le lecteur Godot est désormais actif en mode manuel : les poses Blender sont appliquées au squelette à partir de l’horloge de simulation, sans progression pendant la pause. Les trajets de recherche, retour chargé, retour à vide et repli sélectionnent tous une animation de locomotion ; la recherche stationnaire conserve son animation d’antennes. `tests/ant_animation.gd` vérifie les rotations effectives des six pattes dans ces quatre situations et leur immobilité pendant la pause.
