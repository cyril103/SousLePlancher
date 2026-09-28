extends "res://tests/live_checkpoint.gd"
func total(g: Node, kind: String) -> int:
	var amount: int = g.depots.total(kind)
	for w in g.workers:
		if w.kind == kind: amount += w.carrying
	for site in g.torches.orders: amount += site.materials[kind]
	for pile in g.construction.recovery: amount += pile.materials[kind]
	return amount
func run() -> void:
	var multi := fixture()
	multi.prepare_lantern_production_demo()
	multi.stock.wood = 20
	multi.stock.fiber = 12
	multi._choose_build("workshop")
	check(multi._place_build(Vector3(-4, 0, -3)), "Second workshop built")
	check(multi.torches.request_craft("lantern") and multi.torches.request_craft("torch"), "Concurrent orders in separate workshops")
	var old: Dictionary = multi.Save.capture(multi)
	old.version = 24
	check(multi.Save.validate(old).is_empty(), "Previous format remains readable")
	multi.hud._open_construction_entry(1)
	check(multi.active_tray == "equipment_orders" and multi.hud.craft_order_index == 1, "Board selects the corresponding order")
	multi.hud.craft_order_cancel.pressed.emit()
	check(not multi.torches.orders[0].built and multi.torches.orders[1].built and multi.torches.craft_target == 2, "Cancelling torch preserves other order and lantern target")
	multi.queue_free()
	await process_frame
	for kind in ["torch", "lantern"]:
		for stage in ["waiting", "loaded", "working"]:
			var g := fixture()
			g.prepare_lantern_production_demo()
			g.torches.set_craft_target(0)
			check(g.torches.request_craft(kind), "Order created")
			var reached: bool = stage == "waiting"
			for i in range(1800):
				if reached: break
				step(g)
				if stage == "working": reached = g.torches.orders[0].work > 1
				else:
					for job in g.construction.jobs.values(): reached = reached or (job.collected and not job.deposited)
			check(reached, "Cancellation boundary: " + kind + " / " + stage)
			g.torches.set_craft_target(2)
			g._show_tray("equipment_orders")
			check(g.hud.craft_order_index == 0 and not g.hud.craft_order_cancel.disabled, "UI selects order")
			g.hud.craft_order_cancel.pressed.emit()
			check(g.torches.orders[0].get("cancelled", false), "UI cancels selected order")
			check(g.torches.craft_target == (0 if kind == "lantern" else 2) and g.torches.refill_target == 2, "Only lantern cancellation disables production; maintenance preserved")
			g.torches.set_craft_target(0)
			check(not g.torches.cancel_craft(0) and not g.torches.cancel_craft(-1) and not g.torches.cancel_craft(99), "Repeated or invalid cancellation refused")
			check(total(g, "wood") == 10 and total(g, "fiber") == 6, "Both materials conserved at cancellation")
			var copy := clone(g, "cancel equipment " + kind + stage)
			if copy != null:
				for i in range(2200): step(copy)
				check(copy.torches.items.is_empty() and copy.torches.crafting.is_empty(), "No phantom equipment or builder after reload")
				check(copy.stock.wood == 10 and copy.stock.fiber == 6 and copy.construction.jobs.is_empty(), "All materials recovered after reload")
				check(copy.torches.request_craft(kind), "Workshop reusable after cancellation")
				for i in range(2200):
					step(copy)
					if copy.torches.items.size() == 1: break
				check(copy.torches.items.size() == 1 and not copy.torches.cancel_craft(1), "New order completes; finished equipment cannot be cancelled")
				copy.queue_free()
			var runtime: Dictionary = g.Save.Live.unpack(g.Save.Live.capture(g).data)
			runtime.orders[0].materials.wood = 1
			check(not g.torches.valid_refills(runtime, g.Save.capture(g)), "Corrupt cancelled order rejected")
			g.queue_free()
			await process_frame
	print("EQUIPMENT_CANCEL: %d failure(s)" % failures)
	quit(1 if failures else 0)
