extends "res://tests/live_checkpoint.gd"
func run() -> void:
	var g := fixture()
	g.prepare_kitchen_demo()
	g.kitchen.known = true
	g.kitchen.planned = true
	g.kitchen.built = true
	g.kitchen.work = 24.0
	g.kitchen.materials = g.kitchen.COST.duplicate()
	g.kitchen.harvest = true
	g.stock = {"food": 34, "wood": 20, "fiber": 10, "water": 16}
	for i in range(30): step(g)
	check(g.kitchen.tasks.is_empty() and g.kitchen.reserved == 0, "Full depot prevents remote food reservation")
	g.stock.food = 20
	for lamp in g.torches.items: lamp.fuel = 20.0
	for i in range(30): step(g)
	check(g.kitchen.tasks.is_empty(), "Insufficient autonomy prevents departure")
	for lamp in g.torches.items: lamp.fuel = 180.0
	var interrupted := false
	var completed := false
	for i in range(6000):
		step(g)
		for id in g.kitchen.tasks.keys():
			var t: Dictionary = g.kitchen.tasks[id]
			var c: WorkerDelivery = g.workers[id].delivery
			if not interrupted and t.stage == "bridge_cross" and c.actor.position.z > 19 and c.actor.position.z < 21:
				interrupted = true
				c.cancel()
				check(g.kitchen.owner == id, "Recall retains committed bridge ownership")
				var other := clone(g, "recall halfway over kitchen bridge")
				if other != null:
					other.kitchen.designate_food()
					for j in range(4000):
						step(other)
						if other.kitchen.tasks.is_empty(): break
					check(other.kitchen.tasks.is_empty() and other.kitchen.owner == -1 and other.fissure.owner == -1, "Restored reversal clears both passage ledgers")
					other.queue_free()
					await process_frame
			if t.deposited: completed = true
		if completed: break
	check(interrupted and completed, "One recalled scout does not block the other porter")
	g.kitchen.designate_food()
	for i in range(4000):
		step(g)
		if g.kitchen.tasks.is_empty(): break
	check(g.kitchen.reserved == 0 and g.kitchen.tasks.is_empty(), "Stopping food clears all source claims")
	var data: Dictionary = g.Save.capture(g)
	data.version = 16
	var runtime: Dictionary = g.Save.Live.unpack(data.runtime.data)
	runtime.erase("kitchen")
	data.runtime.data = g.Save.Live.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	var old := fixture()
	check(g.Save.validate(data).is_empty() and old.apply_checkpoint(data), "Version 16 remains loadable")
	check(not old.kitchen.known and old.kitchen.tasks.is_empty(), "Older saves start with undiscovered kitchen")
	old.queue_free()
	g.queue_free()
	await process_frame
	print("KITCHEN_EDGES: %d failure(s)" % failures)
	quit(1 if failures else 0)
