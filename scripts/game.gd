extends Node3D
## Première boucle de gestion : récolte, construction, discrétion et survie.
const Art = preload("res://scripts/world.gd")
const Navigation = preload("res://scripts/ground_navigation.gd")
const Ladder = preload("res://scripts/ladder_passage.gd")
const Bridge = preload("res://scripts/bridge_passage.gd")
const Save = preload("res://scripts/colony_save.gd")
const Refuge = preload("res://scripts/refuge_access.gd")
const Sleep = preload("res://scripts/colony_sleep.gd")
const Needs = preload("res://scripts/colony_needs.gd")
const Construction = preload("res://scripts/construction_logistics.gd")
const HOME := Vector3(-3, 0, 1)
const COSTS := {"bed": {"wood": 4, "fiber": 3}, "private_bed": {"wood": 6, "fiber": 5}, "shelter": {"wood": 8, "fiber": 4}, "workshop": {"wood": 10, "fiber": 6}}
var sleeping := Sleep.new()
var needs := Needs.new()
var construction := Construction.new()
const NAMES := {"food": "Miettes", "wood": "Bois", "fiber": "Fibres", "water": "Eau"}
var stock := {"food": 24, "wood": 12, "fiber": 6, "water": 16}
var patches: Array[Dictionary] = []
var workers: Array[Dictionary] = []
var save_path := Save.DEFAULT_PATH
var pending_save := false
var save_available := false
var save_status := "Aucune sauvegarde."
var delivery_ledger := DeliveryLedger.new()
var buildings: Array[Dictionary] = []
var camera: Camera3D
var focus := Vector3.ZERO
var yaw := 0.32
var zoom := 23.5
var selected := -1
var build_mode := ""
var ghost: Node3D
var hiding := false
var paused := true
var speed := 1.0
var elapsed := 0.0
var meal_timer := 0.0
var suspicion := 0.0
var hunger := 0.0
var shelters := 0
var workshops := 0
var ended := false
var event_index := -1
var hud: Control
var time_label: Label
var detail_label: Label
var objective_label: Label
var news_label: Label
var alert_bar: ProgressBar
var pause_button: Button
var hide_button: Button
var start_panel: PanelContainer
var end_panel: PanelContainer
var end_label: Label
var trays: Dictionary = {}
var dock_buttons: Dictionary = {}
var active_tray := ""
var patch_picker: OptionButton
var assign_button: Button
var release_button: Button
var speed_button: Button
var notice_timer := 0.0
var bridge := Bridge.new()
var east_navigation := Navigation.new()
var east_obstacles: Array[Rect2] = []
var east_stands: Array[Rect2] = []
var east_discovered := false
var east_label: Label3D
var east_stand: Node3D
var water_stand: Node3D
var ladder := Ladder.new()
var refuge: Node3D
var upper_navigation := Navigation.new()
var upper_obstacles: Array[Rect2] = []
var upper_stands: Array[Rect2] = []
var navigation := Navigation.new()
var navigation_obstacles: Array[Rect2] = []
var navigation_stands: Array[Rect2] = []
var home_slots: Array[Vector3] = []
var depot_slots: Array[Vector3] = []
var show_paths := false
var route_mesh: MeshInstance3D
var route_timer := 0.0

func _ready() -> void:
	sleeping.game = self
	construction.game = self
	needs.game = self
	Art.decorate(self)
	refuge = Refuge.new()
	refuge.position = HOME
	add_child(refuge)
	var refuge_label := Art.caption(refuge, "Refuge", Vector3(0, 2.35, -.6), Color("eac37e"))
	refuge_label.pixel_size = .0055
	get_node("Atmosphere").add_torch(HOME + Vector3(1.05, 0, .65))
	buildings.append({"pos": HOME, "kind": "heart"})
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 150
	add_child(camera)
	camera.current = true
	_update_camera()
	_add_patch("food", Vector3(4, 0, -2), 70)
	_add_patch("food", Vector3(-7, 0, -4), 50)
	_add_patch("wood", Vector3(1, 0, 4), 65)
	_add_patch("wood", Vector3(5.2, 2.04, -4.5), 50)
	_add_patch("fiber", Vector3(-7, 0, 3), 45)
	_add_patch("fiber", Vector3(3.7, 2.04, -5.5), 40)
	_add_patch("wood", Vector3(9.7, 2.04, -5.5), 90)
	patches[-1].discovered = false
	patches[-1].label.position = Vector3(.7, 1, .8)
	patches[-1].node.hide()
	_add_patch("water", Vector3(7, 0, 2), 120)
	var east := preload("res://assets/models/exploration_10/east_store_platform.glb").instantiate() as Node3D
	add_child(east)
	east.position = Vector3(10.5, 0, -4.55)
	var bridge_model := preload("res://assets/models/refuge_02/bridge_2m.glb").instantiate() as Node3D
	add_child(bridge_model)
	bridge_model.position = Vector3(8, 1.989, -4)
	bridge_model.rotation.y = PI / 2
	east_label = Art.caption(self, "Réserve inexplorée", Vector3(10.5, 3.3, -3.3), Color("eac37e"))
	east_label.pixel_size = .005
	var landing := preload("res://assets/models/exploration_10/landing_connected.glb").instantiate() as Node3D
	add_child(landing)
	landing.position = Vector3(5, 0, -4.55)
	var ladder_model := preload("res://assets/models/refuge_02/ladder_2m.glb").instantiate() as Node3D
	add_child(ladder_model)
	ladder_model.position = Ladder.BASE
	delivery_ledger.patches = patches
	_setup_navigation()
	for i in range(4):
		_add_worker()
	_make_loading_stations()
	_refresh_save_state()
	_make_ui()
	_refresh_ui()
	if get_meta("restore_mode", false): return
	if "--demo-deliveries" in OS.get_cmdline_user_args() or "--demo-navigation" in OS.get_cmdline_user_args():
		start_panel.hide()
		paused = false
		if "--demo-navigation" in OS.get_cmdline_user_args():
			_choose_build("workshop")
			_place_build(Vector3.ZERO)
			show_paths = true
		for patch in [0, 2, 4, 1]:
			selected = patch
			assign_worker()
		selected = 2
		_show_tray("")
		_news("Livraisons en cours : C pour les affectations, H pour rappeler les porteurs.")
		if show_paths: _news("Navigation : N affiche le trajet de l’habitant sélectionné. H rappelle la colonie.")
		zoom = 18.0
	if "--demo-ladders" in OS.get_cmdline_user_args():
		start_panel.hide()
		paused = false
		for patch in [3, 5, 0, 2]:
			selected = patch
			assign_worker()
		zoom = 18
		focus = Vector3(2, 0, -2)
		_news("Le palier est accessible : bois et fibres en hauteur. H rappelle les porteurs, N montre leur trajet.")
	if "--demo-doors" in OS.get_cmdline_user_args():
		start_panel.hide()
		paused = false
		zoom = 12
		focus = HOME + Vector3(1, 0, 0)
		for patch in [0, 2, 4, 1]:
			selected = patch
			assign_worker()
		_toggle_hide()
		_news("H fait ressortir les habitants et reprendre leurs tâches. V montre l’intérieur du refuge.")
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()
	if "--demo-exploration" in OS.get_cmdline_user_args():
		start_panel.hide()
		paused = false
		zoom = 18
		focus = Vector3(5, 0, -2)
		start_exploration()
		for i in range(1, 4):
			selected = [0, 1, 2][i - 1]
			assign_worker(i)
		selected = -1
		_news("Un éclaireur reconnaît la réserve. T : exploration ; C : affecter au gisement découvert ; H : rappel.")
	if "--demo-sleep" in OS.get_cmdline_user_args(): prepare_sleep_demo()
	if "--demo-construction" in OS.get_cmdline_user_args(): prepare_construction_demo()
	if "--demo-needs" in OS.get_cmdline_user_args(): prepare_needs_demo()

func prepare_needs_demo() -> void:
	start_panel.hide()
	stock = {"food": 40, "water": 30, "wood": 30, "fiber": 20}
	_choose_build("private_bed")
	_place_build(Vector3(-3, 0, -4))
	for i in range(1600):
		simulate(.05)
		suspicion = 0
	workers[0].energy = 20.0
	for i in range(240): simulate(.05)
	for i in range(1, 4):
		var c: WorkerDelivery = workers[i].delivery
		c.inside_refuge = true
		c.actor.position = refuge.slot(i)
		c.actor.rotation.y = 0
	workers[1].nutrition = 10.0
	workers[2].hydration = 10.0
	workers[3].energy = 10.0
	for i in range(20): simulate(.05)
	refuge.set_cutaway(true)
	paused = true
	zoom = 10
	focus = HOME + Vector3(0, .3, -1.3)
	yaw = .55
	hud.resident_index = 2
	_update_camera()
	_news("Besoins autonomes : sommeil, repas, boisson. Espace reprend ; C inspecte les trois jauges ; Eau se récolte à l’Est.")

func prepare_sleep_demo() -> void:
	start_panel.hide()
	stock = {"food": 150, "wood": 40, "fiber": 30, "water": 30}
	for spec in [["private_bed", Vector3(-3, 0, -4)], ["bed", Vector3(0, 0, -3)]]:
		_choose_build(spec[0])
		_place_build(spec[1])
	for i in range(1600):
		simulate(.05)
		suspicion = 0
	for i in range(2): workers[i].energy = 20.0
	for i in range(220): simulate(.05)
	_choose_build("private_bed")
	_place_build(Vector3(-6, 0, -1))
	selected = 0
	assign_worker(3)
	selected = -1
	paused = true
	zoom = 13
	focus = Vector3(-2.7, 0, -2.2)
	yaw = .32
	_update_camera()
	_news("Sommeil : Espace pour reprendre. B fabrique les lits ; Couchages attribue les propriétaires ; H réveille et rappelle.")

func prepare_construction_demo() -> void:
	start_panel.hide()
	stock = {"food": 80, "water": 50, "wood": 7, "fiber": 3}
	for spec in [["bed", Vector3(-3, 0, -4)], ["private_bed", Vector3(0, 0, -3)]]:
		_choose_build(spec[0])
		_place_build(spec[1])
	paused = true
	zoom = 15
	focus = Vector3(-2, 0, -1.8)
	yaw = .32
	hud.resident_index = 0
	_show_tray("beds")
	_update_camera()
	_news("Deux chantiers, des réserves limitées. Espace : livrer puis fabriquer. Affectez ensuite un habitant au bois et aux fibres pour terminer l’alcôve.")

func _add_patch(kind: String, pos: Vector3, amount: int) -> void:
	var node := Art.model(self, "needs_13/condensation" if kind == "water" else kind, pos)
	var label := Art.caption(node, NAMES[kind], Vector3(0, 1.0, 0), Color("eac37e"))
	label.pixel_size = 0.0055
	patches.append({"kind": kind, "pos": pos, "amount": amount, "reserved": 0, "node": node, "label": label, "discovered": true})

func _exit_tree() -> void:
	sleeping.game = null
	construction.game = null
	needs.game = null
	# Workers store their controller; detach its dictionary reference on teardown.
	for worker in workers:
		worker.delivery.worker = {}
		worker.delivery.game = null

func _add_worker() -> void:
	var i := workers.size()
	if home_slots.size() <= i: _refresh_navigation_slots(i + 1)
	var node := Art.worker(self, home_slots[i], i)
	workers.append({"node": node, "patch": -1, "carrying": 0, "kind": "food", "work": 0.0,
		"energy": 100.0, "comfort": 0.0, "privacy": 0.0, "sleep_requested": false,
		"nutrition": 100.0, "hydration": 100.0})
	var controller := WorkerDelivery.new()
	workers[i].delivery = controller
	controller.setup(self, workers[i], i, delivery_ledger)
	if hiding: controller.change("return_home")

func _make_loading_stations() -> void:
	var controller: WorkerDelivery = workers[0].delivery
	var stations: Array[Vector3] = [controller.destination_position]
	for patch in patches:
		stations.append(patch.pos + Vector3(0.9, WorkerDelivery.GROUND_Y, 0.2))
	for station in stations:
		var stand := preload("res://assets/models/reference_01/salvage_crate.glb").instantiate() as Node3D
		add_child(stand)
		var top := station + controller.contact.origin
		var floor_y := 2.04 if station.y > 1 else 0.0
		stand.position = Vector3(top.x, floor_y, top.z)
		stand.scale = Vector3(0.70, (top.y - floor_y) / 0.49, 0.70)
		if station.distance_to(patches[7].pos + Vector3(.9, WorkerDelivery.GROUND_Y, .2)) < .01: water_stand = stand
		var stands: Array[Rect2] = (east_stands if station.x > 8 else upper_stands) if floor_y > 1 else navigation_stands
		if station.x > 8 and floor_y > 1:
			east_stand = stand
			stand.hide()
		stands.append(Navigation.footprint(stand.position, Vector2(0.22, 0.18)))
	navigation.configure(navigation_obstacles, navigation_stands)
	upper_navigation.configure(upper_obstacles, upper_stands)
	east_navigation.configure(east_obstacles, east_stands)
	_refresh_navigation_slots(workers.size())
	for i in range(workers.size()): workers[i].node.position = home_position(i)
	var depot_label := Art.caption(self, "DÉPÔT", controller.destination_position + Vector3(0, 0.95, 0.9), Color("eac37e"))
	depot_label.pixel_size = 0.005

func _setup_navigation() -> void:
	navigation_obstacles = [refuge_footprint()]
	# Blender floor props (coordinates converted from Z-up to Godot Y-up).
	navigation_obstacles.append(Navigation.footprint(Vector3(9, 0, 5.7), Vector2(0.94, 0.94)))
	navigation_obstacles.append(Rect2(-9.92, 5.38, 2.54, 0.84))
	for torch in [Vector3(-6.3, 0, 3.8), Vector3(3, 0, 4.9), HOME + Vector3(1.05, 0, 0.65)]:
		navigation_obstacles.append(Navigation.footprint(torch, Vector2(0.12, 0.12)))
	navigation_obstacles.append(Rect2(3, -6.05, 4, 3))
	navigation_obstacles.append(Rect2(9, -6.05, 3, 3))
	east_navigation.area = Rect2(9, -6.05, 3, 3)
	upper_navigation.area = Rect2(3, -6.05, 4, 3)
	for patch in patches:
		var obstacles: Array[Rect2] = (east_obstacles if patch.pos.x > 8 else upper_obstacles) if patch.pos.y > 1 else navigation_obstacles
		obstacles.append(Navigation.footprint(patch.pos, Vector2(0.55, 0.5)))
	upper_navigation.configure(upper_obstacles)
	east_navigation.configure(east_obstacles)
	navigation.configure(navigation_obstacles)
	# Initial slots are replaced after the physical loading stands are registered.
	_refresh_navigation_slots(4)

func _refresh_navigation_slots(count: int) -> void:
	home_slots = navigation.slots(HOME + Vector3(0, 0, 1.65), count)
	depot_slots = navigation.slots(HOME + Vector3(3.2, 0, 1.2), count, home_slots)
	assert(home_slots.size() == count and depot_slots.size() == count, "Not enough accessible colony slots")

func home_position(index: int) -> Vector3:
	return home_slots[index] + Vector3(0, WorkerDelivery.GROUND_Y, 0)

func queue_position(index: int) -> Vector3:
	return depot_slots[index] + Vector3(0, WorkerDelivery.GROUND_Y, 0)

func _navigation_allows_build(pos: Vector3, kind: String) -> bool:
	var trial := Navigation.new()
	var footprints: Array[Rect2] = navigation_obstacles.duplicate()
	footprints.append(Navigation.building(pos, kind))
	if not kind in ["bed", "private_bed"]: footprints.append(Navigation.footprint(pos + Vector3(1.05, 0, 0.65), Vector2(0.12, 0.12)))
	trial.configure(footprints, navigation_stands)
	var depot: Vector3 = workers[0].delivery.destination_position
	var destinations: Array[Vector3] = home_slots.duplicate()
	destinations.append(HOME + Refuge.OUTSIDE)
	destinations.append_array(depot_slots)
	for bed in sleeping.beds: destinations.append(sleeping.entrance(bed))
	for pile in construction.recovery: destinations.append(pile.pos)
	if kind in ["bed", "private_bed"]: destinations.append(pos + Sleep.ENTRY)
	for patch in patches:
		if patch.pos.y < 1: destinations.append(patch.pos + Vector3(0.9, 0, 0.2))
	destinations.append(Ladder.LOWER)
	for i in range(workers.size() + 1): destinations.append(ladder.waiting(i, false))
	for worker in workers:
		if worker.node.position.y < 0.1 and not worker.delivery.inside_refuge and not worker.delivery.door_active and not worker.delivery.state in ["bed_enter", "sleep", "bed_exit"]: destinations.append(worker.node.position)
	for point in destinations:
		if trial.path(depot, point).is_empty(): return false
	# Reserve a reachable spawn and waiting slot before charging for a new shelter.
	if kind == "shelter":
		if workers.size() >= Refuge.CAPACITY: return false
		if upper_navigation.path(Ladder.UPPER, ladder.waiting(workers.size(), true)).is_empty(): return false
		var homes := trial.slots(HOME + Vector3(0, 0, 1.65), workers.size() + 1)
		var queues := trial.slots(HOME + Vector3(3.2, 0, 1.2), workers.size() + 1, homes)
		if homes.size() <= workers.size() or queues.size() <= workers.size(): return false
		for point in homes + queues:
			if trial.path(depot, point).is_empty(): return false
	return true

func _update_camera() -> void:
	camera.size = zoom
	camera.position = focus + Vector3(sin(yaw) * 25, 26, cos(yaw) * 25)
	camera.look_at(focus)

func ground_point(screen: Vector2) -> Variant:
	return Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))

func _unhandled_input(event: InputEvent) -> void:
	if hud.load_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: hud.cancel_load()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F11: _toggle_fullscreen()
			KEY_F5: request_checkpoint()
			KEY_F9: hud.ask_load()
			KEY_SPACE: _toggle_pause()
			KEY_H: _toggle_hide()
			KEY_ESCAPE: _cancel_build(); _show_tray("")
			KEY_B: _toggle_tray("build")
			KEY_C: _toggle_tray("people")
			KEY_O: _toggle_tray("goals")
			KEY_T: _toggle_tray("work")
			KEY_I: _toggle_tray("stocks")
			KEY_F1: _toggle_tray("help")
			KEY_N: show_paths = not show_paths
			KEY_V: refuge.set_cutaway(not refuge.cutaway)
			KEY_1: _choose_build("bed")
			KEY_2: _choose_build("workshop")
			KEY_3: _choose_build("private_bed")
			KEY_R: _restart()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(15, zoom - 1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(34, zoom + 1)
		if event.button_index == MOUSE_BUTTON_RIGHT: _cancel_build()
		if event.button_index == MOUSE_BUTTON_LEFT and not ended and not start_panel.visible:
			var point = ground_point(event.position)
			if point != null:
				if build_mode != "":
					_place_build(point)
				else:
					for i in range(workers.size()):
						var head: Vector2 = camera.unproject_position(workers[i].node.position + Vector3(0, 0.5, 0))
						if event.position.distance_to(head) < 24:
							hud.select_resident(i)
							return
					selected = -1
					hud.assignment_target = -1
					for i in range(patches.size()):
						var hit = Plane(Vector3.UP, patches[i].pos.y).intersects_ray(camera.project_ray_origin(event.position), camera.project_ray_normal(event.position))
						if patches[i].discovered and hit != null and hit.distance_to(patches[i].pos) < 1.1:
							selected = i
					_show_tray("people" if selected >= 0 else "")
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		yaw -= event.relative.x * 0.006
	_update_camera()
	_refresh_ui()

func _update_routes(delta: float) -> void:
	if route_mesh == null:
		route_mesh = MeshInstance3D.new()
		route_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("efd18a")
		route_mesh.material_override = material
		add_child(route_mesh)
	route_mesh.visible = show_paths and not start_panel.visible and not ended
	if not route_mesh.visible: return
	route_timer -= delta
	if route_timer > 0: return
	route_timer = 0.1
	var controller: WorkerDelivery = workers[hud.resident_index].delivery
	var path: PackedVector3Array = controller.route
	if path.is_empty() or controller.route_index >= path.size():
		route_mesh.mesh = null
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var previous := controller.actor.position
	for i in range(controller.route_index, path.size()):
		mesh.surface_add_vertex(previous + Vector3(0, .05, 0))
		mesh.surface_add_vertex(path[i] + Vector3(0, .05, 0))
		previous = path[i]
	mesh.surface_end()
	route_mesh.mesh = mesh

func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN

func _process(delta: float) -> void:
	notice_timer = maxf(0, notice_timer - delta)
	news_label.visible = notice_timer > 0 or build_mode != ""
	var direction := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction.z += 1
	focus += direction.rotated(Vector3.UP, yaw) * delta * 9
	focus.x = clampf(focus.x, -7, 7)
	focus.z = clampf(focus.z, -5, 5)
	_update_camera()
	if is_instance_valid(ghost):
		var point = ground_point(get_viewport().get_mouse_position())
		if point != null:
			ghost.position = Vector3(snappedf(point.x, 1), 0, snappedf(point.z, 1))
			ghost.visible = _valid_site(ghost.position)
	if not paused and not ended:
		simulate(delta * speed)
	_try_checkpoint()
	_refresh_ui()
	_update_routes(delta)

func simulate(dt: float) -> void:
	refuge.update(dt)
	elapsed += dt
	var phase := fmod(elapsed, 100.0)
	var active := phase >= 68 and phase < 88
	var cycle := int(elapsed / 100)
	if cycle != event_index:
		event_index = cycle
		if cycle > 0:
			for p in patches:
				if p.kind == "food": p.amount += 22
				if p.kind == "water": p.amount += 30
			_news("Le repas des humains a laissé de nouvelles miettes.")
	var exposed := 0
	for worker in workers:
		worker.delivery.update(dt)
		if not worker.delivery.at_refuge(): exposed += 1
	if active:
		suspicion += dt * exposed * 0.8
	else:
		suspicion = maxf(0, suspicion - dt * 0.65)
	# Legacy clock fields remain readable, but no global meal removes food remotely.
	meal_timer = 0
	hunger = 0
	if suspicion >= 100: _end(false, "Les humains ont découvert le refuge.\nRappelez les habitants avant leur passage.")

func assign_worker(worker_index: int = -1) -> bool:
	if selected < 0 or ended or not patches[selected].discovered or patches[selected].amount <= 0: return false
	for i in range(workers.size()):
		if worker_index >= 0 and i != worker_index: continue
		var worker := workers[i]
		if worker.patch < 0 and worker.carrying == 0 and worker.delivery.state == "idle":
			worker.patch = selected
			_news("Un habitant est affecté à la récolte de %s." % NAMES[patches[selected].kind].to_lower())
			return true
	_news("Tous les habitants sont affectés. Libérez-en un sur un autre gisement.")
	return false

func release_worker() -> void:
	for worker in workers:
		if worker.patch == selected and selected >= 0:
			worker.patch = -1
			worker.work = 0.0
			worker.delivery.cancel()
			return

func _valid_site(pos: Vector3) -> bool:
	if absf(pos.x) > 9.5 or absf(pos.z) > 6: return false
	if pos.distance_to(HOME + Vector3(1.6, 0, 0.25)) < 1.6: return false
	for b in buildings:
		if pos.distance_to(b.pos) < 2.2: return false
	for p in patches:
		if pos.distance_to(p.pos) < 1.8: return false
		if pos.distance_to(p.pos + Vector3(0.9, 0, 0.5)) < 1.4: return false
	if pos.distance_to(Vector3(9, 0, 5.7)) < 2: return false
	if pos.distance_to(Vector3(-8.7, 0, 5.8)) < 2: return false
	var footprint := Navigation.building(pos, build_mode if build_mode != "" else "shelter").grow(Navigation.CLEARANCE)
	if footprint.intersects(refuge_footprint()): return false
	if footprint.has_point(Vector2(HOME.x, HOME.z + Refuge.OUTSIDE.z)): return false
	if footprint.intersects(Rect2(3, -6.05, 4, 3)): return false
	if footprint.intersects(Rect2(7, -6.05, 4, 3)): return false
	if footprint.has_point(Vector2(Ladder.LOWER.x, Ladder.LOWER.z)): return false
	for i in range(workers.size() + 1):
		var waiting: Vector3 = ladder.waiting(i, false)
		if footprint.has_point(Vector2(waiting.x, waiting.z)): return false
	for slot in home_slots + depot_slots:
		if footprint.has_point(Vector2(slot.x, slot.z)): return false
	for worker in workers:
		if footprint.has_point(Vector2(worker.node.position.x, worker.node.position.z)): return false
	return true

func _choose_build(kind: String) -> void:
	if ended or start_panel.visible: return
	_cancel_build()
	build_mode = kind
	_show_tray("")
	ghost = Art.model(self, "reference_01/matchbox_bed" if kind in ["bed", "private_bed"] else kind, Vector3.ZERO)
	if kind == "private_bed": Art.model(ghost, "sleep_12/privacy_partition", Vector3.ZERO)
	_set_ghost(ghost)
	_news("Cliquez sur un emplacement libre. Clic droit pour annuler.")

func _set_ghost(node: Node) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.95, 0.75, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = mat
	for child in node.get_children(): _set_ghost(child)

func _place_build(point: Vector3) -> bool:
	if build_mode == "" or ended: return false
	var pos := Vector3(snappedf(point.x, 1), 0, snappedf(point.z, 1))
	if not _valid_site(pos):
		_news("Cet emplacement est occupé ou trop près du bord.")
		return false
	if build_mode == "shelter" and workers.size() >= Refuge.CAPACITY:
		_news("Le refuge est complet : ses six places sont occupées.")
		return false
	var furniture := build_mode in ["bed", "private_bed"]
	for key in COSTS[build_mode]:
		if not furniture and construction.available(key) < COSTS[build_mode][key]:
			_news("Il manque des matériaux. Affectez des habitants au bois et aux fibres.")
			return false
	if not _navigation_allows_build(pos, build_mode):
		_news("Ce bâtiment couperait un accès au refuge, au dépôt ou aux ressources.")
		return false
	if not furniture:
		for key in COSTS[build_mode]: stock[key] -= COSTS[build_mode][key]
	if furniture: sleeping.add(pos, build_mode == "private_bed")
	else: Art.building(self, pos, build_mode)
	buildings.append({"pos": pos, "kind": build_mode})
	navigation_obstacles.append(Navigation.building(pos, build_mode))
	if not furniture: navigation_obstacles.append(Navigation.footprint(pos + Vector3(1.05, 0, 0.65), Vector2(0.12, 0.12)))
	navigation.configure(navigation_obstacles, navigation_stands)
	if furniture:
		_news("Chantier planifié. Bois et fibres seront livrés avant fabrication. T : suivi des travaux.")
	elif build_mode == "shelter":
		shelters += 1
		_refresh_navigation_slots(workers.size() + 1)
		_add_worker()
		_news("Un nouvel habitant rejoint la colonie ! Pensez à lui donner une tâche.")
	else:
		workshops += 1
		_news("L'atelier améliore la vitesse et la capacité de transport de tous.")
	_cancel_build()
	return true

func _cancel_build() -> void:
	build_mode = ""
	if is_instance_valid(ghost): ghost.queue_free()
	ghost = null

func _toggle_hide() -> void:
	if ended or start_panel.visible: return
	if hiding and pending_save:
		pending_save = false
		save_status = "Sauvegarde annulée par l’ordre de sortie."
	hiding = not hiding
	if hiding:
		for worker in workers:
			worker.delivery.cancel()
			if worker.delivery.job < 0 and worker.delivery.state == "idle" and not worker.delivery.inside_refuge:
				worker.delivery.change("return_home")
	else:
		for worker in workers: worker.delivery.resume_from_refuge()
	_news("Tout le monde rentre au refuge. Les tâches seront conservées." if hiding else "Les habitants reprennent leurs tâches.")

func _toggle_pause() -> void:
	if not ended and not start_panel.visible: paused = not paused

func _restart() -> void:
	get_tree().reload_current_scene()

func _news(message: String) -> void:
	news_label.text = message
	notice_timer = 7.0

func _end(won: bool, message: String) -> void:
	ended = true
	if pending_save:
		pending_save = false
		save_status = "Partie terminée avant la sauvegarde ; le fichier précédent est conservé."
		message += "\n\n" + save_status
	_show_tray("")
	_cancel_build()
	end_label.text = ("LA MAISON DES PETITS" if won else "UNE COLONIE À RECONSTRUIRE") + "\n\n" + message
	end_panel.show()

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = preload("res://scripts/atelier_ui.gd").new()
	layer.add_child(hud)
	hud.setup(self)

func _show_tray(key: String) -> void:
	active_tray = key
	for tray_key in trays:
		trays[tray_key].visible = tray_key == key
	_refresh_ui()

func _toggle_tray(key: String) -> void:
	if ended or start_panel.visible: return
	if key == "people": hud.assignment_target = -1
	_cancel_build()
	_show_tray("" if active_tray == key else key)

func _refresh_ui() -> void:
	if is_instance_valid(hud): hud.refresh()

func _capture() -> void:
	start_panel.hide()
	if "--capture-windowed" in OS.get_cmdline_user_args():
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1280, 800)
		await get_tree().process_frame
	if "--capture-people" in OS.get_cmdline_user_args():
		selected = 0
		_show_tray("people")
	if "--capture-build" in OS.get_cmdline_user_args(): _show_tray("build")
	_refresh_ui()
	await get_tree().process_frame
	# Let particles and native window resizing settle before visual verification.
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	get_viewport().get_texture().get_image().save_png("res://artifacts/prototype.png")
	get_tree().quit()

func travel_path(from: Vector3, to: Vector3, id: int = 0) -> PackedVector3Array:
	var upper := from.y > 1
	var nav: GroundNavigation = upper_navigation if upper else navigation
	if upper == (to.y > 1): return upper_path(from, to, id) if upper else nav.path(from, to)
	var entry: Vector3 = Ladder.UPPER if upper else Ladder.LOWER
	var exit: Vector3 = Ladder.LOWER if upper else Ladder.UPPER
	var wait: Vector3 = ladder.waiting(id, upper)
	var first: PackedVector3Array = upper_path(from, wait, id) if upper else nav.path(from, wait)
	var approach := nav.path(wait, entry)
	var other: GroundNavigation = navigation if upper else upper_navigation
	var last: PackedVector3Array = other.path(exit, to) if upper else upper_path(exit, to, id)
	if first.is_empty() or approach.is_empty() or last.is_empty(): return PackedVector3Array()
	first.append_array(approach)
	first.append(exit)
	first.append_array(last)
	return first

func travel_revision() -> int:
	return navigation.revision + upper_navigation.revision + east_navigation.revision

func refuge_footprint() -> Rect2:
	return Rect2(Refuge.FOOTPRINT.position + Vector2(HOME.x, HOME.z), Refuge.FOOTPRINT.size)

func upper_path(from: Vector3, to: Vector3, id: int) -> PackedVector3Array:
	var far_side := from.x > 8
	var nav: GroundNavigation = east_navigation if far_side else upper_navigation
	if far_side == (to.x > 8): return nav.path(from, to)
	var entry: Vector3 = Bridge.FAR if far_side else Bridge.NEAR
	var exit: Vector3 = Bridge.NEAR if far_side else Bridge.FAR
	var wait: Vector3 = bridge.waiting(id, far_side)
	var first := nav.path(from, wait)
	var approach := nav.path(wait, entry)
	var other: GroundNavigation = upper_navigation if far_side else east_navigation
	var last := other.path(exit, to)
	if first.is_empty() or approach.is_empty() or last.is_empty(): return PackedVector3Array()
	first.append_array(approach)
	first.append(exit)
	first.append_array(last)
	return first

func start_exploration() -> bool:
	if east_discovered or hiding or ended or start_panel.visible: return false
	for worker in workers:
		if worker.delivery.exploring:
			_news("Un habitant explore déjà la réserve.")
			return false
	for worker in workers:
		var controller: WorkerDelivery = worker.delivery
		if worker.patch < 0 and worker.carrying == 0 and controller.state == "idle":
			controller.exploring = true
			controller.change("leave_home" if controller.inside_refuge else "explore")
			_news("Un habitant part reconnaître la réserve au-delà de la passerelle.")
			return true
	_news("Libérez un habitant pour explorer la réserve.")
	return false

func discover_east() -> void:
	if east_discovered: return
	east_discovered = true
	patches[6].discovered = true
	patches[6].node.show()
	east_stand.show()
	east_label.text = "Réserve de l’Est"
	_news("Réserve découverte : un gisement de bois est disponible dans les affectations.")

func _refresh_save_state() -> void:
	var result := Save.read_checkpoint(save_path)
	save_available = result.ok
	if result.ok:
		save_status = ("Copie de secours : " if result.backup else "Sauvegarde : ") + result.data.saved_at.replace("T", " · ")
	elif FileAccess.file_exists(save_path): save_status = result.error

func request_checkpoint() -> bool:
	if ended or start_panel.visible or pending_save: return false
	pending_save = true
	_cancel_build()
	if not hiding: _toggle_hide()
	save_status = "Rappel et livraisons en cours avant sauvegarde."
	_news(save_status + (" Reprenez avec Espace pour laisser rentrer les habitants." if paused else ""))
	_try_checkpoint()
	return true

func cancel_checkpoint() -> void:
	pending_save = false
	save_status = "Sauvegarde annulée. Le rappel au refuge reste actif."
	_news(save_status)

func checkpoint_ready() -> bool:
	if not construction.jobs.is_empty(): return false
	if ended or not hiding or not delivery_ledger.jobs.is_empty() or delivery_ledger.destination_owner != -1: return false
	for patch in patches:
		if patch.reserved != 0: return false
	if not delivery_ledger.source_slots.is_empty() or not delivery_ledger.destination_queue.is_empty(): return false
	if ladder.owner != -1 or bridge.owner != -1 or refuge.passage_owner != -1: return false
	if not ladder.queue.is_empty() or not bridge.queue.is_empty() or not refuge.queue.is_empty() or refuge.opening > 0: return false
	for worker in workers:
		var controller: WorkerDelivery = worker.delivery
		if worker.carrying != 0 or controller.job != -1 or not controller.inside_refuge or controller.state != "idle": return false
		if controller.climbing or controller.bridge_active or controller.door_active or controller.exploring: return false
	return true

func _try_checkpoint() -> void:
	if is_instance_valid(hud) and hud.load_panel.visible: return
	if not pending_save or not checkpoint_ready(): return
	var error := Save.write_checkpoint(save_path, Save.capture(self))
	pending_save = false
	if not error.is_empty():
		save_status = error
		_news(error)
		return
	paused = true
	_refresh_save_state()
	_news("Colonie sauvegardée et mise en pause. H prépare la sortie, Espace reprend le temps.")

func apply_checkpoint(data: Dictionary) -> bool:
	# Called on a fresh candidate scene. The active game is untouched until success.
	if not Save.validate(data).is_empty(): return false
	if not needs.restore_water_location(data): return false
	start_panel.hide()
	stock = {"food": 1000000, "wood": 1000000, "fiber": 1000000, "water": 16}
	for building in data.buildings:
		build_mode = building.kind
		var point := Vector3(building.pos[0], 0, building.pos[2])
		if not _place_build(point): return false
	for kind in ["food", "wood", "fiber"]: stock[kind] = int(data.stock[kind])
	stock.water = int(data.stock.get("water", 16))
	if data.version >= 2:
		for i in range(sleeping.beds.size()):
			for key in ["owner", "work", "built"]: sleeping.beds[i][key] = data.furnishings[i][key]
			sleeping.beds[i].owner = int(sleeping.beds[i].owner)
			# v2/v3 sites were already paid in full at placement. Migrate them as delivered.
			var materials: Dictionary = data.furnishings[i].materials if data.version >= 4 else construction.cost(sleeping.beds[i])
			sleeping.beds[i].materials = {"wood": int(materials.wood), "fiber": int(materials.fiber)}
			sleeping.visual(i)
		for i in range(workers.size()):
			for key in ["energy", "comfort", "privacy", "sleep_requested"]: workers[i][key] = data.needs[i][key]
			for key in ["nutrition", "hydration"]: workers[i][key] = float(data.needs[i].get(key, 100.0))
	for i in range(data.patches.size()): patches[i].amount = int(data.patches[i].amount)
	if data.version >= 4:
		for pile in data.recovery:
			construction.add_recovery(Vector3(pile.pos[0], pile.pos[1], pile.pos[2]), {"wood": int(pile.materials.wood), "fiber": int(pile.materials.fiber)})
	if data.patches[6].discovered: discover_east()
	for i in range(workers.size()):
		var controller: WorkerDelivery = workers[i].delivery
		workers[i].patch = int(data.assignments[i])
		controller.actor.position = refuge.slot(i)
		controller.actor.rotation.y = 0
		controller.inside_refuge = true
		controller.pose("idle", 0)
	elapsed = float(data.clock.elapsed)
	meal_timer = float(data.clock.meal_timer)
	suspicion = float(data.clock.suspicion)
	hunger = float(data.clock.hunger)
	event_index = int(data.clock.event_index)
	speed = float(data.speed)
	focus = Vector3(data.view.focus[0], data.view.focus[1], data.view.focus[2])
	yaw = float(data.view.yaw)
	zoom = float(data.view.zoom)
	show_paths = data.view.paths
	hud.resident_index = int(data.view.resident)
	refuge.set_cutaway(data.view.cutaway)
	hiding = true
	paused = true
	_update_camera()
	_refresh_ui()
	return checkpoint_ready()

func load_checkpoint() -> Node3D:
	var result := Save.read_checkpoint(save_path)
	if not result.ok:
		save_status = result.error
		_news(result.error)
		return null
	var candidate := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	candidate.save_path = save_path
	candidate.set_meta("restore_mode", true)
	get_tree().root.add_child(candidate)
	if not candidate.apply_checkpoint(result.data):
		candidate.queue_free()
		camera.make_current()
		save_status = "Sauvegarde incohérente : la partie actuelle est conservée."
		_news(save_status)
		return null
	get_tree().current_scene = candidate
	candidate._news(("Copie de secours chargée." if result.backup else "Colonie restaurée.") + " En pause : H prépare la sortie, Espace reprend le temps.")
	set_process(false)
	queue_free()
	return candidate
