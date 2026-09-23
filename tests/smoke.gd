extends SceneTree
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func advance(game: Node, seconds: float) -> void:
	for i in range(int(seconds * 20)):
		if not game.ended: game.simulate(0.05)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	check(game.active_tray == "", "HUD starts with all command panels closed")
	game.dock_buttons.build.pressed.emit()
	check(game.trays.build.visible, "Build icon opens construction panel")
	game.dock_buttons.people.pressed.emit()
	check(game.trays.people.visible and not game.trays.build.visible, "Only one command panel opens at a time")
	game.patch_picker.item_selected.emit(3)
	check(game.selected == 2, "Assignments picker selects corresponding resource")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game._unhandled_input(escape)
	check(game.active_tray == "", "Escape dismisses command panel")
	check(game.workers.size() == 4, "Initial population")
	check(game.patches.size() == 6, "Resource patches")
	var screen = game.camera.unproject_position(game.patches[0].pos)
	check(game.ground_point(screen).distance_to(game.patches[0].pos) < 0.01, "3D picking projection")
	game.selected = 0
	check(game.assign_worker(), "Assign worker")
	advance(game, 17)
	check(game.stock.food > 24, "Harvest must reach storage")
	game.selected = 2
	game.assign_worker()
	game.selected = 4
	game.assign_worker()
	game.selected = 1
	game.assign_worker()
	check(not game.assign_worker(), "Cannot assign unavailable worker")
	game._choose_build("shelter")
	var before: int = game.stock.wood
	check(not game._place_build(game.HOME), "Reject occupied site")
	check(game.stock.wood == before, "No cost for rejected construction")
	check(game._place_build(Vector3(0, 0, 0)), "Build shelter")
	check(game.stock.wood == before - 8 and game.workers.size() == 5, "Cost and new inhabitant")
	game.selected = 0
	game.assign_worker()
	advance(game, 39)
	game._toggle_hide()
	advance(game, 33)
	check(game.suspicion < 1, "Recall before human passage prevents detection")
	for w in game.workers:
		check(w.node.position.distance_to(game.HOME) < 0.4, "All inhabitants reach refuge")
	game._toggle_hide()
	game._choose_build("workshop")
	check(game._place_build(Vector3(-3, 0, -3)), "Build workshop from harvested resources")
	game._choose_build("shelter")
	check(game._place_build(Vector3(3, 0, 1)), "Build second shelter")
	game.selected = 0
	game.assign_worker()
	advance(game, 50)
	check(game.ended and game.end_label.text.begins_with("LA MAISON"), "Full economy loop reaches victory")
	# Let the renderer initialize shader RIDs before tearing down visual scenes.
	await process_frame
	await process_frame
	game.queue_free()
	await process_frame
	var danger = load("res://scenes/main.tscn").instantiate()
	root.add_child(danger)
	danger.set_process(false)
	danger.start_panel.hide()
	danger.elapsed = 70
	danger.suspicion = 99.9
	danger.workers[0].node.position = Vector3(8, 0, 0)
	advance(danger, 1)
	check(danger.ended, "Detection ends game")
	await process_frame
	await process_frame
	danger.queue_free()
	await process_frame
	var starving = load("res://scenes/main.tscn").instantiate()
	root.add_child(starving)
	starving.set_process(false)
	starving.stock.food = 0
	advance(starving, 36)
	check(starving.ended, "Prolonged starvation ends game")
	await process_frame
	await process_frame
	starving.queue_free()
	await process_frame
	print("SMOKE: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
