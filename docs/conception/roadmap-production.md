# Roadmap de production — terminer une boucle avant d’étendre le jeu

Révision du 27 septembre 2026. **Lot 19 / 6A publié : `8fd7b93`. Lot 20 / 6B publié : `ea3f133`. Lot 21 / 6C publié : `faf0b0f`. Lot 22 / 9A publié : `d580be5`. Lot 23 / 9B validé par le joueur ; commit et push autorisés.** Catalogue publié : `1d88614`.

Le [cahier des charges](cahier-des-charges.md) définit la vision cible ; les [décisions de l’entretien](retours-et-decisions.md) conservent les choix du joueur. **Ce document fixe l’état actuel et l’ordre opérationnel.** Les mentions « prochaine étape » des fiches de lots restent historiques.

## Cap immédiat

**Atlas proposé le 25 septembre 2026 :** [carte du monde et fiches des secteurs](../atlas-monde-v01/index.html). Les tracés futurs restent à valider. Ce document de conception ne change ni l’ordre des lots ni le périmètre de 6A.

**Partir du refuge avec une lanterne, traverser un accès aménagé, récolter dans un secteur voisin, rapporter les ressources et reprendre la partie sans perte.**

Le projet reste un prototype intégré. Nous terminons cette boucle avant d’étendre la carte et le bestiaire. La refonte générale des personnages et du mobilier n’est pas prioritaire. Le catalogue sert aux assets nécessaires aux étapes engagées ; il ne commande pas douze chantiers 3D.

**Étape validée : 9B, priorités de travail individuelles. Prochaine livraison : dépôt distant construit (7A).** La fourmi viendra sur le parcours cuisine, après les transports et la sauvegarde nécessaires, plutôt que dans une démonstration isolée.

## Cible de gameplay confirmée avec le joueur

Les démos préparées servent à éprouver les mécaniques, pas à définir un déroulement imposé pour la partie finale. La cible est une gestion indirecte inspirée de RimWorld et Oxygen Not Included : le joueur désigne sur la carte les zones à explorer, les obstacles à creuser, les passages à étayer, les emplacements à éclairer et les constructions. Les habitants prennent les tâches selon leurs priorités, compétences, disponibilité et besoins ; ils récupèrent équipement et matériaux, travaillent et satisfont leurs besoins de façon autonome. Les ouvertures dangereuses restent soumises aux décisions du joueur.

Après 6C, prioriser le système général de tâches autonomes et les commandes de désignation sur la carte, avant de multiplier secteurs, faune ou assets. Faire évoluer les panneaux de démonstration vers des commandes contextuelles au clic et un tableau de priorités ; ne pas imposer la sélection manuelle d’un habitant pour chaque transport. Cette cible est confirmée ; le système général de tâches et cette évolution d’interface restent à développer et à valider par lots.

## État constaté

Bilan actualisé au lot 23, validé par le joueur. [Fiche 9B](gameplay-lot-23.md). Tests du passage élargi, récolte distante, 6A, fissure, lanternes, chantiers et sauvegardes exécutés sous Godot 4.7.2 ; détail des nouvelles vérifications dans [la fiche du lot 21](gameplay-lot-21.md). 6A, 6B et 6C sont validées.

| Domaine | Disponible aujourd’hui | Limite réelle |
| --- | --- | --- |
| Habitants | Modèles Blender animés : marche, travail, caisse, montée/descente et transitions validés | Diversité et finition ultérieures ; aucune refonte nécessaire pour la prochaine étape |
| Interface | Atelier miniature, désignation de l’alcôve et tableau de priorités 0–3 par habitant | Pas de désignation générique sur toute la carte |
| Navigation | Obstacles au sol, porte, échelle, passerelle, réservations et files | Liens spécialisés ; pas de navigation générale entre secteurs ni de capacité démontrée à 30–50 habitants |
| Transport | Prise, portage, dépose, annulation et rappel | Caisses possibles après élargissement ; une mission par aller-retour, pas de liaison automatique permanente |
| Besoins | Sommeil, faim et soif autonomes, accès physique à la nourriture et à l’eau | Pas de soins, humeur, relations ni milieu simulé |
| Couchages | Lits fabriqués, propriétaire, confort et alcôves d’intimité | Meubles prédéfinis ; pas de pièces construites librement |
| Chantiers | Livraisons physiques pour lits, équipements lumineux et fissure | Ateliers/anciens abris encore au paiement historique ; pas de pont construit par le joueur |
| Dépôts | Stocks locaux, capacité, filtres et réservations, repas et approvisionnement | Casier gratuit et instantané ; pas de transfert automatique ni quotas |
| Éclairage | Torche au sol ; lanterne compatible avec caisse et échelle ; autonomie et retour anticipé | Pas de recharge ni éclairage fixe construit ; remplacement par fabrication |
| Exploration | Réserve découverte à l’étage ; fissure inspectée, dégagée et étayée | Alcôve adjacente agrandie et reconnue à la lanterne ; décor mémorisé et récolte d’une source finie de fibres |
| Passage sud | Chantier 6 bois + 4 fibres puis traversée réservée dans les deux sens | Élargissement supplémentaire 6 bois + 4 fibres pour les caisses ; lanterne obligatoire |
| Sauvegarde | Format v10 : positions, tâches, caisses, lumière, réservations et horloge conservées ; migrations antérieures | Rechargement en pause |
| Faune et humains | Ambiance et menace humaine globale simplifiée | Pas de fourmi jouable, de perception animale locale ni de routines humaines détaillées |
| Catalogue | 12 planches, matériaux et vues de référence publiés | Concepts, pas de nouveaux modèles ; inventaire non exhaustif |

Points de contrôle : [restrictions du passage](../../scripts/fissure_passage.gd), [format v10](../../scripts/colony_save.gd), [sauvegarde sur place](../../scripts/game.gd), [lumière portée](../../scripts/carried_torches.gd), [chantiers](../../scripts/construction_logistics.gd), [dépôts](../../scripts/local_depots.gd). Le passage dirige les déplacements de la mission lumineuse ; la lanterne garde la gestion du combustible et du rangement au refuge.

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

Les numéros 7–11 sont conservés pour correspondre aux anciens documents. Les lots 9A–9B passent en tête pour respecter la priorité confirmée par le joueur : désignations et autonomie avant extension du contenu. **9A est publié ; 9B est réalisé et validé par le joueur** ; les autres sont non commencés. Chaque sous-lot sera présenté et validé séparément ; son détail sera fixé à son ouverture.

| Ordre | Résultat attendu | Preuve de fonctionnement | Assets strictement utiles |
| --- | --- | --- | --- |
| 9A — Désignations et attribution autonome | Désigner sur la carte un travail utilisant les mécaniques existantes ; un habitant disponible prend la tâche et prépare son équipement | Deux habitants peuvent exécuter un ordre sans sélectionner chaque porteur ; réservation unique, annulation et besoins prioritaires | Interface contextuelle, modèles actuels |
| 9B — Priorités de travail | Collecte, transport et construction choisis selon priorités individuelles ; urgences vitales au-dessus | Artisan servi par porteur ; absence redistribuant le travail ; impossibilité expliquée et sauvegarde | Tableau de priorités, pas de nouvelles tenues |
| 7A — Dépôt distant construit | Construire le casier par livraison et le remplir ; remplacer son installation gratuite par un chantier | Dépôt plein, filtre changé, annulation, reprise des stocks des deux côtés | Casier existant, états de chantier |
| 7B — Transport régulier | Ordre simple de transfert entre deux dépôts, besoins et retour prioritaires | Plusieurs rotations sans ordonner chaque trajet ; arrêt expliqué si accès/capacité manquent | Aucun nouveau personnage ou véhicule |
| 7C — Éclairage fixe entretenu | Construire un point lumineux et le ravitailler pour sécuriser la route | Panne, ravitaillement interrompu, reprise et suspension des trajets non sûrs | Support planche 08, combustible minimal à usage défini |
| 8A — Chambre construite | Un niveau, grille, murs/sol/porte/lit, matériaux livrés | Pièce ouverte/fermée, porte bloquée, annulation ; aucun habitant enfermé | Lit/porte existants, modules de cloisons manquants |
| 8B — Intimité réelle | Pièces détectées, propriété et intimité selon occupation, couchage au sol conservé | Chambre partagée puis individuelle, propriétaire absent, sauvegarde | Aucun nouvel ensemble décoratif |
| 10 — Soins et secours minimaux | Blessure de scénario, incapacité, secours au lit, soin consommant une ressource | Secouriste interrompu, lit inaccessible, reprise d’un blessé ; pas de mort soudaine ajoutée | Bandage, animations nécessaires, lit réutilisé |
| 11A — Accès cuisine | Parcours artisanal vers des provisions et pont construit par livraison | Chantier, file au pont, passage chargé, retour et sauvegarde | Passerelle adaptée, complément cuisine limité |
| 11B — Première fourmi | Une espèce riggée : recherche et transport de miettes, perception locale, réaction lisible | Observer puis contourner ou attendre une fenêtre ; aucune détection à travers obstacle | Planche 03, rig, animations et charge nécessaires |
| 11C — Premier chapitre | Nouvelle partie : aménager, préparer, ouvrir, explorer la cuisine, rapporter les provisions ; aide légère | Parcours sans commandes de démo, erreurs récupérables et reprise en expédition | Corrections de lisibilité ciblées |

**Pourquoi cet ordre ?** Transport et sauvegarde rendent l’exploration fiable. Dépôts et priorités réduisent les manipulations répétitives. La fourmi intervient sur un trajet déjà exploitable. Les soins précèdent l’éventuelle introduction de blessures par la faune ; un système de combat complet n’est pas requis pour la première fourmi.

En 7C, fixer une recette minimale avant développement. Métal, mica, cire et résine ne deviennent pas tous des chaînes de production parce qu’ils figurent sur une image. En 8A, convertir les constructions concernées au chantier physique, sans réécriture de tout le bâti.

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

**9B / lot 23 validé : priorités individuelles, collecte/transport/construction arbitrés au prochain travail, besoins prioritaires et persistance. Prochaine livraison : 7A, dépôt distant construit.**
