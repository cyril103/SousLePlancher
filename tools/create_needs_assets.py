"""Water collection point and food portion; Blender-authored, approved materials reused."""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT/'art_source'/'needs_13'
r.EXPORT = ROOT/'assets'/'models'/'needs_13'
for folder in (r.SOURCE,r.EXPORT): folder.mkdir(parents=True,exist_ok=True)
r.clear()
water=r.material('Collected clear water',(.13,.39,.43),.15,.15)
with r.bpy.data.libraries.load(str(ROOT/'art_source/reference_01/thimble_bucket.blend'),link=False) as (src,dst):
    dst.objects=[name for name in src.objects if name.endswith('_mesh')]
bucket=dst.objects[0]
r.bpy.context.collection.objects.link(bucket)
for i,(x,y) in enumerate([(-.27,0),(.27,.02),(0,-.28)]):
    obj=bucket if i==0 else bucket.copy()
    if i:r.bpy.context.collection.objects.link(obj)
    obj.location=(x,y,.06)
    r.bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.176,depth=.008,location=(x,y,.42))
    surface=r.bpy.context.object;surface.name='Collected water';surface.data.materials.append(water)
for i in range(5):r.cube('Collection tray slat',(-.44+i*.22,-.05,.03),(.21,.95,.055),r.lightwood,.008)
r.save_asset('condensation')
r.clear()
r.ellipsoid('Bread crumb',(0,0,.035),(.045,.036,.04),r.label,segments=16,rings=8)
for i in range(5):r.ellipsoid('Crust',(i*.012-.024,.02,.061),(.009,.012,.008),r.rust,segments=8,rings=4)
r.save_asset('ration')
print('NEEDS_ASSETS_OK')
