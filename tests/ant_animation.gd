extends "res://tests/live_checkpoint.gd"
func run() -> void:
 var g := fixture()
 g.prepare_ant_demo()
 var ant = g.ant
 var skeleton: Skeleton3D = ant.actor.find_child("Skeleton3D", true, false)
 for scenario in [["search",0,"walk"],["carry",1,"carry"],["carry",0,"walk"],["retreat",1,"carry"]]:
  ant.state = scenario[0]
  ant.carrying = scenario[1]
  ant.animation_time = 0.0
  ant.refresh()
  var poses := []
  var bones := []
  for side in [-1,1]:
   for leg in range(3):
    var bone := skeleton.find_bone("leg_%d_%d" % [side,leg])
    bones.append(bone)
    poses.append(skeleton.get_bone_pose_rotation(bone))
  ant.animation_time = .2
  ant.refresh()
  check(str(ant.player.current_animation) == scenario[2], "Correct locomotion clip: " + scenario[0])
  for i in range(bones.size()):
   check(poses[i].angle_to(skeleton.get_bone_pose_rotation(bones[i])) > .04, "Leg actually animates: %s/%d" % [scenario[0],i])
  var paused_pose := skeleton.get_bone_pose_rotation(bones[0])
  for i in range(5): await process_frame
  check(paused_pose.is_equal_approx(skeleton.get_bone_pose_rotation(bones[0])), "Paused game does not advance legs")
 ant.state = "rest"
 ant.carrying = 0
 ant.refresh()
 check(str(ant.player.current_animation) == "search", "Stationary ant uses antenna animation")
 g.queue_free()
 await process_frame
 print("ANT_ANIMATION: %d failure(s)" % failures)
 quit(1 if failures else 0)
