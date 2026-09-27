extends "res://tests/live_checkpoint.gd"
func disable(g: Node) -> void:
	g.start_panel.hide()
	for w in g.workers: w.priorities = {"collect": 0, "transport": 0, "build": 0}
func run() -> void:
	var g := fixture()
	g.prepare_priorities_demo()
	var initial := fibres(g)
	var seen_transport := false
	var seen_build := false
	for i in range(3000):
		step(g)
		for id in g.designations.owners: check(id == 0, "Only designated collector claims expedition")
		for job in g.construction.jobs.values():
			seen_transport = true
			check(job.owner == 1, "Porter supplies artisan")
		if g.sleeping.beds[0].builder >= 0:
			seen_build = true
			check(g.sleeping.beds[0].builder == 2, "Artisan constructs supplied bed")
		if g.sleeping.beds[0].built: break
	check(seen_transport and seen_build and g.sleeping.beds[0].built, "Specialized team completes bed autonomously")
	check(fibres(g) == initial, "Specialized chain conserves resources")
	var copy := clone(g, "individual priorities")
	if copy != null:
		for i in range(4): check(copy.workers[i].priorities == g.workers[i].priorities, "Individual preferences restored")
		copy.queue_free()
	g.queue_free()
	await process_frame
	# Rank changes select between two available kinds; disabled jobs never start.
	for transport_first in [false, true]:
		g = fixture()
		disable(g)
		g._choose_build("bed")
		check(g._place_build(Vector3(0, 0, -3)), "Fixture bed placed")
		g.workers[0].patch = 0
		g.workers[0].priorities = {"collect": 2 if transport_first else 1, "transport": 1 if transport_first else 2, "build": 0}
		var c: WorkerDelivery = g.workers[0].delivery
		check(g.priorities.start(c), "A permitted task starts")
		check(c.supply_job >= 0 if transport_first else c.job >= 0, "Lower numerical priority wins")
		g.priorities.set_priority(0, "collect", 0)
		g.priorities.set_priority(0, "transport", 0)
		for i in range(1600): step(g)
		check(c.job < 0 and c.supply_job < 0 and c.worker.carrying == 0, "Disable during work settles existing cargo")
		check(not g.priorities.start(c), "All disabled blocks new work")
		g.queue_free()
		await process_frame
	# Unavailable first choice falls back, and no builder is explicitly explained.
	g = fixture()
	disable(g)
	g.workers[0].priorities = {"collect": 1, "transport": 2, "build": 0}
	g._choose_build("bed")
	check(g._place_build(Vector3(0, 0, -3)), "Fixture bed placed")
	check(g.priorities.start(g.workers[0].delivery) and g.workers[0].delivery.supply_job >= 0, "Blocked collection falls back to supply")
	check("Construction : aucun" in g.priorities.summary(), "No eligible artisan is explained")
	g.queue_free()
	await process_frame
	# Resting artisan leaves a ready construction to the available backup.
	g = fixture()
	disable(g)
	g._choose_build("bed")
	check(g._place_build(Vector3(0, 0, -3)), "Backup fixture placed")
	g.sleeping.beds[0].materials = {"wood": 4, "fiber": 3}
	g.stock.wood -= 4
	g.stock.fiber -= 3
	g.priorities.set_priority(0, "build", 1)
	g.priorities.set_priority(1, "build", 2)
	g.workers[0].energy = 10.0
	step(g)
	check(g.sleeping.beds[0].builder == 1, "Resting artisan replaced by backup builder")
	g.priorities.set_priority(1, "build", 0)
	for i in range(900):
		step(g)
		if g.sleeping.beds[0].built: break
	check(g.sleeping.beds[0].built, "Disabling construction finishes committed work")
	g.queue_free()
	await process_frame
	# An absent collector is replaced by another eligible resident, thirst is not overridden.
	g = fixture()
	g.prepare_priorities_demo()
	g.workers[0].hydration = 10.0
	g.priorities.set_priority(3, "collect", 2)
	for i in range(1000):
		step(g)
		if g.designations.owners.has(3): break
	check(g.designations.owners.has(3) and not g.designations.owners.has(0), "Thirsty collector replaced by available resident")
	var data: Dictionary = g.Save.capture(g)
	var codec = load("res://scripts/live_checkpoint.gd")
	var runtime: Dictionary = codec.unpack(data.runtime.data)
	runtime.workers[0].worker.priorities.collect = 9
	data.runtime.data = codec.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(not g.Save.validate(data).is_empty(), "Invalid saved priority rejected")
	for w in runtime.workers: w.worker.erase("priorities")
	data.runtime.data = codec.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(g.Save.validate(data).is_empty(), "Previous snapshots without preferences validate")
	copy = fixture()
	check(copy.apply_checkpoint(data), "Previous snapshot restored")
	check(copy.priorities.value(0, "collect") == 2, "Migration defaults to normal priorities")
	g.queue_free()
	copy.queue_free()
	await process_frame
	print("PRIORITIES: %d failure(s)" % failures)
	quit(1 if failures else 0)
