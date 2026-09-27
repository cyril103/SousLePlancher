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
func total(g: Node) -> int:
	var result: int = g.fissure.hauling.amount + g.depots.total("fiber")
	for w in g.workers:
		if w.kind == "fiber": result += int(w.carrying)
	for site in g.construction.sites(): result += int(site.materials.fiber)
	for pile in g.construction.recovery: result += int(pile.materials.fiber)
	return result
func settle(g: Node) -> void:
	g.pending_save = true
	if not g.hiding: g._toggle_hide()
	for i in range(3000):
		step(g)
		if g.checkpoint_ready(): return
	for w in g.workers: print(w.delivery.state, " ", w.node.position, " ", w.delivery.description())
	print(g.fissure.missions)
	check(false, "Checkpoint settles remote cargo")
func equip(g: Node, ids: Array) -> void:
	g.pending_save = false
	if g.hiding: g._toggle_hide()
	for id in ids:
		g.workers[id].nutrition = 95
		g.workers[id].hydration = 95
		g.workers[id].energy = 95
		g.workers[id].sleep_requested = false
	for i in range(1200):
		step(g)
		var ready := true
		for id in ids: ready = ready and g.torches.available(g.workers[id].delivery)
		if ready: break
	for id in ids:
		g.torches.add_item(g.depots.entry(0), 180, "lantern")
		check(g.torches.equip(id, "lantern"), "Lantern equip starts")
	for i in range(1200):
		step(g)
		var ready := true
		for id in ids: ready = ready and g.torches.can_haul(id)
		if ready: return
	check(false, "Lanterns ready")
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_alcove_haul_demo()
	check(g.fissure.widened() and g.fissure.wide_frame.visible and not g.fissure.wall.visible, "Upgrade changes real opening model")
	check(g.sleeping.beds.size() == 1 and not g.sleeping.beds[0].built and g.sleeping.beds[0].materials.fiber == 0, "Demo bed needs remote fibres")
	check(g.stock.fiber == 0 and g.torches.can_haul(0), "Demo starts with zero stock fibres and a ready lantern")
	var balance := total(g)
	var capacity: int = g.depots.sites[0].capacity
	g.depots.sites[0].capacity = g.depots.used(0)
	check(not g.fissure.hauling.start(0), "Full depot refuses remote departure")
	check(g.fissure.hauling.reserved == 0, "Rejected departure reserves no fibres")
	g.depots.sites[0].capacity = capacity
	var item: Dictionary = g.torches.items[g.torches.held(0)]
	item.fuel = 15
	check(not g.fissure.hauling.start(0), "Insufficient fuel refuses hauling")
	item.fuel = 180
	check(g.fissure.hauling.start(0), "Remote hauling starts")
	check(g.fissure.hauling.reserved == 3 and g.depots.incoming.has("alcove:0"), "Source and depot are both reserved")
	var carried := false
	for i in range(3000):
		step(g)
		check(total(g) == balance, "Source + cargo + stock + building materials conserved")
		carried = carried or g.workers[0].carrying > 0
		if g.sleeping.beds[0].built and g.torches.missions.is_empty(): break
	check(carried and g.sleeping.beds[0].built, "Remote shipment enables physical bed completion")
	check(g.fissure.hauling.amount == 21 and g.fissure.hauling.reserved == 0, "Exactly one crate removed from source")
	settle(g)
	var saved: Dictionary = g.Save.capture(g)
	check(g.Save.validate(saved).is_empty() and saved.version == 9, "v9 checkpoint validates")
	var invalid := saved.duplicate(true)
	invalid.fissure.upgrade.materials.wood = 5
	check(not g.Save.validate(invalid).is_empty(), "Free widening rejected on load")
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.set_meta("restore_mode", true)
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(saved), "Checkpoint restores upgraded passage and remote source")
	check(restored.fissure.widened() and restored.fissure.hauling.amount == 21, "No remote resource respawn on load")
	restored.queue_free()
	await process_frame
	# Two residents compete for a finite source and independently reserved capacity.
	equip(g, [0, 1])
	check(g.fissure.hauling.start(0) and g.fissure.hauling.start(1), "Two porters depart")
	check(g.fissure.hauling.reserved == 6, "Distinct source claims")
	var recalled := false
	var thirst := false
	for i in range(2400):
		step(g)
		check(total(g) == balance, "Concurrent and recalled cargo remains conserved")
		if g.workers[0].carrying > 0 and not recalled:
			g.workers[0].delivery.cancel()
			recalled = true
		if g.workers[1].carrying > 0 and not thirst:
			g.workers[1].hydration = 34
			thirst = true
		if g.fissure.missions.is_empty(): break
	check(recalled and thirst and g.fissure.hauling.amount == 15, "Recall and thirst keep both collected crates")
	settle(g)
	check(g.depots.settled() and g.fissure.hauling.reserved == 0, "All source, depot and gate claims released")
	# Recall before the capture event releases a reservation without harvesting.
	equip(g, [0])
	check(g.fissure.hauling.start(0), "Cancellation fixture starts")
	g.workers[0].delivery.cancel()
	settle(g)
	check(g.fissure.hauling.amount == 15 and total(g) == balance, "Early recall takes no fibres")
	# A blocked destination must hold the same real crate and reservation.
	equip(g, [0])
	check(g.fissure.hauling.start(0), "Blocked delivery fixture starts")
	for i in range(1400):
		step(g)
		if g.fissure.missions.has(0) and g.fissure.missions[0].phase == "delivery_wait": break
	var obstacles: Array[Rect2] = g.navigation_obstacles.duplicate()
	var depot: Vector3 = g.depots.entry(0)
	g.navigation_obstacles.append(Rect2(depot.x - .5, depot.z - .5, 1, 1))
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	step(g, 20)
	check(g.workers[0].carrying == 3 and g.depots.incoming.has("alcove:0"), "Blocked depot keeps crate and reserved capacity")
	check(total(g) == balance, "Blocked destination loses no fibres")
	g.workers[0].delivery.cancel()
	g.navigation_obstacles = obstacles
	g.navigation.configure(g.navigation_obstacles, g.navigation_stands)
	settle(g)
	check(total(g) == balance, "Unblocking settles the recalled crate")
	# The final partial crate can be claimed only once.
	equip(g, [0, 1])
	g.fissure.hauling.amount = 2
	var final_balance := total(g)
	check(g.fissure.hauling.start(0), "Last partial crate accepted")
	check(not g.fissure.hauling.start(1), "Second resident cannot reserve the same final fibres")
	for i in range(1800):
		step(g)
		check(total(g) == final_balance, "Final partial crate conserved")
		if g.fissure.missions.is_empty(): break
	check(g.fissure.hauling.amount == 0 and g.fissure.hauling.reserved == 0, "Finite source exhausts exactly")
	settle(g)
	var legacy := saved.duplicate(true)
	legacy.version = 8
	for key in ["upgrade", "fiber", "known_fiber"]: legacy.fissure.erase(key)
	var old = load("res://scenes/main.tscn").instantiate()
	old.set_meta("restore_mode", true)
	root.add_child(old)
	old.set_process(false)
	check(old.apply_checkpoint(legacy), "v8 migrates")
	check(not old.fissure.widened() and old.fissure.hauling.amount == 24, "Migration preserves old narrow passage")
	old.queue_free()
	g.queue_free()
	await process_frame
	print("ALCOVE_HAUL: ", failures, " failure(s)")
	quit(1 if failures else 0)
