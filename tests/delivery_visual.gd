extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 1000
	game.selected = 2
	game.assign_worker()
	var controller: WorkerDelivery = game.workers[0].delivery
	game.zoom = 10
	game.yaw = -0.7
	DirAccess.make_dir_recursive_absolute("res://artifacts/delivery_06")
	for state in ["pickup", "to_storage", "putdown"]:
		var found := false
		for i in range(1200):
			game.simulate(0.05)
			if controller.state == state and controller.timer >= 0.5:
				found = true
				break
		assert(found, "Delivery failed to reach " + state)
		game.focus = controller.actor.position
		game._update_camera()
		game._refresh_ui()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/delivery_06/" + state + ".png")
	game.zoom = 19
	game.focus = Vector3.ZERO
	game._show_tray("people")
	game._update_camera()
	game._refresh_ui()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/delivery_06/assignments.png")
	print("DELIVERY_VISUAL_OK: pickup, transport, unloading, assignments")
	quit()
