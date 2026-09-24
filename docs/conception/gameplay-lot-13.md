# Lot 13 — Besoins autonomes : sommeil, faim et soif

État : validé par le joueur (« ok validé, commit et push »), publication autorisée. Complète le lot 12 à sa demande : les habitants doivent décider seuls de dormir, manger et boire, dans l’esprit de RimWorld et Oxygen Not Included.

## Comportement jouable

Chaque habitant possède trois jauges : **énergie**, **satiété** et **hydratation**, visibles dans sa fiche. Leur évolution utilise le temps de simulation : pause et vitesses ×1/×2/×3 s’appliquent aussi aux besoins. Les jauges descendent individuellement, sans prélèvement collectif de nourriture à intervalles fixes.

- Énergie basse : l’habitant rejoint son lit, ou un lit libre accessible si son propre couchage n’est pas utilisable. Sans lit disponible, il rentre dormir allongé au sol dans le refuge. Son propriétaire et son affectation de travail restent conservés.
- Satiété ou hydratation basse : il termine le dépôt d’une charge déjà prélevée, puis revient au refuge pour prendre une portion ou une boisson. Une animation accompagne la consommation réelle d’une unité du stock.
- Réserve vide : il cherche un gisement connu et accessible du type nécessaire, collecte et rapporte une charge, puis satisfait son besoin. Cette collecte d’urgence est temporaire : elle ne remplace pas l’affectation choisie par le joueur.
- Plusieurs besoins simultanés : la plus basse des jauges alimentaires passe d’abord. Un besoin impossible à satisfaire n’empêche pas de consommer une autre ressource disponible. Les besoins alimentaires modérés attendent la fin du sommeil ; sous le seuil critique, ils réveillent le dormeur.
- Après le repas ou la boisson, l’habitant satisfait ses autres besoins urgents, se repose s’il reste fatigué, puis reprend ses travaux.

Le rappel **H** reste prioritaire : les habitants ne ressortent pas récolter pendant une alerte. Ils peuvent manger et boire dans le refuge si les réserves le permettent. Une consommation engagée se termine sans perdre ni dupliquer la ration. Les franchissements d’échelle, de passerelle et de porte déjà commencés se terminent avant un changement de tâche. La sauvegarde attend la fin des actions en cours.

**Se reposer** reste un ordre facultatif de repos anticipé ; le fonctionnement normal n’en dépend pas.

## Nourriture et eau

La nourriture provient des gisements de miettes existants. Un nouveau point de collecte d’**eau de condensation** est placé au sol, à l’est de la colonie. Son asset Blender représente des dés à coudre récupérant l’eau sur un support en bois. Il peut recevoir une affectation normale depuis Habitants ou être utilisé par la collecte autonome d’urgence.

La nouvelle partie commence avec 24 miettes et 16 unités d’eau. Le point d’eau contient 120 unités et reçoit 30 unités par cycle de 100 secondes. Comme pour les miettes, c’est une abstraction provisoire de ressource renouvelable : pas encore de simulation de liquide, de contamination ou de réseau de canalisations. Les charges utilisent le système de livraison existant.

| Règle | Valeur provisoire à vitesse ×1 |
|---|---|
| Satiété initiale / hydratation initiale | 100 / 100 |
| Satiété éveillée | −0,24 par seconde |
| Hydratation éveillée | −0,32 par seconde |
| Consommation pendant le sommeil | 65 % des vitesses éveillées |
| Déclenchement d’un repas / d’une boisson | jauge ≤ 35 |
| Réveil pour faim / soif critique | jauge ≤ 15 |
| Repas | 1 miette, 4 secondes, +55 de satiété avant dépense naturelle |
| Boisson | 1 eau, 3 secondes, +65 d’hydratation avant dépense naturelle |
| Besoin très bas | sous 15 en énergie, satiété ou hydratation : déplacement normal à 65 % |

Les règles de sommeil du lot 12 restent valables : seuil 25, réveil à 95, récupération plus rapide dans un lit et avec intimité. Le repos au sol est maintenant allongé, avec les jambes repliées. Les cloisons restent un ensemble avec le lit, sans calcul général de pièces.

L’ancienne défaite collective « dépôt vide pendant 35 secondes » est supprimée. Une réserve vide n’est plus confondue avec la faim de chaque individu. Cette étape implémente les besoins, leurs priorités et le ralentissement lié aux carences ; elle n’ajoute **pas encore** les maladies, blessures, décès par carence, effondrements ou secours médicaux. Les jauges restent bornées à zéro en l’absence durable de ressources. La découverte par les humains termine toujours la partie.

## Interface et démonstration

Le bandeau supérieur affiche maintenant l’eau. La fiche d’habitant montre trois barres chiffrées et son activité réelle : manger, boire, chercher une ressource, dormir dans son lit ou au sol. Le panneau Stocks explique la consommation individuelle. Les alertes signalent les besoins alimentaires critiques sans masquer l’alerte humaine imminente.

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64.exe' --path . -- --demo-needs
```

La démo commence en pause, avec un habitant au lit, un au sol, un qui mange et un qui boit. **Espace** reprend le temps ; **C** permet de sélectionner chaque habitant. Elle est indépendante de la sauvegarde existante tant qu’on ne demande pas explicitement F5.

## Architecture et compatibilité

`colony_needs.gd` arbitre faim et soif, consommation et collecte autonome. `colony_sleep.gd` conserve les couchages et le sommeil. `WorkerDelivery` reste l’unique responsable des trajets et des transactions de livraison ; une source temporaire satisfait l’urgence sans modifier l’affectation utilisateur.

Le format de sauvegarde passe à la version 3, au chemin historique `user://saves/colony_v1.json`. Il conserve les jauges individuelles, les quantités d’eau, le gisement, son emplacement et les affectations à l’eau. Les formats 1 et 2 restent lisibles : les nouvelles jauges sont initialisées à 100 et une réserve initiale de 16 unités d’eau est ajoutée. Si un ancien bâtiment occupe le nouveau point d’eau, le chargement cherche un emplacement libre et accessible pour la source, puis conserve cette position dans les sauvegardes suivantes. Il ne déplace pas les bâtiments du joueur.

Les valeurs hors limites, sources hors carte et affectations incohérentes sont rejetées avant remplacement de la scène active. Une géométrie incompatible fait également refuser le chargement sans remplacer la partie en cours.

## Assets et validation

- `tools/create_needs_assets.py` produit `needs_13/condensation` et `needs_13/ration` avec Blender ; sources éditables dans `art_source/needs_13`.
- Le résident reçoit les clips Blender `eat` et `drink`, un morceau de nourriture et un dé à coudre tenu en main. Le clip de repos au sol du lot 12 devient une pose allongée compacte.
- Les accessoires sont synchronisés aux os lors de l’échantillonnage manuel, y compris en pause.
- `tests/needs.gd` vérifie la consommation individuelle, la priorité entre besoins, la collecte automatique des deux ressources, le maintien des affectations, le sommeil spontané, le réveil critique au sol et au lit, les rappels, la pause, la sauvegarde et la migration d’un ancien bâtiment situé sur le point d’eau.
- `tests/needs_visual.gd` capture la scène, les repas et le repos au sol, ainsi que le collecteur d’eau et l’interface sous `artifacts/needs/`.
- Les tests de fumée sont adaptés au retrait du compteur de famine collectif. Les tests du lot 12 continuent de vérifier lits, cloisons, construction et sommeil.

Les horaires, préférences alimentaires, cuisine, qualité de l’eau, moral, loisirs, hygiène, température, santé et médecine restent des systèmes distincts à développer suivant le cahier des charges.
