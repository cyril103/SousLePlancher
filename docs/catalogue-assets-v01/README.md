# Catalogue visuel des assets — V01

Ouvrir **[index.html](index.html)** pour parcourir les 12 planches, filtrer les familles, chercher un asset et examiner les images en grand. Le catalogue fonctionne localement, sans connexion Internet ni bibliothèque externe. Dans la visionneuse : flèches pour changer de planche, Échap pour fermer, « Taille réelle » pour examiner les détails.

**Statut : propositions artistiques à commenter.** Ces références préparent la modélisation Blender. Elles ne remplacent pas les modèles du jeu et ne valident ni espèces nouvelles, ni métiers, ni recettes. Les fonctionnalités existantes et futures restent distinguées dans les légendes.

## Contenu

| Planche | Sujet | Références de l’inventaire |
| --- | --- | --- |
| 01 | Habitant : face, profil, dos, trois quarts, détails | CHR-01, CHR-03 |
| 02 | Bâtisseuse, porteur, soignante, éclaireur | CHR-01, CHR-02, PRP-09 |
| 03 | Fourmi : forme, mandibules, recherche et transport | FAU-01 |
| 04 | Araignée, appuis et toile irrégulière | FAU-02, VFX-04 |
| 05 | Cloporte et cafard, espèces optionnelles | FAU-05, FAU-06 |
| 06 | Souris et rat, silhouettes distinctes | FAU-03, FAU-04 |
| 07 | Marteau, racloir, levier, sac, caisse et bandages | PRP-09, PRP-11, PRP-12, CHR-02 |
| 08 | Torche, lanterne, support fixe, mèche et cire | PRP-14, PRP-15, BLD-17, VFX-01 |
| 09 | Lit en boîte d’allumettes et séparation d’intimité | BLD-16 ; détails textiles réutilisables pour BLD-09 |
| 10 | Atelier, casier et niveaux de remplissage | BLD-03, BLD-04, PRP-12 |
| 11 | Miettes, bois, fibres, eau, métal, résine, soie et repas | PRP-01 à PRP-07, BLD-08 |
| 12 | Plancher, cloison, échelle, passerelle et fissure étayée | ENV-01, ENV-02, ENV-08, BLD-05 à BLD-07 |

Les liens aux IDs désignent des usages ou familles, pas une couverture exhaustive de chaque lot du cahier des charges. Par exemple, la planche de ressources ne constitue pas une conception complète du collecteur d’eau.

## Direction retenue pour ces propositions

Des humains minuscules adultes, réalistes avec une légère stylisation, portant des vêtements réparés. Palette commune : lin ivoire, toile sauge, cuir brun, charbon, ocre et métal terni. Les objets humains récupérés doivent être identifiables : boîte d’allumettes, dé à coudre, épingle, mèche, tissu et petites lattes.

L’usure suit l’usage : bords frottés, coutures, zones de prise, poussière dans les creux. Les planches sont éclairées en studio pour montrer les volumes ; ce choix ne modifie pas l’ambiance sombre du jeu. La planche 01 reprend le personnage déjà validé comme point de départ. Les variantes de métiers explorent une finition plus réaliste et restent à harmoniser avec le personnage choisi.

## Passage à Blender

1. Retenir ou corriger les silhouettes, tenues et matériaux avec le joueur.
2. Établir les dimensions et les vues de travail cohérentes. Les vues générées sont indicatives, pas des plans orthographiques cotés ; les espèces et objets ne partagent pas forcément une échelle commune sur les planches.
3. Contrôler les détails avant de les reproduire : mains, raccords entre vues, nombre de membres, position des articulations et attaches. Fourmi/cafard : trois paires de pattes ; araignée : quatre ; cloporte : sept. Les petits appendices et chevauchements des images ne doivent pas devenir des os supplémentaires du rig.
4. Reprendre la convention du projet : une unité Blender = une unité Godot. Valider le gabarit contre l’habitant et les animations existantes ; ne pas déduire une dimension physique réelle de la seule image.
5. Séparer les éléments fonctionnels : corps, sac centré, outils, lanterne à la ceinture, charge portée, partitions, états de chantier. Contrôler les volumes pendant la marche, le portage et la montée.
6. Produire la topologie, les UV, les matériaux, les collisions et le rig nécessaires, puis tester en situation dans Godot. La fourrure et les microfibres des images inspirent les matières : ce ne sont pas des exigences de géométrie individuelle.

Budgets de départ du cahier des charges : habitant 8–15 k triangles, insecte 3–8 k, rongeur 15–30 k, petit objet 100–2 000, bâtiment 5–20 k. Ce sont des objectifs à mesurer et à ajuster, pas des garanties de performance issues des images.

## Provenance et fichiers

- `images/` : les douze PNG finaux, copiés sans modification ni recompression après génération.
- `prompts.json` : prompts exacts et descriptions des planches. Pour 01, le prompt est autonome et utilise le rendu de l’habitant existant comme référence. Pour 02–12, concaténer `common_prompt` et le champ `prompt` de la planche.
- `provenance.json` : correspondance entre fichiers générés et images livrées, dimensions et empreintes. La planche 10 a fait l’objet d’une seconde génération d’édition pour éclaircir le fond et rendre les légendes lisibles ; son prompt d’édition exact et sa source sont conservés dans `revision`.
- `references/habitant-prototype.png` : copie du rendu existant utilisé pour la planche 01.
- `../../tools/build_asset_catalogue.py` : depuis la racine du dépôt, exécuter `python tools/build_asset_catalogue.py` pour reconstruire la galerie à partir des métadonnées.

Génération par l’outil d’images intégré. Sa version de modèle n’est ni sélectionnable ni attestée par l’interface ; aucune attribution certaine à « image 2.5 » n’est faite. Les références de gameplay viennent de `docs/conception/cahier-des-charges.md`, `retours-et-decisions.md` et `inventaire-assets.csv`.

Les assets actuels restent en place. Le catalogue et les propositions attendent le retour du joueur avant leur adoption et leur publication.
