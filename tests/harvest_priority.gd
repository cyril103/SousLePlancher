extends "res://tests/live_checkpoint.gd"
func first_job(g: Node) -> Dictionary:
	for i in range(300):
		step(g)
		if not g.delivery_ledger.jobs.is_empty(): return g.delivery_ledger.jobs.values()[0]
	return {}
func run() -> void:
	var g := fixture()
	g.prepare_harvest_priority_demo()
	check(g.hud.source_priority.selected == 0, "Context panel displays high fiber priority")
	check(not g.local_harvest.set_priority(3, 1) and not g.local_harvest.set_priority(4, 0) and not g.local_harvest.set_priority(4, 4), "Only local sources and priorities 1–3 accepted")
	var job := first_job(g)
	check(job.get("source") == 4, "High fiber priority wins over earlier wood source")
	for i in range(900):
		step(g)
		if g.workers[0].carrying > 0: break
	check(g.workers[0].carrying > 0, "Priority order produces real cargo")
	# Change through the actual UI while a crate is already committed.
	g.hud.source_priority.item_selected.emit(2)
	g.hud.open_harvest_source(2)
	g.hud.source_priority.item_selected.emit(0)
	check(g.local_harvest.priority(4) == 3 and g.local_harvest.priority(2) == 1, "UI changes source priorities")
	check(g.delivery_ledger.jobs.values()[0].source == 4 and g.workers[0].carrying > 0, "Priority edit does not replace committed mission")
	var copy := clone(g, "harvest priority loaded")
	if copy != null:
		check(copy.local_harvest.priority(4) == 3 and copy.local_harvest.priority(2) == 1, "Custom priorities survive loaded save")
		var wood_seen := false
		for i in range(2200):
			step(copy)
			for active in copy.delivery_ledger.jobs.values():
				if active.source == 2: wood_seen = true
			if copy.stock.wood == 15 and copy.stock.fiber == 9 and copy.delivery_ledger.jobs.is_empty(): break
		check(wood_seen and copy.stock.wood == 15 and copy.stock.fiber == 9, "Restored mission completes before next source, preserving exact quotas")
		copy.queue_free()
	var snapshot: Dictionary = g.Save.capture(g)
	check(snapshot.version == 28, "Priority save format is v28")
	for invalid in [0, 4, 1.5, true, "1", null]:
		var bad := snapshot.duplicate(true)
		bad.patches[4].harvest_priority = invalid
		check(not g.Save.validate(bad).is_empty(), "Invalid priority rejected: %s" % str(invalid))
	var bad := snapshot.duplicate(true)
	bad.patches[4].erase("harvest_priority")
	check(not g.Save.validate(bad).is_empty(), "v28 requires explicit priority")
	bad = snapshot.duplicate(true)
	bad.patches[4].harvest_priority = 2
	check(not g.Save.validate(bad).is_empty(), "Compact and runtime priority mismatch rejected")
	bad = snapshot.duplicate(true)
	bad.patches[3].harvest_priority = 1
	check(not g.Save.validate(bad).is_empty(), "Priority for upper source rejected")
	var old := snapshot.duplicate(true)
	old.version = 27
	for patch in old.patches: patch.erase("harvest_priority")
	var runtime: Dictionary = g.Save.Live.unpack(old.runtime.data)
	for patch in runtime.patches: patch.erase("harvest_priority")
	old.runtime.data = g.Save.Live.pack(runtime)
	old.runtime.sha256 = JSON.stringify(old.runtime.data).sha256_text()
	check(g.Save.validate(old).is_empty(), "v27 without priorities remains valid")
	var migrated := fixture()
	check(migrated.apply_checkpoint(old), "v27 restores its active mission")
	for id in g.local_harvest.PATCHES: check(migrated.local_harvest.priority(id) == 2, "Migration defaults every source to normal")
	check(migrated.workers[0].carrying == g.workers[0].carrying, "Migration preserves loaded crate")
	migrated.queue_free()
	g.queue_free()
	await process_frame
	# A blocked high-priority source must not starve an eligible lower source.
	g = fixture()
	g.prepare_harvest_priority_demo()
	g.depots.sites[0].filters.erase("fiber")
	check(first_job(g).get("source") == 2, "Blocked high priority falls through to usable wood")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_harvest_priority_demo()
	g.local_harvest.set_priority(2, 1)
	check(first_job(g).get("source") == 2, "Equal priorities use stable source number order")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_harvest_priority_demo()
	g.local_harvest.set_priority(2, 1)
	g.local_harvest.set_priority(4, 3)
	g.workers[0].patch = 4
	check(first_job(g).get("source") == 4, "Manual assignment remains independent of source priority")
	g.queue_free()
	await process_frame
	print("HARVEST_PRIORITY: %d failure(s)" % failures)
	quit(1 if failures else 0)
