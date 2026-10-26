extends RefCounted
## Shared architectural data. Structural collision and all occupied floor coordinates stay authoritative.
static var families:Dictionary={}
static var assignments:Dictionary={}
static var pilot_families:Array=[]
var w
var b
var craft
var roofs
func _init(world):
	w=world;b=w.b;craft=load("res://scripts/craft_components120.gd").new(w);roofs=load("res://scripts/creative_architecture110.gd").new(w)
static func load_data():
	if not families.is_empty():return
	families=JSON.parse_string(FileAccess.get_file_as_string("res://data/architecture_styles_v13.json")).families
	assignments=JSON.parse_string(FileAccess.get_file_as_string("res://data/building_style_assignment_v13.json")).buildings
static func style(id:String)->Dictionary:
	load_data()
	if not assignments.has(id):return {}
	var row:Dictionary=assignments[id];var result:Dictionary=families[row.family].duplicate(true)
	if not pilot_families.is_empty() and row.family not in pilot_families:return {}
	if not str(row.subtype).is_empty():result.merge(result.subtypes[row.subtype],true)
	if not str(row.wall_override).is_empty():result.wall.color=[row.wall_override]
	if not str(row.roof_override).is_empty():result.roof.color=[row.roof_override]
	if not str(row.accent_override).is_empty():result.trim=row.accent_override
	result.merge({"id":id,"family":row.family,"rank":row.rank,"subtype":row.subtype,"lamp":families[row.family].lamp},true)
	return result
static func muted(tone:String)->String:
	var c:=Color(tone)
	if c.s>.55:c=Color.from_hsv(c.h,.55,c.v)
	return c.to_html(false)
static func geometry_style(world,id:String,p:Vector3,size:Vector3,tone:String,kind:String)->Dictionary:
	return load("res://scripts/palace_styles140.gd").geometry(world,id,p,size,tone,kind)

func roof(id:String,p:Vector3,size:Vector2,height:float)->bool:
	return load("res://scripts/palace_styles160.gd").new(w).roof(id,p,size,height)

func roof_strip(a:Vector3,c:Vector3,depth:float,color:String):
	var along:Vector3=(c-a).normalized();var normal:=Vector3(-along.y,along.x,0)
	b.oriented_box((a+c)*.5,Vector3(a.distance_to(c)+.10,.34,depth),color,Basis(along,normal,Vector3.BACK),false,"slate")
func tile_edges(o:Vector3,width:float,depth:float,tone:String):
	for side in [-1,1]:
		for x in range(-int(width),int(width)+1):b.box(o+Vector3(x*.5,-.04,side*depth*.5),Vector3(.44,.16,.35),tone,false,0,"slate")
func forest_roof(id:String,p:Vector3,size:Vector2,height:float):
	load("res://scripts/palace_styles160.gd").new(w).roof(id,p,size,height)

func complete():
	load("res://scripts/palace_styles160.gd").new(w).complete()

func details(p:Dictionary,s:Dictionary):
	var id:String=p.id;var o:=Vector3(p.center[0],p.center[1],p.center[2]);var width:float=p.size[0];var depth:float=p.size[1];var height:float=float(p.floors[-1])-o.y+3.7
	var turn:=Basis(Vector3.UP,float(p.door_yaw));var k:float={"major":1.0,"medium":.72,"small":.45}[s.rank]
	if absf(sin(float(p.door_yaw)))>.7:var swap:float=width;width=depth;depth=swap
	var trim:String=s.trim;var base:String={"A1":"2E4F66","A2":"E8E2D2","A3":"B4AA96","A4":"B8AC93","A5":"999B97","A6":"9A9890","A7":"9C927D","A8":"8D8A82","A9":"B07A52","A10":"6E7074","A11":"95764E","A12":"66513C","A13":"9B9F94"}[s.family]
	# A skirt follows each wall, below the existing floor; no new threshold or collider.
	for side in [-1,1]:
		for flank in [-1,1]:
			var loc:=Vector3(side*(width*.5+.06),-.28,flank*depth*.33);var q:Vector3=o+turn*loc
			var ground:float=minf(o.y-.20,w.height_at(q.x,q.z));var deep:float=minf(3.0,maxf(.35,o.y-ground))
			b.oriented_box(Vector3(q.x,o.y-deep*.5-.06,q.z),Vector3(.22,deep,maxf(1.0,depth*.30)),base,turn,false,"stone" if s.family not in ["A11","A12"] else "wood")
	# All four elevations receive windows and their own joinery. Doors remain clear.
	for face in 4:
		var face_yaw:float=float(p.door_yaw)+face*PI*.5;var span:float=width if face%2==0 else depth;var offset:float=depth*.5+.29 if face%2==0 else width*.5+.29
		for sign in [-1,1]:
			var center:Vector3=o+Basis(Vector3.UP,face_yaw)*Vector3(sign*span*.30,2.0,offset)
			var frame=craft.at(center,face_yaw)
			match str(s.window):
				"deep_arch","tall_fanlight":
					frame.arch_ring(Vector3(-.65,-.65,0),1.3,.8,.12,trim)
					for edge in [-1,1]:frame.part(Vector3(edge*.83,0,0),Vector3(.22,1.45,.17),trim)
				"round","porthole":
					frame.arch_ring(Vector3(-.62,-.62,0),1.24,0,.15,trim)
					frame.arch_ring(Vector3(.62,.62,0),1.24,0,.15,trim)
				_:
					frame.window(Vector3.ZERO,Vector2(1.3 if s.family in ["A7","A8"] else 1.7,1.7 if s.family=="A3" else 1.3),trim,s.family in ["A6","A10"])
			if s.family=="A2":
				for edge in [-1,1]:
					for row in 6:frame.part(Vector3(edge*1.08,-.65+row*.24,.11),Vector3(.5,.16,.12),trim)
			if s.family=="A10":
				for x in [-.55,0,.55]:frame.part(Vector3(x,0,.10),Vector3(.07,1.3,.09),"2F3236")
			if s.family=="A5":frame.part(Vector3(0,1.8,0),Vector3(2.6,.12,.20),"8C939B")
	match str(s.family):
		"A1":
			for side in [-1,1]:
				var q:Vector3=o+Vector3(side*width*.40,0,depth*.5+1.65);b.box(q+Vector3.UP*1.7,Vector3(.16,3.4,.16),"38525B",false,0,"metal");b.beam(q+Vector3.UP*2.4,q+Vector3(-side*.7,3.25,0),.12,"38525B")
		"A2":
			if id=="AZURE_VIEW":
				var dome:=SphereMesh.new();dome.radius=3.5;dome.height=7;dome.radial_segments=16;dome.rings=8;var mesh:=MeshInstance3D.new();mesh.mesh=dome;mesh.material_override=b.material("3F7FA8");mesh.position=o+Vector3(0,height+1.8,0);w.add_child(mesh)
			for side in [-1,1]:
				var q:Vector3=o+turn*Vector3(side*(width*.5+.8),0,depth*.30);b.shape(q+Vector3.UP*.65,Vector3(1.2,1.3,1.2),"B98768","pot")
			if k>.5:pergola(o+turn*Vector3(width*.32,0,depth*.5+2),Vector2(3.4,2.4),"B7916A","B77D9B")
		"A3":
			for side in [-1,1]:
				var q:Vector3=o+turn*Vector3(side*width*.28,3.0,depth*.5+.8)
				for i in 6:b.oriented_box(q+turn*Vector3((i-2.5)*.4,0,0),Vector3(.4,.12,1.5),str(s.wall.color[0]) if i%2 else "F1E7D5",turn*Basis(Vector3.RIGHT,-.12),false,"fabric")
			if id in ["B03","LISTENING_EAST"]:
				for side in [-1,1]:b.beam(o+turn*Vector3(side*width*.43,.7,-depth*.5-.35),o+turn*Vector3(-side*width*.40,height-1,-depth*.5-.35),.13,"F3EDE0")
		"A4":
			for i in [-3,-2,-1,1,2,3]:
				var q:Vector3=o+turn*Vector3(i*width/7,0,depth*.5+1.8);b.box(q+Vector3.UP*1.65,Vector3(.4,3.3,.4),"E3DBC8",false,0,"stone");b.box(q+Vector3.UP*3.32,Vector3(.65,.18,.65),"D2C5AD",false,0,"stone")
		"A5":
			for side in [-1,1]:
				var a:Vector3=o+Vector3(side*width*.5,height-1,-depth*.5);var c:Vector3=o+Vector3(side*width*.5,height-1,depth*.5)
				b.beam(a,c,.23,"8C939B");b.beam(a+Vector3.UP*.65,c+Vector3.UP*.65,.16,"8C939B")
				for i in 5:b.beam(a.lerp(c,float(i)/5),a.lerp(c,float(i+1)/5)+Vector3.UP*.65,.10,"8C939B")
		"A6":
			for side in [-1,1]:b.beam(o+Vector3(side*(width*.5+.31),.5,-depth*.35),o+Vector3(side*(width*.5+.31),height-1,depth*.35),.13,"3A3D40")
		"A7":farm_purpose(p,s,o,width,depth,height)
		"A8":
			for side in [-1,1]:
				for row in 9:b.shape(o+Vector3(side*(width*.5+.12),.45+row*.37,-depth*.5),Vector3(.35,.35,.20),"A28461","cylinder",PI*.5)
				b.beam(o+Vector3(side*width*.45,.4,depth*.5+.5),o+Vector3(side*width*.23,3.4,depth*.5+.5),.23,"987654")
		"A9":
			for i in 3:b.shape(o+Vector3(width*.5+.8,.4,-depth*.30+i*.9),Vector3(.65,.8,.65),["B9845A","C08F62","A7684A"][i],"pot")
		"A10":
			for level_y in p.floors:
				for side in [-1,1]:
					var q:=Vector3(o.x+side*width*.43,float(level_y)+3.2,o.z+depth*.5+.55)
					for step in 3:b.box(q+Vector3(0,step*.12,0),Vector3(.45+step*.15,.12,.5+step*.15),"A95645",false,0,"wood")
		"A11":
			for side in [-1,1]:
				for z in [-depth*.4,depth*.4]:b.box(o+Vector3(side*width*.43,-.9,z),Vector3(.42,1.8,.42),"A98B5E",false,0,"wood")
		"A12":
			for side in [-1,1]:
				var q:Vector3=o+Vector3(side*(width*.5+.4),-.45,-depth*.35);b.beam(q,q+Vector3(-side*1.2,1.8,.4),.35,"705A42")
			if id=="TREEHOUSE_3":
				var cap:=SphereMesh.new();cap.radius=width*.6;cap.height=width*.42;cap.radial_segments=12;cap.rings=4;var node:=MeshInstance3D.new();node.mesh=cap;node.material_override=b.material("A66B5F");node.position=o+Vector3.UP*4.8;w.add_child(node)
	# Two restrained lamps per building use emission, not two more real-time lights.
	for side in [-1,1]:
		var pos:Vector3=o+turn*Vector3(side*(width*.5-.75),2.55,depth*.5+.55)
		var lamp:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(.25,.42,.25) if s.family!="A10" else Vector3(.4,.55,.4);lamp.mesh=mesh;lamp.material_override=b.material(s.lamp).duplicate();lamp.material_override.emission_enabled=true;lamp.material_override.emission=Color(s.lamp);lamp.material_override.emission_energy_multiplier=.15;lamp.position=pos;lamp.set_meta("stream_ref","scenic_lamp:"+s.family);lamp.set_meta("scenic_lamp_color",s.lamp);lamp.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;w.add_child(lamp)
func pergola(p:Vector3,size:Vector2,wood:String,flower:String):
	for x in [-size.x*.5,size.x*.5]:
		for z in [-size.y*.5,size.y*.5]:b.box(p+Vector3(x,1.4,z),Vector3(.14,2.8,.14),wood,false,0,"wood")
	for x in range(-int(size.x),int(size.x)+1):b.box(p+Vector3(x*.5,2.8,0),Vector3(.1,.15,size.y+.4),wood,false,0,"wood")
	for side in [-1,1]:b.shape(p+Vector3(side*size.x*.36,2.85,0),Vector3(1.5,.8,size.y),flower,"shrub")
func farm_purpose(p:Dictionary,s:Dictionary,o:Vector3,width:float,depth:float,height:float):
	var id:String=p.id;var q:Vector3=o+Vector3(width*.5+.85,0,-depth*.18)
	match id:
		"H01":craft.device("oven",q,.65);b.box(q+Vector3(0,height*.55,-.6),Vector3(.72,height+1.8,.72),"9B6753",false,0,"brick")
		"H02":craft.device("tools",q,.7);b.box(q+Vector3(0,.5,2),Vector3(1.5,1.0,1.2),"C4AD79",false,0,"thatch")
		"H03":craft.device("easel",q,.8)
		"H04":craft.device("espresso",q,.65)
		"H05":craft.device("telescope",o+Vector3(width*.28,height+1,-depth*.24),.7)
		"H06":craft.device("chimes",q+Vector3.UP*1.2,.8)
		"H07":b.box(q+Vector3.UP*(height*.5),Vector3(1.15,height+2.2,1.1),"A39D90",false,0,"stone")
		"H08":craft.device("drying",q,.75)
		"H09":craft.device("flowerbench",q,.65)
		"H10":craft.device("bindery",q,.65)
		"H11":craft.device("puppet",q,.7)
		"H12":
			for i in 8:b.box(o+Vector3(width*.5+.36,1.2+i*.23,0),Vector3(.10,.17,3),"324B40",false,0,"wood")
			b.box(q+Vector3.UP*2.5,Vector3(.35,.5,.22),"C57D73",false,0,"fabric")
		"H13":craft.device("drying",q,.8)
		"H14":
			for i in 4:b.box(o+Vector3(width*.23,height+.4+i*.32,-depth*.1+i*.45),Vector3(1.2,.16,.9),"B58B5E",false,0,"wood")
			for i in 3:b.shape(q+Vector3(0,.55,i*.65),Vector3(.7,1.1,.7),"B7A17B","pot")
		_:pass
	if s.subtype=="A7d":pergola(o+Vector3(-width*.33,0,depth*.5+2),Vector2(3,2),"94775A","C49DA9")
