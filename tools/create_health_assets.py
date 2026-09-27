"""Small salvaged rescue sled and cloth roll, authored in Blender, gameplay axes."""
import bpy
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/health_29'; SRC=ROOT/'art_source/health_29'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0

def mat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.94
 noise=m.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=95
 bump=m.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.025
 m.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);m.node_tree.links.new(bump.outputs['Normal'],p.inputs['Normal'])
 return m
wood=mat('Reclaimed wood',(.22,.12,.055));cloth=mat('Old linen',(.62,.53,.35));rope=mat('Flax ties',(.36,.25,.12))
def cube(name,pos,size,material):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0],-pos[2],pos[1]))
 o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(material)
 b=o.modifiers.new('Soft edges','BEVEL');b.width=.015;b.segments=3;o.modifiers.new('Normals','WEIGHTED_NORMAL')
def save(name):
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(name+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_apply=True)
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for x in [-.32,.32]:
 cube('Wooden skid',(x,.06,0),(.06,.1,1.85),wood)
 a=Vector((x,-.8,.12));b=Vector((x,-1.25,.85))
 bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=.023,depth=(b-a).length,location=(a+b)/2)
 o=bpy.context.object;o.name='Angled pulling handle';o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(wood)
for z in [-.62,0,.62]:cube('Crossbar',(0,.11,z),(.72,.06,.05),wood)
cube('Folded linen',(0,.15,0),(.61,.07,1.68),cloth)
for z in [-.55,.55]:cube('Linen strap',(0,.196,z),(.65,.016,.055),rope)
save('rescue_sled')
for i in range(8):
 bpy.ops.mesh.primitive_torus_add(major_radius=.075,minor_radius=.014,major_segments=24,minor_segments=8,location=(0,0,.017*i))
 bpy.context.object.data.materials.append(cloth)
cube('Loose cloth end',(.075,.015,.03),(.18,.022,.11),cloth)
save('bandage')
print('HEALTH_ASSETS_OK')
