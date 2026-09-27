extends RefCounted
## A compact, grid-placed chamber envelope, with three physical construction stages.
const COSTS := [{"wood": 4, "fiber": 2}, {"wood": 6, "fiber": 4}, {"wood": 2, "fiber": 1}]
const TIMES := [10.0, 18.0, 8.0]
const TITLES := ["Sol", "Cloisons", "Porte"]
const MODELS := ["floor", "walls", "door"]
const ENTRY := Vector3(0, -.0105, 3.0)
var game: Node
var rooms: Array = []
var installed: Array[Rect2] = []
var selected := 0
var preview_pos := Vector3.INF
var preview_revision := -1
var preview_count := -1
var preview_valid := false

func sites() -> Array:
	var all: Array = []
	for room in rooms: all.append_array(room.parts)
	return all

static func bounds(pos: Vector3) -> Rect2:
	return Rect2(Vector2(pos.x - 1.82, pos.z - 1.72), Vector2(3.64, 4.14))

static func walls(pos: Vector3) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for spec in [[Vector3(-1.7, 0, .35), Vector2(.06, 1.95)], [Vector3(1.7, 0, .35), Vector2(.06, 1.95)], [Vector3(0, 0, -1.6), Vector2(1.7, .06)], [Vector3(-1.19, 0, 2.3), Vector2(.51, .06)], [Vector3(1.19, 0, 2.3), Vector2(.51, .06)]]:
		result.append(game_box(pos + spec[0], spec[1]))
	return result

static func game_box(pos: Vector3, half: Vector2) -> Rect2:
	return GroundNavigation.footprint(pos, half)

func reserved() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for room in rooms:
		if room.active: result.append_array(walls(room.pos))
	return result

func safe(extra: Array[Rect2]) -> bool:
	var nav := GroundNavigation.new()
	var boxes: Array[Rect2] = game.navigation_obstacles.duplicate()
	boxes.append_array(extra)
	nav.configure(boxes, game.navigation_stands)
	var start: Vector3 = game.depots.entry(0)
	var points: Array[Vector3] = game.home_slots.duplicate()
	points.append_array(game.depot_slots)
	points.append(game.HOME + game.Refuge.OUTSIDE)
	points.append(game.Ladder.LOWER)
	for i in range(game.workers.size() + 1): points.append(game.ladder.waiting(i, false))
	for bed in game.sleeping.beds: points.append(game.sleeping.entrance(bed))
	for room in rooms: points.append(room.pos + ENTRY)
	for building in game.buildings:
		if building.kind == "workshop": points.append(game.torches.entrance(building))
	for item in game.torches.items:
		if item.owner < 0: points.append(item.pos)
	for p in game.patches:
		if p.pos.y < 1: points.append(p.pos + Vector3(.9, 0, .2))
	for id in range(1, game.depots.sites.size()): points.append(game.depots.entry(id))
	for site in game.construction.sites():
		if site.get("active", true) and not site.built: points.append(game.construction.entrance(site))
	for p in game.construction.recovery: points.append(p.pos)
	for w in game.workers:
		var c: WorkerDelivery = w.delivery
		if not c.inside_refuge and not c.door_active and not c.state in ["bed_enter", "sleep", "bed_exit"]: points.append(c.actor.position)
	for point in points:
		if point.y < 1 and nav.path(start, point).is_empty(): return false
	return true

func can_plan(pos: Vector3) -> bool:
	if not pos.is_finite() or pos.y != 0 or pos != pos.snapped(Vector3.ONE): return false
	if rooms.size() >= 8 or absf(pos.x) > 18 or pos.z < -11 or pos.z > 9: return false
	var footprint := bounds(pos)
	for box in game.navigation_obstacles + game.navigation_stands:
		if footprint.intersects(box): return false
	for room in rooms:
		if footprint.grow(.35).intersects(bounds(room.pos)): return false
	for p in game.patches:
		if p.pos.y < 1 and footprint.grow(.4).has_point(Vector2(p.pos.x, p.pos.z)): return false
	var planned := reserved()
	planned.append_array(walls(pos))
	if not safe(planned): return false
	var nav := GroundNavigation.new()
	var boxes: Array[Rect2] = game.navigation_obstacles.duplicate()
	boxes.append_array(planned)
	nav.configure(boxes, game.navigation_stands)
	return not nav.path(game.depots.entry(0), pos + ENTRY).is_empty() and not nav.path(pos + ENTRY, pos + game.Sleep.ENTRY).is_empty()

func plan(pos: Vector3) -> bool:
	if not can_plan(pos):
		game._news("Chambre impossible ici : emprise occupée ou accès coupé. Prévoir une zone libre devant la porte.")
		return false
	var room := {"pos": pos, "active": true, "mode": "auto", "opening": 0.0, "parts": []}
	for phase in range(3):
		room.parts.append({"room_site": true, "phase": phase, "pos": pos, "active": phase == 0, "built": false, "materials": {"wood": 0, "fiber": 0}, "work": 0.0, "required": TIMES[phase], "hauler": -1, "builder": -1})
	rooms.append(room)
	selected = rooms.size() - 1
	create_visual(room)
	game._news("Chambre tracée : sol, cloisons puis porte seront approvisionnés et fabriqués. Le lit se commande séparément.")
	return true

func create_visual(room: Dictionary) -> void:
	var node := Node3D.new()
	game.add_child(node)
	node.position = room.pos
	room.node = node
	for phase in range(3):
		var model: Node3D = game.Art.model(node, "rooms_27/" + MODELS[phase], Vector3.ZERO)
		model.name = MODELS[phase]
	room.label = game.Art.caption(node, "", Vector3(0, 1.8, -.8))
	room.label.pixel_size = .004
	refresh(room)

func refresh(room: Dictionary) -> void:
	for phase in range(3):
		var model: Node3D = room.node.get_node(MODELS[phase])
		game.depots.set_ghost(model, not room.parts[phase].built)
	room.node.get_node("door").position = Vector3(room.opening * 1.25, 0, 2.4)
	room.label.text = "Chambre %d · %s" % [rooms.find(room) + 1, "Prête" if room.parts[2].built else ("Chantier" if room.active else "Plan suspendu")]

func refresh_site(site: Dictionary) -> void:
	for room in rooms:
		if room.pos == site.pos: refresh(room)

func rebuild_navigation() -> void:
	for box in installed: game.navigation_obstacles.erase(box)
	installed.clear()
	for room in rooms:
		if room.parts[1].built: installed.append_array(walls(room.pos))
		if room.parts[2].built and room.mode == "blocked": installed.append(game_box(room.pos + Vector3(0, 0, 2.3), Vector2(.68, .06)))
	game.navigation_obstacles.append_array(installed)
	game.navigation.configure(game.navigation_obstacles, game.navigation_stands)

func update(dt: float) -> void:
	for room in rooms:
		for phase in range(3): room.parts[phase].active = room.active and (phase == 0 or room.parts[phase - 1].built)
		var opened: bool = room.mode == "open"
		if room.mode == "auto":
			for w in game.workers:
				if w.node.position.y < 1 and w.node.position.distance_to(room.pos + Vector3(0, 0, 2.3)) < 1.45: opened = true
		# Idle craftsmen clear the threshold instead of holding the sliding leaf open forever.
		if room.parts[2].built:
			for w in game.workers:
				var c: WorkerDelivery = w.delivery
				if c.state == "idle" and not c.inside_refuge and not c.exploring and c.worker.carrying == 0 and c.actor.position.distance_to(room.pos + Vector3(0, 0, 2.3)) < 1.05:
					c.change("return_home")
		room.opening = move_toward(room.opening, 1.0 if opened and room.parts[2].built else 0.0, dt * 4)
		room.node.get_node("door").position.x = room.opening * 1.25
		if room.parts[2].built: room.label.text = "Chambre %d · %s" % [rooms.find(room) + 1, owner_name(room)]

func start_work(c: WorkerDelivery) -> bool:
	for site in sites():
		if not site.active or site.built or site.builder >= 0 or site.hauler >= 0 or not game.construction.supplied(site): continue
		var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(from, site.pos + ENTRY, c.owner).is_empty(): continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		site.builder = c.owner
		c.change("room_walk")
		return true
	return false

func owned(c: WorkerDelivery) -> Dictionary:
	for site in sites():
		if site.builder == c.owner: return site
	return {}

func cancel_worker(c: WorkerDelivery) -> bool:
	var site := owned(c)
	if site.is_empty(): return false
	site.builder = -1
	c.change("return_home")
	return true

func tick(c: WorkerDelivery, dt: float) -> bool:
	var site := owned(c)
	if site.is_empty(): return false
	if c.state == "room_walk":
		if c.move(site.pos + ENTRY, dt, false):
			c.actor.rotation.y = PI
			c.change("room_work")
		elif not c.navigation_issue.is_empty(): cancel_worker(c)
	else:
		c.pose("work", fposmod(c.timer, 1.2))
		# Never solidify a wall around a resident or across a now-used route.
		if site.phase == 1 and site.work + dt >= site.required and c.retry_time > 0: return true
		if site.phase == 1 and site.work + dt >= site.required and not safe(walls(site.pos)):
			c.navigation_issue = "Cloisons en attente : accès ou habitant à dégager."
			c.retry_time = 1.0
			return true
		c.navigation_issue = ""
		site.work = minf(site.required, site.work + dt)
		if site.work >= site.required:
			site.built = true
			site.builder = -1
			c.change("idle")
			if site.phase == 1: rebuild_navigation()
			refresh_site(site)
	return true

func set_mode(id: int, mode: String) -> bool:
	var room: Dictionary = rooms[id]
	if not room.parts[2].built or not mode in ["auto", "open", "blocked"]: return false
	if mode == "blocked" and not safe([game_box(room.pos + Vector3(0, 0, 2.3), Vector2(.68, .06))]):
		game._news("Fermeture refusée : elle couperait l’accès à un habitant, un lit ou un chantier.")
		return false
	room.mode = mode
	rebuild_navigation()
	return true

func cancel_plan(id: int) -> bool:
	var room: Dictionary = rooms[id]
	if room.parts[2].built or not room.active: return false
	for site in room.parts:
		game.construction.cancel_site(site)
		if site.builder >= 0: cancel_worker(game.workers[site.builder].delivery)
		site.materials = {"wood": 0, "fiber": 0}
		site.work = 0.0
		site.built = false
		site.active = false
	room.active = false
	rebuild_navigation()
	refresh(room)
	return true

func resume(id: int) -> void:
	var room: Dictionary = rooms[id]
	var extra := reserved()
	extra.append_array(walls(room.pos))
	if not safe(extra):
		game._news("Reprise refusée : dégager les accès du plan.")
		return
	room.active = true
	room.parts[0].active = true
	refresh(room)

func add_bed(id: int) -> bool:
	var room: Dictionary = rooms[id]
	if not room.parts[2].built:
		game._news("Terminer la chambre avant de commander son lit.")
		return false
	game.build_mode = "bed"
	var result: bool = game._place_build(room.pos)
	game._cancel_build()
	return result

func permits_build(pos: Vector3, kind: String) -> bool:
	for room in rooms:
		if bounds(room.pos).intersects(game.Navigation.building(pos, kind)) and not (kind == "bed" and pos == room.pos and room.parts[2].built): return false
	return true

func summary(id: int) -> String:
	var room: Dictionary = rooms[id]
	var text := "Chambre %d · %s" % [id + 1, {"auto": "porte automatique", "open": "porte ouverte", "blocked": "porte condamnée"}[room.mode] if room.parts[2].built else "Construction séquentielle"]
	for phase in range(3):
		var site: Dictionary = room.parts[phase]
		text += "\n%s : %s" % [TITLES[phase], "Terminé" if site.built else ((game.construction.status(site) if site.active else "En attente") + " · " + game.construction.quantities(site))]
	return text

func snapshot() -> Array:
	var result: Array = []
	for room in rooms:
		result.append({"pos": room.pos, "active": room.active, "mode": room.mode, "opening": room.opening, "parts": room.parts.duplicate(true)})
	return result

func restore(data: Array) -> void:
	rooms = data.duplicate(true)
	for room in rooms: create_visual(room)
	rebuild_navigation()

static func valid(value: Variant, runtime: Dictionary) -> bool:
	if not value is Array or value.size() > 8: return false
	var positions: Array = []
	var owners := {}
	for room in value:
		if not room is Dictionary or not room.has_all(["pos", "active", "mode", "opening", "parts"]): return false
		if not room.pos is Vector3 or not room.pos.is_finite() or room.pos.y != 0 or absf(room.pos.x) > 18 or room.pos.z < -11 or room.pos.z > 9 or room.pos != room.pos.snapped(Vector3.ONE): return false
		for p in positions:
			if bounds(p).intersects(bounds(room.pos)): return false
		positions.append(room.pos)
		if not room.active is bool or not room.mode in ["auto", "open", "blocked"] or not (room.opening is float or room.opening is int) or not is_finite(room.opening) or room.opening < 0 or room.opening > 1: return false
		if not room.parts is Array or room.parts.size() != 3: return false
		for phase in range(3):
			var s = room.parts[phase]
			if not s is Dictionary or not s.has_all(["room_site", "phase", "pos", "active", "built", "materials", "work", "required", "hauler", "builder"]): return false
			if s.room_site != true or s.phase != phase or s.pos != room.pos or not s.active is bool or not s.built is bool or s.required != TIMES[phase]: return false
			if not (s.work is float or s.work is int) or not is_finite(s.work) or s.work < 0 or s.work > s.required or s.built != (s.work == s.required): return false
			if not s.materials is Dictionary or not s.materials.has_all(["wood", "fiber"]): return false
			for kind in COSTS[phase]:
				if not s.materials[kind] is int or s.materials[kind] < 0 or s.materials[kind] > COSTS[phase][kind]: return false
			if s.work > 0 and s.materials != COSTS[phase]: return false
			if phase > 0 and s.work > 0 and not room.parts[phase - 1].built: return false
			for key in ["builder", "hauler"]:
				if not s[key] is int or s[key] < -1 or s[key] >= runtime.workers.size(): return false
			if s.builder >= 0:
				if owners.has(s.builder) or s.built or not s.active or not runtime.workers[s.builder].controller.state in ["room_walk", "room_work"]: return false
				owners[s.builder] = true
	for i in range(runtime.workers.size()):
		if str(runtime.workers[i].controller.state).begins_with("room_") and not owners.has(i): return false
	return true

func preview(pos: Vector3) -> bool:
	# Placement always revalidates; cache only the visual hint while hovering one cell.
	if pos != preview_pos or preview_revision != game.navigation.revision or preview_count != rooms.size():
		preview_pos = pos
		preview_revision = game.navigation.revision
		preview_count = rooms.size()
		preview_valid = can_plan(pos)
	return preview_valid

func room_at(pos: Vector3) -> int:
	if pos.y > .5: return -1
	for i in range(rooms.size()):
		var room: Dictionary = rooms[i]
		if not room.active or not room.parts[0].built or not room.parts[1].built or not room.parts[2].built: continue
		var inner := Rect2(Vector2(room.pos.x - 1.6, room.pos.z - 1.5), Vector2(3.2, 3.7))
		if inner.has_point(Vector2(pos.x, pos.z)): return i
	return -1

func bed_index(room: Dictionary) -> int:
	for i in range(game.sleeping.beds.size()):
		if room_at(game.sleeping.beds[i].pos) == rooms.find(room): return i
	return -1

func owner_name(room: Dictionary) -> String:
	var bed := bed_index(room)
	if bed < 0: return "Sans lit"
	var owner: int = game.sleeping.beds[bed].owner
	return "Usage collectif" if owner < 0 else "H%d" % (owner + 1)

func occupants(id: int) -> Array[int]:
	var result: Array[int] = []
	for i in range(game.workers.size()):
		var c: WorkerDelivery = game.workers[i].delivery
		if not c.inside_refuge and room_at(c.actor.position) == id: result.append(i)
	return result

func assign_owner(id: int, owner: int) -> bool:
	var bed := bed_index(rooms[id])
	if bed < 0: return false
	var result: bool = game.sleeping.assign(bed, owner)
	if not result: game._news("Attribution impossible pendant l’accès ou l’occupation d’un lit. Attendre sa libération.")
	return result

func rest_quality(bed: Dictionary, owner: int) -> Dictionary:
	var id := room_at(bed.pos)
	if id < 0:
		return {"privacy": 100.0 if bed.private else 20.0, "comfort": 85.0 if bed.private else 65.0, "rate": 3.0 if bed.private else 2.0, "reason": "Alcôve individuelle" if bed.private else "Lit sans pièce fermée"}
	var room: Dictionary = rooms[id]
	var privacy := 95.0 if bed.owner >= 0 and bed.owner == owner else 60.0
	var reason := "Chambre personnelle, seul et porte fermée" if bed.owner >= 0 and bed.owner == owner else "Chambre collective, seul et porte fermée"
	if room.mode == "open" or room.opening > .1:
		privacy = minf(privacy, 35.0)
		reason = "Porte ouverte : intimité réduite"
	for other in occupants(id):
		if other != owner:
			privacy = minf(privacy, 25.0)
			reason = "Présence d’un autre habitant"
	return {"privacy": privacy, "comfort": 75.0 + privacy * .1, "rate": 2.0 + privacy * .008, "reason": reason}

func privacy_summary(id: int) -> String:
	var room: Dictionary = rooms[id]
	if not room.parts[2].built: return "Pièce non fermée : terminer ses trois étapes."
	var bed := bed_index(room)
	var people := occupants(id)
	var names: Array[String] = []
	for person in people: names.append("H%d" % (person + 1))
	var text := "Pièce détectée · %s\nPrésents : %s" % [owner_name(room), ", ".join(names) if not names.is_empty() else "aucun"]
	if bed >= 0:
		var b: Dictionary = game.sleeping.beds[bed]
		var owner: int = b.occupant if b.occupant >= 0 else b.owner
		var quality := rest_quality(b, owner)
		text += "\nIntimité %d/100 · %s" % [int(quality.privacy), quality.reason]
	return text
