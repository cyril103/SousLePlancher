extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/priorities/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/priorities")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_priorities_demo()
	await shot(g, "table")
	# Verify the actual UI callback affects the intended cell, then restore demo roles.
	g.hud.priority_cells[0].button.pressed.emit()
	if g.priorities.value(0, "collect") != 2 or g.priorities.value(1, "collect") != 0:
		push_error("Priority UI changed wrong resident")
		quit(1)
		return
	g.priorities.set_priority(0, "collect", 1)
	for i in range(3000):
		g.simulate(.05)
		g.suspicion = 0
		if g.sleeping.beds[0].builder == 2: break
	await shot(g, "artisan")
	g.queue_free()
	await process_frame
	print("PRIORITIES_VISUAL_OK")
	quit()
