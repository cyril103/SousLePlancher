extends Node3D
## Première boucle de gestion : récolte, construction, discrétion et survie.
const Art = preload("res://scripts/world.gd")
const HOME := Vector3(-3, 0, 1)
const COSTS := {"shelter": {"wood": 8, "fiber": 4}, "workshop": {"wood": 10, "fiber": 6}}
const NAMES := {"food": "Miettes", "wood": "Bois", "fiber": "Fibres"}
var stock := {"food": 24, "wood": 12, "fiber": 6}
var patches: Array[Dictionary] = []
var workers: Array[Dictionary] = []
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

func _ready() -> void:
	Art.decorate(self)
	Art.building(self, HOME, "heart")
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
	_add_patch("wood", Vector3(7, 0, 1), 50)
	_add_patch("fiber", Vector3(-7, 0, 3), 45)
	_add_patch("fiber", Vector3(4, 0, -5), 40)
	delivery_ledger.patches = patches
	for i in range(4):
		_add_worker()
	_make_loading_stations()
	_make_ui()
	_refresh_ui()
	if "--demo-deliveries" in OS.get_cmdline_user_args():
		start_panel.hide()
		paused = false
		for patch in [0, 2, 4, 1]:
			selected = patch
			assign_worker()
		selected = 2
		_show_tray("")
		_news("Livraisons en cours : C pour les affectations, H pour rappeler les porteurs.")
		zoom = 18.0
	if "--capture" in OS.get_cmdline_user_args():
		_capture.call_deferred()

func _add_patch(kind: String, pos: Vector3, amount: int) -> void:
	var node := Art.model(self, kind, pos)
	var label := Art.caption(node, NAMES[kind], Vector3(0, 1.0, 0), Color("eac37e"))
	label.pixel_size = 0.0055
	patches.append({"kind": kind, "pos": pos, "amount": amount, "reserved": 0, "node": node, "label": label})

func _exit_tree() -> void:
	# Workers store their controller; detach its dictionary reference on teardown.
	for worker in workers:
		worker.delivery.worker = {}
		worker.delivery.game = null

func _add_worker() -> void:
	var i := workers.size()
	var node := Art.worker(self, HOME + Vector3(sin(i * 2.4), 0, cos(i * 2.4)), i)
	workers.append({"node": node, "patch": -1, "carrying": 0, "kind": "food", "work": 0.0})
	var controller := WorkerDelivery.new()
	workers[i].delivery = controller
	controller.setup(self, workers[i], i, delivery_ledger)

func _make_loading_stations() -> void:
	var controller: WorkerDelivery = workers[0].delivery
	var stations: Array[Vector3] = [controller.destination_position]
	for patch in patches:
		stations.append(patch.pos + Vector3(0.9, WorkerDelivery.GROUND_Y, 0.2))
	for station in stations:
		var stand := preload("res://assets/models/reference_01/salvage_crate.glb").instantiate() as Node3D
		add_child(stand)
		var top := station + controller.contact.origin
		stand.position = Vector3(top.x, 0, top.z)
		stand.scale = Vector3(0.70, top.y / 0.49, 0.70)
	var depot_label := Art.caption(self, "DÉPÔT", controller.destination_position + Vector3(0, 0.95, 0.9), Color("eac37e"))
	depot_label.pixel_size = 0.005

func _update_camera() -> void:
	camera.size = zoom
	camera.position = focus + Vector3(sin(yaw) * 25, 26, cos(yaw) * 25)
	camera.look_at(focus)

func ground_point(screen: Vector2) -> Variant:
	return Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F11: _toggle_fullscreen()
			KEY_SPACE: _toggle_pause()
			KEY_H: _toggle_hide()
			KEY_ESCAPE: _cancel_build(); _show_tray("")
			KEY_B: _toggle_tray("build")
			KEY_C: _toggle_tray("people")
			KEY_O: _toggle_tray("goals")
			KEY_T: _toggle_tray("work")
			KEY_I: _toggle_tray("stocks")
			KEY_F1: _toggle_tray("help")
			KEY_1: _choose_build("shelter")
			KEY_2: _choose_build("workshop")
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
						if point.distance_to(patches[i].pos) < 1.1:
							selected = i
					_show_tray("people" if selected >= 0 else "")
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		yaw -= event.relative.x * 0.006
	_update_camera()
	_refresh_ui()

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
	_refresh_ui()

func simulate(dt: float) -> void:
	elapsed += dt
	var phase := fmod(elapsed, 100.0)
	var active := phase >= 68 and phase < 88
	var cycle := int(elapsed / 100)
	if cycle != event_index:
		event_index = cycle
		if cycle > 0:
			for p in patches:
				if p.kind == "food": p.amount += 22
			_news("Le repas des humains a laissé de nouvelles miettes.")
	var exposed := 0
	for worker in workers:
		var node: Node3D = worker.node
		worker.delivery.update(dt)
		if node.position.distance_to(HOME) > 1.8: exposed += 1
	if active:
		suspicion += dt * exposed * 0.8
	else:
		suspicion = maxf(0, suspicion - dt * 0.65)
	meal_timer += dt
	if meal_timer >= 18:
		meal_timer -= 18
		stock.food = maxi(0, stock.food - workers.size())
	if stock.food == 0: hunger += dt
	else: hunger = maxf(0, hunger - dt * 2)
	if suspicion >= 100: _end(false, "Les humains ont découvert le refuge.\nRappelez les habitants avant leur passage.")
	elif hunger >= 35: _end(false, "Les réserves sont restées vides trop longtemps.\nGardez des habitants à la récolte de miettes.")
	elif shelters >= 2 and workshops >= 1 and stock.food >= 35 and elapsed >= 100:
		_end(true, "Deux abris, un atelier et des réserves !\nVotre colonie a trouvé sa place sous le plancher.")

func assign_worker(worker_index: int = -1) -> bool:
	if selected < 0 or ended or patches[selected].amount <= 0: return false
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
	return true

func _choose_build(kind: String) -> void:
	if ended or start_panel.visible: return
	_cancel_build()
	build_mode = kind
	_show_tray("")
	ghost = Art.model(self, "shelter" if kind == "shelter" else "workshop", Vector3.ZERO)
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
	for key in COSTS[build_mode]:
		if stock[key] < COSTS[build_mode][key]:
			_news("Il manque des matériaux. Affectez des habitants au bois et aux fibres.")
			return false
	for key in COSTS[build_mode]: stock[key] -= COSTS[build_mode][key]
	Art.building(self, pos, build_mode)
	buildings.append({"pos": pos, "kind": build_mode})
	if build_mode == "shelter":
		shelters += 1
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
	hiding = not hiding
	if hiding:
		for worker in workers:
			worker.delivery.cancel()
			if worker.delivery.job < 0 and worker.delivery.state == "idle":
				worker.delivery.change("return_home")
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
