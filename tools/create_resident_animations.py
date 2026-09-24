"""Author contact-driven skeletal loops and bake them to glTF.

Source: approved resident reference. Animation poses are solved in Blender;
Godot plays the baked clips and moves the actor at their documented speed.
"""
import bpy
import math
import json
import time
import uuid
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art_source'/'animations_03'
EXPORT=ROOT/'assets'/'models'/'animations_03'
for p in [SOURCE,EXPORT]:p.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_source/reference_01/resident_reference.blend'))
bpy.context.preferences.filepaths.save_version=0
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
# Reference pieces had name-based rigid bindings: Blender's duplicate-name
# renaming could associate a left piece with a right bone. Rebind connected
# garment islands geometrically and blend the boot ankle for bent poses.
adj=[[] for v in mesh.data.vertices]
for edge in mesh.data.edges:
    a,b=edge.vertices;adj[a].append(b);adj[b].append(a)
seen=set()
for vertex in mesh.data.vertices:
    if vertex.index in seen:continue
    pending=[vertex.index];seen.add(vertex.index);island=[]
    while pending:
        i=pending.pop();island.append(i)
        for j in adj[i]:
            if j not in seen:seen.add(j);pending.append(j)
    center=sum((mesh.data.vertices[i].co for i in island),Vector())/len(island)
    side='L' if center.x<0 else 'R'
    bone=None
    if abs(center.x)>.18 and .68<center.z<1.23:
        bone=side+('_upper_arm' if center.z>1.0 else '_forearm' if center.z>.82 else '_hand')
    boot=.045<abs(center.x)<.19 and center.z<.30
    if bone or boot:
        for group in mesh.vertex_groups:group.remove(island)
        if bone:
            group=mesh.vertex_groups.get(bone) or mesh.vertex_groups.new(name=bone)
            group.add(island,1,'REPLACE')
        else:
            foot=mesh.vertex_groups.get(side+'_foot') or mesh.vertex_groups.new(name=side+'_foot')
            shin=mesh.vertex_groups.get(side+'_shin') or mesh.vertex_groups.new(name=side+'_shin')
            for i in island:
                w=max(0,min(1,(mesh.data.vertices[i].co.z-.13)/.12))
                if w<1:foot.add([i],1-w,'REPLACE')
                if w>0:shin.add([i],w,'REPLACE')
rig.animation_data_clear()
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,head,tail,parent in [
    ('socket_carry',(0,-.29,.89),(0,-.29,.95),'spine'),
    ('socket_tool',(.309,-.031,.755),(.309,-.091,.755),'R_hand')]:
    bone=rig.data.edit_bones.new(name);bone.head=head;bone.tail=tail
    bone.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
rig.animation_data_create()
scene=bpy.context.scene;scene.render.fps=30
REST={b.name:b.matrix_local.copy() for b in rig.data.bones}
LENGTH={b.name:b.length for b in rig.data.bones}
MAX_ERROR={}


def update():bpy.context.view_layer.update()


def reset_pose():
    for bone in rig.pose.bones:
        bone.rotation_mode='QUATERNION'
        bone.matrix_basis=Matrix.Identity(4)
    update()


def position_bone(name,head,tail):
    bone=rig.data.bones[name]
    rotation=(bone.tail_local-bone.head_local).rotation_difference(Vector(tail)-Vector(head)) @ REST[name].to_quaternion()
    rig.pose.bones[name].matrix=Matrix.Translation(head) @ rotation.to_matrix().to_4x4()
    update()


def orient_bone(name,rotation):
    pose=rig.pose.bones[name]
    pose.matrix=Matrix.Translation(pose.head.copy()) @ rotation.to_matrix().to_4x4()
    update()


def solve_limb(upper,lower,target,pole,clip):
    origin=rig.pose.bones[upper].head.copy()
    delta=Vector(target)-origin
    requested=delta.length
    a,b=LENGTH[upper],LENGTH[lower]
    distance=max(abs(a-b)+.001,min(a+b-.001,requested))
    direction=delta.normalized()
    bend=Vector(pole)-origin
    bend=(bend-direction*bend.dot(direction)).normalized()
    along=(a*a-b*b+distance*distance)/(2*distance)
    height=math.sqrt(max(0,a*a-along*along))
    knee=origin+direction*along+bend*height
    end=origin+direction*distance
    position_bone(upper,origin,knee)
    position_bone(lower,knee,end)
    MAX_ERROR[clip]=max(MAX_ERROR.get(clip,0),abs(requested-distance))


def smooth(t):return t*t*(3-2*t)


def ground_step(phase,half_span,stance,lift):
    if phase<stance:
        return -.0-half_span+2*half_span*phase/stance, .13
    u=(phase-stance)/(1-stance)
    return half_span-2*half_span*smooth(u), .13+lift*math.sin(math.pi*u)


def climb_contact(phase,base):
    if phase<.65:
        return base-.51*phase, 0.0
    u=(phase-.65)/.35
    return base-.51*.65+.51*.65*smooth(u), .07*math.sin(math.pi*u)


def pose(clip,t):
    reset_pose()
    if clip in ['walk','carry_walk']:
        bob=-.045+.009*math.cos(4*math.pi*t)
    elif clip=='climb':bob=0.0
    else:bob=.003*math.sin(2*math.pi*t)
    rig.pose.bones['root'].matrix=Matrix.Translation((0,0,bob)) @ REST['root']
    update()
    lean={'walk':.035,'carry_walk':.055,'work':.09,'climb':.025,'idle':.007}.get(clip,0)
    lean+=.007*math.sin(2*math.pi*t)
    orient_bone('spine',Quaternion((1,0,0),lean) @ REST['spine'].to_quaternion())
    if clip=='work':
        orient_bone('head',Quaternion((1,0,0),.14) @ REST['head'].to_quaternion())
    for sign,side,offset in [(-1,'L',0),(1,'R',.5)]:
        p=(t+offset)%1
        if clip=='walk':
            fy,fz=ground_step(p,.20,.60,.075)
        elif clip=='carry_walk':
            fy,fz=ground_step(p,.17,.66,.055)
        elif clip=='climb':
            fz,retract=climb_contact(p,.585)
            fy=.03-.19*(fz-.13)+retract
        else:fy,fz=0,.13
        solve_limb(side+'_thigh',side+'_shin',(sign*.11,fy,fz),(sign*.12,-1,.42),clip)
        orient_bone(side+'_foot',REST[side+'_foot'].to_quaternion())
        if clip=='walk':
            wrist=(sign*.302,.085*math.sin(2*math.pi*p),.795+bob+.017*math.cos(2*math.pi*p))
        elif clip=='carry_walk':
            wrist=(sign*.235,-.268,1.005+bob)
        elif clip=='work':
            if side=='R':
                # Fast downstroke, brief contact, slower recovery.
                impact=max(0,math.sin(math.pi*min(t/.38,1))) if t<.38 else 0
                recovery=smooth((t-.52)/.48) if t>.52 else 0
                height=.18*(1-smooth(t/.28)) if t<.28 else .18*recovery
                wrist=(.22,-.29-.025*impact,1.043+height+bob)
            else:wrist=(-.23,-.27,1.015+bob)
        elif clip=='climb':
            hz,retract=climb_contact((p+.12)%1,1.295)
            hy=-.015-.19*(hz-.076)+retract
            wrist=(sign*.25,hy,hz)
        else:wrist=(sign*.304,-.026,.791+bob)
        solve_limb(side+'_upper_arm',side+'_forearm',wrist,(sign*.8,.15,.93+bob),clip)
        orient_bone(side+'_hand',REST[side+'_hand'].to_quaternion())
    update()


def snapshot():return {b.name:b.matrix_basis.copy() for b in rig.pose.bones}


def transition_pose(clip,t):
    if clip in ['pick_up','put_down']:
        if clip=='put_down':t=1-t
        pose('idle',0);start=snapshot()
        pose('carry_walk',0)
        # Stable carrying stance, independent of the walking phase.
        for s,side in [(-1,'L'),(1,'R')]:
            solve_limb(side+'_thigh',side+'_shin',(s*.11,0,.13),(s*.12,-1,.42),clip)
            orient_bone(side+'_foot',REST[side+'_foot'].to_quaternion())
        hold=snapshot()
        rig.pose.bones['root'].matrix=Matrix.Translation((0,0,-.30)) @ rig.pose.bones['root'].matrix
        update()
        for s,side in [(-1,'L'),(1,'R')]:
            solve_limb(side+'_thigh',side+'_shin',(s*.11,0,.13),(s*.12,-1,.42),clip)
            orient_bone(side+'_foot',REST[side+'_foot'].to_quaternion())
        contact=snapshot()
        if t<.4:a,b,u=start,contact,smooth(t/.4)
        else:a,b,u=contact,hold,smooth((t-.4)/.6)
    else:
        pose('climb',0);climb=snapshot()
        pose('idle',0)
        if clip=='climb_exit':
            # Authored root displacement onto the landing, consumed by caller.
            rig.pose.bones['root'].matrix=Matrix.Translation((0,-.45,.51)) @ REST['root']
            update()
        standing=snapshot()
        a,b=(standing,climb) if clip=='climb_enter' else (climb,standing)
        u=smooth(t)
    for bone in rig.pose.bones:
        la,ra,sa=a[bone.name].decompose();lb,rb,sb=b[bone.name].decompose()
        scale=sa.lerp(sb,u)
        bone.matrix_basis=Matrix.Translation(la.lerp(lb,u)) @ ra.slerp(rb,u).to_matrix().to_4x4() @ Matrix.Diagonal((*scale,1))
    update()
    if clip in ['climb_enter','climb_exit']:
        # Stagger the two foot transfers instead of sliding both feet together.
        for s,side,p in [(-1,'L',0),(1,'R',.5)]:
            z,_=climb_contact(p,.585)
            y=.03-.19*(z-.13)
            rung=Vector((s*.11,y,z))
            standing=Vector((s*.11,0,.13)) if clip=='climb_enter' else Vector((s*.11,-.45,.64))
            begin,end=(standing,rung) if clip=='climb_enter' else (rung,standing)
            start,stop=(.12,.72) if side=='L' else (.25,.90)
            fraction=max(0,min(1,(t-start)/(stop-start)))
            target=begin.lerp(end,smooth(fraction))
            target.z+=.07*math.sin(math.pi*fraction)
            solve_limb(side+'_thigh',side+'_shin',target,(s*.12,-1,.42),clip)
            orient_bone(side+'_foot',REST[side+'_foot'].to_quaternion())
        update()


CLIPS={
    'idle':{'frames':120,'loop':True,'speed':0},
    'walk':{'frames':36,'loop':True,'speed':.4/(.60*1.2),'stance':.60,'distance_per_cycle':.4/.60},
    'carry_walk':{'frames':42,'loop':True,'speed':.34/(.66*1.4),'stance':.66,'distance_per_cycle':.34/.66},
    'work':{'frames':36,'loop':True,'speed':0,'impact_seconds':.28*1.2},
    'climb':{'frames':48,'loop':True,'speed':.51/1.6,'rise_per_cycle':.51,'rung_spacing':.255},
    'pick_up':{'frames':54,'loop':False,'speed':0,'contact_seconds':.72},
    'put_down':{'frames':54,'loop':False,'speed':0,'contact_seconds':1.08},
    'climb_enter':{'frames':36,'loop':False,'speed':0},
    'climb_exit':{'frames':42,'loop':False,'speed':0,'root_displacement_godot':[0,.51,.45]},
}
for clip,info in CLIPS.items():
    action=bpy.data.actions.new(clip);action.use_fake_user=True
    rig.animation_data.action=action
    for frame in range(info['frames']+1):
        rig.animation_data.action=None
        scene.frame_set(frame)
        if clip in ['pick_up','put_down','climb_enter','climb_exit']:
            transition_pose(clip,frame/info['frames'])
        else:pose(clip,frame/info['frames'])
        rig.animation_data.action=action
        for bone in rig.pose.bones:
            for channel in ['location','rotation_quaternion','scale']:
                bone.keyframe_insert(channel,frame=frame,group=bone.name)
    for curve in action.fcurves:
        for key in curve.keyframe_points:key.interpolation='LINEAR'
    info['duration']=info['frames']/30
    info['maximum_reach_clamp']=round(MAX_ERROR.get(clip,0),6)
    # NLA track names become explicit glTF clip names.
    track=rig.animation_data.nla_tracks.new();track.name=clip
    track.strips.new(clip,0,action)
    track.mute=True
rig.animation_data.action=None
reset_pose()
scene.frame_start=0;scene.frame_end=120;scene.frame_set(0)
for track in rig.animation_data.nla_tracks:track.mute=False
# The exporter evaluates each NLA track independently. Avoid playing a stack
# of all clips in Blender by muting after export, not while exporting.
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);mesh.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'resident_animated.glb'),export_format='GLB',use_selection=True,
    export_yup=True,export_animations=True,export_nla_strips=True,export_force_sampling=True,export_frame_range=False)
for track in rig.animation_data.nla_tracks:track.mute=True
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(0)


def save(path):
    staged=path.with_name(path.stem+'_'+uuid.uuid4().hex+'.staging.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(staged),compress=True)
    for attempt in range(10):
        try:staged.replace(path);return
        except PermissionError:
            if attempt==9:raise
            time.sleep(.3)


save(SOURCE/'resident_animated.blend')
report={'source':'art_source/reference_01/resident_reference.blend','fps':30,'clips':CLIPS,
    'rig_bones':len(rig.data.bones),'motion':'cycles in place; climb_exit includes documented local root displacement',
    'attachments':['socket_carry','socket_tool'],'limits':['No finger rig','No navigation integration','Transitions authored for fixed staging geometry']}
(SOURCE/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

# Hand-held hammer: origin at grip, shaft along local +Y after glTF export.
wood=next(m for m in bpy.data.materials if 'leather' in m.name.lower() and m.use_nodes)
metal=next(m for m in bpy.data.materials if 'brass' in m.name.lower() and m.use_nodes)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for name,loc,scale,mat in [('Hammer grip',(0,0,.085),(.026,.026,.20),wood),('Hammer head',(0,0,.19),(.16,.052,.050),metal)]:
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    obj=bpy.context.object;obj.name=name;obj.dimensions=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(mat)
    mod=obj.modifiers.new('Worn edges','BEVEL');mod.width=.008;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.join()
bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
save(SOURCE/'hand_hammer.blend')
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'hand_hammer.glb'),export_format='GLB',export_animations=False)
print('RESIDENT_ANIMATIONS_OK',json.dumps(report))
