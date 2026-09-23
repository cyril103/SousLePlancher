"""Run with Blender --background --python tools/create_assets.py.
One editable .blend per asset; GLBs are the runtime interchange format.
"""
import bpy
import math
import os
import random
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'models')
SOURCE = os.path.join(ROOT, 'art_source')
os.makedirs(OUT, exist_ok=True)
os.makedirs(SOURCE, exist_ok=True)
random.seed(12)

def mat(name, rgb):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (*rgb, 1)
    m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = .82
    return m

wood = mat('Chêne ancien', (.28, .17, .095))
edge = mat('Bois de bout', (.43, .27, .14))
grain = mat('Veines du bois', (.19, .11, .062))
teal = mat('Tissu vert sauge', (.12, .40, .32))
cream = mat('Lin naturel', (.79, .62, .38))
dark = mat('Ombre chaude', (.075, .09, .07))
skin = mat('Peau', (.84, .60, .35))
copper = mat('Cuivre patiné', (.32, .48, .43))
gold = mat('Miette dorée', (.88, .55, .17))
thread = mat('Fil de coton', (.64, .27, .16))

def finish(obj, name, material):
    obj.name = name
    obj.data.materials.append(material)
    return obj

def cube(name, loc, scale, material, bevel=.03):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(o, name, material)
    if bevel:
        mod = o.modifiers.new('Arêtes usées', 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def cyl(name, loc, radius, depth, material, top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=20, radius1=radius, radius2=radius if top is None else top, depth=depth, location=loc)
    return finish(bpy.context.object, name, material)

def ball(name, loc, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1, location=loc)
    o = bpy.context.object
    o.scale = scale
    return finish(o, name, material)

def torus(name, loc, major, minor, material):
    bpy.ops.mesh.primitive_torus_add(major_segments=24, minor_segments=6, location=loc, major_radius=major, minor_radius=minor)
    return finish(bpy.context.object, name, material)

def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def save(name):
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE, name + '.blend'))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + '.glb'), export_format='GLB', export_yup=True)

clear()
for i in range(12):
    x = -11 + i * 2
    cube('Lame de parquet', (x, 0, -.10), (1.96, 16.8, .22), wood)
    for j in range(9):
        cube('Fibre', (x + random.uniform(-.85, .85), random.uniform(-7.5, 7.5), .018), (.012, random.uniform(.4, 2), .008), grain, 0)
    for y in [-7.8, 7.8]:
        cyl('Clou', (x + .6, y, .024), .055, .025, copper)
cube('Socle', (0, 0, -.48), (24, 17, .65), dark)
cube('Plinthe', (0, 8.4, .65), (24, .4, 1.5), edge)
for x in [-11.7, 11.7]:
    cube('Solive', (x, 0, .25), (.55, 17, .6), edge)
for x in [-9, 8.7]:
    cube('Pied de meuble géant', (x, 6.8, 1.9), (1.5, 1.5, 3.8), edge, .12)
    cube('Collerette', (x, 6.8, 3.65), (1.8, 1.8, .3), wood)
pipe = cyl('Canalisation', (0, 7.7, 1.2), .23, 21.5, copper)
pipe.rotation_euler.y = math.pi / 2
for x in [-6, 2, 6]:
    ring = torus('Raccord du tuyau', (x, 7.7, 1.2), .25, .06, copper)
    ring.rotation_euler.y = math.pi / 2
cyl('Bobine', (9, -5.7, .6), .65, 1.15, thread)
for z in [.10, 1.2]:
    cyl('Flasque', (9, -5.7, z), .92, .14, cream)
for i in range(13):
    torus('Fil enroulé', (9, -5.7, .2 + i * .071), .65, .025, thread)
for i in range(3):
    x = -9.5 + i * .85
    cyl('Bouton', (x, -5.8, .1), .4, .12, copper)
    for dx in [-.09, .09]:
        for dy in [-.09, .09]:
            cyl('Trou du bouton', (x + dx, -5.8 + dy, .17), .045, .012, dark)
save('floor')

clear()
cyl('Boîte de conserve', (0, 0, .49), .78, .96, cream)
for z in [.08, .18, .8, .92]:
    torus('Nervure', (0, 0, z), .78, .025, edge)
cyl('Toit en tissu', (0, 0, 1.16), 1.04, .5, teal, .32)
ball('Entrée', (0, -.76, .3), (.25, .05, .34), dark)
cube('Marche', (0, -.9, .06), (.55, .38, .12), edge)
for x in [-.46, .46]:
    cube('Fenêtre', (x, -.66, .57), (.19, .08, .22), gold)
    cube('Croisillon', (x, -.72, .57), (.025, .025, .23), wood)
cyl('Cheminée en dé à coudre', (.42, .16, 1.41), .13, .35, copper)
save('shelter')

clear()
for x in [-.62, .62]:
    for y in [-.36, .36]:
        cube('Pied en allumette', (x, y, .36), (.12, .12, .72), edge)
cube('Établi', (0, 0, .76), (1.6, 1.1, .16), cream)
cube('Planche inférieure', (0, 0, .18), (1.45, .85, .12), wood)
cyl('Bobine miniature', (-.43, .08, 1), .19, .32, thread)
for z in [.86, 1.17]:
    cyl('Flasque', (-.43, .08, z), .25, .05, cream)
cube('Manche outil', (.32, 0, .88), (.08, .6, .07), edge)
cube('Tête outil', (.32, .28, .9), (.35, .1, .1), copper)
save('workshop')

clear()
ball('Tunique', (0, 0, .32), (.20, .15, .25), teal)
ball('Visage', (0, -.015, .67), (.18, .16, .19), skin)
ball('Nez', (0, -.174, .66), (.052, .055, .05), skin)
for x in [-.07, .07]:
    ball('Œil', (x, -.157, .71), (.024, .017, .029), dark)
    ball('Chaussure', (x * 1.4, -.04, .075), (.085, .13, .075), wood)
for x in [-.24, .24]:
    ball('Bras', (x, 0, .35), (.065, .075, .18), cream)
cyl('Chapeau gland', (0, 0, .87), .245, .20, edge, .09)
cyl('Tige du gland', (0, 0, 1.0), .035, .1, wood)
ball('Sac à dos', (0, .18, .38), (.16, .08, .19), cream)
save('worker')

for kind, material in [('food', gold), ('wood', edge), ('fiber', thread)]:
    clear()
    for i in range(7):
        x, y = random.uniform(-.55, .55), random.uniform(-.4, .4)
        if kind == 'food':
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(.17, .32), location=(x, y, .2))
            finish(bpy.context.object, 'Miette', material)
        elif kind == 'wood':
            o = cube('Allumette', (x, y, .10 + i * .025), (.13, .85, .10), material, .01)
            o.rotation_euler.z = random.uniform(-.7, .7)
        else:
            torus('Boucle de fil', (x, y, .06 + i * .04), .23, .045, material)
    save(kind)

print('ASSETS_OK: 7 GLB + 7 sources Blender')
