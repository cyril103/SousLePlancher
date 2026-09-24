extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func advance(game: Node, seconds: float) -> void:
	for i in range(int(seconds * 20)): game.simulate(.05)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	game._add_worker()
	game._add_worker()
	for w in game.workers: check(not w.delivery.at_refuge(), "Standing outside is not sheltered")
	game._toggle_hide()
	var waiting_seen := false
	for i in range(900):
		game.simulate(.05)
		var crossings := 0
		for w in game.workers:
			var c: WorkerDelivery = w.delivery
			waiting_seen = waiting_seen or c.waiting_door
			if c.door_active:
				crossings += 1
				check(game.refuge.passage_owner == c.owner and game.refuge.opening >= 1, "Passage is reserved and door fully open")
		check(crossings <= 1, "Only one resident crosses at a time")
	check(waiting_seen, "Collective recall exercises door queue")
	for w in game.workers:
		check(w.delivery.at_refuge() and w.delivery.state == "idle", "All six residents settle inside")
		check(w.node.position.distance_to(game.refuge.slot(w.delivery.owner)) < .01, "Distinct interior place reached")
	check(game.refuge.opening == 0 and game.refuge.queue.is_empty() and game.refuge.passage_owner == -1, "Door closes and reservations clear")
	game.elapsed = 72
	game.suspicion = 0
	advance(game, 1)
	check(game.suspicion == 0, "Residents inside do not expose colony during human passage")
	# Unassigned residents also leave when the player presses Ressortir.
	game._toggle_hide()
	advance(game, 5)
	check(game.suspicion > 0, "Leaving refuge restores exposure, including nearby residents")
	advance(game, 40)
	for w in game.workers:
		check(not w.delivery.at_refuge() and w.delivery.state == "idle", "Ressortir also releases unassigned residents")
		check(w.node.position.distance_to(game.home_position(w.delivery.owner)) < .01, "Exit returns to exterior navigation")
	# Reverse the order during an actual crossing; it must finish safely first.
	game._toggle_hide()
	var c: WorkerDelivery = game.workers[0].delivery
	for i in range(200):
		game.simulate(.05)
		if c.door_active: break
	check(c.door_active, "Door crossing starts")
	var before := c.actor.position
	var angle: float = game.refuge.door.rotation.y
	game.paused = true
	game._process(.5)
	check(c.actor.position == before and game.refuge.door.rotation.y == angle, "Pause freezes door and resident")
	game._toggle_hide()
	check(c.door_active and c.actor.position == before, "Ressortir during entry does not teleport")
	advance(game, 45)
	check(not c.inside_refuge and not c.door_active, "Mid-entry order eventually exits")
	game._toggle_hide()
	advance(game, 40)
	game._toggle_hide()
	for i in range(200):
		game.simulate(.05)
		if c.door_active: break
	game._toggle_hide()
	advance(game, 45)
	check(c.inside_refuge and c.state == "idle", "Recall during exit safely returns inside")
	check(game.refuge.opening == 0 and game.refuge.queue.is_empty(), "Repeated reversals do not jam door")
	game._toggle_hide()
	advance(game, 40)
	game.selected = 2
	check(game.assign_worker(0), "Assignment after exit")
	for i in range(700):
		game.simulate(.05)
		if game.workers[0].carrying > 0: break
	var amount: int = game.workers[0].carrying
	var stock: int = game.stock.wood
	check(amount > 0, "Real cargo collected")
	game._toggle_hide()
	advance(game, 45)
	check(c.inside_refuge and game.stock.wood == stock + amount, "Recall unloads before entering, exactly once")
	check(game.delivery_ledger.jobs.is_empty(), "Recall leaves no abandoned delivery")
	game._toggle_hide()
	advance(game, 35)
	check(game.workers[0].patch == 2 and c.completed_deliveries > 1, "Exit resumes preserved assignment")
	game._choose_build("workshop")
	check(not game._valid_site(game.HOME + game.Refuge.OUTSIDE), "Construction preserves doorway")
	check(not game._navigation_allows_build(Vector3(-6, 0, -1), "shelter"), "Capacity checked before new inhabitant")
	game.free()
	print("DOORS: %d failure(s)" % failures)
	quit(failures)
