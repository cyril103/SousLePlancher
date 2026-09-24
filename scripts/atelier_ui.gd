extends Control
## Live workshop HUD; all panels read the simulation, never a baked screenshot.
const Frame = preload("res://scripts/atelier_panel.gd")
const ICONS = preload("res://assets/ui/atelier/icons.png")
const PORTRAIT = preload("res://assets/ui/atelier/portrait.png")
const DISPLAY_FONT = preload("res://assets/fonts/Lora.ttf")
const BODY_FONT = preload("res://assets/fonts/SourceSans3.ttf")
const INK := Color("342819")
const MUTED := Color("786547")
const CREAM := Color("f4e7c7")
const GOLD := Color("d9b66b")
const ICON_MAP := {"build": 0, "people": 1, "work": 2, "stocks": 3, "goals": 4, "refuge": 5, "food": 6, "wood": 7, "fiber": 8, "time": 9, "help": 10, "settings": 11}
var game: Node
var icon_cache: Dictionary = {}
var resource_values: Dictionary = {}
var population: Label
var availability: Label
var cycle_label: Label
var speed_buttons: Array[Button] = []
var resident_card: PanelContainer
var resident_name: Label
var resident_task: Label
var resident_cargo: Label
var resident_recall: Button
var resident_assign: Button
var assignment_target := -1
var resident_index := 0
var people_list: VBoxContainer
var worker_rows: Array[Button] = []
var work_label: Label
var routes_button: Button
var stocks_label: Label
var build_buttons: Dictionary = {}
var modal_shade: ColorRect
var dock: PanelContainer
var top_population: PanelContainer
var top_resources: PanelContainer
var top_time: PanelContainer
var warning_icon: TextureRect
var last_roster_size := -1

func setup(owner_game: Node) -> void:
	game = owner_game
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := Theme.new()
	var readable_body := FontVariation.new()
	readable_body.base_font = BODY_FONT
	readable_body.variation_opentype = {2003265652: 500.0} # OpenType wght tag.
	skin.default_font = readable_body
	skin.default_font_size = 18
	skin.set_color("font_color", "Label", INK)
	for type in ["Button", "OptionButton"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			skin.set_stylebox(state, type, button_style(state))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			skin.set_color(state, type, CREAM)
		skin.set_color("font_disabled_color", type, Color("ac9878"))
		skin.set_constant("outline_size", type, 0)
		skin.set_constant("h_separation", type, 10)
	skin.set_stylebox("panel", "PopupMenu", flat(Color("2c2017"), GOLD))
	skin.set_stylebox("hover", "PopupMenu", flat(Color("70512a"), GOLD))
	skin.set_color("font_color", "PopupMenu", CREAM)
	skin.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	skin.set_constant("v_separation", "PopupMenu", 14)
	skin.set_stylebox("panel", "TooltipPanel", flat(Color("f0dfb9"), MUTED))
	skin.set_color("font_color", "TooltipLabel", INK)
	skin.set_font_size("font_size", "TooltipLabel", 17)
	theme = skin
	_make_header()
	_make_dock()
	_make_trays()
	_make_resident()
	_make_modals()
	resized.connect(_layout)
	_layout.call_deferred()

func flat(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 7
	box.content_margin_bottom = 7
	return box

func button_style(state: String) -> StyleBoxFlat:
	var color := Color("251b12bb")
	var border := Color("7b6037")
	if state in ["hover", "focus"]:
		color = Color("614524dd")
		border = Color("f1cf80")
	elif state in ["pressed", "hover_pressed"]:
		color = Color("725126ee")
		border = Color("edc266")
	elif state == "disabled":
		color = Color("493a2ec0")
		border = Color("7a6952")
	var box := flat(color, border)
	if state in ["pressed", "hover_pressed", "focus"]: box.set_border_width_all(2)
	box.shadow_color = Color(0, 0, 0, 0.22)
	box.shadow_size = 2
	return box

func icon(key: String) -> Texture2D:
	if not icon_cache.has(key):
		var index: int = ICON_MAP[key]
		var tile := ICONS.get_size() / Vector2(4, 3)
		var atlas := AtlasTexture.new()
		atlas.atlas = ICONS
		atlas.region = Rect2(Vector2(index % 4, index / 4) * tile, tile)
		atlas.filter_clip = true
		icon_cache[key] = atlas
	return icon_cache[key]

func picture(parent: Node, texture: Texture2D, dimensions: Vector2) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.custom_minimum_size = dimensions
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
	return view

func label(parent: Node, text: String, font_size: int = 18, color: Color = INK, display: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if display: node.add_theme_font_override("font", DISPLAY_FONT)
	parent.add_child(node)
	return node

func wrapped(parent: Node, text: String, font_size: int = 18, color: Color = INK) -> Label:
	var node := label(parent, text, font_size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func button(parent: Node, text: String, action: Callable, hint: String = "") -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.custom_minimum_size.y = 38
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.tooltip_text = hint
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func frame(parent: Node, paper: bool = false, linen: bool = false) -> PanelContainer:
	var node := Frame.new()
	node.paper = paper
	node.linen = linen
	parent.add_child(node)
	return node

func column(parent: Node, separation: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node

func row(parent: Node, separation: int = 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node

func _make_header() -> void:
	top_population = frame(self)
	var people_row := row(top_population, 8)
	picture(people_row, icon("refuge"), Vector2(60, 58))
	var info := column(people_row, 0)
	population = label(info, "4 habitants", 22, CREAM, true)
	availability = label(info, "4 disponibles", 16, GOLD)
	top_resources = frame(self)
	var resources := row(top_resources, 16)
	for key in ["food", "wood", "fiber"]:
		var cell := row(resources, 8)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picture(cell, icon(key), Vector2(36, 38))
		label(cell, game.NAMES[key], 18, CREAM, true)
		resource_values[key] = label(cell, "0", 25, CREAM, true)
		cell.tooltip_text = "Réserve disponible au dépôt : %s" % game.NAMES[key].to_lower()
	top_time = frame(self)
	var time_column := column(top_time, 4)
	var controls := row(time_column, 6)
	cycle_label = label(controls, "Cycle 1", 20, CREAM, true)
	cycle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.pause_button = button(controls, "", game._toggle_pause, "Pause / reprendre [Espace]")
	game.pause_button.custom_minimum_size.x = 38
	for value in [1, 2, 3]:
		var speed_value: int = value
		var control := button(controls, "×%d" % value, func(): game.speed = float(speed_value); refresh(), "Vitesse ×%d" % value)
		control.custom_minimum_size.x = 39
		control.toggle_mode = true
		speed_buttons.append(control)
	game.speed_button = speed_buttons[0]
	var warning_row := row(time_column, 6)
	warning_icon = picture(warning_row, icon("time"), Vector2(20, 22))
	game.time_label = label(warning_row, "", 16, GOLD)
	game.time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.alert_bar = ProgressBar.new()
	game.alert_bar.custom_minimum_size = Vector2(44, 7)
	game.alert_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	game.alert_bar.show_percentage = false
	game.alert_bar.tooltip_text = "Soupçons des humains : à 100 %, le refuge est découvert."
	game.alert_bar.add_theme_stylebox_override("background", flat(Color("140f0b")))
	game.alert_bar.add_theme_stylebox_override("fill", flat(Color("c69a4d")))
	warning_row.add_child(game.alert_bar)
	game.news_label = label(self, "Cliquez sur un gisement pour organiser la récolte.", 18, CREAM)
	game.news_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.news_label.add_theme_color_override("font_shadow_color", Color("150e08"))
	game.news_label.add_theme_constant_override("shadow_offset_y", 2)
	game.news_label.add_theme_constant_override("outline_size", 4)
	game.news_label.add_theme_color_override("font_outline_color", Color("1e160dc0"))
	game.notice_timer = 10

func _make_dock() -> void:
	dock = frame(self, false, true)
	var tools := row(dock, 8)
	for spec in [["build", "Construire", "B"], ["people", "Habitants", "C"], ["work", "Travaux", "T"], ["stocks", "Stocks", "I"], ["goals", "Objectifs", "O"], ["refuge", "Au refuge", "H"]]:
		var key: String = spec[0]
		var action: Callable = game._toggle_hide if key == "refuge" else func(): assignment_target = -1; game._toggle_tray(key)
		var control := button(tools, spec[1], action, "%s [%s]" % [spec[1], spec[2]])
		control.icon = icon(key)
		control.expand_icon = true
		control.add_theme_constant_override("icon_max_width", 42)
		control.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		control.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		control.add_theme_font_override("font", DISPLAY_FONT)
		control.add_theme_font_size_override("font_size", 21)
		control.custom_minimum_size = Vector2(150, 80)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.toggle_mode = true
		game.dock_buttons[key] = control
	game.hide_button = game.dock_buttons.refuge
	var utilities := column(tools, 4)
	var help := button(utilities, "?", func(): game._toggle_tray("help"), "Commandes et aide [F1]")
	help.custom_minimum_size = Vector2(42, 36)
	game.dock_buttons.help = help
	var screen := button(utilities, "⛶", game._toggle_fullscreen, "Plein écran [F11]")
	screen.custom_minimum_size = Vector2(42, 36)
	game.dock_buttons.screen = screen

func tray(key: String, title: String) -> VBoxContainer:
	var panel := frame(self, true, true)
	panel.custom_minimum_size.x = 440
	panel.anchor_top = 1
	panel.anchor_bottom = 1
	panel.offset_left = 16
	panel.offset_right = 456
	panel.offset_top = -134
	panel.offset_bottom = -134
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var content := column(panel, 12)
	var heading := row(content)
	var title_label := label(heading, title, 23, INK, true)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(heading, "×", func(): game._show_tray(""), "Fermer [Échap]").custom_minimum_size.x = 36
	panel.hide()
	game.trays[key] = panel
	return content

func _make_trays() -> void:
	var build := tray("build", "Bâtir le refuge")
	for spec in [["shelter", "Abri", "8 bois · 4 fibres", "Un nouvel habitant rejoint la colonie.", "1"], ["workshop", "Atelier", "10 bois · 6 fibres", "Transport plus rapide et charges plus grandes.", "2"]]:
		var kind: String = spec[0]
		var building_row := row(build)
		picture(building_row, icon("refuge" if kind == "shelter" else "work"), Vector2(58, 58))
		var details := column(building_row, 3)
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var control := button(details, "%s — %s [%s]" % [spec[1], spec[2], spec[4]], func(): game._choose_build(kind))
		build_buttons[kind] = control
		wrapped(details, spec[3], 16, MUTED)
	wrapped(build, "Choisissez un bâtiment, puis un emplacement libre. Clic droit pour annuler.", 16, MUTED)
	var people := tray("people", "Habitants & affectations")
	game.patch_picker = OptionButton.new()
	game.patch_picker.focus_mode = Control.FOCUS_NONE
	game.patch_picker.custom_minimum_size.y = 40
	game.patch_picker.add_item("Choisir un gisement…")
	for i in range(game.patches.size()):
		game.patch_picker.add_icon_item(icon(game.patches[i].kind), "%s · gisement %d" % [game.NAMES[game.patches[i].kind], i + 1] + (" · Palier" if game.patches[i].pos.y > 1 else ""))
	game.patch_picker.add_theme_constant_override("icon_max_width", 24)
	game.patch_picker.get_popup().add_theme_constant_override("icon_max_width", 24)
	game.patch_picker.item_selected.connect(func(index: int): game.selected = index - 1; refresh())
	people.add_child(game.patch_picker)
	game.detail_label = wrapped(people, "", 17)
	var actions := row(people)
	game.assign_button = button(actions, "+ Affecter", func(): game.assign_worker(assignment_target); refresh(), "Affecter un habitant disponible au gisement choisi")
	game.release_button = button(actions, "− Libérer", func(): game.release_worker(); refresh(), "Libérer un habitant du gisement ; sa charge sera rapportée")
	game.assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.release_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 174
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	people.add_child(scroll)
	people_list = column(scroll, 6)
	people_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapped(people, "Cliquez sur un habitant pour l’inspecter. [H] rappelle toute la colonie en conservant ses tâches.", 16, MUTED)
	var work := tray("work", "Travaux en cours")
	work_label = wrapped(work, "", 18)
	routes_button = button(work, "Afficher le trajet sélectionné [N]", func(): game.show_paths = not game.show_paths; refresh())
	button(work, "Organiser les affectations", func(): game._show_tray("people"))
	var stocks := tray("stocks", "Le garde-manger")
	stocks_label = wrapped(stocks, "", 18)
	wrapped(stocks, "Les matériaux sont disponibles pour construire après leur livraison au dépôt.", 16, MUTED)
	var goals := tray("goals", "Votre premier foyer")
	game.objective_label = wrapped(goals, "", 19)
	var help := tray("help", "Les gestes essentiels")
	wrapped(help, "Flèches / WASD : déplacer la caméra\nMolette : zoom · Bouton central : rotation\nB : construire · C : habitants · T : travaux\nI : stocks · O : objectifs · H : au refuge\nN : trajet · V : vue intérieure du refuge\nEspace : pause · F11 : plein écran\n1 / 2 : construire un abri / un atelier\nÉchap : fermer / annuler · R : recommencer\n\nLes panneaux n’arrêtent pas le temps. Utilisez Espace pour planifier tranquillement.", 17)

func _make_resident() -> void:
	resident_card = frame(self, true, true)
	resident_card.custom_minimum_size = Vector2(380, 172)
	var content := row(resident_card, 12)
	picture(content, PORTRAIT, Vector2(96, 116))
	var info := column(content, 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resident_name = label(info, "Habitant 1", 23, INK, true)
	resident_task = label(info, "Disponible", 18)
	resident_cargo = label(info, "Sans affectation", 16, MUTED)
	var actions := row(info, 6)
	resident_assign = button(actions, "Affecter", func(): assignment_target = resident_index; game._show_tray("people"), "Choisir un gisement pour cet habitant")
	resident_recall = button(actions, "Rappeler", _recall_resident, "Libérer cet habitant et le faire rentrer avec sa charge")
	resident_card.tooltip_text = "Habitant sélectionné : cliquez sur un autre habitant dans la colonie ou dans la liste."

func _recall_resident() -> void:
	if game.ended or game.start_panel.visible: return
	var worker: Dictionary = game.workers[resident_index]
	worker.patch = -1
	worker.delivery.cancel()
	if worker.delivery.job < 0 and worker.delivery.state == "idle": worker.delivery.change("return_home")
	game._news("L’habitant %d rentre au refuge. Sa charge sera déposée." % (resident_index + 1))
	refresh()

func select_resident(index: int) -> void:
	resident_index = clampi(index, 0, game.workers.size() - 1)
	game._show_tray("")
	refresh()

func _make_modals() -> void:
	modal_shade = ColorRect.new()
	modal_shade.color = Color(0.045, 0.028, 0.015, 0.62)
	add_child(modal_shade)
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.start_panel = frame(self, true, true)
	game.start_panel.custom_minimum_size.x = 560
	var intro := column(game.start_panel, 16)
	picture(intro, icon("refuge"), Vector2(0, 84))
	label(intro, "Sous le Plancher", 36, INK, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(intro, "Une petite civilisation, une grande maison.", 19, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wrapped(intro, "Quatre habitants. Quelques miettes. Tout à construire.\n\n1. Affectez vos habitants aux ressources.\n2. Construisez deux abris et un atelier.\n3. Conservez 35 miettes et survivez au premier cycle.\n\nLes humains passent entre 68 et 88 secondes de chaque cycle. Rappelez vos habitants avec H avant leur arrivée.", 20)
	button(intro, "Fonder la colonie", func(): game.start_panel.hide(); game.paused = false; refresh()).custom_minimum_size.y = 48
	game.end_panel = frame(self, true, true)
	game.end_panel.custom_minimum_size.x = 560
	var ending := column(game.end_panel, 24)
	game.end_label = wrapped(ending, "", 23)
	game.end_label.add_theme_font_override("font", DISPLAY_FONT)
	button(ending, "Recommencer", game._restart)
	game.end_panel.hide()
	for panel in [game.start_panel, game.end_panel]:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH

func _layout() -> void:
	if not is_instance_valid(dock): return
	top_population.position = Vector2(16, 14)
	top_population.size = Vector2(236, 92)
	top_time.position = Vector2(size.x - 366, 14)
	top_time.size = Vector2(350, 92)
	top_resources.position = Vector2((size.x - 560) / 2 - 30, 14)
	top_resources.size = Vector2(560, 76)
	dock.position = Vector2(8, size.y - 120)
	dock.size = Vector2(size.x - 16, 112)
	resident_card.position = Vector2(16, size.y - 306)
	resident_card.size = Vector2(396, 172)
	game.news_label.position = Vector2(270, 112)
	game.news_label.size = Vector2(size.x - 540, 28)
	game.news_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for panel in [game.start_panel, game.end_panel]:
		panel.offset_left = -280
		panel.offset_right = 280
		panel.offset_top = -panel.get_combined_minimum_size().y / 2
		panel.offset_bottom = panel.get_combined_minimum_size().y / 2

func _update_roster() -> void:
	if last_roster_size == game.workers.size(): return
	last_roster_size = game.workers.size()
	for child in people_list.get_children(): child.queue_free()
	worker_rows.clear()
	for i in range(game.workers.size()):
		var index := i
		var control := button(people_list, "", func(): select_resident(index), "Inspecter cet habitant")
		control.alignment = HORIZONTAL_ALIGNMENT_LEFT
		control.icon = PORTRAIT
		control.expand_icon = true
		control.add_theme_constant_override("icon_max_width", 30)
		control.custom_minimum_size.y = 40
		worker_rows.append(control)

func refresh() -> void:
	if not is_instance_valid(game.start_panel): return
	_update_roster()
	var idle := 0
	var carrying := {"food": 0, "wood": 0, "fiber": 0}
	for i in range(game.workers.size()):
		var worker: Dictionary = game.workers[i]
		if worker.patch < 0 and worker.carrying == 0 and worker.delivery.state == "idle": idle += 1
		carrying[worker.kind] += worker.carrying
		worker_rows[i].text = "Habitant %d · %s%s" % [i + 1, worker.delivery.description(), " (%d)" % worker.carrying if worker.carrying > 0 else ""]
	for key in resource_values:
		resource_values[key].text = str(game.stock[key])
	population.text = "%d habitants" % game.workers.size()
	availability.text = "%d disponible%s" % [idle, "s" if idle != 1 else ""]
	game.dock_buttons.people.tooltip_text = "%d habitant(s) disponible(s). Affectations [C]" % idle
	game.pause_button.icon = load("res://assets/icons/play.svg" if game.paused else "res://assets/icons/pause.svg")
	game.pause_button.tooltip_text = "Reprendre [Espace]" if game.paused else "Pause [Espace]"
	for i in range(speed_buttons.size()): speed_buttons[i].set_pressed_no_signal(is_equal_approx(game.speed, i + 1.0))
	game.hide_button.text = "Ressortir" if game.hiding else "Au refuge"
	game.hide_button.set_pressed_no_signal(game.hiding)
	for key in game.trays:
		if game.dock_buttons.has(key): game.dock_buttons[key].set_pressed_no_signal(game.active_tray == key)
	var phase: float = fmod(game.elapsed, 100.0)
	cycle_label.text = "Cycle %d" % (int(game.elapsed / 100) + 1)
	if phase < 68: game.time_label.text = "Passage dans %d s" % ceili(68 - phase)
	elif phase < 88: game.time_label.text = "Cachez-vous ! %d s" % ceili(88 - phase)
	else: game.time_label.text = "Le calme est revenu"
	if game.hunger > 0: game.time_label.text = "Famine : récoltez des miettes !"
	var danger: bool = (phase >= 58 and phase < 88) or game.hunger > 0
	game.time_label.add_theme_color_override("font_color", Color("ffb18b") if danger else GOLD)
	game.alert_bar.value = game.suspicion
	game.alert_bar.tooltip_text = "Soupçons : %d / 100" % int(game.suspicion)
	game.objective_label.text = "%s  Deux abris (%d/2)\n\n%s  Un atelier (%d/1)\n\n%s  35 miettes en réserve (%d/35)\n\n%s  Premier cycle traversé" % ["✓" if game.shelters >= 2 else "○", game.shelters, "✓" if game.workshops > 0 else "○", game.workshops, "✓" if game.stock.food >= 35 else "○", game.stock.food, "✓" if game.elapsed >= 100 else "○"]
	game.patch_picker.select(game.selected + 1)
	# Compute first, then apply once: disabling a held button cancels its click.
	var can_assign := false
	var can_release := false
	game.detail_label.text = "%d habitant(s) disponible(s).\nChoisissez un gisement ou cliquez sur une ressource." % idle
	if game.selected >= 0:
		var patch: Dictionary = game.patches[game.selected]
		var assigned := 0
		for worker in game.workers:
			if worker.patch == game.selected: assigned += 1
		game.detail_label.text = "%s : %d restant(s), dont %d réservé(s).\n%d affecté(s) · %d disponible(s)" % [game.NAMES[patch.kind], patch.amount, patch.reserved, assigned, idle]
		can_assign = idle > 0 and patch.amount > 0 and not game.ended and not game.hiding
		can_release = assigned > 0 and not game.ended
	if assignment_target >= 0:
		var target: Dictionary = game.workers[assignment_target]
		game.assign_button.text = "Affecter n° %d" % (assignment_target + 1)
		can_assign = can_assign and target.patch < 0 and target.carrying == 0 and target.delivery.state == "idle"
	else:
		game.assign_button.text = "+ Affecter"
	game.assign_button.disabled = not can_assign
	game.release_button.disabled = not can_release
	work_label.text = "RÉCOLTE & TRANSPORT\n"
	for key in ["food", "wood", "fiber"]:
		var count := 0
		for worker in game.workers:
			if worker.patch >= 0 and game.patches[worker.patch].kind == key: count += 1
		work_label.text += "\n%s : %d affecté(s) · %d en transport" % [game.NAMES[key], count, carrying[key]]
	work_label.text += "\n\nBÂTIMENTS\n%d abri(s) · %d atelier(s)\n\n%s" % [game.shelters, game.workshops, "Rappel au refuge en cours." if game.hiding else "Les habitants suivent leurs affectations."]
	routes_button.text = "Masquer le trajet [N]" if game.show_paths else "Afficher le trajet sélectionné [N]"
	var blocked := 0
	for worker in game.workers:
		if not worker.delivery.navigation_issue.is_empty(): blocked += 1
	work_label.text += "\n\nÉCHELLE · %s · %d en attente" % ["Passage occupé" if game.ladder.owner >= 0 else "Libre", game.ladder.queue.size()]
	var sheltered := 0
	for worker in game.workers:
		if worker.delivery.at_refuge(): sheltered += 1
	work_label.text += "\nREFUGE · %d/%d à l’abri · %d attendent la porte" % [sheltered, game.workers.size(), game.refuge.queue.size()]
	if blocked > 0: work_label.text += "\n%d trajet(s) bloqué(s) : consultez les habitants." % blocked
	stocks_label.text = "AU DÉPÔT          EN TRANSPORT\n"
	for key in ["food", "wood", "fiber"]:
		stocks_label.text += "\n%s : %d          +%d" % [game.NAMES[key], game.stock[key], carrying[key]]
	stocks_label.text += "\n\nProchain repas dans %d s\nConsommation : %d miettes par repas" % [ceili(18.0 - game.meal_timer), game.workers.size()]
	for kind in build_buttons:
		var affordable: bool = not game.ended and not game.start_panel.visible
		for key in game.COSTS[kind]:
			if game.stock[key] < game.COSTS[kind][key]: affordable = false
		build_buttons[kind].disabled = not affordable
		build_buttons[kind].tooltip_text = "Choisir un emplacement" if affordable else "Matériaux insuffisants au dépôt"
	resident_index = clampi(resident_index, 0, game.workers.size() - 1)
	var resident: Dictionary = game.workers[resident_index]
	resident_name.text = "Habitant %d" % (resident_index + 1)
	resident_task.text = resident.delivery.description()
	resident_cargo.text = "Charge : %d · %s" % [resident.carrying, game.NAMES[resident.kind]] if resident.carrying > 0 else (game.NAMES[game.patches[resident.patch].kind] if resident.patch >= 0 else "Sans affectation")
	resident_recall.disabled = game.ended or (resident.patch < 0 and resident.carrying == 0 and (resident.delivery.inside_refuge or resident.delivery.state == "return_home"))
	resident_assign.disabled = game.ended or game.hiding or resident.patch >= 0 or resident.carrying > 0 or resident.delivery.state != "idle"
	resident_card.visible = game.active_tray == "" and not game.start_panel.visible and not game.ended and game.build_mode == ""
	modal_shade.visible = game.start_panel.visible or game.end_panel.visible
	for i in range(game.patches.size()):
		var patch: Dictionary = game.patches[i]
		patch.label.text = ("▸ " if i == game.selected else "") + game.NAMES[patch.kind] + " · %d" % patch.amount + (" · Palier" if patch.pos.y > 1 else "")
		patch.label.modulate = Color("fff1c8") if i == game.selected else Color("eac37e")
