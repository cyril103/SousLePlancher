extends RefCounted
## Read-only conditions for the two specialized expeditions. Never claims a task.
const Local = preload("res://scripts/harvest_status.gd")
static func result(code: String, text: String, panel: String = "", action: String = "") -> Dictionary:
	return Local.result(code, text, panel, action)

static func inspect(g: Node, kind: String) -> Dictionary:
	if kind not in ["fiber", "food"]: return {}
	var fiber := kind == "fiber"
	if fiber and not g.fissure.opened(): return {}
	if not fiber and not g.fissure.visited: return {}
	var panel := "designations" if fiber else "kitchen"
	if g.local_harvest.targets[kind] == 0: return result("disabled", "Objectif 0 : nouveaux départs suspendus ; charges engagées conservées.", panel, "Voir les expéditions")
	if g.local_harvest.missing(kind) == 0: return result("covered", "Objectif couvert par les stocks et caisses engagées.", panel, "Voir les expéditions")
	if g.ended: return result("ended", "Colonie arrêtée.")
	if g.hiding: return result("recall", "Rappel actif ; ordre conservé pour la reprise avec H.")
	if g.pending_save: return result("saving", "Sauvegarde en cours ; départs suspendus.")
	if fiber and not g.fissure.visited: return result("scout", "Alcôve à reconnaître à la lanterne.", "scout", "Reconnaître")
	if not fiber and not g.kitchen.known: return result("scout", "Cuisine à reconnaître avant de rapporter des provisions.", "kitchen", "Reconnaître")
	var engaged: int = g.designations.owners.size() if fiber else 0
	if not fiber:
		for task in g.kitchen.tasks.values():
			if task.kind == "food": engaged += 1
	if engaged > 0: return result("working", "%d habitant(s) engagé(s) : équipement, trajet ou retour. Consulter leur progression." % engaged, panel, "Suivre les porteurs")
	if not g.fissure.widened(): return result("passage", "Élargir la fissure pour le passage des caisses.", "fissure", "Aménager le passage")
	if not fiber and not g.kitchen.built: return result("bridge", "Le pont cuisine doit être terminé pour les provisions.", "kitchen", "Voir le pont")
	var amount: int = g.fissure.hauling.amount if fiber else g.kitchen.amount
	var reserved: int = g.fissure.hauling.reserved if fiber else g.kitchen.reserved
	if amount <= 0: return result("exhausted", "Gisement épuisé ; choisir une autre source.", "local_harvest", "Sources du refuge")
	if not (g.designations.active if fiber else g.kitchen.harvest): return result("undesignated", "Récolte distante non désignée.", panel, "Désigner la récolte")
	if amount <= reserved: return result("reserved", "Ressources restantes déjà réservées.", panel, "Voir les expéditions")
	var permitted: Array[int] = []
	for id in range(g.workers.size()):
		if fiber and g.workers[id].patch >= 0: continue
		if g.priorities.value(id, "collect") > 0: permitted.append(id)
	if permitted.is_empty(): return result("priority", "Aucun habitant éligible avec Récolte autorisée.", "priorities", "Régler les priorités")
	var accepts := false
	var space := false
	for id in range(g.depots.sites.size()):
		if id > 0 and not g.depots.sites[id].built: continue
		if kind not in g.depots.sites[id].filters: continue
		accepts = true
		if g.depots.free_space(id) > 0: space = true
	if not accepts: return result("filters", "Aucun dépôt construit n’accepte cette ressource.", "depots", "Filtres des dépôts")
	if not space: return result("capacity", "Dépôts pleins ou places déjà réservées.", "depots", "Voir les dépôts")
	var ready: Array[int] = []
	for id in permitted:
		var c: WorkerDelivery = g.workers[id].delivery
		if not g.health.patients.has(id) and g.priorities.available(c) and g.designations.healthy(c): ready.append(id)
	if ready.is_empty(): return result("busy", "Habitants occupés, au repos ou en besoin prioritaire.", "people", "Voir les habitants")
	if g.torches.total_lanterns() == 0: return result("equipment", "Aucune lanterne possédée.", "lantern_production", "Préparer les lanternes")
	var source_path := false
	var depot_path := false
	var accessible_lamp := false
	for id in ready:
		var c: WorkerDelivery = g.workers[id].delivery
		var origin: Vector3 = g.home_position(id) if c.inside_refuge else c.actor.position
		if g.travel_path(origin, g.fissure.NEAR, id).is_empty(): continue
		source_path = true
		var quantity := mini(g.local_harvest.missing(kind), mini(3 + g.workshops, amount - reserved))
		var choice: Dictionary = g.depots.sink(g.fissure.NEAR, kind, quantity, id)
		if choice.is_empty(): continue
		depot_path = true
		var fuel: float = (g.designations.required(c, choice) if fiber else g.kitchen.required(c, "food", choice.id)) + 5
		for i in range(g.torches.items.size()):
			var lamp: Dictionary = g.torches.items[i]
			if lamp.kind != "lantern" or lamp.owner >= 0 or lamp.reserved >= 0 or g.torches.servicing(i): continue
			if g.depots.distance(origin, lamp.pos, id) == INF: continue
			accessible_lamp = true
			if lamp.fuel >= fuel: return result("ready", "Conditions préalables réunies ; départ après reprise, selon les priorités." if g.paused else "Conditions préalables réunies ; attribution selon les priorités.", panel, "Voir les expéditions")
	if not source_path: return result("source_path", "Accès à la fissure bloqué pour les habitants disponibles.", "fissure", "Voir le passage")
	if not depot_path: return result("depot_path", "Aucun dépôt accessible pour la caisse prévue.", "depots", "Vérifier les accès")
	if not accessible_lamp: return result("equipment_busy", "Lanternes portées, réservées, en entretien ou inaccessibles.", "torches", "Voir les équipements")
	return result("fuel", "Aucune lanterne accessible n’a l’autonomie nécessaire à cet aller-retour.", "lantern_service", "Entretenir les lanternes")
