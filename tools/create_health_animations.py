"""Additional baked pulling/care clips, retaining the approved skeleton."""
import bpy, math
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_source/animations_03/resident_animated.blend'))
bpy.context.preferences.filepaths.save_version=0
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
rig.animation_data_clear();rig.animation_data_create()
for a in list(bpy.data.actions):bpy.data.actions.remove(a)
REST={b.name:b.matrix_local.copy() for b in rig.data.bones}
LENGTH={b.name:b.length for b in rig.data.bones};MAX_ERROR={}
source=(ROOT/'tools/create_resident_animations.py').read_text(encoding='utf-8')
exec(source[source.index('def update()'):source.index('CLIPS=') if 'CLIPS=' in source else source.index('CLIPS =')])
scene=bpy.context.scene;scene.render.fps=30
for clip in ['health_pull','health_care','health_place']:
 action=bpy.data.actions.new(clip);action.use_fake_user=True
 for frame in range(61):
  rig.animation_data.action=None;scene.frame_set(frame);t=frame/60
  pose('carry_walk' if clip=='health_pull' else 'idle',t)
  if clip=='health_care':
   rig.pose.bones['root'].matrix=Matrix.Translation((0,0,-.22)) @ rig.pose.bones['root'].matrix;update()
   for s,side in [(-1,'L'),(1,'R')]:
    solve_limb(side+'_thigh',side+'_shin',(s*.13,0,.13),(s*.15,-1,.3),clip)
    orient_bone(side+'_foot',REST[side+'_foot'].to_quaternion())
   orient_bone('spine',Quaternion((1,0,0),.18) @ REST['spine'].to_quaternion())
   orient_bone('head',Quaternion((1,0,0),.24) @ REST['head'].to_quaternion())
  for s,side in [(-1,'L'),(1,'R')]:
   wrist=(s*.32,.20,.85) if clip=='health_pull' else (s*.17,-.37,.73+.025*math.sin(t*math.tau+s))
   solve_limb(side+'_upper_arm',side+'_forearm',wrist,(s*.65,.1,.8),clip)
   orient_bone(side+'_hand',REST[side+'_hand'].to_quaternion())
  if clip=='health_place':
   sleep_pose('floor_rest',0)
   rig.pose.bones['root'].matrix=Matrix.Translation((0,-1.7,0)) @ rig.pose.bones['root'].matrix;update();start=snapshot()
   sleep_pose('sleep',0);end=snapshot();u=smooth(min(1,frame/54))
   for bone in rig.pose.bones:
    la,ra,sa=start[bone.name].decompose();lb,rb,sb=end[bone.name].decompose()
    bone.matrix_basis=Matrix.Translation(la.lerp(lb,u)) @ ra.slerp(rb,u).to_matrix().to_4x4() @ Matrix.Diagonal((*sa.lerp(sb,u),1))
   update()
  rig.animation_data.action=action
  for bone in rig.pose.bones:
   for channel in ['location','rotation_quaternion','scale']:bone.keyframe_insert(channel,frame=frame,group=bone.name)
 for curve in action.fcurves:
  for k in curve.keyframe_points:k.interpolation='LINEAR'
 track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,action);track.mute=True
rig.animation_data.action=None;reset_pose()
for track in rig.animation_data.nla_tracks:track.mute=False
scene.frame_start=0;scene.frame_end=60;scene.frame_set(0)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True);bpy.context.view_layer.objects.active=rig
materials=list(mesh.data.materials);mesh.data.materials.clear() # Animation carrier only; reuse the resident's existing materials in Godot.
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/health_29/rescue_animations.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_nla_strips=True,export_force_sampling=True,export_frame_range=False)
for material in materials:mesh.data.materials.append(material)
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=bpy.data.actions['health_pull'];scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/health_29/rescue_animations.blend'),compress=True)
print('HEALTH_ANIMATIONS_OK')
