extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, name: String) -> void:
	g._update_camera()
	g._refresh_ui()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/health/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/health")
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_health_demo()
	await shot(g, "overview")
	var seen := {}
	var carried_frames := 0
	for i in range(5000):
		g.simulate(.05)
		g.suspicion = 0
		var phase: String = g.health.patients[0].phase if g.health.patients.has(0) else "done"
		if phase == "carried": carried_frames += 1
		if phase == "carried" and carried_frames < 22: continue
		if not g.health.helpers.is_empty() and g.health.helpers.values()[0].stage == "treat" and g.health.patients[0].care > 2: phase = "care"
		if phase in ["carried", "care", "recover", "done"] and not seen.has(phase):
			seen[phase] = true
			g.focus = g.workers[0].node.position
			g.zoom = 10
			g._show_tray("")
			await shot(g, phase)
		if phase == "done": break
	g.queue_free()
	await process_frame
	print("HEALTH_VISUAL_OK")
	quit()
