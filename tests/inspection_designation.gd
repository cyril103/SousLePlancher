extends "res://tests/live_checkpoint.gd"
func run() -> void:
	var g := fixture()
	g.prepare_inspection_demo()
	check(g.fissure.inspect_requested and not g.fissure.designate_inspection(), "One designation only")
	for w in g.workers: w.priorities.build = 0
	for i in range(40): step(g)
	check(g.fissure.missions.is_empty() and "Construction" in g.fissure.inspection_summary(), "Disabled construction prevents dispatch")
	var copy := clone(g, "inspection waiting")
	if copy != null:
		check(copy.fissure.inspect_requested, "Waiting designation survives JSON")
		copy.queue_free()
	g.priorities.set_priority(2, "build", 1)
	g.workers[2].patch = 2
	check(not g.fissure.try_inspection(g.workers[2].delivery), "Assigned gatherer excluded")
	g.workers[2].patch = -1
	g.workers[2].energy = 20
	check(not g.fissure.try_inspection(g.workers[2].delivery), "Tired resident excluded")
	g.workers[2].energy = 100
	g.hiding = true
	check(not g.fissure.try_inspection(g.workers[2].delivery), "Recall blocks dispatch")
	g.hiding = false
	for i in range(500):
		step(g)
		if g.fissure.missions.has(2): break
	check(g.fissure.missions.size() == 1 and g.fissure.missions.has(2), "Eligible resident chosen exactly once")
	copy = clone(g, "inspection dispatched")
	if copy != null:
		for i in range(1400):
			step(copy)
			if copy.fissure.discovered: break
		check(copy.fissure.discovered and not copy.fissure.inspect_requested and not copy.fissure.opened(), "Restored inspection completes without opening passage")
		copy.queue_free()
	g._toggle_hide()
	for i in range(120): step(g)
	check(g.fissure.inspect_requested and not g.fissure.discovered and g.fissure.missions.is_empty(), "Recall keeps order and stops inspector")
	g._toggle_hide()
	for i in range(1200):
		step(g)
		if g.fissure.missions.has(2) and g.fissure.missions[2].phase == "inspect": break
	check(g.fissure.missions.has(2), "Dispatch resumes after recall")
	g._show_tray("inspection")
	g.hud.inspection_cancel.pressed.emit()
	check(not g.fissure.inspect_requested and g.fissure.missions.is_empty(), "UI cancellation removes order and recalls inspector")
	copy = clone(g, "inspection cancelled")
	if copy != null:
		for i in range(700): step(copy)
		check(not copy.fissure.discovered and copy.fissure.missions.is_empty(), "Cancelled inspection never restarts after reload")
		copy.queue_free()
	var old: Dictionary = g.Save.capture(g)
	old.version = 25
	old.fissure.erase("inspect_requested")
	check(g.Save.validate(old).is_empty(), "Previous save format accepted")
	copy = fixture()
	check(copy.apply_checkpoint(old) and not copy.fissure.inspect_requested, "Old saves start without designation")
	copy.queue_free()
	var bad: Dictionary = g.Save.capture(g)
	bad.fissure.inspect_requested = "yes"
	check(not g.Save.validate(bad).is_empty(), "Nonboolean designation rejected")
	g.hud.inspection_start.pressed.emit()
	for i in range(1600):
		step(g)
		if g.fissure.discovered: break
	check(g.fissure.discovered and not g.fissure.inspect_requested and g.fissure.site.is_empty(), "New designation finishes and leaves construction to player")
	check(g.stock.wood == 12 and g.stock.fiber == 6 and g.torches.items.is_empty(), "Inspection consumes no material or equipment")
	g.queue_free()
	await process_frame
	print("INSPECTION_DESIGNATION: %d failure(s)" % failures)
	quit(1 if failures else 0)
