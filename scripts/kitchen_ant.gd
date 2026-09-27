extends RefCounted
## One forager, competing only for unreserved crumbs. Simulation time, no wall-clock AI.
const NEST := Vector3(8.05, -.0105, 29.6)
const VIA := Vector3(7, -.0105, 29.5)
const TURN := Vector3(7, -.0105, 27.6)
const SOURCE := Vector3(6.4, -.0105, 26)
const COVER := Rect2(3.5, 28.2, 2.4, .25)
const OBSTACLES := [COVER, Rect2(-.4, 28.25, 2.8, .5), Rect2(7.2, 25.45, 1.6, 1.1)]
var game: Node3D
var pos := NEST
var yaw := 0.0
var state := "rest"
var clock := 0.0
var animation_time := 0.0
var route := PackedVector3Array()
var index := 0
var carrying := 0
var stored := 0
var encounters := 0
var seen := false
var policy := "wait"
var actor: Node3D
var crumb: Node3D
var cover: Node3D
var label: Label3D
var player: AnimationPlayer
var clips := {}

func setup() -> void:
	actor = game.Art.model(game, "ant_31/ant", pos)
	crumb = game.Art.model(actor, "ant_31/crumb", Vector3(0, .30, -1.05))
	cover = game.Art.model(game, "ant_31/cover", Vector3.ZERO)
	label = game.Art.caption(game, "", pos + Vector3(0, 1.15, 0), Color("ddb67b"))
	label.pixel_size = .0045
	player = actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player != null:
		for clip in player.get_animation_list():
			for key in ["search", "walk", "carry", "alert"]:
				if str(clip).to_lower().ends_with(key): clips[key] = clip
		# Evaluate poses explicitly while keeping pause/speed/save tied to simulation time.
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.active = true
	refresh()

static func clear_segment(a: Vector3, b: Vector3, biscuit_present: bool = true) -> bool:
	# Slab intersection against authored physical skirting, biscuit and fallen offcut.
	var start := Vector2(a.x, a.z)
	var delta := Vector2(b.x - a.x, b.z - a.z)
	for obstacle in range(OBSTACLES.size()):
		if obstacle == 2 and not biscuit_present: continue
		var rect: Rect2 = OBSTACLES[obstacle]
		var lo := 0.0
		var hi := 1.0
		for axis in range(2):
			if absf(delta[axis]) < .00001:
				if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]: lo = 2.0
			else:
				var first: float = (rect.position[axis] - start[axis]) / delta[axis]
				var last: float = (rect.end[axis] - start[axis]) / delta[axis]
				lo = maxf(lo, minf(first, last))
				hi = minf(hi, maxf(first, last))
		if lo <= hi: return false
	return true

func perceives(point: Vector3) -> bool:
	return pos.distance_to(point) <= 3.3 and clear_segment(pos, point, game.kitchen.amount > 0)

func set_route(points: Array, next: String) -> void:
	route = PackedVector3Array(points)
	index = 0
	state = next
	clock = 0.0

func move(dt: float) -> bool:
	if index >= route.size(): return true
	var delta := route[index] - pos
	var step := minf(delta.length(), dt * (.62 if carrying > 0 else .82))
	if step > 0:
		pos += delta.normalized() * step
		yaw = rotate_toward(yaw, atan2(-delta.x, -delta.z), dt * 5)
	if pos.distance_to(route[index]) < .001: index += 1
	return index >= route.size()

func update(dt: float) -> void:
	if not game.kitchen.known:
		refresh()
		return
	seen = true
	clock += dt
	animation_time += dt
	if state in ["search", "gather", "carry"]:
		for w in game.workers:
			if w.delivery.sector_id == "kitchen" and w.node.visible and perceives(w.node.position):
				var delta: Vector3 = w.node.position - pos
				yaw = atan2(-delta.x, -delta.z)
				state = "alert"
				clock = 0.0
				encounters += 1
				game._news("La fourmi a perçu un habitant : antennes dressées, elle se replie. Laissez-lui de l’espace.")
				break
	match state:
		"rest":
			if clock >= 14.0 and game.kitchen.amount > game.kitchen.reserved:
				set_route([VIA, TURN, SOURCE], "search")
		"search":
			if move(dt): state = "gather"; clock = 0.0
		"gather":
			if clock >= 3:
				# A resident's reservation wins, including a reservation made during this approach.
				if game.kitchen.amount > game.kitchen.reserved:
					game.kitchen.amount -= 1
					carrying = 1
				set_route([TURN, VIA, NEST], "carry")
		"carry", "retreat":
			if move(dt):
				stored += carrying
				carrying = 0
				state = "rest"
				clock = 0.0
		"alert":
			if clock >= 1.6: set_route([TURN, VIA, NEST], "retreat")
	refresh()

func worker_wait(c: WorkerDelivery, t: Dictionary, dt: float) -> bool:
	if not game.kitchen.known or t.returning or t.stage not in ["food_walk", "harvest"]: return false
	var near := pos.distance_to(c.actor.position) < 3.05 and clear_segment(pos, c.actor.position, game.kitchen.amount > 0)
	var ahead := false
	if t.stage == "food_walk" and t.index < t.route.size():
		var target: Vector3 = c.actor.position.move_toward(t.route[t.index], 1.1)
		ahead = pos.distance_to(target) < 2.7 and clear_segment(pos, target, game.kitchen.amount > 0)
	if near or ahead:
		t.ant_wait = float(t.get("ant_wait", 0.0)) + dt
		# Waiting cannot secretly finish harvest or consume the entire return fuel budget.
		t.clock = maxf(0, t.clock - dt)
		c.pose("idle", fposmod(t.ant_wait, 4.0))
		if t.ant_wait >= 8:
			game.kitchen.cancel(c, game.fissure.missions[c.owner])
			game.kitchen.status = "Approche occupée : retour prudent, ordre de récolte conservé."
		return true
	t.ant_wait = 0.0
	return false

func food_route(id: int) -> Array:
	var end: Vector3 = game.kitchen.FOOD + Vector3(0, 0, (id - 1.5) * .45)
	if policy == "detour": return [Vector3(2, -.0105, 23.5), Vector3(2, -.0105, 27), Vector3(5.1, -.0105, 27), end]
	return [Vector3(4, -.0105, 24), end]

func toggle_policy() -> void:
	policy = "detour" if policy == "wait" else "wait"
	game._news("Approche cuisine : " + ("détour ouest pour les prochains trajets." if policy == "detour" else "trajet direct, attente prudente."))

func refresh() -> void:
	if not is_instance_valid(actor): return
	actor.visible = game.kitchen.known
	cover.visible = game.fissure.visited
	label.visible = actor.visible
	actor.position = pos
	actor.rotation.y = yaw
	crumb.visible = carrying > 0
	label.position = pos + Vector3(0, 1.15, 0)
	label.text = "FOURMI · " + {"rest": "au nid", "search": "cherche", "gather": "prélève", "carry": "rapporte", "alert": "alerte !", "retreat": "se replie"}[state]
	label.modulate = Color("ee8c63") if state == "alert" else Color("ddb67b")
	if player != null:
		var moving := state in ["search", "carry", "retreat"]
		var key := "alert" if state == "alert" else (("carry" if carrying > 0 else "walk") if moving else "search")
		if clips.has(key):
			player.play(clips[key])
			player.seek(fposmod(animation_time, player.get_animation(clips[key]).length), true)

func summary() -> String:
	if not game.kitchen.known: return "Faune : reconnaître la cuisine pour observer son activité."
	return "Fourmi : %s · %d miette(s) au nid, %d portée\nApproche : %s. Pause pour observer ; un habitant attend jusqu’à 8 s puis rentre si le passage reste occupé." % [{"rest": "au nid", "search": "recherche", "gather": "prélèvement", "carry": "transport", "alert": "alerte locale", "retreat": "repli"}[state], stored, carrying, "détour ouest" if policy == "detour" else "directe prudente"]

func snapshot() -> Dictionary:
	return {"pos": pos, "yaw": yaw, "state": state, "clock": clock, "animation_time": animation_time, "route": route, "index": index, "carrying": carrying, "stored": stored, "encounters": encounters, "seen": seen, "policy": policy}

func restore(data: Dictionary) -> void:
	for key in snapshot():
		if data.has(key): set(key, data[key])
	refresh()

static func valid(v: Variant, kitchen: Dictionary) -> bool:
	if not v is Dictionary or not v.has_all(["pos", "yaw", "state", "clock", "animation_time", "route", "index", "carrying", "stored", "encounters", "seen", "policy"]): return false
	if not v.pos is Vector3 or not v.pos.is_finite() or not Rect2(-1.5, 22, 11, 9).has_point(Vector2(v.pos.x, v.pos.z)) or absf(v.pos.y + .0105) > .001: return false
	if v.state not in ["rest", "search", "gather", "carry", "alert", "retreat"] or v.policy not in ["wait", "detour"] or not v.seen is bool: return false
	for key in ["yaw", "clock", "animation_time"]:
		if not (v[key] is float or v[key] is int) or not is_finite(v[key]): return false
	if v.clock < 0 or v.animation_time < 0: return false
	if not v.route is PackedVector3Array or v.route.size() > 3 or not v.index is int or v.index < 0 or v.index > v.route.size(): return false
	for point in v.route:
		if point not in [NEST, VIA, TURN, SOURCE]: return false
	if not v.carrying is int or v.carrying not in [0, 1] or not v.stored is int or v.stored < 0 or v.stored > 36 or not v.encounters is int or v.encounters < 0: return false
	if v.stored + v.carrying + kitchen.amount > 36: return false
	if v.carrying > 0 and v.state not in ["carry", "alert", "retreat"]: return false
	return true
