extends "res://tests/harvest_targets_visual.gd"
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_lantern_production_demo()
	for i in range(1800):
		g.simulate(.05)
		g.suspicion = 0
		if not g.torches.orders.is_empty() and g.torches.orders[0].work > 1: break
	g._show_tray("equipment_orders")
	await shot(g, "equipment_cancel_before")
	g.hud.craft_order_cancel.pressed.emit()
	g._show_tray("construction_board")
	await shot(g, "equipment_cancel_recovery")
	g._show_tray("lantern_production")
	await shot(g, "equipment_cancel_production")
	g._show_tray("torches")
	await shot(g, "equipment_cancel_torches")
	g.queue_free()
	await process_frame
	print("EQUIPMENT_CANCEL_VISUAL_OK")
	quit()
