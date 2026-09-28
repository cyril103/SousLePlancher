extends "res://tests/live_checkpoint.gd"
func advance(g: Node, count: int) -> void:
 for i in range(count): step(g)
func run() -> void:
 var g := fixture()
 g.start_panel.hide()
 g._choose_build("workshop")
 check(g._place_build(Vector3(0, 0, -3)), "Workshop built using initial stock")
 g.torches.add_item(g.depots.entry(0), 20, "lantern")
 var wood: int = g.stock.wood
 var fiber: int = g.stock.fiber
 check(g.torches.request_refill(), "Stored lantern maintenance ordered")
 check(g.stock.wood == wood and g.torches.items[0].fuel == 20, "Order does not consume stock or refill remotely")
 check(not g.torches.request_refill(), "Duplicate maintenance refused")
 check(not g.torches.equip(0, "lantern"), "Maintenance reserves lantern from equipment pickup")
 var phases := {}
 var interrupted := false
 for i in range(2400):
  step(g)
  var site: Dictionary = g.torches.orders[0]
  var phase := ""
  if not g.construction.jobs.is_empty(): phase = "delivery"
  if site.work > 0 and not site.built: phase = "work"
  if site.built: phase = "complete"
  if not phase.is_empty() and not phases.has(phase):
   phases[phase] = true
   var copy := clone(g, "lantern refill " + phase)
   if copy != null:
    advance(copy, 1600)
    check(copy.torches.items.size() == 1 and copy.torches.items[0].fuel == 180, "Restored maintenance refills existing equipment once")
    check(copy.stock.wood == wood - 2 and copy.stock.fiber == fiber, "Restored maintenance consumes exactly two wood, no fiber")
    copy.queue_free()
    await process_frame
  if phase == "work" and not interrupted:
   interrupted = true
   var paused_work: float = site.work
   g.paused = true
   g._process(.5)
   check(site.work == paused_work, "Pause freezes maintenance")
   g._toggle_hide()
   var work: float = site.work
   advance(g, 80)
   check(site.work == work and g.torches.items[0].fuel == 20, "Recall suspends work and preserves original fuel")
   g._toggle_hide()
  if site.built: break
 check(phases.has("delivery") and phases.has("work") and phases.has("complete"), "Physical supply, maintenance and completion all exercised")
 check(g.torches.items.size() == 1 and g.torches.items[0].fuel == 180, "No duplicate lantern created")
 check(g.stock.wood == wood - 2 and g.stock.fiber == fiber, "Fuel cost paid once through delivery")
 check(not g.torches.request_refill(), "Full lantern cannot be refilled")
 advance(g, 800)
 check(g.torches.equip(0, "lantern"), "Refilled lantern can be equipped")
 for i in range(600):
  step(g)
  if g.torches.held(0) >= 0: break
 check(g.torches.held(0) == 0, "Original lantern reused by a resident")
 g.torches.items[0].fuel = 30
 check(not g.torches.request_refill(), "Carried lantern cannot be refilled remotely")
 g.torches.recall(g.workers[0].delivery)
 advance(g, 1000)
 check(g.torches.request_refill(), "Returned lantern can be maintained again")
 # No wood left: persistent pending order, no free fuel.
 advance(g, 200)
 check(not g.torches.orders[-1].built, "Missing wood blocks maintenance")
 var data: Dictionary = g.Save.capture(g)
 var r: Dictionary = g.Save.Live.unpack(data.runtime.data)
 r.orders[-1].refill = 999
 data.runtime.data = g.Save.Live.pack(r)
 data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
 check(not g.Save.validate(data).is_empty(), "Invalid runtime lantern target rejected")
 var waiting := clone(g, "maintenance missing fuel")
 if waiting != null: waiting.queue_free()
 g.queue_free()
 await process_frame
 # Old version: ordinary equipment and craft orders retain their previous behavior.
 g = fixture()
 var old: Dictionary = g.Save.capture(g)
 old.version = 19
 check(g.Save.validate(old).is_empty(), "v19 without maintenance remains readable")
 var migrated := fixture()
 check(migrated.apply_checkpoint(old), "v19 migration applies")
 migrated.queue_free()
 g.queue_free()
 await process_frame
 print("LANTERN_REFILL: %d failure(s)" % failures)
 quit(1 if failures else 0)
