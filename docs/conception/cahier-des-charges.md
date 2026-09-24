# Sous le plancher
Cahier des charges de conception et roadmap - version 0.2 — plan validé, livraisons progressives
24 septembre 2026 | Référence du prototype : commit 3d1c9a3 | Godot 4.7.2

## 01. Lire et commenter ce dossier
**Objet.** Définir le jeu avant de poursuivre sa production. Ce document décrit une direction complète, des règles candidates, les assets à produire et des jalons vérifiables. Il ne constitue ni un devis ni une promesse de date de sortie. Aucun développement de gameplay n'est engagé par sa rédaction.

**Statuts à distinguer.** VALIDÉ EN ENTRETIEN désigne une direction approuvée, sans signifier que son implémentation existe.  EXISTANT désigne un comportement présent dans le dépôt. PROPOSÉ désigne la recommandation de conception à valider. OPTION désigne une extension exclue des premiers jalons. Toutes les valeurs du futur équilibrage, durées de partie et limites techniques sont des hypothèses de départ, pas des mesures de satisfaction des joueurs.

**Lecture conseillée.** Commencer par la vision, la carte et la première aventure. Examiner ensuite les habitants, les travaux et les dangers. Terminer par les assets, la roadmap et les décisions ouvertes. Les identifiants SYS, ART, QA et DEC servent à formuler les retours sans ambiguïté.

**Livrables associés.** Le PDF v0.1 reste une archive historique non actualisée. Ce Markdown et la [roadmap de production](roadmap-production.md) constituent la révision courante ; les schémas historiques restent conceptuels et ne décrivent pas toutes les extensions retenues. Le fichier `inventaire-assets.csv` recense les lots de production. Le fichier `retours-et-decisions.md` conserve les décisions de l’entretien et les validations de lots. Les diagrammes sont des schémas de conception, pas des captures de fonctionnalités existantes. L'image de couverture provient du prototype actuel.

**Périmètre proposé.** Jeu solo PC Windows, clavier/souris, interface française, caméra 3D de gestion. Simulation avec pause et accélération. Carte de maison fabriquée à la main, événements partiellement variables. Objectif : une colonie attachante et un monde crédible à l'échelle miniature.

**Décisions et prochaine validation.** Les douze orientations DEC sont renseignées au chapitre 32. La présente révision et le découpage en étapes sont validés par le joueur. Les détails non discutés et les statistiques candidates ne sont pas automatiquement approuvés. Chaque étape est montrée au joueur, puis commitée et poussée seulement après sa validation.

## 02. Vision, promesse et limites
**Promesse.** Faire d'un espace oublié une civilisation discrète. Le joueur se souvient d'avoir franchi une fissure, sauvé un porteur et détourné une piste de fourmis, pas seulement d'avoir rempli une jauge.

- **PIL-01 - L'échelle transforme le quotidien.** Un bouton est une plateforme, une allumette une poutre, une canalisation une frontière. Chaque zone doit donner au moins une décision liée à cette échelle.
- **PIL-02 - Préparer vaut mieux que subir.** Observer les habitudes humaines permet de choisir quand récolter, construire ou se déplacer. Les dangers sont annoncés et peuvent être contournés.
- **PIL-03 - Les habitants comptent.** Des individus nommés, spécialisés et autonomes remplacent des unités anonymes. Le joueur fixe des priorités ; il ne distribue pas chaque repas.
- **PIL-04 - La logistique dessine la colonie.** Dépôts, chemins, ponts et refuges changent les itinéraires et les possibilités d'expansion.
- **PIL-05 - Un écosystème plutôt que des vagues.** Insectes, rongeurs et humains réagissent à des besoins et à des traces perceptibles.

**Boucle émotionnelle.** Curiosité devant un passage inconnu, tension pendant une sortie, soulagement au refuge, satisfaction lorsqu'un travail rend une zone accessible. Le refuge doit être chaleureux malgré un environnement sale et hostile.

**DIRECTION VALIDÉE : réalisme miniature stylisé.** Matériaux et éclairage crédibles, silhouettes lisibles, proportions légèrement expressives. L'ambition de finition professionnelle se juge sur les images en mouvement et la cohérence de tous les assets. « AAA » n'est pas un critère mesurable : on le traduit en contrôles de qualité visuels, budgets et scènes de référence.

**Hors premier périmètre.** Multijoueur, génération procédurale dès le premier chapitre, terrain entièrement destructible, simulation complète des humains, reproduction génétique, combat tactique à grande échelle, véhicules complexes et plusieurs maisons. Aucune boutique intégrée. Les modes libre et difficulté réduite sont prévus après la boucle principale.

## 03. État réel du prototype et écarts
Base publiée : `3d1c9a3`, après les lots 12–13. Les fiches de lots décrivent les contrôles et limites de chaque livraison ; ce tableau distingue leur intégration de la cible complète.

| Domaine | EXISTANT | À construire |
| --- | --- | --- |
| Habitants | 4 habitants, faim, soif et sommeil autonomes, repas et boissons au refuge | Soins, traits, relations, recrutement et métiers |
| Stocks | Nourriture, bois, fibres, eau ; réservations et livraisons au dépôt global | Dépôts locaux, capacités, filtres et routes de ravitaillement |
| Travaux | Fabrication de lits et alcôves, propriétaires et annulation | Acheminement des matériaux ; murs, portes et pièces libres |
| Navigation | Chemins au sol, palier, échelle, passerelle, porte et files réservées | Graphe de secteurs, passages aménageables et validation de foule |
| Exploration | Reconnaissance de la réserve orientale dans la scène actuelle | Secteur sombre relié, information mémorisée, missions et cuisine |
| Menaces | Cycle humain de 100 s, soupçons globaux | Routines observables, perception locale, faune et secours |
| Visuel | Assets Blender, rig, animations, textures, poussière, toiles et torches fixes | Torches portées, faune animée, kits des nouvelles zones |
| Produit | Interface Atelier miniature, sauvegarde au refuge, migrations de format | Sauvegarde en expédition, audio, tutoriel et campagne |

**Règles existantes.** Lit : 4 bois et 3 fibres ; alcôve : 6 bois et 5 fibres. Les matériaux sont encore prélevés dans le stock global avant fabrication. L’atelier coûte 10 bois et 6 fibres et améliore les transports. Aucun habitant n’apparaît à la fabrication d’un lit. Les anciennes constructions d’abris subsistent pour compatibilité mais ne définissent plus la progression. La victoire automatique et la famine globale du premier prototype ont été retirées.

**Besoins existants.** Les habitants recherchent sommeil, nourriture et eau ; un besoin critique ralentit les déplacements. Ils dorment dans un lit disponible ou au sol. Le confort et l’intimité sont encore des qualités du couchage. Une jauge vide ne déclenche pas actuellement blessure ou mort. Voir [lot 12](gameplay-lot-12.md) et [lot 13](gameplay-lot-13.md) pour les statistiques réellement implémentées.

**Sauvegarde existante.** Format v3 avec migration v1/v2, point stable après rappel au refuge. Conserve notamment besoins, lits, propriétaires, travaux et découvertes. Ce n’est pas encore une sauvegarde libre pendant une expédition ; cette extension est requise à l’étape 6 de la roadmap.

**Preuves et limites.** Les tests ciblés couvrent navigation, livraisons, interface, échelles, portes, reconnaissance, sauvegarde, sommeil et besoins. Ils ne prouvent ni une colonie de 50 habitants, ni plusieurs secteurs persistants, ni la stabilité d’une campagne longue. Les mesures graphiques du premier décor ne constituent pas un budget validé pour la future campagne.

## 04. Boucles de jeu et progression
[[diagram:loop]]

**Court terme, 30 secondes à 3 minutes.** Affecter un habitant, préparer un trajet, répondre à une alerte, déplacer un stock. Chaque ordre doit produire un retour immédiat : qui agit, où, pourquoi et dans combien de temps approximativement.

**Moyen terme, 10 à 30 minutes.** Explorer un passage, acheminer les matériaux, construire un accès, établir un dépôt et sécuriser une ressource. Une expédition réussie doit modifier une possibilité de la carte, pas seulement donner un bonus numérique.

**Long terme, plusieurs sessions.** Relier les secteurs de la maison, apprendre leurs cycles, diversifier eau et nourriture, puis construire le Grand Refuge. La connaissance de la maison est une forme de progression persistante.

**SYS-01 - Cycle d'expansion.** Un passage découvert reçoit un niveau de connaissance : observé, reconnu, praticable, équipé. Le joueur voit le risque connu et l'information manquante. Reconnaître consomme du temps ; équiper consomme matériaux et travail ; exploiter expose des habitants.

**Choix récurrent.** Une route courte traversant une zone à fourmis peut être intéressante pour une sortie urgente. Une route longue couverte devient rentable lorsque les transports se répètent. Aucun choix ne doit dominer dans toutes les situations.

**Déblocages par accomplissement.** Construire un pont enseigne l'assemblage ; récupérer du métal permet l'outillage ; observer une fuite révèle la collecte d'eau. Les recherches exigent un lieu de travail et une ressource précise, plutôt qu'un arbre de bonus abstraits.

**Critère de plaisir à tester.** Après la première aventure, un joueur doit pouvoir raconter au moins une décision qui lui appartient : quand sortir, quelle équipe envoyer, quel trajet aménager ou quel risque accepter. Si tout le monde suit une séquence imposée, la conception doit être révisée.

## 05. Carte de la maison et échelles
[[diagram:house]]

**SYS-02 - Carte artisanale, situations variables.** La géométrie et les accès majeurs sont conçus pour la lisibilité et les choix. L'emplacement de petites réserves, certaines habitudes et les territoires animaux peuvent varier à partir d'une graine sauvegardée. Les passages critiques ne sont jamais tirés au hasard sans solution de secours.

**Convention spatiale.** Une unité Godot représente provisoirement 1 cm dans la fiction ; un habitant mesure environ 1,6 unité. Cette convention est à confirmer avant de refaire les personnages. Un secteur jouable mesure environ 20 à 40 unités de côté. La maison entière est un graphe de secteurs, pas une reconstruction grandeur nature continue.

| Secteur | Identité et ressource | Contrainte dominante |
| --- | --- | --- |
| Salon, sous-plancher | Départ, fibres, bois, refuge | Vibrations et accès limités |
| Cuisine | Nourriture, graisse, miettes régulières | Fourmis, nettoyage, horaires |
| Cloisons | Raccourcis, isolant, points d'observation | Goulets, dénivelés, câbles à éviter |
| Salle de bains | Eau, humidité, champignons | Fuites, zones glissantes, moisissure |
| Cave et fondations | Métal, grand volume protégé | Rats, froid, longues distances |
| Grenier | Papier, coton, stocks oubliés | Chaleur, sécheresse, araignées |

**Vue en coupe.** Sélectionner un niveau masque le plafond gênant et conserve des silhouettes des niveaux voisins. Les entrées de conduits portent un nom et une destination. La carte stratégique indique les connexions et les horaires connus ; elle ne révèle pas les ressources non explorées.

**Périmètre campagne retenu.** Salon, cuisine, cloisons et fondations, puis une ville souterraine indépendante proposant échanges, recrutement et missions, tout en conservant le refuge du joueur. Salle de bains et grenier restent des extensions de campagne si le coût de production dépasse les moyens disponibles. L'eau peut d'abord venir d'un tuyau fuyant dans une cloison.

**Extension retenue à développer plus tard.** Extérieur et nouvelles zones procédurales persistantes, avec avant-postes, stocks, ateliers et ravitaillement. Les zones découvertes restent accessibles ; cette extension ne transforme pas la maison artisanale en carte entièrement aléatoire. Le joueur ne gère pas plusieurs colonies complètes. Voir les étapes 5–7 de la [roadmap](roadmap-production.md) pour le premier contrat de liaison et de persistance.

## 06. Première aventure : atteindre la cuisine
[[diagram:slice]]

**Tranche jouable J3.** Prévoir davantage de construction et d’aménagement du refuge avant le départ, conformément à DEC-08. La durée initiale de 20–30 minutes est à réévaluer après essai. Quatre habitants, un refuge, deux métiers actifs (éclaireur et ouvrier polyvalent), une zone de départ, un accès masqué vers la cuisine, un pont, un dépôt et une petite colonie de fourmis.

1. Le joueur assure une réserve de départ et désigne un éclaireur. Une entrée de conduit est repérée par un indice sonore et une trace de miettes.
2. L'éclaireur révèle la fissure et deux options : contour étroit praticable à vide, ou pont permettant les porteurs chargés.
3. Un chantier de pont demande des matériaux livrés et du temps de travail. Le joueur peut préparer un dépôt pendant sa construction.
4. La cuisine révèle un biscuit et une piste de fourmis. Le joueur choisit un appât, une fenêtre horaire favorable ou une route plus longue.
5. Une équipe ramène les premières provisions. Le dépôt réduit ensuite la distance moyenne des transports.

**Conditions de réussite.** Au moins un habitant atteint la cuisine et revient ; le pont est praticable ; 6 portions de nourriture sont livrées au refuge ; les quatre habitants restent en état de poursuivre. La mission continue si l'un est blessé : un sauvetage constitue une solution, pas un échec immédiat.

**Contraintes.** Pas de faim mortelle pendant les premières minutes guidées. La piste de fourmis est annoncée avant le premier danger. Le joueur peut suspendre un chantier, rappeler l'équipe et inspecter la raison d'un blocage.

**Mesures J3.** Tester avec 3 à 5 personnes si possible : majorité capable de livrer une première portion sans aide orale, aucun blocage irréversible, au moins deux stratégies observées. Échec technique si un habitant reste immobile plus de 10 secondes sans état expliqué ou si des ressources sont dupliquées à l'annulation.

## 07. Temps, difficulté et conditions de partie
**SYS-03 - Horloge cible.** La durée du jour reste provisoire selon DEC-12 ; 12 minutes réelles à x1 est seulement une hypothèse initiale. Le cycle humain actuel de 100 s ne représente pas encore cette journée cible. Pause, x1 et x2 dès J1 ; x4 seulement après validation des déplacements et des événements. Les besoins et la production utilisent le temps simulé, jamais les images rendues.

**Cadences candidates.** Déplacement à chaque pas physique ; besoins et économie à 1 Hz simulé ; choix d'une nouvelle tâche sur événement ou au plus toutes les 0,5 s ; perception animale étalée entre agents. L'horloge est suspendue par pause. Les effets décoratifs peuvent continuer, sans changer la simulation.

**SYS-04 - Difficulté.** Gestion avec difficultés réelles, anticipation et récupération. La mort définitive est possible dans la cible retenue, après danger annoncé et occasion de secours. Les modes Détente et Survie et leurs multiplicateurs restent à définir ; aucune valeur de difficulté n’est validée par la seule référence à RimWorld.

**Règles d'équité.** Prévenir un événement majeur au moins 30 secondes simulées à l'avance lorsqu'il est observable. Le premier événement de chaque type est atténué. Aucun danger nouveau ne surgit directement dans le refuge initial sans indice préalable.

**Défaite proposée.** Plus aucun habitant capable d'agir et aucun secours possible, ou destruction finale annoncée d'une colonie non évacuée. Une zone perdue, un bâtiment endommagé ou une rupture de nourriture doivent produire une situation récupérable avant la défaite.

**Sauvegarde et reprise.** Sauvegarde manuelle, autosauvegarde au début du jour, avant un événement majeur et à la sortie normale. Trois autosauvegardes tournantes. Une session doit pouvoir être interrompue sans abandonner une expédition. En Standard, le chargement permet de revenir sur une catastrophe.

**Durée de campagne.** Hypothèse de conception : 4 à 8 heures pour les quatre secteurs principaux. Ce n'est pas un engagement ; mesurer le temps de la première aventure avant de dimensionner les chapitres suivants.

## 08. Habitants : identité, besoins et états
**SYS-05 - Échelle humaine de la colonie.** Départ à 4 habitants ; cible de première aventure à 4-6, deuxième étape à 8-12, campagne à 30-50. Chaque habitant possède un identifiant stable, un nom, une apparence, un métier principal, une tâche actuelle et deux traits maximum. Les enfants et la reproduction sont exclus du premier périmètre.

| Statistique | Échelle et évolution proposée | Conséquence lisible |
| --- | --- | --- |
| Santé | 0-100 ; soins requis après blessure | À 0 : incapacité, puis règle du mode de difficulté |
| Satiété | 0-100 ; -100 par jour sans repas | Sous 25 : chercher à manger ; à 0 : affaiblissement |
| Hydratation | 0-100 ; -100 par jour sans eau | Sous 25 : boire ; eau introduite à J4 |
| Énergie | 0-100 ; -6/h active, -2/h au repos | Sous 25 : repos ; +20/h dans un lit |
| Stress | 0-100 ; danger, isolement, pénurie | À 80 : fuite ; -12/h en refuge sûr |
| Compétences | 0-5 par métier ; progression lente | Production, portage ou perception améliorés |

**Alimentation.** Une ration nourrit un habitant pendant un jour, distribuée en trois repas d'un tiers de ration. Une unité d'eau potable par jour également. Les stocks sont enregistrés en petites unités entières (par exemple 300 sous-unités par ration) pour éviter les erreurs d'arrondi. Les repas rendent la satiété correspondante ; ils ne soignent pas instantanément.

**Gestion des urgences.** Une jauge à zéro déclenche d'abord un état expliqué. La famine provoque une perte de santé seulement après 4 heures de fiction sans nourriture. La déshydratation, introduite plus tard, dispose d'un délai propre de 2 heures. Ces délais restent des variables d'équilibrage.

**Arrivées.** Un abri fournit des lits ; il ne crée plus automatiquement un habitant. Des survivants arrivent après une découverte ou un appel, si lits, eau et nourriture couvrent deux jours. Le joueur accepte ou reporte l'accueil. La notification décrit l'impact sur les réserves.

## 09. Métiers spécialisés et progression
**SYS-06 - Spécialisation souple.** Un métier principal donne priorité à un ensemble de tâches. Les tâches secondaires restent autorisées par cases à cocher. Un éclaireur peut porter une ration en urgence, mais son emploi du temps ne doit pas être absorbé par des transports inutiles.

| Métier | Tâches spécialisées | Outil / condition | Arrivée |
| --- | --- | --- | --- |
| Polyvalent | Récolter, porter, travaux simples | Aucun | J1 |
| Éclaireur | Reconnaître, observer, baliser | Sac léger ; lampe facultative | J3 |
| Bâtisseur | Ponts, étais, bâtiments, réparations | Outil d'assemblage | J2 |
| Logisticien | Réserves, livraisons, évacuation | Sac ou harnais | J4 |
| Artisan | Cordage, outils, pièces | Atelier | J4 |
| Soigneur | Stabiliser, transporter un blessé, soins | Bandages et lit | J4 |
| Veilleur | Observer les menaces, alerter | Poste d'observation | J5 |
| Jardinier | Champignons, entretien d'humidité | Bac de culture et eau | J6 |

**Compétence.** Valeur entière 0 à 5. Gain d'expérience seulement sur travail utile terminé, pas sur ordres annulés. Seuils cumulés candidats : 0, 100, 260, 520, 900 et 1 400 points. Une seconde de travail utile donne 1 point avant coefficients propres au métier. Le niveau n'apporte pas un avantage universel.

**Exemples de bonus.** Artisan et bâtisseur : débit de travail multiplié par 1 + 0,08 x niveau. Éclaireur : temps de reconnaissance réduit de 5 % par niveau. Logisticien : manipulation plus rapide, puis un emplacement de portage supplémentaire au niveau 3. Soigneur : consommation identique, durée de soin réduite.

**Traits candidats.** Costaud (+1 emplacement, besoin alimentaire +10 %), prudent (seuil de danger accepté réduit, reconnaissance +15 % de durée), agile (+10 % de vitesse à vide), calme (stress reçu -15 %). Aucun trait ne rend un habitant incapable d'une tâche essentielle.

**Interface.** Fiche avec portrait, état, besoin urgent, métier, tâche et raison. Vue collective par lignes : métier, tâches secondaires, priorité et lieu autorisé. Un filtre montre les habitants inactifs, blessés ou sans accès à leur travail.

## 10. Ordonnancement des tâches et autonomie
[[diagram:tasks]]

**SYS-07 - Une tâche n'est pas un simple déplacement.** Elle contient un identifiant, un type, une cible, une quantité, des préconditions, un métier recommandé, une priorité, un risque maximal et les réservations prises. Les états sont : proposée, réservée, en trajet, en cours, interrompue, terminée ou impossible.

**Ordre de décision.** Danger immédiat et soins urgents avant les besoins vitaux ; besoins avant l'ordre prioritaire du joueur ; puis travaux courants et activités de confort. Un ordre explicite ne peut pas imposer de rester dans une zone mortelle sans avertissement et confirmation de prise de risque dans le jeu.

**Choix candidat.** Score = priorité du joueur x 100 + adéquation métier x 20 + urgence x 30 - secondes estimées de trajet - risque x 2. Chaque terme est normalisé et affichable en mode diagnostic. Ce score initial est une heuristique à tester. Une tâche commencée bénéficie d'une inertie : ne pas changer d'avis à chaque mise à jour pour un faible gain.

**Réservations.** Avant départ, réserver atomiquement la quantité au stock source, une place au stock destination et le poste de travail si nécessaire. Deux habitants ne doivent jamais réclamer la même unité. Une réservation est libérée à l'annulation, au décès, à la disparition d'une cible ou après expiration si l'agent ne progresse plus.

**Interruptions.** Rappel global : arrêter le travail, conserver ou déposer proprement la charge, rejoindre un refuge accessible et mémoriser l'intention. Après retour au calme, revalider la tâche ; ne pas reprendre aveuglément une ressource épuisée ou un trajet devenu dangereux. Le sauvetage d'un blessé crée une tâche dédiée pour deux porteurs si nécessaire.

**Anti-blocage.** Trois échecs de chemin déclenchent une suspension et une notification concise. Le système conserve une raison : passage fermé, outil manquant, ressource réservée, destination pleine ou risque trop élevé. Réévaluer sur événement pertinent, pas en boucle permanente. Une tâche suspendue peut être déplacée ou annulée depuis son panneau.

**Acceptation.** Interrompre une livraison, détruire sa destination puis sauvegarder/recharger : ni perte silencieuse, ni duplication, ni habitant sans état. Les charges transportées restent des objets comptables localisés.

## 11. Logistique et stocks locaux
**SYS-08 - Le stock global est une vue, pas une téléportation.** Chaque ressource existe dans un gisement, un conteneur, un atelier ou un sac. Le bandeau peut indiquer le total connu, mais distingue disponible, réservé et en transport. Un chantier ne consomme que les matériaux arrivés sur place.

**Portage candidat.** Sac standard : 3 emplacements. Une unité de bois, de fibres ou de métal occupe un emplacement ; 1 ration ou 1 unité d'eau également. Les petites fractions de rations sont conditionnées en lots. Les objets volumineux exigent deux habitants ou un chariot, ce dernier restant OPTION.

**Transport.** Une tâche collecte un lot homogène, le dépose et confirme la transaction. La vitesse chargée vaut 80 % de la vitesse à vide. Le temps de prise/dépôt de base est de 1 seconde simulée par lot, réduit par la compétence de logistique. La distance reste le coût principal.

**Dépôts.** Capacité initiale candidate de 30 emplacements pour le refuge et de 12 pour un dépôt intermédiaire. Filtres par type ; minimum souhaité ; maximum ; priorité de livraison. Un stock plein refuse une réservation supplémentaire. En urgence, un dépôt temporaire au sol peut être autorisé, avec risque accru de pillage et d'humidité.

**Politique de ravitaillement.** Les refuges maintiennent deux jours de nourriture et d'eau avant d'alimenter les grands chantiers facultatifs. L'utilisateur peut modifier cette réserve de sécurité. La nourriture périssable est prélevée par date de péremption la plus proche ; les recettes ne doivent pas consommer une portion protégée sans signalement.

**Mesure utile.** Afficher autonomie en jours = réserve comestible accessible / consommation journalière de la population concernée. Une réserve coupée par un passage fermé n'augmente pas l'autonomie du refuge isolé. Les stocks non explorés ne sont pas inclus.

**Acceptation.** Une livraison entre deux dépôts conserve exactement les quantités, même en cas de rappel, blocage, chargement de sauvegarde ou destruction d'un pont. Une file de porteurs ne doit pas livrer davantage que le seuil maximal demandé.

## 12. Navigation, collisions et passages
[[diagram:navigation]]

**SYS-09 - Deux niveaux de chemin.** Un graphe stratégique relie les secteurs et leurs entrées. Dans un secteur chargé, un maillage de navigation décrit les surfaces praticables. Ponts, échelles et conduits sont des liens explicites avec largeur, capacité, sens, coût et conditions d'accès.

**Déplacement local.** Agent cinématique avec capsule de collision, chemin suivi progressivement et évitement local. Vitesse candidate 1,2 unité/seconde à vide, 0,96 chargé ; elle sera ajustée après fixation de l'échelle. Rotation et animation suivent la vitesse réelle. Pas de traversée des bâtiments ou de téléportation pour masquer un blocage.

**Passages étroits.** Un conduit ou pont de largeur inférieure à deux habitants fonctionne comme une ressource réservable. File FIFO avec priorité aux urgences, points d'attente de chaque côté et sens temporaire. Les agents n'essaient pas tous de se contourner dans le même goulet. Un passage dangereux peut être fermé aux porteurs mais ouvert aux éclaireurs.

**Chantiers.** Un fantôme de bâtiment vérifie collision, pente, espace de travail et connectivité avec au moins un refuge. La validation ne doit jamais enfermer un habitant ou fermer l'unique issue sans avertissement. À la fin de construction, activer obstacle et navigation dans la même transaction de simulation.

**Événement dynamique.** Si une fuite bloque une zone, invalider seulement les chemins concernés, annuler les réservations de passage et proposer un refuge alternatif. Si aucun refuge n'est accessible, regrouper les habitants sur un point sûr connu et afficher une demande de secours.

**Acceptation QA-NAV.** 20 habitants traversent un pont à sens alterné sans blocage permanent ; 50 naviguent dans un secteur de test ; un obstacle ajouté provoque un nouveau chemin ; une échelle respecte sa capacité ; un agent coincé est signalé en moins de 10 secondes simulées. Tester aussi après rechargement d'une sauvegarde.

## 13. Exploration et information imparfaite
**SYS-10 - Brouillard de connaissance.** Trois états : inconnu, cartographié, actuellement observé. Les éléments statiques cartographiés restent sur la carte. Les animaux hors de vue sont affichés comme dernière observation datée, jamais comme une position actuelle exacte. Un trajet déjà sûr peut être réévalué après changement de la maison.

**Ordre de reconnaissance.** Choisir un passage, une équipe de un à trois habitants, un seuil de risque, une réserve emportée et un objectif. Le jeu indique l'information certaine et ce qui est estimé. L'équipe rentre à l'objectif atteint, à la réserve minimale, en cas de blessure grave ou sur ordre de rappel.

**Observation.** Un éclaireur immobile à couvert apprend une routine humaine ou animale. La progression dépend du temps réellement observé. Deux observations concordantes suffisent pour afficher une fenêtre horaire avec une marge d'incertitude. Une routine perturbée est marquée comme à reconfirmer.

**Découvertes.** Gisements, raccourcis, objets rares, survivants, risques, traces et sites de refuge. Certaines découvertes ouvrent une recette ou un objectif. Les indices visuels - miettes, griffures, fils, humidité - doivent exister dans la scène, pas seulement dans un texte.

**Équipement.** Sac léger, corde, bandage et lampe. La lampe améliore l'observation mais augmente la visibilité de l'équipe dans certains espaces. L'éclairage n'est donc pas toujours bénéfique. La collecte d'informations ne doit pas devenir une suite d'attentes sans choix : chaque reconnaissance révèle au moins un accès, une décision ou une opportunité.

**Échec récupérable.** Une équipe peut revenir sans ressources mais avec une carte partielle. Un habitant immobilisé peut être secouru. Une menace bloquant le passage principal impose un contournement ou une diversion, pas le redémarrage automatique de la partie.

**Acceptation.** Le brouillard ne révèle ni ressources ni animaux non observés ; une carte mémorisée ne se perd pas au changement de secteur ; les observations et le matériel d'expédition survivent à une sauvegarde.

## 14. Ressources, recettes et équilibrage
**SYS-11 - Unités candidates, distinctes du prototype.** Une ressource possède quantité, volume, localisation, état et qualité éventuelle. Commencer avec peu de types ; ajouter une ressource uniquement si elle produit une nouvelle décision.

| Ressource | Unité et usage | Source | Introduction |
| --- | --- | --- | --- |
| Nourriture | Portion brute ; 2 brutes donnent 1 ration | Miettes, biscuit | J1 |
| Bois | Pièce ; structures et outils | Allumettes, échardes | J1 |
| Fibres | Faisceau ; attaches et literie | Fil, coton, isolant | J1 |
| Eau potable | Unité journalière par habitant | Collecteur, puis filtre | J4 |
| Métal | Fragment ; outils et renforts | Agrafes, trombones | J4 |
| Résine | Dose ; étanchéité et réparation | Colles sèches, objets | J5 |
| Soie | Faisceau ; cordage avancé | Toiles abandonnées | J5 |
| Déchets organiques | Unité ; compost ou appât | Cuisine, consommation | J5 |

**Recettes de départ.** 2 portions brutes + 8 secondes-travail à la table de préparation = 1 ration. Une transformation manuelle reste possible à moitié débit pour ne pas bloquer une colonie dont l'atelier est détruit. 2 fibres + 15 secondes-travail = 1 cordage. 1 bois + 1 métal + 25 secondes-travail = 1 outil simple. 1 fibre + 10 secondes-travail = 1 bandage. Les coûts restent dans des données, pas dans les scripts.

**Production.** Temps de travail effectif = durée de base / multiplicateur de compétence. Le temps total inclut trajets, attente, collecte, livraison et besoins. Les aperçus de production doivent distinguer débit théorique de l'atelier et débit réellement observé.

**Exemple de bilan.** 6 habitants consomment 6 rations/jour, soit 12 portions brutes. Une sortie ramenant 18 portions couvre 1,5 jour avant pertes. Avec 3 porteurs de capacité 3, deux allers-retours sont requis pour déplacer ces 18 portions. La conversion finale demande 72 secondes-travail pour 9 rations.

**Objectif d'équilibrage.** Une petite colonie stabilisée consacre environ 35-50 % de son travail à la subsistance, 20-30 % aux transports, et conserve une marge pour exploration et travaux. Mesurer ces parts ; ne pas imposer ces proportions comme vérité avant playtests.

## 15. Construction, travaux et entretien
**SYS-12 - Cycle de chantier.** Choisir une emprise, valider accès et danger, réserver les matériaux, les livrer, assembler, inspecter puis activer. La construction peut être suspendue. L'annulation restitue 100 % des matériaux non utilisés et 70 % des matériaux assemblés ; ce taux est visible avant confirmation.

| Ouvrage candidat | Coût initial | Travail | Effet |
| --- | --- | --- | --- |
| Abri | 8 bois, 4 fibres | 60 s-travail | 2 lits ; récupération améliorée |
| Atelier | 10 bois, 6 fibres | 90 s-travail | 1 poste d'artisanat |
| Dépôt | 4 bois, 2 fibres | 35 s-travail | 12 emplacements filtrables |
| Pont court | 6 bois, 2 cordages | 80 s-travail | Passage de 3 unités maximum |
| Échelle | 3 bois, 1 cordage | 45 s-travail | Lien vertical de 2 unités |
| Étai | 4 bois, 1 métal | 40 s-travail | Stabilise un passage fragile |
| Collecteur | 4 bois, 2 fibres, 1 métal | 60 s-travail | 4 unités d'eau/jour si source active |
| Infirmerie | 6 bois, 6 fibres | 75 s-travail | 1 lit de soins |

**Capacité.** Deux bâtisseurs maximum sur les petits chantiers. Le second apporte 70 % de son débit pour représenter l'encombrement. Un chantier suspendu ne bloque pas toutes les réserves ; le joueur peut libérer ses matériaux. Les coûts ci-dessus remplacent les constructions instantanées de l'existant.

**Usure.** Introduire d'abord des dégâts causés par événements : fuite, rongeur, choc. Éviter une dégradation passive permanente de tous les bâtiments. En dessous de 40 % d'intégrité, le bâtiment perd sa fonction et crée une tâche de réparation. Les débris restent localisés et peuvent être récupérés.

**Réseaux.** Un pont peut être renforcé ; une gouttière détourne l'eau ; une porte réduit odeur et visibilité mais ralentit le passage. La lumière de chantier et le bruit créent des compromis. Les ouvrages visuels possèdent les états fantôme, livré partiellement, en montage, terminé et endommagé.

**Acceptation.** Prévisualisation fiable, absence de consommation instantanée à distance, coût conservé à la sauvegarde, récupération cohérente après annulation et passage navigable dès l'ouverture réelle du pont.

## 16. Humains, discrétion et événements
**SYS-13 - Simulation indirecte.** Les humains sont représentés d'abord par horaires, bruits, vibrations, ombres et actions sur des volumes de la carte. Une IA de personnage humain complet n'est pas nécessaire pour produire une menace crédible à cette échelle.

**Routine candidate.** Petit déjeuner, départ, retour, repas du soir, nettoyage occasionnel, sommeil. Les horaires sont légèrement décalés chaque jour à partir de la graine de partie. Une action peut déposer de la nourriture, déplacer un obstacle ou rendre un accès dangereux pendant une durée connue seulement après observation.

**Suspicion locale 0-100.** Chaque secteur suit une alerte. Bruit, lumière visible et traces de vol y contribuent. Proposition de taux : bruit de chantier exposé +0,4/s à proximité d'un humain, habitant directement visible +3/s, trace découverte +12 ponctuels. Hors présence et sans indice nouveau, -0,15/s. Une seule trace ne doit pas être ajoutée à chaque tick.

**Seuils.** 25 : indice d'inquiétude ; 50 : inspection possible annoncée ; 80 : menace ciblée telle qu'un piège ou un nettoyage ; 100 : incident majeur local. Atteindre 100 ne détruit pas magiquement toute la maison. La colonie peut perdre un accès ou un stock et se replier.

**Contre-mesures.** Camoufler une entrée, effacer des traces, réduire le bruit, fermer une réserve odorante, observer une fenêtre favorable, détourner la circulation. Chaque alerte explique sa source dominante. Pas d'échec fondé sur une jauge invisible.

**Événements de travaux humains.** Un meuble déplacé ouvre une nouvelle fissure ; une fuite condamne un tunnel ; une réparation supprime une source d'eau. Chaque événement majeur possède au moins une prévention ou une réponse. Leur enchaînement ne doit pas cumuler deux catastrophes non annoncées dans la même minute de jeu Standard.

## 17. Insectes : comportements et interactions
**SYS-14 - Modèle commun.** Percevoir, choisir une intention, naviguer, agir, mémoriser brièvement. Les animaux n'ont pas connaissance de tout le stock du joueur. Ils réagissent à la vue, au contact, à l'odeur ou aux vibrations selon l'espèce. Les seuils sont des données réglables.

| Espèce | Besoin et territoire | Comportement utile au jeu | Réponse du joueur |
| --- | --- | --- | --- |
| Fourmi | Nourriture, piste reliant un nid | Recherche, recrutement, transport, défense proche du nid | Appât, nettoyage de piste, route couverte |
| Araignée | Poste de chasse, réseau de fils | Attend, détecte les vibrations, capture une proie | Contourner, observer, couper un fil à distance |
| Cloporte | Humidité, matière organique | Se cache au sec, recycle des déchets | Canaliser l'humidité ; espèce de bât à choisir |
| Cafard | Abri sombre, nourriture accessible | Sortie opportuniste, fuite à la lumière | Stock fermé, éclairage temporaire, déplacement du dépôt |

**Domestication retenue.** Quelques insectes utiles pour le transport ou la production, avec entretien et besoins. Les espèces et le jalon restent à préciser ; reproduction et dressage approfondi ne sont pas inclus automatiquement.

**Fourmis J3.** Un nid abstrait émet des ouvrières jusqu'à un plafond de test de 20 visibles. Les pistes sont des concentrations sur un petit graphe de points, avec dépôt et évaporation ; ne pas lancer une simulation chimique sur toute la carte. Un appât attire la recherche, mais reste consommable et peut renforcer temporairement la fréquentation locale.

**Araignées J5.** Deux types de fils : décoratifs et fonctionnels. Une toile active est signalée par sa structure, ses vibrations et son propriétaire observé. Couper un fil désactive son déclencheur local ; toucher un décor ne piège jamais un habitant. La soie exploitable provient d'abord de toiles abandonnées.

**Équité et coût.** Animal hors écran : logique réduite, état conservé. Animal proche : perception et navigation complètes. Le plafond ne doit pas provoquer de disparition sous les yeux du joueur. Une attaque nécessite portée, temps de préparation et possibilité de fuite ; aucun dégât à travers un mur.

## 18. Rongeurs, blessures et sauvetage
**SYS-15 - Souris et rats.** La souris est opportuniste : inspecte les réserves, suit des trajets et évite les lieux trop exposés. Le rat représente un territoire plus dangereux, surtout dans la cave. Il n'est pas un ennemi de base à combattre de face.

**États de l'IA.** Repos, recherche alimentaire, déplacement connu, investigation, intimidation, attaque courte, fuite et retour au terrier. La satiété diminue l'intérêt pour une réserve. L'animal interrompt une poursuite après une distance ou une durée maximale ; il n'est pas omniscient et ne poursuit pas éternellement.

**Perception proposée.** Odeur propagée par les passages ouverts, vision interrompue par la géométrie, bruit perçu seulement dans un rayon défini. Le terrier et les couloirs habituels sont cartographiables. Les valeurs sont réglées dans une arène de test avant intégration à la campagne.

**Réponses.** Appât loin d'un accès, porte renforcée, cachette, transport groupé ou changement de trajet. Les pièges mortels et la domestication de rongeurs restent OPTION ; privilégier les situations de gestion et de fuite avant le combat.

**SYS-16 - Blessures.** Trois niveaux : légère (débit -15 %), sérieuse (mobilité -40 %, soins nécessaires), incapacité (transport obligatoire). Le soigneur stabilise, puis un ou deux porteurs conduisent l'habitant à un lit. Le trajet de secours possède une priorité élevée, mais ne traverse pas une zone condamnée sans validation.

**Mode Standard recommandé.** Un habitant à santé nulle devient incapable ; un délai de secours est clairement affiché. Décider avec le joueur si l'expiration provoque la mort ou une évacuation définitive. Le mode Détente évacue sans mort permanente. Le choix DEC-02 doit être fixé avant d'écrire les événements narratifs.

**Acceptation.** La souris réagit à une réserve accessible et ignore une réserve étanche non vue ; une porte coupe sa navigation ; un blessé garde son identité, son équipement et son état pendant le transport et après chargement.

## 19. Campagne, recherches et Grand Refuge
**SYS-17 - Progression en quatre chapitres proposés.** Chaque chapitre ouvre un système et une zone, avec un objectif principal et deux approches possibles. La durée de rénovation ne commence pas au lancement de la première partie.

| Chapitre | Objectif | Système appris | Condition de passage |
| --- | --- | --- | --- |
| Un coin à nous | Stabiliser le refuge et atteindre la cuisine | Récolte, pont, exploration | Retour d'expédition et réserve de sécurité |
| Entre les murs | Relier deux secteurs et capter l'eau | Logistique, outils, observation | Deux refuges connectés et eau suffisante |
| La maison change | Reconnaître les fondations | Menaces locales, soins, contournements | Site final connu et accès sécurisé |
| Le Grand Refuge | Construire et évacuer avant rénovation | Planification à l'échelle de la colonie | Conditions de victoire ci-dessous |

**Recherches concrètes.** Bibliothèque réduite de savoir-faire : assemblage, cordage, stockage étanche, collecte d'eau, renforts et cultures. Chaque savoir exige une découverte, un poste et un essai fabriqué. Les améliorations purement numériques sont secondaires.

**Victoire candidate.** Tous les habitants encore vivants sont au Grand Refuge ; capacité de lits suffisante ; 3 jours de nourriture et d'eau accessibles ; une source renouvelable de chaque ; deux issues praticables ; entrée camouflée ; aucun blessé abandonné. L'évacuation transporte aussi un choix d'outils et de stocks, mais aucun objet décoratif n'est imposé.

**Compte à rebours.** Après découverte explicite des travaux humains, proposer 8 à 12 jours de fiction pour préparer le départ, à équilibrer. Le joueur voit la date et les étapes de la rénovation. En Détente, cette échéance peut être désactivée. Un itinéraire alternatif reste disponible si une seule voie est détruite.

**Après la victoire.** Bilan des habitants sauvés, autonomie et connaissance de la maison ; continuer en mode libre avec la nouvelle base. Aucun score punitif unique ne doit invalider une stratégie prudente. Les chapitres et leurs objectifs sont sauvegardés indépendamment de l'interface.

## 20. Interface, feedback et accessibilité
**SYS-18 - Garder la scène visible.** Conserver la barre d'icônes basse et le bandeau supérieur compact. Un panneau contextuel principal à la fois ; fiches épinglées en option. Les notifications courantes disparaissent ; les alertes critiques restent accessibles dans un journal.

**Vues nécessaires.** Habitants et métiers ; réserves par secteur ; bâtiments et chantiers ; exploration et équipes ; carte de la maison ; calendrier observé ; journal des alertes ; sauvegardes et réglages. Chaque panneau répond à une question concrète et permet une action sans détour inutile.

**Sélection.** Clic : objet ou habitant ; Maj-clic : ajout à une équipe ; rectangle : habitants seulement ; clic droit : action contextuelle décrite par une infobulle. Échap ferme d'abord le panneau ou annule l'outil actif, puis ouvre la pause. Les raccourcis actuels sont conservés autant que possible, mais deviennent reconfigurables.

**Tâche impossible.** Afficher « Atelier inaccessible : pont fermé » avec un bouton centrer. Une icône rouge seule ne suffit pas. Le panneau donne la prochaine action recommandée, sans exécuter automatiquement une dépense importante.

**Caméra.** Déplacement clavier, zoom avec limites selon le secteur, rotation, recentrage sur refuge, changement de niveau et suivi d'un habitant. Prévenir les coupes de caméra qui cachent un passage sélectionné. Les plafonds gênants deviennent invisibles sans supprimer les ombres utiles.

**Accessibilité.** Taille d'interface 90-140 %, contraste et taille de texte réglables, pictogrammes doublés de texte, menace identifiable sans couleur seule, réduction des secousses et des scintillements, volume séparé des alertes, sous-titres pour indices sonores importants. DEC-09 conserve l’apparence des araignées pour tous, sans représentation alternative.

**Acceptation.** Tester 1280 x 800 et 1920 x 1080, texte français long, UI agrandie, toutes les alertes actives et clavier AZERTY. Aucun bouton hors écran, aucune commande de caméra déclenchée par un clic dans un panneau.

## 21. Direction artistique et critères de finition
**ART-01 - Cible visuelle.** Un monde miniature crédible, sombre et habité. La lumière révèle des matières usées ; le refuge apporte des points chauds. Les personnages restent reconnaissables à la distance de gestion. Le résultat doit être cohérent dans le mouvement, sans dépendre d'un angle de capture flatteur.

**Référentiel de travail.** Créer une scène étalon contenant un habitant animé, un refuge, du bois, métal, tissu, terre, une toile et deux conditions de lumière. Cette scène fixe l'échelle, les niveaux de détail et les matériaux avant de produire toute la maison. Le prototype actuel sert de point de départ et doit être clairement étiqueté comme tel.

**Matières.** Bois avec fibres, pores, fissures et zones polies ; métal avec rugosité variable et oxydation localisée ; tissu avec épaisseur, coutures et tension ; saleté accumulée dans les joints plutôt qu'un bruit uniforme sur chaque surface. Prévoir albedo, normal, roughness et masques d'usure, avec textures répétables et détails locaux.

**Lumière.** Une direction de jour cohérente à travers des ouvertures de tailles différentes. Les volumes lumineux doivent s'atténuer aux obstacles et rester stables pendant la rotation de caméra. Les torches éclairent localement ; leur scintillement reste léger. Les ombres portent la profondeur, mais ne rendent pas les ressources illisibles.

**Naturel.** Variations d'échelle, rotation, usure et densité contrôlées. L'aléatoire ne remplace pas la composition : laisser des zones calmes autour des chemins et des points d'intérêt. Toiles et poussières ont des distributions propres, pas trois copies déplacées. Les éléments dangereux doivent se distinguer des éléments décoratifs.

**Grille d'acceptation artistique.** À zoom normal et rapproché : silhouette claire, absence de facettes involontaires, UV sans étirement visible, pas de couture lumineuse, pas de scintillement, pas d'interpénétration évidente, ombres cohérentes, teinte stable sous lumière froide et chaude. Vérification en pause, en mouvement et après changement de niveau.

**Limite assumée.** Une finition professionnelle exige de reprendre personnages, animations, matériaux, décor et effets ensemble. Ne pas qualifier l'ensemble de rendu AAA tant que cette revue n'est pas réussie. Le jalon J0 valide l'ambition visuelle avant d'estimer la production définitive.

## 22. Pipeline Blender, Godot et budgets d'assets
**ART-02 - Une source éditable par lot.** Blender conserve géométrie, rig, UV, matériaux et variantes. Godot reçoit des GLB propres et des ressources de matériau adaptées au moteur. Fixer la version Blender de production après un essai d'export ; le générateur actuel fonctionne avec Blender 2.93. Ne pas dépendre d'un fichier Blender importé automatiquement au lancement.

**Nommage.** `CHR_` personnage, `FAU_` faune, `ENV_` module de décor, `BLD_` bâtiment, `PRP_` objet, `VFX_` effet. Ajouter une variante et un niveau de détail si nécessaire. Chaque lot possède un ID ART, une miniature, une échelle, son pivot, ses points d'attache et son statut de validation.

| Classe | Budget initial proposé | Contrôle |
| --- | --- | --- |
| Habitant principal | 8-15 k triangles ; LOD proche 4 k | 1 rig partagé, 2 matériaux maximum |
| Insecte | 3-8 k ; LOD 1-3 k | Réutiliser le rig par famille |
| Rongeur | 15-30 k ; LOD 6-10 k | Fourrure par matière/cartes limitée, pas de simulation de poils |
| Bâtiment | 5-20 k | États de chantier et collision séparée |
| Petit objet | 100-2 000 triangles | Instanciation ; collision simple si utile |
| Textures | 1 k usuel ; 2 k pour pièce proche | 4 k uniquement après justification visuelle |

**Budgets provisoires.** Viser moins de 2 millions de triangles visibles et 600 appels de dessin sur la scène étalon, avec mémoire vidéo sous 2,5 Go sur GTX 1650. Ces seuils doivent être mesurés ; un seul chiffre ne garantit pas 60 images/s. Privilégier matériaux partagés, atlases, LOD et instanciation avant de baisser la lisibilité.

**Livraison complète.** GLB, source Blender, textures, collisions, points d'interaction, variantes nécessaires, capture de contrôle, provenance et licence. Les modèles de gameplay ont leurs dimensions approuvées avant la navigation. Les textures ou sons externes doivent être autorisés pour redistribution dans le dépôt public ; les fichiers source ne sont publiés que si leur licence le permet.

**Révision.** Gris fonctionnel, revue d'échelle, première matière, animation, intégration, validation finale. Un asset beau mais incompatible avec le portage ou les collisions ne passe pas en terminé. Les assets du prototype à remplacer ne sont pas comptés comme finalisés.

## 23. Personnages, faune et animations à produire
L'inventaire CSV associé est la liste de suivi détaillée. Les quantités sont des lots ou variantes, pas des jours de production. Les lots CHR et FAU suivants définissent la cible minimale de campagne.

| Lot | Contenu | Minimum demandé | Priorité |
| --- | --- | --- | --- |
| CHR-01 | Habitant de référence | 1 corps, 1 rig, 3 têtes ou visages | J0-J2 |
| CHR-02 | Apparences et métiers | 6 palettes, 4 accessoires, 3 sacs | J3-J4 |
| CHR-03 | Locomotion | Repos, marche, course, portage, demi-tour | J2 |
| CHR-04 | Actions de travail | Récolte, prise, dépôt, construction, réparation | J2-J3 |
| CHR-05 | Besoins et danger | Manger, boire, dormir, peur, blessure, incapacité | J4-J5 |
| CHR-06 | Traversées et entraide | Échelle, passage étroit, transport à deux, soin | J3-J5 |
| FAU-01 | Fourmis | 1 rig, 2 variantes visuelles, 5 actions | J3 |
| FAU-02 | Araignée | 1 rig, 2 tailles, 5 actions | J5 |
| FAU-03 | Souris | 1 rig, 6 actions, 2 matières | J5 |
| FAU-04 | Rat | Variante adaptée ou rig distinct après essai | J6 |
| FAU-05 | Cloporte et cafard | 1 rig par espèce, 4 actions chacun | J6 ou option |

**Actions faune.** Marche, repos, recherche/reniflement, réaction, transport ou attaque selon espèce. Ajouter les transitions : une animation isolée ne suffit pas à masquer les changements d'état. Les longues actions utilisent des boucles interruptibles et un point de validation de résultat séparé de l'animation.

**Contrat rig.** Origine au sol, axe avant documenté, hauteur et rayon de navigation associés. Points d'attache main droite, main gauche, dos, tête et charge. Le sac représente réellement la catégorie transportée. Les variantes partagent le squelette lorsqu'elles ont la même morphologie.

**Lisibilité.** Tester les métiers sans se fier uniquement aux couleurs. Une blessure doit modifier posture ou démarche. Éviter de changer brutalement la taille d'un personnage pour une variante. DEC-09 ne prévoit pas de représentation alternative des araignées.

## 24. Environnements, bâtiments et objets
**ART-03 - Produire des kits, puis composer des lieux.** Un kit contient modules compatibles, raccords, usure, variantes et règles d'assemblage. Les zones ne doivent pas ressembler à une répétition d'un seul carré.

| Famille | Lots minimaux | Variantes / états |
| --- | --- | --- |
| Structure du sous-plancher | Planches, solives, piliers, fondations | 6 planches, 3 poutres, 4 angles/murs |
| Passages | Fissure, conduit, seuil, ouverture murale | 2 largeurs ; ouvert, bloqué, équipé |
| Cuisine | Plinthe, pied de meuble, dessous de placard | 3 modules, raccords et obstacles |
| Cloisons | Isolant, ossature, tuyau, gaine | 4 modules, intersections et dénivelés |
| Fondations | Pierre, terre, niche, terrier | 4 modules, 2 sites de refuge final |
| Habitats | Refuge initial, abri, Grand Refuge | Fantôme, chantier, fini, dégâts |
| Production | Atelier, table de préparation, culture | Même contrat de 4 états |
| Services | Dépôt, collecteur, infirmerie, veille | Points de travail et places de stockage |
| Ouvrages | Pont, échelle, étai, porte, gouttière | Modules de longueur, intégrité visible |
| Ressources | Bois, fibres, miettes, eau, métal, résine, soie | Stock faible/moyen/plein + charge portée |
| Déchets et accessoires | Clous, papier, boutons, poussière, tissus | 12 petits objets réutilisables |

**Décor fonctionnel.** Un trou praticable a un lien de navigation. Un tuyau visible ne devient une source d'eau que si un composant le déclare. Les zones de réserve et de travail sont vérifiables en mode debug. Les collisions restent simples, séparées du détail visuel.

**Bâtiments.** Ne pas modéliser chaque évolution comme un objet entièrement indépendant. Réutiliser la structure et activer des sous-ensembles : plancher, montants, toit, accessoires. Le chantier doit montrer ce qui est réellement livré et assemblé.

**Ordre de production.** Salon et cuisine d'abord. Ne pas produire grenier, salle de bains, rat final ou variantes décoratives nombreuses avant validation de J3. Les kits avancés sont conditionnés par la qualité des trajets, la lisibilité des ressources et le plaisir de la première aventure.

## 25. Effets, son et ambiance dynamique
**ART-04 - Effets nécessaires.** Poussière éclairée, rais de lumière, torches, filet d'eau, éclaboussures, vibrations de toile, brume humide locale, souffle d'aspirateur et poussière de chantier. Chaque effet possède état normal, intensité réglable et coût mesuré. Distinguer effets décoratifs et surfaces dangereuses.

**Lumière et performance.** Le prototype utilise Compatibility. Garder ce moteur tant que la scène étalon satisfait les critères. Un essai Forward+ peut comparer brouillard, ombres et qualité des matériaux sur la machine cible ; aucune migration automatique avant mesure. Limiter le nombre de lumières avec ombres qui se recouvrent. Prévoir un réglage réduit conservant les indices de danger.

**AUD-01 - Couches sonores.** Fond de maison (tuyaux, bois, ventilation), activité au-dessus (pas, chaise, vaisselle), proximité (habitants et outils), faune (griffures, frottements), événements et interface. Le son doit aider à comprendre une situation, avec une transcription visuelle disponible.

| Lot sonore | Minimum de départ | Règle |
| --- | --- | --- |
| Ambiances de secteur | 4 boucles discrètes | Transitions fondues, sans raccord audible |
| Pas humains et vibrations | 6 prises variées | Intensité selon proximité et matériau |
| Travaux et portage | 8 familles, 3 variations | Éviter la répétition mécanique |
| Faune | 4 familles de signaux | Pas de cri artificiel à chaque déplacement |
| Interface et alertes | 8 signaux courts | Priorité et volume séparés |
| Musique | 2 thèmes ou textures évolutives | Calme et tension ; silence préservé |

**Déclenchement.** Les pas humains suivent l'événement simulé. Un son ne déclenche pas une menace ; il la représente. Limiter les voix simultanées par importance et proximité, avec variation légère de hauteur et de délai. La musique ne révèle pas automatiquement un animal encore inconnu.

**Acceptation.** Comprendre un passage humain avec le son coupé ; distinguer avertissement et catastrophe ; aucune saturation lors de 20 habitants au travail. Livrer sources, exports, volumes de référence et licences dans l'inventaire.

## 26. Architecture technique et données
[[diagram:architecture]]

**TECH-01 - Séparer simulation et présentation.** Le script actuel rassemble de nombreuses responsabilités. Avant ajout des grands systèmes, extraire horloge, population, tâches, inventaires, navigation, événements et progression. Les scènes 3D affichent les états ; elles ne deviennent pas la seule source de vérité.

**Découpage candidat.** `SimulationClock`, `PopulationSystem`, `TaskSystem`, `InventorySystem`, `ConstructionSystem`, `SectorManager`, `NavigationService`, `PerceptionSystem`, `EventDirector`, `CampaignState`, `SaveService`. Ce sont des responsabilités, pas une obligation de créer dix singletons. Préférer des services explicitement possédés par la session de partie.

**Définitions.** Ressources Godot ou fichiers validés pour bâtiments, métiers, recettes, espèces et événements. Chaque définition a un identifiant stable et une version. Les données de partie contiennent des instances : habitant, pile, tâche, chantier, passage, observation. Les références utilisent des IDs, pas des chemins de nœud fragiles.

**Contrat de tâche minimal.** `id`, `type`, `target_id`, `worker_ids`, `priority`, `state`, `required_items`, `reserved_items`, `work_done`, `risk_limit`, `failure_reason`. Une transaction de stock est exécutée par un seul système. Les callbacks d'animation ne créent pas une seconde consommation.

**Répartition temporelle.** Besoins et événements au tick de simulation. Navigation/animation au pas physique. Choix d'IA déclenché par changement significatif et réparti entre les agents. Secteur lointain : simulation économique réduite avec timestamps ; pas de résolution de collisions invisible coûteuse.

**Outillage.** Affichages debug pour chemin, rayon de perception, réservations, coût des tâches, occupation des passages et raison de refus de construction. Une arène de tests par système permet de reproduire un bug sans rejouer toute la campagne. Journal circulaire des dernières décisions d'IA, exportable sans données personnelles.

## 27. Sauvegardes, stabilité et livraison
**TECH-02 - Sauvegarde versionnée.** Enregistrer version de format, graine, horloge, définitions nécessaires, secteurs découverts, positions, besoins, métiers, stocks, réservations, tâches, chantiers, animaux persistants, observations et objectifs. Les particules, shaders et animations se reconstruisent à partir de l'état ; ils ne sont pas sérialisés.

**Transaction.** Mettre la simulation en pause au point de cohérence, écrire un fichier temporaire, vérifier sa structure puis remplacer atomiquement la sauvegarde cible. Conserver une copie précédente. Si l'écriture échoue, l'ancienne partie reste chargeable et le joueur est informé.

**Chargement.** Vérifier version, références et quantités, charger les définitions, créer les entités, restaurer les connexions, revalider les chemins, puis relancer la simulation. Une tâche dont la cible manque est suspendue avec raison, pas silencieusement supprimée. Prévoir une migration explicite entre versions compatibles.

**Tests de reprise.** Sauvegarder pendant un pont en chantier, un habitant chargé, une file de conduit, une poursuite et un sauvetage. Après chargement, inventaire et progression sont conservés. Les tâches ne s'exécutent pas deux fois. Une pause sauvegardée reste en pause au chargement.

**Livraison PC.** Build Windows autonome avec numéro de version et scénario de référence. Réglages vidéo, audio et commandes dans un fichier utilisateur séparé. Sauvegardes sous le répertoire utilisateur Godot, jamais dans le dossier d'installation. Le dépôt contient les instructions d'export et les dépendances minimales.

**Gestion du projet.** Petits commits par fonctionnalité validée, tags aux jalons acceptés, changements de format de données documentés. Ne pas publier une nouvelle build comme stable si un test de conservation des stocks ou de chargement échoue. Les documents de conception restent séparés du code de simulation.

## 28. Qualité, tests et budgets de performance
**QA-01 - Trois niveaux de preuve.** Tests automatisés de règles ; scénarios d'intégration ; essais humains. Une capture réussie ne prouve pas la navigation, et un test headless ne valide pas les shaders. Chaque jalon indique les trois types nécessaires.

| Domaine | Scénario vérifiable | Critère de passage |
| --- | --- | --- |
| Stocks | Récolte, livraison, annulation, destruction | Conservation exacte, aucune valeur négative |
| Tâches | Cible indisponible, rappel, réaffectation | Réservation libérée, raison de blocage visible |
| Navigation | Goulet, obstacle dynamique, lien vertical | Aucun agent bloqué sans explication >10 s |
| Sauvegarde | Reprise au milieu de 5 actions critiques | État cohérent et objectifs inchangés |
| Perception | Ressource cachée, bruit derrière paroi | Pas d'information ou d'attaque à travers un mur |
| UI | Petit écran, texte long, grossissement | Pas de contrôle masqué ou chevauché |
| Visuel | Caméra normale, rotation et gros plan | Pas de couture, effet plat ou scintillement gênant |

**Budgets proposés.** 1080p, GTX 1650 comme machine de référence provisoire : viser 60 images/s en réglage standard ; 30 images/s minimum en situation chargée avant optimisation finale. Mesurer médiane, 95e percentile et pointes, avec matériel, résolution, version et scène. Cible de frame totale à 60 images/s : 16,7 ms.

**Scène de charge.** 50 habitants, 20 insectes actifs, 15 bâtiments, 3 secteurs dont un détaillé, livraisons simultanées et événement humain. Budget CPU de simulation candidat : 4 ms par image en moyenne ; mémoire vidéo cible sous 2,5 Go. Ces budgets ne sont pas acquis par le prototype actuel.

**Stabilité.** Partie de 60 minutes accélérée, aucune croissance mémoire continue non expliquée, aucune erreur de script, 20 sauvegardes/chargements successifs. Tester également zoom, rotation et ouverture répétée des panneaux.

**Playtests.** À J3 puis J6, 3 à 5 personnes minimum si disponibles. Noter sans guider : première récolte, première affectation, compréhension du danger, temps inactif, reprises après erreur, décisions différentes et frustrations. Modifier les règles avant de multiplier les assets si la boucle n'est pas comprise.

## 29. Roadmap : du socle à la première aventure
**Ordre opérationnel actualisé.** Les jalons ci-dessous définissent des résultats cibles, pas leur état d’avancement. Le [plan de production par étapes](roadmap-production.md) fournit le bilan actuel, les démonstrations et les arrêts pour validation ; il remplace l’ancien ordre de reprise.
[[diagram:roadmap]]

Les jalons sont des contrats de résultat, pas des dates promises. Taille indicative : S = lot limité, M = plusieurs systèmes liés, L = étape nécessitant essais et itérations. Une estimation en jours de travail ne sera crédible qu'après J0 et le premier test de navigation. Limiter le travail en cours à un jalon principal.

| Jalon | Livrable | Dépendances | Taille |
| --- | --- | --- | --- |
| J0 - Accord de conception | Décisions critiques, scène étalon, budgets | Retour du joueur sur ce dossier | M |
| J1 - Socle fiable | Données, horloge, stocks, tâches, sauvegarde v1 | J0 | L |
| J2 - Colonie qui travaille | Obstacles, files, chantiers, habitants animés | J1 | L |
| J3 - Atteindre la cuisine | Exploration, pont, dépôt, fourmis, mini-tutoriel | J2 | L |
| J4 - Colonie durable | Eau, besoins, métiers, outils, soins | J3 validé | L |
| J5 - Maison vivante | Horaires, suspicion locale, araignée, souris | J4 | L |
| J6 - Grand Refuge | Secteurs de campagne, progression, évacuation | J5 | L |
| J7 - Finition et diffusion | Optimisation, accessibilité, audio, correctifs | J6 | L |

**J0 : sortir de la discussion avec une cible.** Valider ton, mortalité, population, style et première mission. Produire une seule scène étalon avec personnage animé et matériaux de référence. Comparer la lisibilité et le coût graphique ; décider de conserver Compatibility ou d'approfondir un autre rendu. Pas de kit complet de maison avant cette décision.

**J1 : protéger l'intégrité du jeu.** Extraire les responsabilités du script principal, définir les IDs et le format de sauvegarde, rendre les stocks locaux, ajouter le cycle de tâches avec réservations. Critère : une livraison interrompue puis chargée ne perd ni ne duplique rien. Les graphismes peuvent rester ceux du prototype.

## 30. Roadmap : étapes jouables, campagne et finition
**J2 : rendre les ordres crédibles.** Maillage de navigation, obstacles, liens, pont réservable, vrai chantier et premières animations. Critère : 20 habitants traversent un goulet, construisent et livrent sans blocage permanent. Un arrêt de chantier est propre et explicable.

**J3 : premier feu vert de gameplay.** Assembler le parcours décrit au chapitre 06, avec une menace fourmi limitée et plusieurs solutions. Faire tester. Ce jalon décide si le projet mérite d'étendre sa carte et son catalogue d'assets.

**J4 - Durabilité.** Ajouter eau et préparation de nourriture, compétences, métier de logisticien, repos, blessures et soin. Une arrivée d'habitant dépend des réserves. Produire les accessoires de métiers et les services essentiels. Acceptation : 10 habitants vivent trois jours, une pénurie est compréhensible et récupérable, les données se rechargent sans dérive.

**J5 - Menaces lisibles.** Remplacer le cycle global simplifié par routines observables et alertes locales. Ajouter araignée et souris dans des secteurs dédiés ; introduire détournement, camouflage et portes. Acceptation : trois solutions différentes face à une menace, aucune perception omnisciente, comportement identique avant et après sauvegarde à état équivalent.

**J6 - Campagne.** Composer les cloisons et fondations, ajouter savoir-faire, événements de rénovation, construction du Grand Refuge et évacuation, puis accès à la ville souterraine indépendante avec échanges, recrutement et missions. La partie peut continuer après le Grand Refuge. Rat seulement si sa fonction ne duplique pas la souris. Acceptation : campagne terminable, deux itinéraires finaux, aucune ressource indispensable dans une zone irréversiblement perdue sans alternative ; visite de la ville puis retour au refuge conservé.

**J7 - Finition.** Revue artistique par secteur, sons finalisés, profils de performance, réglages, localisation française vérifiée, tutoriel allégé et correction des difficultés mal signalées. Acceptation : critères QA du chapitre 28, build autonome installable, sauvegardes robustes et aucune erreur bloquante connue.

**Dépendances fortes.** Navigation avant expansion ; stocks et sauvegardes avant économie complexe ; première aventure avant nouveaux biomes ; perception avant animal dangereux ; scène étalon avant multiplication des assets finaux. Une amélioration graphique peut avancer en parallèle conceptuellement, mais ne doit pas retarder la validation du jeu jouable.

**À réduire en premier si le périmètre déborde.** Reporter grenier et salle de bains ; garder une seule espèce de rongeur ; réduire les variantes de métiers ; étaler la domestication utile en un lot distinct, reporter le chariot et réduire les chaînes avancées. Préserver les choix de trajet, les travaux utiles et l'autonomie des habitants.

**Fin de jalon.** Démonstration de 10 minutes, résultats de tests, capture ou vidéo, liste des limites, mise à jour de l'inventaire et validation du joueur. Une étape refusée repart en correction avec un objectif précis ; elle ne déclenche pas automatiquement le jalon suivant.

## 31. Risques et arbitrages de production
| Risque | Signal précoce | Réponse proposée |
| --- | --- | --- |
| Graphismes avant gameplay | Effets améliorés mais mêmes décisions de jeu | Geler le décor hors bugs jusqu'au test J3 |
| Trop de microgestion | Nombreux habitants inactifs sans raison claire | Priorités, tâches secondaires, alertes explicatives |
| Navigation instable | Files qui se croisent, agents traversant un pont fermé | Liens réservables et arène de tests avant nouveaux secteurs |
| Économie punitive | Tout le travail absorbé par la nourriture | Ajuster trajets, consommation et stock initial |
| Faune arbitraire | Attaques sans indice ou connaissance impossible | Perception locale et délais de réaction visibles |
| Coût artistique excessif | Beaucoup de variantes jamais vues de près | Scène étalon, kits, LOD, catalogue limité |
| Sauvegardes fragiles | Perte de réservations ou doublons après reprise | Transactions, IDs stables, migrations testées |
| Ambition de campagne trop grande | Secteurs copiés sans nouvelle décision | Quatre secteurs forts avant six secteurs complets |

**Arbitrage principal.** Le projet a besoin d'une finition cohérente et d'une boucle stratégique éprouvée. Une demande de réalisme accru peut augmenter fortement le coût des rigs, animations et textures. La scène étalon doit rendre ce coût visible avant engagement sur l'ensemble de la maison.

**Dette actuelle à traiter.** Script de jeu centralisé, déplacements en ligne droite, économie globale, absence de sauvegarde et de sons. La reprendre est une étape de production normale, pas une raison de jeter tous les assets. Les modèles et shaders existants restent utiles pour tester les volumes et le ton.

**Règle d'ajout d'une idée.** Décrire le choix de joueur qu'elle apporte, sa dépendance, ses assets, son coût technique et son test d'acceptation. Si elle ne change qu'un chiffre, la comparer à une extension d'un système existant. Toute nouvelle espèce ou nouvelle zone doit justifier sa place.

**Réserves de planning.** Ne pas affecter tout le temps disponible à la création de contenu : garder une marge pour tests, outils et retours. Après J2, mesurer le temps réel nécessaire pour produire un bâtiment complet et un agent animé ; extrapoler seulement à partir de ces deux exemples.

## 32. Décisions retenues et détails ouverts
Les choix ci-dessous sont issus de l’entretien, pas de nouvelles propositions. Leur réalisation demeure progressive.

| ID | Sujet | Retour / choix | Statut |
| --- | --- | --- | --- |
| DEC-01 | Ton et difficulté | Choix 1B : gestion de colonie avec de vraies difficultés, mais du temps pour anticiper et récupérer, « un peu comme RimWorld ». Cette référence ne valide pas automatiquement tous les systèmes de ce jeu. | Validé en entretien |
| DEC-02 | Mort, blessures et sauvetage | Choix 2B : mort définitive possible, seulement après un danger clairement annoncé et une possibilité de sauvetage. Modalités et délais à concevoir. | Validé en entretien |
| DEC-03 | Population maximale | Choix 1B : une colonie de 30 à 50 habitants à terme, avec métiers spécialisés et logistique. L'effectif initial reste à préciser. | Validé en entretien |
| DEC-04 | Direction artistique | Choix 1B : minuscules humains réalistes mais légèrement stylisés, avec silhouettes et expressions lisibles à distance. Choix 2C : objets détournés intégrés à de petites maisons en matériaux récupérés. Direction retenue ; réalisation visuelle à valider sur une scène étalon. | Direction validée en entretien |
| DEC-05 | Rénovation et but final | Choix 1B+C : construire un Grand Refuge durable et protégé, pouvoir continuer à jouer, et préparer une migration face aux rénovations menaçant le refuge initial. Menace annoncée suffisamment tôt. Ville souterraine indépendante retenue à terme : échanges, recrutement et missions, tout en conservant notre refuge (choix 1B suivant). Articulation des étapes et calendrier de production à préciser. | Direction validée en entretien |
| DEC-06 | Carte et variations | Choix 3B : structure générale de la maison conçue à la main, avec passages, ressources et territoires animaux variables entre les parties. | Validé en entretien |
| DEC-07 | Place du combat | Choix 1B, « un peu à la RimWorld » : évitement et défense, avec des habitants équipés pour combattre lorsque nécessaire. Les modalités de mobilisation, équipements et tactiques restent à préciser. La référence ne valide pas automatiquement tous les systèmes de combat de RimWorld. | Validé en entretien |
| DEC-08 | Première aventure cuisine | Choix 3B : conserver refuge, fissure, pont et accès à la nourriture près de la cuisine avec fourmis, mais consacrer davantage de temps à la construction et à l'aménagement avant l'expédition. Réviser le déroulé et la durée cible du chapitre 06. | Validé avec modification |
| DEC-09 | Arachnophobie | Choix 3B : conserver l'apparence des araignées pour tout le monde, sans mode de représentation alternatif. | Validé en entretien |
| DEC-10 | Domestication | Choix 2B, « à la RimWorld » : quelques espèces d'insectes apprivoisables pour transporter des charges ou produire des ressources. Espèces, entretien et jalon d'introduction à définir. Un système approfondi de reproduction et de dressage n'est pas validé par ce choix. | Validé en entretien |
| DEC-11 | Nombre de secteurs | Choix 2B : première campagne avec sous-plancher du salon, cuisine, cloisons, fondations et ville souterraine ; grenier et salle de bains plus tard. Extérieur et nouvelles zones procédurales évoqués pour prolonger la partie : extension à approfondir. | Périmètre de campagne validé ; extension à préciser |
| DEC-12 | Rythme, durée du jour et besoins | Choix 1C, « à la RimWorld » : garder une durée de journée provisoire puis décider après essai, avec pause et accélération disponibles. Besoins retenus : nourriture, eau, repos, confort et soins ; température, humidité et fumée influencent la vie de la colonie. Durées et valeurs à tester. | Méthode de réglage et besoins validés |

**Compléments retenus.** Construction mixte : pièces sur grille, murs, portes, sols et mobilier, avec structures prêtes à placer. Verticalité par échelles, ponts et futurs monte-charges. Travaux désignés par le joueur, exécutés selon priorités ; contrôle direct d’urgence. Croissance par voyageurs et rescapés plutôt que naissances. Recherche liée aux découvertes. Relations individuelles, amitiés et tensions, sans déduire un système complet de familles.

**Détails ouverts.** Durée du jour, dimensions de grille, budgets de simulation, délais de secours, espèces domestiquées, règles de contrôle des groupes et propagation de température/humidité/fumée. Une simulation complète des gaz et fluides n’est pas requise par la référence à Oxygen Not Included.

**Exploration ajoutée à la suite.** Torches individuelles fabriquées, autonomie lumineuse, passages physiques entre secteurs et routes équipées. Les règles de mains occupées, combustible, persistance et retour sont proposées dans la roadmap pour validation par démonstration.

## 33. Méthode de retour et ordre de reprise
Le joueur demande une livraison à la fois : résultat présenté, validation, puis commit et push. Une correction demandée fait partie de l’étape en cours. Aucune publication de cette révision ou d’un nouveau lot avant son accord.

**Étape actuelle — bilan du 24 septembre 2026.** Gameplay publié jusqu’au lot 18 (`06226a1`) et catalogue de références V01 publié (`1d88614`). Les lits approvisionnés, dépôts locaux, besoins autonomes, torches, lanternes et fissure aménageable existent. La visite d’alcôve reste à vide et la sauvegarde v8 impose le retour au refuge. La [roadmap détaillée](roadmap-production.md) distingue les acquis des travaux restants. Le PDF v0.1 demeure historique ; il ne doit pas servir de liste des fonctionnalités actuelles.

**Premier résultat jouable suivant.** Étape 6A : reconnaître le secteur adjacent avec une lanterne et revenir par la fissure. Puis 6B : rendre le passage compatible avec une charge et rapporter une ressource existante utile au refuge ; 6C : sauvegarder et reprendre en expédition. Réutiliser les modèles fonctionnels. La fourmi intervient ensuite sur le parcours cuisine ; la refonte artistique générale attend le bilan du premier chapitre. Le plan détaille chaque démonstration et ses critères ; sa révision est validée par le joueur, avec validation séparée des futurs lots.

**Références.** Les fiches `gameplay-lot-06.md` à `gameplay-lot-13.md` documentent les incréments déjà livrés. Le fichier `inventaire-assets.csv` est la source de suivi des assets ; les quantités sont des cibles, et un statut partiel ne vaut pas acceptation du lot complet.

## 34. Annexe : valeurs initiales à tester
Ces valeurs sont des points de départ de prototypage. Elles ne sont pas encore intégrées au jeu et ne constituent pas un équilibrage validé. Les unités de distance suivent la convention du chapitre 05.

| Agent | Santé | Vitesse U/s | Vue U | Particularité |
| --- | --- | --- | --- | --- |
| Habitant | 100 | 1,20 vide / 0,96 chargé | 5 | Rayon de collision 0,25 ; hauteur 1,6 |
| Éclaireur | 100 | 1,30 vide | 7 | Sac 2 emplacements, risque réglable |
| Fourmi | 20 | 0,95 | 2 | Suit odeur/piste jusqu'à 6 U connectées |
| Araignée | 80 | 1,35 en sortie courte | 3 | Vibration perçue sur sa toile fonctionnelle |
| Souris | 250 | 2,10 | 6 | Poursuite limitée à 8 s ou 12 U |
| Rat | 400 | 1,80 | 5 | Territoire et intimidation avant attaque |
| Cloporte | 60 | 0,45 | 1,5 | Attiré par humidité, évite le sec |
| Cafard | 45 | 1,65 | 3 | Fuite vers cache connue à la lumière |

**Dégâts et réaction candidats.** Fourmi défensive : 5 points, intervalle minimal 2 s, contact inférieur à 0,45 U. Araignée : immobilisation annoncée de 1 s puis blessure de 15 points ; pas de capture instantanée hors toile. Souris : préparation visible de 1,2 s puis 30 points, portée inférieure à 1 U. Rat : 40 points après 1,5 s. Ces attaques sont interrompues si la cible sort de portée ou derrière une paroi ; le groupe de fourmis possède un plafond d'attaques simultanées pour éviter une mort en une image.

**Fuite.** Habitant fuyant : vitesse x1,15 pendant 4 s, puis fatigue accrue. Un poursuivant cesse d'attaquer après perte de perception et délai propre à l'espèce. Les chiffres doivent permettre une fuite après alerte précoce ; si ce n'est pas le cas, réduire la portée ou augmenter la préparation avant d'augmenter la santé artificiellement.

**Gisements de la première aventure.** Départ : 12 rations, 12 bois, 8 fibres, 4 places de lit provisoires et eau non activée. Cuisine : biscuit de 36 portions brutes, piste de fourmis visible après observation. Renouvellement partiel par repas humain annoncé, plafond de stock pour éviter l'accumulation infinie. Les portions de départ protègent le tutoriel ; les scénarios suivants réduisent cette marge.

**Environnement.** Humidité locale 0-100 ; sous 25, culture en pause ; 40-70, favorable ; au-dessus de 85, moisissure possible après un délai de 1 jour. Intégrité de bâtiment 0-100 ; alerte à 60, fonction suspendue à 40, effondrement à 0. Ne pas ajouter température détaillée avant que l'humidité produise des décisions intéressantes.

## 35. Annexe : matrice de livraison et définition de terminé
| Système | Jalon de première preuve | Asset ou donnée indispensable | Preuve attendue |
| --- | --- | --- | --- |
| SYS-07 tâches | J1 | Types, états et réservations | Réaffectation sans doublon |
| SYS-08 logistique | J1-J2 | Conteneurs, charges, capacités | Bilan de stock conservé |
| SYS-09 navigation | J2 | Collisions, pont et points d'attente | Goulet à 20 habitants |
| SYS-10 exploration | J3 | Passage, brouillard et indices | Découverte puis retour autonome |
| SYS-12 travaux | J2-J3 | Pont en états de chantier | Livraison, montage, interruption |
| SYS-05/06 habitants | J4 | Rig, besoins, compétences | Vie de 10 habitants sur 3 jours |
| SYS-13 humains | J5 | Calendrier, sons et événements | Observation utile à une sortie |
| SYS-14/15 faune | J3 puis J5 | Rigs, perception, territoires | Contournement et absence d'omniscience |
| SYS-17 campagne | J6 | Secteurs, objectifs et fin | Partie complète terminable |
| ART-01 à 04 | J0 puis chaque jalon | Scène étalon, kits et sons | Revue sous plusieurs angles |
| TECH-02 sauvegarde | J1 puis chaque jalon | Schéma versionné et migrations | Reprise des 5 états critiques |

**Terminé signifie.** Fonctionnement conforme au scénario attendu ; comportement explicite en cas d'échec ; intégration à la sauvegarde ; interface et feedback lisibles ; absence d'erreur ; tests adaptés réussis ; coût CPU/GPU connu lorsque pertinent ; documentation et inventaire actualisés. Une fonctionnalité non persistée reste expérimentale.

**Pour un asset.** Échelle, pivot, UV, matériaux, rig et collisions vérifiés selon son usage ; versions de chantier ou de dégâts livrées si requises ; licence tracée ; source modifiable conservée ; intégration dans la scène étalon validée. Le statut « prototype existant » ne devient pas « final » par simple réutilisation.

**Pour une proposition nouvelle.** Affecter un identifiant, un jalon et un critère de réussite. Si elle change une règle déjà validée, mentionner les tâches, recettes, assets et sauvegardes impactés. La revue du joueur clôt la décision ; la production ne démarre pas sur une supposition implicite.
