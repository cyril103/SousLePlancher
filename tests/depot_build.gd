extends "res://tests/live_checkpoint.gd"
func run() -> void:
	var g := fixture()
	g.prepare_depot_build_demo()
	check(g.depots.sites.size() == 2, "Remote depot plan placed without blocking resource or bridge")
	if g.depots.sites.size() < 2:
		print(g.news_label.text)
		quit(1)
		return
	check(not g.depots.sites[1].built and g.depots.free_space(1) == 0, "Blueprint cannot store resources")
	var copy := clone(g, "depot blueprint")
	if copy != null: copy.queue_free()
	var saved_crossing := false
	var saved_work := false
	var initial := fibres(g)
	for i in range(12000):
		step(g)
		if not saved_crossing and g.workers[0].carrying > 0 and g.workers[0].delivery.bridge_active:
			saved_crossing = true
			copy = clone(g, "loaded supply across bridge")
			if copy != null:
				copy.depots.cancel_plan(1)
				for j in range(4000): step(copy)
				check(fibres(copy) == initial and copy.construction.jobs.is_empty(), "Cancelled loaded supply returns without loss")
				copy.queue_free()
		if not saved_work and g.depots.sites[1].work > 2 and not g.depots.sites[1].built:
			saved_work = true
			copy = clone(g, "depot under construction")
			if copy != null:
				copy.depots.set_filter(0, "wood", true)
				copy.depots.cancel_plan(1)
				var stopped := clone(copy, "cancelled upper depot with recovery pile")
				if stopped != null: stopped.queue_free()
				for j in range(5000): step(copy)
				check(fibres(copy) == initial and copy.construction.recovery.is_empty(), "Upper recovery returns all delivered materials")
				copy.depots.resume_plan(1)
				for j in range(12000):
					step(copy)
					if copy.depots.sites[1].built: break
				check(copy.depots.sites[1].built, "Cancelled plan can be rebuilt")
				copy.queue_free()
		if g.depots.used(1) == 12: break
	check(g.depots.sites[1].built, "Remote depot built by deliveries and labor")
	check(g.depots.used(1) == 12, "Remote harvest fills constructed depot")
	check(saved_crossing and saved_work, "Both active supply and active building checkpoints exercised")
	check(g.stock.wood == 6, "Remote harvest stays remote and recipe uses six wood")
	check(g.depots.free_space(1) == 0 and g.depots.booked(1) == 0, "Full depot stops new reservations")
	g.depots.set_filter(1, "wood", false)
	check(g.depots.stocks(1).wood == 12, "Filter change keeps existing stock")
	copy = clone(g, "full distant depot")
	if copy != null: copy.queue_free()
	# Resources stored on the far side can physically supply a refuge-side project.
	g.stock.wood = 0
	g.workers[2].patch = -1
	g._choose_build("bed")
	check(g._place_build(Vector3(0, 0, -3)), "Refuge bed planned with distant wood")
	var far_source := false
	for i in range(6000):
		step(g)
		for job in g.construction.jobs.values():
			if job.depot == 1: far_source = true
		if g.sleeping.beds[0].materials.wood == 4: break
	check(far_source and g.sleeping.beds[0].materials.wood == 4, "Remote stock physically returns to supply refuge construction")
	g.queue_free()
	await process_frame
	g = fixture()
	g.start_panel.hide()
	g._choose_build("depot")
	check(g._place_build(Vector3(4, 0, 2)), "Ground depots also require construction")
	check(not g.depots.sites[1].built, "Ground depot no longer free and instant")
	g.depots.restore_site(1, {})
	var old: Dictionary = g.Save.capture(g)
	old.version = 10
	for key in ["built", "active", "work", "materials"]: old.depots[1].erase(key)
	var codec = load("res://scripts/live_checkpoint.gd")
	var runtime: Dictionary = codec.unpack(old.runtime.data)
	runtime.erase("depot_sites")
	for w in runtime.workers: w.controller.erase("depot_order")
	old.runtime.data = codec.pack(runtime)
	old.runtime.sha256 = JSON.stringify(old.runtime.data).sha256_text()
	check(g.Save.validate(old).is_empty(), "Legacy depot snapshot validates")
	copy = fixture()
	check(copy.apply_checkpoint(old) and copy.depots.sites[1].built, "Legacy depots remain built")
	copy.queue_free()
	g.queue_free()
	await process_frame
	print("DEPOT_BUILD: %d failure(s)" % failures)
	quit(1 if failures else 0)
