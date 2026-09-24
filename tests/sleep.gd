extends SceneTree
const Save = preload("res://scripts/colony_save.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func advance(game: Node, seconds: float) -> void:
	for i in range(int(seconds * 20)):
		game.simulate(.05)
		# Isolate needs and orders from the already tested famine/human event loop.
		game.suspicion = 0
		game.stock.food = 10000
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock = {"food": 10000, "wood": 100, "fiber": 100}
	game._choose_build("private_bed")
	check(game._place_build(Vector3(-3, 0, -4)), "Private sleeping alcove placed")
	check(game.stock.wood == 100 and game.stock.fiber == 100, "Placement keeps materials in depot until pickup")
	check(game.workers.size() == 4, "Furniture never creates an inhabitant")
	check(not game.sleeping.beds[0].built, "Placing an order does not instantly create a usable bed")
	advance(game, 80)
	check(game.sleeping.beds[0].built, "A resident reaches the site and finishes fabrication")
	check(game.stock.wood == 94 and game.stock.fiber == 95, "Completing fabrication does not charge twice")
	var c: WorkerDelivery = game.workers[0].delivery
	game.selected = 2
	check(game.assign_worker(0), "Sleep fixture worker assigned to wood")
	for i in range(1500):
		advance(game, .05)
		if game.workers[0].carrying > 0: break
	check(game.workers[0].carrying > 0, "Needs interrupt a real loaded delivery")
	var stock_before: int = game.stock.wood
	game.workers[0].energy = 20.0
	for i in range(1500):
		advance(game, .05)
		if c.state == "sleep": break
	check(c.state == "sleep", "Fatigued worker sleeps in their assigned bed")
	check(game.stock.wood > stock_before and c.job == -1 and game.workers[0].carrying == 0, "Loaded cargo deposited before sleeping")
	check(game.workers[0].patch == 2, "Work assignment preserved during rest")
	check(not game.sleeping.assign(0, 1), "Cannot reassign an occupied bed")
	var before: float = game.workers[0].energy
	advance(game, 5)
	check(game.workers[0].energy >= before + 14.9, "Private alcove restores energy at expected rate")
	check(game.workers[0].privacy == 100 and game.workers[0].comfort == 85, "Individual partitions provide privacy and comfort")
	advance(game, 45)
	check(c.rest_bed == -1 and c.completed_deliveries >= 2, "Worker gets up and resumes original deliveries")
	# Wake-up during a global recall must finish its animation and release the bed.
	game.sleeping.request_rest(0)
	for i in range(1200):
		advance(game, .05)
		if c.state == "sleep": break
	game._toggle_hide()
	advance(game, 40)
	check(c.inside_refuge and game.sleeping.beds[0].occupant == -1, "Recall wakes and safely returns a sleeper")
	check(c.actor.rotation.x == 0, "Lying pose does not corrupt actor navigation transform")
	# Ground fallback has worse recovery and does not steal a personal bed.
	game.workers[1].energy = 10.0
	advance(game, 5)
	check(game.workers[1].delivery.state == "floor_sleep", "A resident without a bed rests at the refuge")
	before = game.workers[1].energy
	advance(game, 5)
	check(absf(game.workers[1].energy - before - 3.0) < .01 and game.workers[1].comfort == 15, "Ground recovery is slow and uncomfortable")
	# Saved needs, ownership and partial fabrication survive a checkpoint.
	game._choose_build("bed")
	check(game._place_build(Vector3(0, 0, -3)), "Second bed order is reachable")
	game.sleeping.beds[1].work = 3.5
	game.sleeping.beds[1].materials = {"wood": 4, "fiber": 3}
	game.stock.wood -= 4
	game.stock.fiber -= 3
	game.pending_save = true
	advance(game, 2)
	check(game.checkpoint_ready(), "Checkpoint interrupts floor sleep without deadlocking")
	var snapshot := Save.capture(game)
	check(Save.validate(snapshot).is_empty(), "Version 2 snapshot validates")
	var candidate = load("res://scenes/main.tscn").instantiate()
	candidate.set_meta("restore_mode", true)
	root.add_child(candidate)
	candidate.set_process(false)
	check(candidate.apply_checkpoint(snapshot), "Snapshot restores with beds and needs")
	check(candidate.sleeping.snapshot() == game.sleeping.snapshot(), "Ownership and construction progress preserved")
	check(candidate.workers[0].energy == game.workers[0].energy, "Energy survives save/load")
	var invalid: Dictionary = snapshot.duplicate(true)
	invalid.furnishings[1].owner = invalid.furnishings[0].owner
	check(not Save.validate(invalid).is_empty(), "Duplicate personal ownership is rejected")
	invalid = snapshot.duplicate(true)
	invalid.needs[0].energy = -1
	check(not Save.validate(invalid).is_empty(), "Invalid energy rejected")
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy.version = 1
	legacy.patches.resize(7)
	legacy.stock.erase("water")
	legacy.erase("needs")
	legacy.erase("furnishings")
	legacy.buildings = []
	check(Save.validate(legacy).is_empty(), "Original v1 format remains supported")
	var old_game = load("res://scenes/main.tscn").instantiate()
	root.add_child(old_game)
	old_game.set_process(false)
	check(old_game.apply_checkpoint(legacy) and old_game.workers[0].energy == 100, "Old saves receive initialized needs")
	var wood: int = candidate.stock.wood
	check(candidate.sleeping.cancel_order(1), "Unfinished order can be cancelled")
	check(candidate.stock.wood == wood and candidate.sleeping.beds.size() == 1 and candidate.construction.recovery[0].materials.wood == 4, "Cancellation leaves physical materials for recovery")
	check(not candidate.sleeping.cancel_order(0), "Completed furniture cannot be refunded as an order")
	# A need appearing during the upper-zone delivery must not steal an access lock.
	candidate.pending_save = false
	candidate.discover_east()
	candidate.workers[0].energy = 100.0
	candidate.workers[0].sleep_requested = false
	candidate.workers[0].patch = 6
	candidate._toggle_hide()
	var crossing: WorkerDelivery = candidate.workers[0].delivery
	for i in range(2400):
		advance(candidate, .05)
		if crossing.bridge_active and candidate.workers[0].carrying > 0: break
	check(crossing.bridge_active and candidate.workers[0].carrying > 0, "Fatigue fixture reaches a loaded bridge crossing")
	candidate.workers[0].energy = 10.0
	for i in range(2400):
		advance(candidate, .05)
		if crossing.state == "sleep": break
	check(crossing.state == "sleep" and crossing.job == -1, "Fatigue during bridge crossing settles the cargo then reaches a bed")
	check(candidate.bridge.owner == -1 and candidate.ladder.owner == -1, "Sleep leaves no abandoned bridge or ladder lock")
	# Cancel a live worker's unfinished furniture job, not just serialized progress.
	old_game._toggle_hide()
	old_game._choose_build("private_bed")
	check(old_game._place_build(Vector3(-3, 0, -4)), "Live cancellation fixture placed")
	for i in range(2200):
		advance(old_game, .05)
		if old_game.sleeping.beds[0].work > 1: break
	check(old_game.sleeping.beds[0].work > 1, "Actual builder has started construction")
	check(old_game.sleeping.cancel_order(0), "A working builder can have their order cancelled")
	advance(old_game, 1)
	for worker in old_game.workers:
		check(worker.delivery.furniture_order == -1, "Cancelled construction releases every builder reference")
	game.queue_free()
	candidate.queue_free()
	old_game.queue_free()
	await process_frame
	print("SLEEP: %d failure(s)" % failures)
	quit(1 if failures else 0)
