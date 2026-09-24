extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._refresh_ui()
	g._update_camera()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/fissure/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/fissure")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_fissure_demo()
	await shot(g, "blocked")
	for i in range(600):
		g.simulate(.05)
		if g.fissure.discovered: break
	g.fissure.request_build()
	for i in range(2400):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.site.work >= 12: break
	await shot(g, "construction")
	for i in range(1200):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.opened(): break
	for i in range(500):
		g.simulate(.05)
		g.suspicion = 0
		if g.torches.available(g.workers[0].delivery) and g.torches.available(g.workers[1].delivery): break
	if not g.fissure.start(0) or not g.fissure.start(1):
		push_error("Visual fixture could not start both visitors")
		quit(1)
		return
	for i in range(800):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.owner >= 0 and g.fissure.missions[g.fissure.owner].phase == "cross": break
	g.focus = Vector3(4, .5, 6.4)
	g.zoom = 11
	g.yaw = .65
	g._show_tray("")
	await shot(g, "crossing")
	for i in range(200):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.visited: break
	g.yaw = 2.6
	await shot(g, "alcove")
	g.queue_free()
	await process_frame
	print("FISSURE_VISUAL_OK")
	quit()
