"""Blender L02 route: connected alcove, empty-handed ledge, cargo bridge and kitchen pocket."""
import bpy, math, random, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
# Preserve the original alcove; cut a real rear opening in a new variant.
source=(ROOT/'tools/create_alcove_assets.py').read_text(encoding='utf-8')
source=source.replace("'alcove_19'","'kitchen_30'").replace("box('Alcove rear',0,.62,7.6,4.2,1.35,.16,r.oak)","\nfor x in [-1.6,1.6]: box('Rear jamb',x,.62,7.6,1.0,1.35,.16,r.oak)")
source=source.replace("save_asset('alcove_sector')","save_asset('alcove_connected')")
exec(compile(source, __file__, 'exec'))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
OUT=ROOT/'assets/models/kitchen_30';SRC=ROOT/'art_source/kitchen_30'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
def mat(name,color,texture=None):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.9
 if texture:
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/'assets/textures/reference_02'/texture));m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
 return m
wood=mat('Old wood',(.23,.13,.07),'old_wood_basecolor.png');cut=mat('Salvaged rail',(.35,.22,.10),'cut_wood_basecolor.png');dark=mat('Dark masonry',(.12,.115,.10));bisc=mat('Baked biscuit',(.50,.29,.09));crumb=mat('Biscuit edges',(.68,.43,.17));rope=mat('Flax lashings',(.36,.25,.13))
def cube(name,pos,size,material):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0],-pos[2],pos[1]));o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
 b=o.modifiers.new('Worn edges','BEVEL');b.width=.018;b.segments=2;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');return o

def save(name):
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')),compress=True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_apply=True)
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for z in [14.25+i*.5 for i in range(9)]:cube('Alcove approach',(4,-.08,z),(2.5,.16,.49),wood)
# A narrow continuous strip along the masonry is legal only without a crate.
cube('Side ledge',(1,-.075,20.25),(.55,.15,4.0),wood)
for z in [18.5,22]:cube('Ledge turn',(2.5,-.075,z),(3.5,.15,.6),wood)
cube('Joint darkness',(3,-1.2,20.2),(6,.18,3.2),dark)
cube('Foundation wall',(.55,.38,20.2),(.22,.9,4.0),dark)
for z in range(22,31):
 for x in range(-1,10):cube('Kitchen floorboard',(x,-.085,z+.25),(.97,.17,.97),wood)
for x in [-1.6,9.6]:cube('Kitchen side plinth',(x,.5,26),(.25,1.1,9),dark)
cube('Kitchen rear plinth',(4,.55,31),(11.2,1.2,.25),dark)
# Authored crumbs/dirt around the edges, off the mission corridor.
rng=random.Random(1130)
for i in range(50):
 x=rng.choice([rng.uniform(-1,1),rng.uniform(8.8,9.3)]);z=rng.uniform(23,30)
 o=cube('Dust and splinter',(x,.018,z),(.08+rng.random()*.16,.035,.05),cut);o.rotation_euler[2]=rng.random()*math.tau
cube('Fallen skirting offcut',(1,.13,28.5),(2.7,.25,.35),cut)
save('sector')
for x in [3.38,4.62]:cube('Bridge beam',(x,-.045,20.25),(.11,.16,3.85),cut)
for i in range(15):cube('Cargo deck',(4,.012,18.55+i*.245),(1.4,.07,.235),wood)
for x in [3.28,4.72]:
 for z in [18.55,20.25,22]:cube('Guard post',(x,.43,z),(.075,.85,.075),cut)
 cube('Guard rail',(x,.8,20.25),(.07,.08,3.55),cut)
 for z in [18.55,22]:cube('Lashing',(x,.42,z),(.09,.16,.10),rope)
save('bridge')
# Finite source, deliberately bigger than a resident, made of broken biscuit pieces.
cube('Biscuit body',(0,.12,0),(1.55,.23,1.05),bisc)
cube('Pressed top',(0,.25,0),(1.37,.045,.88),crumb)
for x in [-.52,-.26,0,.26,.52]:
 for z in [-.28,0,.28]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.027,depth=.006,location=(x,-z,.276));bpy.context.object.data.materials.append(bisc)
for x in [-.71,.71]:
 for z in [-.4,-.2,0,.2,.4]:cube('Crimped edge',(x,.257,z),(.085,.025,.065),crumb)
for z in [-.46,.46]:
 for x in [-.5,-.25,0,.25,.5]:cube('Crimped edge',(x,.257,z),(.08,.025,.06),crumb)
for i in range(18):
 a=rng.uniform(0,math.tau);d=rng.uniform(.85,1.25)
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.04,location=(math.cos(a)*d,math.sin(a)*d,.025));bpy.context.object.data.materials.append(crumb)
save('biscuit')
print('KITCHEN_ASSETS_OK')
