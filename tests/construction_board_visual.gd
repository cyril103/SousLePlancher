extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, suffix: String) -> void:
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/construction_board_" + suffix + ".png")
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_construction_board_demo()
	await shot(g, "blocked")
	for w in g.workers: w.priorities = {"collect": 0, "transport": 1, "build": 1}
	for i in range(2400):
		g.simulate(.05)
		g.suspicion = 0
		if g.sleeping.beds[0].work >= 2: break
	await shot(g, "working")
	for i in range(2400):
		g.simulate(.05)
		g.suspicion = 0
		if g.sleeping.beds[0].built and g.torches.ready_lanterns() == 2: break
	await shot(g, "complete")
	g.queue_free()
	await process_frame
	print("CONSTRUCTION_BOARD_VISUAL_OK")
	quit()
