extends RefCounted
## Ground rescue and care. Patient/bed and helper claims have one authoritative owner.
var game: Node3D
var patients: Dictionary = {}
var helpers: Dictionary = {}
var allowed: Dictionary = {}
var visuals: Dictionary = {}
var used_fiber := 0
var demo := false

func safe(c: WorkerDelivery) -> bool:
	return c.state in ["idle", "return_home"] and c.job < 0 and c.supply_job < 0 and c.furniture_order < 0 and c.depot_order < 0 and c.worker.carrying == 0 and not c.climbing and not c.bridge_active and not c.door_active and not game.torches.occupied(c.owner) and not game.fissure.occupied(c.owner) and c.sector_id == "refuge_south"

func injure(id: int) -> bool:
	if id < 0 or id >= game.workers.size() or patients.has(id) or helpers.has(id): return false
	var c: WorkerDelivery = game.workers[id].delivery
	if not safe(c) or c.inside_refuge or absf(c.actor.position.y) > .1: return false
	game.refuge.release(id)
	game.ladder.release(id)
	game.bridge.release(id)
	c.waiting_ladder = false
	c.waiting_bridge = false
	c.waiting_door = false
	patients[id] = {"phase": "down", "bed": -1, "helper": -1, "health": 30.0, "care": 0.0, "supplies": 0, "clock": 0.0, "reason": "Attend un secouriste et un lit accessible"}
	c.change("injured")
	c.pose("floor_rest", 0)
	game._news("H%d est immobilisé. Un habitant disponible peut le secourir jusqu’à son lit ou un lit collectif." % (id + 1))
	return true

func ground_path(a: Vector3, b: Vector3) -> bool:
	return absf(a.y) < .2 and absf(b.y) < .2 and not game.navigation.path(a, b).is_empty()

func bed_for(id: int) -> int:
	var c: WorkerDelivery = game.workers[id].delivery
	var choices: Array[int] = []
	var own: int = game.sleeping.owned_bed(id)
	if own >= 0: choices.append(own)
	for i in range(game.sleeping.beds.size()):
		if i != own and game.sleeping.beds[i].owner == -1: choices.append(i)
	for i in choices:
		var bed: Dictionary = game.sleeping.beds[i]
		if bed.built and bed.occupant == -1 and ground_path(c.actor.position, game.sleeping.entrance(bed)): return i
	return -1

func ready(c: WorkerDelivery) -> bool:
	return safe(c) and not patients.has(c.owner) and not helpers.has(c.owner) and allowed.get(c.owner, true) and not c.personal_recall and not c.worker.sleep_requested and minf(c.worker.nutrition, c.worker.hydration) > 35 and c.worker.energy > 25 and not game.hiding and not game.pending_save

func start(c: WorkerDelivery) -> bool:
	if not ready(c): return false
	for id in patients:
		var p: Dictionary = patients[id]
		if p.helper >= 0 or p.phase in ["recover", "exit"]: continue
		var target: Vector3 = game.workers[id].node.position
		if p.phase == "bed": target = game.sleeping.entrance(game.sleeping.beds[p.bed])
		var origin: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if not ground_path(origin, target):
			p.reason = "Aucun accès au sol pour le secouriste"
			continue
		var bed: int = bed_for(id) if p.phase == "down" else p.bed
		if bed < 0:
			p.reason = "Aucun lit personnel ou collectif libre et accessible"
			continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		game.refuge.release(c.owner)
		c.waiting_door = false
		p.helper = c.owner
		p.bed = bed
		game.sleeping.beds[bed].occupant = id
		game.sleeping.caption(bed)
		helpers[c.owner] = {"patient": id, "stage": "approach" if p.phase == "down" else "supply", "depot": -1, "bundle": 0, "clock": 0.0}
		c.change("rescue")
		return true
	return false

func token(id: int) -> String: return "health:%d" % id

func cancel(c: WorkerDelivery) -> bool:
	if patients.has(c.owner): return true # An incapacitated resident cannot be ordered to walk.
	if not helpers.has(c.owner): return false
	var m: Dictionary = helpers[c.owner]
	var p: Dictionary = patients[m.patient]
	game.depots.release(token(c.owner))
	if m.depot >= 0: game.depots.gate(m.depot).release_destination(-2000000000 - c.owner)
	if m.bundle > 0: game.construction.add_recovery(c.actor.position, {"wood": 0, "fiber": m.bundle})
	if p.phase in ["down", "carried"]:
		var patient: WorkerDelivery = game.workers[m.patient].delivery
		if p.phase == "carried":
			patient.actor.position = c.actor.position
			patient.actor.position.y = WorkerDelivery.GROUND_Y
		p.phase = "down"
		game.sleeping.beds[p.bed].occupant = -1
		game.sleeping.caption(p.bed)
		p.bed = -1
	p.helper = -1
	p.reason = "Secours interrompu ; un autre habitant peut reprendre"
	helpers.erase(c.owner)
	c.actor.get_child(0).position = Vector3.ZERO
	c.personal_recall = true
	c.change("return_home")
	c.pose("idle", 0)
	refresh_visuals()
	return true

func toggle(id: int) -> void:
	allowed[id] = not allowed.get(id, true)
	if not allowed[id]: cancel(game.workers[id].delivery)

func tick(c: WorkerDelivery, dt: float) -> bool:
	if patients.has(c.owner):
		var p: Dictionary = patients[c.owner]
		p.clock += dt
		if p.phase in ["bed", "recover"]:
			c.pose("sleep", fposmod(p.clock, 4))
			var quality: Dictionary = game.rooms.rest_quality(game.sleeping.beds[p.bed], c.owner)
			c.worker.comfort = quality.comfort
			c.worker.privacy = quality.privacy
			c.worker.energy = minf(100, c.worker.energy + dt * quality.rate)
			if p.phase == "recover":
				p.health = minf(100, p.health + dt * 1.2)
				if p.health >= 100:
					p.phase = "exit"
					p.clock = 0.0
		elif p.phase == "exit":
			c.pose("bed_exit", minf(p.clock, 1.8))
			if p.clock >= 1.8:
				var bed: Dictionary = game.sleeping.beds[p.bed]
				c.actor.position = game.sleeping.entrance(bed)
				bed.occupant = -1
				game.sleeping.caption(p.bed)
				patients.erase(c.owner)
				c.worker.sleep_requested = c.worker.energy < 25
				c.change("idle")
				c.pose("idle", 0)
				game._news("H%d est rétabli et reprend ses activités." % (c.owner + 1))
		else: c.pose("floor_rest", 0)
		return true
	if not helpers.has(c.owner): return false
	var m: Dictionary = helpers[c.owner]
	var p: Dictionary = patients[m.patient]
	var patient: WorkerDelivery = game.workers[m.patient].delivery
	var bed: Dictionary = game.sleeping.beds[p.bed]
	var entry: Vector3 = game.sleeping.entrance(bed)
	m.clock += dt
	match m.stage:
		"approach":
			if c.move(patient.actor.position, dt, false):
				m.stage = "load"
				m.clock = 0.0
			elif not c.navigation_issue.is_empty(): cancel(c)
		"load":
			c.pose("pick_up", minf(m.clock, 1.8))
			if m.clock >= 1.8:
				p.phase = "carried"
				m.stage = "transport"
		"transport":
			if c.route_revision != game.travel_revision() and not ground_path(c.actor.position, entry):
				cancel(c)
				return true
			var arrived := c.move(entry, dt * .6, false)
			c.pose("health_pull", fposmod(c.anim_time, 2))
			patient.actor.position = c.actor.position + Vector3(0, .12, 0)
			patient.actor.rotation.y = c.actor.rotation.y
			if arrived:
				m.stage = "place"
				m.clock = 0.0
		"place":
			# Authored bed entry provides a continuous floor-to-mattress transfer.
			c.actor.get_child(0).position = Vector3.ZERO
			c.actor.rotation.y = PI
			c.pose("pick_up", minf(m.clock, 1.8))
			patient.actor.position = bed.pos
			patient.actor.rotation.y = 0
			patient.pose("health_place", minf(m.clock, 1.8))
			if m.clock >= 1.8:
				p.phase = "bed"
				m.stage = "supply"
		"supply":
			if p.supplies == 2:
				m.stage = "treat_walk"
				return true
			for depot in range(game.depots.sites.size()):
				if game.depots.available(depot, "fiber") < 2 or not ground_path(c.actor.position, game.depots.entry(depot)): continue
				m.depot = depot
				game.depots.reserve_out(token(c.owner), depot, "fiber", 2)
				m.stage = "fetch"
				break
			if m.stage == "supply":
				cancel(c)
				p.reason = "Deux fibres nécessaires dans un dépôt accessible au sol"
		"fetch":
			var gate: DeliveryLedger = game.depots.gate(m.depot)
			var ticket := -2000000000 - c.owner
			if gate.destination_owner != ticket:
				if c.move(game.depots.waiting(m.depot, c.owner), dt, false): gate.acquire_slot(ticket)
			elif c.move(game.depots.entry(m.depot), dt, false):
				m.bundle = game.depots.withdraw(token(c.owner))
				gate.release_destination(ticket)
				m.stage = "treat_walk"
			if not c.navigation_issue.is_empty(): cancel(c)
		"treat_walk":
			if c.move(entry, dt, false):
				p.supplies += m.bundle
				m.bundle = 0
				m.stage = "treat"
				c.actor.rotation.y = PI
			elif not c.navigation_issue.is_empty(): cancel(c)
		"treat":
			c.pose("health_care", fposmod(m.clock, 2))
			c.actor.tool.hide()
			p.care = minf(12, p.care + dt)
			if p.care >= 12:
				p.supplies = 0
				used_fiber += 2
				p.phase = "recover"
				p.helper = -1
				helpers.erase(c.owner)
				c.change("return_home")
				c.pose("idle", 0)
				game._news("Bandage terminé : deux fibres utilisées. H%d récupère au lit." % (m.patient + 1))
	return true

func refresh_visuals() -> void:
	for id in patients:
		if not visuals.has(id):
			var sled: Node3D = game.Art.model(game, "health_29/rescue_sled", Vector3.ZERO)
			var bandage: Node3D = game.Art.model(game, "health_29/bandage", Vector3.ZERO)
			visuals[id] = {"sled": sled, "bandage": bandage}
		var p: Dictionary = patients[id]
		var c: WorkerDelivery = game.workers[id].delivery
		var v: Dictionary = visuals[id]
		v.sled.visible = p.phase == "carried" and p.helper >= 0 and helpers[p.helper].stage == "transport"
		if v.sled.visible:
			v.sled.transform = c.actor.transform
			v.sled.position.y = WorkerDelivery.GROUND_Y
		if p.helper >= 0 and helpers.has(p.helper):
			var helper: WorkerDelivery = game.workers[p.helper].delivery
			helper.actor.get_child(0).position = Vector3(0, 0, 1.45) if p.phase == "carried" and helpers[p.helper].stage == "transport" else Vector3.ZERO
		v.bandage.visible = p.phase in ["recover", "exit"] or p.supplies > 0
		v.bandage.position = c.actor.position + Vector3(.32, .67, .5)
		if p.helper >= 0 and helpers[p.helper].bundle > 0:
			v.bandage.visible = true
			v.bandage.global_position = game.workers[p.helper].node.ration.global_position
	for id in visuals.keys():
		if patients.has(id): continue
		visuals[id].sled.queue_free()
		visuals[id].bandage.queue_free()
		visuals.erase(id)

func description(id: int) -> String:
	if patients.has(id):
		var p: Dictionary = patients[id]
		return {"down": "Immobilisé · " + p.reason, "carried": "Secours vers le lit", "bed": "Soin en cours · %d/12 s" % int(p.care) if p.care > 0 else "Au lit · attend les soins", "recover": "Convalescence · santé %d/100" % int(p.health), "exit": "Rétabli · se lève"}[p.phase]
	if helpers.has(id):
		var m: Dictionary = helpers[id]
		return "Secourt H%d · %s" % [m.patient + 1, {"approach": "rejoint le blessé", "load": "prépare le transport", "transport": "tire la civière", "place": "installe au lit", "supply": "cherche un bandage", "fetch": "va chercher 2 fibres", "treat_walk": "rejoint le lit", "treat": "soigne"}[m.stage]]
	return ""

func summary() -> String:
	var text := "Soins automatiques · 2 fibres par bandage · 12 s de soin\n"
	for id in range(game.workers.size()):
		text += "\nH%d · %s" % [id + 1, description(id) if patients.has(id) or helpers.has(id) else "En bonne santé"]
	for id in patients:
		var p: Dictionary = patients[id]
		if p.phase == "bed": text += "\nH%d : %s · soin %d/12 s" % [id + 1, p.reason if p.helper < 0 else "Secouriste en route", int(p.care)]
	return text

func snapshot() -> Dictionary:
	return {"patients": patients.duplicate(true), "helpers": helpers.duplicate(true), "allowed": allowed.duplicate(), "used_fiber": used_fiber}

func restore(data: Dictionary) -> void:
	patients = data.get("patients", {})
	helpers = data.get("helpers", {})
	allowed = data.get("allowed", {})
	used_fiber = data.get("used_fiber", 0)

static func valid(value: Variant, r: Dictionary) -> bool:
	if not value is Dictionary or not value.has_all(["patients", "helpers", "allowed", "used_fiber"]): return false
	for k in ["patients", "helpers", "allowed"]:
		if not value[k] is Dictionary: return false
	if not value.used_fiber is int or value.used_fiber < 0 or value.used_fiber % 2 != 0: return false
	var n: int = r.workers.size()
	for id in value.allowed:
		if not id is int or id < 0 or id >= n or not value.allowed[id] is bool: return false
	var beds := {}
	for id in value.patients:
		if not id is int or id < 0 or id >= n: return false
		var p = value.patients[id]
		if not p is Dictionary or not p.has_all(["phase", "bed", "helper", "health", "care", "supplies", "clock", "reason"]): return false
		if p.phase not in ["down", "carried", "bed", "recover", "exit"] or not p.reason is String: return false
		if not p.bed is int or p.bed < -1 or p.bed >= r.beds.size() or not p.helper is int or p.helper < -1 or p.helper >= n: return false
		for key in ["health", "care", "clock"]:
			if not (p[key] is float or p[key] is int) or not is_finite(p[key]) or p[key] < 0: return false
		if p.health > 100 or p.care > 12 or not p.supplies is int or p.supplies not in [0, 2]: return false
		if r.workers[id].controller.state != "injured" or r.workers[id].worker.carrying != 0: return false
		if p.phase != "down" and p.bed < 0: return false
		if p.bed >= 0:
			if beds.has(p.bed) or r.beds[p.bed].occupant != id or not r.beds[p.bed].built: return false
			beds[p.bed] = id
		if p.helper >= 0 and (not value.helpers.has(p.helper) or not value.helpers[p.helper] is Dictionary or value.helpers[p.helper].get("patient") != id): return false
		if p.phase == "carried" and p.helper < 0: return false
	for id in value.helpers:
		if not id is int or id < 0 or id >= n or value.patients.has(id): return false
		var m = value.helpers[id]
		if not m is Dictionary or not m.has_all(["patient", "stage", "depot", "bundle", "clock"]): return false
		if not value.patients.has(m.patient) or value.patients[m.patient].helper != id: return false
		if m.stage not in ["approach", "load", "transport", "place", "supply", "fetch", "treat_walk", "treat"]: return false
		if r.workers[id].controller.state != "rescue": return false
		var phase: String = value.patients[m.patient].phase
		if m.stage in ["approach", "load"] and phase != "down": return false
		if m.stage in ["transport", "place"] and phase != "carried": return false
		if m.stage in ["supply", "fetch", "treat_walk", "treat"] and phase != "bed": return false
		if not m.bundle is int or m.bundle not in [0, 2] or not m.depot is int or m.depot < -1 or m.depot >= r.gates.size(): return false
		if not (m.clock is float or m.clock is int) or not is_finite(m.clock) or m.clock < 0: return false
		if m.stage == "fetch":
			var claim = r.outgoing.get("health:%d" % id, {})
			if claim.get("id", -2) != m.depot or claim.get("quantity", 0) != 2 or claim.get("kind", "") != "fiber": return false
	for i in range(n):
		if r.workers[i].controller.state == "injured" and not value.patients.has(i): return false
		if r.workers[i].controller.state == "rescue" and not value.helpers.has(i): return false
	return true
