extends SceneTree
var game: Node
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func click(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.pressed = down
		root.push_input(event, true)
		# Real mouse clicks span several simulation/HUD refresh frames.
		for i in range(8):
			game._process(0.016)
			await process_frame

func advance(seconds: float) -> void:
	for i in range(ceili(seconds / 0.05)):
		game._process(0.05)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.paused = false
	game.stock.food = 1000
	game._refresh_ui()
	for i in range(8): await process_frame
	await click(game.dock_buttons.people)
	game.patch_picker.item_selected.emit(3)
	for i in range(4): await process_frame
	await click(game.assign_button)
	check(game.workers[0].patch == 2, "Affecter via mouse held across refresh frames")
	var initial: Vector3 = game.workers[0].node.position
	advance(1)
	check(game.workers[0].node.position.distance_to(initial) > 0.2, "Assigned resident walks")
	await click(game.hide_button)
	check(game.hiding, "Refuge button activates recall")
	advance(20)
	await click(game.hide_button)
	check(not game.hiding, "Ressortir button ends shelter order")
	initial = game.workers[0].node.position
	advance(1)
	check(game.workers[0].node.position.distance_to(initial) > 0.2, "Resident resumes preserved task after Ressortir")
	await click(game.release_button)
	check(game.workers[0].patch == -1, "Liberer via mouse held across refresh frames")
	advance(10)
	game.hud.select_resident(2)
	for i in range(4): await process_frame
	await click(game.hud.resident_assign)
	for i in range(4): await process_frame
	await click(game.assign_button)
	check(game.workers[2].patch == 2 and game.workers[0].patch == -1, "Resident-specific assignment via real mouse input")
	advance(1)
	await click(game.hide_button)
	advance(10)
	check(game.workers[2].patch == 2 and game.workers[2].delivery.state == "idle", "Refuge preserves assignment until exit")
	await click(game.hide_button)
	advance(1)
	check(game.workers[2].delivery.state == "to_source", "Second recall and exit resumes assigned resident")
	game.free()
	print("LIVE_ASSIGNMENTS: %d failure(s)" % failures)
	quit(failures)
