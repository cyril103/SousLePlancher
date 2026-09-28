extends "res://tests/live_checkpoint.gd"
func settle(g: Node) -> void:
	for i in range(1400): step(g)
func run() -> void:
	var g := fixture()
	g.prepare_harvest_targets_demo()
	g.hud.harvest_target_controls[1].target.value = 18
	check(g.local_harvest.targets.wood == 18, "UI edits wood target")
	g.hud.harvest_target_controls[1].target.value = 17
	var cloned := false
	var partial := false
	for i in range(1400):
		step(g)
		check(g.local_harvest.expected("wood") <= 17 and g.local_harvest.expected("fiber") <= 10, "Concurrent dispatch respects targets including reservations")
		for job in g.delivery_ledger.jobs.values():
			if job.kind == "wood" and job.quantity == 2: partial = true
		if not cloned and g.workers[0].carrying > 0:
			var copy := clone(g, "harvest quota in transit")
			if copy != null:
				check(copy.local_harvest.targets == g.local_harvest.targets, "Targets restore alongside cargo")
				settle(copy)
				check(copy.stock.wood == 17 and copy.stock.fiber == 10, "Reload reaches exact stock targets")
				copy.queue_free()
			cloned = true
	check(cloned and partial, "Loaded save and partial final crate exercised")
	check(g.stock.wood == 17 and g.stock.fiber == 10 and g.delivery_ledger.jobs.is_empty(), "Stops exactly at both targets")
	g.stock.wood -= 3
	settle(g)
	check(g.stock.wood == 17, "Consumption resumes designated harvest")
	g._choose_build("bed")
	check(g._place_build(Vector3(-3, 0, -4)), "Ordinary construction consumes regulated reserves")
	for i in range(1600):
		step(g)
		if g.sleeping.beds[0].built and g.stock.wood == 17 and g.stock.fiber == 10 and g.construction.jobs.is_empty() and g.delivery_ledger.jobs.is_empty(): break
	check(g.sleeping.beds[0].built and g.stock.wood == 17 and g.stock.fiber == 10, "Delivered construction materials trigger replacement harvests")
	var snapshot: Dictionary = g.Save.capture(g)
	var bad: Dictionary = snapshot.duplicate(true)
	bad.harvest_targets.wood = 3.5
	check(not g.Save.validate(bad).is_empty(), "Fractional target rejected")
	bad.harvest_targets.wood = -2
	check(not g.Save.validate(bad).is_empty(), "Negative invalid target rejected")
	bad.harvest_targets.wood = 10000
	check(not g.Save.validate(bad).is_empty(), "Excessive target rejected")
	bad = snapshot.duplicate(true)
	bad.erase("harvest_targets")
	check(not g.Save.validate(bad).is_empty(), "Version 23 requires targets")
	bad.version = 22
	check(g.Save.validate(bad).is_empty(), "Version 22 without targets accepted")
	var old := fixture()
	check(old.apply_checkpoint(bad), "Old save restored")
	check(old.local_harvest.targets.wood == -1 and old.patches[2].autoharvest, "Migration preserves designation without adding limits")
	old.queue_free()
	g.queue_free()
	await process_frame
	# Two food sources share one colony-wide target, including partial loads.
	g = fixture()
	g.start_panel.hide()
	g.local_harvest.set_active(0, true)
	g.local_harvest.set_active(1, true)
	g.local_harvest.set_target("food", 29)
	for i in range(1200):
		step(g)
		check(g.local_harvest.expected("food") <= 29, "Two sources never independently fill the same gap")
	check(g.stock.food == 29 and g.delivery_ledger.jobs.is_empty(), "Both sources share exact target")
	g.queue_free()
	await process_frame
	# Lowering a target does not confiscate or cancel already committed cargo.
	g = fixture()
	g.prepare_local_harvest_demo()
	g.local_harvest.set_active(4, false)
	g.local_harvest.set_target("wood", 17)
	for i in range(900):
		step(g)
		if g.workers[0].carrying > 0: break
	var expected: int = g.local_harvest.expected("wood")
	check(expected > 12, "Cargo committed before lowering target")
	g.local_harvest.set_target("wood", 0)
	settle(g)
	check(g.stock.wood == expected and g.delivery_ledger.jobs.is_empty(), "Lower target finishes existing loads and blocks subsequent work")
	g.workers[0].patch = 2
	for i in range(900):
		step(g)
		if g.stock.wood > expected: break
	check(g.stock.wood > expected, "Manual assignment ignores automatic quota")
	g.queue_free()
	await process_frame
	# Internal transfers reserve outbound and return space but never create stock.
	g = fixture()
	g.prepare_transfers_demo()
	var wood: int = g.depots.total("wood")
	var loaded := false
	for i in range(1600):
		step(g)
		for job in g.transfers.jobs.values():
			if job.collected and not job.deposited: loaded = true
		check(g.local_harvest.expected("wood") == wood, "Internal transfer counted once before, during and after delivery")
	check(loaded, "Transfer cargo exercised")
	g.queue_free()
	await process_frame
	print("HARVEST_TARGETS: %d failure(s)" % failures)
	quit(1 if failures else 0)
