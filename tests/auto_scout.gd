extends "res://tests/live_checkpoint.gd"
func settle(g: Node, count: int = 3200) -> void:
	for i in range(count): step(g)
func run() -> void:
	var g := fixture()
	check(not g.fissure.designate_scout(), "Closed passage refuses designation")
	g.prepare_auto_scout_demo()
	for w in g.workers: w.priorities.collect = 0
	settle(g, 50)
	check(g.fissure.scout_owner == -1, "Collect disabled blocks dispatch")
	g.priorities.set_priority(2, "collect", 1)
	var lamp: Dictionary = g.torches.items[0]
	lamp.fuel = 1
	settle(g, 50)
	check(g.fissure.scout_owner == -1, "Insufficient fuel never reserves equipment")
	lamp.fuel = 180
	var copy := clone(g, "scout waiting")
	if copy != null:
		check(copy.fissure.scout_requested and copy.fissure.scout_owner == -1, "Waiting designation restored")
		copy.queue_free()
	for i in range(600):
		step(g)
		if g.fissure.scout_owner >= 0: break
	check(g.fissure.scout_owner == 2, "Eligible resident assigned")
	copy = clone(g, "scout equipment reserved")
	if copy != null:
		settle(copy)
		check(copy.fissure.visited and copy.fissure.scout_owner == -1 and copy.torches.items.size() == 1 and copy.torches.items[0].owner == -1, "Reload takes one lantern, explores and stores it")
		copy.queue_free()
	g.fissure.cancel_scout()
	settle(g, 600)
	check(not g.fissure.visited and not g.fissure.scout_requested and g.fissure.scout_owner == -1 and lamp.reserved == -1, "Cancellation during pickup releases reservation")
	g.fissure.designate_scout()
	var crossing := false
	for i in range(2000):
		step(g)
		if g.fissure.missions.has(2) and g.fissure.missions[2].phase == "cross":
			crossing = true
			break
	check(crossing, "Actual threshold crossing reached")
	copy = clone(g, "scout crossing")
	if copy != null:
		copy._show_tray("scout")
		copy.hud.scout_cancel.pressed.emit()
		var cancelled := clone(copy, "scout cancelled crossing")
		if cancelled != null:
			settle(cancelled)
			check(not cancelled.fissure.scout_requested and cancelled.fissure.scout_owner == -1 and cancelled.fissure.missions.is_empty(), "Cancelled crossing reload returns safely without redispatch")
			check(cancelled.torches.items[0].owner == -1 and cancelled.fissure.hauling.amount == 24, "Lantern returned and no resources harvested")
			cancelled.queue_free()
		copy.queue_free()
	g._toggle_hide()
	settle(g, 800)
	check(g.fissure.scout_requested and g.fissure.scout_owner == -1, "Recall preserves order after equipment returns")
	g._toggle_hide()
	settle(g)
	check(g.fissure.visited and not g.fissure.scout_requested and g.fissure.scout_owner == -1, "Order resumes after recall and completes once")
	check(not g.fissure.widened() and g.fissure.hauling.amount == 24, "Reconnaissance neither widens nor harvests")
	var data: Dictionary = g.Save.capture(g)
	data.version = 26
	data.fissure.erase("scout_requested")
	data.fissure.erase("scout_owner")
	copy = fixture()
	check(copy.apply_checkpoint(data) and not copy.fissure.scout_requested and copy.fissure.scout_owner == -1, "Old save migration defaults scouting off")
	copy.queue_free()
	data = g.Save.capture(g)
	data.fissure.scout_owner = 99
	check(not g.Save.validate(data).is_empty(), "Invalid scout rejected")
	g.queue_free()
	await process_frame
	print("AUTO_SCOUT: %d failure(s)" % failures)
	quit(1 if failures else 0)
