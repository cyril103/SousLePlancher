extends RefCounted
## One maintained waypoint on the existing east route; no global lighting simulation.
const COST := {"wood": 4, "fiber": 2}
const REFILL := {"wood": 2, "fiber": 0}
const WORK := 16.0
const CAPACITY := 180.0
const POSITION := Vector3(6.1, 2.04, -5.8)
const ENTRY := Vector3(6.1, 2.0295, -5.1)
var game: Node
var site: Dictionary = {}
var refill: Dictionary = {}
var fuel := 0.0
var automatic := true
var enabled := true
var burned := 0.0
var loaded := 0
var node: Node3D
var light: OmniLight3D
var flame: MeshInstance3D
var label: Label3D

func sites() -> Array:
	return [] if site.is_empty() else [site, refill]

func plan() -> void:
	if not site.is_empty():
		site.active = true
		refresh()
		return
	if not game.east_discovered:
		game._news("Reconnaître la réserve de l’Est avant d’aménager son éclairage.")
		return
	site = {"fixed_site": true, "fuel_site": false, "pos": POSITION, "active": true, "built": false, "work": 0.0, "required": WORK, "materials": {"wood": 0, "fiber": 0}, "builder": -1, "hauler": -1}
	refill = {"fixed_site": true, "fuel_site": true, "pos": POSITION, "active": false, "built": false, "work": 0.0, "required": 0.0, "materials": {"wood": 0, "fiber": 0}, "builder": -1, "hauler": -1}
	create_visual()
	refresh()
	game._news("Brasero commandé : la liaison attendra sa mise en lumière. Construction puis combustible livrés sur place.")

func create_visual() -> void:
	if is_instance_valid(node): node.queue_free()
	node = Node3D.new()
	game.add_child(node)
	node.position = POSITION
	var model := preload("res://assets/models/torch.glb").instantiate() as Node3D
	node.add_child(model)
	model.name = "Support"
	model.scale = Vector3.ONE * .65
	light = OmniLight3D.new()
	node.add_child(light)
	light.position.y = .88
	light.light_color = Color("ffb459")
	light.omni_range = 6.5
	light.light_energy = 2.2
	light.shadow_enabled = true
	flame = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = .07
	mesh.height = .3
	flame.mesh = mesh
	flame.position.y = .8
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/flame.gdshader")
	material.set_shader_parameter("seed", 6.1)
	flame.material_override = material
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(flame)
	label = game.Art.caption(node, "", Vector3(0, 1.35, 0))
	label.pixel_size = .0035

func lit() -> bool:
	return not site.is_empty() and site.built and enabled and fuel > 0

func protects(source: int, target: int) -> bool:
	if site.is_empty() or not site.active: return false
	return (game.depots.entry(source).x > 9) != (game.depots.entry(target).x > 9)

func update(dt: float) -> void:
	if site.is_empty(): return
	if lit():
		var amount := minf(fuel, dt)
		fuel -= amount
		burned += amount
		if fuel == 0: game._news("Brasero éteint : nouvelles rotations suspendues, combustible attendu.")
	# Consume a delivered batch only after its porter has completed the deposit.
	if site.built and refill.hauler < 0 and refill.materials.wood == 2 and fuel <= 0:
		fuel = CAPACITY
		loaded += 2
		refill.materials.wood = 0
		game._news("Brasero ravitaillé : 180 s de combustible, liaisons disponibles s’il est allumé.")
	refill.active = site.built and automatic and fuel <= 90
	refresh()

func refresh() -> void:
	if site.is_empty() or not is_instance_valid(node): return
	game.depots.set_ghost(node.get_node("Support"), not site.built)
	light.visible = lit()
	flame.visible = lit()
	light.light_energy = 2.2 + sin(game.elapsed * 8) * .16
	label.text = "Brasero · %ds" % ceili(fuel) if site.built else "Brasero · " + (game.construction.status(site) if site.active else "Plan annulé")

func start_work(c: WorkerDelivery) -> bool:
	if site.is_empty() or not site.active or site.built or site.builder >= 0 or site.hauler >= 0 or not game.construction.supplied(site): return false
	var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
	if game.travel_path(from, ENTRY, c.owner).is_empty(): return false
	if c.inside_refuge:
		c.change("leave_home")
		return true
	site.builder = c.owner
	c.change("fixed_walk")
	return true

func tick(c: WorkerDelivery, dt: float) -> bool:
	if site.is_empty() or site.builder != c.owner: return false
	if c.state == "fixed_walk":
		if c.move(ENTRY, dt, false):
			c.actor.rotation.y = 0
			c.change("fixed_work")
		elif not c.navigation_issue.is_empty(): cancel_worker(c)
	else:
		c.pose("work", fposmod(c.timer, 1.2))
		site.work = minf(WORK, site.work + dt)
		if site.work >= WORK:
			site.built = true
			site.builder = -1
			c.change("idle")
			game._news("Brasero construit : deux bois de combustible doivent encore être livrés.")
	refresh()
	return true

func cancel_worker(c: WorkerDelivery) -> bool:
	if site.is_empty() or site.builder != c.owner: return false
	site.builder = -1
	c.change("return_home")
	return true

func cancel_plan() -> void:
	if site.is_empty() or site.built: return
	game.construction.cancel_site(site)
	if site.builder >= 0: cancel_worker(game.workers[site.builder].delivery)
	site.materials = {"wood": 0, "fiber": 0}
	site.work = 0.0
	site.active = false
	refresh()

func toggle_auto() -> void:
	automatic = not automatic
	if not automatic and not refill.is_empty():
		refill.active = false
		for w in game.workers:
			var c: WorkerDelivery = w.delivery
			if c.supply_job >= 0 and game.construction.jobs[c.supply_job].target == refill: c.cancel()

func summary() -> String:
	if site.is_empty(): return "Aménager le palier avant la passerelle. 4 bois + 2 fibres, puis 16 s de construction."
	if not site.built: return (game.construction.status(site) if site.active else "Plan annulé, matériaux récupérables.") + "\n" + game.construction.quantities(site)
	return "%s · %d / 180 s\nCombustible en attente : %d / 2 bois\nEntretien automatique : %s\n%s" % ["Allumé" if lit() else "Éteint", ceili(fuel), refill.materials.wood, "oui" if automatic else "non", game.construction.status(refill) if refill.active else "Aucune nouvelle livraison demandée."]

func snapshot() -> Dictionary:
	return {"site": site.duplicate(true), "refill": refill.duplicate(true), "fuel": fuel, "automatic": automatic, "enabled": enabled, "burned": burned, "loaded": loaded}

func restore(data: Dictionary) -> void:
	site = data.get("site", {}).duplicate(true)
	refill = data.get("refill", {}).duplicate(true)
	fuel = float(data.get("fuel", 0))
	automatic = data.get("automatic", true)
	enabled = data.get("enabled", true)
	burned = float(data.get("burned", 0))
	loaded = int(data.get("loaded", 0))
	if not site.is_empty():
		create_visual()
		refresh()

static func valid(value: Variant, runtime: Dictionary) -> bool:
	if not value is Dictionary or not value.has_all(["site", "refill", "fuel", "automatic", "enabled", "burned", "loaded"]): return false
	if not value.site is Dictionary or not value.refill is Dictionary or not value.automatic is bool or not value.enabled is bool: return false
	if not (value.fuel is float or value.fuel is int) or not is_finite(value.fuel) or value.fuel < 0 or value.fuel > CAPACITY: return false
	if not value.loaded is int or value.loaded < 0 or value.loaded % 2 != 0 or not (value.burned is float or value.burned is int) or not is_finite(value.burned) or value.burned < 0: return false
	if not is_equal_approx(value.loaded * 90.0, value.burned + value.fuel): return false
	if value.site.is_empty(): return value.refill.is_empty() and value.fuel == 0 and value.loaded == 0
	for s in [value.site, value.refill]:
		if not s.has_all(["fixed_site", "fuel_site", "pos", "active", "built", "work", "required", "materials", "builder", "hauler"]): return false
		if s.fixed_site != true or not s.fuel_site is bool or not s.active is bool or not s.built is bool or s.pos != POSITION: return false
		if not s.materials is Dictionary or not s.materials.has_all(["wood", "fiber"]): return false
		var cost: Dictionary = REFILL if s.fuel_site else COST
		for kind in cost:
			if not s.materials[kind] is int or s.materials[kind] < 0 or s.materials[kind] > cost[kind]: return false
		for key in ["builder", "hauler"]:
			if not s[key] is int or s[key] < -1 or s[key] >= runtime.workers.size(): return false
		if not (s.work is float or s.work is int) or not is_finite(s.work) or s.work < 0 or s.work > WORK: return false
	if value.site.fuel_site or not value.refill.fuel_site or value.refill.built or value.refill.builder != -1: return false
	if value.site.built != (value.site.work == WORK) or value.site.required != WORK: return false
	if value.site.work > 0 and value.site.materials != COST: return false
	if not value.site.built and (value.fuel > 0 or value.refill.active): return false
	var builder: int = value.site.builder
	if builder >= 0 and (value.site.built or not value.site.active or not runtime.workers[builder].controller.state in ["fixed_walk", "fixed_work"]): return false
	for i in range(runtime.workers.size()):
		if str(runtime.workers[i].controller.state).begins_with("fixed_") and builder != i: return false
	return true
