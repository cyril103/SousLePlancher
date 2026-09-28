extends "res://tests/live_checkpoint.gd"
func click_source(g: Node, id: int) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = g.camera.unproject_position(g.patches[id].pos)
	g._unhandled_input(click)
func run() -> void:
	var g := fixture()
	g.prepare_harvest_source_demo()
	await process_frame
	for id in g.local_harvest.PATCHES:
		click_source(g, id)
		check(g.active_tray == "harvest_source" and g.selected == id, "Map click opens source %d" % id)
		check(not g.patches[id].autoharvest, "Selecting a source does not designate it")
		g.hud.source_toggle.pressed.emit()
		check(g.patches[id].autoharvest, "Context action designates only selected source")
		g.hud.source_toggle.pressed.emit()
		check(not g.patches[id].autoharvest, "Second action suspends source")
	click_source(g, 3)
	check(g.active_tray == "people" and g.selected == 3, "Upper sources retain manual commands")
	g.hud.open_harvest_source(6)
	check(g.selected == 3, "Undiscovered source cannot open contextual panel")
	click_source(g, 2)
	var before: String = JSON.stringify(g.Save.capture(g).runtime)
	for i in range(4): g._refresh_ui()
	check(before == JSON.stringify(g.Save.capture(g).runtime), "Context panel is read only until action")
	g.patches[2].amount = 0
	g._refresh_ui()
	check(g.hud.source_toggle.disabled, "Exhausted source cannot be designated")
	g.hud._toggle_harvest_source()
	check(not g.patches[2].autoharvest, "Stale action cannot start exhausted source")
	g.patches[2].amount = 65
	g.hud.source_toggle.pressed.emit()
	# Only one collector so suspension can be observed during its physical return.
	for id in range(g.workers.size()): g.priorities.set_priority(id, "collect", 1 if id == 0 else 0)
	for i in range(900):
		step(g)
		if g.workers[0].carrying > 0: break
	check(g.workers[0].carrying > 0, "Context designation produces a real load")
	g.hud.source_toggle.pressed.emit()
	var remaining: int = g.patches[2].amount
	var expected: int = g.local_harvest.expected("wood")
	var copy := clone(g, "context suspension loaded")
	if copy != null:
		check(not copy.patches[2].autoharvest, "Suspension survives saved loaded return")
		for i in range(1000):
			step(copy)
			if copy.delivery_ledger.jobs.is_empty() and copy.workers[0].carrying == 0: break
		check(copy.depots.total("wood") == expected, "Committed cargo arrives after restoring suspended order")
		check(copy.patches[2].amount == remaining, "Suspension does not take a new load")
		copy.hud.open_harvest_source(2)
		copy.hud.source_toggle.pressed.emit()
		for i in range(1400):
			step(copy)
			if copy.stock.wood == 17 and copy.delivery_ledger.jobs.is_empty(): break
		check(copy.stock.wood == 17, "Context resume respects reserve target")
		copy.queue_free()
	g.queue_free()
	await process_frame
	print("HARVEST_SOURCE: %d failure(s)" % failures)
	quit(1 if failures else 0)
