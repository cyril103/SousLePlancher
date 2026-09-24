extends RefCounted
## Local inventories, space/material reservations and independent loading queues.
const KINDS := ["food", "wood", "fiber", "water"]
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
	return game.HOME + Vector3(1.6, -.0105, .25) if id == 0 else sites[id].pos + ENTRY

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
	return maxi(0, int(sites[id].capacity) - used(id) - booked(id))

func reserved(id: int, kind: String) -> int:
	var count := 0
	for item in outgoing.values():
		if item.id == id and item.kind == kind: count += item.quantity
	return count

func available(id: int, kind: String) -> int:
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
		if game.navigation.walkable(point): return point
	return center

func add(pos: Vector3) -> void:
	var node: Node3D = game.Art.model(game, "depots_15/local_depot", pos)
	var label: Label3D = game.Art.caption(node, "", Vector3(0, 1.4, 0))
	label.pixel_size = .004
	var contents := Node3D.new()
	node.add_child(contents)
	sites.append({"pos": pos, "capacity": 12, "filters": KINDS.duplicate(), "stock": {"food": 0, "wood": 0, "fiber": 0, "water": 0},
		"gate": DeliveryLedger.new(), "node": node, "label": label, "contents": contents})
	refresh(sites.size() - 1)

func refresh(id: int) -> void:
	if id <= 0: return
	var site := sites[id]
	site.label.text = "Dépôt %d · %d/%d" % [id, used(id), site.capacity]
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
		result.append({"stock": inventory, "capacity": sites[id].capacity, "filters": sites[id].filters.duplicate()})
	return result
