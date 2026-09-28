extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/harvest_targets_" + name + ".png")
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_harvest_targets_demo()
	await shot(g, "orders")
	for i in range(1400):
		g.simulate(.05)
		g.suspicion = 0
	await shot(g, "complete")
	g._show_tray("local_harvest")
	await shot(g, "harvest")
	g.queue_free()
	await process_frame
	print("HARVEST_TARGETS_VISUAL_OK")
	quit()
