extends RefCounted
## Read-only diagnosis of local dispatch conditions, never a scheduling attempt.
static func result(code: String, text: String, panel: String = "", action: String = "") -> Dictionary:
	return {"code": code, "text": text, "panel": panel, "action": action}

static func inspect(g: Node, kind: String) -> Dictionary:
	if g.local_harvest.targets[kind] == 0: return result("disabled", "Départs automatiques désactivés par l’objectif 0.")
	if g.local_harvest.missing(kind) == 0: return result("covered", "Objectif couvert par les stocks et charges engagées.")
	if g.ended: return result("ended", "Colonie arrêtée.")
	if g.hiding: return result("recall", "Rappel actif : reprendre les sorties avec H.")
	if g.pending_save: return result("saving", "Sauvegarde en cours : nouveaux départs suspendus.")
	var selected: Array[int] = []
	var remaining: Array[int] = []
	for id in g.local_harvest.PATCHES:
		var p: Dictionary = g.patches[id]
		if p.kind != kind or not p.discovered or not p.get("autoharvest", false): continue
		selected.append(id)
		if p.amount > 0: remaining.append(id)
	if selected.is_empty(): return result("undesignated", "Aucun gisement au sol désigné pour cette ressource.", "local_harvest", "Désigner")
	if remaining.is_empty(): return result("exhausted", "Gisements désignés épuisés ; choisir une autre source si disponible.", "local_harvest", "Voir les sources")
	var unassigned: Array[int] = []
	var permitted: Array[int] = []
	for id in range(g.workers.size()):
		if g.workers[id].patch >= 0: continue
		unassigned.append(id)
		if g.priorities.value(id, "collect") > 0: permitted.append(id)
	if unassigned.is_empty(): return result("assigned", "Tous les habitants ont une affectation manuelle.", "people", "Affectations")
	if permitted.is_empty(): return result("priority", "Récolte à 0 pour tous les habitants sans affectation.", "priorities", "Priorités")
	var accepts := false
	var space := false
	for id in range(g.depots.sites.size()):
		if id > 0 and not g.depots.sites[id].built: continue
		if not kind in g.depots.sites[id].filters: continue
		accepts = true
		if g.depots.free_space(id) > 0: space = true
	if not accepts: return result("filters", "Aucun dépôt construit n’accepte cette ressource.", "depots", "Dépôts et filtres")
	if not space: return result("capacity", "Dépôts pleins ou places déjà réservées.", "depots", "Voir les dépôts")
	var free_sources: Array[int] = []
	for id in remaining:
		if g.patches[id].amount > g.patches[id].reserved and not g.delivery_ledger.source_slots.has(id): free_sources.append(id)
	if free_sources.is_empty(): return result("reserved", "Postes de prélèvement ou ressources déjà réservés.")
	var ready: Array[int] = []
	for id in permitted:
		if g.health.patients.has(id) or g.workers[id].energy <= g.sleeping.THRESHOLD: continue
		if g.priorities.available(g.workers[id].delivery): ready.append(id)
	if ready.is_empty():
		for job in g.delivery_ledger.jobs.values():
			if job.source in selected: return result("working", "Récolte en cours ; les habitants terminent leurs charges.")
		return result("busy", "Habitants occupés, au repos ou en besoin prioritaire.", "people", "Voir les habitants")
	var reachable_source := false
	for id in ready:
		var c: WorkerDelivery = g.workers[id].delivery
		var origin: Vector3 = g.home_position(id) if c.inside_refuge else c.actor.position
		for source in free_sources:
			var target: Vector3 = g.patches[source].pos + Vector3(.9, WorkerDelivery.GROUND_Y, .2)
			if g.travel_path(origin, target, id).is_empty(): continue
			reachable_source = true
			if not g.depots.sink(target, kind, 1, id).is_empty():
				return result("ready", "Prêt après reprise de la simulation, selon les priorités." if g.paused else "Conditions réunies ; attribution selon les priorités.")
	if not reachable_source: return result("source_path", "Accès aux gisements bloqué pour les habitants disponibles.", "local_harvest", "Localiser les sources")
	return result("depot_path", "Aucun trajet vers un dépôt acceptant la charge.", "depots", "Vérifier les accès")
