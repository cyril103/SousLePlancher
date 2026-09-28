# Lot 41 — Premier chapitre avec gestion autonome

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Guidage dans la partie ordinaire

**Objectifs [O]** conserve ses dix étapes et son bouton de prochaine action. Il ajoute une aide de gestion dans le texte et un second raccourci, calculés depuis la colonie :

- **Organiser les récoltes** ouvre les sources au sol tant que le bois et les fibres ne sont pas tous deux désignés.
- **Régler les réserves** ouvre les objectifs si l’une de ces ressources est encore sans limite. Le texte propose 22 bois et 18 fibres comme point de départ pour ce parcours, sans agrandir les dépôts.
- **Entretenir les lanternes** apparaît une fois une lanterne présente, si l’entretien automatique est désactivé. Il explique l’intérêt de deux lanternes et d’une réserve de deux pleines, le coût des pleins et l’absence de fabrication automatique.
- **Vérifier les réserves** donne ensuite accès aux diagnostics et rappelle que H reste une décision du joueur avant le danger humain.

Ces conseils ne constituent pas des étapes obligatoires. Ils ne désignent aucun gisement, ne modifient aucun objectif et ne distribuent ni matériaux ni équipement. Les réglages personnalisés et les affectations manuelles restent utilisables. Le guidage de l’atelier renvoie désormais aux désignations ; celui de la lanterne précise les priorités de transport et de construction nécessaires.

Aucun nouvel asset, secteur ni format de sauvegarde : **v23 inchangée**. Le conseil et les dix étapes se reconstruisent après rechargement.

## Parcours vérifié depuis zéro

`tests/chapter_campaign.gd -- --autonomous` démarre la scène ordinaire, sans préparation de démo. Le joueur scripté désigne bois et fibres, règle leurs objectifs à 22 et 18, commande les constructions et équipements, choisit les inspections et explorations, désigne les travaux cuisine, puis utilise H pendant les passages humains. Les habitants restent sans affectation manuelle de récolteur pendant tout le test. Les stocks, besoins, ressources et horloge ne sont pas réécrits pour accélérer le parcours.

Résultat observé : les dix étapes sont atteintes à **577,6 secondes simulées**, avec **deux lanternes** entretenues, **trois rappels** et un maximum de **63,12 soupçons**. Une sauvegarde JSON est rechargée pendant le transport des provisions ; désignations, objectifs et entretien sont vérifiés avant que le joueur scripté reprenne ses commandes. L’objectif final n’est crédité qu’après la dépose des provisions.

Cette durée décrit un joueur scripté qui connaît les commandes. Elle ne prédit pas une première partie humaine et ne clôt pas l’évaluation de l’équilibrage 11C. Le parcours manuel du test reste disponible, ainsi que ses variantes précédentes.

## Essai joueur

Fonder une nouvelle colonie et suivre **Objectifs [O]**. Commander le premier lit, puis utiliser le raccourci de gestion pour désigner les ressources et choisir les objectifs. Laisser les priorités Transport et Construction actives afin que les chantiers avancent. Les commandes d’exploration restent celles du chapitre ; consulter les diagnostics si une réserve attend.

## Vérifications

- `tests/chapter_logistics.gd` : raccourcis contextuels, conseils sans modification d’état, respect d’objectifs personnalisés, étapes inchangées et reconstruction identique après sauvegarde JSON.
- `tests/chapter_campaign.gd -- --autonomous` : parcours complet ci-dessus, sans affectation manuelle de récolteur.
- `tests/chapter.gd` : progression du chapitre, fourmi, charge non encore livrée, rappel et sauvegarde.
- `tests/chapter_logistics_visual.gd` : affichage d’une nouvelle partie et du conseil de réserve ; captures `artifacts/harvest_targets_chapter_logistics_*.png`.
