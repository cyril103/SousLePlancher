extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_auto_scout_demo()
	await shot(g, "auto_scout_waiting")
	for i in range(3200):
		g.simulate(.05)
		g.suspicion = 0
		if g.fissure.visited and g.fissure.scout_owner == -1: break
	await shot(g, "auto_scout_complete")
	g.queue_free()
	await process_frame
	print("AUTO_SCOUT_VISUAL_OK")
	quit()
