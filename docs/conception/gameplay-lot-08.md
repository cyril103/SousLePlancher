# Lot 08 — Échelle et récolte sur le palier

Validation du joueur : « ok validé, commit et pousse ». Le lot est accepté avec la navigation au sol du lot 07 ; les limites détaillées ci-dessous restent prévues pour les prochaines étapes.

## Version jouable

La partie principale contient un palier en bois à 2,04 unités de hauteur, accessible par l’échelle du kit validé. Le second gisement de bois et le second gisement de fibres sont déplacés sur ce palier. Leurs affectations passent par les mêmes commandes que les autres ressources ; le menu et les étiquettes indiquent « Palier ».

Démonstration : lancer le projet avec `-- --demo-ladders`. Deux habitants récoltent en hauteur, deux autres continuent au sol. Les réserves et les règles de survie restent celles de la partie normale. H rappelle la colonie, puis permet la reprise des affectations ; N affiche le trajet du résident sélectionné. Le panneau Travaux indique l’occupation de l’échelle et le nombre d’habitants dans sa file.

## Déplacements et réservation

Chaque niveau possède son espace navigable et ses obstacles. Un trajet entre niveaux rejoint une place d’attente, puis l’entrée de l’échelle, franchit le passage et poursuit vers sa destination. Les parcours horizontaux contournent aussi les caisses de préparation du palier.

Une seule personne réserve le passage, montée et descente confondues. La priorité suit l’ordre d’arrivée dans la file. La réservation couvre l’approche, la traversée et le dégagement de la sortie. Un rappel retire un habitant en attente de la file. Pendant une traversée, le rappel est différé jusqu’à la sortie : pas de demi-tour sur les barreaux ni de téléportation au sol. Si la personne transporte déjà des matériaux, elle termine sa livraison avant de rentrer.

Le porteur redescend avant de demander une place au dépôt. Il ne peut donc pas immobiliser le déchargement des habitants restés au sol en attendant l’échelle. Les quantités réservées, prélevées et livrées restent gérées par le registre existant.

## Animation et rendu

Les clips Blender validés des lots 04 et 05 sont réutilisés. La montée dure 7,4 secondes de simulation et la descente 8 secondes. La vitesse de simulation accélère aussi la traversée ; la pause l’arrête complètement. L’amélioration de l’atelier accélère la marche, pas les gestes sur les barreaux.

Le déplacement de la racine du squelette est repris dans la position du personnage à la sortie. Les semelles reviennent à la surface du plancher à 0 ou 2,04 unités ; les déplacements ultérieurs conservent ce niveau.

La même caisse est portée dans le dos pendant la descente, puis replacée dans les mains à la sortie. Cette première intégration change directement le point d’attache : elle ne contient pas encore de geste spécifique pour attacher ou reprendre la caisse ni de sangle animée.

Nouveau modèle créé dans Blender : `assets/models/navigation_08/resource_landing.glb`. Source éditable : `art_source/navigation_08/resource_landing.blend`. Générateur reproductible : `tools/create_ladder_platform.py`. Le modèle comprend planches texturées, supports, clous et garde-corps en corde avec ouverture pour l’échelle. L’échelle et les personnages existants sont réutilisés.

## Construction et limites

Le palier est préinstallé pour ce lot. Son emprise au sol reste inaccessible ; le passage sous la structure n’est pas encore simulé. La construction ne peut occuper le palier, le pied de l’échelle ou les places d’attente, ni couper l’accès aux ressources. Un nouvel abri nécessite aussi une place d’attente accessible sur le palier pour son nouvel habitant.

Il s’agit d’un passage entre deux niveaux fixes. La pose libre d’échelles, plusieurs passages alternatifs, les ponts et les portes restent à intégrer. L’évitement dynamique général entre piétons reste la limite du lot 07 ; l’échelle, elle, impose un passage exclusif. Les changements d’attache de la caisse devront recevoir une animation dédiée avant une finition artistique définitive.

## Vérifications

- `tests/ladders.gd` : récolte et livraison réelles sur les deux niveaux, attente, un seul grimpeur, ordre FIFO, descente chargée sans verrouiller le dépôt, contact des deux semelles à chaque sortie, rappel collectif et annulation pendant une traversée, reprise, pause, nettoyage des réservations et protection du palier contre la construction.
- `tests/ladders_visual.gd` : captures réelles de montée, récolte et descente dans `artifacts/ladders/`. Les réserves de cette capture de contrôle sont augmentées ; celles de la démonstration jouable ne le sont pas.
- Régressions : navigation, livraisons, boucle économique, affectations par événements souris et commandes de l’interface Atelier miniature.

## Suite proposée après retour

Intégrer les portes du refuge : ouverture réservée, franchissement réel, position intérieure puis sortie et reprise du travail. Conserver les règles de rappel et de transport éprouvées ici, avant d’étendre les trajets aux ponts et à plusieurs zones explorables.
