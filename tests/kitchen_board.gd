extends "res://tests/live_checkpoint.gd"
const Board = preload("res://scripts/construction_board.gd")
func total(g: Node, kind: String) -> int:
	var amount: int = g.depots.total(kind) + g.kitchen.materials[kind]
	for w in g.workers:
		if w.kind == kind: amount += w.carrying
	return amount
func run() -> void:
	var g := fixture()
	check(Board.kitchen_entry(g).is_empty(), "Unplanned bridge absent")
	g.prepare_kitchen_board_demo()
	var entry := Board.kitchen_entry(g)
	check(Board.entries(g).size() == 1 and entry.key == "kitchen:bridge", "Bridge appears once in common board")
	check("Bois 0/8" in entry.detail and "Transport : aucun" in entry.detail, "Real delivered quantities and priority blockage shown")
	g.hud._open_construction_entry(0)
	check(g.active_tray == "kitchen", "Bridge card opens its commands")
	g._show_tray("construction_board")
	var before: String = JSON.stringify(g.Save.capture(g).runtime)
	for i in range(5):
		Board.entries(g)
		g._refresh_ui()
	check(before == JSON.stringify(g.Save.capture(g).runtime), "Board cannot mutate tasks or reservations")
	var wood := total(g, "wood")
	var fiber := total(g, "fiber")
	for w in g.workers: w.priorities.transport = 1
	var loaded := false
	for i in range(1800):
		step(g)
		for id in g.kitchen.tasks:
			var task: Dictionary = g.kitchen.tasks[id]
			if task.kind == "supply" and task.collected and not task.deposited: loaded = true
		if loaded: break
	check(loaded and "Réservé vers le pont" in Board.kitchen_entry(g).detail, "Reserved transport displayed before delivery")
	check("H1" in Board.kitchen_entry(g).detail, "Actual assigned resident is shown")
	g.kitchen.toggle_build()
	entry = Board.kitchen_entry(g)
	check("Suspendu" in entry.detail and "En retour au dépôt" in entry.detail, "Suspension distinguishes returning cargo from delivered materials")
	check(not "Réservé vers le pont" in entry.detail, "Cancelled cargo is no longer shown as inbound")
	var copy := clone(g, "kitchen board suspended cargo")
	if copy != null:
		check(Board.kitchen_entry(copy).detail == entry.detail, "Restored bridge card preserves exact quantities and crew")
		g.queue_free()
		g = copy
	for i in range(3000):
		step(g)
		if g.kitchen.tasks.is_empty(): break
	check(g.kitchen.tasks.is_empty() and "Suspendu" in Board.kitchen_entry(g).detail, "Suspended bridge remains visible after returns")
	check(total(g, "wood") == wood and total(g, "fiber") == fiber, "Suspension conserves all building materials")
	g.kitchen.toggle_build()
	for i in range(12000):
		step(g)
		if g.kitchen.supplied() and g.kitchen.tasks.is_empty(): break
	entry = Board.kitchen_entry(g)
	check("Bois 8/8" in entry.detail and "Fibres 4/4" in entry.detail, "Only physically delivered materials count toward bridge")
	check("Construction : aucun" in entry.detail, "Ready bridge explains missing builder priority")
	for w in g.workers: w.priorities.build = 1
	var progress := false
	var returning := false
	for i in range(6500):
		step(g)
		entry = Board.kitchen_entry(g)
		if g.kitchen.work > 1 and not g.kitchen.built:
			progress = "Construction" in entry.detail and "%" in entry.detail
		if g.kitchen.built and not g.kitchen.tasks.is_empty(): returning = "derniers retours" in entry.detail
		if g.kitchen.built and g.kitchen.tasks.is_empty(): break
	check(progress and returning and g.kitchen.built, "Live progress and final crew returns are displayed")
	check(Board.kitchen_entry(g).is_empty(), "Completed and cleared bridge disappears")
	g._show_tray("construction_board")
	check(g.hud.construction_rows.is_empty(), "Board removes finished bridge card")
	check(total(g, "wood") == wood and total(g, "fiber") == fiber, "Watching board preserves material accounting")
	g.queue_free()
	await process_frame
	print("KITCHEN_BOARD: %d failure(s)" % failures)
	quit(1 if failures else 0)
