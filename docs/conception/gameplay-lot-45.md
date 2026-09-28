# Lot 45 — Reconnaissance autonome de l’alcôve

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Commande joueur

Après l’ouverture du passage, **Fissure du plancher → Désigner la reconnaissance** enregistre la sortie sans choisir d’habitant ni équiper manuellement sa lanterne. Le chapitre ouvre ce panneau à l’étape Explorer l’alcôve.

Un habitant libre et reposé, sans affectation de récolte, prend la tâche selon sa priorité **Récolte**. Un seul éclaireur automatique est engagé. Il réserve une lanterne accessible et suffisamment chargée, la récupère physiquement, puis traverse et observe l’alcôve. Le calcul préalable comprend le trajet depuis l’équipement et une marge de retour ; le départ est revérifié après la prise de la lanterne. Une torche ou une lanterne en entretien ne peut pas servir à cette sortie.

La désignation attend si le passage, l’habitant ou l’équipement n’est pas disponible. Les besoins restent prioritaires. H rappelle l’éclaireur et conserve l’ordre, qui peut reprendre après le rappel. **Annuler et rappeler l’éclaireur** retire l’ordre ; une traversée engagée se termine avant le retour. L’habitant rapporte et range sa lanterne au refuge, sans remplacement ni duplication.

La première reconnaissance termine l’ordre. Elle ne prélève pas de fibres, ne commande pas l’élargissement et ne désigne pas la cuisine. Les commandes manuelles restent accessibles. Les sorties cuisine conservent leur place dans l’arbitrage existant ; cette reconnaissance passe avant la récolte locale à priorité Récolte égale.

## Sauvegarde et essai

Le format **v27** conserve la désignation et l’identité de l’éclaireur, avec les missions, réservations et combustible existants. Les sauvegardes antérieures restent lisibles, avec la reconnaissance automatique désactivée par défaut et les missions manuelles conservées.

Démo `-- --demo-auto-scout` : passage ouvert et lanterne fournie pour l’essai, rangée au refuge, ordre désigné et simulation en pause. Espace lance la prise de tâche. Essayer H puis H ou annuler pendant la sortie ; F5/F9 reprend la situation sur place. La démo utilise un fichier utilisateur distinct. Dans la partie normale, l’atelier doit fabriquer la lanterne avec ses matériaux habituels.

## Vérifications

- `tests/auto_scout.gd` : passage fermé, priorité désactivée, combustible insuffisant, attribution, sauvegarde en attente/à la réservation/pendant traversée, annulation pendant équipement et traversée, reprise après rappel, rangement unique, absence de prélèvement, migration v26 et validation de l’identité.
- `tests/auto_scout_visual.gd` : panneaux en attente et après reconnaissance, captures `artifacts/harvest_targets_auto_scout_*.png` contrôlées.
- Régressions : `tests/inspection_designation.gd` et `tests/lanterns.gd`.
- `tests/chapter_campaign.gd -- --auto-scout` : parcours normal avec récoltes, production, entretien, inspection et reconnaissance désignés. Le joueur scripté commande toujours les constructions, l’ouverture et les travaux de cuisine. Besoins, passages humains et rechargement d’une expédition chargée restent actifs.

Résultat : dix étapes atteintes à **696,7 secondes simulées**, avec deux lanternes, deux rappels et un maximum de 54,72 soupçons. Cette durée caractérise le joueur scripté ; l’évaluation humaine de l’équilibrage reste ouverte.
