# Lot 55 — Ambiances et bruitages du monde

Livraison du 28 septembre 2026 ; validée par le joueur après renforcement du mix, commit et push autorisés.

**45 sons, 12 familles** : pas géants et habitants, grincements, marteau, caisses,
fibres, miettes, sciage, eau, porte, flammes et fond de pièce. Banque CC0 traitée
et éléments procéduraux, avec provenance et génération reproductible.
[Écoute, contenu et sources](soundscape-v01/README.md).

## Intégration

L'observateur sonore lit les mouvements, les charges et les animations après la
simulation, sans modifier les tâches, stocks, horloges ou priorités. Son RNG
est indépendant. Les coups de marteau suivent le contact de l'animation ; les
récoltes distantes utilisant cette même animation gardent leur propre timbre.

Les humains se font entendre pendant leur fenêtre 68–88 s. Filtrage au travers
du plancher, spatialisation depuis le point regardé, atténuation des bruits de
colonie pendant le danger, sons plus sourds à l'intérieur du refuge fermé. Le
mixage limite le nombre de voix et évite la répétition immédiate des variantes.

Les sons suivent les actions et la distance, avec une densité bornée en vitesse
accélérée. Pause, accueil, partie terminée et préférence de coupure sont gérés.
Un court fondu à la fermeture permet au moteur de libérer ses lectures WAV.

Bouton **Ambiances** à l'accueil et dans l'aide ; volume dans **Aide / F1**.
Préférences `user://ambience.cfg`, indépendantes de la musique. Sauvegarde de
colonie v28 inchangée. Démo `-- --demo-soundscape` avec récoltes, chantier et
passage humain après environ 18 secondes ; sauvegarde de démo séparée.

## Vérifications

- `world_soundscape.gd` : **0 échec**, dont observation sans mutation, RNG isolé,
  variantes, voix réservées, distance, pause, cadence x3, retour d'horloge et
  simulation effective de livraison/récolte/construction.
- `world_soundscape_visual.gd` : **SOUNDSCAPE_VISUAL_OK**, accueil et aide vérifiés,
  fermeture sans avertissement de ressources audio restantes.
- `menu_music.gd` : **0 échec**, continuité splash/accueil et bouclage conservés.
- `construction.gd` : **0 échec**, livraisons et construction conservées.
- `startup.gd` et `live_checkpoint.gd` : **0 échec**, démarrage et reprise des
  positions, charges, réservations et tâches conservés.
- Génération audio : 45 fichiers décodables, sans écrêtage, raccords des deux
  boucles contrôlés. Aperçu MP3 de 45 s et sources conservés.

Captures locales : `artifacts/soundscape_menu.png` et `artifacts/soundscape_help.png`.

Retour d'écoute : volume insuffisant sans casque. Mix relevé, atténuation de
distance réduite, médiums plus présents et grincements moins filtrés. Comparaison
audio réelle du moteur, six sons identiques à cinq mètres : **+12,5 dB** de niveau
moyen, crête **−9,7 dBFS** après correction, sans écrêtage sur cette séquence.
`world_soundscape.gd` repassé : **0 échec**. Captures et mesures dans
`artifacts/mix_before.wav`, `artifacts/mix_after.wav` et
`artifacts/mix_speaker_comparison.json`.

L'aperçu est un montage des timbres, pas une capture de partie ni une certification
de qualité AAA. L'équilibre artistique se valide à l'écoute du jeu.
