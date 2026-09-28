# Lot 36 — Réserve automatique de lanternes et annulation

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Commandes

**Travaux → Éclairage et éclaireurs → Entretien des lanternes** ouvre le panneau dédié. La réserve souhaitée va de 0 à 8. Une lanterne prête est rangée, non réservée, éteinte et pleine (180 secondes). Les lanternes portées ne comptent pas dans cette réserve.

Si la réserve est insuffisante, un ordre de ravitaillement est créé sur la lanterne rangée admissible la moins chargée. Un seul entretien à la fois, selon les mêmes règles que le lot 35 : atelier requis, deux bois livrés, huit secondes de travail, priorités Transport et Construction. Le système entretient les équipements existants, sans en fabriquer automatiquement. Les raisons d’attente sont affichées : atelier absent, équipement non disponible, matériaux ou porteur attendus.

- **Réserve 0** désactive les prochains entretiens et laisse terminer le travail engagé.
- **Commander un plein** conserve la commande manuelle.
- **Annuler l’entretien et désactiver l’auto** arrête le travail, libère la lanterne et empêche la recréation immédiate de l’ordre. Le combustible initial reste inchangé. Le bois déjà livré forme un tas récupérable ; les charges en route retournent au dépôt. Le bois réservé mais non pris est libéré.
- **H** suspend les sorties et donc les nouveaux entretiens ; la reprise autorise de nouveau l’automatisme.

Un objectif trop élevé attend que les lanternes reviennent ou que le joueur en fabrique. Aucun combustible n’est créé gratuitement. L’objectif n’est pas un quota global de bois : les pleins continuent à coûter deux bois chacun.

## Sauvegarde v21

L’objectif est sauvegardé avec les ordres et les charges. Les traces des ordres annulés sont conservées pour garder stables les références aux travaux, mais ne peuvent plus produire de plein. Validation du seuil, des états annulés et des cibles. Les versions antérieures restent chargeables avec l’entretien automatique désactivé par défaut. Les versions précédentes du jeu ne lisent pas les sauvegardes v21.

## Démonstration

`-- --demo-auto-refills` prépare deux lanternes à ravitailler, six bois, un atelier et l’objectif 2, en pause. Espace livre puis entretient les deux lanternes ; il reste deux bois quand elles sont pleines. Modifier l’objectif pendant le travail ou annuler permet de comparer les comportements. F5/F9 conserve les réglages et la situation. Fichier de sauvegarde distinct de la partie normale.

## Vérifications

- `tests/automatic_refills.gd` : commande UI, réserve exacte, absence de fabrication, arrêt au seuil, reprise, désactivation, JSON pendant entretien, migration v20, seuil invalide, annulations avant prise/en charge/pendant travail, sauvegarde immédiatement après annulation et récupération exacte du bois.
- `tests/lantern_refill.gd` : plein manuel, coût, interruptions, protection de l’équipement et migration.
- `tests/transfer_limits.gd` : quotas de transfert et anciennes sauvegardes toujours fonctionnels.
- `tests/chapter_campaign.gd -- --auto-refills` : parcours normal complet avec deux lanternes fabriquées et entretenues automatiquement. Dix objectifs atteints, rechargement d’une caisse en trajet, 522,1 secondes simulées, un rappel, soupçons maximaux 64. Le script fabrique les deux lanternes par commandes ordinaires ; l’automatisme du jeu ne les crée pas. Cette durée ne prédit pas une première partie humaine.
- `tests/automatic_refills_visual.gd` : panneau et réserve atteinte en rendu Compatibility, captures `artifacts/lantern_refill_automatic_*.png`.

Pas de nouvel asset ni de nouvelle ressource. L’animation de travail générique reste celle du lot 35.
