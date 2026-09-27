extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, title: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/fixed_lighting/" + title + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/fixed_lighting")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_fixed_light_demo()
	await shot(g, "plan")
	for i in range(8500):
		g.simulate(.05)
		g.suspicion = 0
		if g.fixed_lighting.lit(): break
	if not g.fixed_lighting.lit():
		push_error("Light fixture did not finish")
		quit(1)
		return
	g.focus = Vector3(6, 1, -4)
	g.zoom = 12
	await shot(g, "lit")
	g.fixed_lighting.enabled = false
	g.fixed_lighting.refresh()
	await shot(g, "off")
	g.queue_free()
	await process_frame
	print("FIXED_LIGHT_VISUAL_OK")
	quit()
