extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 g.set_meta("restore_mode", true)
 root.add_child(g)
 g.set_process(false)
 g.start_panel.hide()
 g._show_tray("goals")
 g._refresh_ui()
 for i in range(10): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/chapter_goals.png")
 print("CHAPTER_VISUAL_OK")
 g.queue_free()
 await process_frame
 quit()
