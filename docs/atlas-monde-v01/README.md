# Atlas du monde — proposition V01

25 septembre 2026. Base du projet : `ec1214c`. **Plan proposé pour discussion, pas une carte déjà implémentée.** La réalisation reste une étape à la fois selon la [roadmap validée](../conception/roadmap-production.md).

Le joueur a autorisé le commit et la publication de cet atlas. Les implantations futures restent à éprouver dans les lots correspondants ; cette publication n’engage pas leur développement simultané.

Ouvrir [l’atlas illustré](index.html). Il comprend **11 plans vectoriels**, **9 fiches de secteurs/sous-zones** et **12 types de liaisons** : vue d’ensemble, coupe verticale, puis un plan par zone. Les cartes s’ouvrent en grand sans perte de netteté. Les détails textuels sous chaque carte complètent les repères. Le bouton d’impression rassemble les fiches ; format conseillé A3 paysage. Les SVG peuvent également être imprimés séparément.

## 1. Ce qui est fixé et ce qui est proposé

**Direction déjà retenue :** maison artisanale, salon, cuisine, cloisons, fondations, ville souterraine indépendante ; Grand Refuge et migration annoncée ; maintien du refuge du joueur ; salle de bains et grenier différés ; extérieur procédural persistant et avant-postes plus tard.

**Propositions de cet atlas :** subdivision S00–S05, noms des passages, implantation des poches de ressources, emplacement du Grand Refuge, position de la ville dans la strate N−2, tracés L02–L12 et double accès à la ville. Les deux routes de migration répondent à l’objectif de deux itinéraires finaux du cahier des charges ; leur géométrie précise reste à tester.

**État réel :** le salon, son palier Est, ses ressources et la fissure existent. L’alcôve est visitable à vide par un trajet dédié. La lanterne ne fonctionne pas encore dans cette mission. Les autres secteurs sont des concepts. La couleur verte de L01 indique un seuil existant, pas une expédition complète déjà réalisée.

**Pas de changement de roadmap.** Le prochain chantier reste 6A, avec l’alcôve seulement. Le tracé de la cuisine et des extensions n’autorise pas leur production immédiate. Le catalogue d’assets reste la référence visuelle ; les modèles existants sont réutilisés.

## 2. Lire les cartes

| Code visuel | Signification |
| --- | --- |
| S00–S05 | Secteurs opérationnels de campagne ; S01 est une sous-zone du salon, pas un cinquième milieu de maison |
| E01–E03 | Extensions différées, non nécessaires à la campagne principale |
| Z* | Famille de futures zones extérieures ; chaque zone découverte aura un ID réel stable |
| A, B, C… | Repères locaux ; lire le nom et la fonction dans la légende de la planche et sa fiche |
| L01–L12 | Registre des accès entre secteurs ; deux voies peuvent appartenir au même accès (L02) |
| Vert continu, vue globale | Seuil partiellement existant |
| Ocre discontinu, vue globale | Liaison de campagne proposée, à reconnaître/aménager |
| Mauve pointillé, vue globale | Extension différée |
| Vert continu, plans locaux futurs | Circulation proposée ; seul le salon représente des positions actuelles |
| Carrés | Habitat, accès, logistique ou service, distingués par la couleur et la légende |
| Cercles | Ressource, danger, observation ou obstacle ; lettres et légende restent lisibles sans couleur |
| Hachures rouges | Poche dangereuse ; ne signifie pas une zone constamment mortelle |

La vue d’ensemble est un **graphe déplié**, pas un plan cadastral. Les lignes ne fixent ni longueur ni altitude. Les plans locaux futurs sont des schémas fonctionnels : les volumes non praticables structurent les itinéraires, sans figer une architecture finale. Les lettres portent les informations essentielles ; les tableaux restent lisibles à petit écran.

## 3. Échelle et verticalité

Le nord du plan S00 correspond conventionnellement à −Z, l’est à +X. Les coordonnées du salon sont relevées dans le code et exprimées en unités Godot. Les chemins tracés ne sont pas les chemins exacts calculés par la navigation. La position des meubles placés par le joueur n’est pas imposée.

Le cahier des charges propose provisoirement une unité = 1 cm et des secteurs de 20 à 40 unités, mais cette échelle fictive n’est pas définitivement validée. **Ne pas redimensionner le personnage ou le niveau à partir de ce document.** Le gabarit existant et les animations restent l’étalon ; Blender et Godot conservent leur correspondance 1:1.

N0 désigne le réseau sous les planchers ; N+1 les hauteurs des cloisons ; N+2 le grenier ; N−1 les fondations ; N−2 la galerie de la ville. Ces niveaux sont topologiques, sans hauteur métrique imposée. Le palier actuel du salon à y ≈ 2,04 est un relief local de N0, pas un nouvel étage de maison.

## 4. Parcours et progression

| Moment | Parcours | Ce que le joueur décide |
| --- | --- | --- |
| Départ | S00, refuge et ressources proches | Aménager couchages, réserves et atelier ; assurer eau et nourriture |
| 6A | S00 → L01 → S01 → retour | Équiper la lanterne, reconnaître et garder de l’autonomie |
| 6B–6C | Même route, après adaptation au portage | Rapporter des fibres utiles aux lits ; reprendre une mission sauvegardée |
| 7 | S00 ↔ S01 | Construire un dépôt, organiser les transferts et entretenir la lumière |
| 11A–11C | S00 → S01 → L02 → S02 | Construire le pont porteur, observer les fourmis, détourner le trajet ou attendre |
| Campagne | S00/S02 → S03 | Collecter l’eau, observer et aménager la verticalité |
| Migration principale | S00 → L03 → S03 → L05 → S04 | Préparer une route chargée, les haltes et le Grand Refuge |
| Migration de secours | S00 → L01 → S01 → L02 → S02 → L06 → S04 | Maintenir une route distincte de la descente des cloisons |
| Rencontre | S04 → L07 ou L08 → S05 → retour | Échanger, recruter et obtenir des missions, sans céder le refuge |
| Prolongement | S03 → E01/E02 ; S04 → E03 → Z* | Ouvrir seulement les extensions utiles et entretenir les avant-postes |

La fissure élargie de 6B et le pont de cuisine de 11A sont **deux ouvrages distincts**. La passerelle actuelle vers la réserve Est est un troisième ouvrage, déjà présent dans S00. Ne pas les confondre ni remplacer silencieusement les accès validés.

## 5. Contrat commun aux passages

Chaque Lxx doit devenir un lien à deux seuils physiques : ID source et destination, niveau, gabarit utile, largeur, capacité, sens autorisés, temps de traversée, restrictions d’équipement/charge, visibilité et état de chantier. Les IDs Sxx de l’atlas sont des IDs de conception ; ils ne remplacent pas encore les identifiants du code. L01 correspond au contrat actuel `south_fissure`, de `refuge_south` à `alcove_north`.

États proposés : inconnu → repéré → inspecté → aménageable → chantier → ouvert ; suspension temporaire si un danger local rend la route inutilisable. Chaque sens possède son point d’attente hors du seuil. Une traversée engagée conserve son propriétaire jusqu’à ce que le corps et la charge aient dégagé la sortie. Un rappel ne téléporte jamais l’habitant.

Pour L02, le détour étroit et le pont sont deux liens de navigation locaux avec leurs propres restrictions. Pour L07 et L08, les arrivées de ville sont distinctes ; ne pas les faire dépendre du même dernier goulet. L12 est un type de connexion répétable vers des zones Z001, Z002… créées plus tard, pas une boucle E03 → E03.

La carte visible par le joueur ne doit pas montrer tous ces plans au début : inconnue, repérée, reconnue, actuellement observée. Les découvertes restent mémorisées ; positions d’animaux et danger actuel exigent de nouvelles observations. L’atlas complet est un outil de conception avec révélations de campagne.

## 6. Ressources, dangers et absence de blocage

- Bois, fibres, nourriture et eau restent accessibles dans S00 au départ. Aucune ressource d’extension n’est obligatoire pour terminer J3 ou établir le Grand Refuge.
- Un accès se construit avec des ressources disponibles de son côté accessible. Aucun coût ne dépend exclusivement de la zone située derrière cet accès.
- S01 introduit seulement une source distante de fibres, pas une chaîne supplémentaire. La cuisine donne une raison de transporter régulièrement des provisions.
- La piste de fourmis est locale et annoncée ; le détour et l’attente restent des options réelles. Pas de combat obligatoire pour la première récolte.
- La ville propose échanges et services, pas des stocks gratuits infinis ni la simulation automatique de toute sa population comme habitants de la colonie.
- Une rénovation obligatoire n’interrompt pas simultanément les deux routes de migration. Avertissements et temps de préparation sont nécessaires ; le refuge initial n’est pas effacé automatiquement à la découverte du Grand Refuge.
- Les dangers d’eau, de froid, de fumée et les rongeurs sont des fonctions futures à introduire avec leurs systèmes, pas des dégâts invisibles ajoutés à des décors.
- Mesurer les durées réelles aller/retour, les files et le travail avant de fixer les tailles futures. L’autonomie actuelle de 180 secondes de lanterne n’est pas la promesse de couvrir toute la campagne.

## 7. Variations et extérieur

La maison conserve son réseau artisanal. Petits gisements, débris, événements et territoires peuvent varier dans des poches définies ; géométrie des accès majeurs, repli et premières ressources restent garantis. Une graine ne doit pas supprimer l’unique solution d’un objectif obligatoire.

L’extérieur ne peut pas être cartographié entièrement à l’avance si l’exploration doit se prolonger indéfiniment. Le plan fixe donc son **seuil, son modèle de zone et ses règles de connexion**, pas une infinité de cartes fictivement finies. Chaque zone générée aura sa graine, ses connexions réversibles, ses stocks, constructions, découvertes et conséquences persistantes. Les avant-postes prolongent la logistique du refuge principal ; ils ne créent pas plusieurs colonies complètes à gérer.

## 8. Assets et ordre de réalisation

| Zone | Réemploi / création minimale | Références du catalogue |
| --- | --- | --- |
| S00 | Conserver les modèles ; nouveaux modules de chambre seulement aux lots dédiés | 01, 07, 08, 09, 10 |
| S01 | Sol, fissure, étai, fibres et caisse ; adapter le gabarit seulement en 6B | 11, 12 |
| S02 | Kit de plinthe, pont porteur, biscuit, une fourmi riggée | 03, 11, 12 |
| S03 | Montants, paliers, isolant, tuyau et collecteur ; câbles en obstacles | 08, 11, 12 |
| S04 | Maçonnerie, sol sec/humide, Grand Refuge modulaire, souris au lot faune | 06, 09–12 |
| S05 | Kit architectural commun, services distincts, signalétique ; pas une tenue unique pour chaque PNJ | 02, 07, 09, 10 |
| E01–E03 | Aucun asset à produire maintenant ; décomposer chaque extension lors de son engagement | Références à compléter au besoin |

## 9. Vérifications avant de transformer le plan en niveau

1. Valider les noms, les destinations et la progression avec le joueur.
2. Construire en volumes simples le seul secteur du lot engagé ; garder le personnage existant comme étalon.
3. Tester un habitant à vide, puis équipé et chargé ; contrôler les intersections, appuis, files, collisions et clics d’étage.
4. Mesurer durée de trajet et marges de retour, besoins compris ; aucune distance de cet atlas n’est un équilibrage final.
5. Tester source épuisée, dépôt plein, route indisponible, rappel et secours selon périmètre.
6. Comparer la comptabilité avant/après transfert et sauvegarde ; les deux côtés du passage ne possèdent jamais le même habitant ou la même caisse.
7. Habiller dans Blender seulement après ces preuves, puis présenter le résultat et attendre la validation avant commit/push.

## Sources et fichiers

- [Cahier des charges](../conception/cahier-des-charges.md), chapitres 05, 06, 12, 13, 29 et décisions DEC-05/06/08/11.
- [Retours du joueur](../conception/retours-et-decisions.md), [roadmap](../conception/roadmap-production.md), [lot 18](../conception/gameplay-lot-18.md).
- Positions existantes : [game.gd](../../scripts/game.gd), [ladder_passage.gd](../../scripts/ladder_passage.gd), [bridge_passage.gd](../../scripts/bridge_passage.gd), [fissure_passage.gd](../../scripts/fissure_passage.gd).
- `atlas.json` : secteurs, points d’intérêt et registre des connexions ; données de conception uniquement.
- `cartes/` : onze SVG éditables et imprimables, produits par géométrie déterministe ; pas de génération d’image pour les tracés.
- [Générateur](../../tools/build_world_atlas.py) : `python tools/build_world_atlas.py` depuis la racine reconstruit les cartes et la galerie.

Les positions futures restent à valider ; seuls les repères du salon cités avec coordonnées sont relevés dans le jeu. Aucun fichier de gameplay n’est modifié par cet atlas.
