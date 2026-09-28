extends RefCounted
## L02: illuminated missions extend the existing L01 contract, without bypassing its queue.
const COST := {"wood": 8, "fiber": 4}
const WORK := 24.0
const NEAR := Vector3(4, -.0105, 18.5)
const FAR := Vector3(4, -.0105, 22)
const FOOD := Vector3(7, -.0105, 26)
var game: Node3D
var known := false
var scout := false
var harvest := false
var planned := false
var active := false
var built := false
var materials := {"wood": 0, "fiber": 0}
var work := 0.0
var amount := 36
var reserved := 0
var tasks: Dictionary = {}
var owner := -1
var queue: Array[int] = []
var status := "Reconnaître la cuisine depuis l’alcôve."
var scene: Node3D
var deck: Node3D
var piles: Node3D
var biscuit: Node3D
var marker: Label3D
var signature := ""

func setup() -> void:
	scene = game.Art.model(game, "kitchen_30/sector", Vector3.ZERO)
	deck = game.Art.model(game, "kitchen_30/bridge", Vector3.ZERO)
	biscuit = game.Art.model(game, "kitchen_30/biscuit", FOOD + Vector3(1, .01, 0))
	piles = Node3D.new()
	game.add_child(piles)
	marker = game.Art.caption(game, "", NEAR + Vector3(0, 1.5, 0), Color("eac37e"))
	marker.pixel_size = .006
	refresh()

func refresh() -> void:
	if not is_instance_valid(scene): return
	scene.visible = game.fissure.visited
	deck.visible = built
	biscuit.visible = known and amount > 0
	marker.visible = game.fissure.visited
	marker.text = "CUISINE · BISCUIT %d" % amount if known and built else ("PONT · %d %%" % int(work / WORK * 100) if planned else "CUISINE · À RECONNAÎTRE")
	var next := str(materials) + str(built)
	if next != signature:
		signature = next
		for child in piles.get_children():
			piles.remove_child(child)
			child.queue_free()
		if not built:
			for kind in COST:
				if materials[kind] > 0:
					var prop: Node3D = game.Art.model(piles, kind, NEAR + Vector3(-.75 if kind == "wood" else .75, .01, -.8))
					prop.scale = Vector3.ONE * .4
	piles.visible = game.fissure.visited

func request_scout() -> bool:
	if not game.fissure.visited or known: return false
	if scout:
		scout = false
		for id in tasks.keys():
			if tasks[id].kind == "scout": game.workers[id].delivery.cancel()
		return true
	scout = true
	status = "Reconnaissance désignée ; un éclaireur prendra une lanterne."
	return true

func plan() -> bool:
	if not known or planned or not game.fissure.widened():
		game._news("Reconnaître la cuisine et élargir la fissure avant de livrer le pont.")
		return false
	planned = true
	active = true
	status = "Pont commandé : 8 bois, 4 fibres et 24 s de construction sur place."
	refresh()
	return true

func toggle_build() -> void:
	if not planned or built: return
	active = not active
	if not active:
		for id in tasks.keys():
			if tasks[id].kind in ["supply", "build"]: game.workers[id].delivery.cancel()
	status = "Chantier repris." if active else "Chantier suspendu ; matériaux livrés conservés, charges en retour."

func designate_food() -> bool:
	if not built or not known or amount <= 0: return false
	harvest = not harvest
	if not harvest:
		for id in tasks.keys():
			if tasks[id].kind == "food": game.workers[id].delivery.cancel()
	return true

func token(id: int) -> String: return "kitchen:%d" % id
func pending(kind: String) -> int:
	var count := 0
	for t in tasks.values():
		if t.kind == "supply" and t.resource == kind and not t.deposited: count += t.quantity
	return count
func supplied() -> bool: return materials.wood == COST.wood and materials.fiber == COST.fiber
func required(c: WorkerDelivery, kind: String, depot: int = -1) -> float:
	var seconds: float = game.fissure.required_fuel(c) + (42.0 if kind in ["food", "scout"] else 35.0)
	if depot >= 0:
		var base: Vector3 = game.fissure.NEAR
		var home: Vector3 = game.HOME + game.Refuge.OUTSIDE
		if kind == "supply":
			var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
			seconds += maxf(0, game.torches.travel_seconds(c, from, game.depots.entry(depot)) + game.torches.travel_seconds(c, game.depots.entry(depot), base) - game.torches.travel_seconds(c, from, base))
		else:
			seconds += maxf(0, game.torches.travel_seconds(c, base, game.depots.entry(depot)) + game.torches.travel_seconds(c, game.depots.entry(depot), home) - game.torches.travel_seconds(c, base, home))
	return seconds

func try_start(c: WorkerDelivery, priority: String) -> bool:
	if tasks.has(c.owner): return true
	if tasks.size() >= 2 or game.hiding or game.ended or not game.fissure.visited or not game.designations.healthy(c) or not game.torches.available(c) or game.torches.occupied(c.owner): return false
	var kind := ""
	var resource := ""
	var quantity := 0
	var depot := -1
	if priority == "collect":
		if scout and not known:
			for t in tasks.values():
				if t.kind == "scout": return false
			kind = "scout"
		elif harvest and built and amount > reserved:
			var limit: int = game.local_harvest.missing("food")
			if limit == 0:
				return false
			var choice: Dictionary = game.depots.sink(game.fissure.NEAR, "food", mini(limit, mini(3 + game.workshops, amount - reserved)), c.owner)
			if choice.is_empty(): status = "Récolte en attente : aucun dépôt accessible avec de la place."; return false
			kind = "food"
			resource = "food"
			quantity = choice.quantity
			depot = choice.id
	elif active and not built:
		if priority == "build" and supplied():
			for t in tasks.values():
				if t.kind == "build": return false
			kind = "build"
		elif priority == "transport":
			for item in COST:
				var missing: int = COST[item] - materials[item] - pending(item)
				if missing <= 0: continue
				var origin: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
				depot = game.depots.source(origin, item, c.owner, game.fissure.NEAR)
				if depot < 0: continue
				kind = "supply"
				resource = item
				quantity = mini(missing, mini(3 + game.workshops, game.depots.available(depot, item)))
				break
	if kind.is_empty(): return false
	var usable := false
	for item in game.torches.items:
		if game.torches.servicing(game.torches.items.find(item)): continue
		if item.kind == "lantern" and item.owner < 0 and item.reserved < 0 and item.fuel >= required(c, kind, depot) + 5: usable = true
	if not usable:
		status = "En attente : lanterne suffisamment chargée (environ 150 s) et habitant disponible."
		return false
	if not game.torches.equip(c.owner, "lantern"): return false
	var t := {"kind": kind, "stage": "equip", "resource": resource, "quantity": quantity, "depot": depot, "collected": false, "deposited": false, "released": false, "clock": 0.0, "route": PackedVector3Array(), "index": 0, "returning": false}
	tasks[c.owner] = t
	if kind == "supply": game.depots.reserve_out(token(c.owner), depot, resource, quantity)
	if kind == "food":
		reserved += quantity
		game.depots.reserve_in(token(c.owner), {"id": depot, "kind": resource, "quantity": quantity})
	status = "Tâches attribuées selon Récolte, Transport et Construction."
	return true

func update() -> void:
	for id in tasks.keys():
		var t: Dictionary = tasks[id]
		if t.stage != "equip": continue
		var c: WorkerDelivery = game.workers[id].delivery
		if not game.torches.occupied(id): release(c); continue
		if not game.designations.healthy(c) or game.hiding:
			game.torches.recall(c, "Besoins ou rappel prioritaires")
			release(c)
			continue
		if not game.torches.can_haul(id): continue
		if game.torches.items[game.torches.held(id)].fuel < required(c, t.kind, t.depot) or not game.fissure.start(id):
			game.torches.recall(c, "Autonomie ou accès cuisine insuffisant")
			release(c)
			continue
		var m: Dictionary = game.fissure.missions[id]
		m.kitchen = true
		t.stage = "fetch" if t.kind == "supply" else "out"
		if t.kind == "supply": m.phase = "kitchen"
		game._news("H%d · %s. Lanterne, aller et retour réservés." % [id + 1, description(id)])
	if harvest and amount == 0 and tasks.is_empty(): harvest = false
	refresh()

func release(c: WorkerDelivery) -> void:
	if not tasks.has(c.owner): return
	var t: Dictionary = tasks[c.owner]
	if t.kind == "food" and not t.collected and not t.released: reserved -= t.quantity
	game.depots.release(token(c.owner))
	if t.depot >= 0: game.depots.gate(t.depot).release_destination(-1500000000 - c.owner)
	queue.erase(c.owner)
	if owner == c.owner: owner = -1
	tasks.erase(c.owner)
	c.actor.cargo.hide()
	refresh()

func cancel(c: WorkerDelivery, m: Dictionary) -> void:
	var t: Dictionary = tasks[c.owner]
	if m.returning: return
	m.returning = true
	t.returning = true
	t.ant_wait = 0.0
	if not t.collected and not t.released:
		if t.kind == "food": reserved -= t.quantity
		game.depots.release(token(c.owner))
		t.released = true
	if m.phase in ["cross", "clear"]: return
	game.fissure.queue.erase(c.owner)
	if game.fissure.owner == c.owner: game.fissure.owner = -1
	if t.stage == "bridge_cross": return # Complete the one-person bridge before reversing.
	queue.erase(c.owner)
	if owner == c.owner: owner = -1
	if m.side == "near":
		if c.worker.carrying > 0: m.phase = "delivery_wait"
		else: game.fissure.finish(c)
	elif m.phase != "kitchen": m.phase = "back"
	elif c.sector_id == "kitchen": route(t, [Vector3(4, -.0105, 24), FAR + Vector3((c.owner - .5) * .5, 0, .7)], "bridge_back")
	else: route(t, [Vector3(4, -.0105, 16), game.fissure.FAR + Vector3(0, 0, 1)], "alcove_back")

func route(t: Dictionary, points: Array, stage: String) -> void:
	t.route = PackedVector3Array(points)
	t.index = 0
	t.stage = stage
	# Reset the local action clock, not the expedition clock.
	t.clock = 0.0

func walk(c: WorkerDelivery, t: Dictionary, dt: float) -> bool:
	if t.index >= t.route.size(): return true
	if game.fissure.local_move(c, t.route[t.index], dt): t.index += 1
	return t.index >= t.route.size()

func enter(c: WorkerDelivery) -> void:
	var t: Dictionary = tasks[c.owner]
	route(t, [game.fissure.LOOK, Vector3(4, -.0105, 16), NEAR + Vector3((c.owner - 1.5) * .45, 0, -.7)], "to_bridge")

func tick(c: WorkerDelivery, m: Dictionary, dt: float) -> bool:
	if not m.get("kitchen", false): return false
	var t: Dictionary = tasks[c.owner]
	if m.phase.begins_with("delivery_"):
		delivery(c, m, t, dt)
		return true
	if m.phase != "kitchen": return false
	t.clock += dt
	if game.ant.worker_wait(c, t, dt): return true
	match t.stage:
		"fetch":
			var gate: DeliveryLedger = game.depots.gate(t.depot)
			var ticket := -1500000000 - c.owner
			if gate.destination_owner != ticket:
				if c.move(game.depots.waiting(t.depot, c.owner), dt, false): gate.acquire_slot(ticket)
			elif c.move(game.depots.entry(t.depot), dt, false):
				t.stage = "pickup"
				t.clock = 0.0
				c.actor.rotation.y = 0
			if not c.navigation_issue.is_empty(): cancel(c, m)
		"pickup":
			c.pose("pick_up", minf(t.clock, 1.8))
			if t.clock >= c.CAPTURE_TIME and not t.collected:
				c.worker.carrying = game.depots.withdraw(token(c.owner), true)
				c.worker.kind = t.resource
				t.collected = true
				attach(c)
			if t.clock >= 1.8:
				game.depots.gate(t.depot).release_destination(-1500000000 - c.owner)
				m.phase = "approach"
				t.stage = "out"
		"to_bridge":
			if walk(c, t, dt):
				if t.kind == "supply":
					t.stage = "supply_drop"
					t.clock = 0.0
				elif t.kind == "build": t.stage = "build"
				else: t.stage = "bridge_wait"
		"supply_drop":
			c.pose("put_down", minf(t.clock, 1.8))
			if t.clock >= c.DEPOSIT_TIME and not t.deposited:
				materials[t.resource] += t.quantity
				c.worker.carrying = 0
				t.deposited = true
				game.depots.release(token(c.owner))
				c.actor.cargo.hide()
			if t.clock >= 1.8: back(c, m, t)
		"build":
			c.actor.rotation.y = 0
			c.pose("work", fposmod(t.clock, 1.2))
			work = minf(WORK, work + dt)
			if work >= WORK:
				built = true
				active = false
				game._news("Le pont de la cuisine est prêt : les caisses peuvent traverser.")
				back(c, m, t)
		"bridge_wait":
			cross(c, t, false)
		"bridge_back":
			if walk(c, t, dt): cross(c, t, true)
		"bridge_cross":
			if walk(c, t, dt):
				owner = -1
				if t.get("cross_back", false):
					c.sector_id = game.fissure.ALCOVE_SECTOR
					back(c, m, t)
				else:
					c.sector_id = "kitchen"
					if m.returning:
						t.returning = true
						route(t, [FAR + Vector3(0, 0, .7)], "bridge_back")
					else: route(t, game.ant.food_route(c.owner), "food_walk")
		"food_walk":
			if walk(c, t, dt):
				t.stage = "observe" if t.kind == "scout" else "harvest"
				t.clock = 0.0
		"observe":
			c.pose("idle", fposmod(t.clock, 4))
			if t.clock >= 4:
				known = true
				scout = false
				game._news("Cuisine reconnue : biscuit repéré. Construisez le pont pour rapporter ses provisions.")
				return_bridge(c, m, t)
		"harvest":
			c.pose("work", fposmod(t.clock, 1.2))
			if t.clock >= 3:
				t.stage = "food_pickup"
				t.clock = 0.0
		"food_pickup":
			c.pose("pick_up", minf(t.clock, 1.8))
			if t.clock >= c.CAPTURE_TIME and not t.collected:
				amount -= t.quantity
				reserved -= t.quantity
				t.collected = true
				c.worker.kind = "food"
				c.worker.carrying = t.quantity
				attach(c)
			if t.clock >= 1.8: return_bridge(c, m, t)
		"alcove_back":
			if walk(c, t, dt):
				m.phase = "back"
	return true

func attach(c: WorkerDelivery) -> void:
	c.actor.cargo.reparent(c.cargo_socket, false)
	c.actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .52), Vector3.ZERO)
	c.actor.cargo.show()

func cross(c: WorkerDelivery, t: Dictionary, returning: bool) -> void:
	if not built and c.worker.carrying > 0: return
	if not queue.has(c.owner): queue.append(c.owner)
	c.pose("pick_up" if c.worker.carrying > 0 else "idle", 1.8 if c.worker.carrying > 0 else 0)
	if owner >= 0 or queue[0] != c.owner: return
	owner = c.owner
	queue.pop_front()
	t.returning = returning
	t.cross_back = returning
	var points: Array = [NEAR, FAR, FAR + Vector3(0, 0, .7)]
	if not built: points = [NEAR, Vector3(1, -.0105, 18.5), Vector3(1, -.0105, 22), FAR, FAR + Vector3(0, 0, .7)]
	if returning:
		points.reverse()
		points.append(NEAR + Vector3(0, 0, -.7))
	route(t, points, "bridge_cross")

func back(_c: WorkerDelivery, m: Dictionary, t: Dictionary) -> void:
	m.returning = true
	t.returning = true
	route(t, [Vector3(4, -.0105, 16), game.fissure.FAR + Vector3(0, 0, 1)], "alcove_back")

func return_bridge(c: WorkerDelivery, m: Dictionary, t: Dictionary) -> void:
	m.returning = true
	t.returning = true
	route(t, [Vector3(4, -.0105, 24), FAR + Vector3((c.owner - .5) * .5, 0, .7)], "bridge_back")

func delivery(c: WorkerDelivery, m: Dictionary, t: Dictionary, dt: float) -> void:
	var ticket := -1500000000 - c.owner
	match m.phase:
		"delivery_wait":
			if not game.depots.reroute(token(c.owner), c.actor.position, c.owner):
				c.navigation_issue = "Cuisine : livraison bloquée, dégager un dépôt"
				return
			var depot: int = game.depots.incoming[token(c.owner)].id
			if depot != t.depot:
				game.depots.gate(t.depot).release_destination(ticket)
				t.depot = depot
			if game.depots.gate(depot).acquire_slot(ticket): m.phase = "delivery_walk"
			else: c.move(game.depots.waiting(depot, c.owner), dt, true)
		"delivery_walk":
			if c.move(game.depots.entry(t.depot), dt, true):
				m.phase = "delivery_drop"
				t.clock = 0.0
				c.actor.rotation.y = 0
			elif not c.navigation_issue.is_empty():
				game.depots.gate(t.depot).release_destination(ticket)
				m.phase = "delivery_wait"
		"delivery_drop":
			t.clock += dt
			c.pose("put_down", minf(t.clock, 1.8))
			if t.clock >= c.DEPOSIT_TIME and c.worker.carrying > 0:
				game.depots.deposit(token(c.owner))
				c.worker.carrying = 0
				t.deposited = true
				c.actor.cargo.hide()
				c.completed_deliveries += 1
			if t.clock >= 1.8: game.fissure.finish(c)

func description(id: int) -> String:
	if not tasks.has(id): return ""
	var t: Dictionary = tasks[id]
	return ("Cuisine · attend la fourmi" if float(t.get("ant_wait", 0)) > 0 else "Cuisine · " + {"scout": "reconnaissance", "supply": "livraison du pont", "build": "construction du pont", "food": "provisions"}[t.kind] + (" · retour" if t.returning else ""))

func food_reserve_status() -> String:
	var target: int = game.local_harvest.targets.food
	if target == 0: return "Objectif 0 : nouveaux départs suspendus ; les caisses engagées sont livrées."
	if target < 0: return "Provisions sans limite de réserve."
	var text := "Réserve alimentaire : %d / %d, stocks et charges engagées." % [game.local_harvest.expected("food"), target]
	if game.local_harvest.missing("food") == 0: text += " Objectif couvert ; reprise après consommation."
	return text

func summary() -> String:
	var text := "Alcôve → cuisine · détour à vide / pont pour caisses\n"
	text += "Cuisine reconnue" if known else "Cuisine inconnue : désigner une reconnaissance"
	text += "\nPont : " + ("Terminé" if built else ("%s · %d/24 s" % ["En chantier" if active else "Suspendu", int(work)] if planned else "À commander après reconnaissance"))
	text += "\nBois %d/8 · Fibres %d/4\nBiscuit : %s · %d réservées\n%s\n%s" % [materials.wood, materials.fiber, str(amount) + " provisions" if known else "inconnu", reserved, "Récolte désignée" if harvest else "Récolte arrêtée", status]
	text += "\n" + food_reserve_status()
	for id in tasks: text += "\nH%d · %s" % [id + 1, description(id)]
	return text

func snapshot() -> Dictionary:
	return {"known": known, "scout": scout, "harvest": harvest, "planned": planned, "active": active, "built": built, "materials": materials.duplicate(), "work": work, "amount": amount, "reserved": reserved, "tasks": tasks.duplicate(true), "owner": owner, "queue": queue.duplicate(), "status": status}

func restore(data: Dictionary) -> void:
	for key in data:
		if key == "queue": queue.assign(data.queue)
		else: set(key, data[key])
	refresh()

static func valid(v: Variant, r: Dictionary) -> bool:
	if not v is Dictionary or not v.has_all(["known", "scout", "harvest", "planned", "active", "built", "materials", "work", "amount", "reserved", "tasks", "owner", "queue", "status"]): return false
	for k in ["known", "scout", "harvest", "planned", "active", "built"]:
		if not v[k] is bool: return false
	if not v.materials is Dictionary or not v.tasks is Dictionary or not v.queue is Array or not v.status is String or v.tasks.size() > 2: return false
	for k in COST:
		if not v.materials.get(k) is int or v.materials[k] < 0 or v.materials[k] > COST[k]: return false
	if not (v.work is float or v.work is int) or not is_finite(v.work) or v.work < 0 or v.work > WORK: return false
	if v.built and (v.work != WORK or v.materials != COST): return false
	if not v.amount is int or v.amount < 0 or v.amount > 36 or not v.reserved is int or v.reserved < 0 or v.reserved > v.amount: return false
	var booked := 0
	for id in v.tasks:
		if not id is int or id < 0 or id >= r.workers.size(): return false
		var t = v.tasks[id]
		if not t is Dictionary or not t.has_all(["kind", "stage", "resource", "quantity", "depot", "collected", "deposited", "released", "clock", "route", "index", "returning"]): return false
		if t.kind not in ["scout", "supply", "build", "food"] or not t.route is PackedVector3Array or not t.index is int or t.index < 0 or t.index > t.route.size(): return false
		if t.stage not in ["equip", "out", "fetch", "pickup", "to_bridge", "supply_drop", "build", "bridge_wait", "bridge_back", "bridge_cross", "food_walk", "observe", "harvest", "food_pickup", "alcove_back"]: return false
		if t.has("ant_wait") and (not (t.ant_wait is float or t.ant_wait is int) or not is_finite(t.ant_wait) or t.ant_wait < 0 or t.ant_wait > 9): return false
		if not t.quantity is int or t.quantity < 0 or t.quantity > 10 or not t.depot is int or t.depot < -1 or t.depot >= r.gates.size(): return false
		if not (t.clock is float or t.clock is int) or not is_finite(t.clock) or t.clock < 0: return false
		for k in ["collected", "deposited", "released", "returning"]:
			if not t[k] is bool: return false
		if not r.torch_missions.has(id): return false
		if t.kind == "supply" and (t.resource not in COST or t.quantity < 1 or t.depot < 0): return false
		if t.kind == "food" and (t.resource != "food" or t.quantity < 1 or t.depot < 0 or not v.built): return false
		if t.kind in ["scout", "build"] and (t.resource != "" or t.quantity != 0 or t.depot != -1): return false
		if t.stage == "bridge_cross" and v.owner != id: return false
		if t.kind == "supply" and not t.collected and not t.released:
			var outgoing = r.outgoing.get("kitchen:%d" % id, {})
			if outgoing.get("quantity", -1) != t.quantity or outgoing.get("id", -2) != t.depot or outgoing.get("kind", "") != t.resource: return false
		if t.stage != "equip" and not r.fissure.missions.get(id, {}).get("kitchen", false): return false
		if t.kind == "food" and not t.collected and not t.released: booked += t.quantity
		if t.collected and not t.deposited and r.workers[id].worker.carrying != t.quantity: return false
		var claim = r.incoming.get("kitchen:%d" % id, {})
		if ((t.kind == "food" and not t.released) or (t.kind == "supply" and t.collected)) and not t.deposited:
			if claim.get("quantity", -1) != t.quantity or claim.get("id", -2) != t.depot: return false
	for id in r.fissure.missions:
		var m: Dictionary = r.fissure.missions[id]
		if m.get("kitchen", false) and not v.tasks.has(id): return false
		if m.phase == "kitchen" and not m.get("kitchen", false): return false
	if booked != v.reserved: return false
	if not v.owner is int or (v.owner != -1 and (not v.tasks.has(v.owner) or v.tasks[v.owner].stage != "bridge_cross")): return false
	var queued := {}
	for id in v.queue:
		if queued.has(id) or not v.tasks.has(id): return false
		queued[id] = true
	return true

func cancel_pre(c: WorkerDelivery) -> bool:
	if not tasks.has(c.owner) or tasks[c.owner].stage != "equip": return false
	game.torches.recall(c, "Ordre cuisine interrompu")
	release(c)
	return true

func hit(screen: Vector2) -> bool:
	if not marker.visible or game.camera.is_position_behind(marker.global_position): return false
	return game.camera.unproject_position(marker.global_position).distance_to(screen) < 85
