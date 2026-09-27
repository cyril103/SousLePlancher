extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/designations/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/designations")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_designations_demo()
	await shot(g, "map")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = g.camera.unproject_position(g.designations.marker.global_position)
	g._unhandled_input(click)
	if g.active_tray != "designations":
		push_error("Map click did not open designation")
		quit(1)
		return
	await shot(g, "order")
	g.hud.designation_start.pressed.emit()
	for i in range(1800):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.missions.size() == 2 and g.fissure.owner >= 0: break
	await shot(g, "working")
	g.queue_free()
	await process_frame
	print("DESIGNATIONS_VISUAL_OK")
	quit()
