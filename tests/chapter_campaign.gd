extends "res://tests/live_checkpoint.gd"
const Chapter = preload("res://scripts/first_chapter.gd")
var resumed := false
var auto_refills := "--auto-refills" in OS.get_cmdline_user_args()
var reuse_lanterns := "--reuse-lanterns" in OS.get_cmdline_user_args()
var last_progress := -1
var peak_suspicion := 0.0
var recalls := 0

func manage(g: Node) -> void:
 # A scripted player uses only ordinary commands. Simulation, needs and stocks are untouched.
 var phase := fmod(float(g.elapsed), 100.0)
 if not g.hiding and phase >= 68 and phase < 88 and g.suspicion > 50:
  g._toggle_hide()
  recalls += 1
 elif g.hiding and phase >= 88:
  g._toggle_hide()
 if g.hiding: return
 # Keep two local gatherers, release their assignments once enough supplies are stored.
 for pair in [[0, 2, "wood", 22], [1, 4, "fiber", 18]]:
  var w: Dictionary = g.workers[pair[0]]
  if w.patch >= 0 and g.depots.total(pair[2]) >= pair[3]:
   g.selected = w.patch
   g.release_worker()
  elif w.patch < 0 and g.depots.total(pair[2]) < pair[3] - 6:
   g.selected = pair[1]
   g.assign_worker(pair[0])
 if g.sleeping.beds.is_empty():
  g._choose_build("bed")
  g._place_build(Vector3(-3, 0, -4))
 if g.sleeping.ready_count() == 0: return
 if g.workshops == 0:
  g._choose_build("workshop")
  g._place_build(Vector3(0, 0, -3))
  return
 var fresh := 0
 for item in g.torches.items:
  if item.kind == "lantern" and item.fuel >= 150 and item.owner < 0 and item.reserved < 0: fresh += 1
 if auto_refills: g.torches.set_refill_target(2)
 if fresh < 2:
  var servicing := false
  for order in g.torches.orders:
   if not order.built and order.get("refill", -1) >= 0: servicing = true
  if auto_refills:
   if g.torches.items.size() < 2: g.torches.request_craft("lantern")
  elif reuse_lanterns and (servicing or g.torches.refill_candidate() >= 0):
   if not servicing: g.torches.request_refill()
  else: g.torches.request_craft("lantern")
 if g.torches.items.is_empty(): return
 if not g.fissure.discovered:
  for id in [2, 3]:
   if g.torches.available(g.workers[id].delivery):
    g.fissure.start(id, true)
    break
 elif not g.fissure.opened():
  if g.fissure.site.is_empty(): g.fissure.request_build()
 elif not g.fissure.visited:
  if g.fissure.missions.is_empty():
   for id in [2, 3]:
    if g.torches.can_haul(id):
     g.fissure.start(id)
     break
    if g.torches.available(g.workers[id].delivery) and not g.torches.occupied(id):
     g.torches.equip(id, "lantern")
     break
 elif not g.fissure.widened():
  if g.fissure.upgrade.is_empty() and g.fissure.missions.is_empty(): g.fissure.request_upgrade()
 elif not g.kitchen.known:
  if not g.kitchen.scout: g.kitchen.request_scout()
 elif not g.kitchen.built:
  if not g.kitchen.planned: g.kitchen.plan()
 elif not g.kitchen.harvest:
  g.kitchen.designate_food()

func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 root.add_child(g)
 g.set_process(false)
 g.start_panel.hide()
 for i in range(36000):
  if i % 20 == 0: manage(g)
  g.simulate(.05)
  peak_suspicion = maxf(peak_suspicion, g.suspicion)
  var progress: int = Chapter.current(g).completed
  if progress != last_progress:
   last_progress = progress
   print("CAMPAIGN t=", snappedf(g.elapsed, .1), " progress=", progress, " stock=", g.stock)
  if not resumed:
   var loaded := false
   for task in g.kitchen.tasks.values():
    if task.kind == "food" and task.collected and not task.deposited: loaded = true
   if loaded:
    var other := clone(g, "normal campaign loaded provisions")
    if other != null:
     check(Chapter.delivered(other) == 0, "Loaded expedition is not credited before arrival")
     g.queue_free()
     await process_frame
     g = other
     g.paused = false
     resumed = true
  if g.ended or Chapter.delivered(g) > 0: break
 check(resumed, "Normal campaign resumes from a loaded expedition saved to JSON")
 check(not g.ended, "Ordinary human cycles remain survivable")
 check(Chapter.current(g).completed == 10, "All chapter milestones reached from a normal new game")
 print("EQUIPMENT lanterns=",g.torches.items.size()," maintenance=",reuse_lanterns," automatic=",auto_refills)
 print("CAMPAIGN END t=", g.elapsed, " peak_suspicion=", peak_suspicion, " recalls=", recalls, " kitchen=", g.kitchen.summary())
 if failures:
  for w in g.workers: print("WORKER ",w.delivery.owner, " ", w.delivery.state, " needs=",w.energy,"/",w.nutrition,"/",w.hydration, " patch=",w.patch)
  print("FISSURE ",g.fissure.summary(), " LIGHTS ",g.torches.items.size())
 g.queue_free()
 await process_frame
 print("CAMPAIGN: %d failure(s)" % failures)
 quit(1 if failures else 0)
