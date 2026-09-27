extends RefCounted
## Data-only runtime graph. No object IDs, scripts, resources or executable variants
## are loaded from disk. Site references use stable indices in this snapshot.
const COMPONENTS := ["ladder", "bridge", "refuge", "delivery_ledger"]

static func plain(value: Dictionary) -> Dictionary:
	var result := {}
	for key in value:
		if typeof(value[key]) != TYPE_OBJECT: result[key] = value[key]
	return result

static func properties(obj: Object, exclude: Array = []) -> Dictionary:
	var result := {}
	for info in obj.get_property_list():
		if not (info.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or info.name in exclude: continue
		var value = obj.get(info.name)
		if typeof(value) != TYPE_OBJECT: result[info.name] = value
	return result

static func pack(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING_NAME: return str(value)
		TYPE_INT: return {"i": str(value)}
		TYPE_FLOAT: return {"f": PackedFloat64Array([value]).to_byte_array().hex_encode()} # Exact IEEE-754, including navigation INF.
		TYPE_VECTOR3: return {"v": [pack(value.x), pack(value.y), pack(value.z)]}
		TYPE_BASIS: return {"b": [pack(value.x), pack(value.y), pack(value.z)]}
		TYPE_TRANSFORM3D: return {"t": [pack(value.basis), pack(value.origin)]}
		TYPE_PACKED_VECTOR3_ARRAY:
			var points := []
			for point in value: points.append(pack(point))
			return {"p": points}
		TYPE_ARRAY:
			var items := []
			for item in value: items.append(pack(item))
			return items
		TYPE_DICTIONARY:
			var entries := []
			for key in value: entries.append([pack(key), pack(value[key])])
			return {"d": entries}
	return value

static func unpack(value: Variant) -> Variant:
	if value is Array:
		var items := []
		for item in value: items.append(unpack(item))
		return items
	if not value is Dictionary: return value
	if value.has("i"): return int(value.i)
	if value.has("f"):
		return value.f.hex_decode().to_float64_array()[0]
	if value.has("v"): return Vector3(unpack(value.v[0]), unpack(value.v[1]), unpack(value.v[2]))
	if value.has("b"): return Basis(unpack(value.b[0]), unpack(value.b[1]), unpack(value.b[2]))
	if value.has("t"): return Transform3D(unpack(value.t[0]), unpack(value.t[1]))
	if value.has("p"): return PackedVector3Array(unpack(value.p))
	var result := {}
	for pair in value.d: result[unpack(pair[0])] = unpack(pair[1])
	return result

static func encoded(value: Variant, depth: int = 0) -> bool:
	if depth > 24: return false
	if value == null or value is bool or value is String: return true
	if value is Array:
		if value.size() > 16384: return false
		for item in value:
			if not encoded(item, depth + 1): return false
		return true
	if not value is Dictionary or value.size() != 1: return false
	var key: String = str(value.keys()[0])
	var item = value[key]
	match key:
		"i": return item is String and item.is_valid_int()
		"f":
			if not item is String or item.length() != 16: return false
			for ch in item:
				if not ch in "0123456789abcdef": return false
			return not is_nan(item.hex_decode().to_float64_array()[0])
		"v", "b", "t":
			if not item is Array or item.size() != (2 if key == "t" else 3): return false
			for i in range(item.size()):
				var expected := "f" if key == "v" else ("v" if key == "b" or i == 1 else "b")
				if not item[i] is Dictionary or not item[i].has(expected) or not encoded(item[i], depth + 1): return false
			return true
		"p":
			if not item is Array: return false
			for point in item:
				if not point is Dictionary or not point.has("v") or not encoded(point, depth + 1): return false
			return true
		"d":
			if not item is Array or item.size() > 16384: return false
			var keys := {}
			for pair in item:
				if not pair is Array or pair.size() != 2 or not encoded(pair[0], depth + 1) or not encoded(pair[1], depth + 1): return false
				var k = unpack(pair[0])
				if not (k is String or k is int) or keys.has(k): return false
				keys[k] = true
			return true
	return false

static func capture(g: Node) -> Dictionary:
	var r := {"clock": {"elapsed": g.elapsed, "meal_timer": g.meal_timer, "suspicion": g.suspicion, "hunger": g.hunger, "event_index": g.event_index}, "hiding": g.hiding, "workers": [], "components": {}, "patches": [], "beds": [], "orders": [], "items": [], "recovery": [], "construction_jobs": {}, "construction_next": g.construction.next_id,
		"incoming": g.depots.incoming.duplicate(true), "outgoing": g.depots.outgoing.duplicate(true), "gates": [], "torch_missions": g.torches.missions.duplicate(true), "crafting": g.torches.crafting.duplicate(),
		"fissure": {"missions": g.fissure.missions.duplicate(true), "queue": g.fissure.queue.duplicate(), "owner": g.fissure.owner, "follow": g.fissure.follow, "reserved": g.fissure.hauling.reserved, "site": plain(g.fissure.site), "upgrade": plain(g.fissure.upgrade)}}
	for name in COMPONENTS: r.components[name] = properties(g.get(name), ["patches"])
	for w in g.workers:
		var c: WorkerDelivery = w.delivery
		r.workers.append({"worker": plain(w), "controller": properties(c, ["worker"]), "transform": c.actor.transform, "visible": c.actor.visible,
			"clip": c.actor.current, "clip_time": c.actor.player.current_animation_position, "cargo_visible": c.actor.cargo.visible,
			"cargo_parent": "world" if c.actor.cargo.get_parent() == g else "hands", "cargo_transform": c.actor.cargo.transform})
	for patch in g.patches: r.patches.append(plain(patch))
	for bed in g.sleeping.beds: r.beds.append(plain(bed))
	for order in g.torches.orders: r.orders.append(plain(order))
	for item in g.torches.items: r.items.append(plain(item))
	for pile in g.construction.recovery: r.recovery.append(plain(pile))
	for depot in g.depots.sites: r.gates.append(properties(depot.gate, ["patches"]))
	var sites: Array = g.construction.sites()
	for id in g.construction.jobs:
		var job: Dictionary = g.construction.jobs[id].duplicate()
		job.source = -1 if job.source.is_empty() else g.construction.recovery.find(job.source)
		job.target = -1 if job.target.is_empty() else sites.find(job.target)
		r.construction_jobs[id] = job
	r.health = g.health.snapshot()
	r.rooms = g.rooms.snapshot()
	r.fixed_lighting = g.fixed_lighting.snapshot()
	r.transfers = g.transfers.snapshot()
	r.depot_sites = []
	for depot in g.depots.sites.slice(1): r.depot_sites.append(plain(depot))
	r.designations = g.designations.snapshot()
	var data = pack(r)
	return {"schema": 1, "data": data, "sha256": JSON.stringify(data).sha256_text()}

static func validate(data: Dictionary) -> String:
	var value = data.get("runtime")
	if not value is Dictionary or not value.has_all(["schema", "data", "sha256"]) or value.schema != 1: return "État d’expédition incomplet."
	if not value.sha256 is String or JSON.stringify(value.data).sha256_text() != value.sha256: return "État d’expédition altéré."
	if not encoded(value.data) or not value.data is Dictionary or not value.data.has("d"): return "Encodage d’expédition invalide."
	var r: Dictionary = unpack(value.data)
	if not r.has_all(["clock", "hiding", "workers", "components", "patches", "beds", "orders", "items", "recovery", "construction_jobs", "construction_next", "incoming", "outgoing", "gates", "torch_missions", "crafting", "fissure"]): return "Simulation incomplète."
	for key in ["workers", "patches", "beds", "orders", "items", "recovery", "gates"]:
		if not r[key] is Array: return "Liste de simulation invalide."
	for key in ["clock", "components", "construction_jobs", "incoming", "outgoing", "torch_missions", "crafting", "fissure"]:
		if not r[key] is Dictionary: return "Registre de simulation invalide."
	for key in ["elapsed", "meal_timer", "suspicion", "hunger", "event_index"]:
		if not r.clock.has(key) or not (r.clock[key] is float or r.clock[key] is int) or not is_equal_approx(r.clock[key], data.clock.get(key, -2)): return "Horloge active incohérente."
	if not r.hiding is bool or r.workers.size() != data.assignments.size() or r.patches.size() != data.patches.size() or r.beds.size() != data.furnishings.size() or r.items.size() != data.torches.items.size() or r.gates.size() != data.depots.size(): return "Population ou inventaire incohérent."
	if not r.components.has_all(COMPONENTS): return "Accès de simulation manquant."
	if not r.fissure.has_all(["missions", "queue", "owner", "reserved", "site", "upgrade"]) or not r.fissure.missions is Dictionary or not r.fissure.queue is Array: return "Expédition incomplète."
	for i in range(r.patches.size()):
		var patch = r.patches[i]
		if not patch is Dictionary or not patch.has_all(["kind", "amount", "discovered", "reserved"]): return "Source active incomplète."
		for key in ["kind", "amount", "discovered"]:
			if patch[key] != data.patches[i][key]: return "Source active incohérente."
		if not patch.reserved is int or patch.reserved < 0 or patch.reserved > patch.amount: return "Réservation de source invalide."
	for i in range(r.beds.size()):
		var bed = r.beds[i]
		if not bed is Dictionary or not bed.has_all(["owner", "materials", "work", "built", "occupant", "builder", "hauler", "pos", "required", "private"]): return "Lit actif incomplet."
		for key in ["owner", "built"]:
			if bed[key] != data.furnishings[i][key]: return "Lit actif incohérent."
		for kind in ["wood", "fiber"]:
			if bed.materials.get(kind, -1) != data.furnishings[i].materials[kind]: return "Matériaux du lit incohérents."
		if not is_equal_approx(bed.work, data.furnishings[i].work): return "Travaux de lit incohérents."
	for component in COMPONENTS:
		if not r.components[component] is Dictionary: return "Accès invalide."
	if not r.components.delivery_ledger.has_all(["jobs", "source_slots", "next_id"]): return "Registre de récolte incomplet."
	var n: int = r.workers.size()
	if not r.fissure.get("follow", -1) is int or r.fissure.get("follow", -1) < -1 or r.fissure.get("follow", -1) >= n: return "Suivi de caméra invalide."
	if r.has("designations") and not preload("res://scripts/work_designations.gd").valid(r.designations, r): return "Ordre autonome incohérent."
	if data.version >= 11:
		if not r.get("depot_sites") is Array or r.depot_sites.size() != data.depots.size() - 1: return "Chantiers de dépôts incomplets."
		for i in range(r.depot_sites.size()):
			var site = r.depot_sites[i]
			if not site is Dictionary or not site.has_all(["built", "active", "work", "materials", "hauler", "builder"]): return "Dépôt actif incomplet."
			for key in ["built", "active", "work", "materials"]:
				if key == "materials":
					for kind in ["wood", "fiber"]:
						if site.materials.get(kind, -1) != data.depots[i + 1].materials[kind]: return "Matériaux de dépôt incohérents."
				elif site[key] != data.depots[i + 1][key]: return "Chantier de dépôt incohérent."
			for key in ["builder", "hauler"]:
				if not site[key] is int or site[key] < -1 or site[key] >= n: return "Responsable de dépôt invalide."
			if site.builder >= 0 and r.workers[site.builder].controller.get("depot_order", -1) != i + 1: return "Artisan de dépôt orphelin."
	if data.version >= 12 and not preload("res://scripts/depot_transfers.gd").valid(r.get("transfers"), r, data): return "Liaison ou charge de transfert incohérente."
	if data.version >= 13 and not preload("res://scripts/fixed_lighting.gd").valid(r.get("fixed_lighting"), r): return "Éclairage fixe incohérent."
	if data.version >= 14 and not preload("res://scripts/constructed_rooms.gd").valid(r.get("rooms"), r): return "Chambre construite incohérente."
	if data.version >= 16 and not preload("res://scripts/colony_health.gd").valid(r.get("health"), r): return "Secours ou soins incohérents."
	var source_reserved := 0
	for i in range(n):
		var w = r.workers[i]
		if not w is Dictionary or not w.has_all(["worker", "controller", "transform", "visible", "clip", "clip_time", "cargo_parent", "cargo_transform", "cargo_visible"]): return "Habitant incomplet."
		if not w.worker is Dictionary or not w.controller is Dictionary or not w.transform is Transform3D or not w.cargo_transform is Transform3D: return "Position d’habitant invalide."
		if not w.controller.has_all(["owner", "sector_id", "job", "supply_job", "state", "inside_refuge"]) or w.controller.owner != i: return "Identité d’habitant incohérente."
		if not w.controller.sector_id in ["refuge_south", "alcove_north"] or not w.cargo_parent in ["hands", "world"]: return "Secteur ou charge invalide."
		if not w.worker.has_all(["carrying", "kind"]) or not w.worker.carrying is int or w.worker.carrying < 0 or w.worker.carrying > 67: return "Charge invalide."
		for key in ["energy", "comfort", "privacy", "nutrition", "hydration"]:
			if not w.worker.has(key) or not (w.worker[key] is float or w.worker[key] is int) or not is_equal_approx(w.worker[key], data.needs[i][key]): return "Besoin actif incohérent."
		if w.controller.has("depot_order"):
			var order = w.controller.depot_order
			if not order is int or order < -1 or order == 0 or order >= data.depots.size(): return "Chantier de dépôt d’habitant invalide."
			if order > 0 and (not r.has("depot_sites") or r.depot_sites[order - 1].builder != i or r.depot_sites[order - 1].built or not r.depot_sites[order - 1].active): return "Artisan sans chantier de dépôt."
		if w.worker.has("priorities") and not preload("res://scripts/work_priorities.gd").valid(w.worker.priorities): return "Priorités de travail invalides."
		if w.worker.get("patch", -2) != data.assignments[i]: return "Affectation active incohérente."
		if w.controller.job >= 0 and not r.components.delivery_ledger.jobs.has(w.controller.job) and not (w.controller.state == "putdown" and w.controller.get("deposited", false) and w.worker.carrying == 0): return "Récolte orpheline."
		if w.controller.sector_id == "alcove_north" and not r.fissure.missions.has(i): return "Habitant perdu hors secteur."
		if w.controller.supply_job >= 0 and not r.construction_jobs.has(w.controller.supply_job): return "Transport de chantier orphelin."
	for id in r.fissure.missions:
		var m = r.fissure.missions[id]
		if not id is int or id < 0 or id >= n or not m is Dictionary or not m.has_all(["phase", "side", "inspect", "returning", "clock"]): return "Mission invalide."
		if not m.phase in ["approach", "inspect", "wait", "entry", "cross", "clear", "look_walk", "look", "back", "harvest_walk", "harvest", "harvest_pickup", "delivery_wait", "delivery_walk", "delivery_drop"] or not m.side in ["near", "far"]: return "Phase d’expédition inconnue."
		if m.phase in ["entry", "cross", "clear"] and r.fissure.owner != id: return "Seuil sans réservation."
		if not m.inspect and (not r.torch_missions.has(id) or r.torch_missions[id].phase != "sector"): return "Expédition sans lanterne."
		if m.has("quantity"):
			if not m.has_all(["collected", "released", "deposited", "token", "depot", "ticket"]) or not m.quantity is int or m.quantity <= 0: return "Prélèvement invalide."
			if not m.collected and not m.released: source_reserved += m.quantity
			if not m.released and not m.deposited:
				if not r.incoming.has(m.token) or r.incoming[m.token].quantity != m.quantity or r.incoming[m.token].id != m.depot: return "Place au dépôt perdue."
			if m.collected and not m.deposited and r.workers[id].worker.carrying != m.quantity: return "Caisse d’expédition incohérente."
	if source_reserved != r.fissure.reserved or source_reserved > data.fissure.fiber: return "Réservation de fibres incohérente."
	if r.fissure.owner != -1 and not r.fissure.missions.has(r.fissure.owner): return "Propriétaire de seuil orphelin."
	var queued := {}
	for id in r.fissure.queue:
		if queued.has(id) or not r.fissure.missions.has(id) or r.fissure.missions[id].phase != "wait": return "File de fissure incohérente."
		queued[id] = true
	var owners := {}
	for i in range(r.items.size()):
		var item = r.items[i]
		if not item is Dictionary or not item.has_all(["owner", "reserved", "lit", "fuel", "kind"]) or not is_equal_approx(item.fuel, data.torches.items[i].fuel) or item.kind != data.torches.items[i].kind: return "Équipement incohérent."
		if not item.owner is int or item.owner < -1 or item.owner >= n: return "Propriétaire d’équipement invalide."
		if item.owner >= 0:
			if owners.has(item.owner) or not r.torch_missions.has(item.owner) or r.torch_missions[item.owner].item != i: return "Équipement dupliqué ou orphelin."
			owners[item.owner] = true
	for token in r.incoming:
		var claim = r.incoming[token]
		if not claim is Dictionary or not claim.has_all(["id", "quantity", "kind"]) or not claim.id is int or claim.id < 0 or claim.id >= data.depots.size() or not claim.quantity is int or claim.quantity < 1: return "Réservation de dépôt invalide."
	for id in range(data.depots.size()):
		var used := 0
		for quantity in data.depots[id].stock.values(): used += int(quantity)
		for claim in r.incoming.values():
			if claim.id == id: used += claim.quantity
		if data.version >= 11 and id > 0 and not data.depots[id].built and used > 0: return "Réservation dans un dépôt en construction."
		if used > data.depots[id].capacity: return "Capacité de dépôt sur-réservée."
	return ""

static func apply_properties(obj: Object, values: Dictionary) -> bool:
	var allowed := properties(obj)
	for key in values:
		if not allowed.has(key): return false
		var current = obj.get(key)
		if typeof(current) != typeof(values[key]): return false
		if current is Array:
			current.assign(values[key])
		else: obj.set(key, values[key])
	return true

static func merge(target: Dictionary, values: Dictionary) -> void:
	for key in values: target[key] = values[key]

static func restore(g: Node, data: Dictionary) -> bool:
	var r: Dictionary = unpack(data.runtime.data)
	g.health.restore(r.get("health", {}))
	g.rooms.restore(r.get("rooms", []))
	g.fixed_lighting.restore(r.get("fixed_lighting", {}))
	g.transfers.restore(r.get("transfers", {}))
	g.designations.restore(r.get("designations", {}))
	for key in ["elapsed", "meal_timer", "suspicion", "hunger", "event_index"]: g.set(key, r.clock[key])
	# Recreate render nodes through trusted existing constructors, then relink data.
	for order in g.torches.orders:
		if order.has("supplies"): order.supplies.queue_free()
	g.torches.orders.clear()
	for order in r.orders:
		g.torches.orders.append(order)
		g.torches.refresh_site(order)
	for i in range(r.beds.size()):
		merge(g.sleeping.beds[i], r.beds[i])
		g.sleeping.visual(i)
	for pile in g.construction.recovery: pile.node.queue_free()
	g.construction.recovery.clear()
	for pile in r.recovery:
		g.construction.add_recovery(pile.pos, pile.materials)
		merge(g.construction.recovery[-1], pile)
	merge(g.fissure.site, r.fissure.site)
	merge(g.fissure.upgrade, r.fissure.upgrade)
	g.fissure.missions = r.fissure.missions
	g.fissure.queue.assign(r.fissure.queue)
	g.fissure.owner = r.fissure.owner
	g.fissure.follow = int(r.fissure.get("follow", -1))
	g.fissure.hauling.reserved = r.fissure.reserved
	g.torches.missions = r.torch_missions
	g.torches.crafting = r.crafting
	for i in range(r.items.size()):
		merge(g.torches.items[i], r.items[i])
		g.torches.items[i].node.visible = r.items[i].owner < 0
	g.depots.incoming = r.incoming
	g.depots.outgoing = r.outgoing
	for i in range(r.gates.size()):
		if not apply_properties(g.depots.gate(i), r.gates[i]): return false
	for key in COMPONENTS:
		if not apply_properties(g.get(key), r.components[key]): return false
	for i in range(r.patches.size()): merge(g.patches[i], r.patches[i])
	if r.has("depot_sites"):
		for i in range(r.depot_sites.size()):
			merge(g.depots.sites[i + 1], r.depot_sites[i])
			g.depots.refresh(i + 1)
	g.construction.next_id = r.construction_next
	var sites: Array = g.construction.sites()
	for id in r.construction_jobs:
		var job: Dictionary = r.construction_jobs[id]
		if not job.source is int or not job.target is int or job.source < -1 or job.target < -1 or job.source >= g.construction.recovery.size() or job.target >= sites.size(): return false
		job.source = {} if job.source < 0 else g.construction.recovery[job.source]
		job.target = {} if job.target < 0 else sites[job.target]
		g.construction.jobs[id] = job
	for i in range(r.workers.size()):
		var saved: Dictionary = r.workers[i]
		var c: WorkerDelivery = g.workers[i].delivery
		merge(g.workers[i], saved.worker)
		if not apply_properties(c, saved.controller): return false
		if not c.actor.player.has_animation(saved.clip): return false
		c.actor.transform = saved.transform
		c.actor.visible = saved.visible
		c.pose(saved.clip, saved.clip_time)
		c.actor.cargo.reparent(g if saved.cargo_parent == "world" else c.cargo_socket, false)
		c.actor.cargo.transform = saved.cargo_transform
		c.actor.cargo.visible = saved.cargo_visible
		var index: int = g.torches.held(i)
		if index >= 0:
			var item: Dictionary = g.torches.items[index]
			c.actor.lantern.visible = item.kind == "lantern"
			c.actor.torch.visible = item.kind == "torch"
			c.actor.lantern_light.visible = item.lit and item.kind == "lantern"
			c.actor.torch_light.visible = item.lit and item.kind == "torch"
			var light: OmniLight3D = c.actor.lantern_light if item.kind == "lantern" else c.actor.torch_light
			light.light_energy = (1.65 + .10 * sin(g.elapsed * 8 + i) + .07 * sin(g.elapsed * 13.7)) * minf(1, item.fuel / 8.0)
			c.actor.lantern_material.set_shader_parameter("clock", g.elapsed)
			c.actor.torch_material.set_shader_parameter("clock", g.elapsed)
			c.actor.lantern_flame.visible = item.lit
			c.actor.torch_flame.visible = item.lit
	g.health.refresh_visuals()
	g.hiding = r.hiding
	g.refuge.update(0)
	g.fissure.refresh()
	return true
