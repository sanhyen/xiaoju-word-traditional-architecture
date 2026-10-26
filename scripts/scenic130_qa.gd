extends "res://scripts/design120_qa.gd"
var poses:Array=[]
var qa_label:="check"
var requested:PackedStringArray=[]
var floor_measurements:Array=[]
var portal_measurements:Array=[]
func write_progress():
	if m==null:return
	var f:=FileAccess.open(m.evidence_root+"reports/scenic130_progress.json",FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify({"pid":OS.get_process_id(),"phase":phase,"checks":results.size(),"failed":results.filter(func(r):return not r.ok).size(),"position":m.player.position}));f.close()
func want(part:String)->bool:return requested.is_empty() or part in requested
func run(main):
	m=main
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--part="):requested=arg.trim_prefix("--part=").split(",")
		if arg.begins_with("--label="):qa_label=arg.trim_prefix("--label=")
	DirAccess.make_dir_recursive_absolute(m.evidence_root+"reports/scenic130_visual/final")
	await m.start_game(false);await m.get_tree().physics_frame
	if want("geometry"):
		scope_contracts();await geometry();style_contracts()
	if want("map"):await map_checks()
	if want("systems"):
		await mode_checks();await item_integration();await media_smoke();await migration_checks();await memory_migration()
	if want("visual"):await visual_evidence()
	if want("visual_patch"):
		m.set_time(0);await capture("P05_overview",Vector3(500,1040,1240),Vector3(-90,0,110),Vector3(0,5,80));await capture("P10_coast",Vector3(87,49,408),Vector3(0,-1,301),Vector3(0,1,290));scope_contracts()
	if want("landmark_far"):await landmark_evidence()
	if want("perf"):await scenic_performance()
	var failures:Array=results.filter(func(r):return not r.ok)
	var report:Dictionary={"version":ProjectSettings.get_setting("application/config/version"),"label":qa_label,"time":Time.get_datetime_string_from_system(),"parts":requested,"checks":results,"failures":failures,"floors":floor_measurements,"portals":portal_measurements,"poses":poses,"performance":sampled,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":m.get_viewport().get_visible_rect().size,"normal_saves":"isolated APPDATA and LOCALAPPDATA; original saves untouched","pck_sha256":FileAccess.get_sha256(OS.get_executable_path().get_base_dir()+"/XiaojuWorld.pck") if OS.has_feature("standalone") else "source_candidate","conditions":{"method":"process-frame wall-clock intervals; not GPU timing","render_scale":m.get_viewport().scaling_3d_scale}}
	var f:=FileAccess.open(m.evidence_root+"reports/scenic130_"+qa_label+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("SCENIC130_COMPLETE ",JSON.stringify({"checks":results.size(),"failures":failures.size()}));m.get_tree().quit(0 if failures.is_empty() else 1)
func landmark_evidence():
	var marks:Array=m.world.streamer.manifest.authored_counts.scenic130_landscape.landmarks
	for mark in marks:
		var p:Vector3=mark.position;var eye:Vector3=p+Vector3(110,85,280).normalized()*310;var target:Vector3=p+Vector3.UP*float(mark.height)*.5
		m.set_time(0);await capture("V09_far_"+str(mark.region),eye,target,p)
		record("V09_300m_"+str(mark.region),eye.distance_to(p)>=300 and bool(mark.far_geometry),{"distance_m":eye.distance_to(p),"position":p,"height":mark.height,"visual_review_required":true})
	m.set_time(0)
func geometry():
	phase="geometry";m.player.enabled=false;m.player.set_physics_process(false)
	var space:PhysicsDirectSpaceState3D=m.world.get_world_3d().direct_space_state
	for p in m.world.layout.creative_places:
		var door:=Vector3(p.door[0],p.door[1],p.door[2]);m.player.position=door+Vector3.UP*.2;m.world.streamer.set_foci([door])
		var loaded:bool=await m.world.prepare_region(door,24);await m.get_tree().physics_frame
		if not loaded:record("entrance_"+str(p.id),false,{"reason":"stream not ready"});continue
		var forward:Vector3=Basis(Vector3.UP,float(p.door_yaw))*Vector3.BACK;var heights:Array=[]
		for sign in [-1,1]:
			var point:Vector3=door+forward*.05*sign;var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.4,point-Vector3.UP*.8,1,[m.player.get_rid()]);var hit:Dictionary=space.intersect_ray(ray)
			if not hit.is_empty() and hit.normal.y>.7:heights.append(hit.position.y)
		var gap:float=absf(float(heights[0])-float(heights[1])) if heights.size()==2 else INF
		portal_measurements.append({"id":p.id,"heights":heights,"gap_m":gap});record("portal_seam_"+str(p.id),gap<=.031,{"gap_m":gap,"sample_offsets_m":[-.05,.05]})
		var capsule:=CapsuleShape3D.new();capsule.height=1.65;capsule.radius=.33;var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.exclude=[m.player.get_rid()];query.transform=Transform3D(Basis.IDENTITY,door+Vector3.UP*1.02)
		var overlap:Array[Dictionary]=space.intersect_shape(query,1);record("entrance_"+str(p.id),overlap.is_empty(),{"capsule_obstacles":overlap.size(),"door":door})
		for entry in p.get("floor_entries",[]):
			var point:=Vector3(entry.point[0],entry.point[1],entry.point[2]);var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.5,point-Vector3.UP*1.2,1,[m.player.get_rid()]);var hit:Dictionary=space.intersect_ray(ray)
			var valid:bool=not hit.is_empty() and hit.normal.y>.65 and absf(hit.position.y-point.y)<.26
			floor_measurements.append({"place":p.id,"level":entry.name,"point":point,"surface":hit.get("position",Vector3.INF),"ok":valid});record("floor_"+str(p.id)+"_"+str(entry.name),valid,{"point":point,"surface":hit.get("position",Vector3.INF)})
	record("all_83_portals_measured",portal_measurements.size()==83)
	record("all_130_floor_entries_measured",floor_measurements.size()==130)
	m.player.set_physics_process(true)
func style_contracts():
	var counts:Dictionary=m.world.streamer.manifest.authored_counts;var built:Dictionary=counts.get("scenic130_architecture",{});var styles=load("res://scripts/scenic_styles130.gd");styles.load_data();var data=load("res://scripts/scenic_biomes130.gd");data.ready_data()
	record("V01_13_built_families_and_83_assignments",built.size()==83 and styles.families.size()==13,{"buildings":built.size(),"families":styles.families.size()})
	var absent:Array=[];var subtypes:Dictionary={}
	for id in styles.assignments:
		if not built.has(id):absent.append(id);continue
		for key in ["roof","wall","window","structure","base","garden"]:
			if str(built[id].get(key,"")).is_empty():absent.append(id+":"+key)
		if built[id].family=="A7":subtypes[str(built[id].subtype)]=true
	record("six_architectural_dimensions_all_buildings",absent.is_empty(),{"missing":absent});record("V03_five_farm_subtypes",subtypes.size()==5,{"subtypes":subtypes.keys()})
	var adjacent:Array=[["Z01","Z02"],["Z01","AZURE"],["Z02","Z03"],["Z03","Z04"],["Z04","CASTLE"],["CASTLE","Z05"],["Z05","Z07"],["Z07","Z08"],["Z08","Z06"],["Z06","Z09"],["Z09","AZURE"],["AZURE","CAPE"],["ISLAND_01","ISLAND_02"]];var differences:Array=[]
	for pair in adjacent:
		var a:Dictionary={};var c:Dictionary={}
		for r in data.spec.regions:
			if str(r.id)==pair[0]:a=r
			if str(r.id)==pair[1]:c=r
		var n:=0
		for key in a.dimensions:
			if str(a.dimensions[key])!=str(c.dimensions[key]):n+=1
		differences.append({"a":pair[0],"c":pair[1],"different_dimensions":n});record("V02_adjacent_"+str(pair[0])+"_"+str(pair[1]),n>=6,{"different_dimensions":n,"note":"Specification check; corresponding real views are independently reviewed"})
	record("V05_twelve_ecologies",data.spec.biomes.size()==12)
	var roads:Dictionary=counts.get("scenic130_roads",{});record("V06_three_road_levels",int(roads.get("R1",0))>0 and int(roads.get("R2",0))>0 and int(roads.get("R3",0))>0,roads)
	var landscape:Dictionary=counts.get("scenic130_landscape",{});record("13_registered_landmarks",landscape.get("landmarks",[]).size()==13);record("4_distant_islands",int(landscape.get("distant_islands",0))==4)
	var purposes:Array=[]
	for id in built:
		if str(id).begins_with("H") and str(id).trim_prefix("H").is_valid_int():purposes.append(id)
	record("V04_14_external_purpose_markers",purposes.size()==14,{"ids":purposes})
func map_checks():
	phase="map";await move_to(Vector3(0,4.5,110));m.show_map();await m.get_tree().process_frame
	var map=m.modal.find_child("VisitorMap106",true,false);record("map_uses_zoom_layers",map!=null and map.has_method("zoom_level"))
	if map==null:m.close_modal();return
	for extent in [950,600,260,115]:
		if extent==950:map.reset_view()
		else:map.view_rect=Rect2(Vector2(-100,140)-Vector2(extent,extent*.7)*.5,Vector2(extent,extent*.7))
		map.queue_redraw();await m.get_tree().process_frame;await RenderingServer.frame_post_draw
		var collision:=false
		for i in map.labels.size():
			for j in range(i+1,map.labels.size()):
				if map.labels[i].intersects(map.labels[j]):collision=true
		record("map_labels_no_overlap_"+str(extent),not collision,{"labels":map.labels.size(),"hits":map.hits.size(),"level":map.zoom_level()})
		if extent==950:record("map_whole_world_shows_15_regions",map.labels.size()==15,{"labels":map.labels.size()})
	record("278_entries_preserved_by_new_map",map.places().size()==278)
	m.close_modal()
	var mini=m.hud.find_child("MiniMapSurface",true,false)
	if mini!=null:
		mini.rotate_with_camera=true;mini.show_edge_arrows=true;mini.queue_redraw();await m.get_tree().process_frame;record("minimap_rotation_and_arrows",mini.rotate_with_camera and mini.edge_arrow_count>=3,{"arrows":mini.edge_arrow_count});mini.rotate_with_camera=false
	else:record("minimap_rotation_and_arrows",false)
func memory_migration():
	phase="scenic_save";var original:Dictionary=m.state.duplicate(true);m.scenic.defaults();m.state.map_favorites=["B03","CASTLE_TEA"];m.state.map_recent=[]
	for id in ["B01","B02","B03","B12","CABLE_UPPER","FOREST_LODGE"]:m.scenic.visit(id)
	record("recent_locations_keep_last_five",m.state.map_recent.size()==5 and m.state.map_recent[0]=="FOREST_LODGE")
	record("map_memory_writes",m.save_game(false));var loaded:Dictionary=m.store.read();record("map_favorites_cold_decode",loaded.get("map_favorites",[])==["B03","CASTLE_TEA"] and loaded.get("map_recent",[]).size()==5)
	m.state=original
func capture(id:String,eye:Vector3,target:Vector3,anchor:Vector3=Vector3.INF):
	phase="visual_"+id
	if not anchor.is_finite():anchor=target
	m.player.enabled=false;m.player.set_physics_process(false);m.player.position=anchor;m.world.streamer.set_foci([anchor])
	if not await m.world.prepare_region(anchor,24):record("capture_"+id,false);return
	m.watch_camera.position=eye;m.watch_camera.look_at(target);m.watch_camera.fov=67;m.watch_camera.current=true;m.player.figure.hide();m.ui.hide()
	for i in 14:await m.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var file:String=m.evidence_root+"reports/scenic130_visual/final/"+id+".png";m.get_viewport().get_texture().get_image().save_png(file)
	poses.append({"id":id,"file":file,"eye":[eye.x,eye.y,eye.z],"target":[target.x,target.y,target.z],"anchor":[anchor.x,anchor.y,anchor.z],"resolution":m.get_viewport().get_visible_rect().size,"version":ProjectSettings.get_setting("application/config/version"),"time":Time.get_datetime_string_from_system()});print("SCENIC130_SHOT ",id)
func ui_capture(id:String):
	await m.get_tree().process_frame;await RenderingServer.frame_post_draw
	var file:String=m.evidence_root+"reports/scenic130_visual/final/"+id+".png";m.get_viewport().get_texture().get_image().save_png(file);poses.append({"id":id,"file":file,"version":ProjectSettings.get_setting("application/config/version"),"time":Time.get_datetime_string_from_system(),"resolution":m.get_viewport().get_visible_rect().size})
func visual_evidence():
	m.set_time(0);m.environment_controls.weather=0
	for row in [["P01_plaza_north",Vector3(12,12,133),Vector3(-15,42,-250),Vector3(0,5,80)],["P02_street",Vector3(-73,17,242),Vector3(-103,8,182),Vector3(-100,4,197)],["P03_living",Vector3(-274,50,-201),Vector3(-237,28,-245),Vector3(-240,26,-242)],["P04_east",Vector3(105,76,154),Vector3(230,20,-12),Vector3(180,20,20)],["P05_overview",Vector3(500,1040,1240),Vector3(-90,0,110),Vector3(0,5,80)]]:await capture(row[0],row[1],row[2],row[3])
	var representatives:Dictionary={"A1":"B01","A2":"AZURE_VIEW","A3":"B03","A4":"B13","A5":"B10","A6":"B05","A7":"H01","A8":"CABLE_UPPER","A9":"Z09_B2","A10":"CASTLE_MAIN","A11":"VILLA_0","A12":"TREEHOUSE_3","A13":"LIGHTHOUSE","A7b":"H07","A7c":"H03","A7d":"H09","A7e":"H12"}
	for family in representatives:
		for p in m.world.layout.creative_places:
			if str(p.id)!=str(representatives[family]):continue
			var o:=Vector3(p.center[0],p.center[1],p.center[2]);var turn:=Basis(Vector3.UP,float(p.door_yaw));var extent:float=maxf(p.size[0],p.size[1]);var high:float=maxf(6,float(p.floors[-1])-o.y+6);var offset:=Vector3(extent*.85,high*.8+extent*.4,extent*1.2)
			if family=="A10":offset=Vector3(63,54,74)
			await capture("P06_"+str(family)+"_"+str(p.id),o+turn*offset,o+Vector3.UP*high*.42,o)
	for region in load("res://scripts/scenic_biomes130.gd").spec.regions:
		if str(region.id) in ["Z04","CAPE","CREEK"]:continue
		var o:Vector3=m.world.surface(float(region.x),float(region.z));await capture("P08_"+str(region.biome)+"_"+str(region.id),o+Vector3(43,35,57),o+Vector3.UP*3,o)
	var summit:Vector3=m.world.surface(-160,-410);await capture("P08_E8_summit",summit+Vector3(40,28,47),summit,summit)
	await capture("P09_transition_farm_forest",Vector3(-303,56,-196),Vector3(-235,35,-300),Vector3(-240,26,-242))
	await capture("P09_transition_cliff_coast",Vector3(377,48,305),Vector3(322,8,267),Vector3(347,4,289))
	await capture("P10_coast",Vector3(87,49,408),Vector3(0,-1,301),Vector3(0,1,290))
	for time_index in [1,2]:
		m.set_time(time_index)
		await capture("P11_"+str(time_index)+"_castle",Vector3(-45,58,115),Vector3(-112,26,15),Vector3(-112,9,25))
		await capture("P11_"+str(time_index)+"_forest",Vector3(-1,38,554),Vector3(-60,12,490),Vector3(-60,6,490))
	m.set_time(0);m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
	await move_to(Vector3(0,4.5,110));m.show_map();await m.get_tree().process_frame;var map=m.modal.find_child("VisitorMap106",true,false)
	for extent in [950,600,260]:
		if extent==950:map.reset_view()
		else:map.view_rect=Rect2(Vector2(-80,110)-Vector2(extent,extent*.75)*.5,Vector2(extent,extent*.75))
		map.queue_redraw();await ui_capture("P12_map_"+str(extent))
	for p in m.world.layout.creative_places:
		if str(p.id)=="CASTLE_MAIN":
			var point:Array=p.floor_entries[2].point;await move_to(Vector3(point[0],point[1],point[2]));break
	var floor=m.modal.find_child("FloorPlan120",true,false);floor.open({"id":"CASTLE_MAIN_FLOOR_2","parent":"CASTLE_MAIN"});await ui_capture("P12_floor_plan");m.close_modal();await ui_capture("P12_minimap")
	# Hide nearby vegetation and the far proxy together, leaving authoritative terrain and road paint.
	await capture("P13_with_vegetation",Vector3(-145,39,250),Vector3(-114,4,197),Vector3(-100,4,197))
	var hidden:Array=[]
	for node in m.world.find_children("*","GeometryInstance3D",true,false):
		if node.get_meta("scenic_foliage",false) and node.visible:hidden.append(node);node.hide()
	m.world.streamer.far_root.hide();await capture("P13_ground_without_vegetation",Vector3(-145,39,250),Vector3(-114,4,197),Vector3(-100,4,197));m.world.streamer.far_root.show()
	for node in hidden:node.show()
	m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
func scenic_performance():
	for region in [{"id":"E6_field","point":Vector3(-242,26,-226)},{"id":"E12_forest","point":Vector3(-60,6,490)}]:
		await move_to(region.point);m.player.enabled=true;m.player.camera.current=true;m.watch_camera.current=false;m.ui.show();phase="perf_"+str(region.id)
		for i in 90:await m.get_tree().process_frame
		measuring=true;measured_last_usec=0
		var until:int=Time.get_ticks_msec()+12000
		while Time.get_ticks_msec()<until:await m.get_tree().process_frame
		measuring=false;var values:Array=sampled.get(phase,[]);var total:float=0
		for value in values:total+=float(value)
		values.sort();var fps:float=1000*values.size()/maxf(total,.01);record(phase,fps>=45,{"frames":values.size(),"average_fps":fps,"p95_ms":values[int(values.size()*.95)] if not values.is_empty() else INF,"duration_ms":total})
	m.environment_controls.enter();m.environment_controls.switch_mode();m.environment_controls.fit_world_view();phase="perf_whole_overview"
	for i in 100:await m.get_tree().process_frame
	measuring=true;measured_last_usec=0
	var until:int=Time.get_ticks_msec()+12000
	while Time.get_ticks_msec()<until:await m.get_tree().process_frame
	measuring=false;var values:Array=sampled.get(phase,[]);var total:float=0
	for value in values:total+=float(value)
	values.sort();var fps:float=1000*values.size()/maxf(total,.01);var p95:float=values[int(values.size()*.95)] if not values.is_empty() else INF;record(phase,fps>=40 and p95<=35,{"frames":values.size(),"average_fps":fps,"p95_ms":p95,"duration_ms":total});m.environment_controls.leave()
