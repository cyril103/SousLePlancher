extends RefCounted
## Stage 5: one authored threshold. Annex visits do not yet create a remote economy.
const NEAR := Vector3(4, -.0105, 5)
const FAR := Vector3(4, -.0105, 7.4)
const LOOK := Vector3(4, -.0105, 8.8)
const COST := {"wood": 6, "fiber": 4}
const CONTRACT := {"id": "south_fissure", "from": "refuge_south", "to": "alcove_north", "width": .85, "height": 2.1, "capacity": 1, "cargo": false, "seconds": 3.0}
var game: Node3D
var discovered := false
var visited := false
var site: Dictionary = {}
var missions: Dictionary = {}
var owner := -1
var queue: Array[int] = []
var wall: Node3D
var rubble: Node3D
var braces: Node3D
var annex: Node3D
var label: Label3D
var supplies: Node3D
var supply_signature := ""

func setup() -> void:
	wall = game.Art.model(game, "fissure_18/fissure_frame", Vector3(4, 0, 6.2))
	rubble = game.Art.model(game, "fissure_18/fissure_blocked", Vector3(4, 0, 6.2))
	braces = game.Art.model(game, "fissure_18/fissure_braces", Vector3(4, 0, 6.2))
	annex = game.Art.model(game, "fissure_18/fissure_alcove", Vector3(4, 0, 6.2))
	label = game.Art.caption(game, "", Vector3(4, 3.1, 6.2))
	label.pixel_size = .006
	supplies = Node3D.new()
	game.add_child(supplies)
	supplies.position = NEAR + Vector3(-.65, 0, -.45)
	refresh()

func opened() -> bool:
	return not site.is_empty() and site.built

func occupied(id: int) -> bool:
	return missions.has(id) or (not site.is_empty() and site.builder == id)

func sites() -> Array:
	return [] if site.is_empty() else [site]

func entrance(_site: Dictionary) -> Vector3:
	return NEAR

func refresh() -> void:
	if not is_instance_valid(wall): return
	rubble.visible = site.is_empty() or site.work < 8
	braces.visible = not site.is_empty() and site.work >= 8
	annex.visible = opened()
	label.text = "Fissure à inspecter" if not discovered else ("Passage ouvert · alcôve" if opened() else "Fissure bloquée")
	if not site.is_empty() and not site.built:
		label.text = "Dégagement / étaiement · %d %%" % int(site.work / site.required * 100)
	var signature := "" if site.is_empty() or site.built else str(site.materials)
	if signature != supply_signature:
		supply_signature = signature
		for child in supplies.get_children():
			supplies.remove_child(child)
			child.queue_free()
		if not signature.is_empty():
			for kind in ["wood", "fiber"]:
				if site.materials[kind] <= 0: continue
				var prop: Node3D = game.Art.model(supplies, kind, Vector3(-.2 if kind == "wood" else .2, 0, 0))
				prop.scale = Vector3.ONE * .22

func reject(message: String) -> bool:
	game._news(message)
	return false

func request_build() -> bool:
	if not discovered: return reject("Faites inspecter la fissure avant de lancer les travaux.")
	if not site.is_empty(): return reject("Ce passage possède déjà un chantier ou est ouvert.")
	if game.hiding or game.pending_save or game.ended: return reject("Reprenez les sorties avant les travaux.")
	site = {"fissure_site": true, "pos": NEAR, "materials": {"wood": 0, "fiber": 0}, "hauler": -1, "builder": -1, "work": 0.0, "required": 24.0, "built": false}
	refresh()
	game._news("Chantier lancé : livrer 6 bois et 4 fibres, puis dégager et étayer le passage.")
	return true

func cancel_build() -> bool:
	if site.is_empty() or opened(): return reject("Aucun chantier annulable.")
	var builder: int = site.builder
	game.construction.cancel_site(site)
	site = {}
	if builder >= 0: game.workers[builder].delivery.change("return_home")
	refresh()
	game._news("Chantier annulé : les matériaux livrés restent à récupérer devant la fissure.")
	return true

func start(id: int, inspect: bool = false) -> bool:
	if game.ended or game.hiding or game.pending_save: return reject("Reprenez les sorties avant de partir.")
	var c: WorkerDelivery = game.workers[id].delivery
	if c.worker.carrying > 0: return reject("Passage trop étroit pour une caisse : déposez la charge d’abord.")
	if occupied(id) or not game.torches.available(c) or game.torches.occupied(id): return reject("Choisissez un habitant libre, sans équipement engagé.")
	if c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35: return reject("Cet habitant doit satisfaire ses besoins avant de partir.")
	if not inspect and not opened(): return reject("Passage bloqué : inspectez, dégagez et étayez d’abord la fissure.")
	if inspect and discovered: return reject("La fissure est déjà inspectée.")
	if inspect:
		for mission in missions.values():
			if mission.inspect: return reject("Un habitant inspecte déjà la fissure.")
	var from: Vector3 = game.home_position(id) if c.inside_refuge else c.actor.position
	if game.travel_path(from, NEAR, id).is_empty(): return reject("L’entrée de la fissure est inaccessible.")
	missions[id] = {"phase": "approach", "inspect": inspect, "returning": false, "clock": 0.0, "side": "near"}
	c.change("leave_home" if c.inside_refuge else "idle")
	game._news("L’habitant part inspecter la fissure." if inspect else "L’habitant visitera l’alcôve, puis rentrera. Une personne à la fois sur le seuil.")
	return true

func cancel(c: WorkerDelivery) -> bool:
	if not site.is_empty() and site.builder == c.owner:
		site.builder = -1
		c.change("return_home")
		return true
	if not missions.has(c.owner): return false
	var m: Dictionary = missions[c.owner]
	if m.returning: return true
	m.returning = true
	if m.phase == "cross": return true # Finish the committed crossing before turning back.
	queue.erase(c.owner)
	if owner == c.owner: owner = -1
	if m.side == "far": m.phase = "back"
	else: finish(c)
	return true

func finish(c: WorkerDelivery) -> void:
	queue.erase(c.owner)
	if owner == c.owner: owner = -1
	missions.erase(c.owner)
	c.navigation_issue = ""
	c.change("return_home")

func start_work(c: WorkerDelivery) -> bool:
	if site.is_empty() or site.built or site.builder >= 0 or site.hauler >= 0: return false
	if game.hiding or game.pending_save or c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35: return false
	if not game.torches.available(c) or game.torches.occupied(c.owner) or not game.construction.supplied(site): return false
	var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
	if game.travel_path(from, NEAR, c.owner).is_empty(): return false
	if c.inside_refuge:
		c.change("leave_home")
		return true
	site.builder = c.owner
	c.change("fissure_work_walk")
	return true

func local_move(c: WorkerDelivery, target: Vector3, dt: float) -> bool:
	var delta := target - c.actor.position
	var step := minf(delta.length(), dt * 1.4 * game.needs.movement_factor(c.worker))
	if step > 0:
		c.actor.position += delta.normalized() * step
		c.actor.rotation.y = rotate_toward(c.actor.rotation.y, atan2(delta.x, delta.z), dt * 8)
		c.anim_time += step / float(ResidentAnimator.SPEEDS.walk)
	c.pose("walk", fposmod(c.anim_time, c.actor.player.get_animation("walk").length))
	return c.actor.position.distance_to(target) < .001

func tick(c: WorkerDelivery, dt: float) -> bool:
	if not site.is_empty() and site.builder == c.owner:
		if game.hiding or game.pending_save or c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35:
			cancel(c)
			return false
		if c.state == "fissure_work_walk":
			if c.move(NEAR, dt, false): c.change("fissure_work")
		else:
			c.actor.rotation.y = 0
			c.pose("work", fposmod(c.timer, 1.2))
			site.work = minf(24, site.work + dt)
			if site.work >= 24:
				site.built = true
				site.builder = -1
				c.change("return_home")
				game._news("Le passage est dégagé et étayé. Vous pouvez maintenant visiter l’alcôve.")
			refresh()
		return true
	if not missions.has(c.owner): return false
	var m: Dictionary = missions[c.owner]
	if game.hiding or game.pending_save or c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35:
		cancel(c)
		if not missions.has(c.owner): return false
	if c.inside_refuge or c.state == "leave_home": return false
	match m.phase:
		"approach":
			var waiting := NEAR + Vector3((c.owner - 1.5) * .5, 0, -.65)
			if c.move(NEAR if m.inspect else waiting, dt, false):
				m.phase = "inspect" if m.inspect else "wait"
				m.clock = 0.0
		"inspect":
			c.pose("idle", fposmod(c.timer, 4))
			m.clock += dt
			if m.clock >= 5:
				discovered = true
				refresh()
				game._news("Fissure inspectée : passage horizontal étroit, 6 bois et 4 fibres pour l’étayer. Caisses interdites.")
				finish(c)
		"wait":
			if not opened():
				finish(c)
				return true
			if not c.owner in queue: queue.append(c.owner)
			c.pose("idle", fposmod(c.timer, 4))
			if owner == -1 and queue[0] == c.owner:
				owner = c.owner
				queue.pop_front()
				m.phase = "entry"
		"entry":
			if (local_move(c, FAR, dt) if m.side == "far" else c.move(NEAR, dt, false)):
				m.phase = "cross"
				m.clock = 0.0
		"cross":
			m.clock = minf(3, m.clock + dt)
			var a := FAR if m.side == "far" else NEAR
			var b := NEAR if m.side == "far" else FAR
			c.actor.position = a.lerp(b, m.clock / 3)
			c.actor.rotation.y = PI if m.side == "far" else 0
			c.pose("walk", fposmod(m.clock * .8 / float(ResidentAnimator.SPEEDS.walk), c.actor.player.get_animation("walk").length))
			if m.clock >= 3:
				owner = -1
				m.side = "near" if m.side == "far" else "far"
				if m.side == "near": finish(c)
				else: m.phase = "back" if m.returning else "look_walk"
		"look_walk":
			if local_move(c, LOOK + Vector3(c.owner * .35, 0, 0), dt):
				visited = true
				m.phase = "look"
				m.clock = 0.0
		"look":
			c.pose("idle", fposmod(c.timer, 4))
			m.clock += dt
			if m.clock >= 5: m.phase = "back"
		"back":
			if local_move(c, FAR + Vector3((c.owner - 1.5) * .5, 0, .7), dt): m.phase = "wait"
	return true

func description(c: WorkerDelivery) -> String:
	if not site.is_empty() and site.builder == c.owner: return "Dégage la fissure" if site.work < 8 else "Étaye la fissure"
	if not missions.has(c.owner): return ""
	return {"approach": "Va à la fissure", "inspect": "Inspecte la fissure", "wait": "Attend le passage étroit", "entry": "Rejoint le seuil", "cross": "Traverse la fissure", "look_walk": "Explore l’alcôve", "look": "Observe l’alcôve", "back": "Revient vers la fissure"}.get(missions[c.owner].phase, "Retour au refuge")

func summary() -> String:
	var text := "Fissure non inspectée" if not discovered else ("Passage ouvert" if opened() else "Fissure bloquée")
	text += "\n6 bois · 4 fibres · 24 s de travaux\nPassage étroit · une personne · sans caisse"
	if not site.is_empty() and not site.built: text += "\n" + game.construction.quantities(site) + "\n" + game.construction.status(site)
	text += "\n%d habitant(s) en sortie · %d en attente" % [missions.size(), queue.size()]
	return text

func snapshot() -> Dictionary:
	return {"discovered": discovered, "visited": visited, "site": {} if site.is_empty() else {"materials": site.materials.duplicate(), "work": site.work, "built": site.built}}

func restore(data: Dictionary) -> void:
	discovered = data.discovered
	visited = data.visited
	if not data.site.is_empty():
		site = {"fissure_site": true, "pos": NEAR, "materials": data.site.materials.duplicate(), "work": float(data.site.work), "built": data.site.built, "required": 24.0, "hauler": -1, "builder": -1}
	refresh()
