extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/kitchen/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/kitchen")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_kitchen_demo()
	await shot(g, "overview")
	g.kitchen.request_scout()
	var shown := {}
	for i in range(18000):
		g.simulate(.05)
		g.suspicion = 0
		if g.kitchen.known and not g.kitchen.planned: g.kitchen.plan()
		if g.kitchen.built and not g.kitchen.harvest: g.kitchen.designate_food()
		for id in g.kitchen.tasks:
			var t: Dictionary = g.kitchen.tasks[id]
			var name := ""
			if t.stage == "bridge_cross" and t.kind == "scout": name = "empty_ledge"
			if t.stage == "build": name = "construction"
			if t.stage == "bridge_cross" and g.workers[id].carrying > 0: name = "loaded_bridge"
			if name.is_empty() or shown.has(name): continue
			shown[name] = true
			g.focus = Vector3(4, 0, 20)
			g.zoom = 15
			g._show_tray("")
			await shot(g, name)
		if shown.has("loaded_bridge"): break
	g._show_tray("kitchen")
	g.focus = Vector3(4, 0, 23)
	g.zoom = 24
	await shot(g, "kitchen")
	g.queue_free()
	await process_frame
	print("KITCHEN_VISUAL_OK")
	quit()
