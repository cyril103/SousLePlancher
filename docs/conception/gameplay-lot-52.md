# Lot 52 — Donner la priorité à un gisement

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Ordre des récoltes autonomes

Le panneau **Gisement du refuge** propose **1 · Haute**, **2 · Normale** et **3 · Basse**. Cliquer sur la ressource ou son étiquette, ou ouvrir **Détails** depuis la liste des récoltes. La liste affiche également la priorité de chaque source.

Lorsqu’un habitant disponible prend une récolte automatique, les sources de priorité 1 sont examinées avant celles de priorité 2 puis 3. À égalité, le numéro du gisement conserve l’ordre stable précédent. Un gisement épuisé, déjà occupé, bloqué ou dont le quota est couvert laisse passer les autres. Les limites de réservation et les caisses partielles continuent de s’appliquer.

Changer une priorité ne désigne pas un gisement suspendu et n’interrompt aucune caisse engagée. Les habitants conservent leurs propres priorités entre Récolte, Transport et Construction. Les besoins urgents, les affectations manuelles et le rappel gardent leur fonctionnement. Ce réglage ne départage que les cinq gisements du refuge ; l’alcôve et la cuisine conservent leurs règles d’attribution.

Une source haute sans limite peut continuer à être choisie avant les sources basses : les objectifs de réserve permettent de lui donner une limite. Pour arrêter les départs, utiliser **Suspendre la récolte** ; il n’existe pas de priorité 0 pour un gisement.

## Sauvegarde et démo

**Format v28** : chaque gisement conserve sa priorité. Les anciennes sauvegardes sans ce champ reçoivent la priorité **2 · Normale**, ce qui conserve l’ordre précédent, les désignations et les charges en cours. Les valeurs hors de 1–3 et les incohérences entre données compactes et missions sauvegardées sont rejetées. Les sources en hauteur conservent la valeur normale sans commande de priorité.

Lancer `-- --demo-harvest-priority`. Un seul habitant a Récolte autorisée. Les fibres ont la priorité haute et un objectif de 9 depuis un stock de 6 ; le bois a la priorité basse et un objectif de 15 depuis 12. Espace lance la caisse de fibres avant celle de bois. Changer la priorité pendant le portage laisse cette caisse terminer ; F5/F9 reprend avec les réglages conservés.

Sauvegarde distincte : `user://saves/harvest_priority_demo.json`.

## Vérifications

- `tests/harvest_priority.gd` : départ prioritaire réel, modification par l’interface pendant portage, sauvegarde chargée, quotas exacts après reprise, validation v28, migration v27 avec caisse, repli quand le gisement prioritaire est bloqué, égalités et affectation manuelle.
- `tests/harvest_priority_visual.gd` : panneau avec réglage, liste des priorités et portage ; captures `artifacts/harvest_targets_priority_*.png` contrôlées.
- Régressions : `tests/harvest_source.gd`, `tests/local_harvest.gd` et `tests/harvest_targets.gd`, dont besoins urgents, dépôt plein, concurrence, caisses partielles et migrations antérieures.
