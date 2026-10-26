extends RefCounted
## Complete palace joinery over the existing occupied geometry and stable entrances.
static var config:Dictionary={}
static var roof_materials:Dictionary={}
var w
var b
func _init(world):w=world;b=w.b
static func ready_data():
	if config.is_empty():config=JSON.parse_string(FileAccess.get_file_as_string("res://data/palace_v14.json"))
static func definition(id:String)->Dictionary:
	ready_data();return config.buildings.get(id,{})
static func geometry(world,id:String,p:Vector3,size:Vector3,tone:String,kind:String)->Dictionary:
	if id.begins_with("PALACE:") or world.get("layout")==null:return {"tone":tone,"kind":kind}
	var place:Dictionary={}
	if not id.is_empty():
		for record in world.layout.creative_places:
			if str(record.id)==id:place=record;break
	if place.is_empty() and kind in ["plaster","stone","slate","wood","metal","thatch","brick"]:
		var best:float=INF
		for candidate in world.layout.near(world.layout.creative_index,Vector2(p.x,p.z)):
			var record:Dictionary=candidate.place;var at:=Vector3(record.center[0],record.center[1],record.center[2]);var delta:Vector3=(p-at).abs()
			if delta.x>float(record.size[0])*.5+1 or delta.z>float(record.size[1])*.5+1 or p.y<at.y-.5 or p.y>float(record.floors[-1])+8:continue
			var distance:float=Vector2(delta.x,delta.z).length()
			if distance<best:best=distance;place=record;id=str(record.id)
	if place.is_empty():return {"tone":tone,"kind":kind}
	var d:Dictionary=definition(id)
	if d.is_empty():return {"tone":tone,"kind":kind}
	var edge:bool=absf(p.x-float(place.center[0]))>float(place.size[0])*.5-.8 or absf(p.z-float(place.center[2]))>float(place.size[1])*.5-.8
	if kind in ["slate","thatch"]:return {"tone":str(d.roof_color),"kind":"slate"}
	if edge and size.y>.35 and minf(size.x,size.z)<1.25:
		if kind in ["plaster","stone","brick","earth","metal"]:return {"tone":str(d.wall),"kind":"plaster"}
		if kind in ["wood","log","bamboo"]:return {"tone":str(d.wood),"kind":"wood"}
		if kind.is_empty() and Color(tone).s<.30:return {"tone":str(d.wood) if maxf(size.x,size.z)<.85 else str(d.wall),"kind":"wood" if maxf(size.x,size.z)<.85 else "plaster"}
	if edge and size.y<.4 and maxf(size.x,size.z)>2.5 and minf(size.x,size.z)<1.0 and Color(tone).s<.35:return {"tone":str(d.wood),"kind":"wood"}
	return {"tone":tone,"kind":kind}
func box(p:Vector3,size:Vector3,tone:String,turn:Basis=Basis.IDENTITY,kind:String="wood"):
	b.oriented_box(p,size,tone,turn,false,kind)
func beam(a:Vector3,c:Vector3,width:float,tone:String):b.beam(a,c,width,tone,false)
func surface(points:PackedVector3Array,tone:String):
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in [[0,1,2],[0,2,3]]:
		if (points[triangle[1]]-points[triangle[0]]).cross(points[triangle[2]]-points[triangle[0]]).length_squared()<.000001:continue
		for i in triangle:tool.add_vertex(points[i])
	tool.generate_normals();var node:=MeshInstance3D.new();node.mesh=tool.commit()
	if not roof_materials.has(tone):
		var mat:StandardMaterial3D=b.material(tone).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;roof_materials[tone]=mat
	node.material_override=roof_materials[tone];w.add_child(node)
func roof_piece(id:String,o:Vector3,size:Vector2,rise:float=2.0,tone:String="",form:String="hip",yaw:float=0.0):
	var rotator=load("res://scripts/creative_architecture110.gd").new(w);var mark:Dictionary=rotator.capture() if absf(yaw)>.001 else {}
	var d:Dictionary=definition(id);var color:String=str(d.get("roof_color","557D70")) if tone.is_empty() else tone
	var previous:String=b.venue_context;b.venue_context="PALACE:"+id
	var width:float=maxf(1.2,size.x);var depth:float=maxf(1.2,size.y);var half_x:float=width*.5;var half_z:float=depth*.5;var high:float=clampf(rise,.55,minf(width,depth)*.35+1)
	var ridge_half:float=maxf(.12,(width-depth)*.30+width*.13)
	if form in ["hard_gable","hanging_gable"]:ridge_half=half_x-.25
	var segments:int=5
	for sign in [-1,1]:
		for step in segments:
			var u:float=float(step)/segments;var v:float=float(step+1)/segments
			var za:float=sign*half_z*u;var zb:float=sign*half_z*v
			var ya:float=high*pow(1-u,1.50)+pow(u,6)*.36;var yb:float=high*pow(1-v,1.50)+pow(v,6)*.36
			var xa:float=lerpf(ridge_half,half_x,u);var xb:float=lerpf(ridge_half,half_x,v)
			surface(PackedVector3Array([o+Vector3(-xa,ya,za),o+Vector3(xa,ya,za),o+Vector3(xb,yb,zb),o+Vector3(-xb,yb,zb)]),color)
			if step==segments-1:box(o+Vector3(0,yb-.13,zb),Vector3(width+.12,.23,.22),"314E47",Basis.IDENTITY,"slate")
		if form not in ["hard_gable","hanging_gable"]:
			for step in segments:
				var u:float=float(step)/segments;var v:float=float(step+1)/segments
				var xa:float=sign*lerpf(ridge_half,half_x,u);var xb:float=sign*lerpf(ridge_half,half_x,v)
				var ya:float=high*pow(1-u,1.50)+pow(u,6)*.36;var yb:float=high*pow(1-v,1.50)+pow(v,6)*.36
				surface(PackedVector3Array([o+Vector3(xa,ya,-half_z*u),o+Vector3(xa,ya,half_z*u),o+Vector3(xb,yb,half_z*v),o+Vector3(xb,yb,-half_z*v)]),color)
			box(o+Vector3(sign*half_x,.21,0),Vector3(.22,.23,depth+.12),"314E47",Basis.IDENTITY,"slate")
		else:
			var end:float=sign*(half_x-.18)
			surface(PackedVector3Array([o+Vector3(end,.02,-half_z),o+Vector3(end,high,0),o+Vector3(end,high,0),o+Vector3(end,.02,half_z)]),str(d.get("wall","E5DDCA")))
	# Ridges and tile bands follow the same curved slope, not a flat cap.
	beam(o+Vector3(-ridge_half,high+.08,0),o+Vector3(ridge_half,high+.08,0),.22,"45675A")
	var bands:int=clampi(ceili(width/.85),4,40)
	for i in bands+1:
		var base_x:float=lerpf(-half_x,half_x,float(i)/bands)
		for sign in [-1,1]:
			var last:Vector3=o+Vector3(clampf(base_x,-ridge_half,ridge_half),high+.025,0)
			for step in range(1,segments+1):
				var u:float=float(step)/segments;var q:Vector3=o+Vector3(lerpf(clampf(base_x,-ridge_half,ridge_half),base_x,u),high*pow(1-u,1.50)+pow(u,6)*.36+.025,sign*half_z*u)
				beam(last,q,.045,"7D9B82");last=q
	for sx in [-1,1]:
		for sz in [-1,1]:
			var corner:Vector3=o+Vector3(sx*half_x,.36,sz*half_z)
			beam(o+Vector3(sx*ridge_half,high+.07,0),corner,.12,"77937C")
			beam(corner,corner+Vector3(sx*.30,.30,sz*.20),.16,"B9A06E")
			if int(d.get("grade",3))<=2:
				for ornament in 3:box(corner.lerp(o+Vector3(sx*ridge_half,high+.12,0),.10+ornament*.11)+Vector3.UP*.13,Vector3(.17,.20,.18),"B8A276")
	for sign in [-1,1]:
		var at:Vector3=o+Vector3(sign*ridge_half,high+.28,0)
		box(at,Vector3(.24,.48,.25),"AE9662");box(at+Vector3(-sign*.11,.18,0),Vector3(.35,.12,.22),"C4AD7B")
	b.venue_context=previous
	if not mark.is_empty():rotator.rotate_capture(mark,o,yaw)
func roof(id:String,o:Vector3,size:Vector2,height:float)->bool:
	var d:Dictionary=definition(id)
	if d.is_empty():return false
	var safe_height:float=maxf(height,float(d.floor_heights[-1])-o.y+3.55)
	var eave:float=.7 if int(d.grade)>=3 else 1.05
	var top:Vector3=o+Vector3.UP*safe_height
	var form:String=d.roof_form
	roof_piece(id,top,Vector2(size.x+eave*2,size.y+eave*2),float(d.rise),str(d.roof_color),form)
	if int(d.grade)==1:
		top+=Vector3.UP*1.8
		var previous:String=b.venue_context;b.venue_context="PALACE:"+id
		box(top+Vector3.UP*.20,Vector3(size.x*.64,.70,size.y*.63),str(d.wood))
		b.venue_context=previous
		roof_piece(id,top+Vector3.UP*.60,size*.72,float(d.rise)*.72,str(d.roof_color),"hip")
	var built:Dictionary=w.get_meta("palace140_roofs",{});built[id]={"origin":o,"height":safe_height,"eave_y":o.y+safe_height,"form":form,"grade":d.grade,"color":d.roof_color};w.set_meta("palace140_roofs",built)
	return true
func near_portal(p:Vector3)->bool:
	for record in w.get_meta("entrances110",[]):
		for key in ["inside","door","outer"]:
			var value=record.get(key)
			if value is Vector3 and Vector2(value.x-p.x,value.z-p.z).length()<1.55 and absf(value.y-p.y)<2.9:return true
	return false
func bracket(at:Vector3,turn:Basis,wood:String,gold:String,complexity:int):
	for tier in range(complexity):
		box(at+turn*Vector3(0,tier*.14,tier*.12),Vector3(.55+tier*.19,.12,.32+tier*.14),wood,turn)
		box(at+turn*Vector3(0,tier*.14+.08,tier*.14),Vector3(.20,.10,.58+tier*.18),gold,turn)
func lattice(at:Vector3,turn:Basis,size:Vector2,wood:String,variant:int):
	for sign in [-1,1]:
		box(at+turn*Vector3(sign*size.x*.5,0,0),Vector3(.11,size.y+.15,.14),wood,turn)
		box(at+turn*Vector3(0,sign*size.y*.5,0),Vector3(size.x+.15,.11,.14),wood,turn)
	for i in range(1,5):box(at+turn*Vector3((float(i)/5-.5)*size.x,0,.025),Vector3(.045,size.y,.07),wood,turn)
	for j in range(1,4):box(at+turn*Vector3(0,(float(j)/4-.5)*size.y,.03),Vector3(size.x,.045,.07),wood,turn)
	if variant%2==0:
		for sign in [-1,1]:
			var a:Vector3=at+turn*Vector3(-size.x*.23,-sign*size.y*.22,.08);var c:Vector3=at+turn*Vector3(size.x*.23,sign*size.y*.22,.08);beam(a,c,.045,wood)
func detail(place:Dictionary,d:Dictionary)->Dictionary:
	var id:String=place.id;var o:=Vector3(place.center[0],place.center[1],place.center[2]);var width:float=place.size[0];var depth:float=place.size[1]
	var levels:Array=d.floor_heights.duplicate();var high:float=float(levels[-1])-o.y+3.4
	var previous:String=b.venue_context;b.venue_context="PALACE:"+id
	var wood:String=d.wood;var gold:String=d.gold;var grade:int=int(d.grade);var window_count:=0;var bracket_count:=0
	var roof_data:Dictionary=w.get_meta("palace140_roofs",{})
	if not roof_data.has(id):roof(id,o,Vector2(width,depth),high)
	roof_data=w.get_meta("palace140_roofs",{});high=maxf(high,float(roof_data.get(id,{}).get("eave_y",o.y+high))-o.y)
	# Foundation cladding stays below every original occupied floor.
	for face in 4:
		var turn:=Basis(Vector3.UP,face*PI*.5);var base_span:float=width if face%2==0 else depth;var base_reach:float=depth*.5 if face%2==0 else width*.5
		var span:float=base_span;var reach:float=base_reach
		box(o+turn*Vector3(0,-.17,reach+.09),Vector3(span+.12,.24,.20),"CEC6B3",turn,"stone")
		box(o+turn*Vector3(0,-.34,reach+.10),Vector3(span+.26,.10,.25),"A9A894",turn,"stone")
		var columns:int=clampi(ceili(span/3.5),2,11)
		for level in levels.size():
			span=base_span-(level*(1.6 if face%2==0 else 1.4) if id=="CASTLE_MAIN" else 0.0);reach=base_reach-(level*(.7 if face%2==0 else .8) if id=="CASTLE_MAIN" else 0.0);columns=clampi(ceili(span/3.5),2,11)
			var floor_y:float=float(levels[level])-o.y
			var story:float=float(levels[level+1])-float(levels[level])-.20 if level<levels.size()-1 else maxf(3.25,high-floor_y-.16)
			if story<1.6:continue
			for index in columns+1:
				var x:float=-span*.5+float(index)*span/columns
				var foot:Vector3=o+turn*Vector3(x,floor_y,reach+.16)
				if near_portal(foot):continue
				box(foot+Vector3.UP*.16,Vector3(.55,.30,.55),"C9C1AD",turn,"stone")
				box(foot+Vector3.UP*(story*.5),Vector3(.25,story,.25),wood,turn)
				bracket(foot+Vector3.UP*(story-.28),turn,wood,gold,3 if grade<=2 else 2);bracket_count+=1
			for sign in [-1,1]:
				var x:float=sign*span*.28;var at:Vector3=o+turn*Vector3(x,floor_y+story*.53,reach+.28)
				if near_portal(at-Vector3.UP*story*.53):continue
				lattice(at,turn,Vector2(minf(2.0,span*.20),minf(1.65,story*.54)),wood,int(d.variant)+face);window_count+=1
			if story>5.8:
				for tier in range(1,ceili(story/3.0)):
					var y:float=floor_y+tier*2.8
					box(o+turn*Vector3(0,y,reach+.23),Vector3(span+.25,.18,.30),wood,turn)
					for x in [-span*.33,-span*.16,span*.16,span*.33]:
						lattice(o+turn*Vector3(x,y+1.15,reach+.29),turn,Vector2(minf(1.8,span*.13),1.55),wood,int(d.variant)+tier);window_count+=1
			var rail_y:float=floor_y+story-.13
			box(o+turn*Vector3(0,rail_y,reach+.20),Vector3(span+.28,.24,.28),wood,turn)
			box(o+turn*Vector3(0,rail_y-.08,reach+.36),Vector3(span,.045,.045),gold,turn)
			if grade<=2:
				for x in [-span*.33,0,span*.33]:
					box(o+turn*Vector3(x,rail_y+.015,reach+.36),Vector3(.6,.09,.04),"789083",turn)
	# A shallow portal canopy retains the original clear doorway and threshold.
	var entry:=Vector3(place.door[0],place.door[1],place.door[2]);var yaw:float=float(place.get("door_yaw",0));var turn:=Basis(Vector3.UP,yaw)
	if id not in ["CABLE_LOWER","CABLE_UPPER"]:
		roof_piece(id,entry+turn*Vector3(0,3.25,.60),Vector2(minf(width*.55,7.5),2.3),.85,str(d.roof_color),"hanging_gable",yaw if d.get("runtime_envelope",false) else 0.0)
		for sign in [-1,1]:
			box(entry+turn*Vector3(sign*1.85,2.2,.20),Vector3(.18,1.85,.20),wood,turn)
			box(entry+turn*Vector3(sign*1.85,3.0,.40),Vector3(.5,.18,.65),gold,turn)
	# Ceiling ornament is attached above activity space; never a new wall or floor.
	if grade<=2 and id not in ["LIGHTHOUSE","FOREST_OBSERVATORY"]:
		var ceiling:float=high-.55
		for layer in 3:
			var sx:float=minf(width*.42,7.0)-layer*.65;var sz:float=minf(depth*.40,6.0)-layer*.6
			for sign in [-1,1]:
				box(o+Vector3(sign*sx*.5,ceiling+layer*.12,0),Vector3(.10,.12,sz),gold)
				box(o+Vector3(0,ceiling+layer*.12,sign*sz*.5),Vector3(sx,.12,.10),wood)
	b.venue_context=previous
	return {"family":d.family,"grade":grade,"variant":d.variant,"roof":d.roof_form,"color":d.roof_color,"features":d.features,"component_types":["foundation","columns","lattice","beams","dougong","roof","ridge","portal"],"window_panels":window_count,"brackets":bracket_count,"occupied_floors":levels.size(),"eave_y":o.y+high,"ceiling_ornament_y":o.y+high-.55 if grade<=2 else -999,"colliders_added":0,"purpose_preserved":true}
func complete():
	ready_data();var result:Dictionary={};var compatibility:Dictionary={}
	for place in w.layout.creative_places:
		var d:Dictionary=definition(str(place.id))
		if d.is_empty():continue
		var actual:Dictionary=place.duplicate(true)
		if d.get("runtime_envelope",false):
			actual.center=d.envelope_center.duplicate();actual.size=d.envelope_size.duplicate()
			for portal in w.get_meta("entrances110",[]):
				if str(portal.get("id",""))!=str(place.id) or not portal.get("door") is Vector3:continue
				var point:Vector3=portal.door;actual.door=[point.x,point.y,point.z]
				if portal.get("inside") is Vector3:var direction:Vector3=point-portal.inside;actual.door_yaw=atan2(direction.x,direction.z)
				break
		result[str(place.id)]=detail(actual,d)
		compatibility[str(place.id)]={"family":d.family,"subtype":str(d.variant),"rank":"major" if int(d.grade)==1 else "medium" if int(d.grade)==2 else "small","roof":d.roof_form,"wall":"palace_plaster","window":"palace_lattice","structure":"layered_dougong","base":"protected_stone_plinth","garden":d.features,"collision_added":0}
	w.set_meta("palace140_architecture",result);w.set_meta("scenic130_architecture",compatibility)
