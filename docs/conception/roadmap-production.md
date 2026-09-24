# Suite de production — étapes à valider

Révision du 24 septembre 2026. Base publiée : `3d1c9a3`, lots 12–13. **Étape 1 validée par le joueur ; les étapes suivantes seront présentées séparément.**

Ce plan complète le [cahier des charges](cahier-des-charges.md) et applique les [décisions de l'entretien](retours-et-decisions.md). Les jalons J0–J7 désignent des objectifs de produit ; les étapes ci-dessous sont les livraisons successives, plus petites. Les nombres proposés restent ajustables après essai.

**Suivi :** étape 1 publiée dans `058345b`. Étape 2 validée et publiée dans `de71c70` ([lot 14](gameplay-lot-14.md)). Étape 3 validée et publiée dans `930dfb3` ([lot 15](gameplay-lot-15.md)). Étape 4 validée et publiée dans `7c81e89` ([lot 16](gameplay-lot-16.md)). Étape 4 bis validée par le joueur dans le [lot 17](gameplay-lot-17.md), publication autorisée. Les étapes 5 et suivantes ne sont pas commencées.

## Notre fonctionnement

Une seule étape en développement à la fois. Pour chaque étape : réaliser le périmètre annoncé, vérifier les cas d'échec, présenter le résultat et ses limites, puis attendre la validation du joueur. Corriger si nécessaire. **Après validation seulement : commit, push sur GitHub, puis étape suivante.** Une ancienne validation ne vaut pas accord sur une nouvelle livraison.

Les étapes de gameplay auront une démo reproductible dans Godot, des commandes indiquées et une scène lisible sans explication technique. Les étapes documentaires seront présentées sous forme de documents. Les sauvegardes existantes devront être migrées ou une incompatibilité devra être annoncée avant l'essai. Les nouveaux modèles seront produits dans Blender, avec sources, exports et textures.

## Bilan de départ

| Jalon du cahier des charges | État réel | Ce qui empêche de le considérer terminé |
| --- | --- | --- |
| J0 — direction et scène étalon | Direction et premiers assets validés | Catalogue complet et budgets de production non vérifiés |
| J1 — socle de simulation | Réservations, livraisons, sauvegarde au refuge | Tâches générales, stocks locaux et sauvegarde en expédition |
| J2 — déplacements et travaux | Sol, échelle, passerelle, porte, lits fabriqués | Livraison des matériaux, construction libre, test de foule |
| J3 — première aventure | Reconnaissance de la réserve orientale | Véritable liaison de secteurs, cuisine, pont construit, fourmis, tutoriel |
| J4 — vie quotidienne | Faim, soif, sommeil et couchages autonomes | Métiers, soins, relations, recrutement et production alimentaire |
| J5 — écosystème et humains | Ambiance et cycle global de menace | Perception locale, routines et animaux fonctionnels |
| J6 — campagne | Direction définie | Recherches, migration, Grand Refuge et ville indépendante |
| J7 — finition | Tests ciblés et première direction visuelle | Audio, équilibrage, accessibilité et performances à l'échelle cible |

Le jeu reste un prototype intégré. Les 30–50 habitants sont une cible, pas une capacité démontrée. Les lits avec séparation ne constituent pas encore un système de pièces libres ; leur confort est une valeur de couchage, pas un calcul global de bonheur.

## Ordre des prochaines démonstrations

| Étape | Résultat visible | Dépendances | Lien aux jalons |
| --- | --- | --- | --- |
| 1 — ce dossier | Bilan exact, ordre de travail, critères et assets | Entretien et lots publiés | J0–J7 |
| 2 — chantier approvisionné | Un lit reçoit physiquement ses matériaux avant fabrication | Livraisons et lits existants | J1–J2 |
| 3 — réserves locales | Un petit dépôt alimente les travaux et les besoins proches | Étape 2 | J1–J2 |
| 4 — torche individuelle | Fabriquer, équiper et utiliser une torche dans l'obscurité | Tâches, matériaux et équipement | J2–J3 |
| 4 bis — lanterne de ceinture | Explorer la réserve à l’étage avec les mains libres et une autonomie surveillée | Étape 4, échelle et portage | J2–J3 |
| 5 — passage aménageable | Découvrir puis ouvrir une fissure réellement traversable | Chantier, navigation, torche | J2–J3 |
| 6 — premier secteur relié | Partir, récolter ailleurs, revenir et retrouver ses découvertes | Étape 5 et persistance des voyages | J1–J3 |
| 7 — route d'exploitation | Dépôt distant, ravitaillement, éclairage fixe construit | Étapes 3–6 | J3 |
| 8 — habitat aménageable | Construire une chambre avec lit, cloisons et porte | Travaux et stocks fiables | J2–J4 |
| 9 — métiers et priorités | Répartir les travaux sans affecter chaque trajet | Tâches générales | J4 |
| 10 — soins et secours | Relever puis soigner un habitant blessé | Métiers, lits, trajets | J4–J5 |
| 11 — première aventure cuisine | Aménager le refuge, franchir un pont construit, éviter les fourmis, rapporter des provisions | Étapes 2–10 | J3 |

Les torches et la première liaison arrivent avant l'extension de l'habitat : elles rendent rapidement l'exploration tangible, après les fondations nécessaires aux transports. Chaque étape peut être divisée si sa démonstration devient trop large ; on conserve alors une validation et un commit par sous-étape.

## 2 — Un vrai chantier approvisionné

**Démonstration.** Désigner un lit. Un habitant prend bois et fibres au dépôt, les apporte sur place, puis fabrique le lit. Le panneau distingue « matériaux manquants », « transport en cours », « prêt à fabriquer » et « fabrication ».

**Règles.** Réserver n'est pas consommer. Un matériau se trouve soit au dépôt, soit porté, soit livré au chantier, soit incorporé au bâtiment. Les autres travaux ne peuvent pas le réserver deux fois. Les besoins personnels et le rappel interrompent proprement la tâche ; la reprise conserve l'avancement. Le premier contrat général de tâche couvre ce trajet, sans réécrire tous les systèmes en une fois.

**Annulation proposée.** Avant fabrication, les matériaux livrés deviennent récupérables sur place ; une charge en route revient au dépôt. Aucun remboursement magique en plus du stock physique. Une suppression après fabrication relève plus tard de la déconstruction.

**Assets.** Réutiliser caisse, matériaux, lit, marteau et animations existants ; compléter seulement les tas de chantier et états visuels manquants. Aucun nouveau personnage nécessaire.

**Validation.** Deux chantiers concurrents avec un stock insuffisant ; annulation avant prise, pendant transport et après livraison ; rappel pendant travail ; besoin urgent ; sauvegarde au refuge puis reprise. Vérifier conservation des ressources, absence de tâche bloquée et lit utilisable seulement une fois terminé.

## 3 — Des stocks qui existent à un endroit

**Démonstration.** Placer un petit dépôt près d'une ressource, choisir les ressources acceptées et voir les habitants y déposer puis y prendre des matériaux. Afficher stock local, réservé et capacité restante ; le total de la colonie devient une synthèse.

**Règles.** Le dépôt du refuge devient lui aussi un stock local. Une destination pleine ou inaccessible provoque une nouvelle destination valide ou une attente expliquée. Réserver une place avant de commencer un transport. Manger et boire implique d'atteindre une réserve accessible. Commencer avec capacité et filtres ; quotas minimum/maximum et priorités avancées viendront après cet essai.

**Assets.** Petit casier récupéré, contenu visible selon remplissage, icône de dépôt. Source Blender et collisions permettant de s'approcher sans bloquer la porte.

**Validation.** Dépôt plein, filtre modifié pendant un trajet, deux porteurs concurrents, rupture de nourriture, rappel et chargement d'une ancienne sauvegarde sans duplication.

## 4 — Des torches portées pour explorer

**Démonstration.** Fabriquer une torche à l'atelier, l'affecter à un éclaireur et parcourir une portion assombrie de la carte actuelle. La lumière suit sa main, révèle poussière et relief, varie doucement et éclaire sans traverser les obstacles lorsque la technique de rendu le permet. Vérifier explicitement ce dernier point dans le rendu Compatibility.

**Équipement et autonomie.** Un objet possède un état rangé, équipé, allumé ou épuisé et une réserve de combustible persistante. La consommation dépend du temps simulé ; pause et chargement ne font pas perdre de combustible. Coût, durée, rayon et vitesse de consommation seront des paramètres testés dans la démo, sans les considérer déjà équilibrés.

**Mains et trajets.** Première règle proposée : torche en main incompatible avec une caisse à deux mains et avec l'échelle. Le système doit expliquer le conflit avant le départ. Pour transporter dans le noir, utiliser un éclaireur accompagnateur ou aménager un éclairage fixe lors de l'étape 7. Ne pas ranger simplement la torche en laissant un habitant progresser aveuglément. Une lanterne attachée sera une amélioration ultérieure, après validation de son usage et de sa silhouette.

**Sécurité de retour.** Avant l'expédition, comparer l'autonomie au trajet aller-retour estimé avec marge. Recalculer en cas de détour, d'attente ou de besoin urgent. Alerter puis rentrer automatiquement avant épuisement ; refuser un départ manifestement impossible. Si la route devient impraticable, afficher le blocage et permettre le rappel ou l'assistance, sans téléporter l'habitant. L'effet de la lumière sur les insectes attend leur IA : aucune règle universelle « toute bête fuit le feu ».

**Assets.** Torche miniature faite d'écharde et de fibre, embout consumé, attaches main/rangement, poses de marche et d'observation, flamme, braises discrètes et icône d'autonomie. Contrôler sac, vêtements et intersections. Réutiliser les effets existants s'ils tiennent le budget.

**Validation.** Caméra normale et rapprochée ; pause/vitesse ; épuisement ; recharge ou remplacement à l'atelier ; incompatibilité de charge ; rappel ; sauvegarde ; comparaison des performances avec une puis plusieurs torches visibles. Limiter les lumières avec ombres selon les mesures, sans changer les règles de combustible hors écran.

## 4 bis — Une lanterne pour accéder à l’étage

**Décision validée après essai du lot 16.** La torche reste réservée aux parcours sans échelle. Une lanterne fermée fixée à la ceinture permettra de garder les deux mains libres. Elle se fabrique à l’atelier et conserve une autonomie surveillée, avec refus de départ impossible et retour anticipé. Coût et durée seront proposés avec la démonstration.

**Démonstration suivante.** Fabriquer et équiper une lanterne, cliquer la réserve à l’étage, monter l’échelle, traverser la passerelle puis rentrer. Vérifier ensuite le port d’une caisse avec la lanterne, les besoins, le rappel et la sauvegarde. Contrôler dans Blender et Godot les attaches, les barreaux, les vêtements et le sac pendant les animations. L’éclairage fixe construit viendra ensuite pour les trajets réguliers. Cette étape est implémentée et validée par le joueur ; publication autorisée. Proposition : 4 bois + 3 fibres, 16 s de travail, 180 s d’autonomie et 24 s de marge. La démonstration inclut un aller-retour de reconnaissance puis une caisse récoltée et livrée avec lanterne ; les trajets réguliers restent une étape ultérieure.

## 5 — Une fissure qui devient un passage

**Démonstration.** Repérer une fissure depuis le secteur actuel, examiner ses conditions, livrer les matériaux et dégager ou étayer l'accès. Après travaux, un habitant traverse son seuil et rejoint une petite zone d'essai attenante.

**Contrat du passage.** Deux extrémités identifiées, largeur, hauteur, type de traversée, restrictions de charge, capacité et coût de trajet. L'état découvert, bloqué ou ouvert est visible. Le premier passage est horizontal ; les conduits, échelles et ponts réutiliseront ce contrat sans être tous produits ici.

**Assets.** Entrée et sortie assorties, bord de plancher brisé, éclats, étai, état fermé/en chantier/ouvert et point d'interaction. Continuité visuelle du bois, de l'échelle et de l'orientation.

**Validation.** Croisement de deux habitants, file d'attente, rappel sur le seuil, passage bloqué, charge interdite, annulation du chantier et sauvegarde. Un habitant ne peut jamais appartenir aux deux extrémités à la fois.

## 6 — Un premier secteur réellement relié

**Démonstration.** Refuge → fissure → court secteur sombre → ressource distincte → retour au refuge avec charge. La ressource sera choisie pour une recette immédiatement utile, par exemple une résine destinée à l'éclairage ; éviter une ressource sans usage. Le passage se fait par le monde, avec centrage caméra possible sur l'autre secteur.

**Exploration.** Distinguer zone inconnue, décor mémorisé et information actuellement visible. Une zone déjà reconnue reste connue après un départ ; la mémoire ne révèle pas les changements invisibles. La première livraison ne comprend qu'une destination artisanale. La génération procédurale attend la campagne et les budgets de persistance.

**Persistance indispensable.** Identifiants stables de secteur, passage, habitant, objet et tâche. Conserver destination, charge, combustible et progression lors du transfert. Les besoins continuent avec la même horloge hors caméra. Le premier essai peut garder les deux petits secteurs chargés : pas de simulation approximative hors écran à inventer prématurément.

**Sauvegarde.** Étendre le point de sauvegarde au-delà du refuge avant d'accepter cette étape : enregistrer de façon cohérente un voyage, sa réservation et son propriétaire. Tester une sauvegarde avant, pendant et après transfert. Une éventuelle attente de quelques instants pour stabiliser une transition doit être visible et bornée. Ne pas annoncer la sauvegarde libre tant que cette preuve n'existe pas.

**Retour.** Rappel global à travers les secteurs, retour autonome pour faim/soif/sommeil, alerte carburant et gestion d'un passage indisponible. Une caisse à deux mains nécessite une route éclairée ou un accompagnateur ; cette condition doit être satisfaite dans la démo complète.

**Validation.** Aller-retour à vide puis chargé, retour déclenché par besoin, rappel depuis le second secteur, épuisement proche du retour, sauvegarde en trajet, rechargement et revisite. Comparer population, stocks et objets avant/après : aucun habitant perdu, aucune ressource doublée, aucune découverte oubliée.

## 7 — Transformer l'expédition en route utile

**Démonstration.** Construire un dépôt et des points d'éclairage sur le trajet, les ravitailler, puis transporter régulièrement la nouvelle ressource. Le joueur comprend le gain de l'aménagement par rapport à une sortie accompagnée.

**Règles.** Éclairage fixe construit et entretenu, autonomie visible, stocks distants persistants, réservations sur toute la route. Un manque de combustible ou une rupture d'accès suspend les transports avec une cause et une action possibles. Premiers ordres de ravitaillement simples ; pas encore plusieurs colonies autonomes.

**Assets et validation.** Supports de torches récupérés, combustible stocké et signal d'arrêt. Tester dépôt distant plein, panne de lumière, besoins du porteur, retour prioritaire et chargement avec stocks dans les deux secteurs.

## 8–11 — Du refuge au premier chapitre jouable

**8 — Habitat.** Première chambre dessinée sur grille : murs, porte, lit et accès. Construire avec matériaux livrés ; calculer fermeture et intimité ; conserver un couchage de secours. Montrer une chambre partagée et une chambre individuelle. Tester pièce mal fermée, porte bouchée, propriétaire absent et reprise de sauvegarde. Ne pas inclure plusieurs étages constructibles dans ce premier essai.

**9 — Métiers.** Priorités de construction, transport et collecte ; préférences et aptitudes individuelles lisibles ; urgences vitales prioritaires. Montrer un artisan approvisionné par un porteur, puis une absence qui redistribue le travail. Tester absence de travail, concurrence, interruption et impossibilité expliquée. Amis, tensions et humeur feront l'objet de livraisons distinctes après ce socle.

**10 — Soins.** Blessure annoncée, incapacité, secours, lit et soin consommant une ressource. Montrer le sauvetage et la récupération. Tester accès impossible, soignant interrompu et sauvegarde d'un blessé. Introduire ensuite la mort définitive selon le choix validé, avec avertissements et occasion réelle de secours ; ne pas ajouter silencieusement une mort immédiate à une jauge vide.

**11 — Cuisine.** Aménagement initial suffisamment long pour s'approprier le refuge, pont réellement construit, dépôt et fourmis dotées d'une perception locale. Montrer au moins deux façons de ramener les provisions : détour et fenêtre favorable ou diversion. Inclure un tutoriel léger, signaux de danger, rappel et reprise de partie. La durée de 20–30 minutes du dossier initial est une hypothèse à réévaluer, pas une contrainte imposée à l'aménagement.

Pour chacune de ces étapes, produire uniquement les assets requis par la scène démontrée : modules de chambre ; accessoires de métiers ; matériel de soin et animations de secours ; kit cuisine, biscuit, fourmi riggée, appât et animations. Le détail du lot sera fixé avant sa production.

## Après la première aventure

| Ordre proposé | Livraisons successives à détailler au moment de les engager |
| --- | --- |
| Vie de colonie | Cuisine et recettes, recrutement par voyageurs/sauvetages, traits et relations, confort et humeur |
| Milieu et faune | Température puis humidité puis fumée ; observation humaine locale ; araignée et rongeur ; défense ; insecte utile apprivoisable |
| Maison et progression | Cloisons puis fondations, recherches liées aux découvertes, transports verticaux et constructions sur plusieurs niveaux |
| Campagne | Grand Refuge, rénovation annoncée, migration, ville souterraine indépendante avec échanges, recrutement et missions |
| Prolongement | Extérieur, nouvelles zones procédurales persistantes, avant-postes et ravitaillement ; le refuge principal reste le centre de gestion |
| Finition continue | Audio, tutoriel, réglages, mesures CPU/GPU et sauvegardes longues ; vérifier progressivement 10, 20 puis 30–50 habitants |

Ces lignes sont des objectifs conservés, pas des lots géants à implémenter sans revue. La domestication utile et la ville appartiennent à la direction retenue. La reproduction, le dressage approfondi, la simulation complète des gaz et la gestion de plusieurs colonies ne sont pas implicitement inclus.

## Ce qui sera montré à chaque livraison

- La situation initiale, une action du joueur et sa conséquence visible.
- Un cas défavorable pertinent : ressource absente, trajet bloqué, interruption ou rappel.
- La reprise après sauvegarde, dès qu'un état persistant est ajouté.
- Les assets nouveaux et les limites réelles de la version.
- Les vérifications effectuées, puis l'attente de validation avant publication.

**Prochain résultat jouable après validation de ce document : le lit approvisionné physiquement, étape 2.**
