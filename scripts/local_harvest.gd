extends RefCounted
## Orders only. Physical jobs remain in the existing delivery ledger.
const PATCHES := [0, 1, 2, 4, 7]
var game: Node

func set_active(id: int, active: bool) -> bool:
	if not id in PATCHES or id >= game.patches.size(): return false
	if active and (not game.patches[id].discovered or game.patches[id].amount <= 0): return false
	game.patches[id].autoharvest = active
	return true

func try_start(c: WorkerDelivery) -> bool:
	# Called by priorities only for residents without a manual assignment.
	for id in PATCHES:
		var p: Dictionary = game.patches[id]
		if not p.get("autoharvest", false) or not p.discovered or p.amount <= p.reserved: continue
		if game.delivery_ledger.source_slots.has(id): continue
		var target: Vector3 = p.pos + Vector3(.9, WorkerDelivery.GROUND_Y, .2)
		var origin: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(origin, target, c.owner).is_empty(): continue
		if game.depots.sink(target, p.kind, mini(3 + game.workshops, p.amount - p.reserved), c.owner).is_empty(): continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		if c.start_harvest(id): return true
	return false

func summary(id: int) -> String:
	var p: Dictionary = game.patches[id]
	var text := "%s · gisement %d · %d restant(s)" % [game.NAMES[p.kind], id + 1, p.amount]
	if not p.get("autoharvest", false): return text + "\nOrdre suspendu ; les charges engagées se terminent."
	if p.amount <= 0:
		for job in game.delivery_ledger.jobs.values():
			if job.source == id: return text + "\nGisement épuisé ; dernières charges en retour."
		return text + "\nRécolte terminée : gisement épuisé."
	if game.hiding or game.ended or game.pending_save: return text + "\nSuspendu par le rappel ou l’arrêt de la colonie."
	var engaged := 0
	for job in game.delivery_ledger.jobs.values():
		if job.source == id: engaged += 1
	if engaged > 0: return text + "\n%d charge(s) engagée(s), affectations manuelles comprises." % engaged
	var allowed := false
	for i in range(game.workers.size()):
		if game.workers[i].patch < 0 and game.priorities.value(i, "collect") > 0: allowed = true
	if not allowed: return text + "\nAucun habitant sans affectation autorisé à récolter."
	return text + "\nAttend un habitant disponible, un accès et une place au dépôt."
