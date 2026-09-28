extends "res://tests/live_checkpoint.gd"
func run() -> void:
 for mission in ["inspect", "equip"]:
  var g := fixture()
  g.start_panel.hide()
  g._toggle_hide()
  for i in range(900): g.simulate(.05)
  var c: WorkerDelivery = g.workers[0].delivery
  check(c.inside_refuge, "Resident starts inside refuge")
  # Resume without a simulation tick, then command a mission before departure.
  g._toggle_hide()
  if mission == "inspect":
   check(g.fissure.start(0, true), "Inspection accepted from refuge")
  else:
   g.torches.add_item(g.depots.entry(0), 180, "lantern")
   check(g.torches.equip(0, "lantern"), "Equipment pickup accepted from refuge")
  for i in range(200):
   g.simulate(.05)
   if c.door_active and c.door_index == 1: break
  check(c.door_active, "Mission crosses real doorway")
  var committed: PackedVector3Array = c.door_route.duplicate()
  var before: Vector3 = c.actor.position
  g._toggle_hide()
  check(c.door_route == committed and c.actor.position == before, "Recall preserves committed crossing without teleport")
  var restored := clone(g, "recall during door " + mission)
  if restored != null:
   g.queue_free()
   await process_frame
   g = restored
   c = g.workers[0].delivery
  for i in range(1000):
   g.simulate(.05)
   if c.inside_refuge and not c.door_active and c.state == "idle": break
  check(c.inside_refuge and c.actor.position.distance_to(g.refuge.slot(0)) < .01, "Mission recall returns resident to interior slot")
  check(not g.fissure.occupied(0) and not g.torches.occupied(0), "Cancelled mission releases its reservations")
  g.queue_free()
  await process_frame
 print("DOOR_TASK_RECALL: %d failure(s)" % failures)
 quit(1 if failures else 0)
