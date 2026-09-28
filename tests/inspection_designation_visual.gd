extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_inspection_demo()
	await shot(g, "inspection_waiting")
	for i in range(1200):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.discovered: break
	await shot(g, "inspection_complete")
	g._show_tray("fissure")
	await shot(g, "inspection_manual")
	g.queue_free()
	await process_frame
	print("INSPECTION_DESIGNATION_VISUAL_OK")
	quit()
