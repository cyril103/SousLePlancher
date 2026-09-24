# Lot 14 — Matériaux transportés jusqu'aux lits

Étape 2 de la [roadmap](roadmap-production.md). **Validée par le joueur (« tu peux valider ») ; commit et push autorisés.** La révision documentaire précédente a été validée et publiée dans `058345b`.

## Examiner le résultat

Lancer la démo préparée avec :

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64.exe' --path . -- --demo-construction
```

Elle commence en pause, avec un lit, une alcôve et des réserves volontairement insuffisantes pour les deux. **Espace** lance les déplacements. Un porteur prend une caisse au dépôt, rejoint le chantier et la dépose. Le lit se fabrique seulement lorsque ses 4 bois et 3 fibres sont sur place. L'alcôve attend la suite : affecter des habitants au bois et aux fibres permet de la terminer.

**Construire → Gérer les couchages** affiche les quantités livrées et l'état de chaque chantier. **T** ouvre le suivi des travaux et l'accès aux couchages. **Annuler** libère l'emplacement ; les matériaux déjà livrés restent sous forme de tas à récupérer, tandis qu'une charge en route revient au dépôt. **H** rappelle les habitants avec leur charge. **F5** attend leur retour pour sauvegarder ; **F9** recharge.

La démo ne charge ni ne remplace automatiquement la sauvegarde du joueur. Les commandes explicites F5/F9 restent les commandes habituelles.

## Règles de cette livraison

- Planifier un lit ne retire plus immédiatement les matériaux. Un manque de stock n'interdit pas le placement.
- Les ressources restent au dépôt tant que le porteur ne les a pas saisies. Une réservation empêche qu'une seconde tâche ou un atelier consomme la même quantité.
- Les chantiers sont servis dans l'ordre de placement, y compris lorsqu'un porteur rapporte encore une autre catégorie de matériau. Cela évite de répartir les dernières fibres entre plusieurs couchages incomplets.
- Une seule livraison à la fois par chantier ; le dépôt partage sa file entre récolte, approvisionnement et récupération. La capacité d'une charge reste de 3 unités, augmentée par les ateliers existants.
- Les besoins personnels et le rappel priment. Une charge prise est rapportée avant repas, boisson ou repos ; un chantier garde ses matériaux livrés et son travail déjà accompli.
- Les matériaux deviennent incorporés au lit terminé. Il n'est pas encore possible de démonter un lit terminé. L'annulation d'un chantier perd le travail effectué mais conserve les matériaux récupérables.
- Les modèles Blender et animations approuvés sont réutilisés : caisse, bois, fibres, tas de fabrication, lit, prise, portage, dépose et travail. Une silhouette translucide marque le chantier vide ; un tas partiel ne montre que les catégories effectivement livrées.

## Sauvegarde et limites

Le format v4 ajoute les quantités livrées aux lits et les tas issus d'annulations. Les tâches de transport se terminent ou sont annulées avant le point de sauvegarde au refuge. Les anciens formats v2/v3 avaient déjà prélevé le prix total des lits : leurs chantiers sont donc chargés avec les matériaux déjà livrés, sans paiement supplémentaire. Le format v1 reste lisible.

Cette étape pose un premier contrat de transport entre dépôt et chantier. Elle ne remplace pas encore tous les travaux par un ordonnancement général : les métiers et priorités réglables arrivent plus tard. L'atelier conserve sa construction instantanée historique ; les stocks restent centralisés. Pas de dépôts locaux ni de transport entre secteurs dans ce lot.

## Vérifications

La suite `tests/construction.gd` vérifie la conservation des ressources à chaque pas, la concurrence de deux chantiers avec stock limité, le réapprovisionnement par récolte, l'annulation avant prise, en transport, après dépose et pendant fabrication, la récupération physique, la faim urgente, le rappel, la sauvegarde des tas et des chantiers, la migration v3 et le refus de quantités invalides.

Les régressions couvrent sommeil, besoins, livraisons, navigation, échelles, porte, exploration, sauvegarde, clics d'affectation, interface et boucle principale. Les anciennes attentes de paiement immédiat des lits sont remplacées par les nouvelles règles, sans supprimer les contrôles de conservation.

`tests/construction_visual.gd` produit les vues planification, portage, fabrication, lit terminé et récupération dans `artifacts/construction/`. Revue graphique sous Godot 4.7.2, moteur Compatibility. Pas de mesure de capacité pour 30–50 habitants dans cette étape.

**Après validation : commit et push du lot, puis étape 3, premier dépôt local.**
