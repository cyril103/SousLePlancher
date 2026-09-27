# Lot 22 — Désigner une récolte et laisser les habitants agir (9A)

**Réalisé et validé par le joueur ; commit et push autorisés.**

## Résultat visible

Cliquer le repère **FIBRES** de l’alcôve reconnue ouvre une commande contextuelle. **Désigner la récolte** crée un ordre unique, jusqu’à épuisement du gisement. Le panneau est aussi accessible par **Travaux → Ordres de récolte autonomes**. Aucun habitant n’est à sélectionner.

Au maximum deux habitants disponibles récupèrent chacun une lanterne accessible, partent récolter, reviennent chargés et livrent. Les réservations du matériel, du prélèvement, du seuil et du dépôt réutilisent les transactions existantes. Après retour, une nouvelle rotation est possible si les besoins, le combustible et les stocks le permettent. Les ressources rapportées servent notamment aux chantiers déjà commandés.

L’ordre reste en attente si le passage n’est pas élargi, si les habitants sont occupés ou doivent se reposer, si aucune lanterne suffisamment chargée n’est disponible ou si aucun dépôt accessible n’accepte la charge. Le motif est affiché. L’ordre ne fabrique pas automatiquement de lanternes et n’autorise pas l’ouverture d’un passage dangereux.

## Interruptions et sauvegarde

- Sommeil, faim, soif et rappel restent prioritaires. Les départs exigent une énergie supérieure à 35 et des besoins satisfaits ; les contrôleurs existants assurent l’interruption et le retour pendant le trajet.
- **Annuler l’ordre** rappelle ses porteurs. Une charge déjà prise revient au dépôt ; les réservations non prélevées sont libérées. Les missions manuelles sont indépendantes.
- **H** suspend les départs pendant le rappel ; reprendre les sorties rend de nouveau l’ordre exécutable. La pause arrête la simulation et x3 conserve le même ordre des opérations.
- **F5/F9** conservent l’ordre et ses habitants, y compris pendant la récupération d’équipement. Les réservations physiques restent dans le snapshot de 6C. Extension additive du runtime v10 ; les anciens snapshots sans désignation se chargent avec un carnet vide.

## Démonstration

Lancer `-- --demo-designations`. Le passage est déjà élargi, l’alcôve reconnue, deux lanternes disponibles et un lit attend des fibres. Cette préparation appartient au test, pas au déroulement de la partie normale.

1. Cliquer **FIBRES · CLIQUER POUR DÉSIGNER** dans l’alcôve.
2. Cliquer **Désigner la récolte**, puis **Espace**.
3. Observer deux habitants récupérer leurs lanternes et traverser sans affectation manuelle. Le lit reçoit ensuite les fibres rapportées.
4. Essayer **Annuler l’ordre** pendant le trajet ou le portage, puis redésigner.
5. Essayer **F5**, avancer, puis **F9** et reprendre avec Espace.

Sauvegarde séparée : `user://saves/designations_demo.json`.

## Vérifications

`tests/designations.gd` : double ordre refusé, deux départs autonomes et réservations distinctes, restauration pendant expédition et prise d’équipement, annulation chargée, sauvegarde immédiate après annulation, conservation des fibres, soif prioritaire, combustible insuffisant, dépôt refusant les fibres, rappel et achèvement d’une source finie, lecture d’un snapshot antérieur sans ordre.

`tests/designations_visual.gd` : clic projeté sur le repère, ouverture du panneau, action de désignation, captures du panneau et des deux missions. Non-régression : sauvegardes actives et récolte de l’alcôve.

## Périmètre et prochaine étape

Première désignation appliquée à **un gisement distant existant**. Pas encore de sélection rectangulaire, de désignation générique sur tous les gisements, de compétences ni de tableau individuel des priorités. L’attribution parcourt les habitants disponibles ; elle ne prétend pas optimiser distance ou spécialité. La fabrication d’éclairage et les autres chantiers gardent leurs commandes actuelles. Aucun nouvel asset 3D.

Prochaine livraison : **9B, priorités de travail**, en prolongeant l’attribution autonome plutôt qu’en ajoutant de nouveaux secteurs.
