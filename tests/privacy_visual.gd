extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, title: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/privacy/" + title + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/privacy")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_privacy_demo()
	g._show_tray("")
	g.focus = Vector3(-2, 0, -2)
	g.zoom = 38
	await shot(g, "expanded_map")
	g.focus = Vector3(-13, 0, -5)
	g.zoom = 21
	for i in range(2400):
		g.simulate(.05)
		g.suspicion = 0
		var count := 0
		for w in g.workers:
			if w.delivery.state == "sleep": count += 1
		if count == 4: break
	for i in range(12):
		g.simulate(.05)
		g.suspicion = 0
	g._show_tray("rooms")
	await shot(g, "four_sleepers")
	g.rooms.set_mode(0, "open")
	for i in range(12):
		g.simulate(.05)
		g.suspicion = 0
	await shot(g, "open_door")
	g.queue_free()
	await process_frame
	print("PRIVACY_VISUAL_OK")
	quit()
