"""Blender 2.93: authored narrow opening and small adjoining alcove."""
import sys, random, math
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'passage_20'
r.EXPORT = ROOT / 'assets' / 'models' / 'passage_20'
for path in (r.SOURCE, r.EXPORT): path.mkdir(parents=True, exist_ok=True)
rng = random.Random(1805)
def box(name, x, y, z, w, h, d, mat=None):
    return r.cube(name, (x, -z, y), (w, d, h), mat or r.oak, .018)
r.clear()
# Splintered ends define a readable opening without a regular cut-out rectangle.
for side in (-1, 1):
    for i in range(7):
        edge = 1.12 + rng.uniform(-.08, .08)
        width = 2.5 - edge
        box('Split old joist', side * (edge + width/2), .20 + i*.4, 0, width, .38, .30, r.oak)
        chip = box('Fractured fibre', side * (edge-.035), .2+i*.4, -.025, .14, .32, .25, r.oak)
        chip.rotation_euler[1] = rng.uniform(-.3, .3)
box('Upper lintel', 0, 2.75, 0, 5, .25, .4, r.oak)
for side in (-1, 1):
    for y in (.5, 2.3):
        r.tube('Old iron fastening', (side*1.25,.21,y),(side*1.25,.16,y),.035,r.darkmetal,vertices=10)
r.save_asset('wide_frame')
r.clear()
for z in (-.23,.23):
    for x in (-1.0,1.0):
        box('Recovered upright',x,1.1,z,.16,2.2,.19)
        for y in (.32,1.8):
            for offset in (-.025,0,.025):
                r.line('Twine binding',[(x-.095,-z-.11,y+offset),(x+.095,-z-.11,y+offset),(x+.095,-z+.11,y+offset),(x-.095,-z+.11,y+offset),(x-.095,-z-.11,y+offset)],.012,r.ivory)
    box('Braced header',0,2.22,z,2.3,.22,.23)
r.save_asset('wide_braces')
