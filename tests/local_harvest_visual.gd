extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/local_harvest_" + name + ".png")
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_local_harvest_demo()
	for i in range(220): g.simulate(.05)
	await shot(g, "orders")
	g._show_tray("people")
	await shot(g, "people")
	g._show_tray("work")
	await shot(g, "work")
	g.queue_free()
	await process_frame
	print("LOCAL_HARVEST_VISUAL_OK")
	quit()
