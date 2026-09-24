extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(4): await process_frame
	await create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/sleep/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/sleep")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.prepare_sleep_demo()
	await shot(game, "overview")
	game.focus = Vector3(-3, .35, -4)
	game.zoom = 5
	await shot(game, "alcove")
	game.focus = Vector3(0, .35, -3)
	await shot(game, "bed")
	game.zoom = 15
	game.focus = Vector3(-2, 0, -2)
	game._show_tray("beds")
	await shot(game, "ownership")
	game._show_tray("build")
	await shot(game, "build")
	print("SLEEP_VISUAL_OK")
	quit()
