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
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	game.selected = 6
	check(not game.assign_worker(), "Unknown resource cannot be assigned")
	check(not game.patches[6].node.visible and not game.east_stand.visible, "Resource and loading stand remain undiscovered")
	check(game.start_exploration(), "Available resident can scout")
	check(not game.start_exploration(), "Cannot duplicate scouting mission")
	var c: WorkerDelivery = game.workers[0].delivery
	for i in range(1000):
		game.simulate(.05)
		if c.bridge_active: break
	check(c.bridge_active and c.crossings > 0, "Scout takes ladder then bridge")
	var frozen := c.actor.position
	game.paused = true
	game._process(.5)
	check(c.actor.position == frozen and not game.east_discovered, "Pause freezes bridge and exploration")
	game._toggle_hide()
	check(c.bridge_active and c.actor.position == frozen, "Mid-bridge recall does not teleport")
	advance(game, 65)
	check(c.at_refuge() and not game.east_discovered, "Interrupted reconnaissance returns without revealing zone")
	check(game.bridge.owner == -1 and game.bridge.queue.is_empty(), "Recall cleans bridge reservations")
	game._toggle_hide()
	check(game.start_exploration(), "Scout can restart after recall")
	for i in range(1800):
		game.simulate(.05)
		if game.east_discovered: break
	check(game.east_discovered and game.patches[6].node.visible and game.east_stand.visible, "Arriving and surveying reveals usable resource")
	game._refresh_ui()
	check(not game.patch_picker.is_item_disabled(7), "Discovery unlocks assignment UI")
	advance(game, 45)
	game.selected = 6
	check(game.assign_worker(0), "Discovered remote resource can be assigned")
	var stock_before: int = game.stock.wood
	var loaded_crossing := false
	var opposing_started := false
	var waiting_seen := false
	for i in range(2000):
		game.simulate(.05)
		if not opposing_started and game.workers[0].carrying > 0:
			# Stage a second carrier at the near platform to exercise opposing traffic.
			game.workers[1].node.position = game.bridge.waiting(1, false)
			check(game.assign_worker(1), "Second carrier assigned on opposite side")
			opposing_started = true
		var crossing_count := 0
		for w in game.workers:
			if w.delivery.bridge_active: crossing_count += 1
			waiting_seen = waiting_seen or w.delivery.waiting_bridge
		check(crossing_count <= 1, "Opposing carriers never cross together")
		loaded_crossing = loaded_crossing or (c.bridge_active and game.workers[0].carrying > 0)
		if c.bridge_active:
			check(game.bridge.owner == c.owner, "Crossing is reserved")
			check(absf(c.actor.position.y - 2.0295) < .001 and absf(c.actor.position.z + 4) < .001, "Carrier stays on level bridge deck")
		if c.completed_deliveries > 0: break
	check(loaded_crossing and game.stock.wood == stock_before + 3, "Remote cargo crosses bridge and ladder then credits depot once")
	check(waiting_seen, "Opposing traffic waits for passage")
	game._toggle_hide()
	advance(game, 65)
	check(c.at_refuge() and game.bridge.owner == -1 and game.ladder.owner == -1, "Multi-link delivery recall leaves no reserved access")
	var bridge = load("res://scripts/bridge_passage.gd").new()
	check(bridge.request(2) and not bridge.request(0) and not bridge.request(1), "Bridge queues competing arrivals")
	bridge.release(2)
	check(not bridge.request(1) and bridge.request(0), "Bridge follows FIFO order")
	bridge.release(1)
	bridge.release(0)
	check(bridge.queue.is_empty() and bridge.owner == -1, "Cancelled waiter removed")
	game.free()
	print("EXPLORATION: %d failure(s)" % failures)
	quit(failures)
