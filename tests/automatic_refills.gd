extends "res://tests/live_checkpoint.gd"
func setup_colony() -> Node:
 var g := fixture()
 g.start_panel.hide()
 g.stock.wood = 24
 g._choose_build("workshop")
 check(g._place_build(Vector3(0, 0, -3)), "Workshop built")
 g.torches.add_item(g.depots.entry(0), 20, "lantern")
 return g
func wood_total(g: Node) -> int:
 var total: int = g.depots.total("wood")
 for w in g.workers:
  if w.kind == "wood": total += w.carrying
 for site in g.torches.orders: total += site.materials.wood
 for pile in g.construction.recovery: total += pile.materials.wood
 return total
func run() -> void:
 var g := setup_colony()
 g.torches.add_item(g.depots.entry(0), 40, "lantern")
 var wood: int = g.stock.wood
 g.hud.refill_target.value = 2
 check(g.torches.refill_target == 2, "UI sets automatic reserve")
 check(not g.torches.set_refill_target(9), "Oversized reserve rejected")
 var saved := false
 for i in range(3000):
  step(g)
  check(wood_total(g) == wood, "Automatic supply conserves wood")
  if not saved and g.torches.pending_refill() >= 0 and g.torches.orders[-1].work > 0:
   saved = true
   var copy := clone(g, "automatic refill active")
   if copy != null:
    check(copy.torches.refill_target == 2, "Automatic target survives JSON")
    for j in range(3000):
     step(copy)
     if copy.torches.ready_lanterns() == 2: break
    check(copy.torches.ready_lanterns() == 2, "Restored automation replenishes reserve")
    copy.queue_free()
    await process_frame
  if g.torches.ready_lanterns() == 2: break
 check(saved and g.torches.ready_lanterns() == 2, "Two stored lanterns replenished sequentially")
 check(g.torches.items.size() == 2 and g.stock.wood == wood - 4, "No equipment fabricated or fuel paid twice")
 var count: int = g.torches.orders.size()
 for i in range(200): step(g)
 check(g.torches.orders.size() == count, "Satisfied target creates no extra order")
 g.torches.set_refill_target(0)
 g.torches.items[0].fuel = 30 # Isolate a new consumption cycle.
 for i in range(30): step(g)
 check(g.torches.pending_refill() == -1, "Zero target disables new maintenance")
 g.torches.set_refill_target(1)
 for i in range(30): step(g)
 check(g.torches.pending_refill() == -1, "One full lantern already covers target one")
 g.torches.set_refill_target(2)
 step(g)
 check(g.torches.pending_refill() >= 0, "Raised target resumes automatically")
 g.torches.set_refill_target(0)
 for i in range(1800):
  step(g)
  if g.torches.pending_refill() < 0: break
 check(g.torches.ready_lanterns() == 2, "Disabling automation finishes committed maintenance")
 var old: Dictionary = g.Save.capture(g)
 old.version = 20
 old.torches.erase("refill_target")
 check(g.Save.validate(old).is_empty(), "v20 without target remains valid")
 var migrated := fixture()
 check(migrated.apply_checkpoint(old) and migrated.torches.refill_target == 0, "Old saves default to automation off")
 migrated.queue_free()
 var bad: Dictionary = g.Save.capture(g)
 bad.torches.refill_target = 9
 check(not g.Save.validate(bad).is_empty(), "Invalid saved reserve rejected")
 g.queue_free()
 await process_frame
 # Cancel at all transactional boundaries, save immediately, then settle recovery.
 for stage in ["waiting", "loaded", "working"]:
  g = setup_colony()
  wood = g.stock.wood
  g.torches.set_refill_target(2)
  g.torches.update_refills()
  var reached: bool = stage == "waiting"
  for i in range(1800):
   if reached: break
   step(g)
   if stage == "working": reached = g.torches.orders[-1].work > 1
   elif stage == "loaded":
    for job in g.construction.jobs.values(): reached = reached or (job.collected and not job.deposited)
  check(reached, "Cancellation boundary reached: " + stage)
  check(g.torches.cancel_refill(), "Cancel maintenance: " + stage)
  check(g.torches.refill_target == 0 and not g.torches.servicing(0), "Cancellation disables automation and releases equipment")
  check(g.torches.items[0].fuel == 20 and wood_total(g) == wood, "Cancellation preserves fuel and all wood")
  var copy := clone(g, "cancelled maintenance " + stage)
  if copy != null:
   for j in range(2200): step(copy)
   check(copy.torches.pending_refill() < 0 and copy.torches.items[0].fuel == 20, "Cancelled order never refills after loading")
   check(copy.stock.wood == wood and copy.construction.jobs.is_empty(), "All delivered or carried wood recovered")
   copy.queue_free()
   await process_frame
  g.queue_free()
  await process_frame
 print("AUTOMATIC_REFILLS: %d failure(s)" % failures)
 quit(1 if failures else 0)
