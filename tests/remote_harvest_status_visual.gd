extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_remote_harvest_status_demo()
	await shot(g, "remote_food")
	var label: Label = g.hud.harvest_target_controls[2].remote
	var scroll = label.get_parent().get_parent()
	scroll.ensure_control_visible(g.hud.harvest_target_controls[2].remote_action)
	await shot(g, "remote_fiber")
	g.hud._open_remote_harvest_diagnostic("food")
	await shot(g, "remote_maintenance")
	g.queue_free()
	await process_frame
	print("REMOTE_HARVEST_STATUS_VISUAL_OK")
	quit()
