"""Blender-authored chamber envelope; Godot X/Z footprint 3.4 by 3.9 m.
Reuses the approved reference_02 PBR textures. No roof: colony cutaway view.
"""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/rooms_27'
SRC=ROOT/'art_source/rooms_27'
OUT.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0

def mat(name):
 m=bpy.data.materials.new(name); m.use_nodes=True
 n=m.node_tree.nodes; p=n.get('Principled BSDF'); p.inputs['Roughness'].default_value=.86
 t=n.new('ShaderNodeTexImage'); t.image=bpy.data.images.load(str(ROOT/'assets/textures/reference_02'/(name+'_basecolor.png')))
 m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
 return m
wood=mat('old_wood'); cut=mat('cut_wood'); paper=mat('cardboard')
HEIGHT=1.0
def cube(name,pos,size,material):
 # Author in gameplay coordinates, converted to Blender Z-up.
 bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0],-pos[2],pos[1]*HEIGHT))
 o=bpy.context.object; o.name=name; o.dimensions=(size[0],size[2],size[1]*HEIGHT)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(material)
 b=o.modifiers.new('Worn edges','BEVEL');b.width=.008;b.segments=2
 o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return o

def save(name):
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_apply=True)
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for i in range(12):
 cube('Reclaimed floor strip',(-1.55+i*.28,-.012,.35),(.272,.04,3.8),wood)
save('floor')
HEIGHT=1.3 # Lintel clearance 1.78 m for the 1.60 m resident and carried crate.
# Low salvaged-cardboard walls between tied timber uprights.
for side in [-1,1]:
 for i in range(10): cube('Side cardboard panel',(side*1.7,.65,-1.42+i*.39),(.10,1.3,.38),paper)
 for z in [-1.6,.35,2.3]: cube('Corner upright',(side*1.7,.73,z),(.12,1.46,.12),cut)
 for h in [.14,1.28]: cube('Side rail',(side*1.7,h,.35),(.14,.09,3.9),wood)
for i in range(9):cube('Back panel',(-1.51+i*.3775,.65,-1.6),(.37,1.3,.10),paper)
for x in [-1.7,-.68,.68,1.7]:cube('Front upright',(x,.73,2.3),(.12,1.46,.12),cut)
for side in [-1,1]:
 cube('Front wall',(side*1.19,.65,2.3),(.90,1.3,.10),paper)
 cube('Front rail',(side*1.19,1.28,2.3),(1.02,.09,.14),wood)
cube('Door lintel',(0,1.43,2.3),(1.48,.12,.14),cut)
cube('Sliding door rail',(.6,1.53,2.4),(2.6,.08,.09),wood)
save('walls')
cube('Sliding cardboard door',(0,.66,0),(1.27,1.30,.08),paper)
for x in [-.59,.59]:cube('Door edge',(x,.66,0),(.07,1.32,.10),cut)
for h in [.14,1.13]:cube('Door brace',(0,h,-.02),(1.25,.065,.10),wood)
cube('Pull handle',(.40,.70,.09),(.055,.20,.08),cut)
save('door')
print('ROOM_ASSETS_OK')
