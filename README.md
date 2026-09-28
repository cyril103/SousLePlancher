# Sous le plancher

Prototype 3D de gestion d'une colonie miniature sous une maison habitée. Projet Godot 4, testé avec Godot 4.7.2 en rendu Compatibility.

## Jouer

Importer `project.godot` dans Godot, puis F6 sur la scène principale ou F5 pour lancer le projet. Cliquer sur « Fonder la colonie ».

Le jeu démarre en plein écran. **F11** bascule entre plein écran et fenêtre. Si Godot intègre le jeu dans l'éditeur, désactiver l'exécution intégrée pour utiliser une fenêtre de jeu indépendante.

La barre d'icônes en bas donne accès aux constructions, affectations, objectifs, rappel au refuge, pause, vitesse, aide et plein écran. Les panneaux sont fermés par défaut ; un seul s'ouvre à la fois. Cliquez à nouveau sur son icône, sur × ou appuyez sur Échap pour le fermer. Le bandeau supérieur garde les réserves et les alertes visibles. Les notifications disparaissent après quelques secondes.

**B** ouvre les constructions, **C** les affectations, **O** les objectifs. Un clic sur un gisement ouvre directement ses affectations ; le menu déroulant permet aussi de choisir un autre gisement. Le nombre sur l'icône des habitants indique ceux sans tâche.

- Cliquer sur un gisement, puis « Affecter un habitant ». Il récolte et rapporte automatiquement ses ressources au refuge.
- Faire fabriquer un lit (4 bois, 3 fibres) ou une alcôve individuelle avec cloisons (6 bois, 5 fibres). Les habitants y récupèrent leur énergie ; aucun nouvel habitant n’apparaît à la construction.
- Construire un atelier (10 bois, 6 fibres) pour améliorer tous les transports.
- Avant le passage humain, appuyer sur H pour rappeler les habitants. Appuyer à nouveau après le danger pour reprendre les tâches.
- Développer les couchages et maintenir les réserves. La partie continue après le premier cycle, sans l’ancienne victoire automatique.
- Les habitants mangent et boivent selon leurs jauges individuelles, et collectent une ressource accessible si le dépôt est vide. Les besoins critiques ralentissent les déplacements. Des soupçons à 100 terminent la partie.

Caméra : flèches ou ZQSD sur clavier français (WASD physique), molette pour zoomer, bouton central maintenu pour tourner. Espace : pause. 1 : lit ; 2 : atelier ; 3 : alcôve. Échap/clic droit : annuler. R : recommencer.

Le **lot 12** introduit le sommeil, les propriétaires de lits, la fabrication et l’intimité. Voir [le détail du lot](docs/conception/gameplay-lot-12.md). `-- --demo-sleep` prépare deux couchages occupés et un chantier ; Espace reprend la démo. **Couchages** gère les propriétaires et les annulations de travaux, **Se reposer** déclenche un repos anticipé. F5 sauvegarde sur place et met en pause ; F9 recharge. Les besoins et les chantiers sont conservés, et les anciennes sauvegardes restent lisibles.

Le **lot 13** ajoute les besoins autonomes de faim et de soif au sommeil : trois jauges individuelles, repas et boissons au refuge, collecte d’urgence de nourriture et d’eau, réveil en cas de besoin critique. La démo `-- --demo-needs` montre ces comportements. Voir [les règles et limites](docs/conception/gameplay-lot-13.md).

Le **lot 32 / étape 11C** commence le parcours guidé : **Objectifs [O]** suit dix étapes du premier lit au retour des provisions, avec un accès direct aux commandes. Le panneau s’ouvre à la fondation de la colonie. La progression se reconstruit depuis les sauvegardes v18 existantes. Voir [le périmètre et les vérifications](docs/conception/gameplay-lot-32.md).

Le **lot 33** corrige les rappels pendant une sortie du refuge pour inspection ou équipement. Le chapitre complet est testé depuis une nouvelle partie, avec besoins, passages humains et rechargement d’une expédition chargée : [résultats et essai](docs/conception/gameplay-lot-33.md).

Le **lot 34** ajoute les seuils **Garder / Viser** aux transferts : réserve minimale à la source, objectif à destination et reprise automatique après consommation. Démo `-- --demo-transfer-limits`, sauvegarde v19 compatible en lecture avec les versions précédentes. Voir [les règles et essais](docs/conception/gameplay-lot-34.md).

Le **lot 35** permet de **ravitailler les lanternes rangées** : 2 bois livrés, 8 secondes d’entretien, puis 180 secondes d’autonomie sur le même équipement. Atelier requis ; bouton dans Éclairage et éclaireurs. Démo `-- --demo-lantern-refill`, sauvegarde v20 ; [règles et vérifications](docs/conception/gameplay-lot-35.md).

Le **lot 36** ajoute une **réserve automatique de lanternes** (0 à 8) et l’annulation des entretiens avec récupération du bois. Réglages dans **Éclairage et éclaireurs → Entretien des lanternes**. Démo `-- --demo-auto-refills`, sauvegarde v21 ; [règles et tests](docs/conception/gameplay-lot-36.md).

Le **lot 37** ajoute **Travaux → Suivi des chantiers** : matériaux livrés, activité des habitants, priorités désactivées et matériaux récupérables après annulation. Accès aux commandes et centrage caméra ; démo `-- --demo-construction-board`. Sauvegarde v21 inchangée ; [périmètre et essai](docs/conception/gameplay-lot-37.md).

Le **lot 38** ajoute les **récoltes autonomes du refuge** : désigner les cinq gisements au sol, laisser les habitants libres récolter selon leurs priorités, puis suspendre sans perdre les charges. Accès par Travaux ou Habitants. Démo `-- --demo-local-harvest`, sauvegarde v22 ; [règles et vérifications](docs/conception/gameplay-lot-38.md).

Le **lot 39** ajoute les **objectifs de réserve** aux récoltes autonomes : seuil commun par ressource, caisses engagées incluses, dernière caisse partielle et reprise après consommation. Récoltes du refuge → Objectifs de réserve. Démo `-- --demo-harvest-targets`, sauvegarde v23 ; [règles et essais](docs/conception/gameplay-lot-39.md).

Le **lot 40** explique les attentes dans **Objectifs de réserve** : désignation, épuisement, priorités, affectations, filtres, capacité et accès, avec raccourcis vers les commandes utiles. Démo `-- --demo-harvest-status`, sauvegarde v23 inchangée ; [périmètre et essais](docs/conception/gameplay-lot-40.md).

Le **lot 41** intègre la gestion autonome au **premier chapitre [O]** : raccourci contextuel vers les récoltes, les objectifs de réserve et l’entretien des lanternes. Le parcours complet est testé sans affectation manuelle de récolteur, avec reprise en expédition. Nouvelle partie ordinaire, sauvegarde v23 inchangée ; [guidage et résultats](docs/conception/gameplay-lot-41.md).

Le **lot 42** ajoute la **fabrication automatique des lanternes** : objectif total de 0 à 8, équipements portés et commandes engagées inclus, entretien réglé séparément. Démo `-- --demo-lantern-production`, sauvegarde v24 compatible en lecture avec les anciennes versions ; [règles et parcours vérifié](docs/conception/gameplay-lot-42.md).

Le **lot 43** permet d’**annuler une fabrication de torche ou de lanterne**, avec retour des charges et récupération physique des matériaux. Accès par Éclairage et éclaireurs → Fabrications en cours, ou depuis le suivi des chantiers. Sauvegarde v25 ; [règles et essai](docs/conception/gameplay-lot-43.md).

Le **lot 44** ajoute la **désignation de l’inspection de la fissure** : un habitant disponible prend la tâche selon Construction, avec rappel, annulation et reprise sauvegardée. L’ouverture reste une commande séparée. Démo `-- --demo-inspection`, sauvegarde v26 ; [règles et essai](docs/conception/gameplay-lot-44.md).

Le **lot 45** ajoute la **reconnaissance autonome de l’alcôve** : désigner la sortie après ouverture, puis laisser un habitant prendre une lanterne, explorer et revenir selon sa priorité Récolte. Rappel, annulation et reprise sauvegardée ; démo `-- --demo-auto-scout`, sauvegarde v27. Voir [les règles et essais](docs/conception/gameplay-lot-45.md).

Le **lot 46** relie les **fibres de l’alcôve à l’objectif de réserve commun** : stocks et caisses engagées comptés, dernière caisse partielle et reprise après consommation. Démo `-- --demo-alcove-target`, sauvegarde v27 inchangée ; [règles et essais](docs/conception/gameplay-lot-46.md).

Le **lot 47** relie les **provisions de la cuisine à l’objectif alimentaire commun** : réservations comptées dès la préparation, dernière caisse partielle et reprise après les repas. Démo `-- --demo-kitchen-target`, sauvegarde v27 inchangée ; [règles et essais](docs/conception/gameplay-lot-47.md).

Le **lot 48** ajoute les **diagnostics des expéditions** aux objectifs de réserve : alcôve et cuisine, autonomie des lanternes, accès, habitants et dépôts, avec raccourcis vers les commandes utiles. Démo `-- --demo-remote-harvest-status`, sauvegarde v27 inchangée ; [règles et essais](docs/conception/gameplay-lot-48.md).

Le **lot 49** apporte les **commandes de récolte au clic sur les gisements du refuge** : désigner, suspendre, consulter les réservations et ouvrir les priorités ou les affectations manuelles. Démo `-- --demo-harvest-source`, sauvegarde v27 inchangée ; [règles et essais](docs/conception/gameplay-lot-49.md).

Le **lot 50** affiche l’**état des récoltes sur la carte** : réserve couverte, objectif 0, rappel, épuisement et porteurs engagés. Cliquer sur une étiquette ouvre le gisement. Démo `-- --demo-harvest-markers`, sauvegarde v27 inchangée ; [règles et essais](docs/conception/gameplay-lot-50.md).

Le **lot 51** intègre le **pont de la cuisine au suivi des chantiers** : matériaux livrés, caisses réservées, retours après suspension et avancement, avec accès aux commandes du pont. Démo `-- --demo-kitchen-board`, sauvegarde v27 inchangée ; [règles et essais](docs/conception/gameplay-lot-51.md).

Le **lot 52** ajoute les **priorités des gisements du refuge** : haute, normale ou basse pour les prochains départs automatiques, sans interrompre les charges engagées. Démo `-- --demo-harvest-priority`, sauvegarde v28 avec migration des anciennes parties ; [règles et essais](docs/conception/gameplay-lot-52.md).

## Suite de production

Le [plan du monde et des secteurs](docs/atlas-monde-v01/index.html) propose une carte d’ensemble, une coupe verticale, neuf fiches de zones et un registre des passages. L’existant, la campagne prévue et les extensions différées y sont distingués. Publication autorisée par le joueur ; les implantations futures restent à éprouver, sans changement de l’ordre de réalisation.

**Priorité proposée après le catalogue : terminer l’expédition vers le secteur adjacent.** La [roadmap actualisée](docs/conception/roadmap-production.md) sépare reconnaissance avec lanterne (6A), récolte et retour chargé (6B), puis sauvegarde en expédition (6C). Les assets fonctionnels sont réutilisés ; la fourmi et la refonte visuelle ne sont pas les prochains lots. Cette révision documentaire est validée par le joueur ; les lots futurs gardent leur validation séparée.

Le **lot 30 / étape 11A**, validé par le joueur, relie l’alcôve à la cuisine : reconnaissance à vide, pont livré et construit, puis récolte autonome de provisions. Démo `-- --demo-kitchen`, sauvegarde v17 ; [fiche du lot](docs/conception/gameplay-lot-30.md).

Le **lot 29 / étape 10**, validé par le joueur, ajoute le secours autonome au sol, le transport au lit, les bandages approvisionnés avec deux fibres et la convalescence. Démo `-- --demo-health`, sauvegarde v16 ; [fiche du lot](docs/conception/gameplay-lot-29.md).

Le **lot 28 / étape 8B**, validé par le joueur, **multiplie la surface jouable par quatre** et ajoute l’intimité des chambres construites selon leur propriétaire, leur porte et les habitants présents. Démo `-- --demo-privacy` avec quatre chambres attribuées, sommeil autonome et sauvegarde v15 ; [fiche du lot](docs/conception/gameplay-lot-28.md).

Le **lot 27 / étape 8A**, validé par le joueur, ajoute une **chambre compacte sur la grille** : Construire → Construire une chambre. Sol, cloisons et porte sont livrés puis fabriqués en trois étapes ; le lit se commande ensuite. Porte automatique, condamnation sûre, annulation/récupération et sauvegarde v14. Démo `-- --demo-room` ; [fiche du lot](docs/conception/gameplay-lot-27.md). La forme reste prédéfinie ; l’intimité réelle arrive en 8B.

Le **lot 26 / étape 7C**, validé par le joueur, ajoute un **brasero construit et entretenu sur le palier** : Travaux → Éclairage fixe de la passerelle. 4 bois + 2 fibres, puis combustible livré (2 bois / 180 s). Après sa commande, les nouveaux transferts attendent en cas de panne ; les trajets engagés finissent. Sauvegarde v13, démo `-- --demo-fixed-light` ; [fiche du lot](docs/conception/gameplay-lot-26.md).

Le **lot 25 / étape 7B**, validé par le joueur, ajoute les **transferts réguliers entre dépôts** : Stocks → Transferts réguliers entre dépôts. Les porteurs prennent les rotations selon leur priorité Transport, avec réservations, pause, rappel chargé et sauvegarde v12. Démo `-- --demo-transfers` ; [fiche du lot](docs/conception/gameplay-lot-25.md).

Le **lot 24 / étape 7A**, validé par le joueur, remplace les dépôts instantanés par des chantiers : **6 bois, 4 fibres, 16 s de fabrication**, puis 12 places. Un dépôt peut être construit dans la réserve à l’étage, approvisionné par l’échelle et le pont. Annulation/récupération, filtres et sauvegarde v11 sont intégrés. Démo `-- --demo-depot-build` ; [fiche du lot](docs/conception/gameplay-lot-24.md).

Le **lot 23 / étape 9B**, validé par le joueur, ajoute les **priorités de travail individuelles** (Habitants ou Travaux → Priorités). Récolte, transport et construction : 0 désactivé, 1 prioritaire, 2 normal, 3 secondaire. Besoins et charges en cours restent protégés ; préférences sauvegardées. Démo `-- --demo-priorities` ; [fiche du lot](docs/conception/gameplay-lot-23.md).

Le **lot 22 / étape 9A**, validé par le joueur, ajoute la désignation des fibres de l’alcôve : cliquez leur repère, puis **Désigner la récolte**. Deux habitants disponibles prennent leurs lanternes et transportent automatiquement les fibres. Annulation, besoins et sauvegarde sont intégrés. Démo `-- --demo-designations` ; [fiche du lot](docs/conception/gameplay-lot-22.md).

Le **lot 21 / étape 6C**, validé par le joueur, ajoute la sauvegarde sur place : **F5** enregistre la simulation puis met en pause, **F9** recharge après confirmation, **Espace** reprend les tâches. Positions, caisses, éclairages et réservations sont conservés sans rappel au refuge. Format v10 ; les anciens fichiers restent lisibles. Démo `-- --demo-live-save`, préparée pendant une traversée chargée. Voir [les règles et vérifications](docs/conception/gameplay-lot-21.md).

Le **lot 20 / étape 6B**, validé par le joueur, permet de rapporter les fibres de l’alcôve après un élargissement construit (6 bois, 4 fibres, 24 s). Les caisses réservent leurs fibres et une place au dépôt ; rappel et besoins urgents conservent la charge. Démo `-- --demo-alcove-haul` : **Rapporter des fibres**, puis **Espace**. La livraison permet de terminer le lit préparé, auquel il manque trois fibres. Ce lot introduisait le format v9 et la sauvegarde au refuge, remplacés par le lot 21. Voir [règles et tests du lot 20](docs/conception/gameplay-lot-20.md).

Le **lot 19 / étape 6A**, validé par le joueur, relie la lanterne à la fissure : reconnaissance d’une alcôve agrandie, autonomie vérifiée, retour pour besoins urgents ou rappel, suivi caméra et découverte mémorisée. **Travaux → Fissure et passage → Équiper → Explorer à la lanterne**. En partie normale, fabriquer la lanterne à l’atelier. Démo `-- --demo-alcove`, préparée en pause avec passage ouvert et H1 équipé ; cliquer **Explorer à la lanterne**, puis **Espace**. La démo possède un fichier de sauvegarde séparé. Voir [le détail et les tests](docs/conception/gameplay-lot-19.md).

Le **lot 18**, validé par le joueur, ajoute une fissure à inspecter, dégager et étayer : livraison de 6 bois et 4 fibres, puis 24 secondes de travaux. Initialement, une fois ouverte, elle permettait une visite à vide de l’alcôve attenante, avec file d’attente et retour autonome. **Travaux → Fissure et passage** ; démo `-- --demo-fissure`, puis **Espace**. Voir [les règles et limites](docs/conception/gameplay-lot-18.md).

Le **lot 17**, validé par le joueur, ajoute la lanterne de ceinture : 4 bois, 3 fibres, 16 secondes de fabrication et 180 secondes d’autonomie. Elle libère les mains pour l’échelle et les caisses. Démo : `-- --demo-lanterns`, puis **Espace** pour explorer la réserve. Après le retour, **Équiper**, puis **Rapporter du bois** teste une livraison éclairée avec la seconde lanterne. Voir [les règles et limites](docs/conception/gameplay-lot-17.md).

Le **lot 16**, validé par le joueur, ajoute les torches individuelles : fabrication à l’atelier après livraison de 2 bois et 1 fibre, équipement, destination au sol, combustible et retour anticipé. **Travaux → Éclairage et éclaireurs** gère ces actions. Démo en pause : `-- --demo-torches`, puis **Espace**. Torche en main : ni caisse ni échelle. Voir [les règles, essais et limites](docs/conception/gameplay-lot-16.md).

Le **lot 15**, validé par le joueur, ajoute les dépôts locaux : 12 places par casier, filtres, réservations de capacité, approvisionnement des lits et repas sur place. Le refuge possède son propre stock et le bandeau affiche le total de la colonie. Démo en pause : `-- --demo-depots`. Cliquer sur le casier pour le gérer ; **Espace** reprend. Le placement du casier reste provisoirement gratuit et instantané. Voir [le détail et les limites](docs/conception/gameplay-lot-15.md).

Le **lot 14**, validé par le joueur, remplace le paiement immédiat des lits par des livraisons physiques de bois et de fibres. Les chantiers incomplets attendent les matériaux ; leur annulation laisse des tas à récupérer. Démo en pause : `-- --demo-construction`. **Espace** reprend, **Construire → Gérer les couchages** montre le suivi. Voir [les règles et vérifications](docs/conception/gameplay-lot-14.md).

Voir la [roadmap par étapes](docs/conception/roadmap-production.md) et le [cahier des charges révisé](docs/conception/cahier-des-charges.md). Chaque étape est présentée et validée avant commit et push. Le PDF v0.1 est une archive de conception ; le suivi actuel est dans les documents Markdown.

## Assets Blender

Le [catalogue visuel des assets V01](docs/catalogue-assets-v01/index.html) rassemble douze planches générées pour préparer les modèles Blender : habitants, faune, objets et habitat. Les images, prompts et notes de production sont conservés dans `docs/catalogue-assets-v01/`. Ce sont des propositions à commenter avant adoption, sans remplacement des assets actuels.

Les habitants animés sont maintenant utilisés dans la **partie principale**, avec réservation, prise, transport et dépose des caisses. Les affectations affichent l'état des livraisons. **H** rappelle les porteurs avec leur charge ; **Libérer** annule avant la prise ou termine le retour si la caisse est déjà portée. Voir `docs/conception/gameplay-lot-06.md` pour les tests et limites. Le paramètre `-- --demo-deliveries` lance une partie avec quatre affectations préparées.

Le **lot 05** complète `scenes/interaction_review.tscn` avec les pivots de transport et la descente : **1** livraison, **2** montée, **3** descente. Les appuis et raccords sont vérifiés ; voir `docs/conception/assets-lot-05.md` pour les limites et le contrat d'intégration.

Les **interactions du lot 04** se testent dans `scenes/interaction_review.tscn` (**F6**) : **1** pour saisir, transporter et déposer une caisse ; **2** pour entrer sur l'échelle, monter et rejoindre le palier ; **R** pour recommencer. Détails et limites dans `docs/conception/assets-lot-04.md`.

Le **lot d'animations** se teste dans `scenes/animation_review.tscn` (**F6**) : repos, marche, portage de caisse, travail au marteau et échelle. Touches **1–5** pour choisir, **Espace** pour suspendre, **−/+** pour ralentir/accélérer, **D** pour activer le déplacement. Sources Blender, vitesses et limites : `docs/conception/assets-lot-03.md`. Ces animations sont encore indépendantes de l'IA du prototype.

Le **kit de refuge** se visite dans `scenes/refuge_review.tscn` (**F6**) : murs, fenêtre, porte ouvrante, échelle, passerelle et établi assemblés avec le mobilier et l'habitant de référence. **Espace** actionne la porte, **M** masque les murs et **L** change l'éclairage. Sources et limites dans `docs/conception/assets-lot-02.md`.

Un premier lot issu des choix de conception est disponible dans la scène **`scenes/asset_review.tscn`** (ouvrir puis **F6**) : habitant de référence animé, lit en boîte d'allumettes, seau-dé à coudre, caisse et plancher modulaire. Les sources sont dans `art_source/reference_01/`, les GLB dans `assets/models/reference_01/`. Consulter `docs/conception/assets-lot-01.md` pour les commandes, limites et critères de revue. Il s'agit d'une étude indépendante ; les modèles de la partie principale restent ceux du prototype.

Tous les modèles visibles sont créés avec Blender : sol et décor miniature, maison-boîte, établi, habitant au chapeau gland, miettes, bois et fibres. Les sources éditables sont dans `art_source/`, les exports glTF dans `assets/models/`. Le script `tools/create_assets.py` permet de les régénérer avec Blender 2.93 ou compatible :

```powershell
& 'D:\Program\blender2.93\blender.exe' --background --python tools/create_assets.py
```

`art_source/.gdignore` évite l'import automatique des fichiers Blender ; Godot utilise directement les GLB, sans dépendre de Blender au lancement. Aucun asset tiers téléchargé.

## Ambiance sous le plancher

Le décor comporte un bord de plancher supérieur en coupe, des poutres, des fondations, des toiles d'araignée, des échardes, des clous rouillés et des gravats. Ces éléments et les supports des torches sont modélisés dans Blender ; leurs sources sont `art_source/underfloor.blend` et `art_source/torch.blend`. Pour les régénérer :

```powershell
& 'D:\Program\blender2.93\blender.exe' --background --python tools/create_atmosphere.py
```

`scripts/atmosphere.gd` gère la lumière ambiante faible, trois ouvertures de lumière, la poussière en suspension et les torches animées. Les bâtiments anciens reçoivent une torche ; les lits et cloisons n’en ajoutent pas. Le passage des humains atténue momentanément l'éclairage venant du dessus.

Les shaders de `shaders/` produisent l'usure et la saleté du bois, les rais de lumière, les flammes et la poussière. Le plafond est ouvert au-dessus de la zone jouable pour conserver la visibilité. Les faisceaux utilisent une intégration volumétrique locale de 24 échantillons par pixel, limitée par la profondeur de la scène. Leur densité varie avec un bruit 3D lent ; chaque ouverture possède sa largeur, son inclinaison, sa diffusion et son intensité. Les anciens plans croisés et bandes lumineuses au sol sont supprimés. Le rendu reste compatible avec Compatibility.

Les poussières sont des particules douces orientées vers la caméra, distribuées le long de chaque faisceau. Les toiles sont des réseaux de courbes Blender sur des points irréguliers, avec affaissement, déchirures et fils libres. Les graines aléatoires sont fixes pour conserver une composition stable. Les courbes éditables sont conservées dans `art_source/cobweb_73.blend` et `art_source/cobweb_181.blend` ; les maillages assemblés sont inclus dans `underfloor.glb`. Le matériau de soie varie légèrement en intensité et bouge doucement. Le MSAA 4× améliore la lecture des fils fins.

Les effets visuels sont désactivés dans le moteur de rendu factice `--headless` pour éviter du travail inutile. Leur validation se fait par lancement graphique et captures ; les tests de simulation peuvent aussi être exécutés sans `--headless`. Les matériaux sont partagés et conservés en cache pour permettre la libération différée des scènes sans invalider leurs ressources graphiques.

## Validation

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/smoke.gd
```

Le test couvre récolte/livraison, affectation, coût et placement de construction, rappel, poursuite de la colonie après les anciens objectifs et défaite par détection. `tests/sleep.gd` vérifie les lits, travaux et leur persistance ; `tests/needs.gd` vérifie les besoins autonomes, la consommation et la migration des sauvegardes. Le paramètre utilisateur `-- --capture` en mode graphique enregistre une capture de la scène dans `artifacts/prototype.png`.

## Périmètre

Revue visuelle : lancer Godot avec `--script res://tests/visual_review.gd` pour enregistrer trois vues (ensemble, rotation, détail) et mesurer les intervalles de rendu. Mesure indicative sur la scène initiale : 16,61 ms de moyenne, 16,94 ms au 95e percentile, en 1920 × 1080 sur GTX 1650 avec synchronisation verticale. Cette mesure ne couvre pas une colonie développée.

Prototype jouable : habitants animés, livraisons, navigation autour des bâtiments, accès verticaux, exploration d’une réserve, sauvegarde au refuge et premiers besoins de sommeil. Le cahier des charges complet reste à développer. Pas encore d’audio ni de grands humains modélisés ; leur présence est simulée par un cycle et une jauge de soupçons. Les horaires, métiers, pièces modulaires, chaînes de production et territoires procéduraux restent des étapes futures.


Étape 11B / lot 31, validé par le joueur : première fourmi dans la cuisine, approche prudente et sauvegarde v18. Démo `-- --demo-ant`. Voir [la fiche du lot 31](docs/conception/gameplay-lot-31.md).
