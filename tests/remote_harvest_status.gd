extends "res://tests/live_checkpoint.gd"
const Status = preload("res://scripts/remote_harvest_status.gd")
func expect(g: Node, kind: String, code: String) -> void:
	var state := Status.inspect(g, kind)
	check(state.get("code") == code, "%s: expected %s, received %s" % [kind, code, state])
func run() -> void:
	var g := fixture()
	check(Status.inspect(g, "fiber").is_empty() and Status.inspect(g, "food").is_empty(), "Undiscovered remote sources stay hidden")
	g.prepare_remote_harvest_status_demo()
	for kind in ["food", "fiber"]:
		expect(g, kind, "fuel")
		g.hud._open_remote_harvest_diagnostic(kind)
		check(g.active_tray == "lantern_service", "Fuel action opens maintenance")
		g.local_harvest.set_target(kind, 0)
		expect(g, kind, "disabled")
		g.local_harvest.set_target(kind, 1)
		expect(g, kind, "covered")
		g.local_harvest.set_target(kind, -1)
		g.hiding = true
		expect(g, kind, "recall")
		g.hiding = false
		g.depots.sites[0].filters.erase(kind)
		expect(g, kind, "filters")
		g.depots.sites[0].filters.append(kind)
		var capacity: int = g.depots.sites[0].capacity
		g.depots.sites[0].capacity = g.depots.used(0)
		expect(g, kind, "capacity")
		g.depots.sites[0].capacity = capacity
	for w in g.workers: w.priorities.collect = 0
	expect(g, "food", "priority")
	expect(g, "fiber", "priority")
	for w in g.workers:
		w.priorities.collect = 2
		w.patch = -1
		w.sleep_requested = true
	expect(g, "food", "busy")
	expect(g, "fiber", "busy")
	for w in g.workers: w.sleep_requested = false
	g.kitchen.harvest = false
	expect(g, "food", "undesignated")
	g.kitchen.harvest = true
	g.designations.active = false
	expect(g, "fiber", "undesignated")
	g.designations.active = true
	g.kitchen.known = false
	expect(g, "food", "scout")
	g.kitchen.known = true
	g.kitchen.built = false
	expect(g, "food", "bridge")
	g.kitchen.built = true
	g.fissure.visited = false
	expect(g, "fiber", "scout")
	check(Status.inspect(g, "food").is_empty(), "Kitchen hidden until alcove is visited")
	g.fissure.visited = true
	g.fissure.upgrade.built = false
	expect(g, "fiber", "passage")
	expect(g, "food", "passage")
	g.fissure.upgrade.built = true
	var lamps: Array = g.torches.items.duplicate(true)
	g.torches.items.clear()
	expect(g, "food", "equipment")
	expect(g, "fiber", "equipment")
	g.torches.items.assign(lamps)
	for lamp in g.torches.items: lamp.reserved = 0
	expect(g, "food", "equipment_busy")
	expect(g, "fiber", "equipment_busy")
	for lamp in g.torches.items: lamp.reserved = -1
	var amount: int = g.kitchen.amount
	g.kitchen.amount = 0
	expect(g, "food", "exhausted")
	g.kitchen.amount = amount
	g.kitchen.reserved = amount
	expect(g, "food", "reserved")
	g.kitchen.reserved = 0
	var obstacles: Array[Rect2] = g.navigation_obstacles.duplicate()
	var near: Vector3 = g.fissure.NEAR
	obstacles.append(Rect2(Vector2(near.x, near.z) - Vector2(.5, .5), Vector2.ONE))
	g.navigation.configure(obstacles, g.navigation_stands)
	expect(g, "food", "source_path")
	expect(g, "fiber", "source_path")
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	for lamp in g.torches.items: lamp.fuel = 180
	expect(g, "food", "ready")
	expect(g, "fiber", "ready")
	g._show_tray("harvest_targets")
	var before: String = JSON.stringify(g.Save.capture(g).runtime)
	for i in range(5):
		for kind in g.Depots.KINDS: Status.inspect(g, kind)
		g._refresh_ui()
	check(before == JSON.stringify(g.Save.capture(g).runtime), "Reading diagnostics preserves all runtime state")
	var copy := clone(g, "remote diagnostics")
	if copy != null:
		expect(copy, "food", "ready")
		expect(copy, "fiber", "ready")
		copy.queue_free()
	# A previously displayed maintenance action must recheck the current state.
	g.hud._open_remote_harvest_diagnostic("food")
	check(g.active_tray == "kitchen", "Action recomputes current destination")
	for i in range(60):
		step(g)
		if not g.kitchen.tasks.is_empty(): break
	expect(g, "food", "working")
	g.queue_free()
	await process_frame
	print("REMOTE_HARVEST_STATUS: %d failure(s)" % failures)
	quit(1 if failures else 0)
