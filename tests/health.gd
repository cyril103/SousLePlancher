extends "res://tests/live_checkpoint.gd"
func total(g: Node) -> int:
	var result: int = fibres(g) + g.health.used_fiber
	for pile in g.construction.recovery: result += pile.materials.fiber
	for p in g.health.patients.values(): result += p.supplies
	for m in g.health.helpers.values(): result += m.bundle
	return result
func run() -> void:
	var g := fixture()
	g.prepare_health_demo()
	var initial := total(g)
	var tested := {}
	var interrupted := false
	for i in range(6000):
		step(g)
		check(total(g) == initial, "Fibres conserved across rescue and care")
		if not g.health.helpers.is_empty():
			var helper: int = g.health.helpers.keys()[0]
			var stage: String = g.health.helpers[helper].stage
			if not tested.has(stage) and stage in ["transport", "place", "fetch", "treat_walk", "treat"]:
				tested[stage] = true
				var other := clone(g, "health " + stage)
				if other != null:
					for j in range(5000):
						step(other)
						check(total(other) == initial, "Loaded care preserves fibres")
						if other.health.patients.is_empty(): break
					check(other.health.patients.is_empty(), "Loaded " + stage + " completes")
					other.queue_free()
					await process_frame
			if stage == "transport" and not interrupted:
				interrupted = true
				g.health.toggle(helper)
				check(g.health.patients[0].phase == "down" and g.health.patients[0].bed == -1, "Interruption safely releases bed and leaves patient recoverable")
		if g.health.patients.is_empty(): break
	check(g.health.patients.is_empty(), "Autonomous rescue, care and recovery complete")
	check(tested.has("transport") and tested.has("treat") and tested.has("fetch"), "Physical rescue and supply states observed")
	check(g.health.used_fiber == 2 and total(g) == initial, "One bandage consumed exactly once")
	for b in g.sleeping.beds: check(b.occupant == -1, "All patient reservations released")
	g.queue_free()
	await process_frame
	# Missing resources: rescue succeeds, patient remains in bed until stock arrives.
	g = fixture()
	g.prepare_health_demo()
	g.stock.fiber = 0
	for i in range(2400):
		step(g)
		if g.health.patients[0].phase == "bed" and g.health.helpers.is_empty(): break
	check(g.health.patients[0].phase == "bed" and g.health.used_fiber == 0, "No free healing without fibres")
	g.stock.fiber = 2
	for i in range(5000):
		step(g)
		if g.health.patients.is_empty(): break
	check(g.health.patients.is_empty() and g.stock.fiber == 0, "Supply restores autonomous care")
	g.queue_free()
	await process_frame
	# No reachable bed, then restoration of route.
	g = fixture()
	g.prepare_health_demo()
	for b in g.sleeping.beds: b.owner = 1
	for i in range(30): step(g)
	check(g.health.helpers.is_empty() and g.health.patients[0].phase == "down", "Occupied ownership does not steal another resident's bed")
	g.sleeping.beds[0].owner = -1
	var wall := Rect2(-19.5, -6.7, 4.9, .5)
	g.navigation_obstacles.append(wall)
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	for i in range(30): step(g)
	check(g.health.helpers.is_empty(), "Blocked bed is not reserved")
	g.navigation_obstacles.erase(wall)
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	for i in range(5000):
		step(g)
		if g.health.patients.is_empty(): break
	check(g.health.patients.is_empty(), "Restored access resumes rescue")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_health_demo()
	initial = total(g)
	var treatment_interrupted := false
	var bundle_interrupted := false
	for i in range(8000):
		step(g)
		check(total(g) == initial, "Interrupted medical supplies conserved")
		if not g.health.helpers.is_empty():
			var id: int = g.health.helpers.keys()[0]
			var m: Dictionary = g.health.helpers[id]
			if m.bundle == 2 and not bundle_interrupted:
				bundle_interrupted = true
				g.health.toggle(id)
				check(g.construction.recovery.size() == 1, "Interrupted bandage remains physically recoverable")
				# Another helper may use two remaining fibres while this bundle is reclaimed later.
			elif m.stage == "treat" and g.health.patients[0].care > 3 and not treatment_interrupted:
				treatment_interrupted = true
				g.health.toggle(id)
				check(g.health.patients[0].supplies == 2 and g.health.patients[0].care > 3, "Partial treatment and its supplies retained")
		if g.health.patients.is_empty(): break
	check(bundle_interrupted and treatment_interrupted and g.health.patients.is_empty(), "A replacement helper completes interrupted treatment")
	check(g.health.used_fiber == 2, "Interrupted care consumes a single bandage")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_health_demo()
	g.workers[1].node.position = Vector3(-10, WorkerDelivery.GROUND_Y, 4)
	check(g.health.injure(1), "Second patient can be rescued concurrently")
	for i in range(6000):
		step(g)
		if g.health.patients.is_empty(): break
	check(g.health.patients.is_empty() and g.health.used_fiber == 4, "Two patient claims are independent")
	g.queue_free()
	await process_frame
	g = fixture()
	var data: Dictionary = g.Save.capture(g)
	data.version = 15
	var runtime: Dictionary = g.Save.Live.unpack(data.runtime.data)
	runtime.erase("health")
	data.runtime.data = g.Save.Live.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(g.Save.validate(data).is_empty(), "Old v15 has no health requirement")
	var old := fixture()
	check(old.apply_checkpoint(data) and old.health.patients.is_empty(), "Old colony restores healthy")
	old.queue_free()
	g.queue_free()
	await process_frame
	print("HEALTH: %d failure(s)" % failures)
	quit(1 if failures else 0)
