extends "res://tests/live_checkpoint.gd"
func settle(g: Node, count: int = 3000) -> void:
	for i in range(count): step(g)
func run() -> void:
	var g := fixture()
	g.prepare_alcove_target_demo()
	for w in g.workers: w.priorities.transport = 0
	var initial := fibres(g)
	var source: int = g.fissure.hauling.amount
	var captured := false
	var partial := false
	for i in range(3400):
		step(g)
		check(g.local_harvest.expected("fiber") <= 5, "Concurrent crates never exceed common target")
		check(fibres(g) == initial, "Physical fibres conserved")
		for mission in g.fissure.missions.values():
			if mission.get("quantity", 0) == 2: partial = true
			if mission.get("collected", false) and not captured:
				captured = true
				var copy := clone(g, "regulated alcove loaded")
				if copy != null:
					settle(copy)
					check(copy.stock.fiber == 5 and copy.fissure.hauling.amount == source - 5, "Reload delivers exact target")
					copy.queue_free()
		if g.stock.fiber == 5 and g.designations.owners.is_empty(): break
	check(captured and partial and g.stock.fiber == 5, "Two crates include a partial final load")
	check(g.designations.active and "couvert" in g.designations.status, "Covered order remains designated")
	# The existing unfinished bed consumes three fibres through normal logistics.
	for w in g.workers: w.priorities.transport = 1
	settle(g, 4000)
	check(g.sleeping.beds[-1].built and g.stock.fiber == 5 and g.fissure.hauling.amount == source - 8, "Physical bed consumption restarts remote supply")
	check(fibres(g) == initial, "Bed and reserve retain all fibres")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_alcove_target_demo()
	for w in g.workers: w.priorities.transport = 0
	for i in range(1800):
		step(g)
		if g.fissure.hauling.reserved == 5: break
	check(g.fissure.hauling.reserved == 5, "Two departures committed")
	g.local_harvest.set_target("fiber", 0)
	settle(g)
	check(g.stock.fiber == 5 and g.designations.owners.is_empty(), "Lowering to zero finishes committed crates")
	var before: int = g.fissure.hauling.amount
	settle(g, 100)
	check(g.fissure.hauling.amount == before, "Zero prevents additional remote departures")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_alcove_target_demo()
	for w in g.workers: w.priorities.transport = 0
	g.local_harvest.set_active(4, true)
	for i in range(3400):
		step(g)
		check(g.local_harvest.expected("fiber") <= 5, "Ground and remote sources share one quota")
		if g.stock.fiber == 5 and g.designations.owners.is_empty(): break
	check(g.stock.fiber == 5, "Combined sources reach exact target")
	g.queue_free()
	await process_frame
	print("ALCOVE_TARGET: %d failure(s)" % failures)
	quit(1 if failures else 0)
