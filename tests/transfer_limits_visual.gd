extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, suffix: String) -> void:
 g._refresh_ui()
 for i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/transfer_limits_" + suffix + ".png")
func run() -> void:
 var g = load("res://scenes/main.tscn").instantiate()
 g.set_meta("restore_mode", true)
 root.add_child(g)
 g.set_process(false)
 g.prepare_transfer_limits_demo()
 await shot(g, "start")
 for i in range(4000):
  g.simulate(.05)
  g.suspicion = 0
  if g.stock.wood == 17 and g.transfers.jobs.is_empty(): break
 await shot(g, "target")
 g.queue_free()
 await process_frame
 print("TRANSFER_LIMITS_VISUAL_OK")
 quit()
