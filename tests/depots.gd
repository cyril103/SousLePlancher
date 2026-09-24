extends SceneTree
const Save = preload("res://scripts/colony_save.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func fixture() -> Node:
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_meta("restore_mode", true)
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game._choose_build("depot")
	check(game._place_build(Vector3(4, 0, 2)), "Local depot placed at accessible site")
	return game
func advance(game: Node, seconds: float) -> void:
	for i in range(roundi(seconds * 20)):
		game.simulate(.05)
		game.suspicion = 0
func conserved(game: Node, kind: String) -> int:
	var amount: int = game.depots.total(kind)
	for patch in game.patches:
		if patch.kind == kind: amount += patch.amount
	for worker in game.workers:
		if worker.kind == kind: amount += worker.carrying
	for bed in game.sleeping.beds: amount += bed.materials.get(kind, 0)
	for pile in game.construction.recovery: amount += pile.materials.get(kind, 0)
	return amount
func recall(game: Node) -> void:
	game.pending_save = true
	if not game.hiding: game._toggle_hide()
	for i in range(2400):
		advance(game, .05)
		if game.checkpoint_ready(): return
	check(false, "Recall reaches a stable save with every depot lock released")
func run() -> void:
	var game := fixture()
	game.depots.sites[0].capacity = game.depots.used(0)
	game.depots.sites[1].filters = ["wood"]
	game.workers[0].patch = 2
	game.workers[1].patch = 3
	var initial := conserved(game, "wood")
	var limited := true
	var conserved_all := true
	for i in range(3000):
		advance(game, .05)
		limited = limited and game.depots.used(1) + game.depots.booked(1) <= 12
		conserved_all = conserved_all and conserved(game, "wood") == initial
	check(limited and conserved_all, "Competing carriers never overfill or duplicate stock")
	check(game.depots.stocks(1).wood == 12, "Two harvesters fill the local depot")
	check(game.stock.wood == 12, "Local harvest does not teleport into refuge inventory")
	check(game.workers[0].delivery.job == -1 and game.workers[1].delivery.job == -1, "Full destinations prevent new collection")
	check(game.workers[0].delivery.description().contains("place"), "Full depot explains why work stops")
	recall(game)
	var snapshot := Save.capture(game)
	check(Save.validate(snapshot).is_empty(), "v5 local inventories validate")
	var restored = load("res://scenes/main.tscn").instantiate()
	restored.set_meta("restore_mode", true)
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(snapshot), "Depots restore with their building positions")
	check(restored.depots.snapshot() == game.depots.snapshot(), "Stocks, filters and capacities survive reload")
	var invalid := snapshot.duplicate(true)
	invalid.depots[1].stock.wood = 13
	check(not Save.validate(invalid).is_empty(), "Overcapacity save rejected")
	invalid = snapshot.duplicate(true)
	invalid.depots[1].filters = ["wood", "wood"]
	check(not Save.validate(invalid).is_empty(), "Duplicate filter rejected")
	# A changed filter affects future trips, never deletes a booked incoming load.
	var filter_game := fixture()
	filter_game.workers[0].patch = 2
	var c: WorkerDelivery = filter_game.workers[0].delivery
	for i in range(800):
		advance(filter_game, .05)
		if c.worker.carrying > 0: break
	check(c.depot_id == 1 and c.worker.carrying > 0, "Nearest accessible depot selected before pickup")
	filter_game.depots.set_filter(1, "wood", false)
	filter_game._toggle_hide()
	advance(filter_game, 60)
	check(filter_game.depots.stocks(1).wood == 3, "Already booked load arrives after filter change and recall")
	check(filter_game.depots.settled(), "Recall frees all local reservations")
	# Physical construction supply from a local stock while the refuge has none.
	var building := fixture()
	building.stock.wood = 0
	building.stock.fiber = 0
	building.depots.stocks(1).wood = 4
	building.depots.stocks(1).fiber = 3
	building._choose_build("bed")
	check(building._place_build(Vector3(0, 0, -3)), "Bed supplied from remote stock placed")
	var local_source := false
	for i in range(2400):
		advance(building, .05)
		for task in building.construction.jobs.values():
			if task.depot == 1 and task.source.is_empty(): local_source = true
		if building.sleeping.ready_count() == 1: break
	check(local_source and building.sleeping.ready_count() == 1, "Local materials physically reach and complete the bed")
	check(building.stock.wood == 0 and building.depots.stocks(1).wood == 0, "Construction withdraws only its actual source")
	# Food and water are consumed at the local depot, not remotely from the refuge.
	var needs := fixture()
	needs.stock.food = 0
	needs.stock.water = 0
	needs.depots.stocks(1).food = 2
	needs.depots.stocks(1).water = 2
	var eater: WorkerDelivery = needs.workers[0].delivery
	eater.actor.position = Vector3(3, -.0105, 3.6)
	eater.worker.nutrition = 10.0
	eater.worker.hydration = 20.0
	var ate_local := false
	var drank_local := false
	for i in range(1000):
		advance(needs, .05)
		if eater.state == "eat" and eater.need_depot == 1: ate_local = true
		if eater.state == "drink" and eater.need_depot == 1: drank_local = true
		if ate_local and drank_local and eater.state == "idle": break
	check(ate_local and drank_local, "Hungry and thirsty resident reaches local food and water")
	check(needs.depots.stocks(1).food == 1 and needs.depots.stocks(1).water == 1, "Each local ration consumed once")
	check(needs.stock.food == 0 and needs.stock.water == 0 and needs.depots.settled(), "No remote consumption or abandoned eating reservation")
	eater.worker.nutrition = 5.0
	for i in range(500):
		advance(needs, .05)
		if eater.state == "eat": break
	check(eater.state == "eat", "Recall fixture is actually eating outside refuge")
	recall(needs)
	check(eater.inside_refuge and eater.state == "idle" and needs.depots.settled(), "Recall during a local meal finishes the ration and returns for checkpoint")
	# Do not let a forbidden food delivery prevent satisfying thirst from local water.
	needs.pending_save = false
	needs._toggle_hide()
	needs.depots.sites[0].filters = []
	needs.depots.sites[1].filters = ["water"]
	eater.worker.nutrition = 5.0
	eater.worker.hydration = 10.0
	for i in range(1000):
		advance(needs, .05)
		if eater.state == "drink": break
	check(eater.state == "drink" and eater.need_depot == 1, "Unavailable food storage does not block a local drink")
	# A blocked reserved destination is replaced by another reachable depot.
	var rerouted := fixture()
	rerouted.workers[0].patch = 2
	var carrier: WorkerDelivery = rerouted.workers[0].delivery
	for i in range(800):
		advance(rerouted, .05)
		if carrier.worker.carrying > 0: break
	var obstacles: Array[Rect2] = rerouted.navigation_obstacles.duplicate()
	obstacles.append(rerouted.Navigation.footprint(rerouted.depots.entry(1), Vector2(.3, .3)))
	rerouted.navigation.configure(obstacles, rerouted.navigation_stands)
	rerouted._toggle_hide()
	advance(rerouted, 70)
	check(rerouted.stock.wood == 15 and rerouted.depots.stocks(1).wood == 0, "Blocked local arrival reroutes physical cargo to refuge")
	check(rerouted.depots.settled(), "Reroute leaves no reservation at blocked depot")
	var returning := fixture()
	returning.stock.wood = 0
	returning.stock.fiber = 0
	returning.depots.stocks(1).wood = 9
	returning.depots.stocks(1).fiber = 3
	returning._choose_build("bed")
	check(returning._place_build(Vector3(0, 0, -3)), "Cancellation return-space fixture placed")
	var loaded := false
	for i in range(800):
		advance(returning, .05)
		for worker in returning.workers:
			if worker.delivery.supply_job >= 0 and worker.carrying > 0: loaded = true
		if loaded: break
	check(loaded and returning.depots.free_space(1) == 0, "Material withdrawal keeps capacity for possible return")
	returning.sleeping.cancel_order(0)
	advance(returning, 60)
	check(returning.depots.used(1) == 12 and returning.depots.settled(), "Cancelled load returns even when the source depot was full")
	# Filter widgets target the selected depot and the intended kind.
	returning.hud._refresh_depots()
	returning.hud.depot_picker.select(1)
	returning.hud.depot_filters.wood.toggled.emit(false)
	check(not "wood" in returning.depots.sites[1].filters and "fiber" in returning.depots.sites[1].filters and "wood" in returning.depots.sites[0].filters, "UI filter edits only selected local depot")
	# A legacy central inventory is migrated without truncating its existing stock.
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy.version = 4
	legacy.erase("depots")
	legacy.buildings = []
	legacy.stock.wood = 120
	var migrated = load("res://scenes/main.tscn").instantiate()
	migrated.set_meta("restore_mode", true)
	root.add_child(migrated)
	migrated.set_process(false)
	check(migrated.apply_checkpoint(legacy), "v4 central-stock checkpoint migrates")
	check(migrated.stock.wood == 120 and migrated.depots.sites[0].capacity >= migrated.depots.used(0), "Legacy stock preserved with sufficient refuge capacity")
	for item in [game, restored, filter_game, building, needs, rerouted, returning, migrated]: item.queue_free()
	await process_frame
	print("DEPOTS: %d failure(s)" % failures)
	quit(1 if failures else 0)
