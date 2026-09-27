# Lot 24 — Construire un dépôt distant (7A)

**Réalisé et validé par le joueur ; commit et push autorisés.**

## Résultat

Les nouveaux dépôts nécessitent **6 bois, 4 fibres et 16 secondes de fabrication**. Poser un plan ne retire aucun matériau à distance. Les porteurs prennent les ressources dans un dépôt existant, les transportent physiquement jusqu’au chantier, puis un constructeur réalise le casier selon ses priorités de travail. Le stockage reste fermé avant achèvement ; il offre ensuite **12 places**.

Le dépôt distant de ce lot se trouve dans **la réserve de l’Est, à l’étage**, accessible par l’échelle et la passerelle existantes. Après reconnaissance, **Construire → Planifier le dépôt de la réserve à l’étage** pose le casier sur un emplacement prévu. Les dépôts au sol restent plaçables librement dans la zone autorisée, avec la même recette et la même construction.

L’emplacement de l’étage est fixe pour conserver l’accès au gisement et les files du pont. Le casier existant est réutilisé, réduit et orienté pour cette plateforme ; aucune extension de carte ni nouvel asset 3D n’est ajoutée. Le stockage dans l’alcôve au-delà de la fissure n’est pas inclus : les déplacements de chantier y demandent encore une liaison dédiée.

## Transport, stock et priorités

- Transport approvisionne les chantiers et récupère les matériaux abandonnés ; Construction assemble le dépôt.
- Une récolte du même étage livre au dépôt distant sans redescente inutile au refuge.
- Les stocks des deux côtés restent distincts. Un chantier au refuge peut utiliser le bois du dépôt distant, mais un porteur doit le prendre et le ramener par la passerelle et l’échelle.
- Un dépôt plein bloque les nouvelles réservations. Modifier un filtre conserve le stock et les livraisons déjà réservées. Les matériaux présents restent utilisables pour les chantiers même si leur filtre d’entrée est ensuite décoché.
- Les priorités individuelles, besoins et rappels restent applicables. Il n’y a pas encore de transfert régulier, quota ou réapprovisionnement entre dépôts : ce sera 7B.

## Annulation et reprise

**Stocks → Dépôts → Annuler le chantier** libère l’artisan et annule les approvisionnements. Une caisse non prélevée libère sa réservation ; une charge déjà en route est rapportée. Les matériaux déjà livrés deviennent un tas de récupération à côté du plan, y compris à l’étage. Leur récupération exige un dépôt accessible, acceptant la ressource, avec suffisamment de place.

Le plan et son emplacement restent conservés, sans capacité de stockage. **Relancer le plan** permet de recommencer la construction ; les matériaux récupérés ne sont jamais crédités deux fois. Un dépôt terminé ne peut pas être démoli dans ce lot. Cette limite évite de supprimer un inventaire ou des réservations actives.

## Sauvegarde v11

Sont conservés : état actif/annulé/construit, matériaux livrés, progression, artisan, porteur et réservations, positions à l’étage, stocks, filtres, files et tâches en cours. Le rechargement reste en pause.

Les sauvegardes v1–v10 restent lisibles. Les dépôts existants y sont considérés comme déjà construits et conservent leurs stocks. Les données incohérentes (stock dans un dépôt non construit, progression sans matériaux, artisan sans chantier) sont rejetées.

## Démonstration

Lancer `-- --demo-depot-build`. La réserve est déjà reconnue et le plan posé ; la construction n’est pas exécutée d’avance. **H1 transporte, H2 construit, H3 récolte le bois de l’étage.** Le filtre bois du refuge est désactivé dans cette démo afin que la récolte reste bloquée jusqu’à l’ouverture du nouveau dépôt.

1. **Espace**, puis éventuellement **x3** : suivre les quatre livraisons de bois/fibres par l’échelle et le pont.
2. H2 fabrique le casier ; H3 remplit ses 12 places avec le bois de la réserve.
3. Essayer **F5/F9** pendant un transport ou une fabrication.
4. Pour tester l’annulation, cliquer **Annuler le chantier** avant achèvement. Réactiver le filtre **Bois** du **Refuge** pour permettre la récupération des matériaux abandonnés ; le transport d’une caisse déjà réservée au refuge reste possible.
5. **Relancer le plan** pour reconstruire.

Fichier séparé : `user://saves/depot_build_demo.json`. L’essai sans intervention et avec besoins/menace ordinaires atteint le dépôt plein en environ 330 secondes simulées (environ deux minutes à x3, selon l’exécution).

## Vérifications

- `tests/depot_build.gd` : plan sans obstruction des accès, stockage interdit avant fabrication, construction et remplissage, conservation, sauvegardes réelles du plan/transport sur pont/fabrication/annulation/stock plein, annulation chargée, récupération à l’étage, reconstruction, dépôt plein et filtres, utilisation du stock distant pour un chantier au refuge, migration des anciens dépôts.
- `tests/depot_build_visual.gd` : captures du plan, de la fabrication et du dépôt rempli.
- Non-régression : dépôts, priorités, sauvegardes actives et chargement, chantiers, besoins et récolte de l’alcôve.

Prochaine livraison : **7B — transfert régulier entre deux dépôts**.
