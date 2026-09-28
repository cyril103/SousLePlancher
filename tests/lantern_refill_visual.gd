extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, suffix: String) -> void:
 g._refresh_ui()
 for i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/lantern_refill_" + suffix + ".png")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 g.set_meta("restore_mode", true)
 root.add_child(g)
 g.set_process(false)
 g.prepare_lantern_refill_demo()
 await shot(g, "order")
 for i in range(1800):
  g.simulate(.05)
  g.suspicion = 0
  if g.torches.orders[0].work >= 3: break
 await shot(g, "work")
 for i in range(1800):
  g.simulate(.05)
  g.suspicion = 0
  if g.torches.orders[0].built: break
 await shot(g, "ready")
 g.queue_free()
 await process_frame
 print("LANTERN_REFILL_VISUAL_OK")
 quit()
