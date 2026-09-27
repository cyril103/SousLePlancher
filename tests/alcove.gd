extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func step(g: Node, count: int = 1) -> void:
	for i in range(count):
		g.simulate(.05)
		g.suspicion = 0
func return_all(g: Node) -> void:
	g.pending_save = true
	if not g.hiding: g._toggle_hide()
	for i in range(3000):
		step(g)
		if g.checkpoint_ready(): return
	check(false, "Every mission settles before checkpoint")
func equip(g: Node) -> void:
	g.pending_save = false
	if g.hiding: g._toggle_hide()
	g.workers[0].nutrition = 95
	g.workers[0].hydration = 95
	g.workers[0].sleep_requested = false
	g.torches.add_item(g.depots.entry(0), 180, "lantern")
	check(g.torches.equip(0, "lantern"), "Equip after prior expedition")
	for i in range(1200):
		step(g)
		if g.torches.can_haul(0): return
	check(false, "Equipping completes")
func reach(g: Node, phase: String) -> void:
	for i in range(1600):
		step(g)
		if g.fissure.missions.has(0) and g.fissure.missions[0].phase == phase: return
	check(false, "Reach expedition phase: " + phase)
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_alcove_demo()
	var c: WorkerDelivery = g.workers[0].delivery
	check(g.fissure.opened() and g.torches.can_haul(0), "Playable demo is ready")
	check(not g.fissure.annex.visible and not g.fissure.visited, "Unexplored scenery is hidden")
	check(not g.fissure.start(1), "Unequipped resident cannot explore")
	var item: Dictionary = g.torches.items[g.torches.held(0)]
	item.fuel = 10
	check(not g.fissure.start(0), "Low fuel refuses departure")
	check(g.torches.missions[0].phase == "ready" and not item.lit, "Refusal leaves equipment ready and unlit")
	item.fuel = 180
	check(g.fissure.start(0), "Equipped departure accepted")
	check(g.torches.missions[0].phase == "sector", "Movement delegated to passage")
	reach(g, "cross")
	var before: float = item.fuel
	var clock_before: float = g.fissure.missions[0].clock
	g.paused = true
	g._process(.2)
	check(item.fuel == before and g.fissure.missions[0].clock == clock_before, "Pause freezes fuel and crossing together")
	g.paused = false
	g.speed = 3
	g._process(.1)
	check(is_equal_approx(item.fuel, before - .3), "x3 consumes simulation fuel")
	var position: Vector3 = c.actor.position
	c.cancel()
	check(c.actor.position == position and g.fissure.owner == 0, "Recall preserves committed crossing")
	return_all(g)
	check(not g.fissure.visited and not g.fissure.annex.visible, "Interrupted reconnaissance is not completed remotely")
	check(c.sector_id == g.fissure.HOME_SECTOR and c.inside_refuge, "Resident returns to exactly one home sector")
	check(item.owner == -1 and not item.lit and item.fuel < before, "Equipment returned with consumed fuel")
	equip(g)
	check(g.fissure.start(0), "Second expedition starts")
	reach(g, "look")
	check(c.sector_id == g.fissure.ALCOVE_SECTOR and g.fissure.observed(), "Resident and live observation belong to alcove")
	check(g.fissure.annex.visible and not g.fissure.visited, "Scenery visible during actual reconnaissance")
	step(g, 250)
	check(g.fissure.visited, "Observation completes discovery")
	return_all(g)
	check(g.fissure.annex.visible and not g.fissure.observed(), "Static scenery remains memorized without live observation")
	var saved: Dictionary = g.Save.capture(g)
	check(g.Save.validate(saved).is_empty() and saved.fissure.visited, "Discovery saved in refuge checkpoint")
	# A new scene must reconstruct knowledge, never active expeditions.
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.set_meta("restore_mode", true)
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(saved), "Checkpoint restores")
	check(restored.fissure.visited and restored.fissure.annex.visible and restored.fissure.missions.is_empty(), "Discovery persists without orphan mission")
	restored.queue_free()
	await process_frame
	for reason in ["thirst", "sleep", "fuel"]:
		equip(g)
		check(g.fissure.start(0), "Interruption expedition: " + reason)
		reach(g, "look")
		if reason == "thirst": c.worker.hydration = 34
		elif reason == "sleep": c.worker.sleep_requested = true
		else: g.torches.items[g.torches.held(0)].fuel = g.fissure.return_budget(c) + 23
		step(g)
		check(g.fissure.missions[0].returning, "Autonomous recall: " + reason)
		for i in range(1800):
			step(g)
			if c.inside_refuge: break
		check(c.inside_refuge and c.sector_id == g.fissure.HOME_SECTOR, "Autonomous return completes: " + reason)
		return_all(g)
	# Outgoing and returning residents compete for the same physical threshold.
	equip(g)
	g.workers[1].nutrition = 95
	g.workers[1].hydration = 95
	g.workers[1].sleep_requested = false
	g.workers[1].energy = 95
	for i in range(1200):
		step(g)
		if g.torches.available(g.workers[1].delivery): break
	g.torches.add_item(g.depots.entry(0), 180, "lantern")
	check(g.torches.equip(1, "lantern"), "Second scout equips")
	for i in range(1200):
		step(g)
		if g.torches.can_haul(1): break
	check(g.fissure.start(0), "Outbound scout starts")
	reach(g, "look")
	check(g.fissure.start(1), "Opposite scout starts while alcove is occupied")
	c.cancel()
	var sides := {}
	var waited := false
	for i in range(1800):
		var prior_fuel := {}
		for id in g.fissure.missions:
			prior_fuel[id] = g.torches.items[g.torches.held(id)].fuel
		step(g)
		var crossings := 0
		for id in g.fissure.missions:
			var m: Dictionary = g.fissure.missions[id]
			if m.phase in ["cross", "clear"]:
				crossings += 1
				check(g.fissure.owner == id, "Passage stays reserved through exit clearance")
			if m.phase == "cross": sides[m.side] = true
			if m.phase == "wait":
				waited = true
				if prior_fuel.has(id): check(g.torches.items[g.torches.held(id)].fuel < prior_fuel[id], "Queue consumes fuel")
		check(crossings <= 1, "Opposite directions never cross simultaneously")
		if g.fissure.missions.is_empty(): break
	check(waited and sides.has("near") and sides.has("far"), "Both directions use the shared queue")
	return_all(g)
	g.queue_free()
	await process_frame
	print("ALCOVE: ", failures, " failure(s)")
	quit(1 if failures else 0)
