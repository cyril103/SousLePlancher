# Lot 09 — Porte et intérieur du refuge

État : validé par le joueur (« ok validé, commit et pousse »), publication autorisée. Ce lot prolonge les lots 07 et 08 validés ; il ne constitue pas encore le système complet d’habitation modulaire.

## Comportement jouable

Le refuge principal remplace son ancien bloc décoratif par une pièce de 2 × 3 unités, assemblée avec les modèles Blender du kit validé : sol, murs, fenêtre, encadrement et vantail indépendant. Six places intérieures sont desservies par une allée centrale. Le débattement de la porte reste libre.

Un rappel collectif conserve les affectations. Chaque habitant termine sa livraison s’il transporte déjà une caisse, rejoint sa place d’attente extérieure, réserve la porte puis traverse le seuil et rejoint sa place intérieure. La porte s’ouvre avant le franchissement et se referme lorsqu’aucun passage ne la réserve. Une seule personne utilise l’accès à la fois ; la priorité suit l’ordre d’arrivée, entrées et sorties confondues.

« Ressortir » libère également les habitants sans affectation. Ils franchissent réellement la porte et rejoignent le réseau de navigation extérieur. Ceux qui ont une affectation reprennent leur tâche. Un rappel individuel retire l’affectation et laisse la personne à l’intérieur jusqu’à une nouvelle affectation ou un ordre collectif de sortie.

Changer d’ordre pendant un franchissement ne provoque pas de téléportation ni de demi-tour au milieu du seuil : le passage en cours est achevé, puis le nouvel ordre est appliqué. Un habitant encore dans une file peut en être retiré immédiatement.

## Protection et capacité

Le statut « À l’abri » correspond maintenant à une présence réelle à l’intérieur. Attendre près du bâtiment ne protège plus automatiquement des humains. Les files et la porte ajoutent du temps au rappel ; le joueur doit anticiper leur passage. La livraison préalable des charges est conservée.

Le refuge de cette première carte accepte six habitants, ce qui couvre les deux recrutements de la boucle de victoire actuelle. Un abri supplémentaire est refusé avant paiement lorsque ces six places sont occupées. Le message explique que le refuge est complet. L’agrandissement et la distribution des habitants entre plusieurs refuges seront nécessaires avant une population plus importante.

L’emprise du refuge, sa porte et les accès extérieurs sont protégés contre les nouvelles constructions. La navigation extérieure contourne les murs ; seul le contrôleur de porte est autorisé à traverser l’encadrement. Les places intérieures ne sont pas utilisées comme des destinations de navigation extérieure.

## Animation, visibilité et commandes

- La marche animée existante accompagne l’entrée et la sortie. Une petite correction de hauteur permet de franchir le seuil de 0,05 unité sans enfouir les pieds.
- Le vantail est animé sur son gond selon le temps de simulation. Pause et vitesses de jeu s’appliquent à la porte comme aux habitants.
- Le mur latéral passe en vue en coupe au début d’un franchissement. **V** permet ensuite de masquer ou réafficher ce mur ; cela ne change pas les collisions ou la protection. La porte et son cadre restent visibles.
- Le panneau Travaux affiche les habitants à l’abri et la file de la porte. La fiche de chaque habitant indique l’attente, l’entrée, la sortie ou la présence à l’abri.
- Démonstration : lancer le projet avec `-- --demo-doors`. Les quatre habitants ont une tâche et rentrent au refuge. **H** permet de les faire ressortir et de constater la reprise. **V** règle la coupe, **C** ouvre les affectations.

## Livrables et contrôles

Le nouveau contrôleur visuel et de réservation est `scripts/refuge_access.gd`. Les parcours et interruptions sont intégrés à `worker_delivery.gd`, la protection à `game.gd`, et les statuts à `atelier_ui.gd`. Aucun nouveau modèle ou texture n’est généré : les GLB approuvés de `reference_01` et `refuge_02` sont réutilisés.

`tests/doors.gd` vérifie six entrées et sorties, la réservation exclusive avec porte ouverte, la fermeture finale, les places distinctes, la sortie sans affectation, les changements d’ordre pendant entrée et sortie, la pause, la livraison avant rappel, la reprise des tâches, la protection effective et le refus de construction devant l’accès ou au-delà de la capacité.

Les suites navigation, livraison, économie, interface, affectations par événements souris et échelles restent utilisées. Les tests qui supposaient un retour immédiat sur une place extérieure attendent désormais un franchissement réel et une place intérieure. Le test économique autorise une exposition transitoire pendant la file, tout en vérifiant que le rappel évite la découverte et ramène tout le monde à l’abri.

`tests/doors_visual.gd` produit les captures réelles d’entrée, d’intérieur et de sortie dans `artifacts/doors/`. Seule cette capture augmente les réserves alimentaires pour le contrôle ; la démonstration conserve l’économie normale.

## Limites et suite

La pièce est présentée sans toit et avec une coupe latérale pour rendre l’intérieur lisible. L’aménagement fonctionnel, les lits, le repos, la répartition entre bâtiments et la construction modulaire ne sont pas inclus. Les petits abris construits restent les bâtiments de recrutement existants ; la porte jouable de ce lot est celle du refuge principal.

Il n’y a pas encore de geste spécifique de la main sur la poignée : l’ouverture est automatique à l’approche réservée. Le système global d’évitement entre piétons reste celui des lots précédents ; l’accès de la porte est réservé, mais les croisements ordinaires à l’extérieur ne sont pas des collisions dynamiques.

Après revue : raccorder la passerelle validée à une nouvelle petite zone de ressources, puis étendre les accès à plusieurs connexions et introduire les premières contraintes d’exploration. Les besoins des habitants et l’aménagement intérieur restent des lots séparés à équilibrer.
