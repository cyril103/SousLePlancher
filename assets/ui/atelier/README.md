# Interface Atelier miniature

Interface implémentée d’après la proposition 2, validée le 24 septembre 2026.

## Assets

- `materials.png` : atlas de matières généré avec ImageGen intégré (bois, papier, toile, laiton).
- `icons.png` : douze icônes illustrées, fond transparent, atlas 4 × 3.
- `portrait.png` : portrait illustré commun au modèle d’habitant actuel. Les identités graphiques individuelles restent à créer avec les futurs personnages.
- Les PNG sources sont conservés sans retouche. Godot prélève les régions via AtlasTexture et dessine les cadres, vis et états des boutons à la résolution de l’écran.

## Typographie

Lora pour les titres, les ressources et la barre principale ; Source Sans 3 (graisse 500) pour les informations et les actions. Fichiers distribués dans `assets/fonts/`, avec les deux licences SIL Open Font License. Sources officielles : [Lora](https://github.com/google/fonts/tree/main/ofl/lora), [Source Sans 3](https://github.com/google/fonts/tree/main/ofl/sourcesans3). Le réglage des axes suit [FontVariation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html).

## Fonctionnement

Six entrées en bas : Construire [B], Habitants [C], Travaux [T], Stocks [I], Objectifs [O], Au refuge [H]. Aide [F1], plein écran [F11], pause [Espace], vitesses ×1/×2/×3 dans le bandeau supérieur. Un seul panneau contextuel est ouvert à la fois ; Échap le ferme. Les panneaux ne mettent pas la simulation en pause.

La fiche affiche l’état réel, la tâche et la charge du résident sélectionné. Un clic sur un habitant dans le monde ou dans la liste le sélectionne. Affecter depuis sa fiche cible précisément cet habitant disponible. Rappeler libère son affectation et rapporte sa charge au dépôt avant le retour. La commande Au refuge conserve les affectations de la colonie. Les boutons de construction reflètent les matériaux disponibles ; les réservations et les charges en transit sont distinctes des stocks du dépôt.

L’accueil et l’écran de fin disposent d’un fond bloquant les clics vers le terrain. L’interface est séparée du jeu dans `scripts/atelier_ui.gd` et les cadres sont dessinés par `scripts/atelier_panel.gd`.

## Vérification

- `tests/live_assignments.gd` : clics souris maintenus pendant plusieurs rafraîchissements, affectation générale et ciblée, déplacement, libération, rappel et reprise répétée des tâches. Les états des boutons sont calculés avant d’être appliqués pour éviter l’annulation d’un clic en cours.
- `tests/atelier_ui.gd` : navigation des panneaux, affectation ciblée, rappel sans perte de charge, pause/vitesse, stocks, nouveaux arrivants, placement des panneaux et écrans de début/fin.
- `tests/smoke.gd` et `tests/delivery.gd` : boucle de jeu et livraisons sans régression.
- `tests/atelier_visual.gd` : captures de l’interface réelle en 1920×1080, 1280×800, 1024×768 et 1920×800 dans `artifacts/atelier/`.

## Prompts des éléments générés

Outil : ImageGen intégré. La version du modèle n’est pas exposée par l’outil.

### materials

```text
Use case: stylized-concept. Asset: production-ready 2D material texture atlas for the approved miniature workshop game UI. Output square 1024x1024. EXACT layout four equally sized square quadrants, edge to edge no spacing, no borders. Top left: very dark chocolate walnut fine subtle horizontal grain, low contrast to place cream text on, flat diffuse uniform illumination. Top right: warm ivory aged rag paper, fine fibers, almost uniform center, no stains. Bottom left: natural coarse brown linen fabric evenly woven small thread pattern. Bottom right: mellow antique brass fine brushed metal warm gold, not orange, subtly mottled. These are seamless-looking flat surface swatches viewed straight on, no perspective, no objects, no seams, no frames, no shadows, no lettering, no icons, no text, no watermark. Each quadrant is a single flat material entirely filling its 512x512 area. High quality tactile realistic fine material textures, subtle enough for readable game HUD. Reference approved style dark wood and linen, brass edging, ivory paper.
```

### icons

```text
Use case: stylized-concept. Asset type: transparent PNG icon atlas for a professional Borrowers miniature colony game interface, workshop wood/brass/ivory art direction. Square canvas exactly regular 4 columns by 3 rows equal cells; 12 icons only, each centered in its own cell, all same apparent size, generous transparent margin at least 20% within each cell. Transparent background genuine alpha, no grid, no labels, no frames or drop-shadow outside icons. Cohesive meticulously rendered sculpted miniature carved ivory and antique gold icons, front-facing slight embossed relief, bold silhouettes readable at 40px. Row1 left to right: builder's hammer; group of three little human bust silhouettes; crossed hammer and spanner; wooden supply crate. Row2 left to right: rolled parchment checklist; little crafted wooden refuge house with two small leaves; pile of bread crumbs; two short wooden planks. Row3 left to right: coiled twine; hourglass; question mark; small cog wheel. NO text, no decorative scene. Warm cream and brass palette, subtle highlights and dark brown internal shadows. Exactly 12 separated icons, never touch cell boundaries.
```

### portrait

```text
Use case: illustration-story. Asset type: square resident portrait for game HUD. Input reference: approved screenshot interface, use only the small resident portrait at lower left as style reference, not the scene. Generate ONE full square shoulder-up portrait of a tiny Borrowers-like adult male worker with short tousled brown hair, cream linen shirt, brown leather suspenders and sage green work clothes, kind capable expression, turned very slightly right. Painterly high-end strategy game character illustration, detailed natural fabric, warm torchlit tones, understated earthy ivory-beige background, no border, no text, no icons. Entire image is the portrait, no UI scene or collage. Match the human rather than dwarf/fantasy knight identity. Composition face large legible at 90px.
```

