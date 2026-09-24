# Lot 15 — Dépôts locaux, capacité et filtres

Étape 3 de la [roadmap](roadmap-production.md). **Validée par le joueur (« je valide ») ; commit et push autorisés.** Base publiée : `de71c70`, approvisionnement physique des lits.

## Démonstration

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64.exe' --path . -- --demo-depots
```

La scène commence en pause, avec un dépôt de proximité, son contenu visible et un chantier de lit. **Espace** reprend : les matériaux du dépôt alimentent le chantier, un habitant vient y manger puis boire, et un récolteur rapporte du bois. Le refuge ne reçoit pas magiquement ces stocks.

Cliquer sur le casier ou ouvrir **Stocks → Gérer les dépôts et leurs filtres**. Le sélecteur permet d'inspecter le refuge et chaque réserve locale. Les cases Miettes, Bois, Fibres et Eau déterminent les prochaines livraisons acceptées. **Voir ce dépôt** centre la caméra ; **Installer un dépôt** lance son placement. Le bouton existe aussi dans Construire.

**Limite explicite de cette étape :** installer le casier est instantané et gratuit, comme une désignation de réserve. Sa fabrication, le démontage et le déplacement avec manutention ne sont pas inclus. Les lits conservent leur fabrication avec approvisionnement physique. Aucun transfert automatique entre dépôts ni quotas minimum/maximum dans ce lot.

## Règles

| Élément | Comportement |
| --- | --- |
| Refuge | Premier dépôt local, 80 unités pour une nouvelle partie |
| Dépôt de proximité | 12 unités au total, toutes ressources confondues |
| Bandeau supérieur | Total réellement stocké dans tous les dépôts ; les charges portées sont indiquées séparément dans Stocks |
| Choix à la récolte | Dépôt accepté et accessible le plus proche du gisement par le chemin navigable |
| Place disponible | Réservée avant le prélèvement ; une dernière place permet une charge réduite |
| Dépôt plein | Aucun nouveau prélèvement sans place ; raison visible sur l'habitant |
| Changement de filtre | Bloque les nouvelles réservations de cette ressource ; conserve les stocks et honore les livraisons déjà engagées |
| Accès bloqué pendant transport | Recherche une autre destination accessible pouvant accepter toute la charge ; sinon attend avec une cause visible |
| Chantier | Choisit un dépôt contenant des matériaux disponibles, selon le trajet habitant → dépôt → chantier |
| Annulation du chantier | La place libérée au prélèvement reste réservée pour un éventuel retour ; elle est libérée définitivement après livraison au chantier |
| Faim et soif | Réservation d'une portion, déplacement et consommation dans un dépôt accessible ; les ressources ne sont pas consommées à distance |
| Rappel | Les charges sont déposées ; un repas engagé se termine une seule fois, puis l'habitant rentre au refuge |

Un dépôt possède sa propre file d'accès : récolteurs, constructeurs et habitants venus manger ou boire ne prennent pas le même poste simultanément. Les cases décochées n'interdisent pas de retirer les ressources déjà présentes. Le refuge sert toujours les habitants qui s'y trouvent ; pendant le rappel, ils ne ressortent pas chercher un repas dans un casier extérieur.

Les ateliers et anciens abris gardent leur paiement instantané historique, sur le stock disponible **du refuge**. Le total de la colonie ne permet pas de payer à distance ces anciens bâtiments. Leur conversion en véritables chantiers reste à réaliser.

## Sauvegarde

Format v5 : positions des bâtiments, contenu, capacité et filtres de chaque dépôt. Sauvegarde au refuge après règlement de toutes les charges, portions réservées et files d'accès. Les versions v1–v4 migrent leur ancien stock central vers le dépôt du refuge. Si ce stock dépassait 80 unités, la capacité héritée est augmentée pour le conserver intégralement.

Les stocks négatifs, les dépassements de capacité, les filtres inconnus ou dupliqués et les incohérences entre le stock du refuge et sa représentation sauvegardée sont refusés. Les quantités des chantiers et tas de récupération restent distinctes des stocks disponibles.

## Assets

- Source Blender : `art_source/depots_15/local_depot.blend`.
- Export Godot : `assets/models/depots_15/local_depot.glb`.
- Générateur : `tools/create_depot_assets.py`, exécuté avec Blender 2.93.
- Casier compartimenté en bois récupéré, cloisons en carton, attaches de fil, rebord bas et marquage de réserve. Matériaux texturés issus du jeu.
- Contenu composé avec les modèles Blender existants de bois, fibres, miettes et récipient. Sa présence et son volume reflètent le stock ; ce n'est pas une simulation d'empilement objet par objet.

## Vérifications

`tests/depots.gd` contrôle : concurrence de deux porteurs, limite de 12 unités à chaque pas, conservation des ressources, choix de proximité, saturation, filtre modifié avec charge en route, réorientation après blocage, chantier alimenté localement, nourriture et eau locales, rappel pendant repas, place réservée pour retour de matériaux, édition du bon filtre dans l'UI, reprise v5, migration v4 et rejet des données invalides.

Régressions : construction, navigation, livraisons, boucle principale, clics d'affectation, interface, échelles, portes, exploration, sauvegarde, sommeil et besoins. Les fixtures historiques à stocks artificiels de 1 000 à 10 000 unités disposent explicitement d'une capacité adaptée ; le nouveau test vérifie les limites normales.

`tests/depots_visual.gd` produit les captures sous `artifacts/depots/` : vue générale, repas local, lit approvisionné, totaux et panneau de construction. Rendu Compatibility sous Godot 4.7.2. Les budgets pour 30–50 habitants et plusieurs secteurs restent à mesurer.

**Après validation : commit et push, puis étape 4, les torches individuelles.**
