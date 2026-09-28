extends "res://tests/live_checkpoint.gd"
func settle(g: Node, count: int = 3500) -> void:
	for i in range(count): step(g)
func accounted(g: Node) -> int:
	var count: int = g.depots.total("food") + g.kitchen.amount + g.ant.carrying + g.ant.stored
	for w in g.workers:
		if w.kind == "food": count += w.carrying
	return count
func run() -> void:
	var g := fixture()
	g.prepare_kitchen_target_demo()
	var initial := accounted(g)
	var copied := false
	var partial := false
	for i in range(4500):
		step(g)
		check(g.local_harvest.expected("food") <= 29, "Kitchen reservations never exceed target")
		check(accounted(g) == initial, "Food conserved between colony, biscuit, cargo and ant")
		for task in g.kitchen.tasks.values():
			if task.kind == "food" and task.quantity == 2: partial = true
			if task.collected and not task.deposited and not copied:
				copied = true
				var copy := clone(g, "kitchen quota loaded")
				if copy != null:
					for j in range(2200):
						step(copy)
						if copy.stock.food == 29 and copy.kitchen.tasks.is_empty(): break
					check(copy.stock.food == 29 and copy.kitchen.harvest, "Loaded save reaches target without removing designation")
					copy.queue_free()
		if g.stock.food == 29 and g.kitchen.tasks.is_empty(): break
	check(copied and partial and g.stock.food == 29, "Three and two provisions delivered exactly")
	check("couvert" in g.kitchen.food_reserve_status(), "Covered reserve explained")
	# Trigger one real meal, then observe the ordinary stock withdrawal.
	g.workers[3].nutrition = 30
	var ate := false
	var resumed := false
	for i in range(3000):
		step(g)
		if g.workers[3].delivery.state == "eat": ate = true
		for task in g.kitchen.tasks.values():
			if task.kind == "food" and task.quantity == 1: resumed = true
		if ate and resumed and g.stock.food == 29: break
	check(ate and resumed and g.stock.food == 29, "A real meal triggers one replacement provision")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_kitchen_target_demo()
	for i in range(100):
		step(g)
		if g.kitchen.reserved == 5: break
	check(g.kitchen.reserved == 5, "Reservations made when equipment is assigned")
	g.local_harvest.set_target("food", 0)
	var copy := clone(g, "kitchen zero after reservation")
	if copy != null:
		for i in range(4500):
			step(copy)
			if copy.stock.food == 29 and copy.kitchen.tasks.is_empty(): break
		check(copy.stock.food == 29 and copy.kitchen.reserved == 0 and copy.kitchen.harvest, "Zero permits only already committed deliveries after reload")
		settle(copy, 80)
		check(copy.kitchen.tasks.is_empty() and "Objectif 0" in copy.kitchen.food_reserve_status(), "Zero blocks new expeditions")
		copy.queue_free()
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_kitchen_target_demo()
	g.local_harvest.set_active(0, true)
	for i in range(4500):
		step(g)
		check(g.local_harvest.expected("food") <= 29, "Local and kitchen harvest share the same quota")
		if g.stock.food == 29 and g.kitchen.tasks.is_empty(): break
	check(g.stock.food == 29, "Combined sources reach target")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_ant_demo()
	g.stock.wood = 24 # Fixture supplies only for prerequisite buildings.
	g._choose_build("workshop")
	check(g._place_build(Vector3(-4, 0, -3)), "Guide fixture workshop")
	g.stock.fiber = 3
	g._choose_build("bed")
	check(g._place_build(Vector3(0, 0, -3)), "Guide fixture bed")
	g.local_harvest.set_target("food", 0)
	for i in range(1800):
		step(g)
		if g.sleeping.ready_count() > 0: break
	check("Objectif 0" in preload("res://scripts/first_chapter.gd").current(g).text, "Chapter explains food quota before first delivery")
	g.queue_free()
	await process_frame
	print("KITCHEN_TARGET: %d failure(s)" % failures)
	quit(1 if failures else 0)
