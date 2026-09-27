# Lot 20 — Des fibres de l’alcôve pour un lit (6B)

27 septembre 2026. **Validé par le joueur ; commit et push autorisés.**

## Boucle jouable

Après reconnaissance de l’alcôve à la lanterne, le joueur élargit la fissure, envoie un porteur chercher des fibres et les reçoit dans un dépôt du secteur refuge. Les fibres deviennent immédiatement disponibles pour les chantiers existants : un lit peut ainsi être terminé avec la livraison distante.

Le panneau **Travaux → Fissure et passage** contient les commandes d’équipement, de reconnaissance, d’élargissement et de transport. La mission **Rapporter des fibres de l’alcôve** effectue un seul aller-retour. Elle ne crée pas d’affectation automatique permanente.

## Élargissement physique

Coût fixé pour ce lot : **6 bois et 4 fibres**, livrés par les porteurs, puis **24 secondes** de travail. La première ouverture du lot 18 reste nécessaire et son coût est distinct. La reconnaissance 6A est également nécessaire.

Le chantier d’élargissement utilise la logistique existante : réservation, retrait au dépôt, transport, livraison et incorporation. Il ferme le passage aux expéditions et ne peut commencer tant qu’un visiteur y est engagé. Une annulation laisse les matériaux livrés à récupérer et conserve le passage étroit initial. Un chantier partiel est sauvegardé et reprend sans payer deux fois les ingrédients.

Le cadre et les étais sont remplacés à l’achèvement par des modèles Blender à ouverture plus large. Le contrat d’accès annonce alors 1,8 m de largeur utile et autorise les caisses. Avant achèvement, la variante étroite reste visible et la récolte distante est refusée. Le seuil reste réservé à une personne à la fois, dans les deux sens.

## Fibres, réservations et livraison

- Une source finie de **24 fibres** dans l’alcôve, avec le modèle de fibres existant. Elle ne se renouvelle pas au changement de cycle.
- Une caisse contient jusqu’à `3 + nombre d’ateliers` unités, limitée par les fibres libres et les places disponibles au dépôt.
- Au départ, la quantité dans la source et la place au dépôt sont réservées ensemble. Un départ refusé ne consomme ni ne réserve de ressource.
- Trois secondes de préparation, puis prise animée. Les fibres quittent la source au moment où la caisse rejoint les mains ; elles ne sont pas déjà disponibles dans les stocks.
- Retour avec caisse, lanterne allumée et animation de portage, puis attente du poste de dépôt et dépose animée. La place réservée devient du stock à l’événement de dépose.
- Un rappel avant prélèvement libère les réservations et ramène le personnage à vide. Après prélèvement, la charge est conservée et livrée avant le retour au refuge. Les besoins urgents suivent la même règle.
- Dépôt plein ou aucun dépôt accessible : départ refusé. Si le dépôt devient inaccessible pendant la mission, la livraison cherche une autre destination acceptant toute la charge. Sans solution, elle garde caisse et réservation et indique l’accès bloqué ; elle reprend après dégagement.
- L’autonomie au départ comprend collecte, retour, détour vers le dépôt et marge. Le retour anticipé pour combustible reste actif avant prélèvement.

Le prélèvement et la dépose utilisent les animations et la caisse existantes. Les réservations distantes ont leurs propres identifiants ; elles utilisent les mêmes capacités et files de dépôts que les autres transports.

## Connaissance et sauvegarde

Le modèle de la source n’est visible qu’en présence d’un observateur éclairé. Le panneau affiche la dernière quantité observée et les réservations de la colonie. Le décor reconnu reste mémorisé comme en 6A.

Le **format v9** ajoute l’état du chantier d’élargissement, la quantité de fibres distante et la dernière quantité connue. Une sauvegarde v8 conserve son passage étroit et reçoit une source initiale de 24 fibres ; les formats antérieurs restent pris en charge. La validation refuse notamment un élargissement sans matériaux ou une source prélevée sans passage élargi.

**F5 rappelle toujours tous les habitants et attend la livraison des charges puis le retour au refuge.** Aucune sauvegarde libre en pleine expédition n’est ajoutée ici : c’est le périmètre de 6C.

## Assets Blender

- Générateur reproductible : `tools/create_wide_passage_assets.py` (Blender 2.93).
- Sources : `art_source/passage_20/wide_frame.blend`, `wide_braces.blend`.
- Exports et textures : `assets/models/passage_20/`.
- Réemploi : alcôve du lot 19, habitant animé, caisse, fibres et lanterne. Pas de nouvelle famille de ressources ou de refonte artistique.

## Démo validée

Lancer avec `-- --demo-alcove-haul`. La préparation simule reconnaissance, élargissement et livraison du bois au lit. Les stocks de préparation et la lanterne fournie sont propres à la démo.

La démo s’ouvre **en pause**, avec H1 équipé, le passage élargi et un lit qui possède ses quatre bois mais attend trois fibres. Cliquer **Rapporter des fibres de l’alcôve**, puis **Espace**. Le porteur revient, livre et un habitant approvisionne puis termine le lit. **Suivre H sélectionné** permet d’observer le voyage ; les flèches rendent la caméra libre.

La sauvegarde de démo est séparée : `user://saves/alcove_haul_demo.json`. La partie normale garde son fichier.

## Vérifications réalisées

Godot 4.7.2, zéro échec :

- `tests/passage_upgrade.gd` : refus avant reconnaissance, conservation des ingrédients, fermeture pendant chantier, annulation/récupération, sauvegarde partielle, reprise et gabarit final.
- `tests/alcove_haul.gd` : lit rendu possible par la livraison ; total source + charges + stocks + chantiers constant ; deux porteurs concurrents ; dépôt plein ; faible autonomie ; rappel avant/après prise ; soif urgente ; dépôt bloqué puis réouvert ; dernière caisse partielle ; sauvegarde v9 et migration v8.
- Non-régression : `tests/alcove.gd`, `tests/fissure.gd`, `tests/checkpoint.gd`, `tests/lanterns.gd`, `tests/construction.gd`.
- `tests/alcove_haul_visual.gd` : captures inspectées de la démo, du passage chargé et du lit terminé, dans `artifacts/alcove_haul/` (non versionné).

## Suite

Prochaine livraison : **6C, sauvegarde et reprise en expédition**. Pas d’insecte, de nouvelle zone, de génération procédurale ni de nouvelle ressource avant la clôture de cette boucle.
