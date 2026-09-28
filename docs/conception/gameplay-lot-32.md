# Lot 32 — Étape 11C : parcours guidé

Livraison validée par le joueur le 28 septembre 2026 ; commit et push autorisés.

## Résultat jouable

Une nouvelle partie ouvre le panneau Objectifs. Dix étapes relient le premier lit, l’atelier, la lanterne, l’inspection, l’étaiement, l’alcôve, l’élargissement, la reconnaissance cuisine, le pont et le retour des provisions. La prochaine action explique la commande et son coût ; le bouton ouvre le panneau concerné. Les étapes peuvent être réalisées dans un autre ordre. Aucun ordre de construction ou d’expédition n’est exécuté par le guide.

La réussite du retour exige une livraison réelle au dépôt. La source finie de 36 provisions, le stock et la charge de la fourmi ainsi que les caisses cuisine en transit permettent de retrouver le nombre livré, même après consommation des provisions au refuge. Aucun champ de sauvegarde supplémentaire : le format v18 reste inchangé. Une caisse rappelée reste comptée en transit jusqu’à la livraison.

L’aide F5 décrit désormais la sauvegarde sur place, au lieu de l’ancien rappel préalable au refuge. La colonie continue après les objectifs. Un biscuit épuisé sans livraison affiche une explication et la possibilité de reprendre une sauvegarde antérieure.

## Essai

Lancer normalement, cliquer « Fonder la colonie », puis suivre le panneau. O le rouvre. Construire un lit, puis utiliser le bouton de prochaine action. F5/F9 conserve la progression réelle. Les coûts restent ceux des mécaniques existantes ; récolter les ressources manquantes et libérer des habitants de leurs affectations si nécessaire.

## Vérifications

- `tests/chapter.gd` : nouvelle partie sans étape fictive, bouton vers la construction, prélèvement animal non crédité, vraie expédition cuisine, caisse en transit non créditée, sauvegarde JSON en trajet, rappel chargé et progression après livraison/rechargement.
- `tests/smoke.gd` : boucle existante, panneaux, récolte, construction, rappel et défaite.
- `tests/chapter_visual.gd` : capture du panneau en rendu Compatibility, `artifacts/chapter_goals.png`.

## Limites

Ce lot livre le guidage de 11C. Il ne valide pas encore l’équilibrage du parcours complet depuis zéro sur 20–30 minutes. Les tests d’expédition utilisent la préparation cuisine existante ; une recette intégrale sans démo reste nécessaire avant de déclarer 11C terminée. Le guide ne recharge pas les lanternes et n’ajoute ni ressources ni automatisation de l’exploration de l’alcôve. Les étapes reflètent les équipements présents : retirer un lit peut rendre son étape à nouveau incomplète.
