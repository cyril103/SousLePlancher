extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/alcove/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/alcove")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_alcove_demo()
	await shot(g, "departure")
	if not g.fissure.start(0):
		push_error("Demo departure refused")
		quit(1)
		return
	for i in range(1400):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.missions.has(0) and g.fissure.missions[0].phase == "look": break
	g.focus = Vector3(4, .5, 10)
	g.zoom = 13
	g.yaw = 2.6
	await shot(g, "reconnaissance")
	g._show_tray("")
	await shot(g, "scene")
	g.queue_free()
	await process_frame
	print("ALCOVE_VISUAL_OK")
	quit()
