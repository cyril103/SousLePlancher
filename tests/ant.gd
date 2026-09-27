extends "res://tests/live_checkpoint.gd"
func balance(g: Node) -> int:
 var result: int = g.kitchen.amount + g.ant.carrying + g.ant.stored
 for w in g.workers:
  if w.kind == "food": result += w.carrying
 return result
func run() -> void:
 var g := fixture()
 g.prepare_ant_demo()
 check(g.ant.clips.size() == 4, "Four Blender animation clips imported")
 # Visibility cannot cross the physical upright skirting, even within perception range.
 g.ant.pos = Vector3(4.7,-.0105,29)
 check(not g.ant.perceives(Vector3(4.7,-.0105,27.7)), "Skirting blocks nearby perception")
 check(g.ant.perceives(Vector3(5.5,-.0105,29)), "Same side of cover is perceivable")
 check(not g.ant.perceives(Vector3(4.7,-.0105,24)), "Perception has a local range")
 g.ant.pos = g.ant.NEST
 var copied := {}
 for i in range(2400):
  step(g)
  check(balance(g) == 36, "Ant source/cargo/nest conserve finite food")
  if g.ant.state in ["gather", "carry", "rest"] and not copied.has(g.ant.state):
   copied[g.ant.state] = true
   var other := clone(g,"ant " + g.ant.state)
   if other != null:
    check(other.ant.snapshot() == g.ant.snapshot(), "All AI and animation state restored exactly")
    for j in range(100):
     step(g); step(other)
     check(other.ant.snapshot() == g.ant.snapshot(), "Resumed ant follows same simulation")
    other.queue_free()
    await process_frame
  if g.ant.stored >= 2: break
 check(g.ant.stored >= 2 and copied.has("carry"), "Ant physically transports crumbs to nest")
 # Local reaction, then exact JSON restore while alert; no fake worker survives the fixture.
 var c: WorkerDelivery = g.workers[0].delivery
 var old_pos: Vector3 = c.actor.position
 var old_sector: String = c.sector_id
 var old_visible: bool = c.actor.visible
 g.ant.pos = g.ant.SOURCE
 g.ant.state = "gather"
 g.ant.carrying = 0
 c.sector_id = "kitchen"
 c.actor.position = g.ant.pos + Vector3(-2,0,0)
 c.actor.show()
 g.ant.update(.05)
 check(g.ant.state == "alert", "Nearby visible worker triggers local alert")
 c.actor.position = old_pos
 c.sector_id = old_sector
 c.actor.visible = old_visible
 var alert_copy := clone(g,"local alert")
 if alert_copy != null:
  for j in range(1200):
   step(alert_copy)
   if alert_copy.ant.state == "rest": break
  check(alert_copy.ant.state == "rest", "Alert resumes and retreats without chase")
  alert_copy.queue_free()
  await process_frame
 # A full reservation prevents stealing even at the exact pickup boundary.
 var before: int = g.kitchen.amount
 g.ant.pos = g.ant.SOURCE
 g.ant.state = "gather"
 g.ant.clock = 2.99
 g.ant.carrying = 0
 g.kitchen.reserved = g.kitchen.amount
 g.ant.update(.05)
 check(g.kitchen.amount == before and g.ant.carrying == 0, "Reserved crumbs cannot be stolen")
 g.kitchen.reserved = 0
 g.queue_free()
 await process_frame
 # Normal autonomous workers, both approach policies, recalls and JSON snapshots.
 for policy in ["wait", "detour"]:
  g = fixture()
  g.prepare_ant_demo()
  g.ant.policy = policy
  check(g.kitchen.designate_food(), "Harvest designation accepted")
  var delivered := false
  var waiting := false
  var saved := false
  var alerts := false
  var placed_encounter := false
  for i in range(12000):
   step(g)
   if g.ant.state == "alert": alerts = true
   for id in g.kitchen.tasks.keys():
    var t: Dictionary = g.kitchen.tasks[id]
    # Place the animal on an actual outbound worker's approach to exercise the contention boundary.
    if policy == "wait" and not placed_encounter and t.stage == "food_walk":
     placed_encounter = true
     g.ant.pos = g.workers[id].node.position + Vector3(2.5,0,0)
     g.ant.state = "gather"
     g.ant.clock = 0.0
     g.ant.carrying = 0
    waiting = waiting or float(t.get("ant_wait",0)) > 0
    if t.deposited: delivered = true
    if not saved and (float(t.get("ant_wait",0)) > 0 or (t.kind == "food" and t.collected)):
     saved = true
     var other := clone(g,"ant encounter " + policy)
     if other != null:
      other.kitchen.designate_food()
      for j in range(5000):
       step(other)
       if other.kitchen.tasks.is_empty(): break
      check(other.kitchen.tasks.is_empty(), "Recall during encounter or transport returns every worker")
      check(other.kitchen.owner == -1 and other.kitchen.queue.is_empty(), "Recall releases bridge")
      check(other.kitchen.reserved == 0, "Recall releases source claims")
      other.queue_free()
      await process_frame
   if delivered and saved: break
  check(delivered and saved, "Harvest completes with live ant: " + policy)
  if policy == "wait": check(waiting and alerts, "Real expedition waits through local alert")
  print("APPROACH ",policy," waiting=",waiting," alert=",alerts," encounters=",g.ant.encounters)
  var snapshot: Dictionary = g.Save.capture(g)
  var live: Dictionary = g.Save.Live.unpack(snapshot.runtime.data)
  live.ant.carrying = 2
  snapshot.runtime.data = g.Save.Live.pack(live)
  snapshot.runtime.sha256 = JSON.stringify(snapshot.runtime.data).sha256_text()
  check(not g.Save.validate(snapshot).is_empty(), "Invalid animal cargo rejected")
  # v17 had no ant; migration initializes a new forager without altering kitchen stock.
  snapshot = g.Save.capture(g)
  snapshot.version = 17
  live = g.Save.Live.unpack(snapshot.runtime.data)
  live.erase("ant")
  snapshot.runtime.data = g.Save.Live.pack(live)
  snapshot.runtime.sha256 = JSON.stringify(snapshot.runtime.data).sha256_text()
  check(g.Save.validate(snapshot).is_empty(), "v17 migration accepted")
  var migrated := fixture()
  check(migrated.apply_checkpoint(snapshot), "v17 restores")
  check(migrated.ant.stored == 0 and migrated.kitchen.amount == g.kitchen.amount, "v17 does not invent or deduct resources")
  migrated.queue_free()
  g.queue_free()
  await process_frame
 print("ANT: %d failure(s)" % failures)
 quit(1 if failures else 0)
