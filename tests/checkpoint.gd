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
		game._try_checkpoint()
		if not game.pending_save and game.paused: break
func wood_total(game: Node) -> int:
	var total: int = game.stock.wood
	for patch in game.patches:
		if patch.kind == "wood": total += patch.amount
	for worker in game.workers:
		if worker.kind == "wood": total += worker.carrying
	return total
func run() -> void:
	var path := "user://tests/checkpoint_%d/colony.json" % Time.get_ticks_usec()
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = path
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.paused = false
	game.stock = {"food": 10000, "wood": 100, "fiber": 100}
	game._choose_build("shelter")
	check(game._place_build(Vector3(0, 0, -3)), "Fixture shelter built")
	game._choose_build("workshop")
	check(game._place_build(Vector3(-3, 0, -3)), "Fixture workshop built")
	game.discover_east()
	game.speed = 2
	game.focus = Vector3(3, 0, -2)
	game.hud.resident_index = 4
	for i in range(5):
		game.selected = [6,3,2,4,0][i]
		game.assign_worker(i)
	var total := wood_total(game)
	var c: WorkerDelivery = game.workers[0].delivery
	for i in range(2000):
		game.simulate(.05)
		if c.bridge_active and game.workers[0].carrying > 0: break
	check(c.bridge_active and game.workers[0].carrying > 0, "Save requested during loaded bridge crossing")
	check(game.request_checkpoint(), "Checkpoint request accepted")
	check(game.pending_save and not FileAccess.file_exists(path), "No partial snapshot during transit")
	check(not game.request_checkpoint(), "Duplicate request ignored")
	advance(game, 100)
	check(not game.pending_save and game.paused and game.checkpoint_ready(), "Checkpoint waits for all residents, cargo and passage closure")
	check(wood_total(game) == total, "Recall conserves wood across active transports")
	var result := Save.read_checkpoint(path)
	check(result.ok and not result.backup, "Versioned checkpoint written and readable")
	if not result.ok:
		game.free()
		quit(1)
		return
	var snapshot: Dictionary = result.data
	check(snapshot.assignments.size() == 5 and snapshot.patches[6].discovered, "Population, assignments and discovery captured")
	game.hud.ask_load()
	check(game.hud.load_panel.visible and game.paused, "Active-game load asks before replacing progress")
	game.hud.cancel_load()
	check(not game.hud.load_panel.visible and game.paused, "Cancelling load preserves previous pause")
	var restored = game.load_checkpoint()
	check(restored != null, "Fresh candidate restored successfully")
	if restored == null:
		game.free()
		quit(1)
		return
	game = restored
	game.set_process(false)
	await process_frame
	check(game.paused and game.hiding and game.checkpoint_ready(), "Load resumes paused and fully sheltered")
	check(game.shelters == 1 and game.workshops == 1 and game.workers.size() == 5, "Buildings restore without charging or recruiting twice")
	check(game.east_discovered and game.patches[6].node.visible and game.east_stand.visible, "Explored zone and resource visibility persist")
	var recaptured := Save.capture(game)
	for key in ["stock", "patches", "assignments", "clock", "view", "speed", "buildings"]:
		check(JSON.parse_string(JSON.stringify(recaptured[key])) == snapshot[key], "Exact checkpoint field restored: " + key)
	check(wood_total(game) == total, "No cargo duplicated or lost on load")
	game._toggle_hide()
	game.paused = false
	advance(game, 60)
	check(game.workers[0].patch == 6 and game.workers[0].delivery.completed_deliveries > 0, "Restored remote assignment crosses links and delivers")
	check(wood_total(game) == total, "Resources remain conserved after resumed work")
	# A failed replacement must leave the existing primary file untouched.
	var changed := snapshot.duplicate(true)
	changed.stock.wood += 5
	DirAccess.make_dir_recursive_absolute(path + ".bak.tmp")
	check(not Save.write_checkpoint(path, changed).is_empty(), "Backup write failure is reported")
	check(Save.read_file(path).data.stock.wood == snapshot.stock.wood, "Failed write preserves primary checkpoint")
	DirAccess.remove_absolute(path + ".bak.tmp") # Test-owned empty directory only.
	check(Save.write_checkpoint(path, changed).is_empty(), "Second checkpoint replaces primary")
	check(Save.read_file(path + ".bak").data.stock.wood == snapshot.stock.wood, "Previous checkpoint retained as backup")
	Save.write_text(path, "{interrupted")
	var fallback := Save.read_checkpoint(path)
	check(fallback.ok and fallback.backup and fallback.data.stock.wood == snapshot.stock.wood, "Corrupt primary recovers validated backup")
	# Bad data never deserializes game objects or changes the current scene.
	var invalid := snapshot.duplicate(true)
	invalid.assignments[0] = 99
	check(not Save.validate(invalid).is_empty(), "Invalid assignments rejected")
	invalid = snapshot.duplicate(true)
	invalid.version = 999
	check(not Save.validate(invalid).is_empty(), "Unknown format version rejected")
	invalid = snapshot.duplicate(true)
	invalid.stock.wood = -1
	check(not Save.validate(invalid).is_empty(), "Negative inventory rejected")
	invalid = snapshot.duplicate(true)
	invalid.buildings.append(invalid.buildings[1].duplicate(true))
	var invalid_path := path.get_base_dir() + "/overlap.json"
	check(Save.write_checkpoint(invalid_path, invalid).is_empty(), "Structural validation permits semantic reconstruction test")
	game.save_path = invalid_path
	var before := wood_total(game)
	check(game.load_checkpoint() == null and wood_total(game) == before and not game.is_queued_for_deletion(), "Overlapping buildings cannot replace active game")
	await process_frame
	game.save_path = path
	var backup_game = game.load_checkpoint()
	check(backup_game != null, "Backup can reconstruct a playable scene")
	if backup_game != null:
		game = backup_game
		game.set_process(false)
		await process_frame
		check(game.news_label.text.contains("secours"), "Fallback is disclosed to player")
	# Orders of exit and explicit cancellation must not silently overwrite a save.
	game._toggle_hide()
	game.paused = false
	advance(game, 1)
	game.request_checkpoint()
	game._toggle_hide()
	check(not game.pending_save, "Exit cancels pending checkpoint")
	game.request_checkpoint()
	game.cancel_checkpoint()
	check(not game.pending_save and game.hiding, "Explicit cancellation preserves recall but stops saving")
	game.free()
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = path.get_base_dir() + "/recruited_during_recall.json"
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.paused = false
	game.stock.food = 10000
	game.request_checkpoint()
	game._choose_build("shelter")
	check(game._place_build(Vector3(0, 0, -3)), "Recruit during pending checkpoint")
	advance(game, 60)
	check(not game.pending_save and game.checkpoint_ready() and game.workers.size() == 5, "New arrival joins recall and does not stall saving")
	game.free()
	print("CHECKPOINT: %d failure(s)" % failures)
	quit(failures)
