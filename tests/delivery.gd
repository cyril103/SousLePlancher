extends SceneTree
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var ledger := DeliveryLedger.new()
	ledger.patches = [{"kind": "wood", "amount": 5, "reserved": 0}, {"kind": "wood", "amount": 3, "reserved": 0}]
	var stock := {"wood": 0}
	var first := ledger.reserve(0, 0, 3)
	check(first > 0 and ledger.patches[0].reserved == 3, "Reserve without consuming")
	check(ledger.reserve(1, 0, 3) == -1, "Source station cannot be claimed twice")
	check(ledger.reserve(0, 1, 3) == -1, "Worker cannot own two jobs")
	check(ledger.cancel(first) and ledger.patches[0].amount == 5 and ledger.patches[0].reserved == 0, "Cancel releases untouched resources")
	first = ledger.reserve(0, 0, 9)
	var second := ledger.reserve(1, 1, 3)
	check(ledger.collect(first) == 5 and ledger.collect(first) == 0, "Collect remainder once, without negative stock")
	check(not ledger.cancel(first), "Collected cargo must be returned, not destroyed")
	ledger.collect(second)
	check(ledger.acquire_destination(first) and not ledger.acquire_destination(second), "Unloading slot is exclusive")
	check(ledger.deliver(second, stock) == 0, "Non-owner cannot unload")
	check(ledger.deliver(first, stock) == 5 and ledger.deliver(first, stock) == 0, "Deposit is exactly once")
	check(not ledger.acquire_destination(second), "Slot stays occupied while actor stands up")
	ledger.release_destination(first)
	check(ledger.acquire_destination(second), "Next carrier can unload after release")
	ledger.deliver(second, stock)
	ledger.release_destination(second)
	check(stock.wood == 8 and ledger.jobs.is_empty() and ledger.source_slots.is_empty(), "Resource conservation and lock cleanup")

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.depots.sites[0].capacity = 20000 # Large-stock fixture; capacity is tested by depots.gd.
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 1000
	game.selected = 2
	check(not game._valid_site(game.HOME + Vector3(1.6, 0, 0.25)), "Construction keeps unloading station clear")
	check(game.assign_worker(), "Assign real worker")
	game.simulate(0.05)
	var controller: WorkerDelivery = game.workers[0].delivery
	var initial: int = game.patches[2].amount
	check(controller.state == "to_source" and game.patches[2].reserved == 3, "Real task reserves source")
	game.release_worker()
	check(game.patches[2].amount == initial and game.patches[2].reserved == 0 and not controller.actor.cargo.visible, "Cancel before grasp cleans up")
	for i in range(400):
		game.simulate(0.05)
		if controller.state == "idle": break
	check(game.assign_worker(), "Reassign after return")
	var cargo_id := controller.actor.cargo.get_instance_id()
	for i in range(600):
		game.simulate(0.05)
		if game.workers[0].carrying > 0: break
	check(game.workers[0].carrying == 3 and game.patches[2].amount == initial - 3, "Grasp consumes reserved quantity")
	var before: int = game.stock.wood
	var frozen := controller.actor.global_transform
	var frozen_hand := controller.actor.skeleton.get_bone_global_pose(controller.actor.skeleton.find_bone("R_hand"))
	game.paused = true
	game._process(0.5)
	check(controller.actor.global_transform == frozen and game.stock.wood == before, "Pause freezes task and stock")
	check(controller.actor.skeleton.get_bone_global_pose(controller.actor.skeleton.find_bone("R_hand")) == frozen_hand, "Pause freezes skeletal animation")
	game._toggle_hide()
	check(game.workers[0].carrying == 3, "Recall preserves cargo")
	for i in range(700):
		game.simulate(0.05)
		if controller.state == "idle": break
	check(game.stock.wood == before + 3 and controller.completed_deliveries == 1, "Recall delivers once")
	check(controller.actor.cargo.get_instance_id() == cargo_id, "Same cargo object survives pickup and delivery")
	check(game.delivery_ledger.jobs.is_empty() and game.delivery_ledger.destination_owner == -1, "No abandoned reservations")
	check(controller.actor.position.distance_to(game.refuge.slot(0)) < 0.02 and controller.inside_refuge, "Recall ends at interior refuge slot")
	await process_frame
	game.queue_free()
	await process_frame
	print("DELIVERY: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
