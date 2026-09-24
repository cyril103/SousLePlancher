# Lot 07 — Navigation au sol

Première passe implémentée, à examiner en jeu. Elle poursuit la prochaine étape prévue dans le lot 06 après validation de l’interface Atelier miniature et du correctif des affectations. Les échelles restent le lot suivant.

## Changements jouables

- Les habitants cherchent un chemin autour des bâtiments, des gisements, des torches, de la bobine, des boutons et des supports de chargement. Les raccourcis conservent une marge autour des volumes et ne traversent pas les coins.
- Chacun dispose d’une place distincte devant le refuge et d’une place d’attente accessible près du dépôt. Le rappel conserve les affectations et termine le transport des charges déjà prises.
- Le dépôt sert les porteurs dans l’ordre de leurs demandes, sans privilégier leur numéro. Le poste reste réservé jusqu’à la fin du redressement après dépose.
- Une construction ne peut pas recouvrir un habitant ou une place réservée, ni couper les accès aux ressources, au dépôt, aux places du refuge et aux habitants. Un refus ne consomme aucun matériau. Les chemins sont recalculés après une construction acceptée.
- Un trajet impossible affiche sa raison dans la fiche et la liste des habitants. Le panneau Travaux compte les trajets bloqués.
- **N**, ou le bouton du panneau **Travaux**, affiche le chemin restant du résident sélectionné. Le tracé est masqué par défaut dans une partie normale.

## Démonstration

Lancer avec `-- --demo-navigation`. Un atelier est construit au centre avec son coût normal, les quatre habitants reçoivent des tâches et le tracé du premier habitant est activé. Les stocks initiaux et les règles de survie restent ceux du jeu. Observer le contournement, rappeler avec **H**, puis utiliser **Ressortir**. Cliquer sur un habitant pour suivre son trajet ; **N** masque ou affiche le tracé.

La partie normale ne reçoit aucun bâtiment ni aucune affectation supplémentaire.

## Architecture et contraintes

`scripts/ground_navigation.gd` utilise A* sur une grille XZ de pas 0,25. Les empreintes rectangulaires suivent les dimensions des modèles Blender. La marge autour des volumes principaux est de 0,27. Les petits supports bas utilisent une marge de pied de 0,08 afin de conserver la position de contact des animations validées : les bras et les caisses passent au-dessus de leur bord.

Les positions exactes sont reliées à la grille par des segments libres. Un objectif bloqué ne provoque ni téléportation ni arrivée fictive avec un chemin partiel. La simplification vérifie chaque raccourci. Les obstacles existent aussi dans les tests sans rendu.

Chaque habitant conserve son chemin et son indice courant. Un changement d’état, de destination ou de version de navigation déclenche un recalcul. Les recherches infructueuses au gisement sont réessayées au plus une fois par seconde de simulation, ou après une modification des obstacles. La marche reste synchronisée sur la distance parcourue ; les rotations en déplacement deviennent progressives.

Les contrôles de connectivité d’un bâtiment précèdent le paiement. L’aperçu vert vérifie l’emprise locale ; une coupure d’accès détectée lors du clic produit un message explicatif.

## Blocages et ressources

Avant la prise, un trajet devenu impossible libère la réservation et laisse les ressources dans le gisement. Après la prise, le porteur conserve sa caisse et attend une possibilité de livraison : aucune ressource n’est créditée prématurément ni supprimée. Un porteur incapable d’atteindre le dépôt ne conserve pas le poste ou une place bloquante dans sa file logique. La réouverture permet la reprise.

Le statut « À l’abri » correspond aux places de rassemblement protégées devant le refuge. Il remplace l’empilement des personnages au centre du modèle. L’intérieur jouable et le franchissement réel des portes restent à réaliser.

## Vérifications

- `tests/navigation.gd` : détours, angles, destination exacte, régions séparées, mouvements réels sans traversée d’obstacle, livraison de tous les porteurs, rappel, blocage/réouverture sans perte de ressources, nettoyage des réservations, file FIFO et refus d’une construction fermant le dernier passage.
- `tests/live_assignments.gd` : vrais événements souris avec rafraîchissements entre appui et relâchement, affectation générale/ciblée, mouvement, libération et cycles de rappel/sortie.
- `tests/delivery.gd` : réservation, prise/dépose, conservation de la caisse, pause et nettoyage ; le retour vise désormais la place accessible du résident.
- `tests/smoke.gd` : économie, construction, recrutement, rappel, victoire et défaites. Les emplacements de construction évitent désormais les habitants et les zones de service.
- `tests/atelier_ui.gd` : commandes, rappel individuel, vitesses, population et dimensions de fenêtre.
- `tests/navigation_visual.gd` : captures réelles dans `artifacts/navigation/` montrant le contournement, les travaux et le rappel. Ces captures de contrôle utilisent une réserve alimentaire augmentée ; la démonstration jouable ne le fait pas.

## Limites et prochaine étape

Ce lot traite les obstacles statiques et les places d’attente. L’évitement physique entre habitants en mouvement n’est pas encore simulé : leurs chemins peuvent se croiser et un passant peut traverser la place d’un résident immobile. Les places finales sont distinctes, mais ne sont pas des collisions dynamiques.

Les empreintes sont conservatrices et les très petits gravats restent franchissables. Les rotations au contact de prise/dépose gardent les contraintes des clips existants. Il n’y a pas encore de démolition ni de modification du terrain par le joueur ; les tests simulent ces coupures d’accès.

Après revue : réservation et traversée des échelles avec les animations validées, points d’attente de chaque côté, puis raccords entre parcours horizontaux et verticaux. Rééquilibrer ensuite les temps de transport sur plusieurs cycles.

La poursuite autorisée par le joueur est détaillée dans [le lot 08 — échelle et palier](gameplay-lot-08.md).
