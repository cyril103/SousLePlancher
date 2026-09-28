extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_lantern_production_demo()
	await shot(g, "lantern_production_order")
	for i in range(2400):
		g.simulate(.05)
		g.suspicion = 0
		if g.torches.total_lanterns() == 2: break
	await shot(g, "lantern_production_complete")
	g._show_tray("lantern_service")
	await shot(g, "lantern_production_service")
	g.queue_free()
	await process_frame
	print("LANTERN_PRODUCTION_VISUAL_OK")
	quit()
