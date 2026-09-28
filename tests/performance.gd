extends SceneTree
## Real renderer benchmark: run windowed at 1920x1080, without vsync.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.prepare_ant_demo()
	g.start_panel.hide()
	g._show_tray("")
	for pos in [Vector3(-3,0,-4), Vector3(0,0,-3), Vector3(-3,0,0), Vector3(0,0,0)]:
		g.sleeping.add(pos, false)
		var bed = g.sleeping.beds.back()
		bed.built = true
		bed.materials = {"wood":4,"fiber":3}
		bed.work = bed.required
		g.sleeping.visual(g.sleeping.beds.size()-1)
	g.paused = false
	for view in ["colony", "ant", "close", "busy"]:
		if view == "busy":
			g.ant.clock = 14.0
			g.kitchen.designate_food()
			g.speed = 3
		g.focus = Vector3(5,0,26) if view in ["ant", "busy"] else Vector3(-3,0,0)
		g.zoom = 14 if view == "close" else 30
		await create_timer(2).timeout
		var samples: Array[float] = []
		var previous := Time.get_ticks_usec()
		for i in range(240):
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now-previous)/1000.0)
			previous = now
		samples.sort()
		var total := 0.0
		for sample in samples: total += sample
		print("PERF %s: mean %.2f ms, p95 %.2f ms, fps %.1f, draws %d, primitives %d" % [view,total/samples.size(),samples[227],1000.0/(total/samples.size()),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		var shadows := 0
		for lamp in g.find_children("*", "Light3D", true, false):
			if lamp.shadow_enabled: shadows += 2 if lamp is OmniLight3D else 1
		assert(shadows <= 4, "Shadow budget exceeded")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/performance_%s.png" % view)
	g.queue_free()
	await process_frame
	quit()
