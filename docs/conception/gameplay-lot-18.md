# Lot 18 — Une fissure devient un passage

Étape 5, réalisée le 24 septembre 2026. **Validée par le joueur : « je valide ». Commit et publication autorisés.**

## Boucle jouable

La fissure se trouve au bord sud du plancher. Cliquer son ouverture ou utiliser **Travaux → Fissure et passage**. Choisir un habitant libre, puis **Inspecter** : il rejoint l’entrée, observe pendant cinq secondes et rentre au refuge. Le chantier devient disponible après cette inspection physique.

**Dégager et étayer** crée un chantier de **6 bois et 4 fibres**, livré par les porteurs depuis les stocks. Les matériaux déposés sont visibles près de l’entrée. Après approvisionnement complet, un habitant effectue **24 secondes de travaux** : dégagement pendant les huit premières secondes, puis étaiement. L’ouverture reste interdite jusqu’à la fin du travail.

**Visiter l’alcôve** envoie l’habitant sélectionné de l’autre côté. Il traverse, observe et rentre automatiquement. Plusieurs visiteurs peuvent être envoyés : une file commune aux deux sens protège le seuil. Les besoins continuent de diminuer. Soif, faim, sommeil et rappel interrompent la visite pour rentrer ; une traversée engagée se termine d’abord.

## Contrat du premier passage

| Propriété | Valeur |
| --- | --- |
| Identifiant | `south_fissure` |
| Extrémités | `refuge_south` → `alcove_north` |
| Entrée | (4 ; −0,0105 ; 5) |
| Sortie | (4 ; −0,0105 ; 7,4) |
| Type | Horizontal, marche debout |
| Largeur / hauteur utiles | 0,85 / 2,1 unités |
| Capacité | Une personne, réservation commune aux deux sens |
| Traversée | 3 secondes de simulation |
| Charge | Caisse interdite |
| États | Non inspecté, bloqué, chantier, ouvert |

Une seule mission et un seul côté courant sont associés à chaque visiteur. Un rappel ne téléporte pas le résident et ne libère pas un seuil encore occupé. Pause et accélération suivent la même horloge que la colonie.

## Travaux, annulation et sauvegarde

Le chantier réutilise les réservations de dépôt, prises de caisses, transports et déposes. Une interruption conserve la progression du travail. Une annulation laisse les matériaux déposés dans un tas à récupérer et fait rentrer les matériaux déjà portés. Aucun remboursement instantané à distance.

La sauvegarde **v8** conserve inspection, visite, matériaux, progression et ouverture. Comme pour les autres lots, **F5** rappelle les habitants et attend un état stable au refuge avant d’enregistrer. La reprise d’un chantier partiel conserve son coût déjà payé. Une ancienne sauvegarde initialise la fissure fermée et non inspectée. Les constructions d’une ancienne sauvegarde restent chargeables ; si elles bloquent l’approche, le départ est refusé.

## Assets et scène

Quatre modèles produits dans Blender, avec sources dans `art_source/fissure_18/`, exports et textures dans `assets/models/fissure_18/` :

- `fissure_frame` : planches fendues, bordures irrégulières et anciennes fixations ;
- `fissure_blocked` : lattes cassées et éclats encombrant l’ouverture ;
- `fissure_braces` : deux cadres d’étaiement et ligatures ;
- `fissure_alcove` : prolongement du sol, parois basses et petits débris.

Générateur reproductible : `tools/create_fissure_assets.py`, Blender 2.93. Les animations de marche et de travail existantes sont réutilisées. L’alcôve conserve l’ambiance sombre de la scène ; aucun système d’éclairage fixe constructible n’est ajouté.

## Démonstration

Lancer avec `-- --demo-fissure`. La scène démarre en pause avec une inspection déjà confiée à H1 et les stocks nécessaires au chantier.

1. **Espace** : H1 va inspecter la fissure puis rentre.
2. **Dégager et étayer** : suivre les livraisons et les travaux.
3. Choisir un habitant disponible puis **Visiter l’alcôve**. Répéter avec un autre habitant pour voir la file.
4. **Rappeler** agit sur l’habitant choisi ; **H** rappelle tout le monde.
5. **Centrer la caméra sur le passage** facilite l’examen. **F5/F9** permettent l’essai de sauvegarde/reprise.

## Vérifications

`tests/fissure.gd` couvre inspection obligatoire, passage fermé, conservation du bois et des fibres, ouverture après travail, quatre visites, capacité du seuil, pause/x3, caisse refusée, rappel en traversée, annulation et récupération des matériaux, sauvegarde ouverte et partielle, reprise sans double paiement, retour autonome pour soif, migration v7 et approche bloquée. `tests/fissure_visual.gd` capture fissure bloquée, chantier, traversée et alcôve. Les suites existantes couvrent les régressions de navigation, livraisons, interface, besoins, sauvegarde et éclairage porté.

## Limites de cette étape

L’alcôve est une petite zone artisanale de la scène actuelle, sans ressource supplémentaire ni gestion économique distante. La visite utilise un trajet dédié ; les autres secteurs ne sont pas encore reliés par un graphe général. Elle s’effectue à vide, sans mission d’éclairage portée engagée. L’expédition avec lanterne, récolte distante et sauvegarde en voyage appartient à l’étape 6. Pas encore de destruction, d’effondrement, de fermeture du passage après ouverture ni de travaux libres pour élargir le seuil.
