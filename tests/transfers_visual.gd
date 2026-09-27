extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/transfers/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/transfers")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_transfers_demo()
	await shot(g, "orders")
	for i in range(4000):
		g.simulate(.05)
		g.suspicion = 0
		if g.workers[0].carrying > 0 and g.workers[0].delivery.bridge_active: break
	await shot(g, "crossing")
	g.queue_free()
	await process_frame
	print("TRANSFERS_VISUAL_OK")
	quit()
