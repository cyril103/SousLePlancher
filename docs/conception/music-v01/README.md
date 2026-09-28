# Une lumière sous les lames — thème d'accueil

Composition originale du 28 septembre 2026 pour **Sous le plancher**.
Direction : intimité du refuge, fragilité des habitants, émerveillement devant
une maison immense. Ambition cinématique avec un petit ensemble acoustique.
Il s'agit d'un arrangement rendu par échantillonnage, pas d'une séance avec
orchestre ni d'un master AAA validé par une écoute en studio.

## Écouter et reprendre la production

- `une-lumiere-sous-les-lames.mp3` : version d'écoute de **1 min 28**, 320 kbit/s,
  avec une conclusion sur ré mineur.
- `../../../assets/audio/music/une-lumiere-sous-les-lames.ogg` : boucle de jeu
  de **1 min 20**, stéréo 48 kHz, sans silence ajouté au raccord.
- `une-lumiere-sous-les-lames.mid` : huit pistes éditables, tempo et repères.
- `score.json` : chaque note, durée, nuance et panoramique du rendu.
- `sample-manifest.json` : versions immuables, URL et SHA-256 des 31 échantillons.
- `audio-analysis.json` : mesures du fichier Ogg décodé.
- `licenses/` : licences des deux banques utilisées ; crédits dans
  `../../../assets/audio/music/CREDITS.md`.

Les masters WAV **48 kHz / 24 bits** et les huit pistes séparées synchronisées
sont dans `artifacts/music-production/` (hors Git). Les stems sont avant le gain
du master : pour retrouver le niveau de la boucle, appliquer à leur somme le
gain `stem_master_gain_db` indiqué dans les mesures. Leur traitement inclut la
réverbération et les queues de notes ramenées au début du cycle.

## Écriture

32 mesures en **6/8**, noire à **72**, autour de ré mineur. Le balancement lent
évoque la vie du refuge. Le motif commence par une quarte ascendante, puis des
secondes et une retombée : il passe du piano aux reflets du glockenspiel et à
la flûte. Les accords enrichis gardent de l'air, les basses sont séparées des
voix médianes. Pas de grosse percussion ni de voix chantée.

| Temps | Partie | Orchestration |
| --- | --- | --- |
| 0–10 s | La lueur | Piano et motif esquissé au glockenspiel |
| 10–30 s | Le refuge | Thème au piano, entrée progressive des cordes |
| 30–40 s | La réponse | Phrase descendante, apparition de la harpe |
| 40–60 s | Au-delà des lames | Flûte, cordes plus présentes, pulsation bois discrète |
| 60–80 s | Le retour | Reprise allégée, retrait des pupitres, préparation du raccord |
| 80–88 s | Conclusion d'écoute | Résolution et résonance, seulement dans le MP3/WAV d'écoute |

Le rendu conserve les nuances et des décalages d'attaque déterministes. Une
réverbération de chambre commune relie les instruments. La boucle reporte les
queues instrumentales et la réverbération de fin sur le début, sans ajouter ou
retirer de mesure. La version d'écoute ajoute une cadence indépendante.

## Reproduire

Depuis la racine, dans PowerShell avec Python 3.13 :

```powershell
New-Item -ItemType Directory -Force artifacts | Out-Null
New-Item -ItemType File -Force artifacts/.gdignore | Out-Null
python -m venv artifacts/music-env
& artifacts/music-env/Scripts/python.exe -m pip install -r tools/requirements-music.txt
& artifacts/music-env/Scripts/python.exe tools/compose_menu_theme.py
```

Le premier rendu télécharge seulement les échantillons nécessaires. Ils restent
dans `artifacts/music-samples/`, puis les rendus suivants utilisent ce cache.
Les empreintes sont vérifiées. La partition et le MIDI suffisent pour reprendre
l'arrangement dans un séquenceur avec d'autres instruments.

## Dans le jeu

Le lecteur persiste entre le splashscreen et l'accueil. Entrée en fondu de
1,6 seconde, volume à −8 dB par rapport au fichier, puis boucle. Fonder ou
reprendre la colonie déclenche un fondu de 1,5 seconde et arrête la musique.
Le bouton de l'accueil mémorise l'activation dans `user://music.cfg`, séparément
des sauvegardes de colonie. Le morceau accompagne aussi l'accueil lancé
directement depuis `main.tscn`.

Vérifications : absence d'écrêtage du fichier décodé, longueur exacte de la
boucle, contrôle du raccord et compatibilité mono par corrélation ; test Godot
de continuité splash/accueil, activation, extinction, interruption de fondu et
passage effectif de la fin au début. Les mesures techniques ne remplacent pas
la validation artistique à l'écoute par le joueur.
