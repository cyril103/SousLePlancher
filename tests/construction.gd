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
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock = {"food": 200, "water": 200, "wood": 7, "fiber": 3}
	game.save_path = "res://artifacts/construction/checkpoint.json"
	return game

func advance(game: Node, seconds: float) -> void:
	for i in range(roundi(seconds * 20)):
		game.simulate(.05)
		game.suspicion = 0

func total(game: Node, kind: String) -> int:
	var amount: int = game.stock[kind]
	for bed in game.sleeping.beds: amount += int(bed.materials[kind])
	for pile in game.construction.recovery: amount += int(pile.materials[kind])
	for worker in game.workers:
		if worker.kind == kind: amount += worker.carrying
	return amount

func place(game: Node, pos: Vector3, kind: String = "bed") -> void:
	game._choose_build(kind)
	check(game._place_build(pos), "Reachable site accepted")

func settled(game: Node) -> void:
	if not game.hiding: game._toggle_hide()
	game.pending_save = true
	for i in range(2400):
		advance(game, .05)
		if game.checkpoint_ready(): return
	check(false, "Recall settles construction loads and access locks")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/construction")
	var game := fixture()
	place(game, Vector3(-3, 0, -4))
	place(game, Vector3(0, 0, -3), "private_bed")
	check(game.stock.wood == 7 and game.stock.fiber == 3, "Placement does not withdraw material")
	advance(game, .05)
	check(game.construction.reserved("wood") <= 7, "Competing orders cannot overreserve")
	var saw_load := false
	var saw_work := false
	for i in range(1800):
		advance(game, .05)
		for worker in game.workers:
			if worker.delivery.supply_job >= 0 and worker.carrying > 0: saw_load = true
		for bed in game.sleeping.beds:
			if bed.work > 0:
				saw_work = true
				check(game.construction.supplied(bed), "Work requires every material delivered")
		check(total(game, "wood") == 7 and total(game, "fiber") == 3, "Resources conserved at every simulation step")
	check(saw_load and saw_work, "Actual pickup, transport and fabrication occur")
	check(game.sleeping.beds[0].built and not game.sleeping.beds[1].built, "Limited materials finish one bed, not both")
	check(game.construction.status(game.sleeping.beds[1]) == "Matériaux manquants", "Missing material explained")
	settled(game)
	var snap := Save.capture(game)
	check(Save.validate(snap).is_empty(), "Partial site checkpoint validates")
	var restored := fixture()
	check(restored.apply_checkpoint(snap), "Partial site loads")
	check(restored.sleeping.snapshot() == game.sleeping.snapshot(), "Site stock and work survive reload")
	check(total(restored, "wood") == 7 and total(restored, "fiber") == 3, "Load does not pay again")
	var before: int = restored.stock.wood
	check(restored.sleeping.cancel_order(1), "Cancel partially supplied site")
	check(restored.stock.wood == before and restored.construction.recovery.size() == 1, "Delivered material stays on the ground")
	check(not restored.sleeping.cancel_order(1), "Cannot refund twice")
	var recovery_snap := Save.capture(restored)
	check(Save.validate(recovery_snap).is_empty(), "Recovery pile persists")
	var recovered := fixture()
	check(recovered.apply_checkpoint(recovery_snap), "Recovery pile loads")
	recovered.pending_save = false
	recovered._toggle_hide()
	advance(recovered, 70)
	check(recovered.construction.recovery.is_empty() and recovered.stock.wood == 3, "Recovery physically returns spare timber")
	check(total(recovered, "wood") == 7, "Recovered material conserved")
	var invalid := snap.duplicate(true)
	invalid.furnishings[0].materials.wood = 0
	check(not Save.validate(invalid).is_empty(), "Reject work without materials")
	invalid = snap.duplicate(true)
	invalid.furnishings[1].materials.fiber = -1
	check(not Save.validate(invalid).is_empty(), "Reject negative site stock")
	var legacy := snap.duplicate(true)
	legacy.version = 3
	legacy.erase("recovery")
	for bed in legacy.furnishings: bed.erase("materials")
	var old := fixture()
	check(old.apply_checkpoint(legacy), "v3 migrates")
	check(old.construction.supplied(old.sleeping.beds[1]) and old.stock == legacy.stock, "Paid old site migrates without another withdrawal")
	# A shortfall is recoverable through ordinary harvesting, sharing the same depot queue.
	game.pending_save = false
	game._toggle_hide()
	game.workers[2].patch = 2
	game.workers[3].patch = 4
	for i in range(4400):
		advance(game, .05)
		if game.sleeping.ready_count() == 2: break
	check(game.sleeping.ready_count() == 2, "Harvest replenishment unblocks the second real chantier")
	for phase in ["reserved", "loaded", "deposited", "working"]:
		var trial := fixture()
		trial.stock.wood = 20
		trial.stock.fiber = 20
		place(trial, Vector3(-3, 0, -4))
		var reached := false
		for i in range(2200):
			advance(trial, .05)
			for job in trial.construction.jobs.values():
				if phase == "reserved" and not job.collected: reached = true
				if phase == "loaded" and job.collected and not job.deposited: reached = true
				if phase == "deposited" and job.deposited: reached = true
			if phase == "working" and trial.sleeping.beds[0].work > 1: reached = true
			if reached: break
		check(reached, "Cancellation phase " + phase)
		trial.sleeping.cancel_order(0)
		check(total(trial, "wood") == 20 and total(trial, "fiber") == 20, "Cancellation conserves " + phase)
		advance(trial, 100)
		check(trial.stock.wood == 20 and trial.stock.fiber == 20 and trial.construction.jobs.is_empty(), "Recovery completed " + phase)
		trial.queue_free()
	var hungry := fixture()
	place(hungry, Vector3(-3, 0, -4))
	var carrier: WorkerDelivery
	for i in range(800):
		advance(hungry, .05)
		for worker in hungry.workers:
			if worker.carrying > 0 and worker.delivery.supply_job >= 0: carrier = worker.delivery
		if carrier != null: break
	check(carrier != null, "Need fixture has material carrier")
	if carrier != null:
		carrier.worker.nutrition = 10.0
		var ate := false
		for i in range(1600):
			advance(hungry, .05)
			if carrier.state == "eat":
				ate = true
				break
		check(ate and carrier.worker.carrying == 0, "Urgent hunger returns material before eating")
		check(total(hungry, "wood") == 7, "Need interruption conserves material")
	settled(hungry)
	check(hungry.construction.jobs.is_empty() and hungry.delivery_ledger.destination_owner == -1, "Recall releases shared depot")
	for item in [game, restored, recovered, old, hungry]: item.queue_free()
	await process_frame
	print("CONSTRUCTION: %d failure(s)" % failures)
	quit(1 if failures else 0)
