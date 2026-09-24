extends RefCounted
## Simulation of needs and furniture orders. Movement remains with WorkerDelivery.
const BED_STATES := ["bed_walk", "bed_enter", "sleep", "bed_exit"]
const CRAFT_STATES := ["build_walk", "build_work"]
const ENTRY := Vector3(0, WorkerDelivery.GROUND_Y, 1.7)
const THRESHOLD := 25.0
const WAKE := 95.0
var game: Node3D
var beds: Array[Dictionary] = []

func add(pos: Vector3, private: bool) -> void:
	var owner := -1
	for i in range(game.workers.size()):
		if owned_bed(i) < 0:
			owner = i
			break
	var node := Node3D.new()
	game.add_child(node)
	node.position = pos
	var label: Label3D = game.Art.caption(node, "", Vector3(0, 1.9, 0))
	label.pixel_size = .004
	beds.append({"pos": pos, "private": private, "owner": owner, "occupant": -1, "builder": -1,
		"work": 0.0, "required": 20.0 if private else 12.0, "built": false, "node": node, "label": label})
	visual(beds.size() - 1)

func visual(index: int) -> void:
	var bed := beds[index]
	for child in bed.node.get_children():
		if child != bed.label:
			bed.node.remove_child(child)
			child.queue_free()
	game.Art.model(bed.node, "reference_01/matchbox_bed" if bed.built else "sleep_12/bed_materials", Vector3.ZERO)
	if bed.built and bed.private: game.Art.model(bed.node, "sleep_12/privacy_partition", Vector3.ZERO)
	caption(index)

func caption(index: int) -> void:
	var bed := beds[index]
	bed.label.text = ("Alcôve" if bed.private else "Lit") + " %d" % (index + 1)
	if not bed.built: bed.label.text += " · %d %%" % int(100 * bed.work / bed.required)
	elif bed.occupant >= 0: bed.label.text += " · Zzz"
	elif bed.owner >= 0: bed.label.text += " · H%d" % (bed.owner + 1)

func owned_bed(owner: int) -> int:
	for i in range(beds.size()):
		if beds[i].owner == owner: return i
	return -1

func ready_count(private_only: bool = false) -> int:
	var count := 0
	for bed in beds:
		if bed.built and (bed.private or not private_only): count += 1
	return count

func cancel_order(index: int) -> bool:
	if index < 0 or index >= beds.size() or beds[index].built: return false
	var bed := beds[index]
	for worker in game.workers:
		var c: WorkerDelivery = worker.delivery
		if c.furniture_order == index:
			c.furniture_order = -1
			c.change("idle")
			c.pose("idle", 0)
		elif c.furniture_order > index: c.furniture_order -= 1
		if c.rest_bed > index: c.rest_bed -= 1
	var kind := "private_bed" if bed.private else "bed"
	for key in game.COSTS[kind]: game.stock[key] += game.COSTS[kind][key]
	for building in game.buildings:
		if building.pos == bed.pos and building.kind == kind:
			game.buildings.erase(building)
			break
	game.navigation_obstacles.erase(game.Navigation.building(bed.pos, kind))
	game.navigation.configure(game.navigation_obstacles, game.navigation_stands)
	bed.node.queue_free()
	beds.remove_at(index)
	for i in range(beds.size()): caption(i)
	game._news("Chantier annulé. Les matériaux réservés sont rendus au dépôt.")
	return true

func entrance(bed: Dictionary) -> Vector3:
	return bed.pos + ENTRY

func assign(index: int, owner: int) -> bool:
	if index < 0 or index >= beds.size() or owner < -1 or owner >= game.workers.size(): return false
	# No reassignment underneath a sleeping resident or a resident on their way.
	if beds[index].occupant >= 0: return false
	var previous := owned_bed(owner) if owner >= 0 else -1
	if previous >= 0:
		if beds[previous].occupant >= 0: return false
		beds[previous].owner = -1
		caption(previous)
	beds[index].owner = owner
	caption(index)
	return true

func request_rest(owner: int) -> void:
	var worker: Dictionary = game.workers[owner]
	if worker.delivery.state in BED_STATES or worker.delivery.state == "floor_sleep": return
	worker.delivery.cancel()
	worker.sleep_requested = true
	game._news("L’habitant %d déposera sa charge avant de se reposer." % (owner + 1))

func update_need(c: WorkerDelivery, dt: float) -> void:
	if c.state in ["sleep", "floor_sleep"]: return
	var active := not c.state in ["idle", "return_home"]
	c.worker.energy = maxf(0, c.worker.energy - dt * (.16 if active else .10))
	if c.worker.energy <= THRESHOLD and not c.worker.sleep_requested:
		c.cancel()
		c.worker.sleep_requested = true

func available_bed(c: WorkerDelivery) -> int:
	var own := owned_bed(c.owner)
	var choices: Array[int] = []
	if own >= 0: choices.append(own)
	for i in range(beds.size()):
		if i != own and beds[i].owner == -1: choices.append(i)
	for index in choices:
		var bed := beds[index]
		if bed.built and bed.occupant in [-1, c.owner] and (bed.owner == c.owner or bed.owner == -1):
			var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
			if not game.travel_path(from, entrance(bed), c.owner).is_empty(): return index
	return -1

func interrupt(c: WorkerDelivery) -> bool:
	if c.state in BED_STATES + CRAFT_STATES or c.state == "floor_sleep": c.personal_recall = true
	if c.state in ["bed_enter", "sleep"]:
		# Finish entering before reversing the authored motion; never snap through a partition.
		c.rest_recall = true
		if c.state == "sleep": c.change("bed_exit")
		return true
	if c.state == "bed_exit":
		c.rest_recall = true
		return true
	if c.rest_bed >= 0:
		beds[c.rest_bed].occupant = -1
		caption(c.rest_bed)
		c.rest_bed = -1
	if c.furniture_order >= 0:
		beds[c.furniture_order].builder = -1
		c.furniture_order = -1
	if c.state in BED_STATES + CRAFT_STATES or c.state == "floor_sleep":
		c.pose("idle", 0)
		c.change("idle" if c.inside_refuge else "return_home")
		return true
	return false

func tick(c: WorkerDelivery, dt: float) -> bool:
	match c.state:
		"bed_walk":
			if c.move(entrance(beds[c.rest_bed]), dt, false):
				c.actor.position = beds[c.rest_bed].pos
				c.actor.rotation.y = 0
				c.change("bed_enter")
				c.pose("bed_enter", 0)
			return true
		"bed_enter":
			c.pose("bed_enter", minf(c.timer, 1.8))
			if c.timer >= 1.8: c.change("bed_exit" if c.rest_recall else "sleep")
			return true
		"sleep":
			var bed := beds[c.rest_bed]
			c.pose("sleep", fposmod(c.timer, 4))
			c.worker.energy = minf(100, c.worker.energy + dt * (3.0 if bed.private else 2.0))
			c.worker.comfort = 85.0 if bed.private else 65.0
			c.worker.privacy = 100.0 if bed.private else 20.0
			if c.worker.energy >= WAKE:
				c.worker.sleep_requested = false
				c.change("bed_exit")
			return true
		"bed_exit":
			c.pose("bed_exit", minf(c.timer, 1.8))
			if c.timer >= 1.8:
				var bed := beds[c.rest_bed]
				c.actor.position = entrance(bed)
				bed.occupant = -1
				caption(c.rest_bed)
				c.rest_bed = -1
				c.change("return_home" if c.rest_recall or game.hiding else "idle")
				c.rest_recall = false
				c.pose("idle", 0)
			return true
		"floor_sleep":
			var slot: Vector3 = game.refuge.slot(c.owner)
			c.actor.position = Vector3(game.HOME.x + (.35 if c.owner % 2 == 0 else -.35), slot.y, slot.z)
			c.actor.rotation.y = -PI / 2 if c.owner % 2 == 0 else PI / 2
			c.pose("floor_rest", fposmod(c.timer, 4))
			c.worker.energy = minf(100, c.worker.energy + dt * .6)
			c.worker.comfort = 15.0
			c.worker.privacy = 0.0
			if game.pending_save or c.worker.energy >= WAKE:
				c.worker.sleep_requested = false
				c.change("idle")
				c.actor.position = slot
				c.actor.rotation.y = 0
				c.pose("idle", 0)
			return true
		"build_walk", "build_work":
			var bed := beds[c.furniture_order]
			if c.state == "build_walk":
				if c.move(entrance(bed), dt, false):
					c.actor.rotation.y = PI
					c.change("build_work")
			else:
				c.pose("work", fposmod(c.timer, 1.2))
				bed.work = minf(bed.required, bed.work + dt)
				caption(c.furniture_order)
				if bed.work >= bed.required:
					bed.built = true
					bed.builder = -1
					visual(c.furniture_order)
					c.furniture_order = -1
					c.change("idle")
					c.pose("idle", 0)
					game._news("Un couchage est prêt. Son propriétaire l’utilisera lorsqu’il sera fatigué.")
			return true
	# Intercept only at a safe handover: charges and access crossings are settled first.
	if c.personal_recall:
		if not c.inside_refuge: return false
		c.personal_recall = false
	if c.job >= 0 or c.state not in ["idle", "return_home"]: return false
	if game.pending_save: return false
	if c.worker.sleep_requested:
		var index := -1 if game.hiding else available_bed(c)
		if index >= 0:
			if c.inside_refuge:
				c.change("leave_home")
				return true
			game.refuge.release(c.owner)
			c.waiting_door = false
			c.rest_bed = index
			beds[index].occupant = c.owner
			caption(index)
			c.change("bed_walk")
			return true
		if c.inside_refuge:
			c.change("floor_sleep")
			return true
		if c.state != "return_home": c.change("return_home")
		return false
	if game.hiding or c.state != "idle" or c.exploring: return false
	for i in range(beds.size()):
		var bed := beds[i]
		if bed.built or bed.builder >= 0: continue
		var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(from, entrance(bed), c.owner).is_empty(): continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		bed.builder = c.owner
		c.furniture_order = i
		c.change("build_walk")
		return true
	return false

func description(c: WorkerDelivery) -> String:
	return {"bed_walk": "Va à son lit", "bed_enter": "Se couche", "sleep": "Dort dans son lit",
		"bed_exit": "Se lève", "floor_sleep": "Dort au sol · inconfortable", "build_walk": "Va fabriquer un lit",
		"build_work": "Fabrique un couchage"}.get(c.state, "")

func snapshot() -> Array:
	var result: Array = []
	for bed in beds:
		result.append({"owner": bed.owner, "work": bed.work, "built": bed.built})
	return result
