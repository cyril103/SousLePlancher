# Lot 26 — Éclairage fixe entretenu (7C)

27 septembre 2026 — **Validé par le joueur ; commit et push autorisés.**

## Résultat

**Travaux → Éclairage fixe de la passerelle** permet de commander un point lumineux sur le palier, après reconnaissance de la réserve de l’Est. Un porteur livre les matériaux, un artisan fabrique le support, puis le combustible est livré physiquement. Le brasero éclaire effectivement le palier et la passerelle ; flamme et lumière s’éteignent ensemble.

Le modèle Blender de torche fixe et le shader de flamme existants sont réutilisés. Pas de nouvelle chaîne de métal, cire ou résine.

## Construction et combustible

- Emplacement fixe sur le palier ouest, accessible avant la passerelle. Coût : **4 bois, 2 fibres, 16 secondes** de fabrication après livraison.
- La construction ne fournit aucun combustible gratuit. Le premier plein nécessite **2 bois supplémentaires**, livrés par un porteur.
- Un plein dure **180 secondes de simulation**. Une réserve supplémentaire de deux bois est demandée à partir de 90 secondes restantes. Le bois livré attend sur place ; il alimente le prochain plein une fois le précédent épuisé, sans gaspiller l’autonomie restante.
- Au maximum deux bois en réserve, en plus du plein actif. La consommation dépend du temps simulé ; pause et vitesse suivent la simulation.
- Construction et entretien utilisent les priorités individuelles Construction/Transport et les réservations existantes. Les besoins autonomes et rappels restent prioritaires.
- **Suspendre le ravitaillement et rappeler** annule les nouvelles demandes et rappelle les charges en cours. Les ressources déjà déposées restent disponibles pour le prochain plein.
- **Éteindre** conserve l’autonomie restante. Le ravitaillement automatique est un réglage distinct ; **Rallumer** utilise le combustible disponible.
- Annuler le chantier rend les matériaux déposés récupérables et rapporte les charges en transit. Le plan peut être repris. Pas de démolition du support terminé.

## Protection de la route

La commande du brasero active la protection des nouvelles rotations entre dépôts situés de part et d’autre de la passerelle. Elles attendent la mise en service, puis s’arrêtent de repartir si le brasero s’éteint. Le panneau des liaisons indique le motif. Les ordres restent actifs et repartent quand la lumière revient.

**Les trajets engagés finissent**, y compris ceux dont le porteur n’a pas encore pris la caisse. Les livraisons de construction et de combustible restent autorisées pour permettre la remise en service. Le lot n’introduit pas d’arrêt au milieu d’une traversée ni de téléportation de caisse.

Ce contrôle concerne les transferts réguliers de 7B. La récolte historique, les éclaireurs et les missions de l’alcôve conservent leurs règles. Ce n’est pas encore une simulation générale d’obscurité, de danger ou de couverture lumineuse. Avant la commande, les parties existantes conservent leurs trajets ; annuler le plan retire cette protection.

## Sauvegarde

Format **v13** : chantier, matériaux, artisan, porteur, réserve de combustible, autonomie exacte, consommation cumulée, interrupteur et entretien automatique. Les jobs de construction sont reliés à leurs sites au rechargement, y compris pendant une livraison. Le validateur contrôle le bilan combustible livré/consommé/restant.

Les fichiers v12 se rechargent sans brasero ni nouvelle restriction. F5/F9 conservent le fonctionnement habituel de sauvegarde sur place et reprise en pause.

## Démonstration

Lancer avec `-- --demo-fixed-light`. Le dépôt à l’étage et la liaison de transfert de bois sont préparés ; le brasero est un véritable chantier non approvisionné. H1/H2 transportent, H3 peut transporter et construire.

1. **Espace** : livraisons, fabrication, premier combustible, puis départ des transferts.
2. **Voir le palier** : observer le support et la différence entre **Éteindre** et **Rallumer**.
3. **Suspendre le ravitaillement et rappeler** : laisser le combustible s’épuiser, vérifier le motif d’attente des liaisons. Les livraisons déjà engagées finissent.
4. **Reprendre le ravitaillement** : un porteur apporte le bois, la lumière revient et les nouvelles rotations redeviennent possibles s’il reste du stock à transférer.
5. **F5**, **F9**, **Espace** pendant le chantier ou l’entretien.

Fichier séparé : `user://saves/fixed_light_demo.json`. Les ressources de la démo sont finies ; une liaison dont la source est vide attend également son réapprovisionnement.

## Vérifications

Godot 4.7.2, rendu Compatibility :

- `tests/fixed_lighting.gd` : fabrication réelle, premier plein, conservation du bois avec comptabilité du combustible, checkpoints chantier/livraison/allumé/éteint, panne naturelle, ravitaillement et rallumage, rappel d’une livraison chargée, annulation/récupération/reprise du chantier, rejet d’un bilan de combustible falsifié, migration v12.
- Régressions : `transfers`, `depot_build`, `live_checkpoint`, `needs`.
- `tests/fixed_lighting_visual.gd` : captures du plan, du brasero allumé puis éteint et inspection de l’interface.

## Suite

Prochaine livraison : **8A — chambre construite**, sur un niveau, avec murs/sol/porte/lit et livraison physique des matériaux. La détection des pièces et l’intimité réelle restent le lot 8B. Aucun nouveau secteur ou insecte engagé en parallèle.
