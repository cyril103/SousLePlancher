extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._refresh_ui()
	game._update_camera()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/lanterns/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/lanterns")
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	game.prepare_lanterns_demo()
	await shot(game, "overview")
	var c: WorkerDelivery = game.workers[0].delivery
	for i in range(800):
		game.simulate(.05)
		if c.climbing and c.climb_time >= 3: break
	game._show_tray("")
	game.focus = c.actor.position + Vector3(0, 1, 0)
	game.zoom = 5
	game.yaw = -.65
	await shot(game, "climbing")
	for i in range(1200):
		game.simulate(.05)
		game.suspicion = 0
		if game.torches.missions.has(0) and game.torches.missions[0].phase == "observe": break
	game.focus = c.actor.position + Vector3(0, .8, 0)
	game.yaw = .8
	await shot(game, "observation")
	game.yaw = -.9
	await shot(game, "belt-back")
	for i in range(1500):
		game.simulate(.05)
		game.suspicion = 0
		if not game.torches.missions.has(0) and not c.door_active: break
	game.torches.equip(0, "lantern")
	for i in range(800):
		game.simulate(.05)
		if game.torches.lantern(0): break
	game.torches.start_haul(0, 6)
	for i in range(1500):
		game.simulate(.05)
		game.suspicion = 0
		if c.bridge_active and c.worker.carrying > 0: break
	game.focus = c.actor.position + Vector3(0, .8, 0)
	game.yaw = .4
	game.zoom = 6
	await shot(game, "cargo-bridge")
	for i in range(800):
		game.simulate(.05)
		if c.climbing and not c.climb_up and c.climb_time >= 3: break
	game.focus = c.actor.position + Vector3(0, 1, 0)
	game.yaw = -.65
	await shot(game, "cargo-descent")
	game.queue_free()
	await process_frame
	print("LANTERNS_VISUAL_OK")
	quit()
