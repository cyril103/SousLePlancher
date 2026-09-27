extends RefCounted
## Local inventories, space/material reservations and independent loading queues.
const KINDS := ["food", "wood", "fiber", "water"]
const COST := {"wood": 6, "fiber": 4}
const WORK := 16.0
const EAST_POSITION := Vector3(11.2, 2.04, -3.7)
const ENTRY := Vector3(0, -.0105, 1.05)
var game: Node3D
var sites: Array[Dictionary] = []
var incoming: Dictionary = {}
var outgoing: Dictionary = {}

func setup() -> void:
	sites.append({"pos": game.HOME, "capacity": 80, "filters": KINDS.duplicate(), "gate": game.delivery_ledger})

func stocks(id: int) -> Dictionary:
	return game.stock if id == 0 else sites[id].stock

func entry(id: int) -> Vector3:
	return game.HOME + Vector3(1.6, -.0105, .25) if id == 0 else entrance(sites[id].pos)

static func entrance(pos: Vector3) -> Vector3:
	return pos + (Vector3(-.9, -.0105, 0) if pos.y > 1 else ENTRY)

func used(id: int) -> int:
	var count := 0
	for kind in KINDS: count += int(stocks(id).get(kind, 0))
	return count

func booked(id: int) -> int:
	var count := 0
	for item in incoming.values():
		if item.id == id: count += item.quantity
	return count

func free_space(id: int) -> int:
	if id > 0 and not sites[id].built: return 0
	return maxi(0, int(sites[id].capacity) - used(id) - booked(id))

func reserved(id: int, kind: String) -> int:
	var count := 0
	for item in outgoing.values():
		if item.id == id and item.kind == kind: count += item.quantity
	return count

func available(id: int, kind: String) -> int:
	if id > 0 and not sites[id].built: return 0
	return int(stocks(id).get(kind, 0)) - reserved(id, kind)

func total(kind: String) -> int:
	var count := 0
	for id in range(sites.size()): count += int(stocks(id).get(kind, 0))
	return count

func total_available(kind: String) -> int:
	var count := 0
	for id in range(sites.size()): count += available(id, kind)
	return count

func distance(from: Vector3, to: Vector3, owner: int) -> float:
	var path: PackedVector3Array = game.travel_path(from, to, owner)
	if path.is_empty(): return INF
	var length := 0.0
	var previous := from
	for point in path:
		length += previous.distance_to(point)
		previous = point
	return length

func sink(from: Vector3, kind: String, quantity: int, owner: int, whole: bool = false) -> Dictionary:
	var best: Dictionary = {}
	var length := INF
	for id in range(sites.size()):
		if not kind in sites[id].filters: continue
		var amount := mini(quantity, free_space(id))
		if amount <= 0 or (whole and amount < quantity): continue
		var route := distance(from, entry(id), owner)
		if route < length:
			length = route
			best = {"id": id, "quantity": amount, "kind": kind}
	return best

func source(from: Vector3, kind: String, owner: int, target: Vector3 = Vector3.INF) -> int:
	var best := -1
	var length := INF
	for id in range(sites.size()):
		if available(id, kind) <= 0: continue
		var route := distance(from, entry(id), owner)
		if target != Vector3.INF: route += distance(entry(id), target, owner)
		if route < length:
			length = route
			best = id
	return best

func reserve_in(token: String, choice: Dictionary) -> void:
	assert(not incoming.has(token) and choice.quantity <= free_space(choice.id))
	incoming[token] = choice.duplicate()
	refresh(choice.id)

func reserve_out(token: String, id: int, kind: String, quantity: int) -> void:
	assert(not outgoing.has(token) and quantity <= available(id, kind))
	outgoing[token] = {"id": id, "kind": kind, "quantity": quantity}
	refresh(id)

func withdraw(token: String, reserve_return: bool = false) -> int:
	var item: Dictionary = outgoing[token]
	stocks(item.id)[item.kind] -= item.quantity
	outgoing.erase(token)
	if reserve_return: incoming[token] = item
	refresh(item.id)
	return item.quantity

func deposit(token: String) -> int:
	var item: Dictionary = incoming[token]
	stocks(item.id)[item.kind] = int(stocks(item.id).get(item.kind, 0)) + item.quantity
	incoming.erase(token)
	refresh(item.id)
	return item.quantity

func release(token: String) -> void:
	var id := -1
	if incoming.has(token): id = incoming[token].id
	if outgoing.has(token): id = outgoing[token].id
	incoming.erase(token)
	outgoing.erase(token)
	if id >= 0: refresh(id)

func reroute(token: String, from: Vector3, owner: int) -> bool:
	var old: Dictionary = incoming[token]
	if distance(from, entry(old.id), owner) < INF: return true
	var other := sink(from, old.kind, old.quantity, owner, true)
	if other.is_empty(): return false
	incoming[token] = other
	refresh(old.id)
	refresh(other.id)
	return true

func gate(id: int) -> DeliveryLedger:
	return sites[id].gate

func waiting(id: int, owner: int) -> Vector3:
	if id == 0: return game.queue_position(owner)
	var center := entry(id)
	var offsets := [Vector3(-.9, 0, .6), Vector3(.9, 0, .6), Vector3(-.9, 0, 1.4), Vector3(.9, 0, 1.4), Vector3(0, 0, 2.2), Vector3(1.7, 0, 1.4)]
	for i in range(offsets.size()):
		var point: Vector3 = center + offsets[(owner + i) % offsets.size()]
		if (game.east_navigation if center.y > 1 else game.navigation).walkable(point): return point
	return center

func add(pos: Vector3) -> void:
	var node: Node3D = game.Art.model(game, "depots_15/local_depot", pos)
	if pos.y > 1:
		node.scale = Vector3.ONE * .65
		node.rotation.y = -PI / 2
	var label: Label3D = game.Art.caption(node, "", Vector3(0, 1.4, 0))
	label.pixel_size = .004
	if pos.y > 1: label.position.y = 3.0
	var contents := Node3D.new()
	node.add_child(contents)
	sites.append({"pos": pos, "capacity": 12, "filters": KINDS.duplicate(), "stock": {"food": 0, "wood": 0, "fiber": 0, "water": 0},
		"depot_site": true, "built": false, "active": true, "work": 0.0, "required": WORK, "materials": {"wood": 0, "fiber": 0}, "builder": -1, "hauler": -1,
		"gate": DeliveryLedger.new(), "node": node, "label": label, "contents": contents})
	refresh(sites.size() - 1)

func refresh(id: int) -> void:
	if id <= 0: return
	var site := sites[id]
	set_ghost(site.node, not site.built)
	site.label.text = "Dépôt %d · %d/%d" % [id, used(id), site.capacity]
	if not site.built: site.label.text = "Dépôt %d · %s\n%s" % [id, game.construction.status(site) if site.active else "Plan annulé", game.construction.quantities(site)]
	if booked(id) > 0: site.label.text += " · %d places réservées" % booked(id)
	for child in site.contents.get_children():
		site.contents.remove_child(child)
		child.queue_free()
	for i in range(KINDS.size()):
		var kind: String = KINDS[i]
		if stocks(id)[kind] <= 0: continue
		var model: Node3D = game.Art.model(site.contents, "reference_01/thimble_bucket" if kind == "water" else kind, Vector3(-.37 + (i % 2) * .74, .12, -.23 + (i / 2) * .46))
		model.scale = Vector3.ONE * (.28 if kind == "water" else .22 + .025 * minf(stocks(id)[kind], 6))

func set_filter(id: int, kind: String, enabled: bool) -> void:
	if enabled and not kind in sites[id].filters: sites[id].filters.append(kind)
	elif not enabled: sites[id].filters.erase(kind)
	game._news("Filtre modifié. Le stock présent et les livraisons déjà réservées restent conservés.")

func settled() -> bool:
	if not incoming.is_empty() or not outgoing.is_empty(): return false
	for site in sites:
		if site.gate.destination_owner != -1 or not site.gate.destination_queue.is_empty(): return false
	return true

func snapshot() -> Array:
	var result: Array = []
	for id in range(sites.size()):
		var inventory: Dictionary = {}
		for kind in KINDS: inventory[kind] = int(stocks(id).get(kind, 0))
		var saved := {"stock": inventory, "capacity": sites[id].capacity, "filters": sites[id].filters.duplicate()}
		if id > 0:
			for key in ["built", "active", "work", "materials"]: saved[key] = sites[id][key].duplicate() if sites[id][key] is Dictionary else sites[id][key]
		result.append(saved)
	return result

func set_ghost(node: Node, enabled: bool) -> void:
	if node is MeshInstance3D:
		if enabled:
			if node.material_override == null: game._set_ghost(node)
		else: node.material_override = null
	for child in node.get_children(): set_ghost(child, enabled)

func restore_site(id: int, saved: Dictionary) -> void:
	var site := sites[id]
	site.built = saved.get("built", true)
	site.active = saved.get("active", true)
	site.work = float(saved.get("work", WORK))
	var material: Dictionary = saved.get("materials", COST)
	site.materials = {"wood": int(material.wood), "fiber": int(material.fiber)}
	refresh(id)

func start_work(c: WorkerDelivery) -> bool:
	for id in range(1, sites.size()):
		var site := sites[id]
		if not site.active or site.built or site.builder >= 0 or site.hauler >= 0 or not game.construction.supplied(site): continue
		var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(from, entry(id), c.owner).is_empty(): continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		site.builder = c.owner
		c.depot_order = id
		c.change("depot_build_walk")
		return true
	return false

func tick(c: WorkerDelivery, dt: float) -> bool:
	if c.depot_order < 0: return false
	var id := c.depot_order
	var site := sites[id]
	if game.hiding or c.worker.sleep_requested or c.need_interrupt:
		cancel_worker(c)
		return true
	if c.state == "depot_build_walk":
		if c.move(entry(id), dt, false):
			c.actor.rotation.y = PI / 2 if site.pos.y > 1 else PI
			c.change("depot_build_work")
	else:
		c.pose("work", fposmod(c.timer, 1.2))
		site.work = minf(WORK, site.work + dt)
		if site.work >= WORK:
			site.built = true
			site.builder = -1
			c.depot_order = -1
			c.change("idle")
			game._news("Dépôt terminé : 12 places de stockage disponibles.")
		refresh(id)
	return true

func cancel_worker(c: WorkerDelivery) -> bool:
	if c.depot_order < 0: return false
	sites[c.depot_order].builder = -1
	c.depot_order = -1
	c.change("return_home")
	return true

func cancel_plan(id: int) -> bool:
	if id <= 0 or id >= sites.size() or sites[id].built or not sites[id].active: return false
	var site := sites[id]
	game.construction.cancel_site(site)
	if site.builder >= 0: cancel_worker(game.workers[site.builder].delivery)
	site.materials = {"wood": 0, "fiber": 0}
	site.work = 0.0
	site.active = false
	refresh(id)
	game._news("Chantier annulé : matériaux livrés à récupérer sur place, charges en transit rapportées. Le plan peut être relancé.")
	return true

func resume_plan(id: int) -> void:
	if id > 0 and id < sites.size() and not sites[id].built:
		sites[id].active = true
		refresh(id)
