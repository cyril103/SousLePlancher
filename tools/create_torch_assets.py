"""Hand-sized splinter torch, authored in Blender; origin at the grip."""
import sys, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import create_reference_assets as r
r.SOURCE=ROOT/'art_source'/'torches_16'
r.EXPORT=ROOT/'assets'/'models'/'torches_16'
for p in (r.SOURCE,r.EXPORT):p.mkdir(parents=True,exist_ok=True)
r.clear()
shaft=r.cube('Split wooden splinter',(0,0,.12),(.036,.042,.43),r.oak,.008)
shaft.rotation_euler.y=.045
r.cube('Exposed grain',(.017,0,.12),(.008,.032,.36),r.lightwood,.003)
for i in range(13):
    z=.255+i*.009
    points=[(.043*math.cos(j*math.tau/20),.043*math.sin(j*math.tau/20),z+j*.0003) for j in range(21)]
    r.line('Bound cotton wick',points,.009,r.ivory)
charcoal=r.material('Burnt cotton charcoal',(.035,.025,.016,1),.98)
r.cube('Charred tip',(0,0,.375),(.065,.065,.04),charcoal,.012)
r.save_asset('hand_torch')
print('TORCH_ASSET_OK')
