"""Additional editable Blender scenery for the underfloor cutaway.
Run: blender --background --python tools/create_atmosphere.py
"""
import bpy
import os
import random
import math
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
random.seed(41)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, rgb):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*rgb, 1)
    p.inputs['Roughness'].default_value = .97
    return m

wood = material('Bois noirci', (.15, .09, .046))
dust = material('Poussière accumulée', (.23, .19, .13))
stone = material('Mortier effrité', (.22, .22, .19))
rust = material('Fer rouillé', (.24, .105, .045))
web = material('Soie poussiéreuse', (.38, .36, .29))
rag = material('Mèche en chiffon', (.30, .19, .08))

def finish(obj, name, mat):
    obj.name = name
    obj.data.materials.append(mat)
    return obj

def box(name, loc, size, mat, bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(o, name, mat)
    if bevel:
        m = o.modifiers.new('Usure', 'BEVEL')
        m.width = bevel
        m.segments = 1
        bpy.ops.object.modifier_apply(modifier=m.name)
    return o

def rod(name, a, b, radius, mat):
    direction = Vector(b) - Vector(a)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius, depth=direction.length, location=(Vector(a)+Vector(b))/2)
    o = bpy.context.object
    o.rotation_euler = direction.to_track_quat('Z', 'Y').to_euler()
    return finish(o, name, mat)

def save(name):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, 'art_source', name + '.blend'))
    bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, 'assets', 'models', name + '.glb'), export_format='GLB')

# The ceiling is cut away over the playable area; its rear edge remains visible.
for row in range(4):
    for j in range(14):
        box('Pierre des fondations', (-11.25+j*1.68 + (.35 if row%2 else 0), 8.25, .25+row*.49), (1.60,.48,.43), stone, .08)
box('Poutre porteuse', (0, 6.7, 3.70), (23.4, .8, .65), wood, .05)
for j in range(17):
    box('Plancher au-dessus', (-11.0+j*1.36, 7.2, 4.17+random.uniform(-.025,.025)), (1.27, 2.6, .22), wood, .015)
    for k in range(3):
        box('Fissure ancienne', (-11.1+j*1.36+random.uniform(-.3,.3), 6.05+random.uniform(0,2), 4.30), (.015,random.uniform(.15,.7),.012), rust, 0)
for x in [-10.8, -4, 3, 10.8]:
    box('Solive transversale', (x, 6.4, 3.82), (.4, 3.1, .45), wood)
    rod('Clou dépassant', (x+.14, 5.9,3.6), (x+.12,5.9,3.24), .027, rust)

# Splinters and grit cluster along the edges, with sparse specks on the paths.
for i in range(180):
    x, y = random.uniform(-11.3,11.3), random.uniform(-7.8,7.8)
    if i < 130:
        if i % 2: x = random.choice([-1,1])*random.uniform(10.1,11.4)
        else: y = random.choice([-1,1])*random.uniform(6.4,7.8)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1, location=(x,y,.035))
    o = bpy.context.object
    o.scale = (random.uniform(.045,.15),random.uniform(.04,.13),random.uniform(.02,.065))
    finish(o, 'Gravats et poussière', dust if i%3 else stone)
for i in range(32):
    x = random.choice([-1,1])*random.uniform(9.3,11.2)
    y = random.uniform(-7.2,7.7)
    o = box('Écharde', (x,y,.08), (.045,random.uniform(.18,.8),.035), wood, 0)
    o.rotation_euler.z = random.uniform(0,math.pi)
for i in range(7):
    x,y=random.uniform(-10,10),random.choice([-7,7])
    rod('Clou tombé', (x,y,.07), (x+.38,y+.22,.07), .025,rust)

# Organic cobweb sheets: curved attachment lines, loose cross-filaments and tears.
# Each web has its own deterministic seed, span, droop and damage pattern.
def silk_curve(name, a, b, radius, rng, sag=.10, loose=False):
    a, b = Vector(a), Vector(b)
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.resolution_u = 2
    curve.bevel_depth = radius * 1.55
    curve.bevel_resolution = 1
    spline = curve.splines.new('POLY')
    samples = 18
    spline.points.add(samples)
    phase = rng.uniform(0, math.tau)
    for k, p in enumerate(spline.points):
        t = k / samples
        envelope = math.sin(t*math.pi)
        v = a.lerp(b,t)
        v.z -= envelope*sag
        v.y += envelope*(.06*math.sin(t*4.2+phase)+(.10 if loose else 0))
        v.x += envelope*.028*math.sin(t*7+phase)
        p.co = (*v,1)
        p.radius = .62 + .38*math.sin(t*math.pi) + rng.uniform(-.12,.12)
    obj=bpy.data.objects.new(name,curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(web)
    return obj

for cx, cy, span, height, seed in [(-7.1,5.25,3.3,1.2,73),(6.35,5.30,2.55,.96,181)]:
    rng=random.Random(seed)
    objects=[]
    def point(u,v):
        # A sagging sheet with uneven edges and slightly twisted depth.
        return Vector((cx+(u-.5)*span, cy+.28*u+.18*math.sin(u*3+v*2),
                       3.52-v*height-.35*math.sin(math.pi*u)*v))
    # A scattered knot network instead of rows or radial spokes.
    # Reject knots inside torn patches; this avoids a regular mesh silhouette.
    knots=[]
    while len(knots)<65:
        u,v=rng.uniform(.025,.975),rng.uniform(.08,1)
        tear=((u-.55)/.17)**2+((v-.72)/.22)**2 < 1
        if (seed==73 and tear) or (seed==181 and u<.24 and v>.5):
            continue
        if any((u-p[0])**2+(v-p[1])**2<.002 for p in knots):
            continue
        knots.append((u,v))
    nodes=[point(u,v) for u,v in knots]
    edges=set()
    for index,a in enumerate(nodes):
        nearby=sorted((j for j in range(len(nodes)) if j!=index),key=lambda j:(nodes[j]-a).length)
        for j in nearby[:rng.choice([2,2,3])]:
            edge_key=tuple(sorted((index,j)))
            if edge_key in edges or rng.random()<.10: continue
            edges.add(edge_key)
            length=(nodes[j]-a).length
            objects.append(silk_curve('Soie - réseau irrégulier',a,nodes[j],rng.uniform(.004,.0085),rng,
                                      length*rng.uniform(.025,.13)))
    # Long load-bearing lines, anchored at uneven locations under the timber.
    for u in [.025,.29,.76,.98]:
        anchor=Vector((cx+(u-.5)*span,5.48,3.58))
        candidates=sorted(range(len(nodes)),key=lambda j:abs(knots[j][0]-u)+abs(knots[j][1]-.30))
        for j in candidates[:2]:
            objects.append(silk_curve('Soie - attache',anchor,nodes[j],rng.uniform(.006,.009),rng,.04))
    for i in range(12):
        a=nodes[rng.randrange(len(nodes))]
        b=nodes[rng.randrange(len(nodes))]
        if (a-b).length<.45: continue
        objects.append(silk_curve('Soie - voile lâche',a,b,rng.uniform(.003,.0055),rng,rng.uniform(.08,.22),True))
    lower=sorted(nodes,key=lambda p:p.z)[:12]
    for a in lower[::2]:
        b=a+Vector((rng.uniform(-.14,.14),.1,-rng.uniform(.12,.33)))
        objects.append(silk_curve('Soie - fil rompu',a,b,.004,rng,.025,True))
    # Keep the editable curves in a dedicated Blender source, and export a joined mesh.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art_source','cobweb_%s.blend'%seed))
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    bpy.context.object.name='Toile organique %s'%seed
save('underfloor')

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
# Miniature torch fashioned from a match, wire and a scrap of cloth.
rod('Pied de torche', (0,0,.04),(0,0,.97), .047, wood)
for j in range(3):
    a=j*math.tau/3
    rod('Trépied', (0,0,.36),(.25*math.cos(a),.25*math.sin(a),.025), .025, rust)
rod('Chiffon huilé', (0,0,.88),(0,0,1.09), .10, rag)
for z in [.9,.97,1.04]:
    bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=5,major_radius=.102,minor_radius=.012,location=(0,0,z))
    finish(bpy.context.object,'Fil de fer',rust)
save('torch')
print('ATMOSPHERE_ASSETS_OK')


