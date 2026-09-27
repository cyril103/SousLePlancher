# Lot 23 — Priorités de travail individuelles (9B)

**Réalisé et validé par le joueur ; commit et push autorisés.**

## Résultat visible

**Habitants → Priorités de travail**, ou **Travaux → Priorités de travail**, ouvre un tableau par habitant. Cliquer une case fait défiler **0 → 1 → 2 → 3 → 0**. Le zéro est affiché par un tiret : métier désactivé. 1 est prioritaire, 2 normal, 3 secondaire. L’activité de chaque habitant est indiquée sous sa ligne.

| Catégorie | Travaux concernés |
| --- | --- |
| Récolte | Récolte du gisement affecté à cet habitant, ou désignation de l’alcôve s’il n’a pas de gisement affecté. Récupération de la lanterne et retour avec caisse font partie de la même mission. |
| Transport | Livraison physique de bois et fibres aux chantiers de lits, équipements et passage ; récupération des matériaux d’un chantier annulé. |
| Construction | Fabrication des lits, assemblage d’éclairages à l’atelier, dégagement/étaiement et élargissement déjà commandés. |

Un habitant essaie les catégories par priorité croissante. À égalité : construction, transport, récolte. Si aucune tâche exécutable n’est trouvée, il essaie la catégorie suivante. Les recettes, accès et réservations existants décident si le travail est possible. Tous les habitants commencent à 2 dans les trois catégories.

## Limites et arbitrage

Ces priorités règlent le **choix individuel du prochain travail**, pas le classement global des habitants. À disponibilité égale, l’ordre de parcours des habitants reste déterministe ; compétences, distance optimisée et horaires ne sont pas ajoutés dans ce lot. Les gisements locaux restent affectés avec les commandes existantes ; la seule désignation collective est celle de 9A.

Les travaux en cours ne sont pas brutalement interrompus par un changement de priorité : la caisse est déposée, la mission d’expédition se termine ou la fabrication engagée s’achève. Les nouvelles prises de tâche suivent ensuite les nouveaux choix. Le rappel et les besoins conservent leurs interruptions sécurisées. Les ordres manuels d’exploration/équipement ne sont pas réinterprétés comme des métiers.

Une catégorie sans habitant autorisé est signalée dans le tableau. Les problèmes de stock, d’accès ou de lanterne restent expliqués dans les panneaux de chantier et d’ordre. Un collègue au repos ou occupé par un besoin ne réserve pas un nouveau travail : un autre habitant autorisé peut le prendre. Un artisan attend l’approvisionnement physique du porteur.

## Besoins et sauvegarde

Faim, soif, sommeil, rappels et franchissements sont traités avant la prise d’un nouveau travail. Les urgences d’auto-approvisionnement alimentaire ne dépendent pas des cases de métier. Les réservations des tâches actives restent propriétaires de leurs ressources jusqu’à règlement.

Les trois priorités sont enregistrées dans les données de chaque habitant du runtime v10. Les sauvegardes précédentes sans ces champs retrouvent la valeur 2 ; une valeur hors 0–3 ou une catégorie manquante dans un tableau présent est rejetée. Les réservations et tâches en cours restent restaurées par 6C.

## Démonstration à essayer

Lancer `-- --demo-priorities`. Préparation : passage élargi, alcôve reconnue, lanternes disponibles et lit attendant ses fibres. L’ordre de récolte est posé ; **H1 récolte**, **H2 transporte**, **H3 construit**, **H4 est disponible mais ses métiers sont désactivés**.

1. **Espace** : H1 prend une lanterne et rapporte les fibres ; H2 les livre au chantier ; H3 fabrique le lit.
2. Activer Récolte pour H4 : il peut rejoindre l’ordre si les besoins, l’éclairage et les réservations le permettent.
3. Mettre Transport à 0 pour H2 pendant une livraison : il termine cette charge, puis cesse les nouveaux transports.
4. Pour voir une tâche en attente, mettre Construction à 0 avant son démarrage ; la réactiver permet de terminer le lit.
5. **F5**, avancer, **F9** : retrouver les préférences et tâches en pause, puis reprendre avec Espace.

Sauvegarde distincte : `user://saves/priorities_demo.json`. Les rôles et préparatifs sont propres à cette démo ; les règles de priorité fonctionnent aussi dans la partie ordinaire.

## Vérifications

- `tests/priorities.gd` : chaîne spécialisée jusqu’au lit, conservation des fibres, sauvegarde/restauration des préférences, arbitrage entre collecte et transport concurrents, repli d’une catégorie indisponible, désactivation en cours de transport et fabrication, absence d’artisan autorisé, remplacement d’un récolteur assoiffé et d’un artisan fatigué, migration et rejet d’une priorité invalide.
- `tests/priorities_visual.gd` : tableau, callback d’une vraie case vérifiant l’habitant concerné, capture de l’artisan au travail.
- Non-régression : désignations, construction, besoins, sommeil, torches, fissure et sauvegardes actives.

Aucun nouvel asset 3D. Prochaine livraison : **7A — dépôt distant construit**, selon l’ordre de la roadmap.
