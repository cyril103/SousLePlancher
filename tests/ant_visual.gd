extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(g: Node, title: String) -> void:
 g._update_camera()
 g._refresh_ui()
 for i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/ant_" + title + ".png")
func run() -> void:
 var g=load("res://scenes/main.tscn").instantiate()
 g.set_meta("restore_mode",true)
 root.add_child(g)
 g.set_process(false)
 g.prepare_ant_demo()
 g._show_tray("")
 g.hud.hide()
 for stage in ["search", "gather", "carry", "rest"]:
  for i in range(1800):
   g.simulate(.05)
   g.suspicion=0
   if g.ant.state==stage: break
  for i in range(6): g.simulate(.05)
  g.focus=g.ant.pos
  g.zoom=5
  await shot(g,stage)
 g.hud.show()
 g.focus=Vector3(5,0,26)
 g.zoom=18
 g._show_tray("kitchen")
 await shot(g,"overview")
 print("ANT_VISUAL_OK")
 g.queue_free()
 await process_frame
 quit()
