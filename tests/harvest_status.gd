extends "res://tests/live_checkpoint.gd"
const Status = preload("res://scripts/harvest_status.gd")
func expect(g: Node, kind: String, code: String) -> void:
	var state := Status.inspect(g, kind)
	check(state.code == code, "%s diagnosis: expected %s, received %s" % [kind, code, state.code])
func run() -> void:
	var g := fixture()
	g.prepare_harvest_status_demo()
	expect(g, "food", "undesignated")
	expect(g, "wood", "priority")
	expect(g, "water", "disabled")
	g.hud.harvest_target_controls[1].action.pressed.emit()
	check(g.active_tray == "priorities", "Action opens priorities for disabled collection")
	g._show_tray("harvest_targets")
	g.local_harvest.set_target("wood", 12)
	g.hud._open_harvest_diagnostic("wood")
	check(g.active_tray == "harvest_targets", "Stale action rechecks current state before navigation")
	expect(g, "wood", "covered")
	g.local_harvest.set_target("wood", 17)
	g.priorities.set_priority(0, "collect", 1)
	expect(g, "wood", "ready")
	var before: String = JSON.stringify(g.Save.capture(g).runtime)
	for i in range(5):
		for kind in g.Depots.KINDS: Status.inspect(g, kind)
		g._refresh_ui()
	check(before == JSON.stringify(g.Save.capture(g).runtime), "Diagnostics and UI do not alter runtime, jobs or reservations")
	var copy := clone(g, "harvest diagnostics")
	if copy != null:
		expect(copy, "wood", "ready")
		expect(copy, "food", "undesignated")
		copy.queue_free()
	g.hiding = true
	expect(g, "wood", "recall")
	g.hiding = false
	g.pending_save = true
	expect(g, "wood", "saving")
	g.pending_save = false
	g.ended = true
	expect(g, "wood", "ended")
	g.ended = false
	g.patches[2].amount = 0
	expect(g, "wood", "exhausted")
	g.patches[2].amount = 65
	for w in g.workers: w.patch = 0
	expect(g, "wood", "assigned")
	for w in g.workers: w.patch = -1
	g.depots.sites[0].filters.erase("wood")
	expect(g, "wood", "filters")
	g.hud._open_harvest_diagnostic("wood")
	check(g.active_tray == "depots", "Filter issue opens depot commands")
	g.depots.sites[0].filters.append("wood")
	g.depots.sites[0].capacity = g.depots.used(0)
	expect(g, "wood", "capacity")
	g.depots.sites[0].capacity = 80
	g.workers[0].sleep_requested = true
	expect(g, "wood", "busy")
	g.workers[0].sleep_requested = false
	var c: WorkerDelivery = g.workers[0].delivery
	check(c.start_harvest(2), "Start real wood reservation")
	expect(g, "wood", "reserved")
	c.cancel()
	c.personal_recall = false
	c.change("idle")
	# Only the route geometry is changed in these diagnostic fixtures.
	var obstacles: Array[Rect2] = g.navigation_obstacles.duplicate()
	obstacles.append(Rect2(1.3, 3.5, 1.4, 1.4))
	g.navigation.configure(obstacles, g.navigation_stands)
	expect(g, "wood", "source_path")
	obstacles = g.navigation_obstacles.duplicate()
	var depot: Vector3 = g.depots.entry(0)
	obstacles.append(Rect2(Vector2(depot.x, depot.z) - Vector2(.5, .5), Vector2.ONE))
	g.navigation.configure(obstacles, g.navigation_stands)
	expect(g, "wood", "depot_path")
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	expect(g, "wood", "ready")
	# Read the panel while the simulation progresses: the exact quota still holds.
	g._show_tray("harvest_targets")
	for i in range(1400):
		step(g)
		g._refresh_ui()
		if g.stock.wood == 17 and g.delivery_ledger.jobs.is_empty(): break
	check(g.stock.wood == 17, "Open diagnostics preserve real harvest completion")
	expect(g, "wood", "covered")
	g.queue_free()
	await process_frame
	print("HARVEST_STATUS: %d failure(s)" % failures)
	quit(1 if failures else 0)
