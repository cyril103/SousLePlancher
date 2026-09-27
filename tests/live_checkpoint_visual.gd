extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/live_checkpoint/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/live_checkpoint")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_live_save_demo()
	g.save_path = "user://tests/live_visual_%d/save.json" % Time.get_ticks_usec()
	var position: Vector3 = g.workers[0].node.position
	await shot(g, "before")
	g.request_checkpoint()
	for i in range(140): g.simulate(.05)
	var restored = g.load_checkpoint()
	if restored == null:
		push_error("Live reload failed")
		quit(1)
		return
	g = restored
	g.set_process(false)
	await process_frame
	if not g.workers[0].node.position.is_equal_approx(position) or g.workers[0].carrying != 3:
		push_error("Reload lost position or crate")
		quit(1)
		return
	await shot(g, "restored")
	for i in range(1600):
		g.simulate(.05)
		g.suspicion = 0
		if g.sleeping.beds[0].built: break
	if not g.sleeping.beds[0].built:
		push_error("Restored expedition did not finish bed")
		quit(1)
		return
	g.focus = Vector3(0, .5, -3)
	g.yaw = .65
	await shot(g, "completed")
	g.queue_free()
	await process_frame
	print("LIVE_CHECKPOINT_VISUAL_OK")
	quit()
