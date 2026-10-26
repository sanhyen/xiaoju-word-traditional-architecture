extends RefCounted
static var spec:Dictionary={}
static var field:Image
static var texture:Texture2D
static func ready_data():
	if not spec.is_empty():return
	spec=JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes_v13.json"))
	texture=load("res://assets/materials/biome_field130.png");field=texture.get_image()
static func color_at(p:Vector2)->Color:
	ready_data();var b:Array=spec.bounds;var uv:=Vector2((p.x-b[0])/b[2],(p.y-b[1])/b[3])
	var x:float=clampf(uv.x*(field.get_width()-1),0,field.get_width()-1);var y:float=clampf(uv.y*(field.get_height()-1),0,field.get_height()-1)
	var ix:int=floori(x);var iy:int=floori(y);var nx:int=mini(ix+1,field.get_width()-1);var ny:int=mini(iy+1,field.get_height()-1)
	var c:Color=field.get_pixel(ix,iy).lerp(field.get_pixel(nx,iy),x-ix).lerp(field.get_pixel(ix,ny).lerp(field.get_pixel(nx,ny),x-ix),y-iy);c.a=1;return c
static func id_at(p:Vector2,height:float=0)->String:
	ready_data()
	var uv:=Vector2((p.x+672)/1344.0,(p.y+752)/1504.0);var ix:int=clampi(roundi(uv.x*(field.get_width()-1)),0,field.get_width()-1);var iy:int=clampi(roundi(uv.y*(field.get_height()-1)),0,field.get_height()-1)
	if p.y< -285 and height>60:return "E8"
	return "E"+str(clampi(roundi(field.get_pixel(ix,iy).a*12),1,12))
static func nearest_region(p:Vector2)->Dictionary:
	ready_data();var result:Dictionary=spec.regions[0];var best:float=INF
	for r in spec.regions:
		var d:float=Vector2((p.x-r.x)/r.rx,(p.y-r.z)/r.rz).length()
		if d<best:best=d;result=r
	return result
static func biome(p:Vector2,h:float=0)->Dictionary:
	ready_data();var result:Dictionary=spec.biomes[id_at(p,h)].duplicate(true);var r:Dictionary=nearest_region(p)
	if r.has("tree_override"):result.trees=r.tree_override;result.rock=r.rock_override;result.fog=r.fog_override
	return result
static func bind(material:ShaderMaterial):
	ready_data();material.set_shader_parameter("scenic_biomes_enabled",true);material.set_shader_parameter("scenic_biome_field",texture)
func choose(p:Vector3,hint:int)->int:
	var data:Dictionary=biome(Vector2(p.x,p.z),p.y);var roll:int=posmod(floori(p.x*1.37+p.z*2.53)+hint*17,100)
	return int(data.trees[0 if roll<60 else 1 if roll<90 else 2])
func tree(b,p:Vector3,hint:int,scale_value:float,forced_kind:int=0):
	var kind:int=choose(p,hint) if forced_kind==0 else forced_kind;var variant:int=posmod(floori(p.x*.37+p.z*.51),3);var s:float=scale_value*(.88+variant*.12);var palette:Dictionary=biome(Vector2(p.x,p.z),p.y)
	var old_context:String=b.venue_context;b.venue_context=""
	if kind<=7:
		load("res://scripts/vegetation_art.gd").new().tree(b,p,kind-1,s)
	else:
		var count:Dictionary=b.tree_counts;var key:String="T%02d"%kind;count[key]=int(count.get(key,0))+1
		match kind:
			8:
				var top:Vector3=p+Vector3(.8+variant*.15,8.4,0)*s;b.beam(p,p+Vector3(.2,4,0)*s,.38*s,"9C8463");b.beam(p+Vector3(.2,4,0)*s,top,.28*s,"9C8463")
				for i in 7:
					var a:float=i*TAU/7+variant*.3;var mid:Vector3=top+Vector3(cos(a)*1.9,.20,sin(a)*1.9)*s;var end:Vector3=top+Vector3(cos(a)*4.3,-1.5,sin(a)*4.3)*s
					b.beam(top,mid,.42*s,"76965A");b.beam(mid,end,.57*s,"6E8F53")
			9:
				for i in 3:
					var q:Vector3=p+Vector3((i-1)*.48,0,sin(i+variant)*.3)*s;var h:float=(1.2+i*.6)*s;b.box(q+Vector3.UP*h*.5,Vector3(.36*s,h,.38*s),"7C9A6E",false,0,"leaf")
					b.beam(q+Vector3(0,h*.55,0),q+Vector3(.65*s,h*.55,0),.23*s,"7C9A6E")
			10:
				b.beam(p,p+Vector3(.25,4.2,0)*s,.35*s,"786047")
				for i in 5:
					var q:Vector3=p+Vector3(cos(i*2.4+variant)*2.1,3.5+(i%3)*.68,sin(i*2.4+variant)*1.9)*s;b.beam(p+Vector3.UP*2.6*s,q,.13*s,"947255");b.box(q,Vector3(3.1,.8,2.5)*s,["AD6555","BB7953","BA6C59"][i%3],false,0,"leaf")
			11:
				b.beam(p,p+Vector3(.5,17.5,0)*s,2.05*s,"786047")
				for i in 7:
					var a:float=i*TAU/7;var root:Vector3=p+Vector3(cos(a)*3.5,0,sin(a)*3.5)*s;b.beam(root,p+Vector3.UP*3.5*s,.65*s,"6E5941")
				for i in 7:
					var q:Vector3=p+Vector3(cos(i*2.4+variant)*3.7,17+(i%3)*2.4,sin(i*2.4+variant)*3.7)*s;b.beam(p+Vector3.UP*12*s,q,.45*s,"786047");b.box(q,Vector3(7.0,3.2,5.8)*s,["405F46","4E6E48","6B8658"][i%3],false,0,"leaf")
			12:
				b.beam(p,p+Vector3(.13,2.7,0)*s,.30*s,"786047")
				for i in 4:
					var q:Vector3=p+Vector3(cos(i*2.4)*1.2,2.6+(i%2)*.6,sin(i*2.4)*1.1)*s;b.box(q,Vector3(2.2,1.4,2.0)*s,"7A9655",false,0,"leaf")
					for j in 3:b.shape(q+Vector3(sin(j*2.3)*.9,-.45,cos(j*2.3)*.8)*s,Vector3.ONE*.2*s,"C67E67","shrub")
			13:
				for i in 6:
					var q:Vector3=p+Vector3(sin(i*2.4)*.7,0,cos(i*2.4)*.7)*s;var h:float=(3.7+i%3*.5)*s;b.box(q+Vector3.UP*h*.5,Vector3(.09*s,h,.09*s),"7FA25A",false,0,"bamboo")
					for side in [-1,1]:b.beam(q+Vector3.UP*h*.65,q+Vector3(side*.9*s,h*.8,.3*s),.08*s,"678650");b.box(q+Vector3(side*.6*s,h*.82,.3*s),Vector3(1.0,.2,.6)*s,"7A9A60",false,0,"leaf")
	b.venue_context=old_context
func clear(w,p:Vector2,margin:float=1.5)->bool:
	if not w.clear_of_paths(p,margin):return false
	if absf(p.x)<24 and p.y>37 and p.y<138:return false
	for item in w.layout.near(w.layout.creative_index,p):
		var h:Dictionary=item.place
		if absf(p.x-h.center[0])<float(h.size[0])*.5+margin+1 and absf(p.y-h.center[2])<float(h.size[1])*.5+margin+1:return false
	return w.height_at(p.x,p.y)>-1.9
func enrich(w):
	ready_data()
	var b=w.b;var trees:=0;var flowers:=0;var pockets:=0
	var rng:=RandomNumberGenerator.new();rng.seed=6182026130
	for r in spec.regions:
		var data:Dictionary=spec.biomes[r.biome]
		for cluster in (4 if r.biome in ["E6","E7","E12"] else 2):
			var center:=Vector2(float(r.x)+rng.randf_range(-.65,.65)*r.rx,float(r.z)+rng.randf_range(-.65,.65)*r.rz);var placed:Array=[]
			for i in (16 if r.biome in ["E7","E12"] else 9):
				var angle:float=rng.randf()*TAU;var radius:float=sqrt(rng.randf())*23;var q:Vector2=center+Vector2(cos(angle),sin(angle))*radius
				if not clear(w,q,2):continue
				var near:bool=false
				for other in placed:
					if q.distance_to(other)<3.6:near=true;break
				if near:continue
				placed.append(q);tree(b,w.surface(q.x,q.y),int(rng.randi()%13),rng.randf_range(.72,1.04));trees+=1
			for i in 7:
				var q:Vector2=center+Vector2(cos(i*2.4),sin(i*2.4))*(17+i*.9)
				if clear(w,q,.6):b.shape(w.surface(q.x,q.y,.25),Vector3(1.5,.7,1.1),data.shade,"shrub");b.shape(w.surface(q.x+.6,q.y,.15),Vector3(1,.6,.8),data.rock,"rock")
	for house in w.layout.creative_places:
		var o:=Vector3(house.center[0],house.center[1],house.center[2]);var data:Dictionary=biome(Vector2(o.x,o.z),o.y)
		for side in [-1,1]:
			var at:Vector2=Vector2(o.x+side*(float(house.size[0])*.5+2.0),o.z-float(house.size[1])*.27)
			if clear(w,at,.25):
				for i in 4:b.shape(w.surface(at.x,at.y+i*.7,.28),Vector3(.9,.7,.75),data.shade if i%2 else data.flower,"shrub")
			var q:Vector2=at+Vector2(side*2.6,-3.5)
			if clear(w,q,1.5):tree(b,w.surface(q.x,q.y),0,.67);trees+=1
		pockets+=1
	# Curved strips of lavender, sunflowers and poppies, safely outside existing paths.
	for center in [Vector2(-286,-223),Vector2(-280,194),Vector2(-193,-230)]:
		for band in 5:
			for i in 38:
				var q:Vector2=center+Vector2((i-19)*.75,band*2.3+sin(i*.13)*1.6)
				if not clear(w,q,.4):continue
				var at:Vector3=w.surface(q.x,q.y,.38+(.4 if band%3==1 else 0));b.shape(at,Vector3(.65,.5,.6),["AD9CC7","CDB66D","BA7D70"][band%3],"shrub");flowers+=1
	w.set_meta("scenic130_ecology",{"biomes":12,"tree_prototypes":13,"variants_per_prototype":3,"new_cluster_trees":trees,"building_gardens":pockets,"field_flower_clusters":flowers,"placement":"deterministic clustered sampling, 3.6m exclusion, protected roads and portrait corridor"})
