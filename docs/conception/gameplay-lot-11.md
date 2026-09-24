# Lot 11 — Sauvegarde au refuge et reprise de la colonie

État : validé par le joueur (« validé, tu peux commit pousser »), publication autorisée. Cette étape assure la persistance de la première zone découverte avant d’étendre la carte et ses connexions. Elle suit le lot 10 validé.

## Utilisation

**F5**, ou « Sauvegarder au refuge » dans **Objectifs [O]**, demande un point de sauvegarde. La colonie est rappelée ; les charges déjà prélevées sont livrées, les traversées engagées se terminent, puis les habitants entrent au refuge. Le fichier n’est écrit qu’une fois tous les habitants installés, les réservations libérées et la porte fermée. Un message confirme la réussite et le jeu se met en pause.

La sauvegarde correspond donc à la fin du retour, pas à l’instant où F5 a été pressé. L’économie et les risques continuent pendant le rappel : nourriture consommée, livraisons et passage des humains suivent leurs règles habituelles. Une demande effectuée en pause attend que le joueur reprenne avec **Espace**, sauf si tout le monde est déjà installé. Il faut attendre le message de réussite avant de fermer le jeu.

Pendant l’attente, le panneau Objectifs indique combien d’habitants sont à l’abri. Son bouton permet d’annuler la demande sans supprimer le rappel. Donner l’ordre « Ressortir » annule également une sauvegarde en attente. Les affectations sont conservées ; une reconnaissance encore inachevée est interrompue selon les règles normales du rappel et pourra être relancée.

**F9**, ou « Charger la sauvegarde », reprend le point enregistré. Depuis une partie en cours, un panneau met le jeu en pause et demande de confirmer le remplacement des progrès non enregistrés. « Continuer la partie » ou **Échap** ferme ce panneau et rétablit l’état de pause précédent. Depuis l’accueil, « Reprendre la sauvegarde » charge directement le fichier disponible. L’écran de fin de partie permet aussi de reprendre ce point.

La reprise commence en pause, avec les habitants à l’intérieur. **H** prépare leur sortie puis **Espace** reprend le temps ; les tâches conservées redémarrent après le franchissement de la porte.

## Données conservées

- Stocks de nourriture, bois et fibres ; quantités restantes et découverte des gisements.
- Bâtiments construits et leurs positions, population recrutée et affectation de chaque habitant.
- Temps écoulé, prochain repas, suspicion, faim et cycle de renouvellement des miettes.
- Vitesse de simulation, position et orientation de la caméra, zoom, habitant sélectionné, affichage des trajets et coupe du refuge.

La réserve orientale découverte reste visible et affectable après reprise. Le chargement reconstruit les bâtiments sans déduire leur coût du stock enregistré ni recruter les habitants une seconde fois. Les tests vérifient aussi la conservation du bois après une nouvelle livraison depuis la réserve.

Les caisses en transit, files, réservations et animations ne sont pas sérialisées : la demande attend leur résolution. Le point de reprise est un état stable du refuge. Les compteurs internes de diagnostic, tels que le nombre de traversées effectuées par un contrôleur, ne sont pas des statistiques persistantes.

## Fichiers et reprise après erreur

Le format est un JSON versionné, identifié par `SousLePlancher/checkpoint`, version 1. Le fichier est `user://saves/colony_v1.json`, dans les données locales Godot de « Sous le plancher », et sa copie précédente porte le suffixe `.bak`. Ces fichiers restent hors du dépôt Git.

L’écriture prépare un fichier temporaire dans le même dossier, le ferme et le relit pour validation. Si un point précédent est valide, il est conservé en copie de secours avant remplacement du fichier principal. Une erreur d’écriture ou de remplacement est signalée ; le point principal précédent n’est pas supprimé au préalable. Un fichier principal corrompu ne remplace pas une copie de secours saine.

À la lecture, la taille du fichier, son format, sa version, les nombres, les ressources, la population, les affectations, l’horloge et la caméra sont contrôlés. Aucun objet ou script n’est désérialisé depuis le fichier. Une scène candidate est ensuite reconstruite pour vérifier aussi la validité des emplacements des bâtiments. La partie active n’est remplacée qu’après réussite complète.

Si le fichier principal est illisible ou ne satisfait pas la validation des données, une copie de secours valide peut être utilisée ; le message indique alors explicitement « Copie de secours chargée ». Une incohérence géométrique détectée pendant la reconstruction fait refuser le chargement et conserve la partie active.

La méthode de remplacement utilise l’API de fichiers Godot, avec contrôle de chaque retour d’erreur. Référence : [DirAccess, Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_diraccess.html). Ce mécanisme ne remplace pas une sauvegarde externe du dossier utilisateur contre une panne matérielle.

## Intégration et vérifications

`scripts/colony_save.gd` gère le format, sa validation et les fichiers. `game.gd` gère la demande, l’attente, la reconstruction et le remplacement de scène ; `atelier_ui.gd` expose les commandes et la confirmation de chargement. Les textures et polices validées sont réutilisées, sans nouvel asset graphique.

Un habitant recruté alors que la colonie est rappelée rejoint maintenant immédiatement le retour au refuge. Cela évite qu’un recrutement pendant une sauvegarde en attente laisse une personne immobile dehors et empêche l’écriture.

`tests/checkpoint.gd` vérifie : demande pendant un transport chargé sur la passerelle, attente de l’état stable, conservation des ressources, relecture du fichier, reconstruction exacte des champs persistants, bâtiments et population sans double coût, réserve découverte, reprise d’une livraison après chargement, confirmation annulable, échec d’écriture avec conservation du fichier principal, rotation de la copie de secours, fichier interrompu, version inconnue, stock ou affectation invalides, bâtiments superposés, annulations de demande et recrutement pendant le rappel.

Les huit suites existantes restent vérifiées : navigation, livraisons, économie, clics d’affectation, interface, échelles, portes et exploration. Les tests de sauvegarde utilisent des dossiers isolés sous `user://tests/`, sans toucher au fichier normal du joueur.

`tests/checkpoint_visual.gd` produit les captures d’attente, sauvegarde, confirmation, reprise et accueil dans `artifacts/checkpoint/`. Il utilise lui aussi un fichier de test isolé et augmente uniquement ses réserves de contrôle.

## Limites et prochaine étape

Ce premier système propose un emplacement manuel et sa copie précédente. Il n’inclut pas de sauvegarde automatique à la fermeture, de liste de parties nommées, de synchronisation cloud, ni de restauration au milieu d’une animation. Le format concerne la carte actuelle ; une évolution incompatible devra faire évoluer sa version ou fournir une migration.

Une partie déjà terminée ne crée pas un nouveau point de sauvegarde. Si la colonie est découverte, meurt de faim ou atteint la victoire avant la fin d’une demande, celle-ci est annulée et le fichier précédent reste disponible ; l’écran de fin le signale.

Après revue : reprendre la généralisation des connexions entre zones, puis ajouter une découverte ayant un effet sur la progression (matériau, outil ou savoir-faire). La base persistante est désormais disponible pour conserver ces prochaines extensions.
