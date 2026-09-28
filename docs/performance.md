# Budget de rendu — 28 septembre 2026

Objectif : 60 images/s (16,67 ms), avec quatre habitants, quatre lits et la cuisine découverte. Le moteur reste Godot Compatibility.

## Changements

- LOD des maillages importés plus agressif (`lod_bias = 0.35`), y compris habitants, fourmi et mobilier. Godot choisit le maillage selon sa taille projetée ; la caméra orthographique exige cette approche plutôt qu'un simple seuil de distance.
- Échantillonnage des animations des habitants à 30 ou 15 Hz quand leur silhouette est petite ; 4 Hz hors champ. Déplacements et simulation continuent à chaque image. Les animations de contact, changements de clip et retours temporels restent immédiats. Gros plan : cadence complète. Les outils de revue, la pause et les restaurations explicites conservent les poses exactes.
- Fourmi : pas d'animation avant découverte, réduction des poses hors champ, pas de relance du même clip à chaque image.
- Interface périodique à 10 Hz ; les rafraîchissements explicites des commandes restent immédiats.
- Budget de quatre unités d'ombres dynamiques, choisies près du centre de la caméra toutes les 250 ms. Un projecteur coûte une unité, une lumière omnidirectionnelle deux (donc deux lanternes au maximum). Les autres lampes continuent d'éclairer, mais ne projettent plus d'ombres : compromis visible possible lors des mouvements de caméra et dans les zones secondaires.
- Faisceaux volumétriques : 8 échantillons au lieu de 24 et rejet des segments entièrement occultés. Compromis : intégration moins fine.

## Mesures

GTX 1650, OpenGL Compatibility, fenêtre 1920 × 1080, VSync désactivée, 240 images après 2 secondes de chauffe par vue. Scène synthétique reproductible dans `tests/performance.gd`, quatre lits terminés ajoutés à la démo fourmi. Ces mesures ne constituent pas une garantie pour toute sauvegarde, tout matériel ou toute résolution.

| Vue | Avant : FPS moyens | Après : FPS moyens | Après : p95 (ms) |
|---|---:|---:|---:|
| Colonie | 41,8 | 95,4 | 13,18 |
| Cuisine / fourmi | 56,8 | 89,7 | 13,41 |
| Gros plan | 27,9 | 75,4 | 16,17 |
| Récolte ×3 / fourmi active | non mesuré | 66,2 | 21,29 |

Le p95 de la récolte accélérée reste au-dessus du budget de 16,67 ms : les 60 FPS constants ne sont pas garantis dans ce cas. Le benchmark vérifie également le budget pondéré des ombres. Les captures sont enregistrées dans `artifacts/performance_*.png`. Les résultats varient entre passages ; ce tableau rapporte la dernière mesure du réglage final.

Tests : `tests/visual_budget.gd`, `tests/ant_animation.gd`, `tests/ant.gd`, `tests/sleep.gd`. Le test sommeil réussit mais signale à la fermeture quatre objets et deux ressources encore référencés ; ce nettoyage n'est pas corrigé ici.

## Références consultées

- [Xbox / Relic : mode Min Spec d'Age of Empires IV](https://news.xbox.com/en-us/2021/10/24/age-of-empires-min-spec-mode-more-opportunities-to-play/) : simplification de l'éclairage et des effets pour préserver la lisibilité et la cadence. Inspiration de la politique de qualité, sans prétendre reproduire Essence Engine.
- [Présentation GDC de Relic sur MAW](https://www.gdcvault.com/play/1027610/The-MAW-Safely-Multithreading-the) : parallélisation déterministe de la simulation. Pas de parallélisation ajoutée ici : les mesures orientent d'abord vers le rendu.
- [Documentation Godot : Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html) : niveaux géométriques générés à l'import et sélection selon la projection.
