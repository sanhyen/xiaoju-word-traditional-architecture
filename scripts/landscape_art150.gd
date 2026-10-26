extends RefCounted
## Authored landscape only. No new tasks, resources, rewards or interaction IDs.
var w
var b
var rng:=RandomNumberGenerator.new()
var counts:Dictionary={"trees":0,"groves":0,"courts":0,"rock_groups":0,"floating_pavilions":0,"rings":0,"sculptures":0,"regions":[],"belts":[]}
var roof
var dressed_frontages:Dictionary={}
func _init(target):w=target;b=w.b;roof=load("res://scripts/palace_styles160.gd").new(w);rng.seed=15020261025
func at(p:Vector2,up:float=0)->Vector3:return Vector3(p.x,w.height_at(p.x,p.y)+up,p.y)
func free_ground(p:Vector2,pad:float=4)->bool:
	var h:float=w.height_at(p.x,p.y)
	if h<float(w.layout.config.sea_y)+.3:return false
	if w.layout.protected(p):return false
	for r in w.layout.near(w.layout.road_index,p):
		var q:Vector3=w.layout.projection(p,r)
		if p.distance_to(Vector2(q.x,q.z))<r.width*.5+pad:return false
	for rec in w.building_bounds:
		if rec is Dictionary and rec.has("min") and rec.has("max"):
			if p.x>rec.min.x-pad and p.x<rec.max.x+pad and p.y>rec.min.z-pad and p.y<rec.max.z+pad:return false
	# Preserve the full portrait foreground and primary plaza sightline.
	if absf(p.x)<58 and p.y>26 and p.y<155:return false
	return true
func tree(p:Vector3,kind:int,s:float=1.0,pink:bool=false):
	var tones:Array=["355B4C","4E7360","71916B"] if not pink else ["DCAFC1","E8B8C9","EDD0DA"]
	var height:float=[10.0,14.0,8.0][kind]*s
	b.beam(p,p+Vector3(.35*s,height*.69,0),.48*s,"765745")
	if kind==1:
		for i in 4:
			var width:float=(6.5-i*1.1)*s
			b.shape(p+Vector3(.2*s,height*(.46+i*.15),0),Vector3(width,4.5*s,width*.85),tones[i%3],"pine150")
	else:
		for i in 6:
			var a:float=i*2.399;var q:Vector3=p+Vector3(cos(a)*(2.5 if kind==0 else 3.6)*s,height*(.73+.07*(i%3)),sin(a)*2.8*s)
			b.beam(p+Vector3(0,height*.5,0),q,.18*s,"765745")
			b.shape(q,Vector3(5.1,2.7 if kind==0 else 1.9,4.1)*s,tones[i%3],"shrub",a,"leaf")
			if kind==2 and pink:
				b.beam(q,q+Vector3(cos(a)*.7,-1.9*s,sin(a)*.7),.22*s,tones[(i+1)%3])
	counts.trees+=1
func grove(center:Vector2,radius:Vector2,n:int,pink:bool=false,large:bool=false):
	counts.groves+=1
	for i in n:
		var a:float=rng.randf()*TAU;var r:float=sqrt(rng.randf());var p:Vector2=center+Vector2(cos(a)*radius.x,sin(a)*radius.y)*r
		if not free_ground(p,5.0):continue
		var variant:int=i%3;var is_pink:bool=pink and i%5!=0
		if is_pink and variant==1:variant=0
		tree(at(p),variant,rng.randf_range(.75,1.35)*(1.3 if large else 1.0),is_pink)
		if i%4==0:b.shape(at(p+Vector2(3,-2),.45),Vector3(2.5,1.1,2),"60846A","shrub",a,"leaf")
func rock_group(p:Vector2,s:float=1):
	counts.rock_groups+=1
	for i in 5:
		var q:Vector2=p+Vector2(cos(i*2.4)*2.4,sin(i*2.4)*2.0)*s
		b.shape(at(q,1.2*s),Vector3(3.7,3.5+(i%3),2.9)*s,["82968D","9AA79C","687C78"][i%3],"rock",i*.6)
func bench(p:Vector3,yaw:float=0):
	var basis:=Basis(Vector3.UP,yaw)
	b.oriented_box(p+Vector3.UP*.55,Vector3(3.2,.18,.75),"A78C68",basis,false,"wood")
	for s in [-1,1]:b.box(p+basis*Vector3(s*1.1,.25,0),Vector3(.22,.5,.55),"C9C2AC",false,0,"stone")
	b.oriented_box(p+basis*Vector3(0,1,.30),Vector3(3.2,.20,.15),"A78C68",basis,false,"wood")
func court(p:Vector2,size:Vector2,flower:bool=false):
	if not free_ground(p,3):return
	var q:Vector3=at(p);counts.courts+=1
	# Low edges only on the far side; all entrances remain open.
	for side in [-1,1]:
		var end:Vector2=p+Vector2(side*size.x*.5,-size.y*.38)
		b.box(at(end,.38),Vector3(2,.7,1.5),"C9C2AC",false,0,"stone")
		b.shape(at(end,1),Vector3(2.4,1.2,1.9),"E8B8C9" if flower else "60846A","shrub",0,"leaf")
	bench(q+Vector3(-size.x*.28,.05,0),PI*.1)
	load("res://scripts/scenic_styles130.gd").new(w).pergola(q+Vector3(size.x*.25,0,-size.y*.2),Vector2(4.5,3.1),"765745","8FA77A")
func region_courts():
	var cards:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/landscape150_regions.json"))
	for card in cards:
		counts.regions.append(card.id)
		for p in card.groves:grove(Vector2(p[0],p[1]),Vector2(p[2],p[3]),int(p[4]),bool(card.get("pink",false)),bool(card.get("large",false)))
		for p in card.courts:court(Vector2(p[0],p[1]),Vector2(12,8),bool(card.get("pink",false)))
		for p in card.rocks:rock_group(Vector2(p[0],p[1]),float(p[2]))
		region_interface(card)
func short_wall(a:Vector2,c:Vector2,h:float=.85):
	var n:int=maxi(1,ceili(a.distance_to(c)/2.0));var direction:Vector2=(c-a).normalized()
	for j in n:
		var p:Vector2=a.lerp(c,(j+.5)/n)
		if not free_ground(p,2.0):continue
		var q:Vector3=at(p);var turn:=Basis(Vector3.UP,atan2(direction.x,direction.y))
		b.oriented_box(q+Vector3.UP*h*.5,Vector3(.42,h,a.distance_to(c)/n+.015),"C9C2AC",turn,true,"stone")
		b.oriented_box(q+Vector3.UP*(h+.045),Vector3(.58,.12,a.distance_to(c)/n+.05),"64767B",turn,false,"stone")
func region_interface(card:Dictionary):
	var id:String=card.id;var built:=0
	for raw in card.courts:
		var p:=Vector2(raw[0],raw[1])
		# Broken side enclosures leave the middle and the old routes open.
		if id in ["Z01","Z03","Z05","Z06","Z07","Z09","AZURE","CASTLE","CREEK"]:
			short_wall(p+Vector2(-8,-6),p+Vector2(-8,3),1.15 if id in ["CASTLE","Z09"] else .8)
			short_wall(p+Vector2(2,-6),p+Vector2(8,-6));built+=1
		if id in ["Z01","Z05","Z06"] and free_ground(p+Vector2(6,-6),2):
			var q:Vector3=at(p+Vector2(6,-6));var extent:Vector2=Vector2(7,3)
			load("res://scripts/scenic_styles130.gd").new(w).pergola(q,extent,"765745","667B76");built+=1
		if id in ["Z02","Z07","AZURE","ISLAND_01","ISLAND_02","CAPE"]:
			for i in 16:
				var v:Vector2=p+Vector2(9+sin(i*2.4)*5,cos(i*2.4)*7)
				if not free_ground(v,3):continue
				var q:Vector3=at(v)
				for j in 3:b.beam(q+Vector3(j*.16,0,0),q+Vector3(.3+j*.16,.65+(i%4)*.12,.24),.07,"8FA77A")
			built+=1
		if id=="Z07" and free_ground(p+Vector2(4,5),3):
			for row in 3:
				var q:Vector3=at(p+Vector2(3+row*.9,5));b.box(q+Vector3.UP*.08,Vector3(.65,.16,3.4),"765745",false,0,"soil")
				for j in 5:b.shape(q+Vector3(0,.3,j*.6-1.2),Vector3(.4,.45,.4),"60846A","shrub")
			built+=1
		if id=="Z06" and free_ground(p+Vector2(-4,5),3):
			var q:Vector3=at(p+Vector2(-4,5));b.box(q+Vector3.UP*.18,Vector3(4,.36,2.8),"C9C2AC",false,0,"stone")
			b.box(q+Vector3.UP*.37,Vector3(3.5,.025,2.3),"77AFB4",false);built+=1
	# Ground-floor window-side planting follows existing doorway orientation and leaves the opening clear.
	for venue in w.layout.creative_places:
		if str(venue.id) not in card.affected_nearby_ids or str(venue.id).ends_with("_UPPER"):continue
		if dressed_frontages.has(str(venue.id)):continue
		dressed_frontages[str(venue.id)]=true
		var door:=Vector3(venue.door[0],venue.door[1],venue.door[2]);var turn:=Basis(Vector3.UP,float(venue.door_yaw))
		for sign in [-1,1]:
			var q:Vector3=door+turn*Vector3(sign*4.2,.1,.35)
			if absf(w.height_at(q.x,q.z)-door.y)>1.0:continue
			b.oriented_box(q+Vector3.UP*.32,Vector3(1.5,.5,.58),"765745",turn,false,"wood")
			for j in 3:b.shape(q+turn*Vector3((j-1)*.45,.72,0),Vector3(.6,.65,.6),"E8B8C9" if id in ["Z03","Z07","CREEK"] else "8FA77A","shrub")
			built+=1
	if not counts.has("region_interfaces"):counts["region_interfaces"]={}
	counts.region_interfaces[id]=built
func belts():
	for i in 19:
		var x:float=-540+i*60
		grove(Vector2(x,-625+24*sin(i*.8)),Vector2(43,30),22,false,true)
		if i%2==0:rock_group(Vector2(x,-640+17*cos(i)),2.3)
	for side in [-1,1]:
		for i in 17:
			var z:float=-440+i*44
			var x:float=side*(548+24*sin(i*.9))
			grove(Vector2(x,z),Vector2(37,32),19,side==-1 and z< -120 and z> -420,z< -240)
			if i%3==0:rock_group(Vector2(side*592,z),1.6)
	for p in [[-510,-290],[-470,-190],[-535,-90],[-520,170],[510,100],[470,-320],[80,-570],[-180,-500]]:
		court(Vector2(p[0],p[1]),Vector2(12,8),p[0]<0 and p[1]< -100)
	for p in [[-95,548],[-55,551],[185,490],[222,490]]:grove(Vector2(p[0],p[1]),Vector2(13,9),9,false,false)
	counts.belts=["云冠山谷","樱溪花境","暖湾坡岸","青岚崖廊","星潮群岸"]
	# Mid-distance clusters turn the new shoulders into woodland openings instead of empty strips.
	var index:=0
	for road in w.layout.segments:
		if not str(road.id).begins_with("landscape150_") or road.bridge:continue
		index+=1
		if index%7!=0:continue
		var q:Vector3=(road.a+road.c)*.5;var direction:Vector3=(road.c-road.a).normalized();var side:=Vector2(-direction.z,direction.x)
		var center:=Vector2(q.x,q.z)+side*(17 if index%2==0 else -21)
		if preload("res://scripts/landscape_space150.gd").outside_core(center):grove(center,Vector2(15,13),11,center.x< -430 and center.y< -170 and center.y> -430,false)
func ring(center:Vector3,radius:float,yaw:float,tilt:float,tone:String):
	var turn:=Basis(Vector3.UP,yaw)*Basis(Vector3.FORWARD,tilt)
	var node=preload("res://scripts/precision_craft160.gd").new(w,"FLOATING_HALO").asset("halo",center,turn.scaled_local(Vector3.ONE*radius))
	node.set_meta("craft160_far",true)
	counts.rings+=1

func floating_rock(p:Vector3,r:float,depth:float):
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings:Array=[]
	for level in 4:
		var points:Array=[]
		for j in 14:
			var a:float=j*TAU/14;var width:float=r*[1.0,.86,.46,.06][level]*(1+.12*sin(a*3)+.08*cos(a*5))
			points.append(p+Vector3(cos(a)*width,-depth*[0.0,.20,.66,1.0][level],sin(a)*width*.74))
		rings.append(points)
	for level in 3:
		for j in 14:
			var q:Array=[rings[level][j],rings[level][(j+1)%14],rings[level+1][(j+1)%14],rings[level+1][j]]
			for k in [0,1,2,0,2,3]:mesh.set_color(Color(["B8BEAA","8A9C92","617C76"][level]).lightened(.04*(j%3)));mesh.add_vertex(q[k])
	mesh.generate_normals();var node:=MeshInstance3D.new();node.mesh=mesh.commit();var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=.95;node.material_override=mat;w.add_child(node)
	if r>6:
		for j in 11:
			var a:float=j*2.399;var q:Vector3=p+Vector3(cos(a)*r*.83,-depth*(.13+.035*(j%4)),sin(a)*r*.61)
			b.shape(q,Vector3(r*.35,depth*.27,r*.27),["8A9C92","A8B3A0","617C76"][j%3],"rock",a)
			if j%2==0:
				b.shape(q+Vector3.UP*depth*.12,Vector3(r*.36,1.4,r*.28),"60846A","shrub",a,"leaf")
				for v in 3:b.beam(q+Vector3(v*.45,0,0),q+Vector3(v*.45-.5,-3-j%3,.4),.16,"60846A")
func pavilion(p:Vector3,size:Vector2,levels:int=1,accessible:bool=false):
	counts.floating_pavilions+=1;floating_rock(p-Vector3.UP*.45,size.x*.68,size.x*.75)
	var precision=preload("res://scripts/precision_craft160.gd").new(w,"FLOATING_PAVILION")
	var underside=precision.asset("floating_under",p-Vector3.UP*.25,Basis.IDENTITY.scaled(Vector3(size.x/10,size.x/18,size.y/10)))
	underside.set_meta("craft160_far",true)
	b.box(p-Vector3.UP*.22,Vector3(size.x+.8,.44,size.y+.8),"C9C2AC",accessible,0,"stone")
	for level in levels:
		var q:Vector3=p+Vector3.UP*(level*4.5);var dims:Vector2=size*(1-level*.13)
		for x in [-dims.x*.4,0,dims.x*.4]:
			for z in [-dims.y*.38,dims.y*.38]:
				if accessible and level==0 and x==0 and z>0:continue
				precision.column(q+Vector3(x,0,z),3.6,.26)
				precision.asset("dougong",q+Vector3(x,3.2,z),Basis.IDENTITY.scaled(Vector3(.7,.7,.7)))
				if accessible and level==0:b.collision(q+Vector3(x,1.8,z),Vector3(.52,3.6,.52))
		b.box(q+Vector3(0,1.7,-dims.y*.35),Vector3(dims.x*.55,3.1,.24),"E5DDC8",accessible and level==0,0,"plaster")
		for side in [-1,1]:
			precision.asset("lattice_1",q+Vector3(side*dims.x*.18,1.8,-dims.y*.35+.19),Basis.IDENTITY.scaled(Vector3(dims.x*.17/2,1.3/1.7,1)))
		roof.roof_piece("",q+Vector3.UP*3.65,dims+Vector2(2.5,2.5),2.0,"667B76","hip")
		for sign in [-1,1]:
			b.beam(q+Vector3(-dims.x*.45,3.05,sign*dims.y*.38),q+Vector3(dims.x*.45,3.05,sign*dims.y*.38),.23,"BFA36A")
			for i in maxi(3,int(dims.x/1.3)):
				var x:float=lerpf(-dims.x*.46,dims.x*.46,(i+.5)/maxi(3,int(dims.x/1.3)))
				if accessible and sign==1 and absf(x)<1.8:continue
				b.box(q+Vector3(x,.7,sign*dims.y*.46),Vector3(.12,1.15,.12),"D8CDB4",false,0,"stone")
				b.box(q+Vector3(x,1.25,sign*dims.y*.46),Vector3(1.4,.13,.22),"D8CDB4",false,0,"stone")
		if not accessible:
			for sign in [-1,1]:
				b.box(q+Vector3(sign*dims.x*.25,1.7,-dims.y*.34+.2),Vector3(dims.x*.12,1.15,.07),"F2CE91",false)
				for j in 5:b.box(q+Vector3(sign*dims.x*.25+(j-2)*dims.x*.023,1.7,-dims.y*.34+.25),Vector3(.08,1.2,.05),"765745",false,0,"wood")
		if level>0:b.box(q-Vector3.UP*.2,Vector3(dims.x,.4,dims.y),"C9C2AC",false,0,"stone")
	if accessible:
		bench(p+Vector3(-size.x*.25,.02,1),PI*.5)
		for side in [-1,1]:
			for j in 8:b.box(p+Vector3(side*size.x*.5,.65,-size.y*.45+j*size.y*.13),Vector3(.14,1.3,.14),"D8D1BC",true,0,"stone")
			b.beam(p+Vector3(side*size.x*.5,1.2,-size.y*.5),p+Vector3(side*size.x*.5,1.2,size.y*.5),.18,"D8D1BC",true)
func crane(p:Vector3,scale_value:float,yaw:float):
	var node=preload("res://scripts/precision_craft160.gd").new(w,"FLOATING_CRANE").asset("crane",p,Basis(Vector3.UP,yaw).scaled_local(Vector3.ONE*scale_value))
	node.set_meta("craft160_far",true)
	counts.sculptures+=1

func floating_corner():
	# One localized skyline; the high sculptures are scenery, the lower pavilion has a real footbridge.
	pavilion(Vector3(466,112,-503),Vector2(34,27),4)
	pavilion(Vector3(520,132,-539),Vector2(22,18),2)
	pavilion(Vector3(423,126,-557),Vector2(18,14),2)
	pavilion(Vector3(558,104,-466),Vector2(14,12),1)
	ring(Vector3(482,143,-558),23,.15,.12,"BFA36A")
	ring(Vector3(431,127,-578),14,-.25,-.12,"AABDB1")
	ring(Vector3(536,117,-554),11,.35,.2,"BFA36A")
	crane(Vector3(405,137,-497),1.25,-.2);crane(Vector3(548,154,-510),.75,.4)
	for i in 23:
		var a:float=i*.37;var p:=Vector3(484+cos(a)*83,106+i%5*8,-522+sin(a)*52)
		if i%3==0:floating_rock(p,2+i%4,4+i%3)
		else:b.shape(p,Vector3(1.2,1.7,1.3)*(1+i%3*.4),"D8D1BC","rock",a)
	# The route is authored in the layout and is reused by navigation and recovery.
	var low:Vector3=w.layout.vector(w.layout.config.landscape150.lower_pavilion)
	pavilion(low,Vector2(11,9),1,true)
func build():
	var old:String=b.venue_context;b.venue_context="PALACE:LANDSCAPE150"
	region_courts();belts();floating_corner();water_composition();b.venue_context=old
	w.set_meta("landscape150",counts)
	print("LANDSCAPE150 ",JSON.stringify(counts))
func water_composition():
	var arch:Dictionary=w.layout.config.landscape150.main_arch
	var a:Vector3=w.layout.vector(arch.a);var c:Vector3=w.layout.vector(arch.c)
	var along:Vector3=(c-a).normalized();var side:=Vector3(-along.z,0,along.x)
	var span:float=Vector2(c.x-a.x,c.z-a.z).length();var center:Vector3=(a+c)*.5
	var bridge_path:Array=[];var bridge_length:=0.0
	for road in w.layout.config.roads:
		if not str(road.id).begins_with("landscape150_azure_cliff_") or not road.bridge:continue
		var p:Vector3=w.layout.vector(road.points[0]);var q:Vector3=w.layout.vector(road.points[-1])
		if p.z>maxf(a.z,c.z)+.1 or q.z<minf(a.z,c.z)-.1:continue
		var length:float=Vector2(q.x-p.x,q.z-p.z).length();bridge_path.append({"a":p,"c":q,"start":bridge_length,"length":length});bridge_length+=length
	# One continuous masonry arch under the actual guarded road, not disconnected mini arches.
	for flank in [-1,1]:
		for i in 40:
			var t:float=(i+.5)/40.0;var q:Vector3=a.lerp(c,t);var direction:Vector3=along
			for piece in bridge_path:
				if t*bridge_length<=piece.start+piece.length:
					q=piece.a.lerp(piece.c,(t*bridge_length-piece.start)/piece.length);direction=(piece.c-piece.a).normalized();break
			var cross:=Vector3(-direction.z,0,direction.x).normalized();q+=cross*(arch.width*.5+.25)*flank
			q.y-=1.2+15.0*pow(2*t-1,2)
			var tangent:Vector3=(direction+Vector3.UP*(-60*(2*t-1)/maxf(1,bridge_length))).normalized()
			var turn:=Basis(tangent,cross.cross(tangent).normalized(),cross)
			b.oriented_box(q,Vector3(bridge_length/40+.3,1.0,.85),"BDBEA8" if i%3 else "A6AD9B",turn,false,"stone")
		for end in [a,c]:
			var foot:float=w.height_at(end.x,end.z)-1
			b.box(Vector3(end.x,(foot+end.y)*.5,end.z)+side*(arch.width*.5+.25)*flank,Vector3(3,maxf(1,end.y-foot),3),"A6AD9B",false,0,"stone")
	counts["main_arch_span_m"]=span
	# Whitewater and wet rock accents follow the authored downhill channels.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var strips:=0
	for river in w.layout.river_segments:
		if not str(river.id).begins_with("landscape150_"):continue
		var direction:Vector3=(river.c-river.a).normalized();var cross:=Vector3(-direction.z,0,direction.x)
		var pieces:int=maxi(1,int(river.a.distance_to(river.c)/17))
		for j in pieces:
			var q:Vector3=river.a.lerp(river.c,(j+.5)/pieces)+Vector3.UP*.045
			for fragment in 5:
				var middle:Vector3=q+cross*((fragment-2)*river.width*.13)+direction*(sin(j*2.4+fragment)*1.0)
				var width:float=.15+.12*(fragment%3);var length:float=.12+.16*(j%3);var vertices:Array=[middle-cross*width-direction*length,middle+cross*width-direction*length,middle+cross*width+direction*length,middle-cross*width+direction*length]
				for k in [0,1,2,0,2,3]:st.add_vertex(vertices[k])
			strips+=1
	st.generate_normals();var foam:=MeshInstance3D.new();foam.name="Landscape150RiverFoam";foam.mesh=st.commit()
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("A5C7BD");mat.roughness=.55;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;foam.material_override=mat;w.add_child(foam)
	counts["river_foam_bands"]=strips
