"""Expand the original Blender stage while preserving the central gameplay props."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_source/floor.blend'))
bpy.context.preferences.filepaths.save_version=0
for o in bpy.data.objects:
 name=o.name
 if name.startswith(('Lame','Fibre','Clou','Socle','Plinthe','Solive')):
  o.location.x*=2; o.location.y*=2
  o.scale.x*=2; o.scale.y*=2
 elif name.startswith(('Pied','Collerette')):
  o.location.y*=2
 elif name.startswith(('Canalisation','Raccord')):
  o.location.y*=2
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/floor_expanded.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/floor_expanded.glb'),export_format='GLB',export_apply=True)
print('EXPANDED_FLOOR_OK')
