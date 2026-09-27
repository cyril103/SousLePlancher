"""Lot 31: editable ant, rigid-weighted FK/IK-baked rig and four glTF clips.
Reference: docs/catalogue-assets-v01/images/03-fourmis.png.
Blender 2.92, +Y forward / Godot -Z forward. No external dependencies.
"""
import bpy, math, random
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/ant_31'; SRC=ROOT/'art_source/ant_31'
OUT.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
rng=random.Random(1131)
def material(name, color, rough=.45):
 m=bpy.data.materials.new(name);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
 return m
shell=material('Chitin mottled umber',(.065,.039,.018),.36)
# Packed baked color: subtle pores and ochre dust, portable to Compatibility.
image=bpy.data.images.new('ant_chitin',width=256,height=256)
pixels=[]
for y in range(256):
 for x in range(256):
  n=rng.random();dust=.16 if n>.965 else 0
  pixels.extend((.25+n*.10+dust,.18+n*.075+dust*.72,.12+n*.05+dust*.4,1))
image.pixels=pixels;image.filepath_raw=str(OUT/'ant_chitin.png');image.file_format='PNG';image.save();image.pack()
tex=shell.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
shell.node_tree.links.new(tex.outputs['Color'],shell.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
eye=material('Obsidian eyes',(.012,.010,.008),.2)
joint=material('Amber joints',(.14,.07,.027),.48)
hair=material('Fine ochre bristles',(.22,.16,.09),.8)
food=material('Crumb',(.55,.32,.11),.95)
parts=[]
def bind(o,bone):parts.append((o,bone));return o
def ell(name,pos,scale,mat,bone='root'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,radius=1,location=pos)
 o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 for p in o.data.polygons:p.use_smooth=True
 return bind(o,bone)
def rod(name,a,b,r,mat,bone='root',r2=None):
 a,b=Vector(a),Vector(b);d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=r,radius2=r*.65 if r2 is None else r2,depth=d.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
 return bind(o,bone)
ell('Abdomen', (0,-.65,.5),(.32,.47,.29),shell)
ell('Petiole',(0,-.20,.43),(.095,.16,.12),joint)
ell('Thorax',(0,.10,.46),(.21,.32,.22),shell)
ell('Head',(0,.53,.43),(.28,.27,.24),shell,'head')
for side in [-1,1]:
 ell('Compound eye',(side*.239,.59,.49),(.055,.10,.075),eye,'head')
 # Fine shell sutures and short bristles, each rigid weighted to its body part.
 for i in range(16):
  a=i/16*math.tau
  p=(.315*math.cos(a),-.73,.50+.278*math.sin(a))
  rod('Abdominal seam',p,(p[0]*1.01,-.75,p[2]),.006,joint)
 for i in range(24):
  a=rng.uniform(-1.3,1.3);y=rng.uniform(-.94,-.40)
  p=Vector((side*.28*math.cos(a),y,.5+.25*math.sin(a)))
  rod('Sensory bristle',p,p+Vector((side*.035,0,.035)),.0025,hair)
# Bone definitions; limbs built from matching rest endpoints.
bones={'root':(Vector((0,0,0)),Vector((0,0,.4)),None),'head':(Vector((0,.37,.43)),Vector((0,.70,.43)),'root')}
legs=[]
def knee(hip,foot):
 d=foot-hip;dist=d.length;u=d.normalized();l1=.53;l2=.65
 a=(l1*l1-l2*l2+dist*dist)/(2*dist)
 h=math.sqrt(max(.0001,l1*l1-a*a))
 up=Vector((0,0,1));v=(up-u*up.dot(u)).normalized()
 return hip+u*a+v*h
for side in [-1,1]:
 for i,y in enumerate([.29,.06,-.16]):
  name='leg_%s_%s'%(side,i);hip=Vector((side*.16,y,.43));foot=Vector((side*.91,y+(.28 if i==0 else -.27 if i==2 else 0),.025));k=knee(hip,foot)
  bones[name]=(hip,k,'root');bones[name+'_tip']=(k,foot,name)
  rod('Femur',hip,k,.032,shell,name);ell('Knee',k,(.036,.036,.036),joint,name+'_tip');rod('Tibia',k,foot,.022,shell,name+'_tip')
  legs.append((name,hip,foot,side,i))
 for name,points in [('antenna',[(side*.14,.70,.48),(side*.35,1.01,.64),(side*.51,1.32,.44)]),('jaw',[(side*.10,.73,.34),(side*.16,.94,.29),(side*.055,1.02,.29)])]:
  n=name+str(side);a,b,c=map(Vector,points);bones[n]=(a,b,'head')
  rod(name,a,b,.021 if name=='antenna' else .045,joint,n);rod(name,b,c,.013 if name=='antenna' else .029,joint,n)
  if name=='jaw':
   for j in range(3):
    p=b.lerp(c,j/3);rod('Mandible tooth',p,p+Vector((-side*.045,0,0)),.018,joint,n,r2=0)
# Build armature and assign all meshes, including bristles.
bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='AntRig'
bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0])
for name,(a,b,parent) in bones.items():
 bone=rig.data.edit_bones.new(name);bone.head=a;bone.tail=b
 if parent:bone.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for o,bone in parts:
 group=o.vertex_groups.new(name=bone);group.add(list(range(len(o.data.vertices))),1,'REPLACE')
 mod=o.modifiers.new('Ant skeleton','ARMATURE');mod.object=rig;o.parent=rig
# Use matrices for exact two-bone leg targets; tripod gait with planted stance.
scene=bpy.context.scene;scene.render.fps=30
for clip,duration in [('search',2.4),('walk',.8),('carry',1.0),('alert',1.2)]:
 action=bpy.data.actions.new(clip);rig.animation_data_create();rig.animation_data.action=action
 frames=int(duration*30)
 for f in range(0,frames+1,2):
  phase=f/frames;scene.frame_set(f)
  for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
  for name,hip,foot,side,i in legs:
   target=foot.copy()
   if clip in ['walk','carry']:
    t=(phase+(.5 if (i+(1 if side>0 else 0))%2 else 0))%1
    target.y+=(.20-t*.8) if t<.5 else (-.20+(t-.5)*.8)
    if t>=.5:target.z+=math.sin((t-.5)*math.tau)*.14
   k=knee(hip,target)
   for n,a,b in [(name,hip,k),(name+'_tip',k,target)]:
    pb=rig.pose.bones[n];pb.matrix=Matrix.Translation(a)@(b-a).to_track_quat('Y','Z').to_matrix().to_4x4()
    bpy.context.view_layer.update()
  for side in [-1,1]:
   pb=rig.pose.bones['antenna'+str(side)];pb.rotation_mode='XYZ';pb.rotation_euler.z=math.sin(phase*math.tau+side)*(.22 if clip=='search' else .10)
   pb=rig.pose.bones['jaw'+str(side)];pb.rotation_mode='XYZ';pb.rotation_euler.z=side*(.15 if clip=='alert' else -.1 if clip=='carry' else .04*math.sin(phase*math.tau))
  for pb in rig.pose.bones:
   pb.keyframe_insert('location',frame=f);pb.keyframe_insert('rotation_quaternion' if pb.rotation_mode=='QUATERNION' else 'rotation_euler',frame=f);pb.keyframe_insert('scale',frame=f)
 for fc in action.fcurves:
  for kp in fc.keyframe_points:kp.interpolation='LINEAR'
 track=rig.animation_data.nla_tracks.new();track.name=clip;strip=track.strips.new(clip,0,action)
 rig.animation_data.action=None
# Bake all named NLA actions, reset rest view.
scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'ant.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'ant.glb'),export_format='GLB',export_animations=True,export_nla_strips=True)
# Physical crumb carried at the mouth, separate from the skeleton for resource state.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.16,location=(0,0,0));o=bpy.context.object;o.name='Carried crumb';o.scale=(1,.8,.7);o.data.materials.append(food)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'crumb.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'crumb.glb'),export_format='GLB')
# Upright broken skirting provides an actual occluding obstacle near the nest.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
wood=material('Weathered skirting',(.22,.12,.05),.9)
t=wood.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/'assets/textures/reference_02/old_wood_basecolor.png'));wood.node_tree.links.new(t.outputs['Color'],wood.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
bpy.ops.mesh.primitive_cube_add(size=1,location=(4.7,-28.325,.40));o=bpy.context.object;o.name='Ant cover';o.dimensions=(2.4,.25,.8);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(wood)
b=o.modifiers.new('Worn edges','BEVEL');b.width=.035;b.segments=2
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'cover.blend'),compress=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'cover.glb'),export_format='GLB',export_apply=True)
print('ANT_ASSETS_OK')
