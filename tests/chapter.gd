extends "res://tests/live_checkpoint.gd"
const Chapter = preload("res://scripts/first_chapter.gd")
func run() -> void:
 var g := fixture()
 check(Chapter.current(g).completed == 0, "Normal new colony has no invented milestones")
 g._show_tray("goals")
 g._refresh_ui()
 g.hud.chapter_action.pressed.emit()
 check(g.active_tray == "build", "Next action opens actual construction commands")
 g.prepare_ant_demo()
 check(Chapter.delivered(g) == 0, "Prepared kitchen is not a successful delivery")
 g.ant.state = "gather"
 g.ant.pos = g.ant.SOURCE
 g.ant.clock = 3
 g.ant.update(.05)
 check(Chapter.delivered(g) == 0, "Ant pickup is not credited to colony")
 check(g.kitchen.designate_food(), "Normal food order starts")
 var loaded := false
 var arrived := false
 for i in range(14000):
  step(g)
  for id in g.kitchen.tasks:
   var t: Dictionary = g.kitchen.tasks[id]
   if t.kind == "food" and t.collected and not t.deposited and not loaded:
    loaded = true
    check(Chapter.delivered(g) == 0, "Carried crate is not yet a delivery")
    var other := clone(g, "chapter loaded")
    if other != null:
     check(Chapter.current(other) == Chapter.current(g), "Guidance survives JSON reload exactly")
     other.kitchen.designate_food()
     for j in range(6000):
      step(other)
      if other.kitchen.tasks.is_empty(): break
     check(Chapter.delivered(other) > 0, "Recall preserves cargo and completes delivery milestone")
     other.queue_free()
     await process_frame
  if Chapter.delivered(g) > 0:
   arrived = true
   break
 check(loaded and arrived, "Real kitchen round trip reaches chapter milestone")
 var saved := clone(g, "chapter delivered")
 if saved != null:
  check(Chapter.delivered(saved) == Chapter.delivered(g), "Delivered progress survives save")
  saved.queue_free()
 g.queue_free()
 await process_frame
 print("CHAPTER: %d failure(s)" % failures)
 quit(1 if failures else 0)
