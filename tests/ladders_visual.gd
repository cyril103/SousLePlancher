extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(4): await process_frame
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/ladders/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/ladders")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	game.zoom = 8
	game.focus = Vector3(5, 1, -3.7)
	game.yaw = .55
	for patch in [3,5]:
		game.selected = patch
		game.assign_worker()
	var up := false
	var down := false
	var landing := false
	for step in range(1700):
		game.simulate(.05)
		var c: WorkerDelivery = game.workers[0].delivery
		if not up and c.climbing and c.climb_up and c.climb_time > 3:
			await shot(game, "montee")
			up = true
		if not landing and c.state == "gather":
			await shot(game, "palier")
			landing = true
		if not down and c.climbing and not c.climb_up and c.climb_time > 3:
			await shot(game, "descente")
			down = true
		if up and down and landing: break
	print("LADDER_VISUAL ", up, landing, down)
	quit(0 if up and down and landing else 1)
