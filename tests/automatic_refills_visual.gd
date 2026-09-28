extends "res://tests/lantern_refill_visual.gd"
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 g.set_meta("restore_mode", true)
 root.add_child(g)
 g.set_process(false)
 g.prepare_auto_refills_demo()
 await shot(g, "automatic_order")
 for i in range(2400):
  g.simulate(.05)
  g.suspicion = 0
  if g.torches.ready_lanterns() == 2: break
 await shot(g, "automatic_ready")
 g.queue_free()
 await process_frame
 print("AUTOMATIC_REFILLS_VISUAL_OK")
 quit()
