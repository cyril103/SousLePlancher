extends "res://tests/live_checkpoint.gd"
func run() -> void:
	var g := fixture()
	g.prepare_designations_demo()
	check(g.designations.owners.is_empty(), "Demo begins without assigned workers")
	check(g.designations.designate(), "Designation accepted")
	check(not g.designations.designate(), "Duplicate designation rejected")
	var initial := fibres(g)
	for i in range(1000):
		step(g)
		if g.fissure.missions.size() == 2: break
	check(g.fissure.missions.size() == 2, "Two residents automatically equipped and dispatched")
	check(g.fissure.hauling.reserved == 6, "Unique reservation for each crate")
	var copy := clone(g, "autonomous expedition")
	if copy != null:
		check(copy.designations.active and copy.designations.owners == g.designations.owners, "Designation ownership restored")
		copy.designations.cancel()
		for i in range(2000): step(copy)
		check(copy.fissure.missions.is_empty() and copy.designations.owners.is_empty(), "Cancelled restored order settles")
		check(fibres(copy) == initial, "Cancelled restored order conserves fibres")
		copy.queue_free()
	for i in range(1600):
		step(g)
		var loaded := false
		for w in g.workers:
			if w.carrying > 0: loaded = true
		if loaded: break
	g.designations.cancel()
	for i in range(2400): step(g)
	check(g.fissure.missions.is_empty() and g.fissure.hauling.reserved == 0 and g.designations.owners.is_empty(), "Cancellation returns loaded crates and releases claims")
	check(fibres(g) == initial, "No fibres lost or duplicated on cancellation")
	# Existing needs decide when people are available; no forced hunger bypass.
	for w in g.workers: w.hydration = 10.0
	g.designations.designate()
	step(g)
	check(g.designations.owners.is_empty(), "Thirst outranks autonomous task")
	g.designations.cancel()
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_designations_demo()
	for item in g.torches.items: item.fuel = 1.0
	g.designations.designate()
	for i in range(100): step(g)
	check(g.designations.owners.is_empty() and "lanterne" in g.designations.status, "Insufficient fuel waits with explanation")
	for item in g.torches.items: item.fuel = 180.0
	g.depots.set_filter(0, "fiber", false)
	for i in range(20): step(g)
	check(g.designations.owners.is_empty() and "dépôt" in g.designations.status, "Closed depot waits without reserving")
	g.depots.set_filter(0, "fiber", true)
	g.hiding = true
	for i in range(20): step(g)
	check(g.designations.owners.is_empty(), "Recall suppresses departures")
	g.hiding = false
	# A short finite source demonstrates completion without an infinite transport order.
	g.fissure.hauling.amount = 6
	g.fissure.hauling.known = 6
	initial = fibres(g)
	for i in range(3600):
		step(g)
		if not g.designations.active: break
	check(not g.designations.active and g.fissure.hauling.amount == 0, "Finite designation completes automatically")
	check(fibres(g) == initial, "Completion conserves all fibres including bed materials")
	g.designations.designate()
	g.fissure.hauling.amount = 6
	g.fissure.hauling.known = 6
	for w in g.workers:
		w.hydration = 95.0
		w.nutrition = 95.0
		w.energy = 95.0
		w.sleep_requested = false
		w.delivery.personal_recall = false
	for item in g.torches.items: item.fuel = 180.0
	for i in range(1200):
		step(g)
		if not g.designations.owners.is_empty(): break
	check(not g.designations.owners.is_empty(), "New order reserves equipment")
	var waiting := clone(g, "equipment reservation")
	if waiting != null: waiting.queue_free()
	g.designations.cancel()
	var cancelled: Dictionary = g.Save.capture(g)
	check(g.Save.validate(cancelled).is_empty(), "Immediate paused cancellation can be saved")
	for i in range(1200): step(g)
	var old: Dictionary = g.Save.capture(g)
	var codec = load("res://scripts/live_checkpoint.gd")
	var runtime: Dictionary = codec.unpack(old.runtime.data)
	runtime.erase("designations")
	old.runtime.data = codec.pack(runtime)
	old.runtime.sha256 = JSON.stringify(old.runtime.data).sha256_text()
	check(g.Save.validate(old).is_empty(), "Previous v10 snapshots remain readable")
	g.queue_free()
	await process_frame
	print("DESIGNATIONS: %d failure(s)" % failures)
	quit(1 if failures else 0)
