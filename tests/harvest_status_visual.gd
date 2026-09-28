extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_harvest_status_demo()
	await shot(g, "diagnostics")
	g.priorities.set_priority(0, "collect", 1)
	g.local_harvest.set_active(0, true)
	await shot(g, "diagnostics_ready")
	g.queue_free()
	await process_frame
	print("HARVEST_STATUS_VISUAL_OK")
	quit()
