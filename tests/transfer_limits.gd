extends "res://tests/transfers.gd"
func settle(g: Node) -> void:
 for i in range(5000):
  step(g)
  if g.transfers.jobs.is_empty() and not g.transfers.blocked(g.transfers.orders[0]).is_empty(): return
 check(false, "Limited transfers settle within bounded time")
func run() -> void:
 var g := fixture()
 g.prepare_transfers_demo()
 var initial := total(g)
 g.hud.transfer_rows[0].reserve.value = 5
 g.hud.transfer_rows[0].target.value = 17
 check(g.transfers.orders[0].reserve == 5 and g.transfers.orders[0].target_stock == 17, "UI controls apply limits to real order")
 check(not g.transfers.set_limits(0, -1, 17), "Negative reserve rejected")
 check(not g.transfers.set_limits(0, 5, -2), "Invalid target rejected")
 # Two porters must reserve exactly five units, not two full crates.
 var saved := false
 for i in range(2000):
  step(g)
  if g.transfers.jobs.size() == 2:
   var reserved := 0
   for job in g.transfers.jobs.values(): reserved += job.quantity
   check(reserved == 5, "Concurrent porters share remaining target quantity")
   saved = true
   var copy := clone(g, "quota reservations")
   if copy != null:
    settle(copy)
    check(copy.stock.wood == 17 and copy.depots.stocks(1).wood == 7, "Saved quota reaches target exactly")
    copy.queue_free()
    await process_frame
   break
 check(saved, "Two concurrent transfers exercised")
 settle(g)
 check(g.stock.wood == 17 and g.depots.stocks(1).wood == 7, "Quota stops before emptying source")
 check(total(g) == initial and g.depots.settled(), "Limited transfer conserves cargo and releases claims")
 # Model consumption; no explicit restart command. The source floor limits the refill.
 g.stock.wood -= 3
 settle(g)
 check(g.stock.wood == 16 and g.depots.stocks(1).wood == 5, "Consumption resumes transfers only down to source reserve")
 check(total(g) == initial - 3, "Only modeled consumption leaves inventory")
 g.transfers.set_limits(0, 0, -1)
 for i in range(2000):
  step(g)
  var loaded := false
  for job in g.transfers.jobs.values(): loaded = loaded or job.collected
  if loaded: break
 check(not g.transfers.jobs.is_empty(), "Removing limits resumes source drain")
 g.transfers.set_limits(0, 9999, 0)
 var copy := clone(g, "lower target during cargo")
 if copy != null:
  settle(copy)
  check(total(copy) == initial - 3, "Lowering limits never deletes committed cargo")
  copy.queue_free()
  await process_frame
 g.transfers.stop(0)
 settle(g)
 check(total(g) == initial - 3 and g.depots.settled(), "Stop returns committed cargo with quotas")
 # External incoming cargo must count, irrespective of which system reserved it.
 g.transfers.set_limits(0, 0, g.stock.wood + 2)
 g.depots.reserve_in("quota_test", {"id": 0, "kind": "wood", "quantity": 2})
 check(g.transfers.missing(g.transfers.orders[0]) == 0, "Other incoming cargo covers target")
 g.depots.release("quota_test")
 var data: Dictionary = g.Save.capture(g)
 var runtime: Dictionary = g.Save.Live.unpack(data.runtime.data)
 runtime.transfers.orders[0].reserve = -1
 data.runtime.data = g.Save.Live.pack(runtime)
 data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
 check(not g.Save.validate(data).is_empty(), "Invalid saved reserve rejected")
 # Migrate a real v18-shaped order without inventing any quota.
 data = g.Save.capture(g)
 data.version = 18
 runtime = g.Save.Live.unpack(data.runtime.data)
 runtime.transfers.orders[0].erase("reserve")
 runtime.transfers.orders[0].erase("target_stock")
 data.runtime.data = g.Save.Live.pack(runtime)
 data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
 check(g.Save.validate(data).is_empty(), "Old transfer orders remain readable")
 data.version = 19
 check(not g.Save.validate(data).is_empty(), "v19 requires both quota fields")
 data.version = 18
 copy = fixture()
 check(copy.apply_checkpoint(data), "v18 restored")
 check(copy.transfers.orders[0].reserve == 0 and copy.transfers.orders[0].target_stock == -1, "v18 keeps unlimited behavior")
 copy.queue_free()
 g.queue_free()
 await process_frame
 print("TRANSFER_LIMITS: %d failure(s)" % failures)
 quit(1 if failures else 0)
