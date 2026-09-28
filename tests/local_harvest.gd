extends "res://tests/live_checkpoint.gd"
func total(g: Node, kind: String) -> int:
	var amount: int = g.depots.total(kind)
	for p in g.patches:
		if p.kind == kind: amount += p.amount
	for w in g.workers:
		if w.kind == kind: amount += w.carrying
	return amount
func run() -> void:
	var g := fixture()
	g.prepare_local_harvest_demo()
	g.hud.local_harvest_rows[2].toggle.pressed.emit()
	check(not g.patches[2].autoharvest, "UI suspends selected wood source")
	g.hud.local_harvest_rows[2].toggle.pressed.emit()
	check(g.patches[2].autoharvest, "UI resumes selected wood source")
	g.patches[2].amount = 6
	g.patches[4].amount = 6
	var wood := total(g, "wood")
	var fiber := total(g, "fiber")
	check(not g.local_harvest.set_active(3, true) and not g.local_harvest.set_active(6, true), "Elevated and undiscovered sources excluded")
	var copied := false
	for i in range(2400):
		step(g)
		check(total(g, "wood") == wood and total(g, "fiber") == fiber, "Autonomous transport conserves resources")
		for w in g.workers: check(w.patch == -1, "Automatic order never assigns a resident permanently")
		if not copied:
			for w in g.workers:
				if w.carrying <= 0: continue
				var copy := clone(g, "local harvest loaded")
				if copy != null:
					check(copy.patches[2].autoharvest and copy.patches[4].autoharvest, "Orders restored alongside cargo")
					for j in range(2400):
						step(copy)
						if copy.patches[2].amount == 0 and copy.patches[4].amount == 0 and copy.delivery_ledger.jobs.is_empty(): break
					check(copy.patches[2].amount == 0 and copy.patches[4].amount == 0, "Restored orders finish both sources")
					check(total(copy, "wood") == wood and total(copy, "fiber") == fiber, "Restored physical loads conserved")
					copy.queue_free()
				copied = true
				break
		if g.patches[2].amount == 0 and g.patches[4].amount == 0 and g.delivery_ledger.jobs.is_empty(): break
	check(copied and g.patches[2].amount == 0 and g.patches[4].amount == 0, "Free residents harvest designated ground sources to exhaustion")
	g.queue_free()
	await process_frame
	g = fixture()
	g.start_panel.hide()
	for w in g.workers: w.priorities = {"collect": 0, "transport": 0, "build": 0}
	g.local_harvest.set_active(2, true)
	for i in range(40): step(g)
	check(g.delivery_ledger.jobs.is_empty(), "Disabled collection prevents dispatch")
	g.priorities.set_priority(0, "collect", 1)
	for i in range(900):
		step(g)
		if g.workers[0].carrying > 0: break
	check(g.workers[0].carrying > 0, "Permitted free resident picks up wood")
	wood = total(g, "wood")
	g.local_harvest.set_active(2, false)
	var remaining: int = g.patches[2].amount
	for i in range(900): step(g)
	check(g.delivery_ledger.jobs.is_empty() and g.workers[0].carrying == 0, "Suspension finishes committed cargo")
	check(g.patches[2].amount == remaining and total(g, "wood") == wood, "Suspension prevents new dispatch without losing cargo")
	g.local_harvest.set_active(2, true)
	g._toggle_hide()
	for i in range(40): step(g)
	check(g.delivery_ledger.jobs.is_empty(), "Global recall prevents automatic harvest")
	g._toggle_hide()
	for i in range(900):
		step(g)
		if g.workers[0].carrying > 0: break
	check(g.workers[0].carrying > 0, "Recall release resumes existing designation")
	g.local_harvest.set_active(2, false)
	for i in range(900): step(g)
	# Manual assignment remains independent and takes precedence over local orders.
	g.workers[0].patch = 4
	g.local_harvest.set_active(2, true)
	for i in range(900):
		step(g)
		if not g.delivery_ledger.jobs.is_empty(): break
	check(not g.delivery_ledger.jobs.is_empty(), "Manual source remains usable")
	for job in g.delivery_ledger.jobs.values(): check(job.source == 4, "Manual assignment wins over automatic wood")
	var data: Dictionary = g.Save.capture(g)
	var codec = load("res://scripts/live_checkpoint.gd")
	var bad: Dictionary = data.duplicate(true)
	bad.patches[2].autoharvest = 1
	check(not g.Save.validate(bad).is_empty(), "Non-boolean order rejected")
	bad = data.duplicate(true)
	bad.patches[3].autoharvest = true
	check(not g.Save.validate(bad).is_empty(), "Saved elevated order rejected")
	bad = data.duplicate(true)
	bad.patches[2].autoharvest = false
	check(not g.Save.validate(bad).is_empty(), "Runtime and compact order mismatch rejected")
	data.version = 21
	for p in data.patches: p.erase("autoharvest")
	var runtime: Dictionary = codec.unpack(data.runtime.data)
	for p in runtime.patches: p.erase("autoharvest")
	data.runtime.data = codec.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(g.Save.validate(data).is_empty(), "Version 21 without designations accepted")
	var migrated := fixture()
	check(migrated.apply_checkpoint(data), "Version 21 restored")
	for p in migrated.patches: check(not p.autoharvest, "Old saves keep automatic harvest disabled")
	migrated.queue_free()
	g.queue_free()
	await process_frame
	g = fixture()
	g.start_panel.hide()
	for w in g.workers: w.priorities = {"collect": 0, "transport": 0, "build": 0}
	g.priorities.set_priority(0, "collect", 1)
	g.local_harvest.set_active(2, true)
	g.workers[0].hydration = 10.0
	for i in range(20): step(g)
	check(g.delivery_ledger.jobs.is_empty(), "Urgent thirst precedes autonomous wood collection")
	g.workers[0].hydration = 100.0
	g.depots.sites[0].capacity = g.depots.used(0)
	for i in range(60): step(g)
	check(g.delivery_ledger.jobs.is_empty(), "Full depot blocks dispatch without reserving resources")
	g.depots.sites[0].capacity += 3
	for i in range(900):
		step(g)
		if g.workers[0].carrying > 0: break
	check(g.workers[0].carrying > 0, "New storage space resumes order")
	g.queue_free()
	await process_frame
	g = fixture()
	g.start_panel.hide()
	for id in [0, 1, 7]:
		g.patches[id].amount = 3
		g.local_harvest.set_active(id, true)
	var food: int = g.stock.food
	var water: int = g.stock.water
	for i in range(1800):
		step(g)
		if g.patches[0].amount == 0 and g.patches[1].amount == 0 and g.patches[7].amount == 0 and g.delivery_ledger.jobs.is_empty(): break
	check(g.stock.food == food + 6 and g.stock.water == water + 3, "Both food sources and water delivered physically")
	g.queue_free()
	await process_frame
	print("LOCAL_HARVEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
