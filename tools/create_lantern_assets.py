"""Blender 2.93: enclosed miniature belt lantern, origin at the belt loop."""
import sys, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import create_reference_assets as r
r.SOURCE=ROOT/'art_source'/'lanterns_17'
r.EXPORT=ROOT/'assets'/'models'/'lanterns_17'
for p in (r.SOURCE,r.EXPORT): p.mkdir(parents=True,exist_ok=True)
r.clear()
brass=r.material('Recovered dark brass',(.24,.15,.065),.42,.7)
soot=r.material('Wick soot',(.027,.020,.012),.95)
glass=r.material('Amber mica panes',(.75,.55,.26),.22)
glass.blend_method='BLEND'
glass.use_screen_refraction=True
glass.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=.20
glass.diffuse_color=(.75,.55,.26,.20)
# Closed shell, warm mica panes, matchwood posts and rolled metal caps.
for z in (-.085,-.295):
    r.cube('Rolled cap',(0,0,z),(.18,.15,.027),brass,.012)
for x in (-.073,.073):
    for y in (-.058,.058):
        r.cube('Matchwood frame',(x,y,-.19),(.015,.015,.20),r.oak,.004)
        r.tube('Frame rivet',(x,y,-.083),(x,y,-.067),.009,brass,vertices=8)
for x in (-.072,.072): r.cube('Side mica',(x,0,-.19),(.002,.10,.18),glass,.001)
for y in (-.057,.057): r.cube('Front mica',(0,y,-.19),(.13,.002,.18),glass,.001)
r.tube('Wax stub',(0,0,-.28),(0,0,-.226),.025,r.ivory,vertices=16)
r.tube('Cotton wick',(0,0,-.227),(0,0,-.211),.005,soot,vertices=8)
r.tube('Vent hood',(0,0,-.071),(0,0,-.041),.081,brass,radius2=.046,vertices=16)
for i in range(6):
    a=i*math.tau/6
    r.cube('Vent slit',(.047*math.cos(a),.047*math.sin(a),-.045),(.009,.009,.01),soot,.002)
r.line('Leather belt loop',[(-.025,0,-.042),(-.03,0,.018),(0,0,.04),(.03,0,.018),(.025,0,-.042)],.011,r.leather)
r.cube('Closure latch',(.024,-.07,-.19),(.025,.012,.046),brass,.004)
r.save_asset('belt_lantern')
print('LANTERN_ASSET_OK')
