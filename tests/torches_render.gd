extends SceneTree
## Rendering fixture: isolated torch shadow evidence and 1/4 light comparison.
func _initialize() -> void:
	run.call_deferred()
func shot(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/torches/" + name + ".png")
func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.hud.hide()
	# Remove other light contributions, retaining the actual scene occluders.
	for lamp in game.find_children("*", "Light3D", true, false): lamp.hide()
	for i in range(4):
		var c: WorkerDelivery = game.workers[i].delivery
		c.actor.position = Vector3(5.8 + (i % 2) * 1.4, -.0105, -.6 + (i / 2) * 1.5)
		game.torches.add_item(game.depots.entry(0))
		game.torches.items[i].owner = i
		game.torches.items[i].lit = true
		game.torches.items[i].node.hide()
		c.actor.torch.show()
		c.pose("idle", 0)
		game.torches.advance(c, 0)
	game.focus = Vector3(6, .4, -.7)
	game.zoom = 9
	game._update_camera()
	var report: Array = []
	for count in [0, 1, 4]:
		for i in range(4): game.workers[i].node.torch_light.visible = i < count
		await shot("lights-%d" % count)
		for i in range(30): await process_frame
		var begin := Time.get_ticks_usec()
		for i in range(150): await process_frame
		var ms := (Time.get_ticks_usec() - begin) / 150000.0
		report.append({"shadow_lights": count, "mean_frame_ms": ms, "fps": 1000 / ms})
		print("TORCH_RENDER ", report[-1])
	var file := FileAccess.open("res://artifacts/torches/render-metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.queue_free()
	await process_frame
	print("TORCHES_RENDER_OK")
	quit()
