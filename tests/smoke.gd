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
	game.depots.sites[0].capacity = 1000 # Legacy colony-growth scenario; bounded stocks are covered by depots.gd.
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
	check(game.patches.size() == 8 and game.patches[7].kind == "water" and not game.patches[6].discovered, "Initial resources include water and one undiscovered reserve")
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
	check(game._place_build(Vector3(0, 0, -3)), "Build shelter away from residents and loading routes")
	check(game.stock.wood == before - 8 and game.workers.size() == 5, "Cost and new inhabitant")
	game.selected = 0
	game.assign_worker()
	advance(game, 39)
	game._toggle_hide()
	advance(game, 33)
	check(game.suspicion < 100 and not game.ended, "Recall prevents discovery while inhabitants queue for the real door")
	for w in game.workers:
		check(w.delivery.at_refuge(), "All inhabitants reach their accessible refuge slots")
	game._toggle_hide()
	game._choose_build("workshop")
	check(game._place_build(Vector3(-3, 0, -3)), "Build workshop from harvested resources")
	# Pick-up, unloading and depot queuing now take simulation time. Wait for
	# actual deliveries instead of relying on the old instantaneous transfer.
	for i in range(800):
		if game.stock.wood >= 8 and game.stock.fiber >= 4: break
		advance(game, 0.05)
	game._choose_build("shelter")
	check(game._place_build(Vector3(-6, 0, -1)), "Build second shelter with accessible service routes")
	game.selected = 0
	game.assign_worker()
	advance(game, 50)
	check(not game.ended and game.elapsed >= 100, "Legacy shelter milestones no longer end the ongoing colony simulation")
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
	starving.start_panel.hide()
	starving.workers[0].nutrition = 10.0
	advance(starving, 55)
	check(not starving.ended and starving.workers[0].nutrition > 35, "A hungry resident self-supplies instead of triggering the obsolete global famine timer")
	await process_frame
	await process_frame
	starving.queue_free()
	await process_frame
	print("SMOKE: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
