# La maison au-dessus, la colonie tout près

Palette et intégration du 28 septembre 2026. Direction : entendre la masse des
humains à travers le bois, puis le détail des habitants, des outils et des
matières sous le plancher. Sources enregistrées, traitement original et quelques
éléments synthétisés ; tous les détails figurent dans les
[crédits](../../../assets/audio/ambience/CREDITS.md).

## Écoute

`sous-le-plancher-ambiance.mp3` est un **montage de présentation de 45 secondes**,
pas une capture de partie :

| Temps | Sons présentés |
| --- | --- |
| 0–4 s | Fond d'air, feu distant et grincement |
| 4–11 s | Pas des habitants et porte du refuge |
| 11–21 s | Marteau, sciage, caisse, fibres et eau |
| 23–33 s | Pas lourds se déplaçant au-dessus et tension du bois |
| 35–45 s | Retour aux bruits légers de la colonie |

La présentation permet de comparer les timbres. En jeu, la caméra, la distance,
les filtres et les événements réels déterminent le résultat ; ce montage ne
remplace pas une validation artistique à l'écoute d'une partie.

## Palette

| Famille | Variantes | Déclenchement en jeu |
| --- | ---: | --- |
| Pas des humains | 5 | Pendant le passage des humains, secondes 68–88 du cycle |
| Grincements du plancher | 5 | Liés aux pas et rares craquements entre les passages |
| Pas des habitants | 5 | Déplacement réel, avec seuil de distance et limite de cadence |
| Marteau | 5 | Contact à 0,336 s du cycle d'animation de travail |
| Caisse | 5 | Prise ou dépôt effectif d'une charge |
| Fibres | 5 | Récolte, récolte de l'alcôve et entretien des mèches |
| Miettes | 5 | Récolte de nourriture, y compris dans la cuisine |
| Frottement / sciage | 3 | Récolte du bois |
| Eau | 3 | Récolte d'eau |
| Porte | 2 | Début d'ouverture ou de fermeture du refuge |
| Feu | 1 boucle de 23 s | Trois flammes visibles proches au maximum |
| Fond de pièce | 1 boucle de 40 s | Partie ouverte, atténué pendant la pause |

Les 45 WAV mono sont conservés en 48 kHz / 16 bits pour les sources spatiales.
Les prises téléchargées restent en cache dans `artifacts/foley-source/`. Les
préécoutes Freesound sont compressées à la source ; les exporter en WAV ne
reconstitue pas une prise sans perte. Le script vérifie les empreintes et produit
le manifeste avec durée, crête et provenance de chaque fichier.

## Comportement du mixage

Un auditeur suit le point regardé par la caméra et son orientation. Les sons
lointains s'atténuent et ceux hors portée n'occupent aucune voix. Les habitants
à l'intérieur du refuge fermé passent dans un filtre plus sourd ; ouvrir la vue
intérieure retire ce traitement. Il s'agit d'une règle acoustique du refuge,
pas d'une simulation par rayons de toutes les cloisons.

Les sons du dessus passent par leur propre filtre et réverbération. Pendant le
passage des humains, les bruitages proches baissent de 3 dB. Dix voix sont
réservées à la colonie et quatre au dessus, avec limites par famille ; les sons
supplémentaires sont omis plutôt qu'empilés. Les variantes évitent la répétition
immédiate et reçoivent de petites variations de hauteur et de niveau.

La densité et la hauteur restent indépendantes de la vitesse x1/x2/x3. Aucune
action sonore n'est rattrapée après une pause, un déplacement instantané ou une
reprise de sauvegarde. La pause suspend les bruitages et les flammes ; seul le
fond d'air atténué continue. L'accueil utilise son thème musical et le retour à
l'accueil arrête les sons du monde. La fermeture laisse 0,22 s au fondu et à la
libération des lectures audio.

Le bouton **Ambiances** apparaît à l'accueil et dans **Aide [? / F1]**, où se trouve
le volume. Préférences dans `user://ambience.cfg`, séparées de la musique et des
sauvegardes de colonie.

Après écoute du joueur sur haut-parleurs, le mix a été relevé : bruitages de
3 à 8 dB, atténuation moins forte à distance moyenne, présence renforcée dans
les médiums et filtre du dessus ouvert à 2,2 kHz. Le limiteur reste après
l'égalisation. La préférence de volume enregistrée est conservée. Sur une même
séquence de six sons capturée à cinq mètres dans le moteur, le niveau moyen
augmente de 12,5 dB, avec une crête à −9,7 dBFS ; ces chiffres décrivent cette
séquence de contrôle et non le maximum de toutes les parties possibles.
Le montage MP3 présente les timbres ; il ne reproduit pas ce mixage spatial.

## Essayer

```powershell
& 'D:/godot/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe' --path . -- --demo-soundscape
```

Cette démo démarre deux récolteurs et une livraison de matériaux pour un lit,
puis fait arriver les humains après environ 18 secondes. Caméra : flèches/WASD,
rotation au bouton central, zoom à la molette. Espace : pause. Le chemin de
sauvegarde de la démo est indépendant de la partie normale.

## Reproduire et vérifier

Utiliser l'environnement Python du thème musical, avec
`tools/requirements-music.txt`, puis :

```powershell
& artifacts/music-env/Scripts/python.exe tools/create_soundscape.py
```

Le script génère les 45 sons, le manifeste et l'aperçu, puis contrôle les crêtes,
les données finies et le raccord des deux boucles. Importer ensuite le projet
dans Godot. Tests : `tests/world_soundscape.gd` (observation sans modification de
la sauvegarde ni du RNG global, variantes, spatialisation, plafond de voix,
pause, cycle humain, préférences et vraie simulation de livraison/construction),
`tests/world_soundscape_visual.gd` (interfaces et fermeture propre). Régressions
musique d'accueil, démarrage, construction et reprise de sauvegarde également
exécutées. `audio-analysis.json` conserve les mesures de l'aperçu MP3 décodé.
