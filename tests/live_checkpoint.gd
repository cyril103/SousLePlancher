extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func fixture() -> Node:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	return g
func step(g: Node) -> void:
	g.simulate(.05)
	g.suspicion = 0
func fibres(g: Node) -> int:
	var total: int = g.depots.total("fiber") + g.fissure.hauling.amount
	for w in g.workers:
		if w.kind == "fiber": total += w.carrying
	for site in g.construction.sites(): total += site.materials.fiber
	return total
func clone(g: Node, label: String) -> Node:
	var snapshot: Dictionary = g.Save.capture(g)
	var problem: String = g.Save.validate(snapshot)
	check(problem.is_empty(), label + " validates: " + problem)
	if not problem.is_empty(): return null
	var path := "user://tests/live_%d/save.json" % Time.get_ticks_usec()
	var write_error: String = g.Save.write_checkpoint(path, snapshot)
	check(write_error.is_empty(), label + " writes atomically: " + write_error)
	if not write_error.is_empty(): print(g.Save.read_file(path + ".tmp"))
	var result: Dictionary = g.Save.read_checkpoint(path)
	check(result.ok, label + " reads JSON")
	if not result.ok: return null
	var other := fixture()
	check(other.apply_checkpoint(result.data), label + " restores scene")
	for i in range(g.workers.size()):
		var a: WorkerDelivery = g.workers[i].delivery
		var b: WorkerDelivery = other.workers[i].delivery
		check(a.actor.position.is_equal_approx(b.actor.position), label + " restores exact position H%d" % i)
		check(a.state == b.state and a.sector_id == b.sector_id and a.worker.carrying == b.worker.carrying, label + " restores controller and cargo")
	check(g.fissure.owner == other.fissure.owner and g.fissure.queue == other.fissure.queue, label + " preserves threshold reservations")
	check(g.depots.incoming == other.depots.incoming, label + " preserves depot claims")
	check(g.hiding == other.hiding and other.paused and is_equal_approx(g.elapsed, other.elapsed), label + " restores time paused without recall")
	check(fibres(g) == fibres(other), label + " preserves material balance")
	return other
func run() -> void:
	var g := fixture()
	g.prepare_alcove_haul_demo()
	# Ready equipment before departure, including an unfinished bed elsewhere.
	var before := clone(g, "before departure")
	if before != null: before.queue_free()
	await process_frame
	check(g.fissure.hauling.start(0), "Expedition departs")
	var tested := {}
	for i in range(2000):
		step(g)
		if not g.fissure.missions.has(0): break
		var m: Dictionary = g.fissure.missions[0]
		var key: String = m.phase + ("_loaded" if g.workers[0].carrying > 0 else "_empty")
		if tested.has(key) or not m.phase in ["wait", "cross", "harvest", "harvest_pickup", "back", "delivery_wait", "delivery_drop"]: continue
		tested[key] = true
		var other := clone(g, key)
		if other == null: continue
		var total := fibres(other)
		for j in range(1800):
			step(other)
			check(fibres(other) == total, key + " resumed tasks conserve fibres")
			if other.fissure.missions.is_empty() and other.torches.missions.is_empty() and other.sleeping.beds[0].built: break
		check(other.sleeping.beds[0].built and other.fissure.missions.is_empty(), key + " completes delivery and bed once")
		other.queue_free()
		await process_frame
	check(tested.has("cross_empty") and tested.has("cross_loaded") and tested.has("harvest_pickup_loaded"), "Captured both crossing directions and pickup event boundary")
	# Restore another worker's physical construction delivery concurrently.
	for i in range(1000):
		step(g)
		var transporting := false
		for w in g.workers: transporting = transporting or w.delivery.supply_job >= 0
		if transporting:
			var working := clone(g, "concurrent bed supply")
			if working != null:
				var total := fibres(working)
				for j in range(1000):
					step(working)
					check(fibres(working) == total, "Restored construction references conserve materials")
					if working.sleeping.beds[0].built: break
				check(working.sleeping.beds[0].built, "Restored construction target completes")
				working.queue_free()
				await process_frame
			break
	# F5 is synchronous between simulation steps, including while paused.
	g.save_path = "user://tests/live_request_%d/save.json" % Time.get_ticks_usec()
	var pos: Vector3 = g.workers[0].node.position
	var hiding: bool = g.hiding
	var clock: float = g.elapsed
	check(g.request_checkpoint(), "F5 accepted")
	check(not g.pending_save and g.save_available and g.paused, "F5 finishes without waiting for shelter")
	check(g.hiding == hiding and g.elapsed == clock and g.workers[0].node.position == pos, "F5 does not recall, advance or teleport")
	check(g.request_checkpoint(), "Repeated F5 accepted after completed write")
	var good: String = FileAccess.get_file_as_string(g.save_path)
	var invalid: Dictionary = g.Save.capture(g)
	invalid.runtime.sha256 = "invalid"
	check(not g.Save.write_checkpoint(g.save_path, invalid).is_empty(), "Corrupt runtime rejected before overwrite")
	check(FileAccess.get_file_as_string(g.save_path) == good, "Previous file protected")
	# A pre-live v9 checkpoint still migrates to a sheltered paused colony.
	g.pending_save = true
	if not g.hiding: g._toggle_hide()
	for i in range(2400):
		step(g)
		if g.checkpoint_ready(): break
	var legacy: Dictionary = g.Save.capture(g)
	legacy.version = 9
	legacy.erase("runtime")
	var old := fixture()
	check(old.apply_checkpoint(legacy) and old.checkpoint_ready(), "v9 checkpoint migration remains sheltered")
	old.queue_free()
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_alcove_haul_demo()
	g.torches.add_item(g.depots.entry(0), 180, "lantern")
	for i in range(1000):
		step(g)
		if g.torches.available(g.workers[1].delivery): break
	check(g.torches.equip(1, "lantern"), "Second scout equips")
	for i in range(1000):
		step(g)
		if g.torches.can_haul(1): break
	check(g.fissure.hauling.start(0) and g.fissure.hauling.start(1), "Concurrent expeditions start")
	for i in range(1000):
		step(g)
		if not g.fissure.queue.is_empty() and g.fissure.owner >= 0: break
	check(not g.fissure.queue.is_empty(), "Queue fixture reached")
	var queued := clone(g, "two scouts and threshold queue")
	if queued != null:
		var total := fibres(queued)
		for i in range(2400):
			step(queued)
			check(fibres(queued) == total, "Resumed concurrent expeditions conserve fibres")
			if queued.fissure.missions.is_empty() and queued.torches.missions.is_empty(): break
		check(queued.fissure.hauling.amount == 18 and queued.fissure.queue.is_empty(), "Both resumed expeditions deliver once")
		queued.queue_free()
	# Tampering with a validly encoded but inconsistent graph must be refused.
	var inconsistent: Dictionary = g.Save.capture(g)
	var raw: Dictionary = g.Save.Live.unpack(inconsistent.runtime.data)
	raw.fissure.owner = -1
	inconsistent.runtime.data = g.Save.Live.pack(raw)
	inconsistent.runtime.sha256 = JSON.stringify(inconsistent.runtime.data).sha256_text()
	check(not g.Save.validate(inconsistent).is_empty(), "Orphan crossing rejected even with matching integrity digest")
	g.queue_free()
	await process_frame
	# Meals and sleeping progress resume without consuming a second ration.
	g = fixture()
	g.prepare_needs_demo()
	var vital := clone(g, "meals and sleep in progress")
	if vital != null:
		for i in range(600):
			step(g)
			step(vital)
		check(g.stock.food == vital.stock.food and g.stock.water == vital.stock.water, "Resumed meals charge stock exactly once")
		for i in range(g.workers.size()):
			check(is_equal_approx(g.workers[i].nutrition, vital.workers[i].nutrition) and is_equal_approx(g.workers[i].hydration, vital.workers[i].hydration) and is_equal_approx(g.workers[i].energy, vital.workers[i].energy), "Needs follow the same timeline after load")
		vital.queue_free()
	g.queue_free()
	await process_frame
	g = fixture()
	g.start_panel.hide()
	g.stock.wood = 30
	g.stock.fiber = 20
	g.depots.sites[0].capacity = 128
	g._choose_build("workshop")
	check(g._place_build(Vector3(0, 0, -3)), "Craft fixture workshop")
	g.torches.request_craft("lantern")
	for i in range(2400):
		step(g)
		if g.torches.orders[0].work > 4: break
	var craft := clone(g, "lantern assembly")
	if craft != null:
		for i in range(1000):
			step(craft)
			if craft.torches.items.size() > 0: break
		check(craft.torches.items.size() == 1 and craft.torches.orders[0].built, "Restored assembly produces one lantern")
		craft.queue_free()
	g.queue_free()
	await process_frame
	print("LIVE_CHECKPOINT: ", failures, " failure(s)")
	quit(1 if failures else 0)
