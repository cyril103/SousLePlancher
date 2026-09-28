extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_kitchen_target_demo()
	await shot(g, "kitchen_target_waiting")
	for i in range(4500):
		g.simulate(.05)
		g.suspicion = 0
		if g.stock.food == 29 and g.kitchen.tasks.is_empty(): break
	await shot(g, "kitchen_target_covered")
	g._show_tray("harvest_targets")
	await shot(g, "kitchen_target_settings")
	g.queue_free()
	await process_frame
	print("KITCHEN_TARGET_VISUAL_OK")
	quit()
