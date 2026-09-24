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
	game.stock.wood = 24
	game.stock.fiber = 12
	game.depots.sites[0].capacity = 128
	game.build_mode = "workshop"
	check(game._place_build(Vector3(0, 0, -3)), "Workshop has a reachable entrance")
	return game
func recall(game: Node) -> void:
	game.pending_save = true
	if not game.hiding: game._toggle_hide()
	for i in range(2400):
		advance(game, .05)
		if game.checkpoint_ready(): return
	for worker in game.workers: print(worker.node.position, " ", worker.delivery.state, " ", worker.delivery.description())
	check(false, "Torch recall settles all transactions and door locks")
func equipped(game: Node, owner: int = 0) -> void:
	check(game.torches.equip(owner), "Resident can reserve a stored torch")
	for i in range(800):
		advance(game, .05)
		if game.torches.held(owner) >= 0: return
	check(false, "Resident physically collects the torch")
func run() -> void:
	var game := fixture()
	var wood: int = game.stock.wood
	var fiber: int = game.stock.fiber
	check(game.torches.request_craft(), "Recipe accepted")
	check(not game.torches.request_craft(), "One order per workshop")
	check(game.stock.wood == wood and game.torches.items.is_empty(), "Ordering does not consume or spawn remotely")
	for i in range(1600):
		advance(game, .05)
		var delivered: int = game.torches.orders[0].materials.wood
		var carried := 0
		for w in game.workers:
			if w.kind == "wood": carried += int(w.carrying)
		check(game.depots.total("wood") + carried + delivered == wood, "Wood conserved through physical pickup and delivery")
		if not game.torches.items.is_empty(): break
	check(game.torches.items.size() == 1 and game.stock.wood == wood - 2 and game.stock.fiber == fiber - 1, "Exactly one torch from the delivered recipe")
	check(game.torches.orders[0].work == 8, "Eight simulation seconds of assembly")
	advance(game, .1)
	equipped(game)
	var c: WorkerDelivery = game.workers[0].delivery
	game.selected = 2
	check(not game.assign_worker(0), "Torch holder cannot accept two-handed cargo")
	check(not game.torches.depart(0, game.Bridge.SCOUT_POINT), "Upper exploration rejected before ladder departure")
	game.torches.items[0].fuel = 2
	check(not game.torches.depart(0, Vector3(6, -.0105, -.5)), "Insufficient roundtrip fuel rejected")
	game.torches.items[0].fuel = 90
	check(game.torches.depart(0, Vector3(6, -.0105, -.5)), "Ground scouting route accepted")
	advance(game, 2)
	check(is_equal_approx(game.torches.items[0].fuel, 88), "Fuel burns in simulation seconds")
	var fuel: float = game.torches.items[0].fuel
	game.paused = true
	game._process(.25)
	check(game.torches.items[0].fuel == fuel, "Pause freezes fuel")
	game.paused = false
	game.speed = 3
	game._process(.5)
	check(is_equal_approx(game.torches.items[0].fuel, fuel - 1.5), "x3 uses the same simulation clock")
	game.paused = true
	game.torches.items[0].fuel = game.torches.travel_seconds(c, c.actor.position, game.HOME + game.Refuge.OUTSIDE) + 11.9
	advance(game, .05)
	check(game.torches.missions[0].phase == "return", "Safety margin triggers early return")
	recall(game)
	check(game.torches.items[0].fuel > 0 and game.torches.items[0].owner == -1 and not game.torches.items[0].lit, "Return stores the remaining fuel and frees both hands")
	var saved: Dictionary = game.Save.capture(game)
	check(game.Save.validate(saved).is_empty(), "v6 saves torch fuel")
	var invalid := saved.duplicate(true)
	invalid.torches.items[0].fuel = 91
	check(not game.Save.validate(invalid).is_empty(), "Corrupt fuel rejected")
	invalid = saved.duplicate(true)
	invalid.torches.items[0].pos = [9, 0, 9]
	check(not game.Save.validate(invalid).is_empty(), "Arbitrary torch storage rejected")
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.set_meta("restore_mode", true)
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(saved), "v6 roundtrip restores a settled refuge")
	check(restored.torches.items[0].fuel == game.torches.items[0].fuel, "Fuel restored exactly")
	restored.queue_free()
	await process_frame
	var legacy := saved.duplicate(true)
	legacy.version = 5
	legacy.erase("torches")
	check(game.Save.validate(legacy).is_empty(), "v5 remains supported")
	game.pending_save = false
	game._toggle_hide()
	advance(game, 8)
	equipped(game)
	game.torches.items[0].fuel = 90
	check(game.torches.depart(0, Vector3(6, -.0105, -.5)), "Second scout departure")
	advance(game, 2)
	game.workers[0].hydration = 34
	advance(game, .05)
	check(game.torches.missions[0].phase == "return", "Thirst recalls the scout before consumption")
	recall(game)
	game.queue_free()
	await process_frame
	# Recall during physical ingredient transport refunds once; delivered ingredients stay at workshop.
	game = fixture()
	wood = game.stock.wood
	game.torches.request_craft()
	for i in range(800):
		advance(game, .05)
		var carrying := false
		for w in game.workers: carrying = carrying or w.carrying > 0
		if carrying: break
	recall(game)
	check(game.stock.wood + game.torches.orders[0].materials.wood == wood, "Recall conserves workshop ingredients")
	saved = game.Save.capture(game)
	check(game.Save.validate(saved).is_empty(), "Partial recipe checkpoint validates")
	game.queue_free()
	await process_frame
	game = fixture()
	game.torches.add_item(game.depots.entry(0))
	game.torches.add_item(game.depots.entry(0))
	equipped(game, 0)
	equipped(game, 1)
	c = game.workers[0].delivery
	check(game.torches.depart(0, Vector3(6, -.0105, -.5)), "Blocked-route fixture departure")
	advance(game, 4)
	var before: Vector3 = c.actor.position
	var original: Array[Rect2] = game.navigation_obstacles.duplicate()
	game.navigation_obstacles.append(Rect2(2, -6.5, .5, 13))
	game.navigation.configure(game.navigation_obstacles, game.navigation_stands)
	advance(game, .1)
	check(game.torches.missions[0].phase == "return" and c.description().contains("bloqué"), "New obstruction triggers explained return block")
	check(c.actor.position.distance_to(before) < .001, "Blocked return never teleports")
	game.torches.items[0].fuel = .04
	advance(game, .1)
	check(game.torches.items[0].fuel == 0 and not game.torches.items[0].lit, "Burnout extinguishes actual light")
	game.navigation_obstacles = original
	game.navigation.configure(original, game.navigation_stands)
	advance(game, .1)
	check(c.actor.position.distance_to(before) < .001 and c.description().contains("éclaireur"), "No blind walking after burnout, assistance requested")
	check(game.torches.depart(1, before + Vector3(-.5, 0, .5)), "A second torch can assist")
	var moved := false
	for i in range(400):
		var previous: Vector3 = c.actor.position
		advance(game, .05)
		check(c.actor.position.distance_to(previous) <= .12, "Assisted return walks without teleport")
		if c.actor.position.distance_to(before) > .1:
			moved = true
			break
	check(moved, "Exhausted scout resumes under a nearby companion's light")
	game.torches.recall(game.workers[1].delivery)
	recall(game)
	check(c.inside_refuge, "Both scouts complete assisted return")
	game.queue_free()
	await process_frame
	game = fixture()
	game.torches.request_craft()
	for i in range(1400):
		advance(game, .05)
		if game.torches.orders[0].work > 2: break
	var progress: float = game.torches.orders[0].work
	check(progress > 0 and progress < 8, "Assembly interruption fixture reached")
	recall(game)
	check(game.torches.items.is_empty() and game.torches.orders[0].work == progress, "Recall pauses assembly without consuming twice")
	saved = game.Save.capture(game)
	restored = load("res://scenes/main.tscn").instantiate()
	restored.set_meta("restore_mode", true)
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(saved), "Partly assembled torch reloads")
	check(restored.torches.orders[0].work == progress, "Assembly progress persists")
	restored._toggle_hide()
	advance(restored, 40)
	check(restored.torches.items.size() == 1, "Resumed recipe produces exactly one torch")
	restored.queue_free()
	game.queue_free()
	await process_frame
	print("TORCHES_TEST failures=", failures)
	quit(1 if failures else 0)
