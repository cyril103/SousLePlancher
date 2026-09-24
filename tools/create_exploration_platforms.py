"""Blender platforms with matching side openings for the approved bridge kit."""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'exploration_10'
r.EXPORT = ROOT / 'assets' / 'models' / 'exploration_10'
for folder in (r.SOURCE, r.EXPORT): folder.mkdir(parents=True, exist_ok=True)

def platform(name, width, near):
    r.clear()
    half = width / 2
    for x in (-half+.12, half-.12):
        for y in (-1.38,1.38):
            r.cube('Timber support',(x,y,.95),(.13,.13,1.9),r.oak,.012)
        r.cube('Deck bearer',(x,0,1.9),(.16,3,.16),r.oak,.012)
    for i in range(15):
        y = -1.4+i*.2
        r.cube('Reclaimed floorboard',(0,y,2.005),(width,.193,.07),r.lightwood if i%4 else r.oak,.005)
        for x in (-half+.12,half-.12):
            r.tube('Dark pin',(x,y,2.038),(x,y,2.043),.013,r.darkmetal,vertices=8)
    left,right=-half+.06,half-.06
    opening = right if near else left
    closed = left if near else right
    edges=[((left,1.44),(right,1.44)),((closed,-1.44),(closed,1.44)),
           ((opening,-1.44),(opening,-1.10)),((opening,0),(opening,1.44))]
    if near:
        edges += [((left,-1.44),(.4,-1.44)),((1.6,-1.44),(right,-1.44))]
    else:
        edges += [((left,-1.44),(right,-1.44))]
    for a,b in edges:
        for x,y in (a,b):
            r.cube('Rail upright',(x,y,2.37),(.055,.055,.66),r.oak,.008)
        for z in (2.35,2.66):
            r.line('Cotton guard rope',[(a[0],a[1],z),((a[0]+b[0])/2,(a[1]+b[1])/2,z-.05),(b[0],b[1],z)],.012,r.ivory)
    r.save_asset(name)

platform('landing_connected',4,True)
platform('east_store_platform',3,False)
print('EXPLORATION_PLATFORMS_OK')
