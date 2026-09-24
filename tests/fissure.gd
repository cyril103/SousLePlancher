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
	g.start_panel.hide()
	g.stock.wood = 30
	g.stock.fiber = 20
	g.depots.sites[0].capacity = 128
	return g
func step(g: Node, count: int = 1) -> void:
	for i in range(count):
		g.simulate(.05)
		g.suspicion = 0
func settle(g: Node) -> void:
	g.pending_save = true
	if not g.hiding: g._toggle_hide()
	for i in range(3000):
		step(g)
		if g.checkpoint_ready(): return
	for w in g.workers: print(w.delivery.owner, " ", w.delivery.state, " ", w.node.position, " ", w.delivery.description())
	print(g.fissure.missions, " OWNER ", g.fissure.owner, " QUEUE ", g.fissure.queue)
	check(false, "All visitors and builders settle at refuge")
func run() -> void:
	var g := fixture()
	check(not g.fissure.request_build(), "Inspection required before construction")
	check(not g.fissure.start(0), "Blocked threshold cannot be crossed")
	check(g.fissure.start(0, true), "Physical inspection starts")
	for i in range(600):
		step(g)
		if g.fissure.discovered: break
	check(g.fissure.discovered and not g.fissure.opened(), "Inspector discovers without remotely opening passage")
	check(g.fissure.request_build(), "Construction starts after inspection")
	var wood: int = g.depots.total("wood")
	var fiber: int = g.depots.total("fiber")
	for i in range(2600):
		step(g)
		for kind in ["wood", "fiber"]:
			var carried := 0
			for w in g.workers:
				if w.kind == kind: carried += w.carrying
			check(g.depots.total(kind) + carried + g.fissure.site.materials[kind] == (wood if kind == "wood" else fiber), "Physical materials conserved: " + kind)
		if g.fissure.opened(): break
	check(g.fissure.opened() and g.fissure.site.work == 24, "Delivered materials and 24 seconds open threshold")
	check(g.depots.total("wood") == wood - 6 and g.depots.total("fiber") == fiber - 4, "Recipe paid once")
	settle(g)
	var saved: Dictionary = g.Save.capture(g)
	check(g.Save.validate(saved).is_empty(), "Open threshold save validates")
	var invalid := saved.duplicate(true)
	invalid.fissure.site.materials.wood = 5
	check(not g.Save.validate(invalid).is_empty(), "Reject free passage construction")
	g.queue_free()
	await process_frame
	g = fixture()
	check(g.apply_checkpoint(saved), "Open threshold reloads")
	check(g.fissure.opened() and g.fissure.braces.visible, "Open state and visuals persist")
	g.pending_save = false
	g._toggle_hide()
	check(g.fissure.start(0) and g.fissure.start(1), "Two visits can queue")
	check(g.fissure.start(2) and g.fissure.start(3), "Additional visitors share the same passage")
	var waited := false
	var crossing := false
	for i in range(1800):
		step(g)
		var count := 0
		for id in g.fissure.missions:
			if g.fissure.missions[id].phase == "cross": count += 1
		waited = waited or not g.fissure.queue.is_empty()
		crossing = crossing or count > 0
		check(count <= 1, "One threshold occupant")
		if g.fissure.missions.is_empty(): break
	check(waited and crossing and g.fissure.visited and g.fissure.missions.is_empty(), "Queued roundtrips reach annex and return")
	settle(g)
	g.pending_save = false
	g._toggle_hide()
	g.workers[0].carrying = 1
	check(not g.fissure.start(0), "Cargo forbidden")
	g.workers[0].carrying = 0
	check(g.fissure.start(0), "Recall visit starts")
	for i in range(600):
		step(g)
		if g.fissure.owner == 0 and g.fissure.missions[0].phase == "cross" and g.fissure.missions[0].clock > 1: break
	check(g.fissure.owner == 0, "Recall reaches committed threshold")
	var clock_before: float = g.fissure.missions[0].clock
	g.paused = true
	g._process(.25)
	check(g.fissure.missions[0].clock == clock_before, "Pause freezes passage traversal")
	g.paused = false
	g.speed = 3
	g._process(.1)
	check(is_equal_approx(g.fissure.missions[0].clock, clock_before + .3), "x3 uses simulation time for passage")
	var pos: Vector3 = g.workers[0].node.position
	g.workers[0].delivery.cancel()
	check(g.workers[0].node.position.is_equal_approx(pos) and g.fissure.owner == 0, "Recall does not teleport or release a crossing early")
	settle(g)
	check(g.fissure.owner == -1 and g.fissure.queue.is_empty(), "Recall releases passage")
	g.queue_free()
	await process_frame
	# Cancel while materials are being carried; delivered stock becomes a recovery pile.
	g = fixture()
	g.fissure.discovered = true
	g.fissure.request_build()
	for i in range(1000):
		step(g)
		if g.fissure.site.materials.wood > 0: break
	check(g.fissure.cancel_build(), "Site cancellation accepted")
	for i in range(1800):
		step(g)
		if g.construction.jobs.is_empty() and g.construction.recovery.is_empty(): break
	check(g.depots.total("wood") == 30 and g.depots.total("fiber") == 20, "Cancellation recovers every material")
	check(not g.fissure.opened(), "Cancelled work stays blocked")
	g.queue_free()
	await process_frame
	# Partial work persists, including physically delivered ingredients.
	g = fixture()
	g.fissure.discovered = true
	g.fissure.request_build()
	for i in range(2400):
		step(g)
		if g.fissure.site.work > 10: break
	var work: float = g.fissure.site.work
	check(work > 10 and work < 24, "Partly braced checkpoint fixture")
	settle(g)
	saved = g.Save.capture(g)
	check(g.Save.validate(saved).is_empty(), "Partial passage checkpoint validates")
	g.queue_free()
	await process_frame
	g = fixture()
	check(g.apply_checkpoint(saved), "Partial passage checkpoint restores")
	check(g.fissure.site.work == work and not g.fissure.opened(), "Work preserved without early opening")
	g._toggle_hide()
	step(g, 1200)
	check(g.fissure.opened(), "Restored work completes")
	check(g.depots.total("wood") == 24 and g.depots.total("fiber") == 16, "Restore never charges recipe twice")
	check(g.fissure.start(0), "Need interruption fixture starts")
	for i in range(600):
		step(g)
		if g.fissure.missions.has(0) and g.fissure.missions[0].side == "far": break
	g.workers[0].hydration = 34
	step(g)
	check(g.fissure.missions.has(0) and g.fissure.missions[0].returning, "Thirst triggers autonomous return from annex")
	for i in range(600):
		step(g)
		if not g.fissure.missions.has(0): break
	check(not g.fissure.missions.has(0), "Need-driven return crosses without global recall")
	settle(g)
	var legacy: Dictionary = g.Save.capture(g)
	legacy.version = 7
	legacy.erase("fissure")
	g.queue_free()
	await process_frame
	g = fixture()
	check(g.apply_checkpoint(legacy) and not g.fissure.discovered and not g.fissure.opened(), "v7 migrates with unopened fissure")
	g._toggle_hide()
	g.navigation_obstacles.append(Rect2(3.5, 4.5, 1, 1))
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	check(not g.fissure.start(0, true), "Blocked entrance refuses inspection without teleportation")
	g.queue_free()
	await process_frame
	print("FISSURE: ", failures, " failure(s)")
	quit(1 if failures else 0)
