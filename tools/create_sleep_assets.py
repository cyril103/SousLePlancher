"""Handmade individual privacy screens and bed construction kit, authored in Blender."""
import math
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'sleep_12'
r.EXPORT = ROOT / 'assets' / 'models' / 'sleep_12'
for folder in (r.SOURCE, r.EXPORT): folder.mkdir(parents=True, exist_ok=True)
r.clear()
# Open front, independent side partitions: every bed has its own alcove.
for x in (-.72, .72):
    for y in (-.94, 1.13):
        r.cube('Split matchwood post', (x,y,.74), (.055,.06,1.48), r.lightwood, .008)
        for z in (.16,1.31):
            r.line('Cotton lash', [(x-.045,y-.05,z),(x+.045,y-.05,z+.02),(x+.045,y+.05,z+.04),(x-.045,y+.05,z+.06)], .009, r.ivory)
    r.tube('Upper rail', (x,-.97,1.42),(x,1.16,1.42),.026,r.oak,vertices=8)
    # Each narrow cloth panel sags differently and has an irregular hem.
    verts=[]; faces=[]
    for j in range(25):
        y=-.9+j*2.0/24
        for k in range(9):
            t=k/8
            z=.14+(1.37-.14)*t + .024*math.sin(j*.77)*(1-t)
            xx=x+.027*math.sin(j*1.4)+.018*math.sin(t*math.pi)
            verts.append((xx,y,z))
    for j in range(24):
        for k in range(8):
            a=j*9+k; faces.append((a,a+9,a+10,a+1))
    mesh=r.bpy.data.meshes.new('Pleated linen'); mesh.from_pydata(verts,[],faces); mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for face in mesh.polygons:
        for loop in face.loop_indices:
            vertex=mesh.loops[loop].vertex_index
            uv.data[loop].uv=((vertex//9)/24,(vertex%9)/8)
    obj=r.bpy.data.objects.new('Reused linen privacy screen',mesh);r.bpy.context.collection.objects.link(obj)
    obj.data.materials.append(r.shirt)
    solid=obj.modifiers.new('Double sided cloth','SOLIDIFY');solid.thickness=.008
    for j in range(9):
        y=-.87+j*.24
        r.line('Stitched top loops',[(x,y,1.33),(x-.025,y,1.46),(x+.025,y,1.46),(x,y,1.33)],.006,r.ivory)
    r.line('Weighted hem',[(x+.027*math.sin(j*1.4),-.9+j*2/24,.14+.024*math.sin(j*.77)) for j in range(25)],.009,r.ivory)
# Back wall: irregular strips of used cardboard and timber, with no roof.
for i in range(7):
    x=-.62+i*.206
    r.cube('Recovered cardboard strip',(x,1.12,.69),(.199,.038,1.32-(i%3)*.027),r.paper,.009)
r.cube('Rear brace',(0,1.155,.35),(1.49,.035,.075),r.oak,.007)
r.cube('Rear brace',(0,1.155,1.15),(1.49,.035,.065),r.lightwood,.007)
r.save_asset('privacy_partition')
r.clear()
for i in range(5):
    board=r.cube('Bed frame timber',(-.35+i*.16,0,.055+i*.015),(.13,1.65,.07),r.lightwood,.009)
    board.rotation_euler.z=(i-2)*.02
r.cube('Folded bedding',(.30,.35,.23),(.52,.5,.27),r.shirt,.07)
for i in range(3):r.tube('Spare match brace',(-.45,-.5,.15+i*.03),(.4,-.35,.15+i*.03),.022,r.oak,vertices=8)
r.save_asset('bed_materials')
r.clear()
for s in (-1,1):
    # Coordinates relative to the approved resident's head bone (Z = 1.20).
    r.ellipsoid('Closed eyelid',(s*.047,-.116,.239),(.021,.012,.013),r.skin,segments=16,rings=8)
    r.line('Resting eyelid seam',[(s*.029,-.123,.239),(s*.047,-.129,.236),(s*.064,-.121,.238)],.0015,r.hair)
r.save_asset('closed_eyes')
print('SLEEP_ASSETS_OK')
