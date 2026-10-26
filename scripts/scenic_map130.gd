extends "res://scripts/bay_map_view.gd"
## Zoom controls visibility, not the underlying 278-entry catalog.
var rotate_with_camera:=false
var show_edge_arrows:=true
var interaction_points:Array=[]
var basemap:Texture2D
var edge_arrow_count:=0
const BIOMES=preload("res://scripts/scenic_biomes130.gd")
const STYLE=preload("res://scripts/scenic_styles130.gd")
func point(x:float,z:float)->Vector2:
	if mini:
		var delta:=Vector2(x-player_pos.x,z-player_pos.z)*(size.x/320.0)
		return size*.5+delta.rotated(-yaw if rotate_with_camera else 0)
	return super.point(x,z)
func zoom_level()->int:
	if mini:return 1
	return 0 if view_rect.size.x>740 else 1 if view_rect.size.x>360 else 2 if view_rect.size.x>160 else 3
func region_for(place:Dictionary)->String:
	return str(BIOMES.nearest_region(Vector2(float(place.x),float(place.z))).id)
func draw_base():
	if basemap==null and ResourceLoader.exists("res://assets/maps/scenic130_atlas.png"):basemap=load("res://assets/maps/scenic130_atlas.png")
	if basemap!=null:
		if mini:
			draw_set_transform(size*.5,-yaw if rotate_with_camera else 0)
			var offset:Vector2=(preload("res://scripts/landscape_space150.gd").MAP.position-Vector2(player_pos.x,player_pos.z))*scale_m();draw_texture_rect(basemap,Rect2(offset,preload("res://scripts/landscape_space150.gd").MAP.size*scale_m()),false)
			draw_set_transform(Vector2.ZERO)
		else:draw_texture_rect(basemap,Rect2(point(-672,-752),preload("res://scripts/landscape_space150.gd").MAP.size*scale_m()),false)
	else:
		for region in BIOMES.spec.regions:
			ellipse([region.x,region.z],[region.rx,region.rz],Color(BIOMES.spec.biomes[region.biome].ground).lightened(.22))
	var cfg:Dictionary=spec.bay_layout
	for road in cfg.roads:
		if zoom_level()==0 and float(road.width)<4.2:continue
		if zoom_level()==1 and float(road.width)<2.4:continue
		for i in road.points.size()-1:
			var a:Vector2=point(road.points[i][0],road.points[i][2]);var c:Vector2=point(road.points[i+1][0],road.points[i+1][2]);var width:float=(3.1 if road.width>=4.2 else 2.0 if road.width>=2.4 else 1.1) if not mini else 1.3
			stroke(a,c,Color("A69E88"),width+1);stroke(a,c,Color("ECE4D0"),width)
	for route in cfg.sea_walk.routes:
		for i in route.points.size()-1:stroke(point(route.points[i][0],route.points[i][2]),point(route.points[i+1][0],route.points[i+1][2]),Color("B9A275"),2)
func category(place:Dictionary)->String:
	var id:String=str(place.id);var role:String=str(place.get("role",""));var kind:String=str(place.get("kind",""))
	if id.begins_with("CABLE_") or id=="B01":return "station"
	if "DOCK" in id or "BOAT" in id or kind in ["boat","dock"]:return "dock"
	if id in ["B02","CASTLE_TEA","CREEK_TEA","SUMMIT_TEA","H04","H14"]:return "cafe"
	if id in ["B03","B04","B11"] or kind=="workshop":return "shop"
	if role in ["home","villa","treehouse","forest","lobby"] or id.begins_with("H"):return "house"
	if id=="LIGHTHOUSE" or kind in ["view","hidden_view","zone","island"]:return "landmark"
	if kind=="upper":return "stairs"
	if kind=="facility":return "facility"
	return "venue"
func icon(p:Vector2,kind:String,radius:float=5,tone:Color=Color("526C63")):
	draw_circle(p,radius+2,Color("F8F0DC"))
	match kind:
		"house","shop":
			draw_polyline(PackedVector2Array([p+Vector2(-radius,0),p+Vector2(0,-radius),p+Vector2(radius,0)]),tone,1.5,true);draw_rect(Rect2(p+Vector2(-radius*.65,0),Vector2(radius*1.3,radius*.8)),tone,false,1.3)
		"station":
			draw_rect(Rect2(p-Vector2(radius,radius*.7),Vector2(radius*2,radius*1.4)),tone,false,1.5);draw_line(p+Vector2(-radius*.5,radius),p+Vector2(radius*.5,radius),tone,1.5)
		"dock":
			draw_line(p-Vector2(0,radius),p+Vector2(0,radius),tone,1.5);draw_arc(p+Vector2(0,-radius*.1),radius*.9,0,PI,10,tone,1.4,true);draw_line(p+Vector2(-radius*.55,-radius*.4),p+Vector2(radius*.55,-radius*.4),tone,1.4)
		"cafe":
			draw_rect(Rect2(p-Vector2(radius*.8,radius*.5),Vector2(radius*1.4,radius)),tone,false,1.3);draw_arc(p+Vector2(radius*.7,-radius*.05),radius*.4,-PI*.5,PI*.5,8,tone,1.2)
		"landmark":draw_polyline(PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius*.35,0),p+Vector2(radius,radius*.4),p+Vector2(0,radius),p+Vector2(-radius,radius*.4),p+Vector2(-radius*.35,0),p+Vector2(0,-radius)]),tone,1.3,true)
		"stairs":
			draw_polyline(PackedVector2Array([p+Vector2(-radius,radius),p+Vector2(-radius,0),p,p+Vector2(0,-radius),p+Vector2(radius,-radius)]),tone,1.5,true)
		"facility":draw_circle(p,2,tone)
		_:draw_circle(p,radius*.85,tone,false,1.5,true);draw_line(p+Vector2(-radius,0),p+Vector2(radius,0),tone,1)
func region_labels():
	for region in BIOMES.spec.regions:
		var anchor:Vector2=point(region.x,region.z)
		if not inside(anchor,12):continue
		var words:String=str(region.name);var extent:Vector2=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,14)+Vector2(10,6);var chosen:=Rect2()
		for radius in [11,25,41,65,86]:
			for offset in [Vector2(-extent.x*.5,-radius-extent.y),Vector2(radius,3),Vector2(-extent.x-radius,3),Vector2(-extent.x*.5,radius)]:
				var rect:=Rect2(anchor+offset,extent)
				if available_label(rect):chosen=rect;break
			if chosen.has_area():break
		if not chosen.has_area():continue
		labels.append(chosen);draw_line(anchor,chosen.get_center(),Color(.30,.40,.34,.45),1,true);draw_style_box(label_style(),chosen);label_at(chosen.position+Vector2(5,17),words,Color("345349"),14)
		var item:Dictionary={"id":region.id,"name":words,"kind":"zone","x":region.x,"z":region.z}
		if spec.bay_layout.zones.has(str(region.id)):item.safe=spec.bay_layout.zones[str(region.id)].safe
		else:
			var representative:String={"AZURE":"AZURE_VIEW","CASTLE":"CASTLE_MAIN","CAPE":"LIGHTHOUSE","CREEK":"CREEK_TEA","ISLAND_01":"ISLAND","ISLAND_02":"ISLAND_02"}.get(str(region.id),"")
			for place in places():
				if str(place.id)==representative and place.has("safe"):item.safe=place.safe;break
		hits.append({"place":item,"point":anchor,"label":chosen})
func arrows(entries:Array):
	edge_arrow_count=0
	if not show_edge_arrows:return
	var candidates:Array=[]
	for p in entries:
		if str(p.id) not in STYLE.assignments:continue
		var anchor:Vector2=point(p.x,p.z)
		if Rect2(Vector2(14,14),size-Vector2(28,28)).has_point(anchor):continue
		candidates.append(p)
	candidates.sort_custom(func(a,c):return Vector2(a.x-player_pos.x,a.z-player_pos.z).length_squared()<Vector2(c.x-player_pos.x,c.z-player_pos.z).length_squared())
	var occupied:Array=[]
	for p in candidates:
		var direction:Vector2=(point(p.x,p.z)-size*.5).normalized();var distance:float=minf((size.x*.5-17)/maxf(absf(direction.x),.001),(size.y*.5-17)/maxf(absf(direction.y),.001));var at:Vector2=size*.5+direction*distance
		var collision:bool=false
		for other in occupied:
			if at.distance_to(other)<20:collision=true;break
		if collision:continue
		occupied.append(at);draw_colored_polygon(PackedVector2Array([at+direction*7,at+direction.rotated(2.5)*6,at+direction.rotated(-2.5)*6]),Color("AE7957"));hits.append({"place":p,"point":at});edge_arrow_count+=1
		if edge_arrow_count>=4:break
func _draw():
	if spec.is_empty() or font==null:return
	BIOMES.ready_data();STYLE.load_data();labels.clear();hits.clear();clusters.clear();edge_arrow_count=0
	draw_rect(Rect2(Vector2.ZERO,size),Color("AACBCD"));draw_base();draw_target_route()
	var level:int=zoom_level();var entries:Array=places()
	if not mini:region_labels()
	for destination in entries:
		if not str(destination.id).begins_with("VIEW150_"):continue
		var anchor:Vector2=point(destination.x,destination.z)
		if not inside(anchor,10):continue
		icon(anchor,"landmark",5,Color("9F805B"));var hit:Dictionary={"place":destination,"point":anchor}
		if not mini:
			var rect:Rect2=try_label(anchor,short_name(destination),true)
			if rect.has_area():hit.label=rect
		hits.append(hit)
	if level==0:
		for id in ["B01","B02","B03","B13","B10","B05","B12","CABLE_UPPER","Z09_B5","AZURE_VIEW","CASTLE_MAIN","LIGHTHOUSE","FOREST_OBSERVATORY"]:
			for p in entries:
				if str(p.id)!=id:continue
				var at:Vector2=point(p.x,p.z)
				if inside(at,8):icon(at,"landmark",5,Color("9F805B"));hits.append({"place":p,"point":at})
	else:
		var names:Array=[]
		for p in entries:
			var kind:String=p.get("kind","");var id:String=p.id
			if id.begins_with("VIEW150_"):continue
			if kind in ["reserved","zone","island"]:continue
			if level==1 and id not in STYLE.assignments:continue
			if level==2 and kind=="upper":continue
			var at:Vector2=point(p.x,p.z)
			if not inside(at,8):continue
			icon(at,category(p),4 if mini else 5);hits.append({"place":p,"point":at})
			if level>=2 and kind!="upper":names.append(p)
		if not mini:
			names.sort_custom(func(a,c):return name_priority(a)>name_priority(c))
			for p in names:
				var at:Vector2=point(p.x,p.z);var rect:Rect2=try_label(at,short_name(p),false)
				if rect.has_area():
					for hit in hits:
						if str(hit.place.id)==str(p.id):hit.label=rect;break
		if level==3 and not mini:
			for interaction in interaction_points:
				var at:Vector2=point(interaction.pos.x,interaction.pos.z)
				if not inside(at,8):continue
				icon(at,"facility",2,Color("9B997E"));hits.append({"point":at,"place":{"id":interaction.id,"name":interaction.title,"kind":"facility","enabled":false,"x":interaction.pos.x,"z":interaction.pos.z,"subtitle":"设施位置 · 可标记后步行抵达"}})
	var p:Vector2=point(player_pos.x,player_pos.z);var direction:Vector2=Vector2(0,-1) if mini and rotate_with_camera else Vector2(-sin(yaw),-cos(yaw))
	if inside(p,8):draw_colored_polygon(PackedVector2Array([p+direction*10,p+direction.rotated(2.5)*8,p+direction.rotated(-2.5)*8]),Color("BD8059"));draw_arc(p,12,0,TAU,20,Color("F7F1D6"),2,true)
	if mini:arrows(entries)
	else:label_at(Vector2(12,21),["全图 · 区域与地标","中景 · 建筑图标","近景 · 名称与室外地点","详图 · 设施与楼层入口"][level],Color("34554A"),15)
	label_at(Vector2(size.x-37,21),"N ↑" if not mini or not rotate_with_camera else "N",Color("34554A"),13)
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("84A68F"),false,2)
func _get_tooltip(at:Vector2)->String:
	var selected:Dictionary={};var distance:float=13
	for hit in hits:
		var d:float=0.0 if hit.get("label",Rect2()).has_point(at) else at.distance_to(hit.point)
		if d<distance:distance=d;selected=hit.place
	return str(selected.get("name",""))
