"""Blender 2.93: first art reference lot, independent of the prototype assets.
Run: blender --background --python tools/create_reference_assets.py
Geometry is authored in Blender; reference_02 materials use image_gen atlases.
"""
import bpy
import math
import random
import json
import sys
import time
import uuid
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art_source' / 'reference_01'
EXPORT = ROOT / 'assets' / 'models' / 'reference_01'
TEXTURES = ROOT / 'assets' / 'textures' / 'reference_01'
PREVIEW = ROOT / 'artifacts' / 'reference_01'
for folder in (SOURCE, EXPORT, TEXTURES, PREVIEW):
    folder.mkdir(parents=True, exist_ok=True)
random.seed(104)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
MATERIALS = {}
PARTS = {}
MANIFEST = []


def texture(name, kind):
    size = 256
    img = bpy.data.images.new(name, width=size, height=size)
    values = []
    rng = random.Random(19)
    for y in range(size):
        for x in range(size):
            if kind == 'cloth':
                v = .84 + .025 * math.sin(x * math.pi / 2) + .025 * math.sin(y * math.pi / 2)
                v += rng.uniform(-.025, .025)
            else:
                wave = x * .55 + 2 * math.sin(y * .025) + math.sin(y * .085)
                v = .68 + .045 * math.sin(wave) + .025 * math.sin(wave * 2.7)
                v += .035 * math.sin(x*.033+math.sin(y*.048)) + rng.uniform(-.025, .025)
            values.extend((v, v, v, 1))
    img.pixels = values
    img.filepath_raw = str(TEXTURES / (name + '.png'))
    img.file_format = 'PNG'
    img.save()
    return img


CLOTH = texture('woven_cotton', 'cloth')
WOOD = texture('reclaimed_wood', 'wood')


def material(name, color, rough=.75, metallic=0, tex=None):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    nodes = m.node_tree.nodes
    links = m.node_tree.links
    bsdf = nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metallic
    if tex:
        # A directly connected image is exported faithfully to glTF.
        tinted = tex.copy()
        tinted.name = name + '_albedo'
        pixels = list(tex.pixels)
        for i in range(0, len(pixels), 4):
            for j in range(3):
                pixels[i+j] *= color[j]
        tinted.pixels = pixels
        tinted.filepath_raw = str(TEXTURES / (name + '_albedo.png'))
        tinted.file_format = 'PNG'
        tinted.save()
        node = nodes.new('ShaderNodeTexImage')
        node.image = tinted
        links.new(node.outputs['Color'], bsdf.inputs['Base Color'])
    MATERIALS[name] = m
    return m


skin = material('warm_skin', (.67, .39, .235), .72)
cheek = material('ear_lip', (.45, .20, .13))
hair = material('chestnut_hair', (.075, .035, .021), .86)
eye = material('dark_eyes', (.022, .029, .025), .35)
ivory = material('ivory_thread', (.76, .65, .43))
shirt = material('linen_shirt', (.72, .61, .41), tex=CLOTH)
vest = material('sage_canvas', (.26, .39, .28), tex=CLOTH)
trousers = material('charcoal_trousers', (.18, .21, .20), tex=CLOTH)
rust = material('rust_patch', (.50, .23, .12), tex=CLOTH)
leather = material('worn_leather', (.17, .075, .033), .84)
oak = material('old_wood', (.47, .30, .15), tex=WOOD)
lightwood = material('cut_wood', (.68, .49, .28), tex=WOOD)
paper = material('cardboard', (.55, .39, .23), .94)
label = material('faded_paper', (.72, .65, .48), .92)
metal = material('tarnished_brass', (.33, .28, .18), .48, .72)
darkmetal = material('dark_iron', (.085, .09, .08), .58, .75)

# Bake the authored atlases to plain images and tangent normals for glTF.
sys.path.insert(0, str(ROOT/'tools'))
from reference_materials import create_materials
real_materials = create_materials(ROOT/'assets'/'textures'/'reference_02')
shirt = real_materials['linen_shirt']
vest = real_materials['sage_canvas']
trousers = real_materials['charcoal_trousers']
rust = real_materials['rust_patch']
leather = real_materials['worn_leather']
oak = real_materials['old_wood']
lightwood = real_materials['cut_wood']
paper = real_materials['cardboard']
label = real_materials['faded_paper']
metal = real_materials['tarnished_brass']


def finish(obj, name, mat, bone=None):
    obj.name = name
    obj.data.materials.append(mat)
    if bone:
        PARTS[obj.name] = bone
        obj['deform_bone'] = bone
    return obj


def cube(name, loc, scale, mat, bevel=.012, bone=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(obj, name, mat, bone)
    # Each face receives its own usable texture area; orient grain along the
    # long dimension instead of Blender's default tiny cube-atlas islands.
    uv = obj.data.uv_layers.active
    if uv:
        for face in obj.data.polygons:
            normal_axis = max(range(3), key=lambda axis: abs(face.normal[axis]))
            axes = [axis for axis in range(3) if axis != normal_axis]
            axes.sort(key=lambda axis: scale[axis])
            for index in face.loop_indices:
                co = obj.data.vertices[obj.data.loops[index].vertex_index].co
                uv.data[index].uv = (co[axes[0]]/scale[axes[0]]+.5,co[axes[1]]/scale[axes[1]]+.5)
    if bevel:
        mod = obj.modifiers.new('Soft worn edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        obj.data.use_auto_smooth = True
        mod = obj.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def ellipsoid(name, loc, scale, mat, bone=None, segments=20, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    finish(obj, name, mat, bone)
    for p in obj.data.polygons:
        p.use_smooth = len(p.vertices) <= 4
    return obj


def tube(name, start, end, radius, mat, bone=None, radius2=None, vertices=12):
    start, end = Vector(start), Vector(end)
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius,
        radius2=radius if radius2 is None else radius2,
        depth=(end-start).length, location=(start+end)/2)
    obj = bpy.context.object
    obj.rotation_euler = (end-start).to_track_quat('Z', 'Y').to_euler()
    finish(obj, name, mat, bone)
    for p in obj.data.polygons:
        p.use_smooth = True
    return obj


def line(name, coords, radius, mat, bone=None):
    data = bpy.data.curves.new(name, 'CURVE')
    data.dimensions = '3D'
    data.resolution_u = 4
    data.bevel_depth = radius
    data.bevel_resolution = 1
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(coords)-1)
    for p, co in zip(spline.bezier_points, coords):
        p.co = co
        p.handle_left_type = 'AUTO'
        p.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    finish(obj, name, mat, bone)
    return obj


def profile(name, rings, mat, sides=32, bone=None):
    # Rings: z, width radius, depth radius, depth offset.
    verts = [(rx*math.cos(a*2*math.pi/sides), cy+ry*math.sin(a*2*math.pi/sides), z)
             for z, rx, ry, cy in rings for a in range(sides)]
    faces = []
    for j in range(len(rings)-1):
        for k in range(sides):
            faces.append((j*sides+k,j*sides+(k+1)%sides,(j+1)*sides+(k+1)%sides,(j+1)*sides+k))
    faces.extend((tuple(reversed(range(sides))), tuple((len(rings)-1)*sides+k for k in range(sides))))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, name, mat, bone)
    for p in mesh.polygons:
        p.use_smooth = True
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.025)
    bpy.ops.object.mode_set(mode='OBJECT')
    return obj


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    PARTS.clear()


def meshes():
    for obj in list(bpy.context.scene.objects):
        if obj.type == 'CURVE':
            name = obj.name
            bpy.ops.object.select_all(action='DESELECT')
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.convert(target='MESH')
            if name in PARTS:
                PARTS[bpy.context.object.name] = PARTS[name]
    return [o for o in bpy.context.scene.objects if o.type == 'MESH']


def save_blend(path):
    # Save a complete new file first. Windows indexing can briefly lock a
    # freshly written .blend, so retry only the final atomic replacement.
    staging = path.with_name(path.stem + '_' + uuid.uuid4().hex + '.staging.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(staging), compress=True)
    for attempt in range(10):
        try:
            staging.replace(path)
            return
        except PermissionError:
            if attempt == 9:
                raise
            time.sleep(.3)


def save_asset(name, rig=None):
    objs = meshes()
    # Consolidate mesh pieces while retaining material slots and rigid bone weights.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objs:
        if rig and obj.name.startswith(('L_leg_cloth', 'R_leg_cloth')):
            side = obj.name[0]
            upper = obj.vertex_groups.new(name=side+'_thigh')
            lower = obj.vertex_groups.new(name=side+'_shin')
            for vertex in obj.data.vertices:
                weight = max(0.0, min(1.0, (vertex.co.z-.39)/.12))
                if weight: upper.add([vertex.index], weight, 'REPLACE')
                if weight<1: lower.add([vertex.index], 1-weight, 'REPLACE')
        elif rig:
            group = obj.vertex_groups.new(name=obj.get('deform_bone', PARTS.get(obj.name, 'spine')))
            group.add(list(range(len(obj.data.vertices))), 1.0, 'REPLACE')
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name + '_mesh'
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if rig:
        mod = obj.modifiers.new('Reference skeleton', 'ARMATURE')
        mod.object = rig
        obj.parent = rig
    obj.data.calc_loop_triangles()
    bounds = [Vector(v) for v in obj.bound_box]
    entry = {'asset':name, 'triangles':len(obj.data.loop_triangles),
        'materials':len(obj.data.materials), 'dimensions':[round(max(v[i] for v in bounds)-min(v[i] for v in bounds),4) for i in range(3)],
        'rig_bones':len(rig.data.bones) if rig else 0,
        'status':'art reference v0.1; review required'}
    MANIFEST.append(entry)
    for img in bpy.data.images:
        if img.filepath and not img.packed_file:
            img.pack()
    save_blend(SOURCE / (name+'.blend'))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(EXPORT / (name+'.glb')), export_format='GLB',
        use_selection=True, export_yup=True, export_animations=True, export_force_sampling=True)


def character():
    clear()
    # 1.60 units high, human proportions with slightly enlarged head and hands.
    profile('Linen torso',[(.75,.12,.082,0),(.85,.15,.09,0),(1.03,.18,.10,0),(1.17,.22,.09,.005),(1.22,.14,.08,0)],shirt,bone='spine')
    profile('Canvas waistcoat',[(.79,.151,.097,0),(.91,.157,.107,0),(1.10,.193,.115,0),(1.155,.188,.10,0),(1.185,.13,.084,0)],vest,bone='spine')
    cube('Waistcoat opening',(0,-.11,1.025),(.021,.012,.28),shirt,.003,'spine')
    for z in [.86,.93,1.00,1.07]:
        ellipsoid('Small button',(.023,-.122,z),(.012,.007,.012),metal,'spine',12,8)
    for s in [-1,1]:
        pocket=cube('Patch pocket',(s*.107,-.105,.92),(.07,.019,.083),vest,.008,'spine')
        pocket.rotation_euler.y=s*.08
        for j in range(5):
            x=s*.107-.025+j*.012
            tube('Pocket hand stitch',(x,-.118,.888),(x+.005,-.119,.893),.0018,ivory,'spine',vertices=6)
    profile('Trouser seat',[(.66,.14,.086,0),(.80,.151,.098,0)],trousers,bone='hips')
    profile('Leather belt',[(.785,.156,.103,0),(.821,.156,.103,0)],leather,bone='hips')
    cube('Belt buckle',(0,-.111,.803),(.055,.018,.038),metal,.004,'hips')
    cube('Buckle inset',(0,-.122,.803),(.033,.008,.019),leather,.001,'hips')
    tube('Neck',(0,0,1.19),(0,0,1.31),.066,skin,'head',vertices=20)
    ellipsoid('Head',(0,-.005,1.414),(.119,.104,.158),skin,'head',32,20)
    ellipsoid('Jaw',(0,-.04,1.35),(.082,.076,.072),skin,'head')
    ellipsoid('Nose bridge',(0,-.109,1.414),(.027,.024,.044),skin,'head')
    ellipsoid('Nose tip',(0,-.13,1.392),(.033,.029,.024),skin,'head')
    line('Mouth',[(-.029,-.110,1.354),(0,-.120,1.35),(.029,-.11,1.354)],.003,cheek,'head')
    for s in [-1,1]:
        ellipsoid('Ear',(s*.116,0,1.411),(.029,.023,.048),skin,'head')
        ellipsoid('Ear inner',(s*.135,-.014,1.413),(.008,.007,.023),cheek,'head',12,8)
        ellipsoid('Eye socket',(s*.047,-.097,1.438),(.028,.014,.017),cheek,'head')
        ellipsoid('Eye',(s*.047,-.109,1.439),(.019,.009,.011),eye,'head')
        ellipsoid('Eye catchlight',(s*.045-.003,-.116,1.443),(.003,.002,.003),ivory,'head',8,6)
        line('Eyebrow',[(s*.023,-.107,1.46),(s*.048,-.105,1.47),(s*.072,-.091,1.466)],.005,hair,'head')
    # Fitted scalp mesh, swept fringe, not a spherical helmet.
    verts=[]; faces=[]; seg=32; rings=8
    for j in range(rings):
        for i in range(seg):
            a=i*2*math.pi/seg
            front=max(0,-math.sin(a))
            end=1.9-.57*front+.09*math.sin(a*3)
            t=.025+(end-.025)*j/(rings-1)
            verts.append((.123*math.sin(t)*math.cos(a),.005+.108*math.sin(t)*math.sin(a),1.422+.17*math.cos(t)))
    for j in range(rings-1):
        for i in range(seg): faces.append((j*seg+i,j*seg+(i+1)%seg,(j+1)*seg+(i+1)%seg,(j+1)*seg+i))
    mesh=bpy.data.meshes.new('Swept hair');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('Swept hair',mesh);bpy.context.collection.objects.link(obj);finish(obj,'Swept hair',hair,'head')
    for p in mesh.polygons:p.use_smooth=True
    for i in range(5):
        x=-.075+i*.028
        line('Swept lock',[(x,.0,1.573),(x+.04,-.07,1.545),(x+.01,-.101,1.485+i*.004)],.014,hair,'head')
    for s, side in [(-1,'L'),(1,'R')]:
        thigh=side+'_thigh'; shin=side+'_shin'; foot=side+'_foot'
        upper=side+'_upper_arm'; fore=side+'_forearm'; hand=side+'_hand'
        leg=profile(side+'_leg_cloth',[(.17,.047,.049,0),(.29,.054,.057,0),(.39,.065,.067,-.005),(.45,.067,.070,-.008),(.58,.080,.080,0),(.74,.083,.084,0)],trousers,sides=20)
        leg.location.x=s*.105
        tube('Boot upper',(s*.11,0,.11),(s*.11,0,.27),.057,leather,shin,.061,20)
        cube('Boot sole',(s*.11,-.039,.032),(.129,.225,.043),darkmetal,.022,foot)
        ellipsoid('Boot toe',(s*.11,-.05,.078),(.063,.108,.06),leather,foot)
        for z in [.126,.157,.188]:
            line('Boot laces',[(s*.11-.03,-.055,z),(s*.11+.03,-.055,z+.017)],.003,ivory,shin)
        sleeve=ellipsoid('Full linen sleeve',(s*.234,0,1.075),(.079,.081,.15),shirt,upper,24,16)
        sleeve.rotation_euler.y=-s*.30
        tube('Rolled cuff',(s*.27,0,.984),(s*.28,-.009,.93),.070,shirt,fore,.07,20)
        tube('Forearm',(s*.28,-.009,.935),(s*.304,-.026,.791),.044,skin,fore,.032,20)
        ellipsoid('Hand',(s*.309,-.031,.755),(.038,.030,.059),skin,hand)
        ellipsoid('Thumb',(s*.28,-.056,.77),(.017,.019,.032),skin,hand,12,8)
    cube('Knee repair',(-.105,-.085,.437),(.078,.012,.094),rust,.009,'L_shin')
    for i in range(5):
        tube('Knee stitches',(-.137+i*.016,-.095,.471),(-.132+i*.016,-.095,.477),.002,ivory,'L_shin',vertices=6)
    cube('Canvas satchel',(0,.153,1.008),(.26,.115,.29),shirt,.035,'spine')
    cube('Satchel flap',(0,.22,1.078),(.27,.028,.135),vest,.025,'spine')
    cube('Satchel closure',(0,.24,1.01),(.028,.016,.14),leather,.004,'spine')
    for s in [-1,1]:
        line('Shoulder strap',[(s*.11,.16,1.08),(s*.145,.06,1.204),(s*.13,-.095,1.145),(s*.12,-.119,.88)],.013,leather,'spine')
    # Rigid segment binding for review poses; deformation topology comes after approval.
    bpy.ops.object.select_all(action='DESELECT')
    data=bpy.data.armatures.new('Resident reference rig')
    rig=bpy.data.objects.new('resident_rig',data);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,start,end,parent=None):
        b=data.edit_bones.new(name);b.head=start;b.tail=end
        if parent:b.parent=data.edit_bones[parent]
    bone('root',(0,0,0),(0,0,.15))
    bone('hips',(0,0,.72),(0,0,.84),'root')
    bone('spine',(0,0,.84),(0,0,1.2),'hips')
    bone('head',(0,0,1.2),(0,0,1.58),'spine')
    for s,side in [(-1,'L'),(1,'R')]:
        bone(side+'_thigh',(s*.09,0,.73),(s*.105,0,.43),'hips')
        bone(side+'_shin',(s*.105,0,.43),(s*.11,0,.13),side+'_thigh')
        bone(side+'_foot',(s*.11,0,.13),(s*.11,-.12,.06),side+'_shin')
        bone(side+'_upper_arm',(s*.205,0,1.15),(s*.269,0,.963),'spine')
        bone(side+'_forearm',(s*.269,0,.963),(s*.304,-.026,.791),side+'_upper_arm')
        bone(side+'_hand',(s*.304,-.026,.791),(s*.309,-.031,.715),side+'_forearm')
    for name,loc,parent in [('socket_back',(0,.24,1.06),'spine'),('socket_head',(0,0,1.60),'head'),('socket_hand_R',(.309,-.05,.75),'R_hand')]:
        bone(name,loc,(loc[0],loc[1],loc[2]+.045),parent)
    bpy.ops.object.mode_set(mode='OBJECT')
    rig.animation_data_create()
    rig.animation_data.action=bpy.data.actions.new('idle_reference')
    for frame,angle in [(1,0),(31,.012),(61,0),(91,-.008),(121,0)]:
        p=rig.pose.bones['spine'];p.rotation_mode='XYZ';p.rotation_euler.x=angle;p.keyframe_insert('rotation_euler',frame=frame)
        p=rig.pose.bones['head'];p.rotation_mode='XYZ';p.rotation_euler.z=-angle*1.5;p.keyframe_insert('rotation_euler',frame=frame)
    bpy.context.scene.frame_set(1)
    bpy.context.scene.render.fps=30
    bpy.context.scene.frame_end=121
    save_asset('resident_reference',rig)


def decal(name, corners, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(corners, [], [(0,1,2,3)])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, name, mat)
    uv = mesh.uv_layers.new(name='UVMap')
    for index,coord in enumerate([(0,0),(1,0),(1,1),(0,1)]):
        uv.data[index].uv = coord
    return obj


def bed():
    clear()
    # Human-scale matchbox reused as an open drawer bed.
    cube('Cardboard tray base',(0,0,.065),(.91,1.88,.10),paper,.025)
    for x in [-.455,.455]:cube('Folded cardboard side',(x,0,.20),(.05,1.88,.28),paper,.015)
    for y in [-.935,.935]:cube('Drawer end',(0,y,.20),(.94,.045,.28),paper,.012)
    # The sleeve is retained as a headboard, its open end frames the drawer.
    cube('Sleeve back',(0,1.00,.45),(1.04,.065,.86),paper,.012)
    cube('Sleeve top fold',(0,.91,.88),(1.04,.23,.035),paper,.009)
    for x in [-.505,.505]:
        cube('Sleeve side return',(x,.91,.45),(.035,.23,.86),paper,.009)
    decal('Original match label',[(-.48,.960,.38),(.48,.960,.38),(.48,.960,.86),(-.48,.960,.86)],real_materials['matchbox_print'])
    decal('Label on sleeve rear',[(.48,1.035,.38),(-.48,1.035,.38),(-.48,1.035,.86),(.48,1.035,.86)],real_materials['matchbox_print'])
    for s in [-1,1]:
        # Long recognisable striking strips on both sides of the reused box.
        x=s*.486
        points=[(x,-.88,.085),(x,.88,.085),(x,.88,.31),(x,-.88,.31)]
        if s<0:points.reverse()
        decal('Phosphorus striking strip',points,real_materials['matchbox_striker'])
    decal('Drawer end print',[(-.40,-.959,.09),(.40,-.959,.09),(.40,-.959,.30),(-.40,-.959,.30)],real_materials['matchbox_print'])
    # Exposed card layers, peeled corner and one match repurposed as a brace.
    for z in [.095,.108,.121]:
        line('Exposed card ply',[(-.47,-.94,z),(-.475,0,z+.002),(-.47,.88,z)],.002,ivory)
    tube('Matchwood brace',(.48,-.87,.055),(.48,.73,.055),.024,lightwood,vertices=8)
    ellipsoid('Spent match head',(.48,.75,.055),(.034,.067,.034),rust,segments=12,rings=8)
    for x in [-.36,.36]:
        for y in [-.78,.78]:cube('Reclaimed wood foot',(x,y,.045),(.13,.17,.09),oak,.015)
    cube('Stuffed linen mattress',(0,0,.23),(.84,1.78,.23),shirt,.085)
    cube('Patchwork quilt',(0,-.20,.365),(.84,1.28,.08),vest,.032)
    for x in [-.205,.205]:
        for j in range(3):
            y=-.62+j*.4
            cube('Quilt patch',(x,y,.41),(.389,.376,.018),rust if (j+(x>0))%3==0 else shirt,.018)
    for j in range(17):
        y=-.78+j*.07
        tube('Quilt seam',(-.004,y,.425),(.004,y+.025,.425),.0025,ivory,vertices=6)
    pillow=cube('Linen pillow',(0,.64,.395),(.65,.38,.16),shirt,.075)
    pillow.rotation_euler.z=.045
    line('Pillow seam',[(-.27,.47,.40),(0,.46,.41),(.27,.47,.40)],.003,ivory)
    save_asset('matchbox_bed')


def bucket():
    clear()
    # Open thimble: thickness and recessed dimples in actual exported geometry.
    segments=64; levels=25; verts=[];faces=[]
    for j in range(levels):
        z=.025+j*.41/(levels-1)
        base=.177+.041*j/(levels-1)
        for i in range(segments):
            a=i*2*math.pi/segments
            wave=(max(0,math.cos(a*16+(j//4%2)*math.pi))**5)*(max(0,math.cos(j*math.pi/2))**3)
            r=base-.009*wave if 2<j<levels-3 else base
            verts.append((r*math.cos(a),r*math.sin(a),z))
    for j in range(levels-1):
        for i in range(segments):faces.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
    mesh=bpy.data.meshes.new('Thimble dimples');mesh.from_pydata(verts,[],faces);mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for face in mesh.polygons:
        seam=any(mesh.loops[i].vertex_index%segments==segments-1 for i in face.loop_indices)
        for i in face.loop_indices:
            vertex=mesh.loops[i].vertex_index
            column=vertex%segments
            u=1.0 if seam and column==0 else column/segments
            uv.data[i].uv=(u,(vertex//segments)/(levels-1))
    obj=bpy.data.objects.new('Thimble shell',mesh);bpy.context.collection.objects.link(obj);finish(obj,'Thimble shell',metal)
    for p in mesh.polygons:p.use_smooth=True
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    mod=obj.modifiers.new('Metal thickness','SOLIDIFY');mod.thickness=.012;bpy.ops.object.modifier_apply(modifier=mod.name)
    tube('Thimble base',(0,0,.016),(0,0,.032),.177,metal,vertices=48)
    line('Rolled lip',[(.218*math.cos(a*2*math.pi/32),.218*math.sin(a*2*math.pi/32),.436) for a in range(33)],.012,metal)
    line('Wire handle',[(-.215,0,.37),(-.265,0,.57),(0,0,.72),(.265,0,.57),(.215,0,.37)],.011,darkmetal)
    tube('Handle grip',(-.071,0,.71),(.071,0,.71),.021,leather,vertices=16)
    save_asset('thimble_bucket')


def crate():
    clear()
    for i in range(4):cube('Base slat',(-.30+i*.2,0,.045),(.192,.60,.07),oak,.007)
    for x in [-.38,.38]:
        for y in [-.28,.28]:cube('Corner post',(x,y,.25),(.065,.065,.48),lightwood,.008)
    for z in [.13,.28,.43]:
        for y in [-.30,.30]:cube('Long slat',(0,y,z),(.83,.045,.12),oak,.007)
        for x in [-.40,.40]:cube('End slat',(x,0,z),(.045,.60,.12),lightwood,.006)
        for x in [-.35,.35]:
            for y in [-.328,.328]:ellipsoid('Nail head',(x,y,z),(.012,.005,.012),darkmetal,segments=10,rings=6)
    cube('Paper stock label',(.08,-.329,.29),(.22,.008,.09),label,.005)
    for i in range(3):cube('Tally mark',(.025+i*.031,-.335,.29),(.007,.004,.047),hair,.001)
    save_asset('salvage_crate')


def floor_module():
    clear()
    rng=random.Random(65)
    for i in range(5):
        obj=cube('Salvaged plank',(-.8+i*.4,0,-.065),(.392,2,.13),oak if i%2 else lightwood,.008)
        for y in [-.86,.86]:
            tube('Old nail',(-.8+i*.4,y,-.001),(-.8+i*.4,y,.004),.014,darkmetal,vertices=10)
        for j in range(2):
            x=-.8+i*.4+rng.uniform(-.13,.13);y=rng.uniform(-.8,.3)
            line('Dry split',[(x,y,.001),(x+.012,y+.20,.001),(x-.005,y+.43,.001)],.0017,leather)
    save_asset('floor_module_2x2')


def append_asset(name, pos=(0,0,0), angle=0):
    with bpy.data.libraries.load(str(SOURCE/(name+'.blend')),link=False) as (src,dst):
        dst.objects=src.objects
    originals=[obj for obj in dst.objects if obj]
    mapping={obj:obj.copy() for obj in originals}
    objects=list(mapping.values())
    for original,obj in mapping.items():
        bpy.context.collection.objects.link(obj)
        if original.parent in mapping:obj.parent=mapping[original.parent]
        for mod in obj.modifiers:
            if mod.type=='ARMATURE' and mod.object in mapping:mod.object=mapping[mod.object]
    parent=bpy.data.objects.new(name+'_placement',None);bpy.context.collection.objects.link(parent)
    for obj in objects:
        if obj.parent is None:obj.parent=parent
    parent.location=pos;parent.rotation_euler.z=angle
    return parent


def camera_at(loc, target, size):
    bpy.ops.object.camera_add(location=loc)
    camera=bpy.context.object
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='ORTHO';camera.data.ortho_scale=size
    bpy.context.scene.camera=camera
    return camera


def area(name,loc,target,power,color,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.color=color;data.size=size
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);obj.location=loc
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()


def render_setup():
    scene=bpy.context.scene
    scene.render.engine='CYCLES';scene.cycles.samples=32
    scene.cycles.use_denoising=True
    scene.render.threads_mode='FIXED';scene.render.threads=6
    scene.render.resolution_x=1500;scene.render.resolution_y=1150;scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new('Reference studio')
    scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.16,.145,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.3
    scene.view_settings.view_transform='Filmic';scene.view_settings.look='Medium High Contrast'
    area('Warm key',(-3,-4,6),(0,0,.6),480,(1,.82,.63),4)
    area('Cool fill',(3,-1,3),(0,0,.8),200,(.68,.83,1),3)
    area('Rim',(1,4,5),(0,0,.8),500,(1,.9,.73),3)
    stage=material('studio_background',(.055,.074,.066),.94)
    cube('Studio ground',(0,0,-.22),(200,200,.15),stage,.01)


def showcase():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    render_setup()
    for x in [-1,1]:
        for y in [-1,1]:append_asset('floor_module_2x2',(x,y,0))
    append_asset('resident_reference',(.35,-.65,0),-.14)
    append_asset('matchbox_bed',(-.88,.32,0),.04)
    append_asset('salvage_crate',(.85,.92,0),-.18)
    append_asset('thimble_bucket',(1.02,-.35,0),.12)
    camera_at((5,-8,6),(0,0,.45),5.65)
    save_blend(SOURCE/'reference_showcase.blend')
    if '--no-render' in sys.argv:
        return
    bpy.context.scene.render.filepath=str(PREVIEW/'lot_01.png');bpy.ops.render.render(write_still=True)
    clear();render_setup()
    append_asset('resident_reference',(-.45,0,0),-.22)
    append_asset('resident_reference',(.45,.04,0),math.pi-.28)
    camera_at((3,-7,3.3),(0,0,.85),2.45)
    bpy.context.scene.render.resolution_x=1400;bpy.context.scene.render.resolution_y=1400
    bpy.context.scene.render.filepath=str(PREVIEW/'resident_front_back.png');bpy.ops.render.render(write_still=True)


if __name__ == '__main__':
    character()
    bed()
    bucket()
    crate()
    floor_module()
    (SOURCE/'manifest.json').write_text(json.dumps({'units':'1 Blender unit = 1 Godot unit; resident height about 1.60',
        'assets':MANIFEST,'textures':'image_gen atlases; Blender-baked albedo and estimated tangent normals; packed in blend and GLB',
        'rig_limit':'rigid segment skinning, reference idle only; not a final deformable production rig'},indent=2),encoding='utf-8')
    showcase()
    print('REFERENCE_LOT_OK',json.dumps(MANIFEST))
