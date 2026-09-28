extends RefCounted
## Guidance derived from saved simulation: no separate tutorial progression to desynchronize.

static func delivered(game: Node) -> int:
	var outstanding: int = game.kitchen.amount + game.ant.stored + game.ant.carrying
	for id in game.kitchen.tasks:
		var task: Dictionary = game.kitchen.tasks[id]
		if task.kind == "food" and task.collected and not task.deposited:
			outstanding += game.workers[id].carrying
	return maxi(0, 36 - outstanding)

static func steps(game: Node) -> Array:
	var lantern := false
	for item in game.torches.items:
		if item.kind == "lantern": lantern = true
	return [
		[game.sleeping.ready_count() > 0, "Installer un premier lit", "build", "Commander un lit : 4 bois, 3 fibres. Les habitants livrent puis fabriquent le couchage."],
		[game.workshops > 0, "Construire un atelier", "build", "Prévoir 10 bois et 6 fibres. Désigner le bois et les fibres au sol pour que les habitants libres réapprovisionnent le refuge."],
		[lantern, "Fabriquer une lanterne", "fissure", "Fabriquer à l’atelier : 4 bois, 3 fibres. Transport et Construction doivent être autorisés pour livrer puis fabriquer."],
		[game.fissure.discovered, "Inspecter la fissure", "fissure", "Choisir un habitant disponible, sans éclairage équipé, puis Inspecter."],
		[game.fissure.opened(), "Dégager et étayer", "fissure", "Commander le passage : 6 bois, 4 fibres. Laisser livrer les matériaux et terminer les travaux."],
		[game.fissure.visited, "Explorer l’alcôve", "fissure", "Choisir un habitant reposé, Équiper la lanterne, puis Explorer à la lanterne après la prise de l’équipement."],
		[game.fissure.widened(), "Élargir pour les caisses", "fissure", "Attendre le retour de l’éclaireur, puis commander l’élargissement : 6 bois, 4 fibres."],
		[game.kitchen.known, "Reconnaître la cuisine", "kitchen", "Désigner la reconnaissance. Un habitant disponible prendra une lanterne suffisamment chargée."],
		[game.kitchen.built, "Construire le pont", "kitchen", "Commander le pont : 8 bois, 4 fibres. Les porteurs livrent depuis les dépôts ; reprendre le chantier s’il est suspendu."],
		[delivered(game) > 0, "Rapporter les provisions", "kitchen", "Désigner la récolte. Observer la fourmi, attendre ou choisir le détour ouest. L’objectif se termine au dépôt."],
	]

static func logistics(game: Node) -> Dictionary:
	if not game.patches[2].get("autoharvest", false) or not game.patches[4].get("autoharvest", false):
		return {"tray": "local_harvest", "action": "Organiser les récoltes", "text": "Désigner le bois et les fibres du refuge : les habitants sans affectation prennent les tâches à leur priorité Récolte. Les affectations manuelles restent utilisables."}
	if game.local_harvest.targets.wood < 0 or game.local_harvest.targets.fiber < 0:
		return {"tray": "harvest_targets", "action": "Régler les réserves", "text": "Pour ce parcours, viser 22 bois et 18 fibres constitue un point de départ. Les charges engagées comptent ; les récoltes reprennent après consommation. Les objectifs n’ajoutent pas de capacité aux dépôts."}
	if game.workshops > 0 and game.torches.total_lanterns() < 2 and game.torches.craft_target == 0:
		return {"tray": "lantern_production", "action": "Préparer les lanternes", "text": "Viser 2 lanternes au total permet leur fabrication automatique : 4 bois et 3 fibres par équipement. Les commandes déjà engagées comptent. L’entretien des lanternes vides se règle séparément."}
	var lantern := false
	for item in game.torches.items:
		if item.kind == "lantern": lantern = true
	if lantern and game.torches.refill_target == 0:
		return {"tray": "lantern_service", "action": "Entretenir les lanternes", "text": "Préparer deux lanternes puis viser une réserve de 2 lanternes pleines facilite les sorties. L’entretien automatique coûte 2 bois par plein ; il entretient les équipements existants sans en fabriquer."}
	return {"tray": "harvest_targets", "action": "Vérifier les réserves", "text": "Les réserves se régulent avec vos objectifs. Si un travail attend, consulter leur diagnostic et les priorités. H reste nécessaire avant le passage humain ; l’automatisme ne rappelle pas la colonie."}

static func current(game: Node) -> Dictionary:
	var milestones := steps(game)
	var completed := 0
	var next: Array = []
	var lines := PackedStringArray()
	for milestone in milestones:
		if milestone[0]: completed += 1
		elif next.is_empty(): next = milestone
		lines.append(("✓ " if milestone[0] else "○ ") + milestone[1])
	var text := "%d / %d étapes · Du refuge à la cuisine\n\n" % [completed, milestones.size()]
	if next.is_empty():
		text += "Premier chapitre accompli. Les provisions sont arrivées ; la colonie continue."
	else:
		text += "Prochaine action · " + next[1] + "\n" + next[3]
		if next[2] == "kitchen":
			text += "\n" + game.kitchen.status
			if game.kitchen.amount == 0 and delivered(game) == 0:
				text += "\nBiscuit épuisé. Si aucune caisse ne revient, reprendre une sauvegarde antérieure pour cet objectif ; la colonie peut continuer avec ses gisements locaux."
	var support := logistics(game)
	text += "\n\nGestion des réserves · " + support.text
	text += "\n\n" + "\n".join(lines)
	text += "\n\nBesoins et réserves restent prioritaires. H rappelle les habitants ; H à nouveau reprend les tâches. Ravitailler les lanternes rangées dans Éclairage et éclaireurs : 2 bois par plein. F5 sauvegarde sur place et met en pause."
	return {"text": text, "tray": "build" if next.is_empty() else next[2], "action": "Développer la colonie" if next.is_empty() else next[1], "completed": completed, "support_tray": support.tray, "support_action": support.action}
