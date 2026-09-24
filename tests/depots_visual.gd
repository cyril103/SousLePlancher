extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._refresh_ui()
	game._update_camera()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/depots/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/depots")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.prepare_depots_demo()
	await shot(game, "overview")
	for i in range(400):
		game.simulate(.05)
		if game.workers[3].delivery.state == "eat": break
	game.focus = Vector3(4, .3, 2)
	game.zoom = 7
	await shot(game, "local-meal")
	game.zoom = 17
	game.focus = Vector3(2, 0, 0)
	for i in range(1800):
		game.simulate(.05)
		game.suspicion = 0
		if game.sleeping.ready_count() == 1: break
	await shot(game, "supplied-bed")
	game._show_tray("stocks")
	await shot(game, "totals")
	game._show_tray("build")
	await shot(game, "build-panel")
	game.queue_free()
	await process_frame
	print("DEPOTS_VISUAL_OK")
	quit()
