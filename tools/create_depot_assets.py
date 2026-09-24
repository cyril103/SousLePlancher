"""Blender 2.93: a compartmented miniature depot from reclaimed matchwood."""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'depots_15'
r.EXPORT = ROOT / 'assets' / 'models' / 'depots_15'
for folder in (r.SOURCE, r.EXPORT): folder.mkdir(parents=True, exist_ok=True)
r.clear()
for i in range(7):
    plank = r.cube('Uneven salvaged base', (-.65+i*.215,0,.07), (.205,.96,.09), r.lightwood, .012)
    plank.rotation_euler.z = (i%3-1)*.008
for x in (-.77,.77):
    for y in (-.48,.48):
        r.cube('Corner match post',(x,y,.38),(.075,.075,.72),r.oak,.012)
        for z in (.18,.51):
            r.line('Twine lashing',[(x-.055,y-.05,z),(x+.055,y-.05,z+.02),(x+.055,y+.05,z+.04),(x-.055,y+.05,z+.06)],.009,r.ivory)
    for z in (.25,.47,.66):
        r.cube('Worn side slat',(x,0,z),(.055,.96,.12),r.lightwood,.014)
for z in (.24,.45,.65):
    r.cube('Rear crate slat',(0,.48,z),(1.48,.055,.13),r.oak,.014)
r.cube('Low front lip',(0,-.48,.20),(1.48,.06,.18),r.lightwood,.015)
r.cube('Central divider',(0,0,.35),(.035,.90,.46),r.paper,.006)
r.cube('Cross divider',(0,0,.35),(1.46,.035,.46),r.paper,.006)
r.cube('Label backing',(.40,-.52,.26),(.46,.02,.18),r.paper,.01)
for i in range(3):
    r.cube('Hand drawn stock marks',(.28+i*.11,-.535,.26),(.025,.004,.10),r.oak,.002)
r.save_asset('local_depot')
print('DEPOT_ASSET_OK')
