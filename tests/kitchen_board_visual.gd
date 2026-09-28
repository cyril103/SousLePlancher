extends "res://tests/construction_board_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_kitchen_board_demo()
	await shot(g, "kitchen_waiting")
	for w in g.workers: w.priorities = {"collect": 0, "transport": 1, "build": 1}
	var loaded := false
	for i in range(1800):
		g.simulate(.05)
		g.suspicion = 0
		for id in g.kitchen.tasks:
			if g.kitchen.tasks[id].collected and not g.kitchen.tasks[id].deposited: loaded = true
		if loaded: break
	g.kitchen.toggle_build()
	await shot(g, "kitchen_suspended")
	g.hud._open_construction_entry(0)
	await shot(g, "kitchen_commands")
	g.queue_free()
	await process_frame
	print("KITCHEN_BOARD_VISUAL_OK")
	quit()
