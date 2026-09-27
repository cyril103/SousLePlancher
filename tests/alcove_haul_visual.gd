extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/alcove_haul/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/alcove_haul")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_alcove_haul_demo()
	await shot(g, "ready")
	if not g.fissure.hauling.start(0):
		push_error("Remote cargo demo failed to depart")
		quit(1)
		return
	var crossing := false
	for i in range(1600):
		g.simulate(.05)
		g.suspicion = 0
		if g.workers[0].carrying > 0 and g.fissure.missions[0].phase == "cross" and g.fissure.missions[0].clock > 1.3:
			crossing = true
			break
	if not crossing:
		push_error("Loaded crossing never reached")
		quit(1)
		return
	g.focus = Vector3(4, .7, 6.3)
	g.zoom = 7
	g.yaw = .65
	g._show_tray("")
	await shot(g, "loaded_crossing")
	for i in range(1800):
		g.simulate(.05)
		g.suspicion = 0
		if g.sleeping.beds[0].built: break
	if not g.sleeping.beds[0].built:
		push_error("Remote delivery did not enable bed completion")
		quit(1)
		return
	g.focus = Vector3(0, .5, -3)
	g.zoom = 10
	g.yaw = 2.6
	await shot(g, "bed_complete")
	g.queue_free()
	await process_frame
	print("ALCOVE_HAUL_VISUAL_OK")
	quit()
