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
		game.suspicion = 0 # Human detection is covered by smoke; isolate needs here.
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	advance(game, 20)
	check(game.stock.food == 24 and game.stock.water == 16, "No global meal silently removes stock")
	check(game.workers[0].nutrition < 100 and game.workers[0].hydration < game.workers[0].nutrition, "Independent needs decay at different rates")
	var c: WorkerDelivery = game.workers[0].delivery
	c.inside_refuge = true
	c.actor.position = game.refuge.slot(0)
	game.workers[0].patch = 2
	game.workers[0].nutrition = 10.0
	game.workers[0].hydration = 20.0
	game.stock.food = 1
	game.stock.water = 1
	advance(game, .05)
	check(c.state == "eat" and game.stock.food == 0 and game.stock.water == 1, "Most urgent need wins and withdraws exactly one ration")
	game._toggle_hide()
	advance(game, 4)
	check(game.workers[0].nutrition > 63 and game.stock.food == 0, "Recall neither duplicates nor discards an ongoing meal")
	advance(game, 4)
	check(game.workers[0].hydration > 80 and game.stock.water == 0, "Resident drinks autonomously after eating")
	check(game.workers[0].patch == 2, "Personal needs preserve the player assignment")
	# Autonomous replenishment from an accessible source, with no gather order.
	game._toggle_hide()
	game.workers[0].nutrition = 10.0
	game.workers[0].hydration = 100.0
	game.workers[0].energy = 100.0
	for i in range(2400):
		advance(game, .05)
		if c.state == "eat": break
	check(c.state == "eat" and c.completed_deliveries > 0, "Empty food reserve triggers automatic collection, delivery and eating")
	check(game.workers[0].patch == 2 and c.needs_supply == -1, "Emergency source does not overwrite the original work assignment")
	advance(game, 5)
	var completed := c.completed_deliveries
	game.workers[0].hydration = 10.0
	for i in range(2400):
		advance(game, .05)
		if c.state == "drink": break
	check(c.state == "drink" and c.completed_deliveries > completed and game.patches[7].amount < 120 + 30 * int(game.elapsed / 100), "Water can be collected and drunk through the real delivery pipeline")
	advance(game, 4)
	# Low energy must decide to sleep without a UI request.
	game.workers[1].energy = 20.0
	for i in range(1200):
		advance(game, .05)
		if game.workers[1].delivery.state == "floor_sleep": break
	check(game.workers[1].delivery.state == "floor_sleep", "No bed: an exhausted resident autonomously sleeps on the floor")
	game.workers[1].hydration = 5.0
	game.stock.water = 3
	for i in range(300):
		advance(game, .05)
		if game.workers[1].delivery.state == "drink": break
	check(game.workers[1].delivery.state == "drink", "Critical thirst wakes a floor sleeper")
	advance(game, 4)
	# Pause freezes all needs, not just the visible animations.
	game.paused = true
	var before: float = game.workers[0].hydration
	game._process(1)
	check(game.workers[0].hydration == before, "Pause freezes needs")
	# Save/load supports the water resource, its assignment and individual meters.
	game.workers[0].patch = 7
	game.pending_save = true
	if not game.hiding: game._toggle_hide()
	for i in range(2000):
		advance(game, .05)
		if game.checkpoint_ready(): break
	check(game.checkpoint_ready(), "Checkpoint settles meals, deliveries and sleepers")
	var data := Save.capture(game)
	check(Save.validate(data).is_empty(), "Current needs snapshot validates")
	var copy = load("res://scenes/main.tscn").instantiate()
	copy.set_meta("restore_mode", true)
	root.add_child(copy)
	copy.set_process(false)
	check(copy.apply_checkpoint(data), "Needs snapshot restores")
	check(copy.workers[0].nutrition == game.workers[0].nutrition and copy.workers[0].hydration == game.workers[0].hydration, "Individual food/water meters restored exactly")
	check(copy.stock.water == game.stock.water and copy.workers[0].patch == 7, "Water stock and assignment persist")
	var bad: Dictionary = data.duplicate(true)
	bad.needs[0].hydration = -2
	check(not Save.validate(bad).is_empty(), "Invalid needs are rejected")
	var legacy: Dictionary = data.duplicate(true)
	legacy.version = 2
	legacy.patches.resize(7)
	legacy.stock.erase("water")
	legacy.assignments[0] = -1
	for need in legacy.needs:
		need.erase("nutrition")
		need.erase("hydration")
	check(Save.validate(legacy).is_empty(), "Version 2 remains readable without thirst data")
	legacy.buildings.append({"kind": "workshop", "pos": [7, 0, 2]})
	var migrated = load("res://scenes/main.tscn").instantiate()
	root.add_child(migrated)
	migrated.set_process(false)
	check(migrated.apply_checkpoint(legacy), "Old building at the added water source survives migration")
	check(migrated.patches[7].pos != Vector3(7, 0, 2) and migrated.workshops == 1, "Only the new water source moves; old buildings are preserved")
	check(not migrated.travel_path(migrated.home_position(0), migrated.patches[7].pos + Vector3(.9, 0, .2), 0).is_empty(), "Migrated source remains reachable")
	var migrated_data := Save.capture(migrated)
	var restored = load("res://scenes/main.tscn").instantiate()
	root.add_child(restored)
	restored.set_process(false)
	check(restored.apply_checkpoint(migrated_data) and restored.patches[7].pos == migrated.patches[7].pos, "Relocated water source persists in subsequent saves")
	# An unavailable most-urgent resource must not prevent satisfying another need.
	restored.stock.food = 2
	restored.stock.water = 0
	restored.workers[0].nutrition = 10.0
	restored.workers[0].hydration = 0.0
	advance(restored, .05)
	check(restored.workers[0].delivery.state == "eat", "Empty water while hiding does not prevent an available meal")
	advance(restored, 4.1)
	restored.stock.water = 1
	advance(restored, .05)
	check(restored.workers[0].delivery.state == "drink", "Newly available water resolves an already pending need")
	# A sleeping resident wakes for a critical vital need without losing bed ownership.
	copy._choose_build("private_bed")
	check(copy._place_build(Vector3(-3, 0, -4)), "Bed wake-up fixture placed")
	copy.pending_save = false
	copy.depots.sites[0].capacity = 1000 # Keep this fixture focused on waking for hunger.
	copy.stock.food = 100
	copy.stock.water = 100
	for worker in copy.workers:
		worker.nutrition = 100.0
		worker.hydration = 100.0
		worker.energy = 100.0
		worker.sleep_requested = false
		worker.patch = -1
	copy._toggle_hide()
	advance(copy, 80)
	copy.workers[0].energy = 20.0
	for i in range(1000):
		advance(copy, .05)
		if copy.workers[0].delivery.state == "sleep": break
	check(copy.workers[0].delivery.state == "sleep", "Bed fixture sleeps autonomously")
	copy.workers[0].nutrition = 5.0
	for i in range(1000):
		advance(copy, .05)
		if copy.workers[0].delivery.state == "eat": break
	check(copy.workers[0].delivery.state == "eat" and copy.sleeping.beds[0].occupant == -1, "Critical hunger wakes a bed sleeper and releases occupancy")
	check(copy.sleeping.beds[0].owner == 0, "Getting up to eat preserves personal ownership")
	game.queue_free()
	copy.queue_free()
	migrated.queue_free()
	restored.queue_free()
	await process_frame
	print("NEEDS: %d failure(s)" % failures)
	quit(1 if failures else 0)
