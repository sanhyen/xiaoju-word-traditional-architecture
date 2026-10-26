extends "res://scripts/palace_styles140.gd"
## Same original floors and uses; new sample-derived curved joinery and real openwork.
const Precision=preload("res://scripts/precision_craft160.gd")
func roof_piece(id:String,o:Vector3,size:Vector2,rise:float=2.0,tone:String="",form:String="hip",yaw:float=0.0):
	Precision.new(w,id).roof(o,size,clampf(rise,.55,minf(size.x,size.y)*.35+1),form,yaw)
func bracket(at:Vector3,turn:Basis,wood:String,gold:String,complexity:int):
	Precision.new(w,b.venue_context).asset("dougong",at,turn.scaled_local(Vector3(.55,.65,.55)))
func lattice(at:Vector3,turn:Basis,size:Vector2,wood:String,variant:int):
	Precision.new(w,b.venue_context).asset("lattice_"+str(posmod(variant,3)),at,turn.scaled_local(Vector3(size.x/2,size.y/1.7,1)))
func overhead_clear(at:Vector3,radius:float)->bool:
	# Stair runs remain open even when a decorative ceiling would have no collider.
	for route in w.get_meta("upper_routes110",[]):
		for point in route.get("points",[]):
			if point is Vector3 and Vector2(point.x-at.x,point.z-at.z).length()<radius+2.0 and absf(point.y-at.y)<2.6:return false
	return true
func detail(place:Dictionary,d:Dictionary)->Dictionary:
	var id:String=place.id;var o:=Vector3(place.center[0],place.center[1],place.center[2]);var width:float=place.size[0];var depth:float=place.size[1]
	var levels:Array=d.floor_heights.duplicate();var high:float=float(levels[-1])-o.y+3.4
	var previous:String=b.venue_context;b.venue_context="PALACE:"+id
	var grade:int=int(d.grade);var craft=Precision.new(w,id)
	if not w.get_meta("palace140_roofs",{}).has(id):roof(id,o,Vector2(width,depth),high)
	var roofs:Dictionary=w.get_meta("palace140_roofs",{});high=maxf(high,float(roofs.get(id,{}).get("eave_y",o.y+high))-o.y)
	var counts:Dictionary={"columns":0,"dougong":0,"openwork":0,"coffers":0,"carved_panels":0,"lamps":0}
	for face in 4:
		var turn:=Basis(Vector3.UP,face*PI*.5);var base_span:float=width if face%2==0 else depth;var base_reach:float=depth*.5 if face%2==0 else width*.5
		box(o+turn*Vector3(0,-.17,base_reach+.09),Vector3(base_span+.12,.24,.20),"CEC6B3",turn,"stone")
		for level in levels.size():
			var span:float=base_span-(level*(1.6 if face%2==0 else 1.4) if id=="CASTLE_MAIN" else 0.0)
			var reach:float=base_reach-(level*(.7 if face%2==0 else .8) if id=="CASTLE_MAIN" else 0.0)
			var floor_y:float=float(levels[level])-o.y
			var story:float=float(levels[level+1])-float(levels[level])-.20 if level<levels.size()-1 else maxf(3.25,high-floor_y-.16)
			if story<1.6:continue
			var columns:int=clampi(ceili(span/3.3),2,14)
			for index in columns+1:
				var x:float=-span*.5+float(index)*span/columns;var foot:Vector3=o+turn*Vector3(x,floor_y,reach+.16)
				if near_portal(foot):continue
				craft.column(foot,story,.19 if grade==1 else .15);counts.columns+=1
				craft.asset("dougong",foot+Vector3.UP*(story-.28),turn.scaled_local(Vector3(.58,.6,.58)));counts.dougong+=1
			for sign in [-1,1]:
				var at:Vector3=o+turn*Vector3(sign*span*.28,floor_y+story*.53,reach+.28)
				if near_portal(at-Vector3.UP*story*.53):continue
				craft.asset("lattice_"+str(posmod(int(d.variant)+face,3)),at,turn.scaled_local(Vector3(minf(2.1,span*.20)/2,minf(1.7,story*.54)/1.7,1)));counts.openwork+=1
			craft.painted_beam(o+turn*Vector3(0,floor_y+story-.12,reach+.20),span+.28,.32,turn)
			# A carved waist panel anchors every solid facade, below the windows, outside the occupied envelope.
			for sign in [-1,1]:
				var panel:Vector3=o+turn*Vector3(sign*span*.28,floor_y+.55,reach+.22)
				if near_portal(panel-Vector3.UP*.55):continue
				craft.asset("carved_panel",panel,turn.scaled_local(Vector3(minf(1.7,span*.18)/1.7,.35,.55)));counts.carved_panels+=1
			if story>5.8:
				for tier in range(1,ceili(story/3.0)):
					var y:float=floor_y+tier*2.8;craft.painted_beam(o+turn*Vector3(0,y,reach+.23),span,.22,turn)
					for x in [-span*.3,span*.3]:
						craft.asset("lattice_"+str(posmod(int(d.variant)+tier,3)),o+turn*Vector3(x,y+1,reach+.29),turn.scaled_local(Vector3(minf(1.8,span*.13)/2,.85,1)));counts.openwork+=1
	var entry:=Vector3(place.door[0],place.door[1],place.door[2]);var yaw:float=float(place.get("door_yaw",0));var turn:=Basis(Vector3.UP,yaw)
	if id not in ["CABLE_LOWER","CABLE_UPPER"]:
		roof_piece(id,entry+turn*Vector3(0,3.25,.60),Vector2(minf(width*.55,7.5),2.3),.85,str(d.roof_color),"hanging_gable",yaw if d.get("runtime_envelope",false) else 0.0)
		for sign in [-1,1]:
			craft.asset("dougong",entry+turn*Vector3(sign*1.85,2.96,.35),turn.scaled_local(Vector3(.45,.40,.45)))
			craft.asset("lantern",entry+turn*Vector3(sign*1.65,2.65,.65),turn.scaled_local(Vector3(.75,.75,.75)));counts.lamps+=1
			var lamp:=OmniLight3D.new();lamp.position=entry+turn*Vector3(sign*1.65,2.56,.85);lamp.light_color=Color("ffd096");lamp.light_energy=0;lamp.omni_range=7.0;lamp.omni_attenuation=1.4;lamp.distance_fade_enabled=true;lamp.distance_fade_begin=28;lamp.distance_fade_length=12;lamp.shadow_enabled=grade==1 and sign==1;lamp.set_meta("precision160_lantern",id);w.add_child(lamp);w.night_lights.append(lamp)
	# Coffered ceilings respect every occupied story; around stairs, individual panels are omitted.
	for level in levels.size():
		var floor_y:float=float(levels[level]);var top:float=float(levels[level+1])-.55 if level<levels.size()-1 else o.y+high-.22
		if top-floor_y<2.4:continue
		var sw:float=maxf(2,width-2.2);var sd:float=maxf(2,depth-2.2)
		if id=="CASTLE_MAIN":sw-=level*1.6;sd-=level*1.4
		var nx:int=clampi(int(sw/3.0),1,12);var nz:int=clampi(int(sd/3.0),1,12)
		for ix in nx:
			for iz in nz:
				var p:Vector3=Vector3(o.x+(float(ix)+.5-nx*.5)*sw/nx,top,o.z+(float(iz)+.5-nz*.5)*sd/nz)
				if not overhead_clear(p,1.6):continue
				if grade<=2 and level==levels.size()-1 and Vector2(p.x-o.x,p.z-o.z).length()<minf(3,sw*.25):continue
				craft.asset("coffer",p,Basis.IDENTITY.scaled(Vector3(sw/nx/2,.7,sd/nz/2)));counts.coffers+=1
		if grade<=2 and level==levels.size()-1 and id not in ["LIGHTHOUSE","FOREST_OBSERVATORY"] and overhead_clear(Vector3(o.x,top,o.z),3):
			var scale_value:float=minf(1,minf(sw,sd)/7)
			craft.asset("caisson",Vector3(o.x,top-.50,o.z),Basis.IDENTITY.scaled(Vector3(scale_value,.7,scale_value)))
	b.venue_context=previous
	var result:Dictionary={"family":d.family,"grade":grade,"variant":d.variant,"roof":d.roof_form,"color":d.roof_color,"features":d.features,"component_types":["curved_roof","half_round_tiles","circular_tile_ends","tapered_columns","carved_dougong","openwork_lattice","painted_beams","carved_panels","coffered_ceiling"],"window_panels":counts.openwork,"brackets":counts.dougong,"occupied_floors":levels.size(),"eave_y":o.y+high,"ceiling_ornament_y":o.y+high-.55,"colliders_added":0,"purpose_preserved":true,"precision_counts":counts,"use":d.palace_use}
	var all:Dictionary=w.get_meta("precision160_architecture",{});all[id]=result;w.set_meta("precision160_architecture",all)
	return result
