# Lot 28 — Quatre chambres, grande carte et intimité (8B)

27 septembre 2026 — **Validé par le joueur ; commit et push autorisés.**

## Terrain agrandi à la demande du joueur

La zone de navigation au sol passe de **21 × 13 à 42 × 26 unités**, soit **quatre fois la surface rectangulaire de référence**. Les obstacles réduisent localement la surface effectivement praticable. Le sol Blender passe également de 24 × 17 à 48 × 34, avec sa marge de décor extérieure. Les accessoires de la colonie centrale restent en place ; les anciens éléments de bordure sont déplacés vers le nouveau pourtour.

Le placement ordinaire s’étend jusqu’à ±19 en X et ±11 en Z, sous réserve de l’emprise et de la navigation. Les centres de chambres sont autorisés de −18 à +18 en X et de −11 à +9 en Z, pour conserver la place de la porte et de son accès. La caméra peut se déplacer dans cette nouvelle zone et dézoomer jusqu’à 60. Le plafond, les poussières et deux rais de lumière supplémentaires accompagnent l’extension.

La fissure et la réserve à l’étage gardent leurs coordonnées. L’alcôve possède une emprise interdite à la navigation ordinaire : l’agrandissement ne permet pas de contourner son passage spécialisé. Aucun nouveau gisement, biome, insecte ni secteur procédural.

## Reconnaissance des chambres et propriété

Une chambre est reconnue quand ses trois étapes sont achevées. Son intérieur est déterminé par les dimensions du plan construit ; les lits et habitants y sont associés par leur position. Un chantier ouvert ne procure pas le bénéfice d’une pièce terminée.

**Construire → Construire une chambre** affiche la chambre sélectionnée, les habitants présents et le motif de son niveau d’intimité. Le menu d’attribution permet de choisir H1–H4 ou **Chambre collective · lit non attribué**.

La propriété de la chambre est celle de son lit. Il n’existe donc pas deux propriétaires contradictoires à sauvegarder. Attribuer un autre lit à un habitant libère son précédent lit. L’attribution ne peut pas changer pendant une réservation d’accès ou une occupation ; le choix est désactivé ou refusé avec un message. Les chambres restent chacune limitées à leur lit central : « collective » signifie utilisation successive du lit disponible, pas dortoir à plusieurs lits.

## Intimité et récupération réelles

Les valeurs sont recalculées pendant le sommeil, selon la pièce, la porte et les occupants présents :

| Situation | Intimité |
| --- | ---: |
| Chambre personnelle, seul, porte fermée | 95 / 100 |
| Chambre collective, seul, porte fermée | 60 / 100 |
| Porte ouverte ou maintenue ouverte | Au plus 35 / 100 |
| Un autre habitant est présent dans la chambre | Au plus 25 / 100 |

Pour un lit dans une chambre, confort = `75 + intimité × 0,1` et récupération = `2 + intimité × 0,008` points d’énergie par seconde. Fermer la porte automatique rétablit le bénéfice si l’habitant est seul. La présence d’un visiteur le réduit jusqu’à son départ. Le panneau précise la cause ; le personnage conserve les dernières valeurs vécues après son réveil, comme dans le système de besoins existant.

Les lits simples hors chambre, anciennes alcôves et couchages au sol conservent leurs règles : respectivement intimité 20, 100 et 0. Il n’y a pas encore d’humeur, de relation sociale ou de malus durable lié à une intrusion. Les règles de sécurité de porte et le retour au refuge restent inchangés.

## Sauvegarde

Format **v15** : coordonnées étendues, caméra élargie, matériaux à récupérer dans l’extension. Chambres, état des portes, propriétaires de lits et besoins individuels sont déjà enregistrés par les systèmes existants ; l’association géométrique est recalculée après chargement. Les sauvegardes v14 restent lisibles avec leurs anciennes coordonnées et profitent du terrain agrandi.

## Démonstration

Lancement : `-- --demo-privacy`. Quatre chambres et quatre lits déjà construits servent de fixture pour tester 8B. La construction normale reste celle du lot 27, avec paiement et livraisons physiques. Chambres aux positions (−17, −9), (−12, −9), (−17, −3), (−12, −3) dans la nouvelle zone ouest ; propriétaires H1 à H4.

1. **Espace** : les quatre habitants fatigués rejoignent chacun leur lit automatiquement.
2. Dans le panneau Chambres, comparer **Porte auto** et **Ouverte** pendant le repos : le niveau d’intimité change.
3. Après libération des lits, changer l’attribution ou passer une chambre en usage collectif. Les propriétaires restent cohérents avec le panneau Couchages.
4. Utiliser la molette pour dézoomer et ZQSD/flèches pour parcourir l’extension. Le panneau défile pour accéder aux commandes inférieures.
5. **F5 / F9** pendant le sommeil ou après changement d’attribution.

Fichier distinct : `user://saves/privacy_demo.json`.

## Assets et vérifications

- Sol agrandi dans Blender : `art_source/floor_expanded.blend`, `assets/models/floor_expanded.glb`, script `tools/create_expanded_floor.py`. Les modèles de chambre sont réutilisés.
- `tests/privacy.gd` : surface ×4, quatre chambres accessibles, association des lits et propriétaires, sommeil autonome des quatre habitants, portes et intrusion, réattribution sûre, sauvegarde/reprise, migration v14, chantier réellement approvisionné à (−17, 8), annulation/récupération/reprise en bordure sud agrandie.
- Régressions `navigation`, `alcove_haul`, `rooms`. Les murs des tests de séparation sont alignés sur les nouvelles limites de carte ; les exigences de non-franchissement sont conservées.
- `tests/privacy_visual.gd` : vue d’ensemble, quatre dormeurs et effet d’une porte ouverte, contrôlés en rendu Compatibility sous Godot 4.7.2.

## Limites et suite

La détection concerne les chambres compactes construites, pas un assemblage libre de murs. Aucun dortoir multi-lit ou éditeur de forme n’est ajouté. La carte est plus grande, mais conserve le même contenu de ressources ; l’espace libre sert à l’aménagement.

**Prochaine livraison : étape 10 — soins et secours minimaux**, à cadrer avant développement, sans engager en parallèle une nouvelle espèce ou un nouveau secteur.
