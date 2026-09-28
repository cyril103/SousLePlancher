# Lot 47 — Réguler les provisions de la cuisine

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Réserve alimentaire commune

La récolte désignée du biscuit respecte l’objectif **Miettes** des réserves, partagé avec les sources du refuge. **Accès cuisine → Objectif de réserve alimentaire** ouvre le réglage. Le panneau cuisine affiche le stock prévu et indique si le seuil est couvert.

Les stocks de tous les dépôts et les caisses engagées sont comptés. Les provisions de cuisine sont réservées dès l’attribution de l’équipement : un second porteur ou une récolte locale ne peut pas réserver à nouveau le même manque. La dernière caisse peut être partielle.

Une fois le seuil couvert, la désignation reste active, sans nouveau départ. La consommation lors d’un repas rend à nouveau une récolte possible. Les lanternes, les accès, les besoins, la place au dépôt et la fourmi gardent leurs règles existantes.

**0** suspend les nouveaux départs ; **−1** garde la récolte sans limite. Une baisse laisse terminer les caisses déjà réservées, même pendant la prise de l’équipement. Pour rappeler les porteurs, utiliser la commande d’arrêt de récolte ou H. La collecte urgente pour les besoins reste possible indépendamment du quota.

La reconnaissance et le chantier du pont ne sont pas limités par cet objectif alimentaire. Avant la première livraison du chapitre, le guide explique qu’un seuil à zéro ou déjà couvert peut empêcher de commander une nouvelle caisse ; il n’augmente pas le réglage à la place du joueur.

## Sauvegarde et essai

**Format v27 inchangé** : objectifs, réservations et tâches cuisine sont déjà conservés. Les sauvegardes avec un objectif alimentaire réglé appliquent désormais ce seuil à la cuisine ; −1 conserve la récolte sans limite.

Démo `-- --demo-kitchen-target` : pont et lanternes fournis, 24 provisions en stock, objectif de 29 et récolte désignée. Espace reprend. Les deux premières caisses contiennent trois et deux provisions. Observer la fourmi, puis modifier l’objectif ou utiliser F5/F9 pendant le retour. La démo dispose d’une sauvegarde utilisateur distincte.

## Vérifications

- `tests/kitchen_target.gd` : quota exact, caisse partielle, comptabilité des provisions dans la colonie/le biscuit/les charges/la fourmi, rechargement pendant portage, reprise après un repas réel, baisse à zéro après réservation, récolte locale concurrente et explication dans le chapitre.
- `tests/kitchen_target_visual.gd` : panneaux cuisine et réserves, captures `artifacts/harvest_targets_kitchen_target_*.png` contrôlées.
- Régressions : `tests/chapter.gd` pour les provisions, rappels et progression du chapitre ; `tests/harvest_targets.gd` pour les récoltes locales, quotas et transferts.
