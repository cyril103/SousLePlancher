"""Blender 2.93: authored narrow opening and small adjoining alcove."""
import sys, random, math
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'fissure_18'
r.EXPORT = ROOT / 'assets' / 'models' / 'fissure_18'
for path in (r.SOURCE, r.EXPORT): path.mkdir(parents=True, exist_ok=True)
rng = random.Random(1805)
def box(name, x, y, z, w, h, d, mat=None):
    return r.cube(name, (x, -z, y), (w, d, h), mat or r.oak, .018)
r.clear()
# Splintered ends define a readable opening without a regular cut-out rectangle.
for side in (-1, 1):
    for i in range(7):
        edge = .55 + rng.uniform(-.08, .08)
        width = 2.5 - edge
        box('Split old joist', side * (edge + width/2), .20 + i*.4, 0, width, .38, .30, r.oak)
        chip = box('Fractured fibre', side * (edge-.035), .2+i*.4, -.025, .14, .32, .25, r.oak)
        chip.rotation_euler[1] = rng.uniform(-.3, .3)
box('Upper lintel', 0, 2.75, 0, 5, .25, .4, r.oak)
for side in (-1, 1):
    for y in (.5, 2.3):
        r.tube('Old iron fastening', (side*1.25,.21,y),(side*1.25,.16,y),.035,r.darkmetal,vertices=10)
r.save_asset('fissure_frame')
r.clear()
for i in range(11):
    obj = box('Loose broken slat', rng.uniform(-.35,.35), .18+i*.19, rng.uniform(-.13,.13), rng.uniform(.75,1.1), .21, .15, r.oak)
    obj.rotation_euler[1] = rng.uniform(-.5,.5)
for i in range(9):
    obj=box('Fallen splinter',rng.uniform(-.8,.8),.045,rng.uniform(-.65,.5),rng.uniform(.2,.6),.08,.1)
    obj.rotation_euler[2]=rng.uniform(-2,2)
r.save_asset('fissure_blocked')
r.clear()
for z in (-.23,.23):
    for x in (-.51,.51):
        box('Recovered upright',x,1.1,z,.16,2.2,.19)
        for y in (.32,1.8):
            for offset in (-.025,0,.025):
                r.line('Twine binding',[(x-.095,-z-.11,y+offset),(x+.095,-z-.11,y+offset),(x+.095,-z+.11,y+offset),(x-.095,-z+.11,y+offset),(x-.095,-z-.11,y+offset)],.012,r.ivory)
    box('Braced header',0,2.22,z,1.3,.22,.23)
r.save_asset('fissure_braces')
r.clear()
# Floor joins the original floor at local z = 0; scenery stays clear of routes.
for i in range(8):
    box('Alcove floorboard',-1.75+i*.5,-.1,1.85,.485,.18,3.7,r.oak)
for x in (-2.1,2.1): box('Alcove side',x,.62,1.85,.15,1.35,3.7,r.oak)
box('Alcove rear',0,.62,3.7,4.2,1.35,.16,r.oak)
for i in range(14):
    x=rng.choice((-1,1))*rng.uniform(1.35,1.85)
    chip=box('Dusty wood fragment',x,.04,rng.uniform(.6,3.4),.25,.07,.1)
    chip.rotation_euler[2]=rng.uniform(-3,3)
r.save_asset('fissure_alcove')
print('FISSURE_ASSETS_OK')
