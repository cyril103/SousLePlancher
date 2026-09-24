extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(4): await process_frame
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/exploration/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/exploration")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	game.zoom = 11
	game.focus = Vector3(8, 1.3, -4.3)
	await shot(game, "inexploree")
	game.start_exploration()
	var c: WorkerDelivery = game.workers[0].delivery
	for i in range(1400):
		game.simulate(.05)
		if c.bridge_active and c.actor.position.x > 7.8: break
	await shot(game, "passerelle")
	for i in range(1000):
		game.simulate(.05)
		if game.east_discovered: break
	game._show_tray("work")
	await shot(game, "decouverte")
	print("EXPLORATION_VISUAL ", game.east_discovered)
	quit(0 if game.east_discovered else 1)
