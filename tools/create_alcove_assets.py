"""Blender 2.93: authored narrow opening and small adjoining alcove."""
import sys, random, math
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'alcove_19'
r.EXPORT = ROOT / 'assets' / 'models' / 'alcove_19'
for path in (r.SOURCE, r.EXPORT): path.mkdir(parents=True, exist_ok=True)
rng = random.Random(1805)
def box(name, x, y, z, w, h, d, mat=None):
    return r.cube(name, (x, -z, y), (w, d, h), mat or r.oak, .018)
r.clear()
# Floor joins the original floor at local z = 0; scenery stays clear of routes.
for i in range(8):
    box('Alcove floorboard',-1.75+i*.5,-.1,3.8,.485,.18,7.6,r.oak)
for x in (-2.1,2.1): box('Alcove side',x,.62,3.8,.15,1.35,7.6,r.oak)
box('Alcove rear',0,.62,7.6,4.2,1.35,.16,r.oak)
for i in range(28):
    x=rng.choice((-1,1))*rng.uniform(1.35,1.85)
    chip=box('Dusty wood fragment',x,.04,rng.uniform(.6,7.3),.25,.07,.1)
    chip.rotation_euler[2]=rng.uniform(-3,3)
r.save_asset('alcove_sector')
print('ALCOVE_ASSETS_OK')
