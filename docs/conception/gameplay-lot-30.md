# Lot 30 — Accès cuisine et pont approvisionné (11A)

27 septembre 2026 — **Validé par le joueur ; commit et push autorisés.**

## Parcours livré

Le salon mène à l’alcôve par la fissure L01 existante. Une ouverture réelle à l’arrière de l’alcôve mène au joint rompu L02, puis à une première poche sous la cuisine. Cette cuisine est distincte de la réserve de bois située sur le palier du salon.

La scène contient les trois zones simultanément. Le joueur donne trois ordres indépendants : **reconnaître**, **construire le pont**, puis **récolter le biscuit**. Les habitants choisissent les tâches disponibles selon leurs priorités et vont chercher leur lanterne ; aucun porteur précis ni itinéraire manuel n’est imposé.

## Accès et travaux

- Reconnaissance à vide par une corniche étroite longeant la maçonnerie. L’aller-retour révèle le biscuit et autorise la commande du pont.
- La fissure doit déjà avoir été reconnue ; son élargissement est nécessaire avant la commande du pont et le transport de ses matériaux.
- Pont : **8 bois + 4 fibres**, livrés réellement depuis les dépôts jusque sur la rive de l’alcôve. Les porteurs passent par L01 avec leurs caisses.
- Une fois les matériaux réunis, un artisan équipé se rend sur place et effectue **24 secondes** de travaux. Les matériaux restent comptés dans le pont construit.
- Le pont terminé autorise les caisses ; la corniche n’accepte jamais un habitant chargé.
- L01 et L02 ont chacun leur propriétaire et leur file. Une seule personne traverse L02 à la fois, y compris lors de la reconnaissance. Un rappel pendant une traversée engagée la laisse finir avant le demi-tour.
- « Suspendre le chantier » rappelle les travailleurs. Les matériaux déjà livrés et le travail restent sur place ; les caisses non déposées rentrent au dépôt. « Reprendre » conserve ces acquis. Ce lot n’ajoute pas de démolition du pont ni de récupération de ses matériaux incorporés.

## Provisions et autonomie

Le biscuit représente **36 unités de nourriture**, sans nouvelle catégorie d’inventaire. Le joueur désigne sa récolte après construction du pont. Jusqu’à deux habitants peuvent travailler sur les missions cuisine simultanément, en incluant les travaux et la reconnaissance.

Chaque récolte réserve sa quantité au départ ainsi que la place dans un dépôt. Le prélèvement intervient au moment où le personnage saisit la caisse ; le stock du dépôt augmente seulement lors de la dépose. Un ordre arrêté avant prélèvement libère les réservations. Après prélèvement, il fait rentrer la caisse. Un dépôt plein empêche un nouveau départ ; un accès de livraison bloqué conserve la caisse et cherche un dépôt de remplacement.

Les priorités existantes sont utilisées : **Récolte** pour reconnaissance/provisions, **Transport** pour les matériaux et **Construction** pour le pont. Les besoins et le rappel restent prioritaires. Une tâche engagée se termine ou revient proprement avant de céder la place.

La lanterne de ceinture est obligatoire. Son autonomie est vérifiée pour la mission, ses éventuels détours par les dépôts, le retour et une marge. Le combustible continue de baisser pendant les trajets, les files et les travaux. La réserve de retour peut provoquer un rappel anticipé. Une lanterne trop faible ne permet pas de nouveau départ ; la recharge reste hors périmètre, comme dans les lots précédents.

## Interface

Panneau **Travaux → Accès cuisine et pont**, également accessible en cliquant le repère L02 sur la carte :

1. Désigner/annuler la reconnaissance à vide.
2. Commander le pont après découverte et élargissement de L01.
3. Suspendre/reprendre les travaux.
4. Désigner/arrêter la récolte du biscuit.
5. Recentrer sur le pont, suivre un habitant engagé ou accéder aux lanternes.

Le panneau défile et montre les matériaux livrés, l’avancement, les provisions restantes/réservées et les habitants engagés. La caméra peut maintenant parcourir la liaison et la cuisine jusqu’à Z = 31 après reconnaissance de l’alcôve.

## Assets Blender

Sources : `art_source/kitchen_30`. Exports : `assets/models/kitchen_30`. Reproduction : `tools/create_kitchen_assets.py`.

- Variante de l’alcôve avec deux jambages et une ouverture arrière ; l’ancien asset est conservé.
- Prolongement de plancher, corniche et joint sombre.
- Pont à lattes, poutres et garde-corps, visible après achèvement.
- Première poche de cuisine, plinthes, débris de bois et biscuit perforé.

Les caisses, lanternes et animations existantes sont réutilisées. Les matériaux bois proviennent des références déjà approuvées. Il s’agit d’un parcours artisanal de prototype, pas de toute la cuisine de l’atlas.

## Sauvegarde

Format **v17** : découverte, ordres actifs, matériaux du pont, progression, nourriture restante, missions, caisses, réservations, chemins locaux, files et propriétaire de L02 sont conservés. L01 reste géré par son registre existant. Le chargement reprend en pause, aux positions et phases enregistrées.

Les sauvegardes v16 restent lisibles ; la cuisine y commence inconnue. Les contrôles ajoutés refusent notamment les charges sans réservation, une traversée sans propriétaire, les missions cuisine orphelines et un pont construit sans ses matériaux.

## Démo validée

`-- --demo-kitchen` — fichier distinct `user://saves/kitchen_demo.json`.

La scène démarre en pause, avec **l’alcôve reconnue et L01 déjà élargi**. Douze lanternes sont fournies pour tester ce lot sans refaire leur fabrication ; leur combustible reste réellement consommé. Le pont reste à construire et le biscuit inconnu. Ces préparatifs appartiennent uniquement à la démo.

1. Cliquer **Désigner la reconnaissance à vide**, puis **Espace**. Utiliser « Suivre un habitant engagé » pour observer le passage sur la corniche et son retour.
2. Après découverte, cliquer **Commander le pont**. Observer les livraisons depuis le refuge et les travaux. Suspendre puis reprendre pour vérifier le retour des caisses.
3. Une fois le pont construit, cliquer **Désigner la récolte du biscuit**. Les caisses franchissent les deux accès et alimentent le dépôt.
4. **F5 / F9** pendant un chantier ou un trajet chargé ; la reprise se fait sur place.
5. Arrêter la récolte pendant un trajet pour vérifier le retour sans perte de charge. Si les lanternes restantes sont trop faibles, utiliser la fabrication normale.

## Vérifications

- `tests/kitchen.gd` : reconnaissance préalable, corniche à vide, pont réellement approvisionné, conservation bois/fibres, suspension avec charge, sauvegardes/reprises de livraison et de construction, récolte et retour chargé.
- `tests/kitchen_edges.gd` : dépôt plein, faible autonomie, rappel en cours de traversée, reprise du demi-tour, libération des deux registres de passage, arrêt de récolte et migration v16.
- `tests/kitchen_visual.gd` : vue d’ensemble, corniche, chantier, pont chargé et cuisine.
- Régressions : `tests/alcove_haul.gd` et `tests/health.gd`.

## Limites et suite

Pas de fourmi, de combat, de génération procédurale, de dépôt dans la cuisine ni de bâtiment libre dans cette nouvelle poche. Le secours du lot 29 reste limité au rez-de-chaussée du secteur initial. Les routes locales L01/L02 utilisent des parcours réservés propres à ces accès ; ce lot ne constitue pas encore un graphe universel de navigation entre secteurs.

La source de biscuit est finie et ne remplace pas les sources alimentaires initiales. La présence humaine conserve la règle globale du prototype ; les routines locales et fenêtres de récolte restent à développer.

**Prochaine livraison : 11B, première fourmi sur le parcours cuisine.** Aucun bestiaire supplémentaire n’est engagé dans ce lot.
