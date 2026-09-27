extends "res://tests/live_checkpoint.gd"
func total(g: Node) -> int:
	var result: int = g.depots.total("wood")
	for w in g.workers:
		if w.kind == "wood": result += w.carrying
	return result
func run() -> void:
	var g := fixture()
	g.prepare_transfers_demo()
	var initial := total(g)
	check(not g.transfers.add(1, 0, "wood"), "Duplicate link rejected")
	check(not g.transfers.add(0, 1, "wood"), "Opposite cyclic link rejected")
	var copy := clone(g, "transfer order waiting")
	if copy != null: copy.queue_free()
	var saved := false
	for i in range(9000):
		step(g)
		check(total(g) == initial, "Transfer conserves wood")
		if not saved and g.workers[0].carrying > 0 and g.workers[0].delivery.bridge_active:
			saved = true
			copy = clone(g, "transfer crossing loaded")
			if copy != null:
				copy.transfers.stop(0)
				for j in range(4000): step(copy)
				check(copy.transfers.jobs.is_empty() and total(copy) == initial, "Stop across bridge settles loads and reservations")
				copy.queue_free()
			copy = clone(g, "needs during loaded transfer")
			if copy != null:
				copy.transfers.toggle(0)
				copy.workers[0].hydration = 10.0
				for j in range(4000): step(copy)
				check(copy.transfers.jobs.is_empty() and total(copy) == initial and copy.workers[0].hydration > 35, "Urgent thirst returns cargo and drinks autonomously")
				copy.queue_free()
		if g.transfers.orders[0].delivered == 12 and g.transfers.jobs.is_empty(): break
	check(saved, "Loaded crossing tested")
	check(g.transfers.orders[0].delivered == 12 and g.stock.wood == 24 and g.depots.stocks(1).wood == 0, "Repeated trips transfer all 12 wood")
	check(g.depots.settled(), "All inventory and gate reservations released")
	copy = clone(g, "empty source waiting to refill")
	if copy != null: copy.queue_free()
	# A standing order wakes when stock returns; filters and capacity block dispatch.
	g.depots.stocks(1).wood = 6
	g.depots.sites[0].filters.erase("wood")
	for i in range(20): step(g)
	check(g.transfers.jobs.is_empty(), "Closed destination filter blocks new trips")
	g.depots.sites[0].filters.append("wood")
	g.depots.sites[0].capacity = g.depots.used(0)
	for i in range(20): step(g)
	check(g.transfers.jobs.is_empty(), "Full destination blocks new trips")
	g.depots.sites[0].capacity = 80
	for i in range(100):
		step(g)
		if not g.transfers.jobs.is_empty(): break
	check(not g.transfers.jobs.is_empty(), "Refilled source resumes automatically")
	g.transfers.toggle(0)
	for i in range(4000): step(g)
	check(g.transfers.jobs.is_empty() and g.depots.settled(), "Pause finishes committed trips")
	check(total(g) == initial + 6, "Pause preserves all resources")
	copy = clone(g, "paused transfer after refill")
	if copy != null: copy.queue_free()
	g.transfers.toggle(0)
	for i in range(4000): step(g)
	check(g.transfers.orders[0].delivered == 18, "Resume finishes remaining source stock")
	g.queue_free()
	await process_frame
	print("TRANSFERS: %d failure(s)" % failures)
	quit(1 if failures else 0)
