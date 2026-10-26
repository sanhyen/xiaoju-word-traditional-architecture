"""Editable precision craft library, derived from the actual approved-for-rollout sample method."""
from pathlib import Path
import json,math,shutil
import numpy as np
import craft160_geometry as g
ROOT=Path(__file__).resolve().parents[1];DEST=ROOT/'assets/craft160'

def main():
    g.OUT=DEST;g.TEX=DEST/'textures';g.MODEL=DEST/'models';g.textures()
    for args in [('red','7f2c24',.38,0,'wood.png','wood_normal.png'),('wood','392319',.52,0,'wood.png','wood_normal.png'),('wood_light','795339',.52,0,'wood.png','wood_normal.png'),('tile','427e70',.24,.05,'stone.png','stone_normal.png'),('tile_light','6e9c87',.3,.05),('tile_dark','214d49',.5),('gold','c6a25e',.32,.7),('bronze','9b8554',.4,.62),('paint','ffffff',.62,0,'artisan_paint.png'),('stone','c8c3af',.8,0,'stone.png','stone_normal.png'),('plaster','e6ddc8',.9,0,'plaster.png','plaster_normal.png'),('jade','598f82',.26),('porcelain','e1d7bd',.19,0,'porcelain.png'),('fabric','c4af87',.9,0,'linen.png'),('paper','e0d8b8',.95),('book0','35565d',.9),('book1','766347',.9),('book2','8b4f3b',.9)]:g.material(*args)
    g.material('lamp','efd3a0',.8,emission=[.8,.46,.16]);g.material('painting','ffffff',.94,0,'landscape_painting.png')
    g.group='dougong';g.dougong()
    g.group='column_base';g.lathe([(.48,0),(.48,.10),(.44,.14),(.43,.25),(.35,.31),(.32,.39)],'stone',32);g.ring((0,.43,0),.292,.024,'bronze')
    for v in range(3):g.group='lattice_'+str(v);g.lattice(2,1.7,v)
    g.group='paint_beam';g.frame_panel(3,.38)
    g.group='carved_panel';g.carved_panel(1.7,2.3)
    g.group='coffer';g.ceiling_coffer(0,0,0,2,2)
    g.group='caisson'
    with g.at(0,-4.65,0):g.caisson()
    g.group='table';g.table(2,.98,1.1)
    g.group='round_table'
    g.lathe([(.82,.04),(.84,.12),(.18,.19),(.13,.78),(.30,.82),(.98,.82),(1,.86),(1,.98),(.94,1)],'wood',48)
    g.ring((0,.99,0),.93,.018,'bronze',n=64)
    g.group='chair';g.chair()
    g.group='settee'
    g.table(2.1,.55,.85)
    g.block((0,.57,0),(1.96,.14,.75),'fabric',.1)
    for x in [-.98,.98]:g.tube([(x,.5,-.32),(x,1.12,-.32),(x,.98,.34)],.055,'wood',10)
    g.tube(g.bezier([(-1.03,1.08,-.32),(-.5,1.26,-.32),(.5,1.26,-.32),(1.03,1.08,-.32)]),.065,'wood',12)
    with g.at(0,.85,-.32):g.lattice(1.86,.47,1)
    g.group='daybed'
    g.table(1.6,.60,2.8)
    g.block((0,.69,0),(1.55,.18,2.65),'fabric',.10)
    g.block((0,.82,-.8),(1.4,.15,.5),'fabric',.12)
    for x in [-.73,.73]:
        g.tube([(x,.56,-1.31),(x,1.32,-1.31),(x,1.45,-1.31)],.055,'wood',12)
    with g.at(0,1.08,-1.31):g.lattice(1.38,.50,2)
    g.tube(g.bezier([(-.78,1.4,-1.31),(-.35,1.6,-1.31),(.35,1.6,-1.31),(.78,1.4,-1.31)]),.06,'wood',12)
    g.cloud(0,1.48,-1.26,.55,'gold')
    g.group='bookcase'
    for x in [-1.1,1.1]:g.block((x,1.15,0),(.13,2.3,.6),'wood',.035)
    for y in [.12,.72,1.34,1.97,2.32]:g.block((0,y,0),(2.2,.1,.6),'wood',.03)
    g.block((0,1.18,-.27),(2.08,2.3,.05),'wood_light')
    for y in [.77,1.39,2.02]:
        for i in range(7):
            hh=.29+(i%3)*.06;g.block((-.88+i*.24,y+hh*.5,.02),(.16,hh,.30),'book'+str(i%3),.012)
            g.block((-.88+i*.24,y+hh-.04,.177),(.13,.013,.008),'gold')
    g.cloud(0,2.43,.1,.95,'wood_light')
    g.group='cabinet'
    for x in [-1.1,1.1]:g.block((x,1.15,0),(.13,2.3,.6),'wood',.035)
    for y in [.12,.72,1.34,1.97,2.32]:g.block((0,y,0),(2.2,.1,.6),'wood',.03)
    g.block((0,1.18,-.27),(2.08,2.3,.05),'wood_light');g.cloud(0,2.43,.1,.95,'wood_light')
    g.group='vase';g.vase(.6)
    g.group='lantern';g.lantern((0,0,0),.3)
    g.group='screen';g.screen(2.4,2.5)
    g.group='roof_finial'
    g.tube(g.bezier([(0,0,0),(.45,.18,0),(.48,.8,0),(.18,1,0)]),np.linspace(.13,.02,20),'bronze',10)
    g.ellipsoid((.16,.65,0),(.13,.19,.12),'bronze',14,8)
    g.group='tile_strip'
    # One physical 26 cm x 42 cm curved cover tile, open underside, closed leading rim.
    g.grid(lambda u,v:(.116*math.cos(math.pi*u),.11*math.sin(math.pi*u),(.5-v)*.42),8,2,'tile',False)
    g.tube([(.12*math.cos(t),.115*math.sin(t),.21) for t in np.linspace(0,math.pi,12)],.012,'tile_light',6)
    g.group='tile_end';g.ring((0,0,0),.105,.018,'tile_light','z',20);g.ellipsoid((0,0,.008),(.043,.043,.025),'tile_light',10,6)
    g.group='rafter';g.tube([(0,0,0),(0,0,1)],.055,'red',10)
    g.group='crane'
    g.ellipsoid((0,0,0),(4.5,2.15,1.8),'porcelain',32,20)
    g.tube(g.bezier([(2.4,.6,0),(5,2.0,0),(4.8,7.7,0),(7.8,9,0)],40),np.linspace(1.0,.42,40),'porcelain',16)
    g.ellipsoid((8.1,9,0),(.85,.68,.55),'porcelain',24,16)
    g.tube([(8.6,8.95,0),(12.6,8.5,0)],np.array([.25,.015]),'bronze',14)
    for side in [-1,1]:
        g.ellipsoid((8.4,9.15,side*.48),(.10,.12,.05),'wood',12,8)
        for i in range(12):
            with g.at(-i*.27,1.1+math.sin(i*.14)*2,side*(1.5+i*.72),-.1*side):
                g.tube(g.bezier([(0,0,0),(-1,1,side*1.5),(-3,1.1,side*3.6),(-4-i*.19,-.5,side*5.1)],20),np.linspace(.48,.025,20),'porcelain' if i<8 else 'tile_light',10)
    g.group='halo';g.tube([(math.cos(t),math.sin(t),0) for t in np.linspace(0,2*math.pi,193)],.016,'bronze',12)
    for i in range(32):
        t=i*math.pi/16;g.ellipsoid((math.cos(t),math.sin(t),0),(.024,.024,.024),'gold',10,8)
    g.group='floating_under'
    g.lathe([(5,0),(5,-.2),(4.8,-.5),(4.2,-.8),(4,-1.2),(3.1,-1.5),(2.3,-2.0),(1.7,-2.5),(.9,-3.6),(.08,-4.3)],'stone',48)
    for t in np.linspace(0,2*math.pi,12,endpoint=False):
        g.tube(g.bezier([(4.7*math.cos(t),-.4,4.7*math.sin(t)),(4*math.cos(t+.12),-2.2,4*math.sin(t+.12)),(2.1*math.cos(t),-3.6,2.1*math.sin(t)),(1.4*math.cos(t+.2),-5,1.4*math.sin(t+.2))],32),np.linspace(.09,.012,32),'wood_light',8)
    g.export_glb()
    (g.MODEL/'royal_courtyard.glb').replace(g.MODEL/'precision_library.glb')
    layout=json.loads((DEST/'layout.json').read_text(encoding='utf-8'))
    layout.update(scope='Full-world precision component library; no collisions are imported from sample',sources=['tools/craft160_world_assets.py','tools/craft160_geometry.py'])
    (DEST/'library.json').write_text(json.dumps(layout,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Precision library groups:',len(layout['groups']))
if __name__=='__main__':main()
