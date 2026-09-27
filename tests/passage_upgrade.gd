extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func step(g: Node) -> void:
	g.simulate(.05)
	g.suspicion = 0
func balance(g: Node, kind: String) -> int:
	var count: int = g.depots.total(kind)
	for w in g.workers:
		if w.kind == kind: count += int(w.carrying)
	for site in g.construction.sites(): count += int(site.materials[kind])
	for pile in g.construction.recovery: count += int(pile.materials[kind])
	return count
func settle(g: Node) -> void:
	g.pending_save = true
	if not g.hiding: g._toggle_hide()
	for i in range(3000):
		step(g)
		if g.checkpoint_ready(): return
	check(false, "Upgrade checkpoint settles")
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	g.prepare_alcove_demo()
	check(not g.fissure.request_upgrade(), "Recognition required before widening")
	check(not g.fissure.hauling.start(0), "Narrow passage refuses cargo")
	g.fissure.start(0)
	for i in range(2200):
		step(g)
		if g.fissure.visited and g.torches.missions.is_empty(): break
	var wood := balance(g, "wood")
	var fibre := balance(g, "fiber")
	check(g.fissure.request_upgrade(), "Physical widening ordered")
	for i in range(1800):
		step(g)
		check(balance(g, "wood") == wood and balance(g, "fiber") == fibre, "Widening supply conserves materials")
		if g.fissure.upgrade.materials.wood > 0: break
	check(not g.fissure.access_contract().cargo and not g.fissure.wide_frame.visible, "Unfinished work retains narrow physical opening")
	check(not g.fissure.start(0), "Work closes passage to expeditions")
	check(g.fissure.cancel_build(), "Widening cancellation accepted")
	for i in range(2000):
		step(g)
		if g.construction.jobs.is_empty() and g.construction.recovery.is_empty(): break
	check(g.fissure.opened() and not g.fissure.widened(), "Cancellation keeps original passage usable")
	check(balance(g, "wood") == wood and balance(g, "fiber") == fibre, "Cancelled widening recovers materials")
	check(g.fissure.request_upgrade(), "Widening can restart")
	for i in range(2400):
		step(g)
		if g.fissure.upgrade.work > 10: break
	var work: float = g.fissure.upgrade.work
	check(work > 10 and work < 24, "Partial upgrade fixture")
	settle(g)
	var saved: Dictionary = g.Save.capture(g)
	check(g.Save.validate(saved).is_empty(), "Partial widening checkpoint validates")
	g.queue_free()
	await process_frame
	g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	check(g.apply_checkpoint(saved), "Partial widening restores")
	check(g.fissure.upgrade.work == work and not g.fissure.widened(), "No early completion on load")
	g._toggle_hide()
	for i in range(1800):
		step(g)
		if g.fissure.widened(): break
	check(g.fissure.widened() and g.fissure.access_contract().cargo and g.fissure.access_contract().width == 1.8, "Finished geometry enables loaded crossing")
	check(balance(g, "wood") == wood and balance(g, "fiber") == fibre, "Restored upgrade does not duplicate its cost")
	g.queue_free()
	await process_frame
	print("PASSAGE_UPGRADE: ", failures, " failure(s)")
	quit(1 if failures else 0)
