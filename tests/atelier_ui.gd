extends SceneTree
## Live UI contracts: selection, exact assignment, cargo safety, layout and pause.
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func settle() -> void:
	for i in range(5): await process_frame

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var hud = game.hud
	await settle()
	check(hud.modal_shade.visible, "Welcome screen blocks world interaction")
	game.start_panel.hide()
	game._refresh_ui()
	check(not hud.modal_shade.visible and hud.resident_card.visible, "Starting exposes live resident card")
	var build_button: Button = game.dock_buttons.build
	var click_position := build_button.get_global_rect().get_center()
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = click_position
		root.push_input(click, true)
		await process_frame
	check(game.active_tray == "build", "Viewport mouse click reaches the dock, not the ground")
	game._show_tray("")
	for key in ["build", "people", "work", "stocks", "goals", "help"]:
		game.dock_buttons[key].pressed.emit()
		check(game.active_tray == key, "Dock opens " + key)
		var visible_count := 0
		for panel in game.trays.values():
			if panel.visible: visible_count += 1
		check(visible_count == 1 and not hud.resident_card.visible, "Only one contextual panel is visible")
	hud.select_resident(2)
	hud.resident_assign.pressed.emit()
	game.patch_picker.item_selected.emit(3)
	game.assign_button.pressed.emit()
	check(game.workers[2].patch == 2 and game.workers[0].patch == -1, "Resident-specific assignment does not assign the first idle worker")
	game.simulate(0.05)
	game._refresh_ui()
	check(hud.resident_assign.disabled, "Busy resident cannot be assigned twice")
	hud.speed_buttons[2].pressed.emit()
	check(game.speed == 3 and hud.speed_buttons[2].button_pressed, "3x speed is live and selected")
	game.pause_button.pressed.emit()
	check(not game.paused, "Pause button resumes")
	var pause_key := InputEventKey.new()
	pause_key.keycode = KEY_SPACE
	pause_key.pressed = true
	game._unhandled_input(pause_key)
	check(game.paused, "Space pauses after pressing UI buttons")
	game.stock.food = 1000
	for i in range(1000):
		game.simulate(0.05)
		if game.workers[2].carrying > 0: break
	var stock_before: int = game.stock.wood
	hud._recall_resident()
	check(game.workers[2].patch == -1 and game.workers[2].carrying > 0, "Resident recall retains collected cargo")
	for i in range(1000):
		game.simulate(0.05)
		if game.workers[2].delivery.state == "idle": break
	check(game.stock.wood == stock_before + 3 and game.workers[2].carrying == 0, "Recall deposits cargo exactly once")
	game.stock.wood = 0
	game._refresh_ui()
	check(hud.build_buttons.bed.disabled and hud.build_buttons.private_bed.disabled and hud.resource_values.wood.text == "0", "Stock and furniture affordability are live")
	game._add_worker()
	game._refresh_ui()
	await settle()
	check(hud.worker_rows.size() == 5 and hud.population.text == "5 habitants", "New arrivals appear in roster")
	for dimensions in [Vector2(1440, 900), Vector2(1600, 900), Vector2(2133, 900), Vector2(1440, 1080)]:
		hud.size = dimensions
		hud._layout()
		await settle()
		check(not hud.top_population.get_rect().intersects(hud.top_resources.get_rect()), "Population and resources do not overlap")
		check(not hud.top_time.get_rect().intersects(hud.top_resources.get_rect()), "Resources and time do not overlap")
		for key in game.trays:
			game._show_tray(key)
			await settle()
			var panel: Control = game.trays[key]
			check(panel.position.y > 120 and panel.get_rect().end.y <= hud.dock.position.y, "Panel fits above dock: " + key)
	game._end(false, "Test de fin")
	game._refresh_ui()
	check(hud.modal_shade.visible and not hud.resident_card.visible, "End screen blocks world and hides resident card")
	game.free()
	print("ATELIER_UI: %d failure(s)" % failures)
	quit(failures)
