extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var splash = load("res://scenes/startup.tscn").instantiate()
	splash.history_path = "user://startup_visual_test.cfg"
	splash.auto_advance = false
	root.add_child(splash)
	for i in range(120): await process_frame
	for index in [0, 4]:
		splash.artwork.texture = load(splash.IMAGES[index])
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/startup_%d.png" % (index + 1))
	splash.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://startup_visual_test.cfg"))
	print("STARTUP_VISUAL_OK")
	quit()
