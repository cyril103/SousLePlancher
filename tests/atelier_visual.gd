extends SceneTree
## Captures the implemented HUD, including narrow/tall and wide layouts.
func _initialize() -> void:
	run.call_deferred()

func capture(path: String) -> void:
	for i in range(6): await process_frame
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/atelier")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await capture("res://artifacts/atelier/intro.png")
	game.start_panel.hide()
	game.paused = false
	game.stock.food = 48
	game.zoom = 13
	game.yaw = -0.7
	game.focus = Vector3(-1, 0, 2)
	game.selected = 2
	game.assign_worker()
	for i in range(400):
		game.simulate(0.05)
		if game.workers[0].delivery.state == "to_storage": break
	game._update_camera()
	game._refresh_ui()
	await capture("res://artifacts/atelier/gameplay-1920.png")
	for key in ["people", "build", "work", "stocks", "goals", "help"]:
		game._show_tray(key)
		await capture("res://artifacts/atelier/" + key + ".png")
	root.size = Vector2i(1280, 800)
	game._show_tray("people")
	await capture("res://artifacts/atelier/people-1280.png")
	root.size = Vector2i(1024, 768)
	game._show_tray("build")
	await capture("res://artifacts/atelier/build-1024.png")
	root.size = Vector2i(1920, 800)
	game._show_tray("")
	await capture("res://artifacts/atelier/wide.png")
	print("ATELIER_VISUAL_OK")
	quit()
