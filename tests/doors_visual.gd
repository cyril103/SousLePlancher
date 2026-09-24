extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(4): await process_frame
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/doors/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/doors")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	game.zoom = 7
	game.focus = game.HOME + Vector3(0, .6, -.2)
	game.yaw = .8
	game._toggle_hide()
	var c: WorkerDelivery = game.workers[0].delivery
	for i in range(500):
		game.simulate(.05)
		if c.door_active and absf(c.actor.position.z - (game.HOME.z + .9)) < .12: break
	await shot(game, "entree")
	for i in range(700): game.simulate(.05)
	await shot(game, "interieur")
	game._toggle_hide()
	for i in range(500):
		game.simulate(.05)
		if c.door_active and absf(c.actor.position.z - (game.HOME.z + .9)) < .12: break
	await shot(game, "sortie")
	print("DOORS_VISUAL_OK")
	quit()
