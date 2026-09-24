extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func advance(game: Node, seconds: float) -> void:
	for i in range(roundi(seconds * 20)):
		game.simulate(.05)
		game.suspicion = 0
func fixture() -> Node:
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.stock.wood = 28
	game.stock.fiber = 16
	game.depots.sites[0].capacity = 128
	game.build_mode = "workshop"
	check(game._place_build(Vector3(0, 0, -3)), "Accessible workshop")
	return game
func equip(game: Node, owner: int = 0) -> void:
	check(game.torches.equip(owner, "lantern"), "Reserve lantern")
	for i in range(800):
		advance(game, .05)
		if game.torches.lantern(owner): return
	check(false, "Physical equipment completes")
func settle(game: Node) -> void:
	game.pending_save = true
	if not game.hiding: game._toggle_hide()
	for i in range(3200):
		advance(game, .05)
		if game.checkpoint_ready(): return
	for w in game.workers: print(w.node.position, " ", w.delivery.state, " ", w.delivery.description())
	print("MISSIONS ", game.torches.missions)
	check(false, "Recall reaches settled checkpoint")
func run() -> void:
	var game := fixture()
	var wood: int = game.stock.wood
	var fiber: int = game.stock.fiber
	check(game.torches.request_craft("lantern"), "Lantern recipe accepted")
	check(not game.torches.request_craft(), "Torch and lantern share the same workshop slot")
	for i in range(2200):
		advance(game, .05)
		var carried_wood := 0
		var carried_fiber := 0
		for w in game.workers:
			if w.kind == "wood": carried_wood += int(w.carrying)
			if w.kind == "fiber": carried_fiber += int(w.carrying)
		check(game.stock.wood + carried_wood + game.torches.orders[0].materials.wood == wood, "Wood conserved through lantern supplies")
		check(game.stock.fiber + carried_fiber + game.torches.orders[0].materials.fiber == fiber, "Fibers conserved through lantern supplies")
		if game.torches.items.size() == 1: break
	check(game.stock.wood == wood - 4 and game.stock.fiber == fiber - 3, "4 wood + 3 fiber paid exactly once")
	check(game.torches.orders[0].work == 16 and game.torches.items[0].fuel == 180, "Assembly time and initial fuel")
	advance(game, .1)
	equip(game)
	var c: WorkerDelivery = game.workers[0].delivery
	check(not game.torches.hands_occupied(0) and c.actor.lantern.visible and not c.actor.torch.visible, "Belt lamp leaves both hands free")
	game.torches.items[0].fuel = 30
	check(not game.torches.depart(0, game.Bridge.SCOUT_POINT), "Reject insufficient ladder roundtrip fuel")
	game.torches.items[0].fuel = 180
	check(game.torches.depart(0, game.Bridge.SCOUT_POINT), "Lantern can reach the east deck")
	var climbing_seen := false
	var bridge_seen := false
	for i in range(2300):
		advance(game, .05)
		climbing_seen = climbing_seen or c.climbing
		bridge_seen = bridge_seen or c.bridge_active
		if not game.torches.missions.has(0): break
	check(climbing_seen and bridge_seen and c.crossings == 2 and c.bridge_crossings == 2, "Real ladder and bridge crossed in both directions")
	check(game.east_discovered and c.inside_refuge, "Observation discovers reserve, then scout returns home")
	check(game.torches.items[0].fuel > 0 and game.torches.items[0].owner == -1, "Remaining fuel stored after scouting")
	# Unlit equipment does not regenerate; use a fresh lamp for the second long trip.
	advance(game, 4)
	game.torches.add_item(game.depots.entry(0), 180, "lantern")
	equip(game)
	check(game.torches.held(0) == 1, "Replacement chooses the best-fueled accessible lantern")
	var supply_before: int = game.patches[6].amount + game.depots.total("wood")
	check(game.torches.start_haul(0, 6), "Lit cargo mission starts")
	var loaded_climb := false
	var delivered_before := c.completed_deliveries
	for i in range(2400):
		advance(game, .05)
		loaded_climb = loaded_climb or (c.climbing and c.worker.carrying > 0)
		var total: int = game.patches[6].amount + game.depots.total("wood") + int(c.worker.carrying)
		check(total == supply_before, "Cargo and depot stock remain conserved")
		if not game.torches.missions.has(0): break
	check(loaded_climb and c.completed_deliveries == delivered_before + 1, "One crate descends and is delivered exactly once")
	check(c.inside_refuge and c.worker.patch == -1 and c.job < 0, "Cargo mission finishes at refuge without restarting")
	settle(game)
	var saved: Dictionary = game.Save.capture(game)
	check(game.Save.validate(saved).is_empty(), "v7 lantern save validates")
	var legacy := saved.duplicate(true)
	legacy.version = 6
	for item in legacy.torches.items:
		item.erase("kind")
		item.fuel = minf(item.fuel, 90)
	check(game.Save.validate(legacy).is_empty(), "v6 equipment without kind remains valid")
	var invalid := saved.duplicate(true)
	invalid.torches.items[0].kind = "invalid"
	check(not game.Save.validate(invalid).is_empty(), "Reject unknown equipment")
	invalid = saved.duplicate(true)
	invalid.torches.items[0].fuel = 181
	check(not game.Save.validate(invalid).is_empty(), "Reject fuel beyond lantern capacity")
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.set_meta("restore_mode", true)
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(saved), "Restore v7 with lanterns")
	check(restored.torches.items[0].kind == "lantern" and restored.torches.items[0].fuel == game.torches.items[0].fuel, "Type and fuel persist")
	restored.queue_free()
	game.queue_free()
	await process_frame
	# Interrupt while already on the ladder: finish the crossing, release locks, return.
	game = fixture()
	game.torches.add_item(game.depots.entry(0), 180, "lantern")
	equip(game)
	c = game.workers[0].delivery
	game.torches.depart(0, game.Bridge.SCOUT_POINT)
	for i in range(600):
		advance(game, .05)
		if c.climbing and c.climb_time > 2: break
	check(c.climbing, "Recall fixture is mid-ladder")
	var position: Vector3 = c.actor.position
	game.torches.recall(c)
	check(c.climbing and c.actor.position.is_equal_approx(position), "Recall does not teleport or abort climb pose")
	settle(game)
	check(game.ladder.owner == -1 and game.bridge.owner == -1, "Access locks released after interrupted scout")
	game.queue_free()
	await process_frame
	# A persistent global recall during loaded descent must not restart unloading.
	game = fixture()
	game.discover_east()
	game.torches.add_item(game.depots.entry(0), 180, "lantern")
	equip(game)
	c = game.workers[0].delivery
	supply_before = game.patches[6].amount + game.depots.total("wood")
	check(game.torches.start_haul(0, 6), "Recall cargo fixture starts")
	for i in range(1500):
		advance(game, .05)
		if c.climbing and c.worker.carrying > 0 and c.climb_time > 2: break
	check(c.climbing and c.worker.carrying > 0, "Recall interrupts a loaded descent")
	settle(game)
	check(c.job < 0 and c.worker.carrying == 0, "Recall settles cargo without a stuck delivery")
	check(game.patches[6].amount + game.depots.total("wood") == supply_before, "Recalled cargo conserved")
	check(game.ladder.owner == -1 and game.bridge.owner == -1, "Loaded recall releases crossings")
	game.queue_free()
	await process_frame
	game = fixture()
	game.torches.request_craft("lantern")
	for i in range(2000):
		advance(game, .05)
		if game.torches.orders[0].work > 2: break
	var progress: float = game.torches.orders[0].work
	check(progress > 0 and progress < 16, "Lantern assembly interruption reached")
	settle(game)
	saved = game.Save.capture(game)
	check(game.Save.validate(saved).is_empty(), "Partial lantern assembly checkpoint validates")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	check(game.apply_checkpoint(saved), "Restore partial lantern recipe")
	check(game.torches.orders[0].kind == "lantern" and game.torches.orders[0].work == progress, "Lantern recipe and work persist")
	game.pending_save = false
	if game.hiding: game._toggle_hide()
	advance(game, 50)
	check(game.torches.items.size() == 1 and game.torches.items[0].kind == "lantern", "Resumed assembly produces one lantern")
	game.queue_free()
	await process_frame
	print("LANTERNS: ", failures, " failure(s)")
	quit(1 if failures else 0)
