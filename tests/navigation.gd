extends SceneTree
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var nav := GroundNavigation.new()
	var boxes: Array[Rect2] = [Rect2(-1, -1, 2, 2)]
	nav.configure(boxes)
	var start := Vector3(-3, 0, 0)
	var end := Vector3(3, 0, 0)
	var route := nav.path(start, end)
	check(route.size() >= 3 and route[-1].is_equal_approx(end), "Route bends around obstacle and reaches exact destination")
	var previous := start
	for point in route:
		check(nav.segment_clear(previous, point), "Smoothed route never cuts a corner")
		previous = point
	check(nav.path(start, Vector3.ZERO).is_empty(), "Blocked endpoint is not silently snapped through an obstacle")
	boxes = [Rect2(-0.3, -6.5, 0.6, 13)]
	nav.configure(boxes)
	check(nav.path(start, end).is_empty(), "Separated regions have no partial/fake route")
	nav.configure([])
	check(nav.path(start, end).size() == 1, "Removing obstacle restores direct route")

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 1000
	var depot: Vector3 = game.workers[0].delivery.destination_position
	for slot in game.home_slots + game.depot_slots:
		check(not game.navigation.path(depot, slot).is_empty(), "All refuge and queue slots reachable from depot")
	for patch in game.patches:
		check(not game.travel_path(depot, patch.pos + Vector3(.9, WorkerDelivery.GROUND_Y, .2)).is_empty(), "Every collection station reachable")
	for i in range(4):
		game.selected = [0, 2, 4, 1][i]
		game.assign_worker()
	for i in range(900):
		var before: Array[Vector3] = []
		for worker in game.workers: before.append(worker.node.position)
		game.simulate(0.05)
		for j in range(game.workers.size()):
			check(game.navigation.segment_clear(before[j], game.workers[j].node.position), "Actual movement respects all obstacles")
	for worker in game.workers:
		check(worker.delivery.completed_deliveries >= 1, "Every assigned worker completes delivery without starvation at depot")
	game._toggle_hide()
	for i in range(700): game.simulate(0.05)
	for worker in game.workers:
		check(worker.delivery.at_refuge(), "Recall reaches assigned refuge place")
	check(game.delivery_ledger.jobs.is_empty() and game.delivery_ledger.destination_queue.is_empty(), "Recall cleans up jobs and FIFO queue")
	game._toggle_hide()
	# Let one resident reserve, then make its source inaccessible before grasp.
	for worker in game.workers: worker.patch = -1
	game.selected = 2
	game.assign_worker(0)
	game.simulate(0.05)
	var controller: WorkerDelivery = game.workers[0].delivery
	var source: Vector3 = controller.source_position
	var blocked: Array[Rect2] = game.navigation_obstacles.duplicate()
	blocked.append(GroundNavigation.footprint(source, Vector2(.1, .1)))
	game.navigation.configure(blocked, game.navigation_stands)
	game.simulate(.1)
	check(controller.job < 0 and game.patches[2].reserved == 0, "Blocked outbound route releases reservation before taking cargo")
	game.simulate(.1)
	check(controller.description().contains("bloqué"), "Unreachable work is explained in resident status")
	game.navigation.configure(game.navigation_obstacles, game.navigation_stands)
	for i in range(600):
		game.simulate(.05)
		if game.workers[0].carrying > 0: break
	check(game.workers[0].carrying > 0, "Restored access resumes task automatically")
	var quantity: int = game.workers[0].carrying
	var stock_before: int = game.stock.wood
	blocked = game.navigation_obstacles.duplicate()
	blocked.append(GroundNavigation.footprint(depot, Vector2(.1, .1)))
	game.navigation.configure(blocked, game.navigation_stands)
	for i in range(150): game.simulate(.05)
	check(game.workers[0].carrying == quantity and game.stock.wood == stock_before, "Blocked depot neither destroys cargo nor credits stock early")
	check(game.delivery_ledger.destination_owner == -1, "Unreachable depot is not held reserved")
	check(controller.description().contains("bloqué"), "Blocked depot reports its reason")
	game.navigation.configure(game.navigation_obstacles, game.navigation_stands)
	game._toggle_hide()
	for i in range(700): game.simulate(.05)
	check(game.stock.wood == stock_before + quantity and controller.at_refuge(), "Reopening depot finishes cargo and recall exactly once")
	game._choose_build("shelter")
	stock_before = game.stock.wood
	check(not game._place_build(game.home_slots[0]), "Construction cannot occupy refuge waiting slots")
	check(game.stock.wood == stock_before, "Rejected construction costs nothing")
	# Sealing the last connection is rejected even without overlapping a station.
	game.navigation_obstacles.append(Rect2(-.1, -6.5, .2, 5.5))
	game.navigation_obstacles.append(Rect2(-.1, 1.0, .2, 5.5))
	game.navigation.configure(game.navigation_obstacles, game.navigation_stands)
	check(not game.navigation.path(depot, game.patches[0].pos + Vector3(.9, 0, .2)).is_empty(), "Remaining connection is initially usable")
	check(not game._navigation_allows_build(Vector3.ZERO, "workshop"), "Building cannot seal last connection to resources")
	await process_frame
	game.free()
	var ledger := DeliveryLedger.new()
	ledger.patches = [{"kind": "wood", "amount": 9, "reserved": 0}, {"kind": "wood", "amount": 9, "reserved": 0}, {"kind": "wood", "amount": 9, "reserved": 0}]
	var ids: Array[int] = []
	for i in range(3):
		ids.append(ledger.reserve(i, i, 3))
		ledger.collect(ids[i])
	check(ledger.acquire_destination(ids[0]), "First carrier owns depot")
	ledger.acquire_destination(ids[2])
	ledger.acquire_destination(ids[1])
	ledger.deliver(ids[0], {"wood": 0})
	ledger.release_destination(ids[0])
	check(not ledger.acquire_destination(ids[1]) and ledger.acquire_destination(ids[2]), "FIFO follows arrival order, not worker index")
	print("NAVIGATION: %d failure(s)" % failures)
	quit(failures)
