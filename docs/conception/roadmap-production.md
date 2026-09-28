# Roadmap de production — terminer une boucle avant d’étendre le jeu

Révision du 27 septembre 2026. **Lot 19 / 6A publié : `8fd7b93`. Lot 20 / 6B publié : `ea3f133`. Lot 21 / 6C publié : `faf0b0f`. Lot 22 / 9A publié : `d580be5`. Lot 23 / 9B publié : `e63107e`. Lot 24 / 7A publié : `7065446`. Lot 25 / 7B publié : `a51eea7`. Lot 26 / 7C publié : `d64659c`. Lot 27 / 8A publié : `22994ee`. Lot 28 / 8B publié : `1e0b8e1`. Lot 29 / étape 10 publié : `eb761b3`. Lot 30 / 11A publié : `becadcc`, ambiance étendue : `52aedc7`. Lot 31 / 11B validé par le joueur, animations corrigées ; commit et push autorisés.** Catalogue publié : `1d88614`.

Le [cahier des charges](cahier-des-charges.md) définit la vision cible ; les [décisions de l’entretien](retours-et-decisions.md) conservent les choix du joueur. **Ce document fixe l’état actuel et l’ordre opérationnel.** Les mentions « prochaine étape » des fiches de lots restent historiques.

## Livraison autorisée — lot 46 : fibres de l’alcôve régulées

La récolte désignée de l’alcôve partage l’objectif de fibres du refuge : charges engagées incluses, caisse finale partielle et reprise après consommation. Les voyages manuels restent libres. Format v27 inchangé. Voir [lot 46](gameplay-lot-46.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 45 : reconnaissance autonome de l’alcôve (`90e0620`)

Désignation de la sortie, attribution selon Récolte, prise d’une lanterne adaptée, reconnaissance et retour au refuge. Rappel, annulation et reprise sauvegardée ; ouverture et travaux suivants restent commandés par le joueur. Format v27, anciennes sauvegardes lisibles. Voir [lot 45](gameplay-lot-45.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 44 : inspection désignée (`296fbdd`)

Inspection de la fissure attribuée à un habitant disponible selon Construction, sans sélection manuelle. Rappel, annulation et sauvegarde intégrés ; le joueur commande toujours séparément l’ouverture et l’exploration. Format v26, anciennes sauvegardes lisibles. Voir [lot 44](gameplay-lot-44.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 43 : annulation des fabrications (`d55b92d`)

Liste des commandes de torches et lanternes, annulation ciblée et récupération physique des matériaux, avec reprise sauvegardée. Une lanterne annulée désactive son objectif de production ; les autres commandes restent actives. Format v25, anciennes sauvegardes lisibles. Voir [lot 43](gameplay-lot-43.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 42 : fabrication automatique des lanternes (`4271887`)

Objectif total de lanternes, fabrication physique séquentielle et entretien distinct. Le chapitre propose le réglage ; le parcours complet est vérifié sans commande manuelle d’équipement, avec reprise sauvegardée. Format v24, anciennes sauvegardes lisibles. Voir [lot 42](gameplay-lot-42.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 41 : chapitre et gestion autonome (`75a9622`)

Le guide du premier chapitre propose les récoltes autonomes, objectifs de réserve et entretien des lanternes sans appliquer les réglages. Recette complète depuis une nouvelle partie sans affectation manuelle de récolteur, avec sauvegarde chargée. Voir [lot 41](gameplay-lot-41.md). Commit et push autorisés par le joueur. L’appréciation humaine de l’équilibrage reste ouverte.

## Livraison publiée — lot 40 : diagnostic des réserves (`33b2b33`)

Les objectifs de réserve indiquent les raisons d’attente et ouvrent les commandes correspondantes. Lecture des conditions de départ, sans lancer de travail ; panneau défilant et sauvegarde v23 inchangée. Voir [lot 40](gameplay-lot-40.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 39 : objectifs de réserve (`c209b8e`)

Seuil commun par ressource pour les récoltes autonomes au sol ; stocks et charges engagées pris en compte, transferts internes comptés une fois, caisses partielles et reprise après consommation. Sauvegarde v23. Voir [lot 39](gameplay-lot-39.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 38 : récoltes autonomes du refuge (`6f7732a`)

Désignations des cinq gisements au sol, attribution aux habitants sans affectation selon leurs priorités, suspension après les charges engagées et sauvegarde v22. Voir [lot 38](gameplay-lot-38.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 37 : suivi des chantiers (`d1e9456`)

Vue commune des chantiers à livraison physique : matériaux livrés, habitant engagé, priorités désactivées, récupération après annulation et accès aux commandes. Démo et reprise v21, sans nouveau champ sauvegardé. Voir [lot 37](gameplay-lot-37.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 36 : réserve de lanternes (`59add65`)

Objectif de 0 à 8 lanternes rangées et pleines, ravitaillement automatique des équipements existants et annulation avec récupération du bois. Panneau dédié et sauvegarde v21, automatisme désactivé pour les anciennes parties. Voir [lot 36](gameplay-lot-36.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 35 : entretien des lanternes (`2ef4909`)

Ravitaillement physique des lanternes rangées : 2 bois, 8 secondes de travail, autonomie finale de 180 secondes, même équipement. Rappel, priorités et sauvegarde v20 intégrés ; anciens fichiers lisibles. Correction du démarrage des récoltes manuelles avec lanterne. Voir [lot 35](gameplay-lot-35.md). Commit et push autorisés par le joueur.

## Livraison publiée — lot 34 : stocks régulés (`cf34ef9`)

Après le guidage (lot 32, `879212f`) et la recette depuis zéro (lot 33, `d268d8e`), ajout de seuils aux transferts : réserve source, objectif destination, caisses réservées prises en compte et reprise automatique. Sauvegarde v19 avec migration des anciennes liaisons sans limite. Voir [lot 34](gameplay-lot-34.md). Commit et push autorisés par le joueur.

## Livraison validée — guidage 11C / lot 32

Le guidage du premier chapitre est validé par le joueur le 28 septembre 2026 : dix objectifs issus de la simulation, prochaine action et accès direct aux commandes. Voir [lot 32](gameplay-lot-32.md). La recette technique du parcours intégral depuis une nouvelle partie est couverte par le [lot 33](gameplay-lot-33.md), dont le commit et le push sont autorisés par le joueur : dix objectifs, besoins et menaces actifs, reprise chargée depuis une sauvegarde. Un blocage de porte pendant les rappels est corrigé. L’appréciation de l’équilibrage reste ouverte ; 11C n’est pas déclarée validée dans son ensemble.

## Cap immédiat

**Atlas proposé le 25 septembre 2026 :** [carte du monde et fiches des secteurs](../atlas-monde-v01/index.html). Les tracés futurs restent à valider. Ce document de conception ne change ni l’ordre des lots ni le périmètre de 6A.

**Partir du refuge avec une lanterne, traverser un accès aménagé, récolter dans un secteur voisin, rapporter les ressources et reprendre la partie sans perte.**

Le projet reste un prototype intégré. Nous terminons cette boucle avant d’étendre la carte et le bestiaire. La refonte générale des personnages et du mobilier n’est pas prioritaire. Le catalogue sert aux assets nécessaires aux étapes engagées ; il ne commande pas douze chantiers 3D.

**11B / lot 31 validé : première fourmi sur le parcours cuisine**, recherche et transport de miettes, perception locale, attente ou détour prudent, sauvegarde v18. Voir la [fiche du lot 31](gameplay-lot-31.md). Livraison validée ; la suite sera engagée à la demande du joueur.

## Cible de gameplay confirmée avec le joueur

Les démos préparées servent à éprouver les mécaniques, pas à définir un déroulement imposé pour la partie finale. La cible est une gestion indirecte inspirée de RimWorld et Oxygen Not Included : le joueur désigne sur la carte les zones à explorer, les obstacles à creuser, les passages à étayer, les emplacements à éclairer et les constructions. Les habitants prennent les tâches selon leurs priorités, compétences, disponibilité et besoins ; ils récupèrent équipement et matériaux, travaillent et satisfont leurs besoins de façon autonome. Les ouvertures dangereuses restent soumises aux décisions du joueur.

Après 6C, prioriser le système général de tâches autonomes et les commandes de désignation sur la carte, avant de multiplier secteurs, faune ou assets. Faire évoluer les panneaux de démonstration vers des commandes contextuelles au clic et un tableau de priorités ; ne pas imposer la sélection manuelle d’un habitant pour chaque transport. Cette cible est confirmée ; le système général de tâches et cette évolution d’interface restent à développer et à valider par lots.

## État constaté

Bilan du lot 30 validé par le joueur : [fiche accès cuisine](gameplay-lot-30.md). Lot 29 publié et validé : [fiche soins et secours](gameplay-lot-29.md). Lot 28 publié et validé : [fiche 8B](gameplay-lot-28.md). Lot 27 publié et validé : [fiche 8A](gameplay-lot-27.md). Lot 26 publié et validé : [fiche 7C](gameplay-lot-26.md). Lot 25 validé et publié : [fiche 7B](gameplay-lot-25.md). Lot 24 publié et validé : [fiche 7A](gameplay-lot-24.md). Tests du passage élargi, récolte distante, 6A, fissure, lanternes, chantiers et sauvegardes exécutés sous Godot 4.7.2 ; détail des nouvelles vérifications dans [la fiche du lot 21](gameplay-lot-21.md). 6A, 6B et 6C sont validées.

| Domaine | Disponible aujourd’hui | Limite réelle |
| --- | --- | --- |
| Habitants | Modèles Blender animés : marche, travail, caisse, montée/descente et transitions validés | Diversité et finition ultérieures ; aucune refonte nécessaire pour la prochaine étape |
| Interface | Atelier miniature, désignation de l’alcôve et tableau de priorités 0–3 par habitant | Pas de désignation générique sur toute la carte |
| Navigation | Terrain 42 × 26 (surface ×4), obstacles, portes, échelle, passerelle, réservations et files | Liens spécialisés ; pas de navigation générale entre secteurs ni de capacité démontrée à 30–50 habitants |
| Transport | Prise, portage, dépose, annulation, rappel et liaisons récurrentes entre dépôts | Seuils par liaison ajoutés au lot 34 local ; missions de l’alcôve encore spécialisées |
| Besoins | Sommeil, faim et soif autonomes, accès physique à la nourriture et à l’eau | Secours au sol et soin au lit validés ; pas d’humeur, relations ni milieu simulé |
| Soins (lot 29 validé) | Blessure de scénario, secours autonome, deux fibres livrées, bandage, convalescence et reprise | Sol uniquement, entrée de blessure sur habitant disponible ; pas de combat, décès ou alimentation assistée |
| Couchages | Lits fabriqués, propriétaire, alcôves ; chambres compactes reconnues, intimité selon porte et occupants | Forme prédéfinie, un lit par chambre ; pas de dortoir multi-lit ni de murs libres |
| Chantiers | Livraisons physiques pour lits, éclairages, fissure, dépôts et étapes de chambre | Ateliers/anciens abris encore au paiement historique ; pont cuisine construit par missions éclairées dédiées au lot 30 ; pas de pont libre sur la carte |
| Dépôts | Chantiers 6 bois + 4 fibres + 16 s, stocks locaux, filtres, réservations ; casier distant à l’étage | Emplacement distant fixe ; pas de casier dans l’alcôve ni quotas |
| Éclairage | Torche et lanterne portées ; brasero construit au palier, combustible livré et autonomie | Un emplacement fixe ; protection des nouveaux transferts seulement, pas de couverture lumineuse générale ; ravitaillement des lanternes rangées ajouté au lot 35 local |
| Exploration | Réserve découverte à l’étage ; fissure inspectée, dégagée et étayée | Alcôve adjacente agrandie et reconnue à la lanterne ; décor mémorisé et récolte d’une source finie de fibres |
| Passage sud | Chantier 6 bois + 4 fibres puis traversée réservée dans les deux sens | Élargissement supplémentaire 6 bois + 4 fibres pour les caisses ; lanterne obligatoire |
| Sauvegarde | Format v18 local : fourmi, charge et politique d’approche ; pont et missions cuisine, patients et secours actifs, coordonnées étendues, chambres et portes, éclairage fixe, combustible, liaisons et chantiers : positions, tâches, caisses, lumière, réservations et horloge conservées ; migrations antérieures | Rechargement en pause |
| Cuisine (lot 30 validé) | L02 depuis l’alcôve, corniche à vide, pont 8 bois/4 fibres, biscuit fini, récolte autonome et files | Petite poche artisanale ; fourmi du lot 31 validée, pas de dépôt cuisine |
| Faune (lot 31 validé) et humains | Une fourmi riggée dans la cuisine : prélèvement, transport, perception locale, alerte et repli ; approche prudente des habitants | Obstacles fixes 2D, pas de combat ni de colonie animale ; menace humaine globale simplifiée |
| Catalogue | 12 planches, matériaux et vues de référence publiés | Concepts, pas de nouveaux modèles ; inventaire non exhaustif |

Points de contrôle : [restrictions du passage](../../scripts/fissure_passage.gd), [format v17](../../scripts/colony_save.gd), [sauvegarde sur place](../../scripts/game.gd), [lumière portée](../../scripts/carried_torches.gd), [chantiers](../../scripts/construction_logistics.gd), [dépôts](../../scripts/local_depots.gd). Le passage dirige les déplacements de la mission lumineuse ; la lanterne garde la gestion du combustible et du rangement au refuge.

### Livraisons closes, à ne pas refaire

| Étape | Résultat publié | Référence |
| --- | --- | --- |
| Besoins et couchages | Sommeil, faim, soif, lits et intimité | Lots 12–13, `3d1c9a3` |
| 1 | Première révision et méthode | `058345b` |
| 2 | Lits approvisionnés physiquement | [Lot 14](gameplay-lot-14.md), `de71c70` |
| 3 | Stocks locaux | [Lot 15](gameplay-lot-15.md), `930dfb3` |
| 4 | Torches | [Lot 16](gameplay-lot-16.md), `7c81e89` |
| 4 bis | Lanternes de ceinture | [Lot 17](gameplay-lot-17.md), `23c5eac` |
| 5 | Fissure aménageable et visite | [Lot 18](gameplay-lot-18.md), `06226a1` |
| Catalogue | Images, galerie et prompts | [V01](../catalogue-assets-v01/index.html), `1d88614` |

## Une seule livraison ouverte

1. Annoncer le résultat visible, ses limites et les assets indispensables.
2. Développer ce seul périmètre ; traiter ses régressions avant la suite.
3. Présenter une démo reproductible : action normale, interruption, reprise.
4. Attendre le retour du joueur et corriger dans le même lot.
5. Après validation et autorisation : commit, push et mise à jour du bilan. Engager la suite selon les instructions du joueur.

Cette révision ne vaut pas validation de tous les lots futurs. Toute idée nouvelle est différée sauf si elle bloque l’étape courante. Une refactorisation se limite aux dépendances du lot, sans réécriture générale parallèle.

La livraison est terminée si le résultat est observable, les blocages sont expliqués dans l’UI, les ressources sont conservées et les états persistants se rechargent selon le contrat annoncé. Toute incompatibilité de sauvegarde est annoncée avant l’essai.

## Étape 6 — Une expédition utile, en trois démonstrations

**6A, 6B et 6C sont validées et publiées : la boucle technique d’expédition est terminée.**

### 6A — Reconnaître le secteur adjacent avec une lanterne

**Réalisé et validé par le joueur le 27 septembre 2026.** Démo `-- --demo-alcove`. Voir [lot 19](gameplay-lot-19.md).

**Démonstration.** Un habitant équipé traverse la fissure ouverte, explore une petite zone adjacente et revient. Le joueur peut le suivre et savoir dans quel secteur il se trouve.

**À réaliser.** Étendre l’alcôve en une seule zone artisanale ; conserver les deux zones chargées dans la même scène au départ. Donner des identifiants stables aux secteurs, accès et missions. Relier navigation, mission et éclairage ; un habitant n’appartient qu’à un secteur à la fois. Consommer le combustible pendant marche, attente et traversée. Prévoir retour anticipé, besoin urgent et rappel entre secteurs. Distinguer zone inconnue et décor reconnu, sans révéler les changements hors observation.

**Assets.** Réutiliser habitant, lanterne, fissure et sol. Adapter uniquement les modules nécessaires à la circulation et à la lecture de la zone dans Blender, référence planche 12.

**Validation.** Aller-retour éclairé, file bidirectionnelle, rappel sur le seuil, besoin urgent, départ refusé si autonomie insuffisante, pause/x3 cohérentes. Découverte conservée après sauvegarde au refuge. Aucun habitant perdu, dupliqué ou téléporté.

**Limites annoncées.** Pas de caisse, récolte distante, nouvelle ressource, insecte ou génération procédurale. La sauvegarde reste après retour au refuge.

### 6B — Rapporter des ressources pour améliorer le refuge

**Réalisé et validé par le joueur.** Démo `-- --demo-alcove-haul`. Voir [lot 20](gameplay-lot-20.md).

**Démonstration.** Récolter des fibres dans la zone reconnue, revenir chargé, livrer au refuge puis utiliser les fibres dans un lit. Réutiliser une ressource avec modèle et recette existants ; ne pas ouvrir une chaîne de résine pour justifier l’expédition.

**Dépendance obligatoire : le gabarit du passage.** La fissure actuelle interdit réellement les caisses. Prévoir une amélioration approvisionnée physiquement, avec largeur et modèle adaptés au portage ; coût fixé pour ce lot : 6 bois, 4 fibres, puis 24 secondes de travaux. Avant achèvement, le passage chargé reste interdit. Ne pas supprimer seulement le contrôle logiciel en laissant la caisse traverser les parois.

**À réaliser.** Une source distante, une mission de récolte puis livraison, réservation du prélèvement et de la place au dépôt. Conserver charge et propriétaire lors du retour. Utiliser la lanterne de ceinture et les règles de besoins/rappel. La sauvegarde reste stabilisée au refuge, limite indiquée dans la démo.

**Assets.** Fibres et caisse existantes ; variante du passage élargi si nécessaire. Pas de kit complet de secteur.

**Validation.** Aller-retour à vide puis chargé, deux porteurs concurrents, dépôt plein, rappel chargé, besoin urgent, autonomie insuffisante. Contrôler source + charge + stocks + chantier + matériaux incorporés : aucune perte ou duplication. Montrer le lit rendu possible par la livraison.

### 6C — Sauvegarder et reprendre l’expédition

**Réalisé et validé par le joueur.** Démo `-- --demo-live-save` ; [fiche du lot 21](gameplay-lot-21.md).

**Démonstration.** Sauvegarder un habitant dans l’autre secteur ou en trajet, recharger, poursuivre son retour avec sa charge et sa lanterne dans le même état.

**À réaliser.** Sérialiser secteurs, découvertes, position, mission, charge, réservations, files et combustible. Restaurer les tâches une seule fois et garder la même horloge de besoins dans les deux secteurs. Migrer v9 (et conserver les migrations antérieures) en préservant stocks et travaux. Une capture cohérente en fin de pas de simulation est possible ; pas de rappel général caché sous le nom de sauvegarde en expédition.

**Assets.** Aucun nouveau modèle ; indications de sauvegarde dans l’interface existante.

**Validation.** Sauvegarde avant départ, en attente, pendant traversée, pendant prélèvement et au retour chargé ; demandes répétées ; migration v9 ; fichier précédent protégé si données invalides. Comparer habitants, ressources, équipement et réservations. Rejouer 6A–6B depuis une partie ordinaire.

**Point d’arrêt.** Une expédition utile et persistante fonctionne. On évalue la boucle avant d’étendre son contenu.

## Suite ordonnée après l’expédition

Les numéros 7–11 sont conservés pour correspondre aux anciens documents. Les lots 9A–9B passent en tête pour respecter la priorité confirmée par le joueur : désignations et autonomie avant extension du contenu. **9A, 9B, 7A–7C, 8A–8B et 10 sont publiés ; 11A est validé par le joueur** ; les autres sont non commencés. Chaque sous-lot sera présenté et validé séparément ; son détail sera fixé à son ouverture.

| Ordre | Résultat attendu | Preuve de fonctionnement | Assets strictement utiles |
| --- | --- | --- | --- |
| 9A — Désignations et attribution autonome | Désigner sur la carte un travail utilisant les mécaniques existantes ; un habitant disponible prend la tâche et prépare son équipement | Deux habitants peuvent exécuter un ordre sans sélectionner chaque porteur ; réservation unique, annulation et besoins prioritaires | Interface contextuelle, modèles actuels |
| 9B — Priorités de travail | Collecte, transport et construction choisis selon priorités individuelles ; urgences vitales au-dessus | Artisan servi par porteur ; absence redistribuant le travail ; impossibilité expliquée et sauvegarde | Tableau de priorités, pas de nouvelles tenues |
| 7A — Dépôt distant construit | Construire le casier par livraison et le remplir ; remplacer son installation gratuite par un chantier | Dépôt plein, filtre changé, annulation, reprise des stocks des deux côtés | Casier existant, états de chantier |
| 7B — Transport régulier (lot 25 validé) | Ordre simple de transfert entre deux dépôts, besoins et retour prioritaires | Plusieurs rotations sans ordonner chaque trajet ; arrêt expliqué si accès/capacité manquent | Aucun nouveau personnage ou véhicule |
| 7C — Éclairage fixe entretenu (lot 26 validé) | Construire un point lumineux et le ravitailler pour sécuriser la route | Panne, ravitaillement interrompu, reprise et suspension des trajets non sûrs | Support planche 08, combustible minimal à usage défini |
| 8A — Chambre construite (lot 27 validé) | Plan compact sur grille, sol/cloisons/porte puis lit, matériaux livrés | Pièce ouverte/fermée, porte bloquée, annulation ; aucun habitant enfermé | Lit/porte existants, modules de cloisons manquants |
| 8B — Intimité réelle et terrain ×4 (lot 28 validé) | Pièces détectées, propriété et intimité selon occupation, couchage au sol conservé | Chambre partagée puis individuelle, propriétaire absent, sauvegarde | Aucun nouvel ensemble décoratif |
| 10 — Soins et secours minimaux (lot 29 validé) | Blessure de scénario, incapacité, secours au lit, soin consommant une ressource | Secouriste interrompu, lit inaccessible, reprise d’un blessé ; pas de mort soudaine ajoutée | Bandage, animations nécessaires, lit réutilisé |
| 11A — Accès cuisine (lot 30 validé) | Parcours artisanal vers des provisions et pont construit par livraison | Chantier, file au pont, passage chargé, retour et sauvegarde | Passerelle adaptée, complément cuisine limité |
| 11B — Première fourmi | Une espèce riggée : recherche et transport de miettes, perception locale, réaction lisible | Observer puis contourner ou attendre une fenêtre ; aucune détection à travers obstacle | Planche 03, rig, animations et charge nécessaires |
| 11C — Premier chapitre | Nouvelle partie : aménager, préparer, ouvrir, explorer la cuisine, rapporter les provisions ; aide légère | Parcours sans commandes de démo, erreurs récupérables et reprise en expédition | Corrections de lisibilité ciblées |

**Pourquoi cet ordre ?** Transport et sauvegarde rendent l’exploration fiable. Dépôts et priorités réduisent les manipulations répétitives. La fourmi intervient sur un trajet déjà exploitable. Les soins précèdent l’éventuelle introduction de blessures par la faune ; un système de combat complet n’est pas requis pour la première fourmi.

Recette 7C retenue : 4 bois + 2 fibres + 16 s, puis 2 bois pour 180 s de combustible. Métal, mica, cire et résine ne deviennent pas tous des chaînes de production parce qu’ils figurent sur une image. En 8A, convertir les constructions concernées au chantier physique, sans réécriture de tout le bâti.

**J3, premier test d’ensemble.** Le parcours cuisine complet doit donner envie de gérer et d’explorer. La durée de 20–30 minutes reste une hypothèse, pas un délai imposé à l’aménagement. Des parties de J4 peuvent précéder J3 sans clore J4.

## Production artistique : compléter avant de refaire

- Garder habitants, sacs, lits, atelier, dépôts, torches, lanternes et passages fonctionnels.
- Produire seulement les assets indispensables au lot engagé, avec source Blender, export, textures et essai dans Godot.
- Corriger un défaut d’usage immédiatement : appui, attache, collision ou silhouette illisible. Reporter les refontes esthétiques générales.
- Utiliser le [catalogue](../catalogue-assets-v01/README.md) comme référence ; recouper les vues générées avec les gabarits et animations existants.
- Une tenue n’ajoute pas un métier ; une image de rat ou de cloporte n’engage pas sa production.
- Mesurer sur le rendu actuel avant d’augmenter lumières, textures ou géométrie. Ne pas promettre un résultat « AAA » à partir des planches.

**Revue artistique générale après 11C.** Choisir alors un asset étalon, mesurer son coût et décider des améliorations à étendre. Aucun remplacement en masse avant cette preuve.

## Objectifs conservés mais différés

| Après le premier chapitre | Condition avant ouverture |
| --- | --- |
| Production alimentaire, eau durable, recrutement, traits, humeur, relations | Priorités fiables et essai de 10 habitants sur trois jours simulés |
| Température, humidité, fumée, chauffage, ventilation | Modèle de milieu borné, mesurable et expliqué |
| Routines humaines, perception locale | Informations observables, conséquences et retours possibles |
| Araignée, souris, défense, domestication utile | Retour sur la fourmi et fonctions distinctes ; une espèce à la fois |
| Cloisons de maison, fondations, recherche, monte-charges, construction verticale | Première carte/logistique consolidées et sélection des étages fiable |
| Grand Refuge, rénovation, migration, ville souterraine indépendante | Progression et sauvegarde des secteurs testables |
| Extérieur procédural persistant et avant-postes | Campagne maison consolidée, budgets de génération/persistance mesurés |
| Refonte globale des modèles, variantes et audio complet | Priorisation après le premier chapitre ; corrections de lisibilité autorisées avant |

Ces reports ne suppriment pas la ville, les relations, le milieu ou la domestication de la direction retenue. Naissances, simulation exhaustive des gaz et plusieurs colonies complètes ne sont pas déduites des références RimWorld/ONI.

## Jalons et contrôle de progression

| Jalon | État actuel | Preuve encore attendue |
| --- | --- | --- |
| J0 — Direction | Direction, premiers assets et catalogue disponibles | Budgets mesurés, inventaire non exhaustif |
| J1 — Socle | Livraisons, stocks locaux, besoins, sauvegarde au refuge | Sauvegarde en expédition et tâches générales |
| J2 — Travaux et déplacements | Circulation spécialisée et premiers chantiers | Habitat libre, pont construit, goulet à 20 habitants |
| J3 — Première aventure | Éclairage et première fissure disponibles | Expédition puis cuisine, fourmi et tutoriel |
| J4 — Colonie durable | Besoins élémentaires et couchages | Priorités, soins, production, recrutement ; 10 habitants sur trois jours |
| J5 — Maison vivante | Ambiance et menace globale du prototype | Routines, perception locale et faune |
| J6 — Campagne | Conception cible | Progression jusqu’au Grand Refuge et à la ville |
| J7 — Finition | Vérifications ciblées par lot | Audio, accessibilité, équilibre, performances et build complet |

À chaque lot : conservation des ressources, réservations libérées, besoins/rappel, pause/vitesse, migration et reprise selon périmètre. Réutiliser les suites navigation, livraisons, construction, dépôts, besoins, éclairage et fissure ; ajouter les cas nouveaux utiles. Mesurer progressivement 10, 20 puis 30–50 habitants. Cette dernière cible n’est pas démontrée.

**11B / lot 31 validé : fourmi intégrée, concurrence sur les miettes, attente et détour, sauvegarde v18.**
