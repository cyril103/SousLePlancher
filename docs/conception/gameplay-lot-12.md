# Lot 12 — Sommeil, fabrication des lits et intimité

État : validé par le joueur (« ok validé, commit et push »), publication autorisée avec le lot 13. Ce lot suit sa demande de commencer la vie quotidienne par le sommeil et de remplacer les abris hérités du premier prototype.

## Jouer et examiner

Dans **Construire [B]**, choisir **Lit [1]** ou **Alcôve [3]**, puis un emplacement libre. Les matériaux sont réservés immédiatement au dépôt. Un habitant termine sa livraison avant de rejoindre le chantier ; il fabrique le couchage avec son animation de travail. Le tas de matériaux devient un lit uniquement lorsque la fabrication est terminée. La pause et la vitesse de simulation s’appliquent aux travaux et au repos.

**Couchages**, accessible depuis Construire, Travaux ou la fiche d’un habitant, permet de consulter les chantiers et de changer les propriétaires. Un premier lit est automatiquement attribué à chaque habitant qui en manque. Un lit libre peut être utilisé par un habitant sans lit attitré. Un couchage réservé par un dormeur ne peut pas changer de propriétaire. Chaque habitant possède au plus un lit ; les réservations empêchent deux habitants de dormir dans le même.

Un chantier inachevé peut être annulé : son travail est perdu, ses matériaux réservés sont rendus une seule fois et l’obstacle est retiré de la navigation. Les lits achevés ne disposent pas encore d’un ordre de démontage.

La fiche d’habitant affiche son énergie, son lit et la qualité de son dernier repos. **Se reposer** demande un repos anticipé sans supprimer son affectation. À faible énergie, il prend cette décision automatiquement. Une charge déjà prélevée est déposée avant de dormir. Au réveil, le travail reprend.

Sans couchage terminé et accessible, un habitant rejoint le refuge et somnole accroupi à sa place : cela évite un blocage permanent, mais récupère beaucoup moins vite. Les cloisons d’une alcôve procurent de l’intimité ; elles ne constituent pas un refuge sûr contre les humains. **H** réveille les dormeurs, interrompt les travaux et rappelle la colonie. Les franchissements engagés se terminent avant le changement de tâche.

Démo préparée, sans modifier la sauvegarde du joueur :

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64.exe' --path . -- --demo-sleep
```

La démo commence en pause : deux lits occupés et un troisième chantier, avec des réserves de démonstration. **Espace** reprend la simulation. Une nouvelle partie ordinaire commence avec quatre habitants, aucun lit et les réserves initiales habituelles.

## Équilibrage provisoire

Les durées ci-dessous sont des secondes de simulation à vitesse ×1. Le cycle des humains de 100 secondes reste une mécanique antérieure, distincte d’une future horloge quotidienne.

| Élément | Valeur |
|---|---|
| Énergie initiale | 100/100 |
| Fatigue en activité | −0,16/s |
| Fatigue au repos éveillé et pendant le retour | −0,10/s |
| Demande automatique de sommeil | énergie ≤ 25 |
| Épuisement | sous 15, vitesse de déplacement normale réduite à 65 % |
| Réveil normal | énergie ≥ 95 |
| Lit en boîte d’allumettes | 4 bois + 3 fibres ; 12 s de fabrication sur place |
| Lit simple occupé | +2 énergie/s ; confort 65 ; intimité 20 |
| Alcôve individuelle avec lit | 6 bois + 5 fibres ; 20 s de fabrication sur place |
| Alcôve occupée | +3 énergie/s ; confort 85 ; intimité 100 |
| Repos de fortune au refuge | +0,6 énergie/s ; confort 15 ; intimité 0 |
| Se coucher / se relever | 1,8 s par transition, hors récupération |

Le confort et l’intimité décrivent le dernier repos. Ils ne sont pas encore des besoins autonomes ni un système d’humeur. L’alcôve constitue un ensemble indivisible avec son lit ; la pose libre de murs, la détection de pièces fermées et l’amélioration d’un lit existant ne sont pas implémentées dans ce lot.

## Retrait des anciennes règles

Le bouton Abri, son raccourci et l’objectif « deux abris, un atelier, 35 miettes » sont retirés de la partie ordinaire. Construire un lit ne crée pas d’habitant. Il n’y a plus de victoire automatique à la fin du premier cycle. Les défaites par faim et découverte restent actives.

Les vieux abris et leurs habitants déjà recrutés sont conservés lors du chargement d’une ancienne partie, afin de ne pas supprimer les progrès existants. Leur ancien constructeur demeure uniquement pour cette compatibilité et les fixtures de régression. Le refuge initial reste pour l’alerte humaine, la porte et les points de sauvegarde ; il n’est pas compté comme un lit. Le recrutement futur suivra le cahier des charges.

## Persistance et architecture

`colony_sleep.gd` porte les besoins, commandes de fabrication, propriétaires et réservations de lits. `WorkerDelivery` reste responsable des déplacements, caisses, portes, échelles et passerelles ; le service de sommeil intervient aux points où une tâche peut être suspendue sans perte de ressources.

Le point de sauvegarde attend toujours une colonie réunie au refuge. Les dormeurs se lèvent et les chantiers libèrent leurs ouvriers. La version 2 ajoute énergie, confort, intimité, demande de repos, propriétaires des lits et avancement des travaux. Les matériaux déjà payés ne sont pas facturés une seconde fois au chargement. Les anciennes versions 1 sont lues avec des besoins initialisés à 100 et aucun lit. Le chemin historique `user://saves/colony_v1.json` est volontairement conservé pour retrouver les parties existantes.

## Assets et rendu

- Réutilisation du lit approuvé `reference_01/matchbox_bed.glb`, avec ses textures de boîte d’allumettes et son linge.
- Nouveaux assets Blender `sleep_12/privacy_partition`, `bed_materials`, `closed_eyes` ; sources `.blend` éditables sous `art_source/sleep_12`.
- Cloisons latérales en tissu plissé, ourlets irréguliers, attaches en fil, montants en bois et fond en carton. Façade et plafond ouverts pour l’accès et la lecture de la scène.
- Quatre clips squelettiques ajoutés au résident : `bed_enter`, `sleep`, `bed_exit`, `floor_rest`. La respiration anime le repos ; les paupières fermées ne sont visibles que pendant le sommeil.
- Les matériaux PBR texturés sont conservés : le shader d’usure du décor ancien ne remplace plus leurs textures par une couleur unie.

Régénération : `tools/create_sleep_assets.py`, puis `tools/create_resident_animations.py` dans Blender ; import des GLB dans Godot. Les clips existants conservent leurs vitesses et conventions de déplacement.

## Vérification

`tests/sleep.gd` couvre la fabrication différée, le paiement unique, le sommeil déclenché pendant un transport, la conservation de la charge et de l’affectation, le réveil avec reprise du travail, le rappel, le repos au sol, la propriété exclusive, la sauvegarde des besoins et des chantiers, la lecture de l’ancien format, le rejet de données incohérentes et le remboursement d’un chantier annulé.

`tests/sleep_visual.gd` produit des vues d’ensemble, des deux couchages et des panneaux de construction et d’attribution sous `artifacts/sleep/`. Les suites existantes vérifient navigation, livraison, interface, échelles, porte, exploration et sauvegarde. Le test de fumée vérifie désormais que les anciens objectifs ne terminent plus la colonie.

## Suite à discuter après revue

Horaires de sommeil individuels, spécialisation des constructeurs, transport physique des matériaux vers les chantiers, démontage et déplacement du mobilier, cloisons librement placées et calcul réel des pièces, pénalités d’humeur liées au bruit et au manque d’intimité. Ce lot ne prétend pas encore réaliser ces systèmes.
