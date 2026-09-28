extends "res://tests/live_checkpoint.gd"
func settle(g: Node, count: int = 2200) -> void:
	for i in range(count): step(g)
func run() -> void:
	var g := fixture()
	g.start_panel.hide()
	g.torches.set_craft_target(2)
	for i in range(10): g.torches.update_production()
	check(g.torches.orders.is_empty() and "atelier" in g.torches.production_summary(), "No production without a workshop")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_lantern_production_demo()
	g.hud.craft_target.value = 3
	check(g.torches.craft_target == 3, "UI sets production target")
	g.hud.craft_target.value = 2
	check(not g.torches.set_craft_target(9), "Invalid target rejected")
	g.hiding = true
	g.torches.update_production()
	check(g.torches.orders.is_empty(), "Recall prevents new production")
	g.hiding = false
	g.pending_save = true
	g.torches.update_production()
	check(g.torches.orders.is_empty(), "Save boundary prevents new production")
	g.pending_save = false
	check(g.torches.request_craft("lantern"), "Manual order before automation")
	var news: String = g.news_label.text
	for i in range(10): g.torches.update_production()
	check(g.torches.orders.size() == 1 and g.news_label.text == news, "Existing manual order counted without duplicate or repeated notification")
	var copied := false
	for i in range(3000):
		step(g)
		check(g.torches.total_lanterns() + g.torches.pending_lanterns() <= 2, "Inventory and committed orders never exceed target")
		check(g.torches.pending_lanterns() <= 1, "Automatic production remains sequential")
		if not copied and g.torches.orders[0].work > 0:
			var copy := clone(g, "lantern production active")
			if copy != null:
				check(copy.torches.craft_target == 2, "Production target survives JSON")
				settle(copy)
				check(copy.torches.total_lanterns() == 2 and copy.stock.wood == 2 and copy.stock.fiber == 0, "Reload completes exact equipment count and cost")
				copy.queue_free()
			copied = true
		if g.torches.total_lanterns() == 2: break
	check(copied and g.stock.wood == 2 and g.stock.fiber == 0, "Two lanterns cost eight wood and six fibers")
	var orders: int = g.torches.orders.size()
	settle(g, 100)
	check(g.torches.orders.size() == orders, "Satisfied target creates no extra order")
	g.torches.items[0].fuel = 20
	settle(g)
	check(g.torches.total_lanterns() == 2 and g.torches.ready_lanterns() == 2 and g.stock.wood == 0, "Empty lantern maintained for two wood instead of replaced")
	check(g.torches.equip(0, "lantern"), "Resident reserves existing lantern")
	orders = g.torches.orders.size()
	for i in range(200): step(g)
	check(g.torches.total_lanterns() == 2 and g.torches.orders.size() == orders, "Carried or reserved equipment still counts toward total")
	var data: Dictionary = g.Save.capture(g)
	var bad: Dictionary = data.duplicate(true)
	bad.torches.craft_target = 9
	check(not g.Save.validate(bad).is_empty(), "Invalid saved production target rejected")
	bad = data.duplicate(true)
	bad.torches.erase("craft_target")
	check(not g.Save.validate(bad).is_empty(), "New format requires production setting")
	bad.version = 23
	check(g.Save.validate(bad).is_empty(), "Version 23 without production setting accepted")
	var old := fixture()
	check(old.apply_checkpoint(bad) and old.torches.craft_target == 0, "Old saves migrate with production off")
	old.queue_free()
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_lantern_production_demo()
	step(g)
	check(g.torches.pending_lanterns() == 1, "First automatic order committed")
	g.torches.set_craft_target(0)
	settle(g)
	check(g.torches.total_lanterns() == 1 and g.stock.wood == 6 and g.stock.fiber == 3, "Disabling finishes only committed fabrication")
	g.torches.set_craft_target(2)
	settle(g)
	check(g.torches.total_lanterns() == 2, "Raised target resumes fabrication")
	g.torches.set_craft_target(1)
	g.stock.wood += 4
	g.stock.fiber += 3
	check(g.torches.request_craft("lantern"), "Manual order may exceed automatic target")
	settle(g)
	check(g.torches.total_lanterns() == 3, "Lower target neither deletes equipment nor blocks manual work")
	g.queue_free()
	await process_frame
	print("LANTERN_PRODUCTION: %d failure(s)" % failures)
	quit(1 if failures else 0)
