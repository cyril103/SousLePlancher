extends "res://tests/live_checkpoint.gd"
func material_total(g: Node, kind: String) -> int:
	var result: int = g.depots.total(kind) + g.kitchen.materials.get(kind, 0)
	if kind == "food": result += g.kitchen.amount
	for w in g.workers:
		if w.kind == kind: result += w.carrying
	return result
func run() -> void:
	var g := fixture()
	g.prepare_kitchen_demo()
	check(not g.kitchen.plan(), "Bridge requires actual scouting")
	check(not g.kitchen.designate_food(), "Cargo harvest forbidden without bridge")
	check(g.kitchen.request_scout(), "Scout order accepted")
	for i in range(5000):
		step(g)
		if g.kitchen.known and g.kitchen.tasks.is_empty(): break
	check(g.kitchen.known and g.kitchen.tasks.is_empty(), "Unladen scouting round trip completes through ledge")
	print("SCOUT DONE ", g.kitchen.snapshot())
	check(g.kitchen.plan(), "Known bridge can be commissioned")
	var wood := material_total(g, "wood")
	var fiber := material_total(g, "fiber")
	var captured := {}
	var paused_once := false
	for i in range(14000):
		step(g)
		check(material_total(g, "wood") == wood and material_total(g, "fiber") == fiber, "Bridge materials conserved")
		for id in g.kitchen.tasks.keys():
			var t: Dictionary = g.kitchen.tasks[id]
			if not paused_once and t.kind == "supply" and t.collected:
				paused_once = true
				g.kitchen.toggle_build()
				for j in range(2400):
					step(g)
					if g.kitchen.tasks.is_empty(): break
				check(g.kitchen.tasks.is_empty(), "Paused construction returns cargo and releases claims")
				g.kitchen.toggle_build()
				break
			if t.stage in ["pickup", "to_bridge", "build"] and not captured.has(t.stage):
				captured[t.stage] = true
				var other := clone(g, "kitchen construction " + t.stage)
				if other != null:
					check(other.kitchen.materials == g.kitchen.materials, "Bridge deliveries restored")
					for j in range(10000):
						step(other)
						if other.kitchen.built: break
					check(other.kitchen.built, "Restored bridge finishes")
					other.queue_free()
					await process_frame
		if g.kitchen.built and g.kitchen.tasks.is_empty(): break
	check(g.kitchen.built, "Physically delivered bridge completes")
	print("BRIDGE DONE ", g.kitchen.snapshot())
	check(g.kitchen.designate_food(), "Food designation enabled by bridge")
	var delivered := false
	var saved_food := false
	for i in range(7000):
		step(g)
		for id in g.kitchen.tasks.keys():
			var t: Dictionary = g.kitchen.tasks[id]
			if t.kind == "food" and t.collected and not t.deposited and not saved_food:
				saved_food = true
				var other := clone(g, "kitchen loaded food")
				if other != null:
					other.kitchen.designate_food() # Recall preserves the already collected crate.
					for j in range(4000):
						step(other)
						if other.kitchen.tasks.is_empty(): break
					check(other.kitchen.tasks.is_empty(), "Loaded recall crosses both accesses and delivers")
					check(other.kitchen.owner == -1 and other.kitchen.queue.is_empty(), "Bridge reservation freed")
					other.queue_free()
					await process_frame
			if t.kind == "food" and t.deposited: delivered = true
		if delivered: break
	check(delivered and saved_food, "Kitchen provisions physically returned")
	print("FINAL ",g.kitchen.snapshot())
	g.queue_free()
	await process_frame
	print("KITCHEN: %d failure(s)" % failures)
	quit(1 if failures else 0)
