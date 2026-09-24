extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(4): await process_frame
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/needs/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/needs")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.prepare_needs_demo()
	await shot(game, "overview")
	game.focus = game.HOME + Vector3(0, .4, -.8)
	game.zoom = 5
	await shot(game, "eat-drink-floor")
	game.focus = Vector3(7, .2, 2)
	game.zoom = 6
	game._show_tray("stocks")
	await shot(game, "water")
	print("NEEDS_VISUAL_OK")
	quit()
