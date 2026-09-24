"""Blender-built resource landing. Deck top matches the approved 2.04 m animation."""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import create_reference_assets as r
r.SOURCE = ROOT / 'art_source' / 'navigation_08'
r.EXPORT = ROOT / 'assets' / 'models' / 'navigation_08'
for folder in (r.SOURCE, r.EXPORT): folder.mkdir(parents=True, exist_ok=True)
r.clear()
# Blender Y becomes negative Godot Z. Front edge Y=-1.5, opening X=1.
for x in (-1.88, 0, 1.88):
    for y in (-1.38, 1.38):
        r.cube('Salvaged timber support', (x,y,.95), (.13,.13,1.90), r.oak,.012)
    r.cube('Deck bearer', (x,0,1.90), (.16,3,.16), r.oak,.012)
for i in range(15):
    y = -1.4 + i*.2
    r.cube('Reclaimed floorboard', (0,y,2.005), (4,.193,.07), r.lightwood if i%4 else r.oak,.005)
    for x in (-1.88, 0, 1.88):
        r.tube('Dark fastening pin',(x,y,2.038),(x,y,2.043),.013,r.darkmetal,vertices=8)
# Low rope rails leave the ladder approach open at X=.45..1.55.
edges = [((-1.94,-1.44),(.40,-1.44)),((1.60,-1.44),(1.94,-1.44)),
         ((-1.94,1.44),(1.94,1.44)),((-1.94,-1.44),(-1.94,1.44)),((1.94,-1.44),(1.94,1.44))]
for a,b in edges:
    for x,y in (a,b):
        r.cube('Rail upright',(x,y,2.37),(.055,.055,.66),r.oak,.008)
    for z in (2.35,2.66):
        r.line('Sagging cotton guard rope',[(a[0],a[1],z),((a[0]+b[0])/2,(a[1]+b[1])/2,z-.05),(b[0],b[1],z)],.012,r.ivory)
r.save_asset('resource_landing')
print('LANDING_ASSET_OK')
