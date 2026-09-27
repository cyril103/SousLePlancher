extends RefCounted
## Stages 6A/6B: the threshold owns movement; the lantern owns equipment and fuel.
const NEAR := Vector3(4, -.0105, 5)
const FAR := Vector3(4, -.0105, 7.4)
const LOOK := Vector3(4, -.0105, 12.7)
const HOME_SECTOR := "refuge_south"
const ALCOVE_SECTOR := "alcove_north"
const OBSERVE := 12.0
const COST := {"wood": 6, "fiber": 4}
const CONTRACT := {"id": "south_fissure", "from": "refuge_south", "to": "alcove_north", "width": .85, "height": 2.1, "capacity": 1, "cargo": false, "seconds": 3.0}
var game: Node3D
var discovered := false
var visited := false
var site: Dictionary = {}
var upgrade: Dictionary = {}
var hauling := preload("res://scripts/alcove_hauling.gd").new()
var wide_frame: Node3D
var wide_braces: Node3D
var missions: Dictionary = {}
var follow := -1
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
	hauling.game = game
	wall = game.Art.model(game, "fissure_18/fissure_frame", Vector3(4, 0, 6.2))
	rubble = game.Art.model(game, "fissure_18/fissure_blocked", Vector3(4, 0, 6.2))
	braces = game.Art.model(game, "fissure_18/fissure_braces", Vector3(4, 0, 6.2))
	annex = game.Art.model(game, "alcove_19/alcove_sector", Vector3(4, 0, 6.2))
	wide_frame = game.Art.model(game, "passage_20/wide_frame", Vector3(4, 0, 6.2))
	wide_braces = game.Art.model(game, "passage_20/wide_braces", Vector3(4, 0, 6.2))
	hauling.setup()
	label = game.Art.caption(game, "", Vector3(4, 3.1, 6.2))
	label.pixel_size = .006
	supplies = Node3D.new()
	game.add_child(supplies)
	supplies.position = NEAR + Vector3(-.65, 0, -.45)
	refresh()

func opened() -> bool:
	return not site.is_empty() and site.built

func occupied(id: int) -> bool:
	return missions.has(id) or (not work_site().is_empty() and work_site().builder == id)

func sites() -> Array:
	var result: Array = [] if site.is_empty() else [site]
	if not upgrade.is_empty(): result.append(upgrade)
	return result

func entrance(_site: Dictionary) -> Vector3:
	return NEAR

func refresh() -> void:
	if not is_instance_valid(wall): return
	rubble.visible = site.is_empty() or site.work < 8
	wall.visible = not widened()
	wide_frame.visible = widened()
	wide_braces.visible = widened()
	braces.visible = not widened() and not site.is_empty() and site.work >= 8
	annex.visible = visited or observed()
	label.text = "Fissure à inspecter" if not discovered else ("Passage ouvert · alcôve" if opened() else "Fissure bloquée")
	if not site.is_empty() and not site.built:
		label.text = "Dégagement / étaiement · %d %%" % int(site.work / site.required * 100)
	var site := work_site()
	if not upgrade.is_empty(): label.text = "Passage élargi · caisses autorisées" if widened() else "Élargissement · %d %%" % int(upgrade.work / upgrade.required * 100)
	hauling.refresh()
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

func widened() -> bool:
	return not upgrade.is_empty() and upgrade.built

func access_contract() -> Dictionary:
	var value := CONTRACT.duplicate()
	value.cargo = widened()
	value.width = 1.8 if widened() else .85
	return value

func work_site() -> Dictionary:
	return upgrade if not upgrade.is_empty() else site

func request_upgrade() -> bool:
	if not opened() or not visited: return reject("Reconnaissez d’abord l’alcôve.")
	if not upgrade.is_empty(): return reject("L’élargissement est déjà commandé ou terminé.")
	if not missions.is_empty(): return reject("Rappelez les éclaireurs avant les travaux.")
	if game.hiding or game.pending_save or game.ended: return reject("Reprenez les sorties avant les travaux.")
	upgrade = {"fissure_site": true, "pos": NEAR, "materials": {"wood": 0, "fiber": 0}, "hauler": -1, "builder": -1, "work": 0.0, "required": 24.0, "built": false}
	refresh()
	game._news("Élargissement : livrer 6 bois et 4 fibres, puis 24 s de travaux. Le passage ferme pendant le chantier.")
	return true

func cancel_build() -> bool:
	var target := work_site()
	if target.is_empty() or target.built: return reject("Aucun chantier annulable.")
	var builder: int = target.builder
	game.construction.cancel_site(target)
	if not upgrade.is_empty(): upgrade = {}
	else: site = {}
	if builder >= 0: game.workers[builder].delivery.change("return_home")
	refresh()
	game._news("Chantier annulé : les matériaux livrés restent à récupérer devant la fissure.")
	return true

func start(id: int, inspect: bool = false) -> bool:
	if game.ended or game.hiding or game.pending_save: return reject("Reprenez les sorties avant de partir.")
	var c: WorkerDelivery = game.workers[id].delivery
	if c.worker.carrying > 0: return reject("Passage trop étroit pour une caisse : déposez la charge d’abord.")
	if not upgrade.is_empty() and not upgrade.built: return reject("Passage fermé pendant l’élargissement.")
	if occupied(id) or not game.torches.available(c): return reject("Choisissez un habitant libre.")
	if inspect and game.torches.occupied(id): return reject("Rangez votre éclairage avant cette inspection de chantier.")
	if not inspect and not game.torches.can_haul(id): return reject("Équipez une lanterne de ceinture avant d’explorer l’alcôve sombre.")
	if c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35: return reject("Cet habitant doit satisfaire ses besoins avant de partir.")
	if not inspect and not opened(): return reject("Passage bloqué : inspectez, dégagez et étayez d’abord la fissure.")
	if inspect and discovered: return reject("La fissure est déjà inspectée.")
	if inspect:
		for mission in missions.values():
			if mission.inspect: return reject("Un habitant inspecte déjà la fissure.")
	var from: Vector3 = game.home_position(id) if c.inside_refuge else c.actor.position
	if game.travel_path(from, NEAR, id).is_empty(): return reject("L’entrée de la fissure est inaccessible.")
	if not inspect:
		var required := required_fuel(c)
		var item: Dictionary = game.torches.items[game.torches.held(id)]
		if item.fuel < required: return reject("Autonomie insuffisante : %.0f s disponibles, %.0f s nécessaires, retour et marge compris." % [item.fuel, required])
		game.torches.missions[id].phase = "sector"
		item.lit = true
	missions[id] = {"id": "south_fissure:H%d" % id, "phase": "approach", "inspect": inspect, "returning": false, "clock": 0.0, "side": "near"}
	c.change("leave_home" if c.inside_refuge else "idle")
	game._news("L’habitant part inspecter la fissure." if inspect else "L’éclaireur reconnaîtra l’alcôve à la lanterne, puis rentrera. Une personne à la fois sur le seuil.")
	return true

func cancel(c: WorkerDelivery) -> bool:
	var site := work_site()
	if not site.is_empty() and site.builder == c.owner:
		site.builder = -1
		c.change("return_home")
		return true
	if not missions.has(c.owner): return false
	var m: Dictionary = missions[c.owner]
	if m.returning: return true
	m.returning = true
	hauling.cancel_uncollected(c, m)
	if m.phase in ["cross", "clear"]: return true # Finish the committed crossing before turning back.
	queue.erase(c.owner)
	if owner == c.owner: owner = -1
	if m.side == "far": m.phase = "back"
	else: finish(c)
	return true

func finish(c: WorkerDelivery) -> void:
	if missions.has(c.owner): hauling.release(c, missions[c.owner])
	queue.erase(c.owner)
	if owner == c.owner: owner = -1
	missions.erase(c.owner)
	c.sector_id = HOME_SECTOR
	c.navigation_issue = ""
	if game.torches.missions.has(c.owner) and game.torches.missions[c.owner].phase == "sector":
		game.torches.recall(c, "Retour de l’alcôve")
	c.change("return_home")
	refresh()

func start_work(c: WorkerDelivery) -> bool:
	var site := work_site()
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
	var clip := "carry_walk" if c.worker.carrying > 0 else "walk"
	var delta := target - c.actor.position
	var step := minf(delta.length(), dt * 1.4 * game.needs.movement_factor(c.worker))
	if step > 0:
		c.actor.position += delta.normalized() * step
		c.actor.rotation.y = rotate_toward(c.actor.rotation.y, atan2(delta.x, delta.z), dt * 8)
		c.anim_time += step / float(ResidentAnimator.SPEEDS[clip])
	c.pose(clip, fposmod(c.anim_time, c.actor.player.get_animation(clip).length))
	return c.actor.position.distance_to(target) < .001

func tick(c: WorkerDelivery, dt: float) -> bool:
	var site := work_site()
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
				game._news("Passage élargi : les caisses peuvent traverser." if widened() else "Passage ouvert : vous pouvez explorer l’alcôve.")
			refresh()
		return true
	if not missions.has(c.owner): return false
	var m: Dictionary = missions[c.owner]
	if game.hiding or game.pending_save or c.worker.sleep_requested or minf(c.worker.nutrition, c.worker.hydration) <= 35:
		cancel(c)
		if not missions.has(c.owner): return false
	if not m.inspect and not m.returning:
		var item: Dictionary = game.torches.items[game.torches.held(c.owner)]
		if item.fuel <= return_budget(c) + game.torches.margin(c.owner):
			game._news("H%d : réserve de combustible atteinte, retour anticipé." % (c.owner + 1))
			cancel(c)
			if not missions.has(c.owner): return false
	if c.inside_refuge or c.state == "leave_home": return false
	if hauling.tick(c, m, dt): return true
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
			c.pose("pick_up" if c.worker.carrying > 0 else "idle", 1.8 if c.worker.carrying > 0 else fposmod(c.timer, 4))
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
			annex.visible = visited or observed()
			var a := FAR if m.side == "far" else NEAR
			var b := NEAR if m.side == "far" else FAR
			c.actor.position = a.lerp(b, m.clock / 3)
			c.actor.rotation.y = PI if m.side == "far" else 0
			var clip := "carry_walk" if c.worker.carrying > 0 else "walk"
			c.pose(clip, fposmod(m.clock * .8 / float(ResidentAnimator.SPEEDS[clip]), c.actor.player.get_animation(clip).length))
			if m.clock >= 3:
				m.side = "near" if m.side == "far" else "far"
				if m.side == "near":
					c.sector_id = HOME_SECTOR
					owner = -1
					if c.worker.carrying > 0:
						m.phase = "delivery_wait"
						c.change("idle")
					else: finish(c)
				else:
					c.sector_id = ALCOVE_SECTOR
					m.phase = "clear"
				refresh()
		"clear":
			if local_move(c, FAR + Vector3((c.owner - 1.5) * .5, 0, .7), dt):
				owner = -1
				m.phase = "back" if m.returning else ("harvest_walk" if m.has("quantity") else "look_walk")
		"look_walk":
			if local_move(c, LOOK + Vector3(c.owner * .35, 0, 0), dt):
				m.phase = "look"
				m.clock = 0.0
		"look":
			c.pose("idle", fposmod(c.timer, 4))
			m.clock += dt
			if m.clock >= OBSERVE:
				visited = true
				m.returning = true
				m.phase = "back"
				refresh()
				game._news("Alcôve reconnue : son décor restera mémorisé. L’éclaireur rentre au refuge.")
		"back":
			if local_move(c, FAR + Vector3((c.owner - 1.5) * .5, 0, .7), dt): m.phase = "wait"
	return true

func description(c: WorkerDelivery) -> String:
	var site := work_site()
	if missions.has(c.owner) and missions[c.owner].has("quantity"):
		return hauling.description(c, missions[c.owner])
	if not site.is_empty() and site.builder == c.owner: return "Dégage la fissure" if site.work < 8 else "Étaye la fissure"
	if not missions.has(c.owner): return ""
	return ("Alcôve · " if c.sector_id == ALCOVE_SECTOR else "Refuge · ") + {"approach": "Va à la fissure", "inspect": "Inspecte la fissure", "wait": "Attend le passage étroit", "entry": "Rejoint le seuil", "cross": "Traverse la fissure", "clear": "Dégage le seuil", "look_walk": "Explore l’alcôve", "look": "Observe l’alcôve", "back": "Revient vers la fissure"}.get(missions[c.owner].phase, "Retour au refuge")

func summary() -> String:
	var text := "Fissure non inspectée" if not discovered else ("Passage ouvert" if opened() else "Fissure bloquée")
	if not opened(): text += "\n6 bois · 4 fibres · 24 s de travaux"
	text += "\nUne personne à la fois · lanterne · " + ("caisses autorisées" if widened() else "sans caisse")
	if not upgrade.is_empty() and not upgrade.built: text += "\nÉlargissement : " + game.construction.quantities(upgrade) + " · " + game.construction.status(upgrade)
	text += "\n" + hauling.summary()
	if not site.is_empty() and not site.built: text += "\n" + game.construction.quantities(site) + "\n" + game.construction.status(site)
	text += "\nAlcôve : " + ("observée à la lanterne" if observed() else ("décor mémorisé" if visited else "inconnue"))
	text += "\n%d habitant(s) en sortie · %d en attente" % [missions.size(), queue.size()]
	return text

func snapshot() -> Dictionary:
	return {"discovered": discovered, "visited": visited, "site": saved_site(site), "upgrade": saved_site(upgrade), "fiber": hauling.amount, "known_fiber": hauling.known}

func restore(data: Dictionary) -> void:
	discovered = data.discovered
	visited = data.visited
	if not data.site.is_empty():
		site = {"fissure_site": true, "pos": NEAR, "materials": data.site.materials.duplicate(), "work": float(data.site.work), "built": data.site.built, "required": 24.0, "hauler": -1, "builder": -1}
	if not data.get("upgrade", {}).is_empty():
		upgrade = {"fissure_site": true, "pos": NEAR, "materials": data.upgrade.materials.duplicate(), "work": float(data.upgrade.work), "built": data.upgrade.built, "required": 24.0, "hauler": -1, "builder": -1}
	hauling.amount = int(data.get("fiber", 24))
	hauling.known = int(data.get("known_fiber", 24 if visited else -1))
	refresh()

func saved_site(value: Dictionary) -> Dictionary:
	return {} if value.is_empty() else {"materials": value.materials.duplicate(), "work": value.work, "built": value.built}

func observed() -> bool:
	for id in missions:
		if missions[id].side == "far" or (missions[id].phase == "cross" and missions[id].clock >= 1.5):
			var index: int = game.torches.held(id)
			if index >= 0 and game.torches.items[index].lit: return true
	return false

func required_fuel(c: WorkerDelivery) -> float:
	var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
	return game.torches.travel_seconds(c, from, NEAR) + game.torches.travel_seconds(c, NEAR, game.HOME + game.Refuge.OUTSIDE) + 2 * FAR.distance_to(LOOK) / (1.4 * game.needs.movement_factor(c.worker)) + OBSERVE + 16.0 + 8.0 * missions.size() + game.torches.margin(c.owner)

func return_budget(c: WorkerDelivery) -> float:
	var m: Dictionary = missions[c.owner]
	var walking: float = game.torches.travel_seconds(c, NEAR, game.HOME + game.Refuge.OUTSIDE)
	if m.has("quantity") and not m.get("released", false):
		walking = game.torches.travel_seconds(c, NEAR, game.depots.entry(m.depot)) + game.torches.travel_seconds(c, game.depots.entry(m.depot), game.HOME + game.Refuge.OUTSIDE) + 8.0
	if m.side == "far" or m.phase == "cross":
		walking += c.actor.position.distance_to(FAR) / (1.4 * game.needs.movement_factor(c.worker)) + 6.0
	else:
		walking += game.torches.travel_seconds(c, c.actor.position, NEAR)
	return walking + 8.0 * missions.size() + 4.0
