extends RefCounted
## Individual needs: urgency arbitration, real stock consumption and self-supply.
const THRESHOLD := 35.0
const CRITICAL := 15.0
const METERS := {"food": "nutrition", "water": "hydration"}
const DURATIONS := {"food": 4.0, "water": 3.0}
const GAINS := {"food": 55.0, "water": 65.0}
var game: Node3D

func consuming(c: WorkerDelivery) -> bool:
	return c.state in ["eat", "drink"]

func priority(c: WorkerDelivery) -> String:
	var choice := ""
	var lowest := THRESHOLD + 1
	for kind in ["water", "food"]:
		var value: float = c.worker[METERS[kind]]
		if value <= THRESHOLD and value < lowest:
			lowest = value
			choice = kind
	return choice

func movement_factor(worker: Dictionary) -> float:
	return .65 if minf(worker.energy, minf(worker.nutrition, worker.hydration)) < CRITICAL else 1.0

func update(c: WorkerDelivery, dt: float) -> void:
	# Sleep reduces consumption but never freezes hunger or thirst.
	var rate := .65 if c.state in ["sleep", "floor_sleep"] else 1.0
	c.worker.nutrition = maxf(0, c.worker.nutrition - .24 * rate * dt)
	c.worker.hydration = maxf(0, c.worker.hydration - .32 * rate * dt)
	if consuming(c): return
	var kind := priority(c)
	if kind.is_empty():
		c.need_interrupt = false
		if c.job < 0: c.needs_supply = -1
		return
	# Ordinary hunger waits for the sleeper; critical hunger wakes them safely.
	if c.state in ["bed_enter", "sleep", "bed_exit", "floor_sleep"]:
		if c.worker[METERS[kind]] > CRITICAL: return
	if c.need_interrupt or c.needs_supply >= 0: return
	c.need_interrupt = true
	c.cancel()

func source(c: WorkerDelivery, kind: String) -> int:
	var selected := -1
	var distance := INF
	var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
	for i in range(game.patches.size()):
		var patch: Dictionary = game.patches[i]
		if patch.kind != kind or not patch.discovered or patch.amount <= patch.reserved: continue
		var path: PackedVector3Array = game.travel_path(from, patch.pos + Vector3(.9, WorkerDelivery.GROUND_Y, .2), c.owner)
		if path.is_empty(): continue
		var length := 0.0
		for j in range(1, path.size()): length += path[j - 1].distance_to(path[j])
		if length < distance:
			distance = length
			selected = i
	return selected

func tick(c: WorkerDelivery, dt: float) -> bool:
	if consuming(c):
		var kind := "food" if c.state == "eat" else "water"
		c.pose(c.state, fposmod(c.timer, 2.0))
		var used := minf(dt, float(DURATIONS[kind]) - c.consumption_time)
		c.consumption_time += used
		c.worker[METERS[kind]] = minf(100, c.worker[METERS[kind]] + float(GAINS[kind]) * used / float(DURATIONS[kind]))
		if c.consumption_time >= float(DURATIONS[kind]) - .00001:
			c.need_interrupt = false
			c.change("idle")
			c.pose("idle", 0)
		return true
	if c.job >= 0 or c.state not in ["idle", "return_home"] or game.pending_save: return false
	var kind := priority(c)
	if kind.is_empty(): return false
	# No activity takes priority over an explicit recall or a save in progress.
	if game.hiding and not c.inside_refuge: return false
	if game.stock.get(kind, 0) <= 0 and (game.hiding or source(c, kind) < 0):
		var other := "food" if kind == "water" else "water"
		if c.worker[METERS[other]] <= THRESHOLD and game.stock.get(other, 0) > 0: kind = other
	if game.stock.get(kind, 0) > 0:
		c.needs_supply = -1
		if not c.inside_refuge:
			if c.state != "return_home": c.change("return_home")
			return false # The ordinary door controller executes the return.
		# The ration is committed once, at the start. This short action finishes on recall.
		game.stock[kind] -= 1
		c.consumption_time = 0
		c.actor.position = game.refuge.slot(c.owner)
		c.actor.rotation.y = 0
		c.change("eat" if kind == "food" else "drink")
		c.pose(c.state, 0)
		return true
	if game.hiding:
		c.navigation_issue = "Réserve d’eau vide" if kind == "water" else "Réserve de nourriture vide"
		return false
	var patch := source(c, kind)
	if patch >= 0:
		c.needs_supply = patch
		if c.inside_refuge: c.change("leave_home")
		elif c.state == "return_home":
			game.refuge.release(c.owner)
			c.waiting_door = false
			c.personal_recall = false
			c.change("idle")
		return false # Delivery uses this temporary source, preserving the player's assignment.
	c.needs_supply = -1
	# Do not strand residents in an infinite waiting task when all sources are exhausted.
	c.navigation_issue = "Aucune eau accessible" if kind == "water" else "Aucune nourriture accessible"
	return false

func description(c: WorkerDelivery) -> String:
	if c.state == "eat": return "Mange au refuge"
	if c.state == "drink": return "Boit au refuge"
	if c.needs_supply >= 0: return "Cherche de l’eau" if game.patches[c.needs_supply].kind == "water" else "Cherche à manger"
	if c.need_interrupt and c.state == "return_home": return "Rentre boire" if priority(c) == "water" else "Rentre manger"
	return ""

func restore_water_location(data: Dictionary) -> bool:
	# A pre-water save may already have a building on the new default source.
	# Relocate only the added source, never the player's existing buildings.
	var candidates: Array[Vector3] = []
	if data.version >= 3:
		candidates.append(Vector3(data.water_source[0], 0, data.water_source[2]))
	else:
		candidates.append(Vector3(7, 0, 2))
		for x in range(-8, 9, 2):
			for z in range(-5, 6, 2): candidates.append(Vector3(x, 0, z))
	var original: Vector3 = game.patches[7].pos
	var original_footprint: Rect2 = game.Navigation.footprint(original, Vector2(.55, .5))
	var original_stand: Rect2 = game.Navigation.footprint(game.water_stand.position, Vector2(.22, .18))
	for point in candidates:
		var footprint: Rect2 = game.Navigation.footprint(point, Vector2(.55, .5))
		var stand: Vector3 = point + Vector3(.9, 0, .2) + game.workers[0].delivery.contact.origin
		stand.y = 0
		var occupied := false
		for obstacle in game.navigation_obstacles:
			if obstacle != original_footprint and footprint.grow(.3).intersects(obstacle): occupied = true
		var obstacles: Array[Rect2] = game.navigation_obstacles.duplicate()
		obstacles.erase(original_footprint)
		for building in data.buildings:
			var pos := Vector3(building.pos[0], 0, building.pos[2])
			var box: Rect2 = game.Navigation.building(pos, building.kind)
			if footprint.grow(.3).intersects(box) or point.distance_to(pos) < 1.8 or (point + Vector3(.9, 0, .5)).distance_to(pos) < 1.4: occupied = true
			obstacles.append(box)
			if building.kind not in ["bed", "private_bed"]: obstacles.append(game.Navigation.footprint(pos + Vector3(1.05, 0, .65), Vector2(.12, .12)))
		if occupied: continue
		obstacles.append(footprint)
		var stands: Array[Rect2] = game.navigation_stands.duplicate()
		stands.erase(original_stand)
		stands.append(game.Navigation.footprint(stand, Vector2(.22, .18)))
		var trial = game.Navigation.new()
		trial.configure(obstacles, stands)
		var depot: Vector3 = game.workers[0].delivery.destination_position
		if trial.path(depot, point + Vector3(.9, 0, .2)).is_empty(): continue
		for slot in game.home_slots + game.depot_slots:
			if trial.path(depot, slot).is_empty(): occupied = true
		if occupied: continue
		game.navigation_obstacles.erase(original_footprint)
		game.navigation_obstacles.append(footprint)
		game.navigation_stands.erase(original_stand)
		game.navigation_stands.append(game.Navigation.footprint(stand, Vector2(.22, .18)))
		game.patches[7].pos = point
		game.patches[7].node.position = point
		game.water_stand.position = stand
		game.navigation.configure(game.navigation_obstacles, game.navigation_stands)
		return true
	return false
