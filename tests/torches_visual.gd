extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._refresh_ui()
	game._update_camera()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/torches/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/torches")
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	game.prepare_torches_demo()
	for i in range(75): game.simulate(.05)
	await shot(game, "overview")
	game._show_tray("")
	game.focus = game.workers[0].node.position + Vector3(0, .8, 0)
	game.zoom = 5
	await shot(game, "hand-close")
	game.workers[0].node.rotation.y += PI
	game.workers[0].delivery.pose("idle", .3)
	await shot(game, "back-close")
	game.queue_free()
	await process_frame
	print("TORCHES_VISUAL_OK")
	quit()
