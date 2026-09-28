extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_harvest_source_demo()
	await shot(g, "source_selected")
	g.hud.source_toggle.pressed.emit()
	for i in range(900):
		g.simulate(.05)
		g.suspicion = 0
		if g.workers[0].carrying > 0: break
	g.hud.source_toggle.pressed.emit()
	await shot(g, "source_suspended")
	g._show_tray("local_harvest")
	await shot(g, "source_list")
	g.queue_free()
	await process_frame
	print("HARVEST_SOURCE_VISUAL_OK")
	quit()
