extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.start_panel.hide()
	g._show_tray("goals")
	await shot(g, "chapter_logistics_start")
	g.local_harvest.set_active(2, true)
	g.local_harvest.set_active(4, true)
	await shot(g, "chapter_logistics_targets")
	g.queue_free()
	await process_frame
	print("CHAPTER_LOGISTICS_VISUAL_OK")
	quit()
