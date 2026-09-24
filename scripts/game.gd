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
var stock_label: Label
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
	label.pixel_size = 0.008
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
	depot_label.pixel_size = 0.0065

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
					selected = -1
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

func assign_worker() -> bool:
	if selected < 0 or ended or patches[selected].amount <= 0: return false
	for worker in workers:
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

func _style(bg: Color, border: Color = Color("38544e")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _panel(parent: Node, pos: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	panel.position = pos
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", _style(Color("182c2bf2")))
	return panel

func _label(parent: Node, text: String, font_size: int = 18, color: Color = Color("e7e4d4")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 42
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _style(Color("29453f")))
	button.add_theme_stylebox_override("hover", _style(Color("3c6659"), Color("99c7a5")))
	button.add_theme_stylebox_override("pressed", _style(Color("507864")))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _show_tray(key: String) -> void:
	active_tray = key
	for name in trays:
		trays[name].visible = name == key
	for name in ["build", "people", "goals", "help"]:
		if dock_buttons.has(name): dock_buttons[name].button_pressed = name == key

func _toggle_tray(key: String) -> void:
	if ended or start_panel.visible: return
	_cancel_build()
	_show_tray("" if active_tray == key else key)

func _dock_button(parent: Node, key: String, title: String, hint: String, action: Callable) -> Button:
	var button := _button(parent, title, action)
	button.custom_minimum_size = Vector2(88, 60)
	button.icon = load("res://assets/icons/%s.svg" % key)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_font_size_override("font_size", 13)
	button.tooltip_text = hint
	var normal := _style(Color("22332ff2"))
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("3c6659")
	hover.border_color = Color("99c7a5")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("507864")
	pressed.border_color = Color("e9c582")
	button.add_theme_stylebox_override("pressed", pressed)
	button.toggle_mode = key in ["build", "people", "goals", "help", "refuge"]
	dock_buttons[key] = button
	return button

func _tray(ui: Control, key: String, title: String) -> VBoxContainer:
	var panel := _panel(ui, Vector2.ZERO, Vector2(480, 0))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1
	panel.anchor_bottom = 1
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -110
	panel.offset_bottom = -110
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var label := _label(heading, title, 19, Color("e9c582"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := _button(heading, "×", func(): _show_tray(""))
	close.tooltip_text = "Fermer ce panneau (Échap)"
	panel.hide()
	trays[key] = panel
	return column

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	layer.add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 16
	ui.theme = theme
	var header := _panel(ui, Vector2(16, 12), Vector2(0, 52))
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_right = -16
	var skin := _style(Color("172724ef"))
	skin.content_margin_top = 8
	skin.content_margin_bottom = 8
	header.add_theme_stylebox_override("panel", skin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	header.add_child(row)
	_label(row, "SOUS LE PLANCHER", 17, Color("e9c582"))
	stock_label = _label(row, "", 17)
	stock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label = _label(row, "", 15)
	alert_bar = ProgressBar.new()
	alert_bar.custom_minimum_size = Vector2(80, 12)
	alert_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alert_bar.show_percentage = false
	alert_bar.tooltip_text = "Soupçons des humains : à 100 %, la colonie est découverte."
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("d6a566")
	fill.set_corner_radius_all(4)
	alert_bar.add_theme_stylebox_override("fill", fill)
	row.add_child(alert_bar)

	var build := _tray(ui, "build", "CONSTRUIRE")
	var abri := _button(build, "Abri   ·   8 bois / 4 fibres   [1]", func(): _choose_build("shelter"))
	abri.tooltip_text = "Accueille un habitant supplémentaire. Cliquez ensuite sur le terrain."
	var atelier := _button(build, "Atelier   ·   10 bois / 6 fibres   [2]", func(): _choose_build("workshop"))
	atelier.tooltip_text = "Améliore la vitesse et la capacité de transport de tous les habitants."
	_label(build, "Choisissez un bâtiment, puis son emplacement.", 14, Color("a7bdb2"))

	var people := _tray(ui, "people", "AFFECTATIONS")
	patch_picker = OptionButton.new()
	patch_picker.focus_mode = Control.FOCUS_NONE
	patch_picker.custom_minimum_size.y = 38
	patch_picker.add_item("Choisir un gisement…")
	for i in range(patches.size()):
		patch_picker.add_item("%s · gisement %d" % [NAMES[patches[i].kind], i + 1])
	patch_picker.item_selected.connect(func(index: int): selected = index - 1; _refresh_ui())
	people.add_child(patch_picker)
	var people_scroll := ScrollContainer.new()
	people_scroll.custom_minimum_size = Vector2(0, 250)
	people_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	people.add_child(people_scroll)
	detail_label = _label(people_scroll, "", 17)
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var actions := HBoxContainer.new()
	people.add_child(actions)
	assign_button = _button(actions, "+ Affecter", assign_worker)
	release_button = _button(actions, "− Libérer", release_worker)
	assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	release_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(people, "Libérer annule avant la prise ; une charge déjà prise\nest rapportée au dépôt. H rappelle tous les habitants.", 14, Color("a7bdb2"))

	var goals := _tray(ui, "goals", "VOTRE PREMIER FOYER")
	objective_label = _label(goals, "", 17)
	var help := _tray(ui, "help", "COMMANDES")
	_label(help, "Flèches / ZQSD : déplacer la caméra\nMolette : zoom · Molette maintenue : rotation\nB : construire · C : affectations · O : objectifs\nH : rappel au refuge · Espace : pause\n1 / 2 : abri / atelier · F11 : plein écran\nÉchap : fermer / annuler · R : recommencer", 16)

	var dock := _panel(ui, Vector2.ZERO, Vector2(0, 0))
	dock.anchor_left = 0.5
	dock.anchor_right = 0.5
	dock.anchor_top = 1
	dock.anchor_bottom = 1
	dock.offset_left = -466
	dock.offset_right = 466
	dock.offset_top = -104
	dock.offset_bottom = -12
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var dock_skin := _style(Color("172724f5"))
	dock_skin.content_margin_top = 8
	dock_skin.content_margin_bottom = 8
	dock.add_theme_stylebox_override("panel", dock_skin)
	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 8)
	dock.add_child(tools)
	_dock_button(tools, "build", "Construire", "Construire un abri ou un atelier [B]", func(): _toggle_tray("build"))
	_dock_button(tools, "people", "Affectations", "Répartir les habitants entre les gisements [C]", func(): _toggle_tray("people"))
	_dock_button(tools, "goals", "Objectifs", "Voir la progression de la colonie [O]", func(): _toggle_tray("goals"))
	tools.add_child(VSeparator.new())
	hide_button = _dock_button(tools, "refuge", "Au refuge", "Rappeler tous les habitants / reprendre les tâches [H]", _toggle_hide)
	pause_button = _dock_button(tools, "pause", "Pause", "Mettre en pause / reprendre [Espace]", _toggle_pause)
	speed_button = _dock_button(tools, "speed", "Vitesse ×1", "Changer la vitesse de simulation", func(): speed = 2.0 if speed == 1.0 else 1.0)
	tools.add_child(VSeparator.new())
	_dock_button(tools, "help", "Aide", "Afficher les commandes", func(): _toggle_tray("help"))
	_dock_button(tools, "screen", "Plein écran", "Basculer entre fenêtre et plein écran [F11]", _toggle_fullscreen)

	news_label = _label(ui, "Cliquez sur une ressource ou ouvrez les affectations dans la barre du bas.", 17, Color("e9c582"))
	news_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	news_label.offset_left = 24
	news_label.offset_right = -24
	news_label.offset_top = 76
	news_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	news_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	news_label.add_theme_color_override("font_shadow_color", Color("10201c"))
	news_label.add_theme_constant_override("shadow_offset_x", 1)
	news_label.add_theme_constant_override("shadow_offset_y", 2)
	notice_timer = 10
	start_panel = _panel(ui, Vector2(420, 240), Vector2(600, 400))
	var intro := VBoxContainer.new()
	intro.add_theme_constant_override("separation", 18)
	start_panel.add_child(intro)
	_label(intro, "BIENVENUE SOUS LE PLANCHER", 26, Color("e9c582"))
	_label(intro, "Quatre habitants. Quelques miettes. Tout à construire.\n\n1. Cliquez sur les miettes, le bois ou les fibres,\n    puis affectez-y vos habitants.\n2. Construisez deux abris et un atelier.\n3. Gardez 35 miettes et survivez au premier passage.\n\nLes humains passent entre 68 et 88 secondes de chaque\ncycle. Rappelez tout le monde avec H avant leur arrivée !", 18)
	_button(intro, "Fonder la colonie", func(): start_panel.hide(); paused = false)
	start_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	end_panel = _panel(ui, Vector2(420, 300), Vector2(610, 260))
	var end_content := VBoxContainer.new()
	end_content.add_theme_constant_override("separation", 24)
	end_panel.add_child(end_content)
	end_label = _label(end_content, "", 22, Color("e9c582"))
	_button(end_content, "Recommencer", _restart)
	end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	end_panel.hide()

func _refresh_ui() -> void:
	if stock_label == null: return
	stock_label.text = "Miettes  %d     Bois  %d     Fibres  %d     Habitants  %d" % [stock.food, stock.wood, stock.fiber, workers.size()]
	pause_button.text = "Reprendre" if paused else "Pause"
	pause_button.icon = load("res://assets/icons/play.svg" if paused else "res://assets/icons/pause.svg")
	speed_button.text = "Vitesse ×%d" % int(speed)
	hide_button.text = "Ressortir" if hiding else "Au refuge"
	hide_button.set_pressed_no_signal(hiding)
	var phase := fmod(elapsed, 100.0)
	if phase < 68:
		time_label.text = "Cycle %d · Passage dans %d s" % [int(elapsed / 100) + 1, ceili(68 - phase)]
	elif phase < 88:
		time_label.text = "Cachez-vous ! Encore %d s" % ceili(88 - phase)
	else: time_label.text = "Calme · Vous pouvez ressortir"
	if hunger > 0: time_label.text = "FAMINE · Récoltez des miettes !"
	time_label.modulate = Color("ffb078") if phase >= 58 and phase < 88 else Color.WHITE
	alert_bar.value = suspicion
	objective_label.text = "%s  Deux abris (%d/2)\n%s  Un atelier (%d/1)\n%s  35 miettes en réserve\n%s  Premier passage traversé" % ["✓" if shelters >= 2 else "○", shelters, "✓" if workshops > 0 else "○", workshops, "✓" if stock.food >= 35 else "○", "✓" if elapsed >= 100 else "○"]
	var idle := 0
	for worker in workers:
		if worker.patch < 0 and worker.delivery.state == "idle": idle += 1
	dock_buttons.people.text = "Habitants · %d" % idle
	dock_buttons.people.tooltip_text = "%d habitant(s) sans tâche. Gérer les affectations [C]" % idle
	patch_picker.select(selected + 1)
	assign_button.disabled = selected < 0 or ended
	release_button.disabled = true
	detail_label.text = "%d habitant(s) sans tâche\n\n" % idle
	if selected >= 0:
		var assigned := 0
		for worker in workers:
			if worker.patch == selected: assigned += 1
		detail_label.text += "%s · %d restant(s), dont %d réservé(s)\n%d habitant(s) affecté(s)" % [NAMES[patches[selected].kind], patches[selected].amount, patches[selected].reserved, assigned]
		release_button.disabled = assigned == 0 or ended
		var available := false
		for worker in workers:
			if worker.patch < 0 and worker.carrying == 0 and worker.delivery.state == "idle": available = true
		assign_button.disabled = not available or patches[selected].amount <= 0 or ended
	else: detail_label.text += "Cliquez sur un gisement\npour organiser la récolte."
	detail_label.text += "\n"
	for i in range(workers.size()):
		var worker := workers[i]
		detail_label.text += "\nHabitant %d · %s%s" % [i + 1, worker.delivery.description(), " (%d)" % worker.carrying if worker.carrying > 0 else ""]
	if hunger > 0: detail_label.text += "\n\nFAMINE : récoltez des miettes !"
	for i in range(patches.size()):
		var p := patches[i]
		p.label.text = ("▸ " if i == selected else "") + NAMES[p.kind] + " · %d" % p.amount
		p.label.modulate = Color("a4efcd") if i == selected else Color("eac37e")

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
