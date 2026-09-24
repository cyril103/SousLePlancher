extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	await process_frame
	game.torches.add_item(game.depots.entry(0))
	check(game.torches.equip(0), "Reserve torch for picking regression")
	for i in range(800):
		game.simulate(.05)
		if game.torches.held(0) >= 0: break
	check(game.torches.held(0) >= 0, "Resident has physically collected torch")
	var c: WorkerDelivery = game.workers[0].delivery
	for angle in [.32, -.8, 1.4]:
		game.yaw = angle
		for distance in [17.0, 28.0]:
			game.zoom = distance
			game._update_camera()
			for target in [Vector3(4, 2.04, -4), Vector3(8, 2.04, -4), Vector3(10.2, 2.04, -3.7)]:
				var screen: Vector2 = game.camera.unproject_position(target)
				var picked = game.destination_point(screen)
				check(picked != null and picked.y > 2, "Landing, bridge and east deck clicks retain elevation across camera changes")
			var label_screen: Vector2 = game.camera.unproject_position(game.east_label.global_position)
			check(game.destination_point(label_screen).is_equal_approx(game.Bridge.SCOUT_POINT), "Reserve label resolves to its upper destination")
			game.torches.choose_target(0)
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = label_screen
			var before: Vector3 = c.actor.position
			game._unhandled_input(click)
			check(game.torches.missions[0].phase == "ready" and not game.torches.items[0].lit, "Actual click rejects upstairs order without starting a ground journey")
			check(game.news_label.text.contains("deux mains"), "Height rejection explains the ladder restriction")
			game.simulate(.05)
			check(c.actor.position.is_equal_approx(before), "Rejected click does not move scout under bridge")
	game.yaw = .32
	game._update_camera()
	var ground := Vector3(-5, 0, 4)
	var screen: Vector2 = game.camera.unproject_position(ground)
	check(game.destination_point(screen).distance_to(ground) < .01, "Uncovered ground still picks the correct position")
	game.torches.choose_target(0)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = screen
	game._unhandled_input(click)
	check(game.torches.missions[0].phase == "out", "Ground destination still launches torch scouting")
	game.queue_free()
	await process_frame
	print("DESTINATION_PICKING: ", failures, " failure(s)")
	quit(1 if failures else 0)
