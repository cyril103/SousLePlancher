extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_harvest_markers_demo()
	await shot(g, "markers_orders")
	for i in range(900):
		g.simulate(.05)
		g.suspicion = 0
		if not g.delivery_ledger.jobs.is_empty(): break
	await shot(g, "markers_working")
	g.hud.open_harvest_source(4)
	await shot(g, "markers_selected")
	g.queue_free()
	await process_frame
	print("HARVEST_MARKERS_VISUAL_OK")
	quit()
