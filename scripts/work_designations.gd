extends RefCounted
## First map designation: finite alcove harvest, two concurrent reservations.
var game: Node
var active := false
var owners: Dictionary = {}
var status := "Aucun ordre de récolte."
var marker: Label3D

func setup() -> void:
	marker = game.Art.caption(game, "", Vector3(3, 1.1, 12.9), Color("eac37e"))
	marker.pixel_size = .007
	marker.no_depth_test = true
	refresh()

func refresh() -> void:
	marker.visible = game.fissure.visited
	marker.text = "FIBRES · RÉCOLTE DÉSIGNÉE" if active else "FIBRES · CLIQUER POUR DÉSIGNER"

func hit(screen: Vector2) -> bool:
	if not marker.visible or game.camera.is_position_behind(marker.global_position): return false
	var center: Vector2 = game.camera.unproject_position(marker.global_position)
	var font: Font = ThemeDB.fallback_font
	var extent := font.get_string_size(marker.text, HORIZONTAL_ALIGNMENT_LEFT, -1, marker.font_size)
	var unit: float = game.camera.unproject_position(marker.global_position + game.camera.global_basis.x).distance_to(center)
	return Rect2(center - extent * marker.pixel_size * unit * .5, extent * marker.pixel_size * unit).grow(12).has_point(screen)

func designate() -> bool:
	if not game.fissure.visited or active: return false
	active = true
	status = "Ordre enregistré ; recherche d’habitants disponibles."
	refresh()
	return true

func cancel() -> void:
	active = false
	for id in owners.keys(): game.workers[id].delivery.cancel()
	status = "Ordre annulé ; les charges prélevées sont rapportées."
	refresh()

func healthy(c: WorkerDelivery) -> bool:
	return not c.worker.sleep_requested and c.worker.energy > 35 and minf(c.worker.nutrition, c.worker.hydration) > 35 and c.needs_supply < 0 and not c.need_interrupt

func required(c: WorkerDelivery, choice: Dictionary) -> float:
	var p = game.fissure
	return p.required_fuel(c) + 24.0 - game.torches.margin(c.owner) + game.torches.travel_seconds(c, p.NEAR, game.depots.entry(choice.id)) + game.torches.travel_seconds(c, game.depots.entry(choice.id), game.HOME + game.Refuge.OUTSIDE) + 12

func try_start(c: WorkerDelivery) -> bool:
	tick(c.owner)
	return owners.has(c.owner)

func tick(candidate: int = -1) -> void:
	for id in owners.keys():
		if not game.torches.occupied(id) and not game.fissure.occupied(id): owners.erase(id)
	refresh()
	if not active: return
	if game.hiding or game.ended or game.pending_save:
		status = "Suspendu : rappel ou arrêt de la colonie."
		return
	if not game.fissure.widened():
		status = "En attente : élargir le passage pour les caisses."
		return
	if game.fissure.hauling.amount <= 0:
		for id in owners:
			if not game.fissure.occupied(id): game.torches.recall(game.workers[id].delivery, "Gisement épuisé")
		status = "Dernières charges en retour." if not owners.is_empty() else "Récolte terminée : gisement épuisé."
		if owners.is_empty(): active = false
		refresh()
		return
	if candidate >= 0 or not owners.is_empty():
		status = "Récolte en cours." if owners.size() >= 2 else "En attente : habitants disponibles et reposés."
	for id in range(game.workers.size()):
		var c: WorkerDelivery = game.workers[id].delivery
		if owners.has(id):
			if not healthy(c): game.torches.recall(c, "Besoins prioritaires"); continue
			if not game.torches.can_haul(id): continue
		elif id != candidate or owners.size() >= 2 or not healthy(c) or not game.torches.available(c) or game.torches.occupied(id): continue
		if game.fissure.hauling.amount <= game.fissure.hauling.reserved:
			status = "Toutes les fibres restantes sont réservées."
			if owners.has(id): game.torches.recall(c, "Récolte déjà réservée")
			continue
		var choice: Dictionary = game.depots.sink(game.fissure.NEAR, "fiber", mini(3 + game.workshops, game.fissure.hauling.amount - game.fissure.hauling.reserved), id)
		if choice.is_empty():
			status = "En attente : aucun dépôt accessible avec de la place pour les fibres."
			if owners.has(id): game.torches.recall(c, "Dépôt indisponible")
			continue
		var fuel := required(c, choice)
		if owners.has(id):
			if game.torches.items[game.torches.held(id)].fuel < fuel:
				game.torches.recall(c, "Autonomie insuffisante pour la récolte")
			elif not game.fissure.hauling.start(id):
				game.torches.recall(c, "Accès à la récolte indisponible")
			continue
		var usable := false
		for item in game.torches.items:
			if item.kind != "lantern" or item.owner >= 0 or item.reserved >= 0 or item.fuel < fuel + 5: continue
			var from: Vector3 = game.home_position(id) if c.inside_refuge else c.actor.position
			if game.depots.distance(from, item.pos, id) < INF: usable = true
		if not usable:
			status = "En attente : fabriquer une lanterne suffisamment chargée et accessible."
			continue
		if game.torches.equip(id, "lantern"): owners[id] = true

func summary() -> String:
	var text := "Récolter les fibres de l’alcôve jusqu’à épuisement.\nDeux habitants au maximum ; lanternes récupérées automatiquement.\n\n" + ("%d habitant(s) engagé(s).\n" % owners.size() if not owners.is_empty() else "") + status
	for id in owners:
		text += "\nH%d · %s" % [id + 1, game.workers[id].delivery.description()]
	return text

func snapshot() -> Dictionary:
	var live := {}
	for id in owners:
		if game.torches.occupied(id) or game.fissure.occupied(id): live[id] = true
	return {"active": active, "owners": live, "status": status}

static func valid(value: Variant, runtime: Dictionary) -> bool:
	if not value is Dictionary or not value.has_all(["active", "owners", "status"]): return false
	if not value.active is bool or not value.owners is Dictionary or not value.status is String or value.owners.size() > 2: return false
	for id in value.owners:
		if not id is int or id < 0 or id >= runtime.workers.size() or value.owners[id] != true: return false
		if not runtime.torch_missions.has(id) and not runtime.fissure.missions.has(id): return false
	return true

func restore(value: Dictionary) -> void:
	active = value.get("active", false)
	owners = value.get("owners", {}).duplicate()
	status = value.get("status", "Aucun ordre de récolte.")
	refresh()
