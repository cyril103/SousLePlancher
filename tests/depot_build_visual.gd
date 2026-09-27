extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/depot_build/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/depot_build")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_depot_build_demo()
	await shot(g, "plan")
	var captured := false
	for i in range(12000):
		g.simulate(.05)
		g.suspicion = 0
		if not captured and g.depots.sites[1].work > 2:
			captured = true
			g.focus = Vector3(8.5, 1, -3.5)
			g.zoom = 12
			await shot(g, "construction")
		if g.depots.used(1) == 12: break
	await shot(g, "full")
	if not captured or g.depots.used(1) != 12:
		push_error("Depot visual fixture incomplete")
		quit(1)
		return
	g.queue_free()
	await process_frame
	print("DEPOT_BUILD_VISUAL_OK")
	quit()
