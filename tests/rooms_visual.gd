extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, title: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/rooms/" + title + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/rooms")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_room_demo()
	await shot(g, "plan")
	for i in range(18000):
		g.simulate(.05)
		g.suspicion = 0
		if g.rooms.rooms[0].parts[2].built: break
	if not g.rooms.rooms[0].parts[2].built or not g.rooms.add_bed(0):
		push_error("Room visual fixture failed")
		quit(1)
		return
	g.focus = Vector3(0, 0, -3)
	g.zoom = 12
	await shot(g, "envelope")
	for i in range(8000):
		g.simulate(.05)
		g.suspicion = 0
		if g.sleeping.beds[0].built: break
	g.sleeping.request_rest(0)
	var entry_shot := false
	for i in range(3000):
		g.simulate(.05)
		g.suspicion = 0
		if not entry_shot and absf(g.workers[0].node.position.z - (g.rooms.rooms[0].pos.z + 2.3)) < .15:
			entry_shot = true
			await shot(g, "doorway")
		if g.workers[0].delivery.state == "sleep": break
	await shot(g, "sleep")
	g.queue_free()
	await process_frame
	print("ROOMS_VISUAL_OK")
	quit()
