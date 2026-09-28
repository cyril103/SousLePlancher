extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	current_scene = g
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/soundscape_menu.png")
	g.prepare_soundscape_demo()
	g.elapsed = 67
	g._show_tray("help")
	for i in range(100): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/soundscape_help.png")
	print("SOUNDSCAPE_VISUAL_OK")
	g.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
