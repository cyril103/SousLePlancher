extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/construction/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/construction")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.prepare_construction_demo()
	await shot(game, "planned")
	for i in range(800):
		game.simulate(.05)
		if game.workers[0].delivery.state == "supply_drop_walk" and game.workers[0].node.position.distance_to(game.workers[0].delivery.destination_position) > 1.5: break
	await shot(game, "delivery")
	for i in range(1200):
		game.simulate(.05)
		game.suspicion = 0
		if game.sleeping.beds[0].work > 2: break
	await shot(game, "building")
	for i in range(800):
		game.simulate(.05)
		game.suspicion = 0
		if game.sleeping.beds[0].built: break
	await shot(game, "finished")
	game.sleeping.cancel_order(1)
	await shot(game, "recovery")
	print("CONSTRUCTION_VISUAL_OK")
	game.queue_free()
	await process_frame
	quit()
