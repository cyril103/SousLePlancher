# Lot 53 — Un splashscreen différent au lancement

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Écran de lancement

Le démarrage normal utilise `scenes/startup.tscn`, puis ouvre l’accueil existant de `scenes/main.tscn`. Une des cinq illustrations retenues est tirée au hasard. L’image précédente est exclue du tirage suivant, même après fermeture du jeu, grâce à `user://startup.cfg`. Le premier lancement peut choisir n’importe laquelle. Un historique absent ou invalide n’empêche pas le lancement.

Les images gardent leurs proportions et toute leur composition ; des bandes sombres occupent l’espace restant selon le format de l’écran. Un fondu de 0,35 s présente l’image. Elle reste affichée au moins trois secondes avant la transition automatique, sous réserve que la scène suivante soit chargée. Clic gauche, Entrée, Espace ou Échap demandent de passer dès que le chargement est terminé. Le fondu de sortie dure 0,3 s. Le logo de démarrage standard du moteur est masqué.

L’image est présentée avant le chargement de la scène sur le thread principal. Le chargement asynchrone de ce graphe de scripts produisait des instances RefCounted non libérées à la fermeture ; le chargement différé sur le thread principal supprime cet avertissement. L’image reste fixe pendant cette préparation. Un échec affiche un message permettant de réessayer.

L’historique est indépendant des sauvegardes de colonie (v28 inchangée) et utilise un générateur aléatoire distinct. Si l’écriture de ce fichier utilisateur échoue, le jeu reste accessible, mais le dernier choix ne peut pas être garanti au lancement suivant. Recommencer une partie dans la même session ne rejoue pas le splashscreen.

## Visuels et provenance

Les cinq PNG originaux, générés avec l’outil intégré puis choisis par le joueur, sont documentés dans [la galerie](splashscreens-v01/index.html) avec les prompts dans son README. Le jeu utilise les copies de `assets/ui/splash/` (1672 × 941 pixels chacune). Aucune nouvelle génération ni retouche n’a été nécessaire pour l’intégration. Le dossier des propositions est exclu de l’import Godot avec `.gdignore`.

## Vérifications

- `tests/startup.gd` : cinq choix atteignables, exclusion du précédent, chargement des cinq textures, historique lu à deux lancements, chargement de la vraie scène, passage avec Espace et accueil accessible.
- `tests/startup_visual.gd` : affichage plein écran des propositions 1 et 5 ; captures `artifacts/startup_1.png` et `artifacts/startup_5.png` contrôlées.
- Lancement normal via la scène configurée, puis fermeture automatique : aucun avertissement de ressource après correction du chargement.

Pour essayer : lancer le projet normalement (F6 sur `startup.tscn` ou F5 dans l’éditeur), fermer et relancer pour constater le changement. Les tests ou lancements explicites de `main.tscn` gardent leur accès direct au jeu.
