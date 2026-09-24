"""Blender refuge kit, using the approved material family from reference_02.
Run blender --background --python tools/create_refuge_assets.py
"""
import bpy
import math
import json
import random
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import create_reference_assets as r

r.SOURCE=ROOT/'art_source'/'refuge_02'
r.EXPORT=ROOT/'assets'/'models'/'refuge_02'
for path in (r.SOURCE,r.EXPORT):path.mkdir(parents=True,exist_ok=True)


def beam(name,a,b,width=.09,depth=.09,mat=None):
    from mathutils import Vector
    a,b=Vector(a),Vector(b)
    obj=r.cube(name,(a+b)/2,(width,depth,(b-a).length),mat or r.oak,.008)
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return obj


def peg(x,y,z):
    r.tube('Bent pin fastening',(x,y+.01,z),(x,y-.013,z),.012,r.darkmetal,vertices=10)


def frame():
    for x in [-.94,.94]:r.cube('Matchwood upright',(x,0,1.1),(.12,.16,2.2),r.lightwood,.008)
    for z in [.065,2.135]:r.cube('Horizontal timber',(0,0,z),(1.76,.15,.13),r.lightwood,.007)


def boards(x0,x1,z0,z1,seed):
    rng=random.Random(seed)
    count=max(1,round((x1-x0)/.18))
    step=(x1-x0)/count
    for i in range(count):
        x=x0+(i+.5)*step
        o=r.cube('Reclaimed wall strip',(x,.025,(z0+z1)/2),(step-.007,.075,z1-z0),r.oak if i%3 else r.lightwood,.004)
        o.rotation_euler.y=rng.uniform(-.002,.002)
        for z in [z0+.08,z1-.08]:peg(x,-.018,z)


def lash(x,y,z):
    for j in range(3):
        dz=(j-1)*.023
        r.line('Cotton binding',[(x-.063,y-.065,z+dz),(x+.063,y-.065,z+dz+.012),(x+.063,y+.065,z+dz+.022),(x-.063,y+.065,z+dz+.015),(x-.063,y-.065,z+dz)],.006,r.ivory)


def wall_plain():
    r.clear();frame();boards(-.88,.88,.13,2.07,18)
    beam('Diagonal repair brace',(-.79,-.057,.25),(.78,-.057,1.98),.065,.043)
    for x in [-.94,.94]:
        for z in [.18,2.0]:lash(x,0,z)
    r.save_asset('wall_solid_2m')


def wall_window():
    r.clear();frame()
    boards(-.88,-.5,.13,2.07,11);boards(.5,.88,.13,2.07,12)
    boards(-.5,.5,.13,.81,14);boards(-.5,.5,1.79,2.07,15)
    for x in [-.49,.49]:r.cube('Window jamb',(x,-.022,1.30),(.07,.16,1.02),r.lightwood,.007)
    for z in [.82,1.78]:r.cube('Window frame',(0,-.022,z),(1.05,.17,.07),r.lightwood,.007)
    r.cube('Wide sill',(0,-.12,.82),(1.16,.40,.065),r.oak,.009)
    r.cube('Window mullion',(0,.022,1.30),(.037,.044,.90),r.lightwood,.005)
    r.cube('Window crossbar',(0,.022,1.34),(.92,.044,.036),r.lightwood,.005)
    # A rolled fabric blind makes the opening habitable without hiding it.
    r.tube('Rolled linen blind',(-.48,-.09,1.9),(.48,-.09,1.9),.071,r.vest,vertices=24)
    for x in [-.31,.31]:
        r.line('Blind tie',[(x,-.15,1.87),(x,-.10,1.98),(x,-.01,1.87),(x,-.15,1.87),(x,-.14,1.66)],.007,r.ivory)
    r.save_asset('wall_window_2m')


def doorway():
    r.clear();frame()
    boards(-.88,-.59,.13,2.07,21);boards(.59,.88,.13,2.07,22)
    for x in [-.56,.56]:r.cube('Door jamb',(x,-.03,1.0),(.1,.19,2.0),r.lightwood,.008)
    r.cube('Door lintel',(0,-.03,2.025),(1.22,.21,.15),r.lightwood,.008)
    r.cube('Threshold',(0,-.03,.025),(1.04,.27,.05),r.oak,.009)
    r.save_asset('wall_doorway_2m')


def door():
    r.clear()
    for i in range(5):r.cube('Door slat',(.105+i*.199,0,.98),(.192,.073,1.89),r.oak if i%2 else r.lightwood,.006)
    for z in [.32,1.63]:r.cube('Door cross brace',(.50,-.055,z),(.95,.045,.09),r.lightwood,.006)
    beam('Door diagonal',(.1,-.063,.36),(.9,-.063,1.59),.06,.04)
    for z in [.33,1.63]:
        r.cube('Tin hinge strap',(.10,-.088,z),(.20,.025,.065),r.metal,.006)
        r.tube('Hinge pin',(0,-.075,z-.07),(0,-.075,z+.07),.023,r.darkmetal,vertices=12)
    r.line('Wire latch handle',[(.85,-.055,1.0),(.87,-.13,1.0),(.87,-.13,.90),(.85,-.055,.90)],.012,r.darkmetal)
    r.save_asset('door_leaf_1m')


def ladder():
    r.clear()
    for x in [-.36,.36]:
        beam('Ladder rail',(x,-.32,.04),(x,.16,2.52),.08,.08,r.lightwood)
    for i in range(9):
        z=.2+i*.255;y=-.32+.48*z/2.52
        r.cube('Ladder rung',(0,y-.032,z),(.81,.09,.057),r.oak,.012)
        for x in [-.36,.36]:lash(x,y,z)
    r.save_asset('ladder_2m')


def bridge():
    r.clear()
    for x in [-.42,.42]:r.cube('Bridge stringer',(x,0,-.07),(.09,2,.14),r.oak,.009)
    for i in range(12):
        y=-.92+i*(1.84/11)
        plank=r.cube('Matchstick deck',(0,y,.018),(.99,.15,.066),r.lightwood if i%3 else r.oak,.009)
        plank.rotation_euler.z=.006*math.sin(i*4)
        for x in [-.4,.4]:r.tube('Deck pin',(x,y,.04),(x,y,.055),.009,r.darkmetal,vertices=8)
    for x in [-.48,.48]:
        for y in [-.94,0,.94]:
            r.cube('Rail post',(x,y,.43),(.065,.065,.9),r.lightwood,.01)
            lash(x,y,.75)
        r.line('Rope handrail',[(x,-.95,.83),(x,-.48,.78),(x,0,.83),(x,.48,.78),(x,.95,.83)],.017,r.leather)
        r.line('Lower rope',[(x,-.95,.40),(x,-.48,.34),(x,0,.40),(x,.48,.34),(x,.95,.40)],.010,r.ivory)
    r.save_asset('bridge_2m')


def workbench():
    r.clear()
    for x in [-.73,.73]:
        for y in [-.32,.32]:
            r.cube('Workbench matchwood leg',(x,y,.45),(.09,.09,.9),r.lightwood,.008)
            lash(x,y,.23)
    for i in range(4):r.cube('Workbench tabletop',(0,-.33+i*.22,.94),(1.72,.21,.09),r.oak if i%2 else r.lightwood,.009)
    r.cube('Low tool shelf',(0,0,.22),(1.53,.72,.055),r.oak,.009)
    for x in [-.73,.73]:beam('Bench diagonal',(x,-.29,.25),(x,.29,.8),.045,.045)
    # Thread spool, wire needle and cobbled pin hammer identify the workshop.
    r.tube('Spool core',(-.52,.18,1.01),(-.52,.18,1.35),.115,r.rust,vertices=24)
    for z in [1.0,1.36]:r.tube('Spool flange',(-.52,.18,z-.025),(-.52,.18,z+.025),.16,r.paper,vertices=24)
    for i in range(12):
        z=1.025+i*.026
        r.line('Wound thread',[(-.52+.118*math.cos(a*math.pi/8),.18+.118*math.sin(a*math.pi/8),z) for a in range(17)],.004,r.ivory)
    r.line('Loose sewing thread',[(-.41,.18,1.10),(-.25,.12,1.0),(-.20,-.20,1.0),(-.05,-.34,1.0)],.004,r.ivory)
    beam('Hammer handle',(.14,-.29,1.01),(.37,.10,1.01),.037,.037,r.leather)
    r.tube('Hammer salvaged pin head',(.29,.13,1.04),(.49,.04,1.04),.045,r.metal,vertices=16)
    r.cube('Scrap cutting board',(.48,.18,1.007),(.43,.30,.025),r.lightwood,.012)
    r.tube('Sewing needle',(-.16,.28,1.025),(.19,.15,1.025),.006,r.metal,vertices=8)
    r.cube('Fabric offcut',(-.23,0,.275),(.57,.36,.035),r.vest,.014)
    r.cube('Folded fabric',(.25,.05,.28),(.38,.29,.05),r.shirt,.015)
    r.save_asset('salvage_workbench')


for builder in [wall_plain,wall_window,doorway,door,ladder,bridge,workbench]:builder()
metadata={
    'status':'reference kit v0.1, visual assets; gameplay not implemented',
    'grid':{'wall_width':2.0,'wall_height':2.2,'floor_grid':2.0,'resident_height':1.58},
    'assets':r.MANIFEST,
    'anchors_godot':{
        'wall_solid_2m':{'left':[-1,0,0],'right':[1,0,0]},
        'wall_window_2m':{'left':[-1,0,0],'right':[1,0,0]},
        'wall_doorway_2m':{'hinge':[-.505,0,.075],'clearance_width':1.02,'clearance_height':1.95},
        'door_leaf_1m':{'pivot':[0,0,0],'opening_angle_degrees':-100},
        'ladder_2m':{'bottom':[0,0,.32],'top':[0,2.2,-.11]},
        'bridge_2m':{'entry':[0,.05,1],'exit':[0,.05,-1]},
        'salvage_workbench':{'operator':[0,0,1.05]}},
    'limits':['No navigation or agent traversal','No construction/damage states','Door opens in review only','No production collision shapes yet']}
(r.SOURCE/'manifest.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
print('REFUGE_KIT_OK',json.dumps(r.MANIFEST))
