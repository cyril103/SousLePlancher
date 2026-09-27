extends "res://tests/live_checkpoint.gd"
func wood(g: Node) -> int:
	var amount: int = g.depots.total("wood") + g.fixed_lighting.loaded
	for s in g.construction.sites(): amount += s.materials.wood
	for p in g.construction.recovery: amount += p.materials.wood
	for w in g.workers:
		if w.kind == "wood": amount += w.carrying
	return amount
func run() -> void:
	var g := fixture()
	g.prepare_fixed_light_demo()
	var f = g.fixed_lighting
	var balance := wood(g)
	check(not f.lit() and not g.transfers.blocked(g.transfers.orders[0]).is_empty(), "Unbuilt lamp suspends new route departures")
	var other := clone(g, "lamp plan")
	if other != null: other.queue_free()
	var milestones := {}
	for i in range(8500):
		step(g)
		check(wood(g) == balance, "Construction and combustion conserve accounted wood")
		var key := ""
		if f.site.work > 0 and not f.site.built: key = "construction"
		if f.site.built and f.refill.hauler >= 0: key = "fuel delivery"
		if f.lit(): key = "lit"
		if not key.is_empty() and not milestones.has(key):
			milestones[key] = true
			other = clone(g, key)
			if other != null:
				check(other.fixed_lighting.snapshot() == f.snapshot(), "Lamp runtime restored exactly")
				other.queue_free()
		if f.lit(): break
	check(milestones.has_all(["construction", "fuel delivery", "lit"]), "Build and first fuelling complete")
	# Exhaust naturally with maintenance paused, while ordinary committed trips settle.
	f.toggle_auto()
	for i in range(4000): step(g)
	check(not f.lit() and f.fuel == 0, "Fuel burns out without maintenance")
	check(not g.transfers.blocked(g.transfers.orders[0]).is_empty(), "Darkness blocks new transfers")
	check(wood(g) == balance, "Panne loses no cargo")
	f.toggle_auto()
	for i in range(4000):
		step(g)
		if f.lit(): break
	check(f.lit() and f.loaded >= 4, "Automatic physical refuelling relights after outage")
	f.enabled = false
	var reserve: float = f.fuel
	for i in range(30): step(g)
	check(f.fuel == reserve and not f.lit(), "Manual extinction preserves remaining fuel")
	other = clone(g, "manually extinguished")
	if other != null: other.queue_free()
	f.enabled = true
	check(f.lit(), "Manual relighting")
	check(wood(g) == balance, "Complete cycle preserves wood balance")
	g.queue_free()
	await process_frame
	# Interrupt maintenance while loaded; keep the order suspended until all charges settle.
	g = fixture()
	g.prepare_fixed_light_demo()
	f = g.fixed_lighting
	balance = wood(g)
	var recalled := false
	for i in range(9000):
		step(g)
		if f.refill.hauler >= 0 and g.workers[f.refill.hauler].carrying > 0:
			recalled = true
			f.toggle_auto()
			break
	check(recalled, "Loaded maintenance interruption reached")
	for i in range(4000): step(g)
	check(f.refill.hauler == -1 and f.loaded == 0 and wood(g) == balance, "Cancelled fuel returned without duplication")
	other = clone(g, "maintenance suspended")
	if other != null: other.queue_free()
	g.queue_free()
	await process_frame
	# Cancelling a partially built post preserves delivered materials as recovery piles.
	g = fixture()
	g.prepare_fixed_light_demo()
	balance = wood(g)
	for i in range(7000):
		step(g)
		if g.fixed_lighting.site.work > 1: break
	check(g.fixed_lighting.site.work > 1, "Partial construction reached")
	g.fixed_lighting.cancel_plan()
	check(wood(g) == balance and not g.fixed_lighting.site.active, "Cancelled materials recoverable")
	other = clone(g, "cancelled upper light")
	if other != null: other.queue_free()
	g.fixed_lighting.plan()
	for i in range(7000):
		step(g)
		if g.fixed_lighting.lit(): break
	check(g.fixed_lighting.lit() and wood(g) == balance, "Cancelled plan resumes and recovers materials")
	var data: Dictionary = g.Save.capture(g)
	var runtime: Dictionary = g.Save.Live.unpack(data.runtime.data)
	runtime.fixed_lighting.fuel += 1.0
	data.runtime.data = g.Save.Live.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(not g.Save.validate(data).is_empty(), "Forged fuel balance rejected despite valid checksum")
	g.queue_free()
	await process_frame
	# A genuine pre-lighting runtime migrates with no new route restriction.
	g = fixture()
	g.prepare_transfers_demo()
	data = g.Save.capture(g)
	data.version = 12
	runtime = g.Save.Live.unpack(data.runtime.data)
	runtime.erase("fixed_lighting")
	data.runtime.data = g.Save.Live.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(g.Save.validate(data).is_empty(), "Version 12 still validates")
	other = fixture()
	check(other.apply_checkpoint(data) and other.fixed_lighting.site.is_empty(), "Version 12 restores without light plans")
	other.queue_free()
	g.queue_free()
	await process_frame
	print("FIXED_LIGHTING: %d failure(s)" % failures)
	quit(1 if failures else 0)
