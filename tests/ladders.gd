extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	for i in range(4):
		game.selected = [3, 5, 0, 2][i]
		check(game.assign_worker(i), "Assignment accepted")
	var waiting_seen := false
	var loaded_seen := false
	for step in range(2200):
		var previous: Array[int] = []
		for w in game.workers: previous.append(w.delivery.crossings)
		game.simulate(.05)
		var climbers := 0
		for w in game.workers:
			var c: WorkerDelivery = w.delivery
			if c.crossings > previous[c.owner]:
				for side in ["L", "R"]:
					var ankle := c.actor.skeleton.get_bone_global_pose(c.actor.skeleton.find_bone(side + "_foot")).origin
					var sole := c.actor.skeleton.global_transform * (ankle - Vector3(0, .1195, 0))
					check(absf(sole.y - (2.04 if c.climb_up else 0.0)) < .003, "Both boots touch the floor at ladder exit")
			waiting_seen = waiting_seen or c.waiting_ladder
			if c.climbing:
				climbers += 1
				check(game.ladder.owner == c.owner, "Climber owns passage")
				if w.carrying > 0:
					loaded_seen = true
					check(game.delivery_ledger.destination_owner != c.job, "Ladder does not lock depot")
			elif w.node.position.y > 1:
				check(absf(w.node.position.y - 2.0295) < .002, "Upper walking preserves foot height")
		check(climbers <= 1, "No simultaneous opposing climbers")
	check(waiting_seen and loaded_seen, "Real traffic includes waiting and loaded descent")
	for w in game.workers: check(w.delivery.completed_deliveries > 0, "Every resident completes a delivery")
	game._toggle_hide()
	for step in range(1600): game.simulate(.05)
	for w in game.workers: check(w.delivery.at_refuge(), "Recall brings ground and upper workers home")
	check(game.ladder.owner == -1 and game.ladder.queue.is_empty(), "Recall releases passage and queue")
	check(game.delivery_ledger.jobs.is_empty(), "Recall leaves no abandoned cargo reservation")
	game._toggle_hide()
	var c: WorkerDelivery = game.workers[0].delivery
	for step in range(800):
		game.simulate(.05)
		if c.climbing: break
	check(c.climbing, "Restored assignments use ladder again")
	var before := c.actor.position
	game.paused = true
	game._process(.5)
	check(c.actor.position == before, "Pause freezes ladder animation and displacement")
	game.workers[0].patch = -1
	c.cancel()
	check(c.climbing and c.actor.position == before, "Mid-climb cancel does not teleport or reverse")
	game._toggle_hide()
	for step in range(1600): game.simulate(.05)
	check(c.at_refuge(), "Mid-climb cancellation safely finishes crossing and returns")
	check(game.ladder.owner == -1 and game.ladder.queue.is_empty(), "Cancellation cleans passage")
	check(not game._valid_site(Vector3(5, 0, -4)), "Construction cannot intersect platform")
	var passage = load("res://scripts/ladder_passage.gd").new()
	check(passage.request(2), "First arrival owns ladder")
	check(not passage.request(1) and not passage.request(0), "Later arrivals wait")
	passage.release(2)
	check(not passage.request(0) and passage.request(1), "Ladder FIFO follows arrival, not worker index")
	passage.release(0)
	passage.release(1)
	check(passage.queue.is_empty() and passage.owner == -1, "Cancelled waiter is removed")
	game.free()
	print("LADDERS: %d failure(s)" % failures)
	quit(failures)
