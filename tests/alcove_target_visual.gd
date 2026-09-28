extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_alcove_target_demo()
	await shot(g, "alcove_target_waiting")
	var engaged := false
	for i in range(5000):
		g.simulate(.05)
		g.suspicion = 0
		if not engaged and g.designations.owners.size() == 2:
			engaged = true
			await shot(g, "alcove_target_engaged")
		if g.stock.fiber == 5 and g.sleeping.beds[-1].built and g.designations.owners.is_empty(): break
	await shot(g, "alcove_target_covered")
	g.queue_free()
	await process_frame
	print("ALCOVE_TARGET_VISUAL_OK")
	quit()
