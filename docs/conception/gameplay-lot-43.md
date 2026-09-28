# Lot 43 — Annuler une fabrication d’équipement

Livraison du 28 septembre 2026 ; commit et push autorisés par le joueur.

## Commande joueur

**Travaux → Éclairage et éclaireurs → Fabrications en cours** liste les commandes actives de torches et lanternes. Choisir la commande affiche ses matériaux et son avancement ; **Annuler la fabrication** arrête ce chantier. Le suivi des chantiers ouvre directement la commande correspondante. Le panneau de production automatique donne aussi accès à cette liste.

L’annulation libère l’artisan et les réservations non prélevées. Les charges déjà prises reviennent au dépôt ; les matériaux livrés restent sur place sous forme de tas à récupérer. Leur récupération utilise les priorités de transport et la place disponible. Le travail d’assemblage est perdu, mais aucun bois ni aucune fibre n’est détruit ou remboursé instantanément.

Annuler une lanterne met son objectif de fabrication automatique à zéro, pour éviter une recréation immédiate. Annuler une torche ne change pas cet objectif. Les autres commandes et l’entretien restent actifs ; les équipements terminés ne peuvent pas être annulés. L’atelier libéré peut recevoir une nouvelle commande.

Le panneau Éclairage et éclaireurs devient défilant pour garder ses commandes accessibles. Aucun nouvel asset.

## Sauvegarde et essai

Le format **v25** valide les fabrications annulées dans la simulation sauvegardée, avec leurs charges en retour et tas de récupération. Les anciennes sauvegardes restent lisibles, sans réglage à migrer.

Lancer `-- --demo-lantern-production`, reprendre avec Espace, attendre une livraison puis mettre en pause. Ouvrir **Gérer / annuler les fabrications**, annuler la commande et consulter **Suivi des chantiers et récupération**. F5/F9 permet de vérifier la reprise au même instant. Reprendre la simulation : les matériaux reviennent au dépôt. Régler à nouveau l’objectif total à deux pour relancer la production.

## Vérifications

- `tests/equipment_cancel.gd` : torche et lanterne annulées avant prélèvement, pendant portage et pendant assemblage ; conservation des deux matériaux, sauvegarde JSON immédiate, récupération complète après reprise et nouvel ordre terminé. Vérifie aussi les indices invalides, la double annulation, les commandes terminées, le choix entre deux ateliers, la préservation des autres ordres et de l’entretien, la lecture v24 et le rejet d’un état annulé incohérent.
- `tests/equipment_cancel_visual.gd` : panneaux de commande, récupération, production et éclairage ; captures `artifacts/harvest_targets_equipment_cancel_*.png`.
- Régressions : `tests/lantern_production.gd`, `tests/automatic_refills.gd`, `tests/construction_board.gd`.
