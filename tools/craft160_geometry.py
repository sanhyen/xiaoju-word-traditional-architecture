"""Original editable curved-mesh courtyard assets, metre scale, glTF 2.0.

Authoring source is this deterministic Python model, not the old box palace
generator. No museum photographs are baked into the geometry or materials.
"""
from pathlib import Path
from contextlib import contextmanager
from collections import defaultdict
import json, math, struct, time
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/craft160'
TEX=OUT/'textures'; MODEL=OUT/'models'
PI=math.pi
rng=np.random.default_rng(16026)
groups=defaultdict(list); matrices=[np.eye(4)]; group='garden'; counts=defaultdict(int)
colliders=[]; lamps=[]; labels=[]
materials=[]; material_ids={}

def material(name,color,rough=.65,metal=0,texture=None,normal=None,emission=None):
    srgb=[int(color[i:i+2],16)/255 for i in (0,2,4)]
    c=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in srgb]
    m={'name':name,'pbrMetallicRoughness':{'baseColorFactor':c+[1],'metallicFactor':metal,'roughnessFactor':rough}}
    if texture:m['_texture']=texture
    if normal:m['_normal']=normal
    if emission:m['emissiveFactor']=emission
    material_ids[name]=len(materials);materials.append(m)

def textures():
    TEX.mkdir(parents=True,exist_ok=True)
    n=1024; y,x=np.mgrid[0:n,0:n]; rand=np.random.default_rng(160)
    grain=np.sin(x*.11+2*np.sin(y*.007)+.4*np.sin(y*.03))*.035+np.sin(x*.71+y*.002)*.014
    for name,field in [('wood',grain+rand.normal(0,.012,(n,n))),('stone',rand.normal(0,.02,(n,n))+np.sin(x*.035+np.sin(y*.017))*.015),('plaster',rand.normal(0,.012,(n,n)))]:
        rgb=np.clip((.85+field[:,:,None])*np.ones((1,1,3))*255,0,255).astype('uint8')
        Image.fromarray(rgb).save(TEX/f'{name}.png')
        dy,dx=np.gradient(field); normal=np.stack((-dx*2,-dy*2,np.ones_like(dx)),axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
        Image.fromarray(np.uint8(np.clip(normal*.5+.5,0,1)*255)).save(TEX/f'{name}_normal.png')
    im=Image.new('RGB',(2048,512),(24,66,62)); d=ImageDraw.Draw(im)
    for inset,width,col in [(8,9,'#bd9b53'),(27,3,'#7a9b84'),(44,5,'#b79552'),(63,2,'#527d73')]:
        d.rectangle((inset,inset,2047-inset,511-inset),outline=col,width=width)
    for cx in range(128,2048,256):
        for rad,col,ww in [(95,'#c9ad68',3),(81,'#7ea297',3),(27,'#d3ba7e',4)]:d.ellipse((cx-rad,256-rad,cx+rad,256+rad),outline=col,width=ww)
        for a in np.linspace(0,2*PI,12,endpoint=False):
            pts=[]
            for t in np.linspace(0,2*PI,70):
                rr=53+32*math.cos(t);pp=17*math.sin(t)
                pts.append((cx+math.cos(a)*rr-math.sin(a)*pp,256+math.sin(a)*rr+math.cos(a)*pp))
            d.line(pts,fill='#c5ad6c',width=3)
        for side in [-1,1]:
            pts=[(cx+side*(105+t*16),256+45*math.sin(t*PI)) for t in np.linspace(0,1,40)]
            d.line(pts,fill='#b69b5c',width=3)
    for xx in range(64,2048,64):
        d.line([(xx-15,35),(xx-15,20),(xx+15,20),(xx+15,35)],fill='#c9aa68',width=2)
        d.line([(xx-15,477),(xx-15,492),(xx+15,492),(xx+15,477)],fill='#c9aa68',width=2)
    im.save(TEX/'painted_beam.png')
    # Original relief floor rosette, deliberately tileable rather than a museum photo.
    im=Image.new('RGB',(1024,1024),'#b1ada0');d=ImageDraw.Draw(im)
    d.rectangle((3,3,1020,1020),outline='#817f76',width=6)
    for j in range(4):
        for i in range(4):
            xx=i*256; yy=j*256
            d.rectangle((xx+8,yy+8,xx+248,yy+248),outline='#a29e91',width=3)
    im.save(TEX/'paving.png')
    im=Image.new('RGB',(1024,1024),'#92836a');d=ImageDraw.Draw(im)
    for yy in range(0,1024,8):d.line((0,yy,1024,yy),fill='#a49479',width=2)
    for xx in range(0,1024,8):d.line((xx,0,xx,1024),fill='#8c7e65',width=1)
    im.save(TEX/'linen.png')
    im=Image.new('RGB',(1024,1024),'#d0c8b7');d=ImageDraw.Draw(im)
    for i in range(8):
        xx=i*128;shade=195+(i*7)%23
        d.rectangle((xx,0,xx+127,1023),fill=(shade,shade-4,shade-10))
        d.line((xx,0,xx,1024),fill='#77736a',width=2)
        for j in range(35):
            x0=xx+5+j*3.3
            pts=[(x0+1.5*math.sin(y*.012+i),y) for y in range(0,1024,8)]
            d.line(pts,fill=(shade-9,shade-13,shade-18),width=1)
        yy=(i%3)*341;d.line((xx,yy,xx+127,yy),fill='#827b6d',width=2)
    im.save(TEX/'wood_planks.png')
    im=Image.new('RGB',(1024,1024),'#eeebe0');d=ImageDraw.Draw(im)
    for y0 in [46,72,140,870,930,957]:d.line((0,y0,1024,y0),fill='#355b83',width=5 if y0 in [46,957] else 3)
    for cx in range(64,1024,128):
        cy=500+int(80*math.sin(cx*.02))
        for a in np.linspace(0,2*PI,8,endpoint=False):
            pts=[(cx+(28+24*math.cos(t))*math.cos(a)-10*math.sin(t)*math.sin(a),cy+(28+24*math.cos(t))*math.sin(a)+10*math.sin(t)*math.cos(a)) for t in np.linspace(0,2*PI,35)]
            d.line(pts,fill='#466e97',width=3)
        d.line([(cx,cy+45),(cx+20,cy+160),(cx-10,cy+240)],fill='#466e97',width=4)
    im.save(TEX/'porcelain.png')

@contextmanager
def at(x=0,y=0,z=0,yaw=0):
    c,s=math.cos(yaw),math.sin(yaw)
    m=np.array([[c,0,s,x],[0,1,0,y],[-s,0,c,z],[0,0,0,1]],float)
    matrices.append(matrices[-1]@m)
    yield
    matrices.pop()

def emit(v,f,mat,uv=None,smooth=True):
    v=np.asarray(v,float); f=np.asarray(f,np.uint32)
    if len(f)==0:return
    m=matrices[-1];v=v@m[:3,:3].T+m[:3,3]
    auto_uv=uv is None
    if uv is None:uv=v[:,[0,2]]*.3
    uv=np.asarray(uv,float)
    if not smooth:
        uv=uv[f].reshape(-1,2);v=v[f].reshape(-1,3);f=np.arange(len(v),dtype=np.uint32).reshape(-1,3)
        if auto_uv:
            tri=v[f];face_n=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0]);dominant=np.argmax(np.abs(face_n),axis=1)
            uv=np.empty((len(v),2),float)
            for index,axis in enumerate(dominant):
                axes=[2,1] if axis==0 else ([0,2] if axis==1 else [0,1])
                uv[index*3:index*3+3]=tri[index][:,axes]*.3
    normals=np.zeros_like(v);tri=v[f];n=np.cross(tri[:,1]-tri[:,0],tri[:,2]-tri[:,0])
    for k in range(3):np.add.at(normals,f[:,k],n)
    normals/=np.maximum(1e-10,np.linalg.norm(normals,axis=1,keepdims=True))
    groups[(group,mat)].append((v.astype('<f4'),normals.astype('<f4'),uv.astype('<f4'),f.reshape(-1).astype('<u4')))

def grid(fn,nu,nv,mat,flip=False,uvscale=(1,1)):
    v=[];uv=[];f=[]
    for j in range(nv+1):
        for i in range(nu+1):v.append(fn(i/nu,j/nv));uv.append((i/nu*uvscale[0],j/nv*uvscale[1]))
    for j in range(nv):
        for i in range(nu):
            a=j*(nu+1)+i;b=a+1;c=a+nu+1;d=c+1
            f.extend([(a,c,b),(b,c,d)] if flip else [(a,b,c),(b,d,c)])
    emit(v,f,mat,uv)

def block(p,size,mat,bevel=.025):
    # A chamfered solid for actual beam/table/stone shapes. Fine ornament uses curves below.
    x,y,z=np.array(size)*.5;b=min(bevel,x*.45,y*.45,z*.45)
    poly=[(-x+b,-z),(x-b,-z),(x,-z+b),(x,z-b),(x-b,z),(-x+b,z),(-x,z-b),(-x,-z+b)]
    with at(*p):extrude_xz(poly,-y,y,mat)

def extrude_xz(poly,y0,y1,mat):
    n=len(poly);v=[(x,y,z) for y in [y0,y1] for x,z in poly];f=[]
    for i in range(1,n-1):f.extend([(0,i,i+1),(n,n+i+1,n+i)])
    for i in range(n):j=(i+1)%n;f.extend([(i,n+i,j),(j,n+i,n+j)])
    # xz points are counterclockwise as seen from below: side orientation above is outward.
    emit(v,f,mat,smooth=False)

def lathe(profile,mat,segments=32):
    v=[];uv=[];f=[]
    for j,(r,y) in enumerate(profile):
        for i in range(segments+1):
            a=2*PI*i/segments;v.append((r*math.cos(a),y,r*math.sin(a)));uv.append((i/segments,j/(len(profile)-1)))
    for j in range(len(profile)-1):
        for i in range(segments):
            a=j*(segments+1)+i;b=a+segments+1
            f.extend([(a,b,a+1),(a+1,b,b+1)])
    emit(v,f,mat,uv)

def tube(points,r,mat,sides=8,closed=False):
    pts=np.asarray(points,float);v=[];uv=[];f=[]
    if len(pts)<2:return
    for i,p in enumerate(pts):
        tangent=pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)];tangent/=max(np.linalg.norm(tangent),1e-8)
        ref=np.array([0,1,0]) if abs(tangent[1])<.9 else np.array([1,0,0]);a=np.cross(tangent,ref);a/=max(np.linalg.norm(a),1e-8);b=np.cross(tangent,a)
        radius=r[i] if isinstance(r,(list,np.ndarray)) else r
        for k in range(sides):
            ang=k*2*PI/sides;v.append(p+radius*(math.cos(ang)*a+math.sin(ang)*b));uv.append((k/sides,i/(len(pts)-1)))
    for i in range(len(pts)-1):
        for k in range(sides):
            a=i*sides+k;b=i*sides+(k+1)%sides;c=a+sides;d=b+sides;f.extend([(a,b,c),(b,d,c)])
    # end discs, with outward order
    for k in range(1,sides-1):f.extend([(0,k+1,k),((len(pts)-1)*sides,(len(pts)-1)*sides+k,(len(pts)-1)*sides+k+1)])
    emit(v,f,mat,uv)

def ring(center,r,t,mat,axis='y',n=48):
    pts=[]
    for a in np.linspace(0,2*PI,n+1):
        q=(r*math.cos(a),0,r*math.sin(a)) if axis=='y' else (r*math.cos(a),r*math.sin(a),0)
        pts.append(np.asarray(center)+q)
    tube(pts,t,mat,8)

def ellipsoid(p,scale,mat,nu=16,nv=10):
    with at(*p):
        grid(lambda u,v:(scale[0]*math.sin(v*PI)*math.cos(u*2*PI),scale[1]*math.cos(v*PI),scale[2]*math.sin(v*PI)*math.sin(u*2*PI)),nu,nv,mat)

def bezier(p,steps=20):
    a,b,c,d=np.asarray(p,float);return [(1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d for t in np.linspace(0,1,steps)]

def collider(p,size,kind='box'):
    m=matrices[-1];q=m[:3,:3]@np.array(p)+m[:3,3]
    colliders.append({'kind':kind,'p':q.tolist(),'size':list(size),'yaw':math.atan2(m[0,2],m[0,0])})

def lotus(cx,cy,z,r,mat='gold',petals=8):
    for a in np.linspace(0,2*PI,petals,endpoint=False):
        pts=[]
        for t in np.linspace(0,2*PI,23):
            xx=r*(.51+.47*math.cos(t));yy=r*.19*math.sin(t)
            pts.append((cx+xx*math.cos(a)-yy*math.sin(a),cy+xx*math.sin(a)+yy*math.cos(a),z+.025*math.sin(t)**2))
        tube(pts,.012 if r<.4 else .018,mat,6)
    ring((cx,cy,z),r*.17,.018,mat,'z',24)

def cloud(x,y,z,scale=1,mat='gold'):
    for sign in [-1,1]:
        pts=[]
        for t in np.linspace(0,1,40):
            a=t*2*PI*1.35; rr=(.44-.33*t)*scale
            pts.append((x+sign*(.22*scale+rr*math.cos(a)),y+rr*.65*math.sin(a),z))
        tube(pts,.019*scale,mat,7)

def lattice(width,height,variant=0):
    # Truly open polygonal lattice. Crossing strips are not transparent decals.
    block((0,0,0),(width+.15,height+.15,.16),'wood',.045)
    # Replace solid frame above by a hollow frame: remove that one batch entry.
    groups[(group,'wood')].pop()
    for sx in [-1,1]:block((sx*width*.5,0,0),(.12,height+.12,.16),'wood',.035)
    for sy in [-1,1]:block((0,sy*height*.5,0),(width,.12,.16),'wood',.035)
    spacing=.39
    for j in range(int(height/spacing)):
        yy=-height*.5+.21+j*spacing
        for i in range(int(width/spacing)):
            xx=-width*.5+.21+i*spacing
            r=.17
            poly=[(xx+r*math.cos(a),yy+r*math.sin(a),.015) for a in np.linspace(PI/4,2*PI+PI/4,9)]
            tube(poly,.021,'wood_light',6)
            if (i+j+variant)%3==0:lotus(xx,yy,.035,.13,'gold',4)
            if i<int(width/spacing)-1:tube([(xx+.17,yy,.015),(xx+spacing-.17,yy,.015)],.021,'wood_light',6)
            if j<int(height/spacing)-1:tube([(xx,yy+.17,.015),(xx,yy+spacing-.17,.015)],.021,'wood_light',6)
            if i==0:tube([(-width*.5,yy,.015),(xx-.17,yy,.015)],.021,'wood_light',6)
            if i==int(width/spacing)-1:tube([(xx+.17,yy,.015),(width*.5,yy,.015)],.021,'wood_light',6)
            if j==0:tube([(xx,-height*.5,.015),(xx,yy-.17,.015)],.021,'wood_light',6)
            if j==int(height/spacing)-1:tube([(xx,yy+.17,.015),(xx,height*.5,.015)],.021,'wood_light',6)
    for sy in [-1,1]:tube([(-width*.5,sy*(height*.5-.09),.09),(width*.5,sy*(height*.5-.09),.09)],.011,'gold',6)

def dougong():
    # A carved curved gong profile, extruded through real depth, with nested arms.
    for level in range(3):
        spread=.58+level*.24;yy=level*.22
        for yaw in [0,PI/2]:
            with at(0,yy,level*.1,yaw):
                poly=[]
                # shape in x/y, stored as x/z then turned upright
                profile=[(-spread,.09),(-spread+.08,.01),(-spread+.18,-.035),(-spread*.55,-.09),(-.18,-.16),(.18,-.16),(spread*.55,-.09),(spread-.18,-.035),(spread-.08,.01),(spread,.09),(spread,.22),(spread-.13,.22),(spread-.26,.12),(.25,.065),(-.25,.065),(-spread+.26,.12),(-spread+.13,.22),(-spread,.22)]
                n=len(profile);v=[(x,y,z) for z in [-.105,.105] for x,y in profile];f=[]
                # fan works for this mildly concave upward bracket profile; underside is explicit.
                for i in range(n):j=(i+1)%n;f.extend([(i,j,n+i),(j,n+j,n+i)])
                # triangulate concave polygon through simple ear clipping
                def ears(points):
                    ids=list(range(len(points)));res=[];a=np.array(points,float)
                    signed=sum(a[i,0]*a[(i+1)%len(a),1]-a[(i+1)%len(a),0]*a[i,1] for i in range(len(a)))
                    if signed<0:ids.reverse()
                    while len(ids)>3:
                        found=False
                        for ii in range(len(ids)):
                            ia,ib,ic=ids[ii-1],ids[ii],ids[(ii+1)%len(ids)];aa,bb,cc=a[[ia,ib,ic]]
                            cross=lambda x,y:x[0]*y[1]-x[1]*y[0]
                            if cross(bb-aa,cc-bb)<=1e-9:continue
                            if any(cross(bb-aa,a[k]-aa)>=0 and cross(cc-bb,a[k]-bb)>=0 and cross(aa-cc,a[k]-cc)>=0 for k in ids if k not in (ia,ib,ic)):continue
                            res.append((ia,ib,ic));ids.pop(ii);found=True;break
                        if not found:break
                    if len(ids)==3:res.append(tuple(ids))
                    return res
                for aa,bb,cc in ears(profile):f.extend([(aa,cc,bb),(n+aa,n+bb,n+cc)])
                emit(v,f,'paint',smooth=False)
                tube([(x,y,.118) for x,y in profile[:11]],.017,'gold',6)
                for xx in [-spread*.66,spread*.66]:
                    with at(xx,.20,0):lathe([(.12,0),(.18,.04),(.18,.11),(.13,.14)],'red',16)
        with at(0,yy,0):lathe([(.16,0),(.21,.05),(.21,.15),(.14,.19)],'red',20)

def column(height):
    lathe([(.48,0),(.48,.10),(.44,.14),(.43,.25),(.35,.31),(.32,.39)],'stone',40)
    lathe([(.29,.36),(.29,.48),(.268,height*.4),(.235,height-.14),(.25,height)],'red',36)
    ring((0,.43,0),.292,.024,'bronze')
    ring((0,height-.18,0),.248,.025,'gold')
    collider((0,height*.5,0),(.57,height,.57),'cylinder')

def roof(width,depth,eave,rise):
    hx,hz=width*.5,depth*.5;ridge=max(.8,hx-hz*.72)
    def pos(u,v,side):
        z=side*hz*v; extent=ridge+(hx-ridge)*v
        x=(u*2-1)*extent
        y=eave+rise*max(0,1-v)**1.75+.50*v**7+.32*v**4*abs(u*2-1)**6
        return (x,y,z)
    for side in [-1,1]:
        grid(lambda u,v:pos(u,v,side),48,32,'tile_dark',flip=side>0,uvscale=(width/2,depth/2))
        # broad under-eave surface with thickness and dark timber underside
        grid(lambda u,v:np.array(pos(u,v,side))-[0,.16,0],32,16,'wood',flip=side<0,uvscale=(width/3,depth/3))
        rows=int(width/.255)
        for i in range(rows+1):
            u=i/rows
            points=[np.array(pos(u,v,side))+[0,.055,0] for v in np.linspace(.02,1,30)]
            # half round glazed cover tiles, continuous curvature, visible transverse joints
            def cover(t,a):
                q=np.array(pos(u,.02+t*.98,side));angle=PI*a
                return q+np.array([.102*math.cos(angle),.055+.102*math.sin(angle),0])
            grid(cover,28,7,'tile' if i%5 else 'tile_light',flip=side>0,uvscale=(1,6))
            for vv in np.linspace(.12,.98,10):
                q=np.array(pos(u,vv,side));pts=[q+[.105*math.cos(a),.06+.105*math.sin(a),0] for a in np.linspace(0,PI,9)]
                tube(pts,.012,'tile_light',5)
            q=np.array(pos(u,1,side))
            # round tile-end ornament with raised centre, entirely modelled
            with at(q[0],q[1]+.075,q[2]+side*.018,0 if side>0 else PI):
                ring((0,0,0),.092,.017,'tile_light','z',16)
                ellipsoid((0,0,.012),(.037,.037,.024),'tile_light',8,6)
        # carved eave fascia and curved rafters visible from below
        tube([np.array(pos(u,1,side))-[0,.13,0] for u in np.linspace(0,1,70)],.095,'red',10)
        tube([np.array(pos(u,1,side))+[0,.03,side*.02] for u in np.linspace(0,1,70)],.035,'bronze',8)
        for i in range(int(width/.43)+1):
            u=i/int(width/.43)
            tube([np.array(pos(u,v,side))-[0,.25,0] for v in np.linspace(.65,1.01,12)],.065,'red',10)
    # hipped end roof fans with actual curved surface, decorative ridge sweeps
    for sx in [-1,1]:
        def end(u,v):
            z=(u*2-1)*hz*v;x=sx*(ridge+(hx-ridge)*v)
            return (x,eave+rise*(1-v)**1.75+.50*v**7+.32*v**4*abs(u*2-1)**6,z)
        grid(end,28,24,'tile',flip=sx<0,uvscale=(depth/2,3))
        grid(lambda u,v:np.array(end(u,v))-[0,.16,0],20,12,'wood',flip=sx>0)
        for u in np.linspace(0,1,int(depth/.32)):
            tube([np.array(end(u,v))+[0,.055,0] for v in np.linspace(.06,1,28)],.045,'tile_light',6)
        for side in [-1,1]:
            path=[np.array(pos(1 if sx>0 else 0,v,side))+[0,.12,0] for v in np.linspace(0,1,40)]
            tube(path,.105,'bronze',10)
            tip=np.array(pos(1 if sx>0 else 0,1,side))
            tube(bezier([tip+[0,.1,0],tip+[sx*.3,.15,side*.2],tip+[sx*.6,.7,side*.3],tip+[sx*.47,.95,side*.3]]),[.12*(1-t)+.015 for t in np.linspace(0,1,20)],'bronze',10)
            for v in [.68,.78,.88]:
                q=np.array(pos(1 if sx>0 else 0,v,side))+[0,.27,0]
                ellipsoid(q,(.13,.17,.12),'bronze',12,8)
                tube([q,q+[sx*.14,.21,side*.08],q+[sx*.19,.26,side*.13]],.05,'bronze',7)
    tube([(-ridge,eave+rise+.12,0),(ridge,eave+rise+.12,0)],.13,'bronze',12)
    for sx in [-1,1]:
        with at(sx*ridge,eave+rise,0):
            tube(bezier([(0,.1,0),(sx*.6,.3,0),(sx*.6,1.15,0),(sx*.25,1.3,0)]),np.linspace(.19,.035,20),'bronze',12)
            ellipsoid((sx*.18,.88,0),(.17,.26,.16),'bronze',16,10)

def frame_panel(width,height,mat='paint'):
    block((0,0,0),(width,height,.13),mat,.025)
    if mat=='paint':
        for sign in [-1,1]:
            vertices=[(-width*.5,-height*.5,sign*.067),(width*.5,-height*.5,sign*.067),(width*.5,height*.5,sign*.067),(-width*.5,height*.5,sign*.067)]
            faces=[(0,1,2),(0,2,3)] if sign>0 else [(0,2,1),(0,3,2)]
            emit(vertices,faces,mat,[(0,1),(1,1),(1,0),(0,0)],False)
    for sy in [-1,1]:tube([(-width*.5,sy*(height*.5-.035),.08),(width*.5,sy*(height*.5-.035),.08)],.017,'gold',6)
    for xx in np.linspace(-width*.35,width*.35,max(1,int(width/1.5))):lotus(xx,0,.1,min(.22,height*.32),'gold',8)

def wall_with_windows(width,height,door=False):
    # local wall in XY plane; central door remains open and walkable.
    if door:
        for sx in [-1,1]:
            with at(sx*(width*.25+.6),height*.5,0):
                block((0,0,0),(width*.5-1.2,height,.22),'plaster')
        block((0,height-.25,0),(2.4,.5,.22),'paint')
        for sx in [-1,1]:collider((sx*(width*.25+.6),height*.5,0),(width*.5-1.2,height,.28))
    else:
        block((0,.5,0),(width,1,.25),'red')
        with at(0,2.05,0):lattice(width-.22,2.0)
        block((0,height-.32,0),(width,.64,.25),'paint')
        collider((0,height*.5,0),(width,height,.24))

def hall():
    global group
    group='hall_stone'
    with at(0,0,-18):
        block((0,.40,0),(34,.8,20),'stone',.12);block((0,.84,0),(34.3,.12,20.3),'stone',.04)
        collider((0,.4,0),(34,.8,20));collider((0,.84,0),(34.3,.12,20.3))
        for z in [9.75,-9.75]:
            for x in np.arange(-16,17,2):
                if z>0 and abs(x)<5:continue
                with at(x,.9,z):baluster()
        for side in [-1,1]:
            for z in np.arange(-8,9,2):
                with at(side*16.7,.9,z,PI/2):baluster()
    # visible stone steps, with matching walkable ramp collision proxy
    for i in range(7):
        h=.9*(i+1)/7;z=-3.5-(i+.5)*4.5/7
        block((0,h*.5,z),(8,h,4.5/7+.015),'stone',.025)
    colliders.append({'kind':'ramp','p':[0,0,-3.5],'size':[8,.9,4.5],'yaw':0})
    group='hall_shell'
    with at(0,.9,-18):
        block((0,-.015,0),(28,.08,14),'floor',.01)
        # Seven bays, deep portico and clear central entry.
        for z in [-7,7]:
            for x in np.arange(-14,15,4):
                with at(x,0,z):column(5.65)
                with at(x,5.50,z,0 if z>0 else PI):dougong()
        for x in [-14,14]:
            for z in [-3.5,0,3.5]:
                with at(x,0,z):column(5.65)
                with at(x,5.5,z,PI/2 if x>0 else -PI/2):dougong()
        for z in [-7,7]:
            for x in np.arange(-12,13,4):
                with at(x,4.95,z):frame_panel(3.55,.65)
        for x in [-14,14]:
            for z in [-5.25,-1.75,1.75,5.25]:
                with at(x,4.95,z,PI/2):frame_panel(3.05,.65)
        # Front door and four window bays, no solid wall behind lattice.
        for x in [-12,-8,-4,4,8,12]:
            with at(x,0,5.35):wall_with_windows(3.8,4.6)
        for sx in [-1,1]:
            block((sx*1.94,2.3,5.35),(.18,4.6,.35),'wood')
            ring((sx*1.96,1.7,5.58),.12,.026,'bronze','z',24)
        block((0,4.42,5.35),(4,.35,.35),'paint')
        collider((0,4.42,5.35),(4,.35,.35))
        block((0,2.75,-7),(28,5.5,.32),'plaster')
        collider((0,2.75,-7),(28,5.5,.32))
        for x in [-14,14]:
            for z in [-5.25,-1.75,1.75,5.25]:
                with at(x,0,z,PI/2):wall_with_windows(3.45,4.6)
        block((0,5.58,0),(28,.22,14),'wood')
        for x in np.arange(-12,13,4):block((x,5.25,0),(.27,.40,14),'paint')
        for z in [-5,-1,3]:block((0,5.30,z),(28,.35,.25),'paint')
        block((0,4.15,7.32),(4.4,.8,.12),'wood')
        for yy in [3.79,4.51]:tube([(-2.15,yy,7.39),(2.15,yy,7.39)],.018,'gold',8)
    group='hall_roof'
    with at(0,.9,-18):
        roof(33,19,6.12,3.15)
        block((0,9.15,0),(23,.9,10),'red')
        for z in [-5.015,5.015]:
            for x in [-9,-6,-3,0,3,6,9]:
                with at(x,9.13,z):frame_panel(2.8,.60)
        roof(25.7,12,9.72,2.6)
    group='hall_interior'
    with at(0,.9,-18):
        caisson()
        for sx in [-1,1]:
            with at(sx*6.3,0,-1.3,PI/2):moon_partition()
        # Carved central freestanding screen: access around either side remains open.
        with at(0,0,1):screen(5.5,3.65)
        for x in [-8.8,8.8]:
            with at(x,0,-3):table(3.4,1.1,1.9)
            with at(x-1.1,1.1,-3):vase(.48)
            with at(x+1.0,1.1,-3):vase(.34,'jade')
            for z in [-1,-5]:
                with at(x,0,z,0 if z==-1 else PI):chair()
        with at(0,0,-4.5):table(4.2,1.05,1.4)
        for x in [-2.8,2.8]:
            with at(x,0,-4.5):chair()
        for x in [-10,-5,5,10]:
            with at(x,2.55,-6.65):carved_panel(2.7,3.1)
        with at(0,3.0,-6.65):
            block((0,0,0),(5.6,3.3,.14),'wood')
            emit([(-2.65,-1.5,.08),(2.65,-1.5,.08),(2.65,1.5,.08),(-2.65,1.5,.08)],[(0,1,2),(0,2,3)],'painting',[(0,1),(1,1),(1,0),(0,0)])
            for yy in [-1.59,1.59]:tube([(-2.73,yy,.09),(2.73,yy,.09)],.025,'gold',8)
        for x in [-10,-6,6,10]:
            for z in [-3,1]:
                ceiling_coffer(x,5.43,z,3.4,3.3)
        for x in [-10,-5,0,5,10]:lantern((x,4.3,2.7),.42)
    labels.append({'text':'海 上 御 苑','p':[0,5.0,-10.57],'size':.009,'color':'ead9aa'})

def baluster():
    lathe([(.17,0),(.17,.15),(.10,.22),(.10,.80),(.17,.87),(.17,.98),(.10,1.03)],'stone',24)
    ellipsoid((0,1.08,0),(.16,.17,.16),'stone',16,10)
    for yy in [.22,.90]:block((.9,yy,0),(1.8,.11,.14),'stone')
    for x in [.35,.72,1.08,1.45]:
        tube([(x,.28,0),(x,.81,0)],.035,'stone',8)
    collider((.9,.5,0),(1.85,1,.20))

def moon_partition():
    # Open circular passage cut through an actual solid panel, with a carved rim.
    centre=np.array([0,1.78]);radius=1.78;vertices=[]
    for zz in [-.09,.09]:
        for outer in [False,True]:
            for a in np.linspace(0,2*PI,97):
                direction=np.array([math.cos(a),math.sin(a)])
                if outer:
                    candidates=[]
                    if abs(direction[0])>1e-8:candidates.append(2.5/abs(direction[0]))
                    if direction[1]>1e-8:candidates.append((4.5-centre[1])/direction[1])
                    elif direction[1]<-1e-8:candidates.append(-centre[1]/direction[1])
                    rr=min(candidates)
                else:rr=radius
                q=centre+rr*direction;vertices.append((q[0],q[1],zz))
    faces=[];n=97
    for i in range(96):
        for side in [0,1]:
            a=side*2*n+i;b=a+n
            faces.extend([(a,b,a+1),(a+1,b,b+1)] if side else [(a,a+1,b),(a+1,b+1,b)])
        faces.extend([(i,i+2*n,i+1),(i+1,i+2*n,i+2*n+1)])
    emit(vertices,faces,'wood',smooth=False)
    for z in [-.12,.12]:
        for r,mat in [(1.81,'gold'),(1.89,'wood_light'),(1.97,'gold')]:ring((0,1.78,z),r,.025 if mat=='gold' else .045,mat,'z',80)
        for sx in [-1,1]:
            cloud(sx*1.65,3.88,z,.75,'gold')
            lotus(sx*2.13,.70,z,.22,'gold',8)
        cloud(0,4.12,z,1.1,'gold')
    for sx in [-1,1]:collider((sx*2.15,2.25,0),(.7,4.5,.23))
    collider((0,4.08,0),(3.6,.84,.23))

def caisson():
    for level in range(5):
        r=3.3-level*.47;y=4.65+level*.145
        for a in np.linspace(0,2*PI,8,endpoint=False):
            aa=np.array([r*math.cos(a),y,r*math.sin(a)]);bb=np.array([r*math.cos(a+PI/4),y,r*math.sin(a+PI/4)])
            tube([aa,bb],.09,'paint',10);tube([aa-[0,.09,0],bb-[0,.09,0]],.026,'gold',8)
            for t in [.25,.5,.75]:
                q=aa*(1-t)+bb*t
                ellipsoid(q-[0,.06,0],(.09,.07,.09),'gold',12,8)
            inner=r-.47
            p0=(r*math.cos(a),y,r*math.sin(a));p1=(r*math.cos(a+PI/4),y,r*math.sin(a+PI/4));p2=(inner*math.cos(a+PI/4),y+.145,inner*math.sin(a+PI/4));p3=(inner*math.cos(a),y+.145,inner*math.sin(a))
            emit([p0,p1,p2,p3],[(0,1,2),(0,2,3)],'paint',[(0,0),(1,0),(1,1),(0,1)])
    # lotus pendant with curved petals, visible from below
    for layer in range(3):
        for a in np.linspace(0,2*PI,12,endpoint=False):
            pts=[]
            for t in np.linspace(0,2*PI,33):
                rr=.5+.40*math.cos(t);ww=.16*math.sin(t)
                pts.append(((rr*math.cos(a)-ww*math.sin(a))*(1+layer*.22),5.31-layer*.12-.08*math.sin(t)**2,(rr*math.sin(a)+ww*math.cos(a))*(1+layer*.22)))
            tube(pts,.032,'gold',8)
    ellipsoid((0,5.13,0),(.25,.13,.25),'jade',24,12)
    for layer in range(2):
        for a in np.linspace(0,2*PI,12,endpoint=False):
            with at(.48*math.cos(a),5.23-layer*.10,.48*math.sin(a),-a):
                ellipsoid((0,0,0),(.59-layer*.12,.095,.16),'gold',20,12)

def ceiling_coffer(x,y,z,width,depth):
    with at(x,y,z):
        block((0,0,0),(width,.07,depth),'paint')
        emit([(-width*.5,-.037,-depth*.5),(width*.5,-.037,-depth*.5),(width*.5,-.037,depth*.5),(-width*.5,-.037,depth*.5)],[(0,1,2),(0,2,3)],'paint',[(.333,0),(.667,0),(.667,1),(.333,1)])
        for sign in [-1,1]:
            tube([(sign*width*.5,-.05,-depth*.5),(sign*width*.5,-.05,depth*.5)],.032,'gold',8)
            tube([(-width*.5,-.05,sign*depth*.5),(width*.5,-.05,sign*depth*.5)],.032,'gold',8)
        ring((0,-.07,0),.67,.022,'gold','y',40)
        for a in np.linspace(0,2*PI,8,endpoint=False):
            with at(.33*math.cos(a),-.08,.33*math.sin(a),-a):ellipsoid((0,0,0),(.29,.035,.09),'gold',14,8)

def carved_panel(width,height):
    frame_panel(width,height,'wood')
    for sign in [-1,1]:
        tube([(sign*(width*.5-.09),-height*.5+.09,.08),(sign*(width*.5-.09),height*.5-.09,.08)],.02,'gold',8)
        tube([(-width*.5+.09,sign*(height*.5-.09),.08),(width*.5-.09,sign*(height*.5-.09),.08)],.02,'gold',8)
    for sign in [-1,1]:
        stem=[(sign*.30*math.sin(t*PI*2),-height*.4+t*height*.78,.13) for t in np.linspace(0,1,50)]
        tube(stem,.026,'wood_light',8)
        for j in range(5):
            yy=-height*.31+j*height*.145;xx=sign*(.52+.12*math.sin(j))
            tube(bezier([(0,yy-.15,.13),(sign*.2,yy,.15),(xx,yy+.05,.15),(xx,yy+.21,.15)]),.018,'gold',7)
            lotus(xx,yy+.26,.16,.21,'gold',8)
            for a in [-.6,.6]:
                pts=[(xx+sign*(.12+.13*math.cos(t)),yy+a*.28+.055*math.sin(t),.16+.02*math.sin(t)**2) for t in np.linspace(0,2*PI,25)]
                tube(pts,.016,'wood_light',7)

def table(width=2.8,height=.85,depth=1.2):
    block((0,height-.07,0),(width,.14,depth),'wood',.065)
    block((0,height+.005,0),(width-.12,.025,depth-.12),'wood_light',.04)
    for sx in [-1,1]:
        for sz in [-1,1]:
            x=sx*(width*.5-.17);z=sz*(depth*.5-.15)
            tube(bezier([(x,height-.12,z),(x*.93,height*.7,z*.9),(x*1.02,.2,z*1.02),(x*1.03,.05,z*1.04)]),np.linspace(.075,.055,20),'wood',10)
    for sz in [-1,1]:
        cloud(0,height-.28,sz*(depth*.5-.07),min(1.3,width*.35),'wood_light')
        tube([(-width*.5+.15,height-.25,sz*(depth*.5-.1)),(width*.5-.15,height-.25,sz*(depth*.5-.1))],.04,'wood',8)
    collider((0,height*.5,0),(width,height,depth))

def chair():
    table(.72,.48,.68)
    for sx in [-1,1]:tube([(sx*.30,.45,-.28),(sx*.32,.85,-.32),(sx*.38,1.16,-.32)],.045,'wood',10)
    tube(bezier([(-.42,1.12,-.32),(-.2,1.28,-.33),(.2,1.28,-.33),(.42,1.12,-.32)]),.053,'wood',10)
    with at(0,.87,-.31):lattice(.39,.43)
    block((0,.51,.02),(.59,.08,.53),'fabric',.1)

def vase(h=1,mat='porcelain'):
    lathe([(r*h,y*h) for r,y in [(.12,0),(.16,.03),(.16,.1),(.29,.22),(.32,.42),(.25,.65),(.11,.79),(.10,.94),(.14,.97),(.14,1),(.10,1),(.08,.94)]],mat,36)
    for yy,rr in [(.12,.175),(.67,.23),(.95,.12)]:ring((0,yy*h,0),rr*h,.013*h,'gold',n=32)

def screen(width,height):
    for sx in [-1,1]:
        block((sx*(width*.5+.12),height*.5,0),(.18,height,.23),'wood',.035)
        block((sx*(width*.5+.12),.12,0),(.5,.24,.75),'wood',.08)
        with at(sx*(width*.5+.12),height,0):vase(.23,'bronze')
    panels=5;pw=width/panels
    for i in range(panels):
        x=(i-(panels-1)*.5)*pw
        with at(x,.7,0):frame_panel(pw-.06,1.05,'wood_light')
        with at(x,height*.5+.48,0):lattice(pw-.06,height-1.28,i)
    cloud(0,height+.12,0,min(1.8,width*.34),'wood_light')
    collider((0,height*.5,0),(width+.35,height,.28))

def lantern(p,scale=.36):
    x,y,z=p
    with at(x,y,z):
        lathe([(scale*.55,-scale),(scale*.72,-scale*.82),(scale*.8,scale*.63),(scale*.55,scale*.9)],'lamp',8)
        for yy in [-scale,scale*.9]:
            lathe([(scale*.55,yy-.04),(scale*.87,yy),(scale*.88,yy+.05),(scale*.59,yy+.10)],'wood',8)
        for a in np.linspace(0,2*PI,8,endpoint=False):
            xx=math.cos(a)*scale*.77;zz=math.sin(a)*scale*.77
            tube([(xx,-scale*.83,zz),(xx,scale*.66,zz)],.024,'gold',6)
        tube([(0,scale,0),(0,scale+.45,0)],.018,'bronze',8)
        for dx in [-.10,0,.1]:tube([(dx,-scale-.1,0),(dx,-scale-.4,0)],.012,'red',5)
    m=matrices[-1];q=m[:3,:3]@np.array(p)+m[:3,3];lamps.append({'p':q.tolist(),'range':7.5,'energy':1.5})

def study():
    global group
    group='study_shell'
    with at(-23,.45,-6):
        block((0,-.25,0),(13,.5,11),'stone',.08);collider((0,-.25,0),(13,.5,11))
        block((0,.01,0),(12,.06,10),'planks');collider((0,.01,0),(12,.06,10))
        for x in [-6,-2,2,6]:
            for z in [-5,5]:
                with at(x,0,z):column(3.9)
                with at(x,3.75,z,0 if z>0 else PI):dougong()
        for x in [-4,4]:
            with at(x,0,4.5):wall_with_windows(3.9,3.6)
        for x in [-6,6]:
            for z in [-3.3,0,3.3]:
                with at(x,0,z,PI/2):wall_with_windows(3.3,3.6)
        block((0,1.9,-5),(12,3.8,.25),'plaster');collider((0,1.9,-5),(12,3.8,.25))
        block((0,3.95,0),(12,.16,10),'wood')
        for x in [-4,0,4]:block((x,3.7,0),(.22,.35,10),'paint')
        for x in [-4,0,4]:
            for z in [-2.5,2.5]:ceiling_coffer(x,3.78,z,3.4,4.3)
        with at(0,3.6,4.5):frame_panel(3.8,.6)
        roof(15,13,4.25,2.5)
    for i in range(3):block((-23,(i+1)*.15*.5,.4-i*.45),(4,(i+1)*.15,.47),'stone')
    colliders.append({'kind':'ramp','p':[-23,0,.65],'size':[4,.49,1.6],'yaw':0})
    group='study_interior'
    with at(-23,.49,-6):
        with at(-1.9,0,-1.5):
            table(3.6,.86,1.6)
            with at(.9,.86,0):vase(.35,'jade')
            block((-.8,.90,.1),(.75,.07,.5),'paper')
            for i in range(6):tube([(-1.1+i*.1,.944,-.10),(-1.1+i*.1,.944,.25)],.003,'ink',5)
            tube([(.2,.91,-.23),(.55,.93,.24)],.014,'wood',8)
            with at(0,0,1.3,PI):chair()
        # shelves are open, with individually bound books and varied display niches
        for cx in [-3.8,0,3.8]:
            for xx in [-1.55,1.55]:block((cx+xx,1.5,-4.65),(.12,3,.6),'wood')
            for yy in [.12,.85,1.6,2.35,3.0]:block((cx,yy,-4.65),(3.2,.1,.65),'wood')
            for sx in [-1,1]:
                with at(cx+sx*.77,.48,-4.29):
                    frame_panel(1.43,.55,'wood_light')
                    ring((sx*.47,0,.09),.052,.012,'bronze','z',20)
            with at(cx,3.20,-4.65):
                cloud(0,0,.34,1.7,'wood_light')
                lotus(0,.07,.35,.22,'gold',8)
            for yy,xx in [(1.21,-.3),(1.97,.45),(2.68,-.6)]:block((cx+xx,yy,-4.65),(.065,.65,.6),'wood')
            for shelf in range(3):
                for b in range(7):
                    h=.32+.19*((b+shelf)%3)/2;x=cx-1.3+b*.23
                    block((x,.18+shelf*.75+h*.5,-4.6),(.14,h,.36),'book'+str((b+shelf)%3),.009)
                    for yy in [.18+shelf*.75+.06,.18+shelf*.75+h-.06]:block((x,yy,-4.405),(.13,.015,.012),'gold',.001)
                with at(cx+1,.2+shelf*.75,-4.6):vase(.42,'porcelain' if shelf%2 else 'jade')
            collider((cx,1.5,-4.65),(3.2,3,.7))
        # landscape artwork panel on a real carved frame, not fake room depth
        with at(3.45,1.80,.35,PI/2):
            block((0,0,0),(3.2,2.3,.16),'wood')
            emit([(-1.45,-1,.10),(1.45,-1,.10),(1.45,1,.10),(-1.45,1,.10)],[(0,1,2),(0,2,3)],'painting',[(0,1),(1,1),(1,0),(0,0)])
            for yy in [-1.07,1.07]:tube([(-1.5,yy,.12),(1.5,yy,.12)],.035,'gold',8)
            cloud(0,1.28,0,1.4,'wood_light')
        with at(3.8,0,2.5):table(2.5,.48,1.3)
        with at(3.8,.48,2.5):tea_set()
        for x in [2.4,5.1]:
            block((x,.15,2.5),(.9,.3,.9),'fabric',.12);collider((x,.15,2.5),(.9,.3,.9))
        for x,z in [(-3,1.7),(2,-1)]:lantern((x,3.05,z),.37)
    labels.append({'text':'听 雨 书 房','p':[-23,4.05,-1.29],'size':.007,'color':'ead9aa'})

def tea_set():
    with at(0,0,0):
        lathe([(.16,0),(.22,.06),(.23,.19),(.14,.26),(.10,.29)],'porcelain',24)
        ring((.25,.17,0),.12,.025,'porcelain','z',24)
        tube(bezier([(-.17,.14,0),(-.35,.15,0),(-.25,.29,0),(-.37,.29,0)]),np.linspace(.05,.025,20),'porcelain',8)
    for x,z in [(-.48,.25),(.48,.25)]:
        with at(x,0,z):lathe([(.08,0),(.09,.03),(.11,.15),(.095,.15),(.08,.04)],'porcelain',24)

def galleries():
    global group
    for side in [-1,1]:
        group='gallery_west' if side<0 else 'gallery_east'
        with at(side*22,0,13):
            block((0,.12,0),(4.8,.24,22),'stone');collider((0,.12,0),(4.8,.24,22))
            for z in np.arange(-10,11,4):
                for x in [-1.85,1.85]:
                    with at(x,.24,z):column(3.4)
                    with at(x,3.5,z,PI/2 if x>0 else -PI/2):dougong()
            for x in [-1.85,1.85]:
                for z in np.arange(-8,9,4):
                    with at(x,3.28,z,PI/2):frame_panel(3.6,.5)
            with at(0,0,0,PI/2):roof(25,6.5,4.0,1.5)
            for z in [-6,2,10]:lantern((0,3.05,z),.32)
        # low accessible broad steps at each gallery end
        for z in [1.5,24.5]:
            block((side*22,.06,z),(4.8,.12,1),'stone');collider((side*22,.06,z),(4.8,.12,1))
    # East pavilion echoes the main hall without a second monumental roof.
    group='tea_pavilion'
    with at(23,.15,-6):
        block((0,-.075,0),(12,.15,10),'stone');collider((0,-.075,0),(12,.15,10))
        for x in [-5.6,0,5.6]:
            for z in [-4.5,4.5]:
                with at(x,0,z):column(3.9)
                with at(x,3.75,z):dougong()
        for x in [-5.6,5.6]:
            with at(x,1.8,0,PI/2):lattice(5.5,2.8)
            collider((x,1.8,0),(.18,3.6,5.5))
        roof(15,13,4.25,2.4)
        for x in [-3.5,3.5]:
            with at(x,0,0):table(2.4,.8,1.3)
            with at(x,.8,0):tea_set()
            for z in [-1.4,1.4]:
                with at(x,0,z,0 if z<0 else PI):chair()
        lantern((0,3.2,0),.4)

def tree(p,size=1,flower=False):
    with at(*p):
        trunk=bezier([(0,0,0),(.2,2*size,0),(-.4*size,3.8*size,.3),(0,5*size,0)])
        tube(trunk,np.linspace(.24*size,.06*size,20),'bark',10)
        for i in range(9):
            a=i*2.399;r=(1.5+i%3*.45)*size;y=(2.8+i*.24)*size
            tip=np.array([math.cos(a)*r,y,math.sin(a)*r])
            tube(bezier([(0,y*.6,0),(0,y*.9,0),tip*.8,tip]),np.linspace(.10*size,.016*size,20),'bark',8)
            for j in range(12):
                offset=rng.normal(0,[.42,.22,.42])*size;center=tip+offset
                # Clusters use overlapping curved leaf blades, never cube crowns.
                for k in range(14):
                    ang=k*2.399+j;sc=.24*size
                    pp=center+rng.normal(0,.21*size,3);tilt=float(rng.uniform(-.5,.6))
                    grid(lambda u,v,p=pp,a=ang,s=sc,t=tilt:(p[0]+s*(u-.5)*2*math.cos(a)-s*.72*(v-.5)*math.sin(u*PI)*math.sin(a),p[1]+s*(.32*math.sin(u*PI)*math.sin(v*PI)+t*(u-.5)),p[2]+s*(u-.5)*2*math.sin(a)+s*.72*(v-.5)*math.sin(u*PI)*math.cos(a)),5,2,'leaf'+str((i+j+k)%3))
                if flower and j%3==0:
                    for a in np.linspace(0,2*PI,5,endpoint=False):ellipsoid(center+[.05*math.cos(a),.06,.05*math.sin(a)],(.045,.027,.045),'flower',8,5)
        collider((0,2*size,0),(.5*size,4*size,.5*size),'cylinder')

def gate_and_garden():
    global group
    group='garden_ground'
    block((0,-.18,0),(85,.36,83),'ground');collider((0,-.2,0),(85,.4,83))
    block((0,.012,12),(8,.024,38),'paving',.01)
    for side in [-1,1]:
        block((side*15,.015,-.1),(22,.03,3),'paving')
        block((side*12,.018,24),(20,.035,3),'paving')
        # raised pond stone edges, water below coping, with lotus leaves
        with at(side*11.7,0,12):
            for x in [-4.2,4.2]:block((x,.18,0),(.28,.36,12),'stone');collider((x,.18,0),(.28,.36,12))
            for z in [-6,6]:block((0,.18,z),(8.7,.36,.28),'stone');collider((0,.18,z),(8.7,.36,.28))
            block((0,.035,0),(8.2,.05,11.8),'water')
            collider((0,.15,0),(8.2,.30,11.8))
            for i in range(14):
                x=float(rng.uniform(-3.6,3.6));z=float(rng.uniform(-5.4,5.4))
                with at(x,.1,z):
                    grid(lambda u,v:(.4*v*math.cos(u*PI*1.9),.06*v*v,.4*v*math.sin(u*PI*1.9)),22,4,'jade')
                    if i%4==0:
                        for layer in range(2):
                            for a in np.linspace(0,2*PI,9,endpoint=False):
                                ang=a+layer*.27
                                grid(lambda u,v,a=ang,l=layer:((.03+u*.30*(1-l*.2))*math.cos(a)-.16*(v-.5)*math.sin(u*PI)*math.sin(a),.07+.20*u**1.5+.035*math.sin(v*PI),(.03+u*.30*(1-l*.2))*math.sin(a)+.16*(v-.5)*math.sin(u*PI)*math.cos(a)),9,5,'flower',flip=False)
                        ellipsoid((0,.15,0),(.07,.08,.07),'gold',12,8)
        for z in [3,22]:
            tree((side*11.7,0,z),1.05,True)
        for z in [-18,-28]:tree((side*31,0,z),1.45)
    group='garden_details'
    for x,z in [(-6,3),(6,3),(-6,22),(6,22),(-29,18),(29,18)]:
        with at(x,0,z):
            lathe([(.35,0),(.35,.15),(.20,.25),(.17,.85),(.30,.96)],'stone',24)
            lantern((0,1.38,0),.26)
            collider((0,.8,0),(.6,1.6,.6),'cylinder')
    for side in [-1,1]:
        for z in [3,20]:
            with at(side*29,0,z):
                for i in range(5):
                    ellipsoid((rng.uniform(-1,1),.3+rng.random()*.4,rng.uniform(-1,1)),(.6,.6,.4),'rock',12,8)
                for i in range(22):
                    x,z0=rng.uniform(-1.5,1.5,2);h=rng.uniform(.3,.8)
                    tube(bezier([(x,0,z0),(x,h*.4,z0),(x+.15,h*.8,z0),(x+.2,h,z0)]),.012,'leaf1',5)
                    ellipsoid((x+.2,h,z0),(.08,.07,.08),'flower',8,6)
    group='garden_walls'
    # Perimeter is a real enclosed courtyard, with a broad opening at the south gate.
    for x in [-34,34]:
        block((x,1.65,-1),( .4,3.3,66),'plaster');collider((x,1.65,-1),(.45,3.3,66))
        tube([(x,3.35,-34),(x,3.35,32)],.15,'tile',12)
    block((0,1.65,-34),(68,3.3,.4),'plaster');collider((0,1.65,-34),(68,3.3,.45))
    for x in [-20,20]:
        block((x,1.65,29),(28,3.3,.4),'plaster');collider((x,1.65,29),(28,3.3,.45))
    group='gate'
    with at(0,0,27):
        for x in [-5.5,-2.1,2.1,5.5]:
            for z in [-1.9,1.9]:
                with at(x,0,z):column(3.65)
                with at(x,3.5,z):dougong()
        for sx in [-1,1]:
            with at(sx*3.85,1.65,0):lattice(3.1,3.0)
            collider((sx*3.85,1.65,0),(3.15,3.3,.25))
        roof(15.0,7.5,4.05,2.1)
        with at(0,3.22,1.95):frame_panel(3.9,.65)
        for x in [-3.8,3.8]:lantern((x,2.8,2.4),.35)
    labels.append({'text':'晴 海 花 境','p':[0,3.27,29.04],'size':.007,'color':'ead9aa'})

def export_glb():
    MODEL.mkdir(parents=True,exist_ok=True)
    doc={'asset':{'version':'2.0','generator':'XiaojuWorld craft160 original mesh authoring'},'scene':0,'scenes':[{'nodes':[]}],'nodes':[],'meshes':[],'materials':[],'accessors':[],'bufferViews':[],'buffers':[],'images':[],'textures':[],'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':10497,'wrapT':10497}]}
    binary=bytearray();texids={}
    def blob(data,target=None):
        while len(binary)%4:binary.append(0)
        start=len(binary);binary.extend(data);rec={'buffer':0,'byteOffset':start,'byteLength':len(data)}
        if target:rec['target']=target
        doc['bufferViews'].append(rec);return len(doc['bufferViews'])-1
    def accessor(array,typ,component=5126,bounds=False):
        array=np.ascontiguousarray(array);bv=blob(array.tobytes(),34963 if component==5125 else 34962)
        rec={'bufferView':bv,'componentType':component,'count':len(array),'type':typ}
        if bounds:rec.update(min=array.min(axis=0).tolist(),max=array.max(axis=0).tolist())
        doc['accessors'].append(rec);return len(doc['accessors'])-1
    for source in materials:
        m=json.loads(json.dumps(source))
        for key in ['_texture','_normal']:
            if key not in m:continue
            name=m.pop(key)
            if name not in texids:
                data=(TEX/name).read_bytes();doc['images'].append({'bufferView':blob(data),'mimeType':'image/png','name':name});doc['textures'].append({'source':len(doc['images'])-1,'sampler':0});texids[name]=len(doc['textures'])-1
            if key=='_texture':m['pbrMetallicRoughness']['baseColorTexture']={'index':texids[name]}
            else:m['normalTexture']={'index':texids[name],'scale':.35}
        # leaves are explicitly double sided; all architectural shell faces remain solid.
        if m['name'].startswith('leaf') or m['name']=='painting':m['doubleSided']=True
        doc['materials'].append(m)
    summary=[]
    for name in sorted({k[0] for k in groups}):
        primitives=[];triangles=0
        for (g,mat),chunks in groups.items():
            if g!=name or not chunks:continue
            v=[];n=[];uv=[];idx=[];offset=0
            for vv,nn,tt,ii in chunks:v.append(vv);n.append(nn);uv.append(tt);idx.append(ii+offset);offset+=len(vv)
            vertices=np.concatenate(v);norm=np.concatenate(n);tex=np.concatenate(uv);indices=np.concatenate(idx)
            triangles+=len(indices)//3
            primitives.append({'attributes':{'POSITION':accessor(vertices,'VEC3',bounds=True),'NORMAL':accessor(norm,'VEC3'),'TEXCOORD_0':accessor(tex,'VEC2')},'indices':accessor(indices,'SCALAR',5125),'material':material_ids[mat]})
        doc['meshes'].append({'name':name,'primitives':primitives});doc['nodes'].append({'name':name,'mesh':len(doc['meshes'])-1});doc['scenes'][0]['nodes'].append(len(doc['nodes'])-1)
        summary.append({'name':name,'triangles':triangles,'materials':len(primitives)})
    while len(binary)%4:binary.append(0)
    doc['buffers']=[{'byteLength':len(binary)}]
    j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
    target=MODEL/'royal_courtyard.glb'
    with target.open('wb') as f:
        f.write(struct.pack('<4sII',b'glTF',2,12+8+len(j)+8+len(binary)));f.write(struct.pack('<I4s',len(j),b'JSON'));f.write(j);f.write(struct.pack('<I4s',len(binary),b'BIN\x00'));f.write(binary)
    meta={'colliders':colliders,'lamps':lamps,'labels':labels,'groups':summary,'triangles':sum(s['triangles'] for s in summary),'materials':len(materials),'units':'metres','orientation':'Y up; north is -Z','spawn':[0,.05,34],'artwork':'Original AI landscape painting and painted beam texture; sculpted and openwork geometry authored by the editable Python model','sources':['tools/craft160_geometry.py'],'scope':'standalone art demonstration; original world unmodified'}
    (OUT/'layout.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'glb_bytes':target.stat().st_size,'triangles':meta['triangles'],'surfaces':sum(s['materials'] for s in summary),'colliders':len(colliders),'lamps':len(lamps)},ensure_ascii=True),flush=True)

def main():
    start=time.monotonic();textures()
    for args in [
        ('red','7f2c24',.38,0,'wood.png','wood_normal.png'),('wood','392319',.52,0,'wood.png','wood_normal.png'),('wood_light','795339',.52,0,'wood.png','wood_normal.png'),
        ('tile','427e70',.24,.05,'stone.png','stone_normal.png'),('tile_light','6e9c87',.3,.05),('tile_dark','214d49',.5),
        ('gold','c6a25e',.32,.7),('bronze','9b8554',.4,.62),('paint','ffffff',.62,0,'artisan_paint.png' if (TEX/'artisan_paint.png').exists() else 'painted_beam.png'),
        ('stone','c8c3af',.8,0,'stone.png','stone_normal.png'),('plaster','e6ddc8',.9,0,'plaster.png','plaster_normal.png'),('floor','9c978b',.62,0,'paving.png'),('paving','ddd8c7',.87,0,'paving.png'),
        ('ground','a6a18b',.93,0,'stone.png'),('rock','898b7a',.9,0,'stone.png'),('bark','514b34',.9,0,'wood.png'),
        ('leaf0','35594a',.85),('leaf1','64815b',.85),('leaf2','899663',.83),('flower','deb0a0',.7),('jade','598f82',.26),('porcelain','e1d7bd',.19,0,'porcelain.png'),('fabric','c4af87',.9,0,'linen.png'),('planks','96795c',.58,0,'wood_planks.png','wood_normal.png'),
        ('paper','e0d8b8',.95),('ink','333b38',.9),('book0','35565d',.9),('book1','766347',.9),('book2','8b4f3b',.9),('water','396b65',.13,.15)]:material(*args)
    material('lamp','efd3a0',.8,emission=[.8,.46,.16])
    painting='landscape_painting.png' if (TEX/'landscape_painting.png').exists() else 'painted_beam.png'
    material('painting','ffffff',.94,0,painting)
    hall();study();galleries();gate_and_garden();export_glb()
    print('Authoring seconds',round(time.monotonic()-start,2),flush=True)
if __name__=='__main__':main()
