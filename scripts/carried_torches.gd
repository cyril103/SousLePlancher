extends RefCounted
## Workshop orders share physical material logistics; expeditions own the hands.
const COST := {"wood": 2, "fiber": 1}
const DURATION := 90.0
const MARGIN := 12.0
const OBSERVE := 12.0
const RANGE := 4.5
const RECIPES := {"torch": {"wood": 2, "fiber": 1}, "lantern": {"wood": 4, "fiber": 3}}
const CAPACITIES := {"torch": 90.0, "lantern": 180.0}
const WORK := {"torch": 8.0, "lantern": 16.0}
const NAMES := {"torch": "Torche", "lantern": "Lanterne"}
var game: Node3D
var orders: Array[Dictionary] = []
var items: Array[Dictionary] = []
var missions: Dictionary = {}
var crafting: Dictionary = {}
var picking := -1

func entrance(site: Dictionary) -> Vector3:
	return site.pos + Vector3(0, -.0105, 1.15)

func request_craft(kind: String = "torch") -> bool:
	if not RECIPES.has(kind): return false
	if items.size() >= 4096: return reject("La réserve de torches est pleine.")
	if game.hiding or game.pending_save or game.ended: return reject("Reprenez les sorties avant de lancer une fabrication.")
	for building in game.buildings:
		if building.kind != "workshop": continue
		var busy := false
		for order in orders:
			if order.pos == building.pos and not order.built: busy = true
		if busy: continue
		var site := {"torch_site": true, "kind": kind, "pos": building.pos, "materials": {"wood": 0, "fiber": 0}, "hauler": -1, "builder": -1, "work": 0.0, "required": WORK[kind], "built": false}
		orders.append(site)
		refresh_site(site)
		game._news("%s commandée : %d bois et %d fibres, puis %.0f s d’assemblage." % [NAMES[kind], RECIPES[kind].wood, RECIPES[kind].fiber, WORK[kind]])
		return true
	return reject("Il faut un atelier libre. Un ordre d’éclairage à la fois par atelier.")

func refresh_site(site: Dictionary) -> void:
	if not site.has("supplies"):
		var node := Node3D.new()
		game.add_child(node)
		node.position = site.pos + Vector3(0, .85, .35)
		site["supplies"] = node
	for child in site.supplies.get_children():
		site.supplies.remove_child(child)
		child.queue_free()
	if site.built: return
	for kind in ["wood", "fiber"]:
		if site.materials[kind] <= 0: continue
		var prop: Node3D = game.Art.model(site.supplies, kind, Vector3(-.12 if kind == "wood" else .25, 0, 0))
		prop.scale = Vector3.ONE * .15

func available(c: WorkerDelivery) -> bool:
	return c.state == "idle" and c.job < 0 and c.supply_job < 0 and c.furniture_order < 0 and not c.exploring and c.worker.patch < 0 and c.worker.carrying == 0 and not c.door_active and not c.climbing and not c.bridge_active and not c.personal_recall

func held(owner: int) -> int:
	for i in range(items.size()):
		if items[i].owner == owner: return i
	return -1

func occupied(owner: int) -> bool:
	return held(owner) >= 0 or missions.has(owner) or crafting.has(owner)

func lantern(owner: int) -> bool:
	var index := held(owner)
	return index >= 0 and items[index].kind == "lantern"

func hands_occupied(owner: int) -> bool:
	return held(owner) >= 0 and not lantern(owner)

func can_haul(owner: int) -> bool:
	return lantern(owner) and missions.has(owner) and missions[owner].phase == "ready"

func margin(owner: int) -> float:
	return 24.0 if lantern(owner) else MARGIN

func reject(message: String) -> bool:
	game._news(message)
	return false

func equip(owner: int, kind: String = "torch") -> bool:
	var c: WorkerDelivery = game.workers[owner].delivery
	if game.hiding or game.pending_save or not available(c) or occupied(owner): return reject("Libérez cet habitant et reprenez les sorties avant de l’équiper.")
	var from: Vector3 = game.home_position(owner) if c.inside_refuge else c.actor.position
	var best := -1
	var distance := INF
	for i in range(items.size()):
		var item := items[i]
		if item.kind != kind or item.owner >= 0 or item.reserved >= 0 or item.fuel <= 0: continue
		var d: float = game.depots.distance(from, item.pos, owner)
		if d < INF and (best < 0 or item.fuel > items[best].fuel or (is_equal_approx(item.fuel, items[best].fuel) and d < distance)):
			distance = d
			best = i
	if best < 0: return reject("Aucun équipement de ce type utilisable et accessible. Fabriquez-en un à l’atelier.")
	items[best].reserved = owner
	missions[owner] = {"phase": "equip", "item": best, "target": Vector3.ZERO, "observed": 0.0, "reason": ""}
	c.change("leave_home" if c.inside_refuge else "idle")
	game._news("L’habitant va prendre son équipement. Choisissez ensuite une destination.")
	return true

func choose_target(owner: int) -> void:
	if held(owner) < 0 or not missions.has(owner) or missions[owner].phase != "ready":
		reject("Équipez d’abord cet habitant et attendez qu’il ait pris son éclairage.")
		return
	picking = owner
	game._cancel_build()
	game._show_tray("")
	game._news("Cliquez au sol ou à l’étage. La lanterne laisse les mains libres. Échap annule." if lantern(owner) else "Cliquez une destination au sol dans le secteur actuel. Échap annule. Échelles et caisses incompatibles.")

func route_length(from: Vector3, to: Vector3, owner: int) -> float:
	var path: PackedVector3Array = game.travel_path(from, to, owner)
	if path.is_empty(): return INF
	var previous := from
	var length := 0.0
	for point in path:
		if absf(point.y - previous.y) > 1 and not lantern(owner): return INF
		length += previous.distance_to(point)
		previous = point
	return length

func travel_seconds(c: WorkerDelivery, from: Vector3, to: Vector3) -> float:
	var velocity: float = (1.7 + game.workshops * .35) * game.needs.movement_factor(c.worker)
	if not lantern(c.owner): return route_length(from, to, c.owner) / velocity
	var path: PackedVector3Array = game.travel_path(from, to, c.owner)
	if path.is_empty(): return INF
	var seconds := 0.0
	var previous := from
	for point in path:
		if absf(point.y - previous.y) > 1:
			seconds += 7.4 if point.y > previous.y else 8.0
			seconds += 8.0 * (game.ladder.queue.size() + (1 if game.ladder.owner >= 0 and game.ladder.owner != c.owner else 0))
		elif game.bridge.is_edge(previous, point):
			seconds += previous.distance_to(point) / 1.2
			seconds += 2.5 * (game.bridge.queue.size() + (1 if game.bridge.owner >= 0 and game.bridge.owner != c.owner else 0))
		else: seconds += previous.distance_to(point) / velocity
		previous = point
	return seconds

func return_seconds(c: WorkerDelivery) -> float:
	if c.climbing:
		return maxf(0, (7.4 if c.climb_up else 8.0) - c.climb_time) + travel_seconds(c, game.Ladder.UPPER if c.climb_up else game.Ladder.LOWER, game.HOME + game.Refuge.OUTSIDE)
	if c.bridge_active:
		return c.actor.position.distance_to(c.bridge_target) / 1.2 + travel_seconds(c, c.bridge_target, game.HOME + game.Refuge.OUTSIDE)
	return travel_seconds(c, c.actor.position, game.HOME + game.Refuge.OUTSIDE)

func depart(owner: int, target: Vector3) -> bool:
	picking = -1
	if not missions.has(owner) or missions[owner].phase != "ready": return false
	var c: WorkerDelivery = game.workers[owner].delivery
	var item := items[held(owner)]
	if absf(target.y - c.actor.position.y) > 1 and not lantern(owner):
		return reject("Destination à l’étage : l’échelle exige deux mains libres. Impossible de monter avec une torche en main.")
	if lantern(owner) and target.y > 1 and target.x > 7 and target.x < 9:
		target = game.Bridge.NEAR if target.x < 8 else game.Bridge.FAR
	var outward := travel_seconds(c, c.actor.position, target)
	var inward := travel_seconds(c, target, game.HOME + game.Refuge.OUTSIDE)
	if is_inf(outward + inward): return reject("Destination inaccessible : aucun trajet aller-retour praticable avec cet équipement.")
	var required := outward + inward + OBSERVE + margin(owner)
	if item.fuel < required: return reject("Autonomie insuffisante : %.0f s disponibles, %.0f s nécessaires avec retour et marge." % [item.fuel, required])
	if c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35: return reject("Cet habitant doit satisfaire ses besoins avant de partir.")
	missions[owner].phase = "out"
	missions[owner].target = target
	missions[owner].observed = 0.0
	item.lit = true
	c.change("idle")
	game._news("Éclaireur en route · %.0f s prévues, retour et marge compris." % required)
	return true

func start_haul(owner: int, patch: int) -> bool:
	if not can_haul(owner) or game.hiding or game.pending_save or game.ended: return false
	if patch < 0 or patch >= game.patches.size() or not game.patches[patch].discovered: return reject("Reconnaissez d’abord cette réserve.")
	if game.patches[patch].amount <= game.patches[patch].reserved: return reject("Cette réserve est vide ou déjà réservée.")
	var c: WorkerDelivery = game.workers[owner].delivery
	if c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35: return reject("Cet habitant doit satisfaire ses besoins avant de partir.")
	var source: Vector3 = game.patches[patch].pos + Vector3(.9, c.GROUND_Y, .2)
	var choice: Dictionary = game.depots.sink(source, game.patches[patch].kind, mini(3 + game.workshops, game.patches[patch].amount - game.patches[patch].reserved), owner)
	if choice.is_empty(): return reject("Aucun dépôt accessible n’a de place pour cette charge.")
	var required := travel_seconds(c, c.actor.position, source) + travel_seconds(c, source, game.depots.entry(choice.id)) + travel_seconds(c, game.depots.entry(choice.id), game.HOME + game.Refuge.OUTSIDE) + 8.0 + margin(owner)
	var item := items[held(owner)]
	if item.fuel < required or is_inf(required): return reject("Autonomie insuffisante pour récolter, livrer et rentrer avec une marge.")
	missions[owner].phase = "haul"
	missions[owner]["started"] = false
	missions[owner]["hauling"] = true
	c.worker.patch = patch
	item.lit = true
	c.change("idle")
	game._news("Un trajet de récolte éclairé : l’habitant rapportera une caisse puis rangera sa lanterne au refuge.")
	return true

func recall(c: WorkerDelivery, reason: String = "Rappel demandé") -> bool:
	if crafting.has(c.owner):
		var order: Dictionary = orders[crafting[c.owner]]
		order.builder = -1
		crafting.erase(c.owner)
		c.change("return_home")
		return true
	if not missions.has(c.owner): return false
	var mission: Dictionary = missions[c.owner]
	if mission.phase == "equip":
		items[mission.item].reserved = -1
		missions.erase(c.owner)
		c.change("idle" if c.inside_refuge else "return_home")
		return true
	if mission.phase != "return":
		items[mission.item].lit = items[mission.item].fuel > 0
		mission.phase = "return"
		mission.reason = reason
		game._news("H%d · %s. Retour au refuge avec son éclairage." % [c.owner + 1, reason])
	if mission.get("hauling", false): c.worker.patch = -1
	# Finish committed crossings and settle a real cargo transaction before turning back.
	if c.job >= 0:
		if not mission.get("cargo_cancelled", false):
			c.cancel(true)
			# Deferred crossing cancellation must still run once on the landing.
			mission.cargo_cancelled = not (c.climbing or c.bridge_active or c.door_active)
	elif c.climbing: c.cancel_after_ladder = true
	elif c.bridge_active: c.bridge_cancel = true
	elif c.door_active: c.recall_after_door = true
	elif c.state != "return_home": c.change("return_home")
	return true

func add_item(pos: Vector3, fuel: float = DURATION, kind: String = "torch") -> void:
	var model: Node3D = game.Art.model(game, "lanterns_17/belt_lantern" if kind == "lantern" else "torches_16/hand_torch", pos + Vector3(0, .34 if kind == "lantern" else .15, 0))
	if kind == "torch": model.rotation.z = PI / 2
	items.append({"kind": kind, "pos": pos, "fuel": fuel, "owner": -1, "reserved": -1, "lit": false, "node": model})

func extinguish_and_store(c: WorkerDelivery) -> void:
	var index := held(c.owner)
	if index < 0: return
	var item := items[index]
	item.lit = false
	item.owner = -1
	item.pos = game.depots.entry(0)
	item.node.position = item.pos + Vector3(.15 * (index % 4), .34 if item.kind == "lantern" else .15, 0)
	item.node.show()
	c.actor.torch.hide()
	c.actor.torch_light.hide()
	c.actor.lantern.hide()
	c.actor.lantern_light.hide()
	missions.erase(c.owner)

func advance(c: WorkerDelivery, dt: float) -> void:
	var index := held(c.owner)
	if index < 0: return
	var item := items[index]
	if item.lit:
		item.fuel = maxf(0, item.fuel - dt)
		if item.fuel == 0: item.lit = false
	var belt: bool = item.kind == "lantern"
	var flame: Node3D = c.actor.lantern_flame if belt else c.actor.torch_flame
	var light: OmniLight3D = c.actor.lantern_light if belt else c.actor.torch_light
	flame.visible = item.lit
	light.visible = item.lit
	light.light_energy = (1.65 + .10 * sin(game.elapsed * 8 + c.owner) + .07 * sin(game.elapsed * 13.7)) * minf(1, item.fuel / 8.0)
	var material: ShaderMaterial = c.actor.lantern_material if belt else c.actor.torch_material
	material.set_shader_parameter("clock", game.elapsed)
	for i in range(c.actor.torch_sparks.size()):
		var ember: MeshInstance3D = c.actor.torch_sparks[i]
		var age := fposmod(game.elapsed * .25 + i * .31, 1.4)
		ember.visible = not belt and item.lit and age < .9
		ember.position = Vector3(sin(i * 3.7 + age * 5) * .025, .5 + age * .3, cos(i * 4.2 + age) * .02)
		ember.scale = Vector3.ONE * maxf(.1, 1 - age)
	if c.inside_refuge and missions.has(c.owner) and missions[c.owner].phase == "return": extinguish_and_store(c)
	if belt and missions.has(c.owner):
		var m: Dictionary = missions[c.owner]
		if m.phase == "haul" and c.job >= 0: m.started = true
		if (c.climbing or c.bridge_active) and m.phase in ["out", "observe", "haul"] and item.fuel <= return_seconds(c) + margin(c.owner):
			recall(c, "Réserve de combustible atteinte pendant le passage")

func assisted(c: WorkerDelivery) -> bool:
	# The initial refuge already has a permanent torch. Its unobstructed apron
	# remains safe when an escort puts their own torch away behind the door.
	var apron: Vector3 = game.HOME + game.Refuge.OUTSIDE
	if c.actor.position.y < 1 and c.actor.position.distance_to(apron) < 3 and game.navigation.segment_clear(c.actor.position, apron): return true
	for item in items:
		if not item.lit or item.owner < 0 or item.owner == c.owner: continue
		var other: WorkerDelivery = game.workers[item.owner].delivery
		if other.job >= 0 or other.climbing or other.bridge_active or absf(c.actor.position.y - other.actor.position.y) > .5: continue
		var nav: GroundNavigation = (game.east_navigation if c.actor.position.x > 8 else game.upper_navigation) if c.actor.position.y > 1 else game.navigation
		if c.actor.position.distance_to(other.actor.position) < RANGE - 1 and nav.segment_clear(c.actor.position, other.actor.position):
			missions[c.owner]["escort"] = other.owner
			recall(other, "Accompagne H%d à court de combustible" % (c.owner + 1))
			return true
	return false

func tick(c: WorkerDelivery, dt: float) -> bool:
	if not missions.has(c.owner): return craft_tick(c, dt)
	var m: Dictionary = missions[c.owner]
	if m.phase == "equip":
		if c.inside_refuge or c.state == "leave_home": return false
		if c.move(items[m.item].pos, dt, false):
			items[m.item].owner = c.owner
			items[m.item].reserved = -1
			items[m.item].node.hide()
			if items[m.item].kind == "lantern": c.actor.lantern.show()
			else: c.actor.torch.show()
			m.phase = "ready"
			c.change("idle")
			game._news("H%d équipé. Éclairage → Destination ; la lumière s’allume au départ." % (c.owner + 1))
		return true
	var item := items[m.item]
	if game.hiding or game.pending_save or c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35:
		recall(c, "Besoins ou rappel prioritaire")
	if m.phase in ["out", "observe", "haul"]:
		var back := return_seconds(c)
		if c.job >= 0 and c.worker.carrying > 0:
			back = travel_seconds(c, c.actor.position, c.destination_position) + travel_seconds(c, c.destination_position, game.HOME + game.Refuge.OUTSIDE) + 4.0
		if item.fuel <= back + margin(c.owner) or not item.lit: recall(c, "Marge de sécurité atteinte")
	if m.phase == "haul":
		if c.job < 0 and (m.started or not c.navigation_issue.is_empty()):
			recall(c, "Livraison terminée" if m.started else "Récolte indisponible")
		else: return false # Normal, reserved harvest and two-handed cargo animations.
	if m.phase == "return":
		# An escort stays with its slower companion and approaches again at corners.
		# It cannot run ahead, extinguish its lamp, and abandon the assisted resident.
		if item.lit:
			for buddy_owner in missions:
				if missions[buddy_owner].get("escort", -1) != c.owner: continue
				var buddy: WorkerDelivery = game.workers[buddy_owner].delivery
				if buddy.inside_refuge: continue
				if c.actor.position.distance_to(buddy.actor.position) > 1.8 or not game.navigation.segment_clear(c.actor.position, buddy.actor.position):
					game.refuge.release(c.owner)
					c.waiting_door = false
					c.move(buddy.actor.position, dt, false)
					return true
		if not c.inside_refuge and not item.lit and item.fuel <= 0 and not assisted(c):
			c.navigation_issue = "Éclairage épuisé : envoyer un éclaireur allumé à proximité pour accompagner le retour"
			c.pose("pick_up" if c.worker.carrying > 0 else "idle", 1.8 if c.worker.carrying > 0 else 0)
			return true
		if c.job >= 0: return false # Deliver or refund the crate before entering the refuge.
		if not c.inside_refuge and is_inf(route_length(c.actor.position, game.home_position(c.owner), c.owner)):
			c.navigation_issue = "Retour bloqué : dégager le chemin ; rappel en attente, assistance nécessaire"
			c.pose("idle", 0)
			return true
		# Normal refuge door handling, while needs and other tasks remain suspended.
		c.navigation_issue = ""
		if c.state != "return_home": c.change("return_home")
		return false
	if m.phase == "ready":
		c.pose("idle", fposmod(c.timer, 4))
		return true
	if m.phase == "out":
		if c.move(m.target, dt, false):
			m.phase = "observe"
			c.change("idle")
	elif m.phase == "observe":
		c.pose("idle", fposmod(c.timer, 4))
		m.observed += dt
		if m.observed >= OBSERVE:
			if item.kind == "lantern" and c.actor.position.y > 1 and game.east_navigation.area.has_point(Vector2(c.actor.position.x, c.actor.position.z)):
				game.discover_east()
			recall(c, "Reconnaissance terminée")
	return true

func craft_tick(c: WorkerDelivery, dt: float) -> bool:
	if crafting.has(c.owner):
		var site: Dictionary = orders[crafting[c.owner]]
		if c.state == "torch_work":
			c.pose("work", fposmod(c.timer, 1.2))
			site.work = minf(site.required, site.work + dt)
			if site.work == site.required:
				site.built = true
				refresh_site(site)
				site.builder = -1
				add_item(entrance(site), CAPACITIES[site.kind], site.kind)
				crafting.erase(c.owner)
				c.change("idle")
				game._news("%s prête à l’atelier : %.0f s d’autonomie. Travaux → Éclairage et éclaireurs." % [NAMES[site.kind], CAPACITIES[site.kind]])
		elif c.move(entrance(site), dt, false):
			c.actor.rotation.y = PI
			c.change("torch_work")
		return true
	return false

func start_work(c: WorkerDelivery) -> bool:
	if game.hiding or game.pending_save or c.worker.sleep_requested or c.personal_recall or not available(c) or occupied(c.owner): return false
	for i in range(orders.size()):
		var site := orders[i]
		if site.built or site.builder >= 0 or site.hauler >= 0 or not game.construction.supplied(site): continue
		var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(from, entrance(site), c.owner).is_empty(): continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		site.builder = c.owner
		crafting[c.owner] = i
		c.change("torch_work_walk")
		return true
	return false

func description(c: WorkerDelivery) -> String:
	if crafting.has(c.owner): return "Assemble : " + NAMES[orders[crafting[c.owner]].kind].to_lower()
	if not missions.has(c.owner): return ""
	if not c.navigation_issue.is_empty(): return c.navigation_issue
	var m: Dictionary = missions[c.owner]
	if m.phase == "haul" or (m.phase == "return" and c.job >= 0): return "" # Let the delivery controller describe its current cargo stage.
	return {"equip": "Va chercher son éclairage", "ready": NAMES[items[m.item].kind] + " équipée · destination à choisir", "out": "Éclaire le passage", "observe": "Observe les environs", "return": "Retour éclairé · " + m.reason}.get(m.phase, "")

func snapshot() -> Dictionary:
	var saved_items: Array = []
	for item in items: saved_items.append({"kind": item.kind, "pos": game.Save.vector(item.pos), "fuel": item.fuel})
	var saved_orders: Array = []
	for order in orders:
		if not order.built: saved_orders.append({"kind": order.kind, "pos": game.Save.vector(order.pos), "materials": order.materials.duplicate(), "work": order.work})
	return {"items": saved_items, "orders": saved_orders}

func restore(data: Dictionary) -> void:
	for item in data.items: add_item(Vector3(item.pos[0], item.pos[1], item.pos[2]), float(item.fuel), item.get("kind", "torch"))
	for site in data.orders:
		var kind: String = site.get("kind", "torch")
		orders.append({"torch_site": true, "kind": kind, "pos": Vector3(site.pos[0], site.pos[1], site.pos[2]), "materials": {"wood": int(site.materials.wood), "fiber": int(site.materials.fiber)}, "hauler": -1, "builder": -1, "work": float(site.work), "required": WORK[kind], "built": false})
		refresh_site(orders[-1])
