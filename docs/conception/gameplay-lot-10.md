# Lot 10 — Passerelle et reconnaissance de la réserve de l’Est

État : validé par le joueur (« je valide et tu peux commit et pousser »), publication autorisée. Suite du lot 09 validé.

## Boucle jouable

Une passerelle relie le palier existant à une seconde plateforme de 3 × 3 unités. La structure est visible, mais le contenu de la réserve reste inconnu. Dans **Travaux [T]**, « Explorer la réserve de l’Est » envoie un habitant disponible, sans affectation ni charge. Une seule reconnaissance peut être active. Un habitant disponible à l’intérieur du refuge commence par sortir par la porte.

L’éclaireur emprunte l’échelle puis la passerelle et observe la réserve pendant trois secondes de simulation. La découverte révèle un gisement de **90 unités de bois**, sa caisse de préparation et son entrée dans le menu d’affectation. La reconnaissance ne prélève aucune ressource et ne crédite pas les stocks. L’éclaireur revient ensuite au refuge ; le joueur peut l’affecter de nouveau lorsqu’il est disponible.

Après découverte, une affectation de récolte fonctionne comme ailleurs : réservation du gisement, préparation et prise de la caisse, passerelle, descente d’échelle puis dépose au dépôt. Le gisement est fini et utilise le matériau bois existant. Il n’introduit pas encore de ressource ou de recette nouvelle.

La reconnaissance est interdite pendant un rappel collectif. Un rappel avant la fin de l’observation annule la mission sans révéler la réserve ; le joueur peut la relancer. Si un passage d’échelle, de porte ou de passerelle est engagé, il se termine avant le retour. Une découverte acquise reste disponible pendant le reste de la partie, y compris après rappel et sortie.

## Traversée et navigation

La passerelle ne laisse passer qu’un habitant à la fois, chargé ou non, avec une file commune aux deux sens. La réservation commence à l’approche et se libère une fois arrivé sur la plateforme opposée, à distance du bord. Des places d’attente sont définies de chaque côté. Les rappels retirent les personnes en attente ou diffèrent l’annulation jusqu’à la fin d’une traversée engagée.

Les trois espaces navigables restent séparés : sol, palier principal et réserve orientale. Les chemins combinent des parcours horizontaux locaux et les connexions contrôlées d’échelle et de passerelle. Les habitants ne peuvent pas couper directement à travers le vide entre plateformes. La grille de navigation utilise maintenant les limites propres à chaque espace, y compris à l’est de la carte initiale.

Le tablier de la passerelle et les plateformes sont alignés à la hauteur 2,04. La traversée réutilise les cycles de marche et de portage, à 1,2 unité par seconde de simulation. Pause et accélération du jeu s’appliquent au passage. Les caisses restent dans les mains sur le pont, puis passent dans le dos sur l’échelle selon la règle du lot 08.

## Assets Blender et interface

Le modèle `refuge_02/bridge_2m.glb` validé est réutilisé. Deux variantes de plateforme sont créées dans Blender, avec des ouvertures latérales correspondant au pont :

- `assets/models/exploration_10/landing_connected.glb` remplace le palier principal dans la partie ; son ouverture d’échelle est conservée.
- `assets/models/exploration_10/east_store_platform.glb` forme la réserve orientale.
- Sources éditables dans `art_source/exploration_10/`, générateur `tools/create_exploration_platforms.py`, matériaux de la famille existante. Les anciens assets et scènes de revue restent disponibles.

Le panneau Travaux contient la commande de reconnaissance, son état, puis le statut découvert. Le résumé des travaux est placé dans une zone défilante pour conserver l’accès aux boutons. Il affiche aussi l’occupation et l’attente de la passerelle. La fiche de l’habitant indique exploration, traversée, attente ou blocage d’accès. Le sélecteur des ressources désactive la réserve tant qu’elle est inconnue.

## Essai et contrôles

Démonstration : lancer le projet avec `-- --demo-exploration`. Un éclaireur part reconnaître les lieux tandis que trois habitants récoltent les ressources connues. L’économie reste normale. **T** ouvre les travaux, **C** les affectations, **H** rappelle ou fait ressortir la colonie et **N** affiche le trajet sélectionné. Le joueur affecte lui-même un porteur au gisement après découverte.

`tests/exploration.gd` vérifie : impossibilité d’affecter une ressource inconnue, mission unique, passage échelle/pont, pause, rappel pendant la traversée, annulation avant révélation, nouvelle reconnaissance, déblocage des affectations, transport chargé avec un porteur opposé, exclusivité et attente, hauteur sur le pont, crédit unique au dépôt et nettoyage des accès. Un test de réservation vérifie également l’ordre FIFO. Le second porteur est placé sur le palier par le scénario de test pour provoquer un croisement opposé.

Les sept suites précédentes restent vérifiées : navigation, livraison, économie, clics d’affectation, interface, échelles et portes. Le test économique distingue désormais six gisements connus et une réserve à découvrir. Les captures de `tests/exploration_visual.gd`, dans `artifacts/exploration/`, montrent la zone inconnue, une traversée et la découverte ; seules ces captures augmentent les réserves pour leur contrôle.

## Limites et suite

Cette zone est fixe et son pont est déjà installé. Il s’agit d’une première boucle de reconnaissance et d’ouverture de ressource, sans brouillard de guerre général, génération procédurale, sauvegarde persistante, coût de réparation ou construction libre de pont. La fin de partie de la colonie reste celle du prototype ; la nouvelle réserve est une possibilité supplémentaire, pas une condition de victoire.

Les réservations protègent les accès étroits, mais l’évitement physique global entre piétons sur les plateformes reste à développer. La reconnaissance réutilise l’attente animée existante, sans clip spécifique de fouille ni sac d’expédition.

Après retour : transformer les connexions en données réutilisables pour plusieurs zones, puis introduire une première découverte utile à la progression (matériau, outil ou savoir-faire). La sauvegarde des zones découvertes devra précéder l’exploration durable d’une carte plus grande.

La persistance préalable à l’extension de la carte est traitée dans [le lot 11 — sauvegarde au refuge et reprise](gameplay-lot-11.md).
