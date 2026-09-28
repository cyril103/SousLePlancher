# Lot 54 — Le thème musical de l'accueil

Livraison du 28 septembre 2026 ; validée par le joueur, commit et push autorisés.

**Une lumière sous les lames** est une composition originale de 32 mesures en
6/8, noire à 72. Piano doux, glockenspiel, harpe, flûte, violoncelles, altos et
violons ; pulsation bois discrète dans la partie centrale. Le rendu repose sur
des instruments échantillonnés, avec partition, MIDI, provenance et production
reproductible. [Écoute et dossier musical](music-v01/README.md).

## Intégration

- Boucle Ogg stéréo de 80 secondes, queues et réverbération raccordées.
- Version d'écoute de 88 secondes avec une conclusion, MP3 320 kbit/s.
- Un lecteur global survit au passage du splashscreen vers l'accueil : la
  musique ne repart pas du début au changement de scène.
- Fondu d'entrée de 1,6 seconde ; fondu de sortie de 1,5 seconde quand l'accueil
  disparaît pour fonder ou reprendre une colonie. Une réouverture de l'accueil
  réactive la musique si le joueur ne l'a pas coupée.
- Bouton « Musique : activée / coupée » à l'accueil. Préférence indépendante
  dans `user://music.cfg`. Le volume du lecteur est à −8 dB.
- Sauvegarde de colonie v28 inchangée ; aucune musique de partie ajoutée.

## Vérifications

`tests/menu_music.gd` vérifie l'import Ogg, la durée, la continuité réelle
splash/accueil, la préférence d'activation sur un fichier de test, les fondus,
leur interruption et le rebouclage effectif en plaçant la lecture près de la
fin. Exécution graphique avec pilote audio Dummy : **0 échec**. Capture
`artifacts/menu_music.png`, bouton visible et panneau contenu dans l'écran.

Régression `tests/startup.gd` : **0 échec**. Import Godot validé. Mesures du
fichier Ogg décodé : **−15,9 LUFS**, crête réelle **−1,9 dBFS**, plage de niveau
**6 LU**. Masters WAV 48 kHz / 24 bits et huit stems dans
`artifacts/music-production/`. L'absence d'écrêtage et le raccord sont mesurés ;
la qualité artistique reste à valider à l'écoute par le joueur.
