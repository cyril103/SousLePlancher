extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_harvest_priority_demo()
	await shot(g, "priority_source")
	g._show_tray("local_harvest")
	await shot(g, "priority_list")
	g.hud.open_harvest_source(4)
	for i in range(900):
		g.simulate(.05)
		g.suspicion = 0
		if g.workers[0].carrying > 0: break
	await shot(g, "priority_loaded")
	g.queue_free()
	await process_frame
	print("HARVEST_PRIORITY_VISUAL_OK")
	quit()
