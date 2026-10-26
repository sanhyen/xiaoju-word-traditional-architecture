extends "res://scripts/palace140_qa.gd"
func run(main):
	m=main
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--part="):requested=arg.trim_prefix("--part=").split(",")
		if arg.begins_with("--label="):qa_label=arg.trim_prefix("--label=")
	await m.start_game(false);await m.get_tree().physics_frame
	if want("geometry"):scope_contracts();await geometry();palace_contracts();await landscape_contracts()
	if want("contracts"):await landscape_contracts()
	if want("scope"):scope_contracts()
	if want("geometry_patch"):
		for p in m.world.layout.creative_places:
			if str(p.id) in ["SUMMIT_TEA","B05","B07","B05_UPPER","B07_UPPER","THEME_POEM","B10","B10_UPPER","THEME_FROST","Z09_B2","LIGHTHOUSE"]:await entrance(p);await floors_probe(p)
	if want("routes") or want("routes_select"):await landscape_routes()
	if want("map"):await landscape_map()
	if want("navigation"):await landscape_navigation()
	if want("systems"):await mode_checks();await item_integration();await media_smoke();await memory_migration()
	if want("migration"):await real_save_migration();await expanded_save()
	if want("visual"):await landscape_visuals()
	if want("visual_repair"):await ground_visuals()
	if want("visual_last"):
		m.set_time(0)
		await ground_capture("castle_axis_ground",Vector2(-113,95),Vector3(-112.5,30,10))
		var arch:Dictionary=m.world.layout.config.landscape150.main_arch;var center:Vector3=(m.world.layout.vector(arch.a)+m.world.layout.vector(arch.c))*.5
		await ground_capture("azure_arch_valid_ground",Vector2(585,-21),center-Vector3.UP*7)
	if want("save_patch"):await expanded_works_restore()
	if want("perf"):await landscape_performance()
	if want("perf_final"):await route_performance_final()
	if want("water_patch"):await water_patch()
	if want("arch_final"):
		m.set_time(0);var arch:Dictionary=m.world.layout.config.landscape150.main_arch;var center:Vector3=(m.world.layout.vector(arch.a)+m.world.layout.vector(arch.c))*.5
		await ground_capture("azure_arch_aligned_ground",Vector2(585,1),center-Vector3.UP*4)
	var failures:Array=results.filter(func(r):return not r.ok)
	var report:Dictionary={"version":ProjectSettings.get_setting("application/config/version"),"label":qa_label,"parts":requested,"checks":results,"failures":failures,"floors":floor_measurements,"portals":portal_measurements,"poses":poses,"performance":sampled,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":m.get_viewport().get_visible_rect().size,"render_scale":m.get_viewport().scaling_3d_scale,"normal_saves":"isolated APPDATA and LOCALAPPDATA","pck_sha256":FileAccess.get_sha256(OS.get_executable_path().get_base_dir()+"/XiaojuWorld.pck") if OS.has_feature("standalone") else "source_candidate"}
	var f:=FileAccess.open(m.evidence_root+"reports/landscape150_"+qa_label+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("LANDSCAPE150_COMPLETE ",JSON.stringify({"checks":results.size(),"failures":failures.size()}));m.get_tree().quit(0 if failures.is_empty() else 1)
func landscape_contracts():
	phase="landscape_contracts";var built:Dictionary=m.world.streamer.manifest.authored_counts.get("landscape150",{})
	record("15_regions_5_belts_authored",built.get("regions",[]).size()==15 and built.get("belts",[]).size()==5,built)
	record("floating_corner_5_pavilions_3_rings_2_cranes",built.get("floating_pavilions",0)==5 and built.get("rings",0)==3 and built.get("sculptures",0)==2)
	record("new_ravine_main_arch",float(built.get("main_arch_span_m",0))>40)
	record("landscape_foliage_and_rest_courts",int(built.get("trees",0))>600 and int(built.get("courts",0))>=10)
	var json:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/world_layout_bay_v1.json"));var missing:Array=[]
	for family in ["cloud_loop","cherry_loop","warm_coast","azure_cliff","cape_connection","west_connect","cloud_balcony","sky_approach","sky_footbridge","tide_access"]:
		if not json.roads.any(func(r):return str(r.id).begins_with("landscape150_"+family)):missing.append(family)
	record("outer_bounds_and_new_routes",equivalent(json.bounds,[-640.0,640.0,-720.0,720.0]) and missing.is_empty(),{"bounds":json.bounds,"route_segments":json.landscape150.route_segments,"missing_route_families":missing})

func landscape_navigation():
	phase="new_map_walking_navigation"
	var nav=load("res://scripts/creative_navigation110.gd").new();nav.ensure_layout(m.world.layout,m.world)
	var origin:=Vector3(0,m.world.height_at(0,80)+.08,80)
	for target in m.world.layout.config.landscape150.destinations:
		var route:Dictionary=nav.route_from(origin,target)
		record("walk_from_plaza_"+str(target.id),route.connected,{"reason":route.reason,"goal":route.goal,"length":route.get("length",0),"origin":origin,"points":route.points})
		if route.connected:
			var reverse:Dictionary=nav.route_from(route.goal,{"id":"return_plaza","safe":[origin.x,origin.y-m.world.layout.config.sea_y,origin.z]})
			record("walk_return_"+str(target.id),reverse.connected,{"reason":reverse.reason})
func landscape_routes():
	phase="new_route_collision";m.player.enabled=false;m.player.set_physics_process(false)
	var space:PhysicsDirectSpaceState3D=m.world.get_world_3d().direct_space_state
	var capsule:=CapsuleShape3D.new();capsule.height=1.65;capsule.radius=.33
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.exclude=[m.player.get_rid()]
	var total:=0;var failures:Array=[];var maximum_grade:=0.0
	var only:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/landscape150_route_retry.json")) if "routes_select" in requested else []
	for r in m.world.layout.segments:
		if not str(r.id).begins_with("landscape150_"):continue
		if not only.is_empty() and str(r.id) not in only:continue
		var center:Vector3=(r.a+r.c)*.5;m.player.position=center;m.world.streamer.set_foci([center])
		if not await m.world.prepare_region(center,24):failures.append({"id":r.id,"error":"stream"});continue
		var horizontal:float=Vector2(r.a.x-r.c.x,r.a.z-r.c.z).length();maximum_grade=maxf(maximum_grade,absf(r.a.y-r.c.y)/maxf(.01,horizontal))
		var n:int=maxi(2,ceili(horizontal/1.5));var last:=Vector3.INF
		for j in n+1:
			var p:Vector3=r.a.lerp(r.c,float(j)/n)
			if not r.bridge:p.y=m.world.height_at(p.x,p.z)+.04
			var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.65,p-Vector3.UP*.85,1,[m.player.get_rid()]));total+=1
			if hit.is_empty() or hit.normal.y<.70:failures.append({"id":r.id,"point":p,"error":"support"});continue
			p.y=hit.position.y;query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*.93)
			var blocks:Array=space.intersect_shape(query,1)
			if not blocks.is_empty():
				var collider=blocks[0].collider;var box=AABB()
				for node in collider.get_children():
					if node is CollisionShape3D and node.shape is BoxShape3D:box=AABB(node.global_position-node.shape.size*.5,node.shape.size)
				failures.append({"id":r.id,"point":p,"error":"clearance","collider":str(collider.get_path()),"box":box})
			if last.is_finite() and absf(p.y-last.y)>p.distance_to(last)*.72+.15:failures.append({"id":r.id,"point":p,"error":"step"})
			last=p
	record("new_roads_support_clearance_and_steps",failures.is_empty(),{"sample_count":total,"failures":failures,"maximum_authored_grade":maximum_grade})
	var low:Vector3=m.world.layout.vector(m.world.layout.config.landscape150.lower_pavilion);m.player.position=low;m.world.streamer.set_foci([low]);await m.world.prepare_region(low,24)
	var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(low+Vector3.UP*.5,low-Vector3.UP*.8,1,[m.player.get_rid()]));record("low_floating_pavilion_physical_floor",not hit.is_empty() and absf(hit.position.y-low.y)<.15,{"position":low,"hit":hit.get("position")})
	m.player.set_physics_process(true)
func landscape_map():
	phase="expanded_map";m.show_map();await m.get_tree().process_frame
	var map=m.modal.find_child("VisitorMap106",true,false)
	if map==null:
		for node in m.modal.find_children("*","Control",true,false):
			if node.get_script()==load("res://scripts/bay_map_view.gd"):map=node;break
	if map==null:record("expanded_map_control",false);m.close_modal();return
	var places:Array=map.places();var ids:Array=[]
	for p in places:ids.append(str(p.id))
	for p in m.world.layout.config.landscape150.destinations:record("map_"+str(p.id),str(p.id) in ids)
	record("expanded_map_extents",map.view_rect.end.x>=640 and map.view_rect.position.y<=-720 and map.view_rect.end.y>=720,{"rect":map.view_rect})
	await m.get_tree().process_frame;await RenderingServer.frame_post_draw
	var folder:String=m.evidence_root+"reports/landscape150_visual/"+qa_label;DirAccess.make_dir_recursive_absolute(folder);m.get_viewport().get_texture().get_image().save_png(folder+"/expanded_map.png");m.close_modal()
func expanded_save():
	phase="expanded_save_restore";m.store.configure_palace()
	var p:=Vector3(50,m.world.height_at(50,-600)+.1,-600);await move_to(p)
	record("expanded_point_save",m.save_game(false))
	var read:Dictionary=m.store.read();record("expanded_point_decodes",not read.is_empty() and m.world.layout.within_bounds(Vector3(read.safe_point[0],read.safe_point[1],read.safe_point[2])))
	await m.start_game(true);record("expanded_point_restores_nearby",Vector2(m.player.position.x-p.x,m.player.position.z-p.z).length()<5,{"expected":p,"actual":m.player.position})
func capture150(id:String,eye:Vector3,target:Vector3,anchor:Vector3):
	await capture(id,eye,target,anchor)
func ground_capture(id:String,xz:Vector2,target:Vector3):
	var foot:=Vector3(xz.x,m.world.height_at(xz.x,xz.y)+.08,xz.y)
	await m.world.prepare_region(foot,24)
	var space:PhysicsDirectSpaceState3D=m.world.get_world_3d().direct_space_state
	var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.7,foot-Vector3.UP*1.0,1,[m.player.get_rid()]))
	if not hit.is_empty():foot.y=hit.position.y+.08
	record("ground_camera_"+id,not hit.is_empty() and hit.normal.y>.7,{"foot":foot,"eye_height_m":1.7})
	await capture150(id,foot+Vector3.UP*1.7,target,foot)
func ground_visuals():
	m.set_time(0)
	await ground_capture("cloud_valley_ground",Vector2(50,-600),Vector3(-112,38,10))
	await ground_capture("cherry_creek_ground",Vector2(-465,-385),Vector3(-500,59,-410))
	await ground_capture("warm_bay_ground",Vector2(-535,160),Vector3(-330,10,285))
	var arch:Dictionary=m.world.layout.config.landscape150.main_arch;var center:Vector3=(m.world.layout.vector(arch.a)+m.world.layout.vector(arch.c))*.5
	await ground_capture("azure_arch_ground",Vector2(574,-55),center-Vector3.UP*7)
	await ground_capture("castle_ground",Vector2(-139,70),Vector3(-112.5,29,10))
	await ground_capture("floating_palaces_ground",Vector2(438,-435),Vector3(480,132,-530))
	await ground_capture("north_rim_ground",Vector2(560,-580),Vector3(605,45,-650))
	m.set_time(2);await ground_capture("forest_windows_ground",Vector2(-75,483),Vector3(-75,4.4,471));m.set_time(0)
	for id in ["Z03","Z07"]:
		var cards:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/landscape150_regions.json"))
		for card in cards:
			if card.id==id:
				var p:Array=card.courts[0];var q:=Vector3(p[0],m.world.height_at(p[0],p[1]),p[1]);await capture150("region_"+id+"_pink_repair",q+Vector3(22,17,29),q+Vector3.UP*3,q)
func expanded_works_restore():
	phase="expanded_save_and_works";m.store.configure_palace()
	var p:=Vector3(58,m.world.height_at(58,-600)+.08,-600);var uid:String=m.creative.items.grant("paper_lamp",1,{"tone":1})[0]
	record("expanded_work_fixture_placed",m.creative.items.transfer(uid,"placed",{"position":[p.x,p.y,p.z],"yaw":.4,"area":"world"}))
	await move_to(Vector3(50,m.world.height_at(50,-600)+.08,-600));record("expanded_work_save",m.save_game(false));await m.start_game(true)
	var work:Dictionary=m.creative.items.data().works.get(uid,{})
	record("expanded_work_not_returned_to_bag",work.get("location")=="placed" and equivalent(work.get("position"),[p.x,p.y,p.z]),{"uid":uid,"work":work})
	var low:Vector3=m.world.layout.vector(m.world.layout.config.landscape150.lower_pavilion);await move_to(low+Vector3(0,.15,1));record("floating_low_save",m.save_game(false));await m.start_game(true)
	record("floating_low_restores_to_actual_floor",m.player.position.distance_to(low+Vector3(0,.15,1))<1.5,{"actual":m.player.position,"floor":low})
func landscape_visuals():
	m.set_time(0)
	for scene in [
		["cloud_valley",Vector3(40,95,-620),Vector3(-10,40,-365),Vector3(50,65,-600)],
		["cherry_creek",Vector3(-470,77,-345),Vector3(-502,53,-395),Vector3(-465,60,-385)],
		["warm_bay",Vector3(-530,35,245),Vector3(-340,6,310),Vector3(-520,20,220)],
		["azure_arch",Vector3(600,40,35),Vector3(540,23,-40),Vector3(540,25,-10)],
		["castle_forecourt",Vector3(-165,40,110),Vector3(-112.5,25,10),Vector3(-112,5,75)],
		["floating_palaces",Vector3(390,100,-390),Vector3(480,132,-530),Vector3(438,75,-435)],
		["tide_cove",Vector3(-100,20,585),Vector3(-55,1,530),Vector3(-70,0,546)]]:
		await capture150(scene[0],scene[1],scene[2],scene[3])
	var cards:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/landscape150_regions.json"))
	for card in cards:
		var p:Array=card.courts[0];var q:=Vector3(p[0],m.world.height_at(p[0],p[1]),p[1]);await capture150("region_"+str(card.id),q+Vector3(22,17,29),q+Vector3.UP*3,q)
	m.set_time(2);var forest:=Vector3(-62,m.world.height_at(-62,490),490);await capture150("forest_windows_night",forest+Vector3(22,12,23),forest+Vector3.UP*5,forest);m.set_time(0)
func landscape_performance():
	m.player.enabled=false;m.player.set_physics_process(false);m.ui.show();m.player.figure.hide();m.watch_camera.current=true
	for route in [{"id":"north_valley","a":Vector2(20,-580),"c":Vector2(180,-570)},{"id":"cherry_creek","a":Vector2(-455,-300),"c":Vector2(-465,-385)},{"id":"floating_corner","a":Vector2(438,-435),"c":Vector2(478,-365)}]:
		var a:=Vector3(route.a.x,m.world.height_at(route.a.x,route.a.y)+2,route.a.y);var c:=Vector3(route.c.x,m.world.height_at(route.c.x,route.c.y)+2,route.c.y)
		m.player.position=a;m.world.streamer.set_foci([a]);await m.world.prepare_region(a,24)
		for i in 90:await m.get_tree().process_frame
		phase="perf_"+str(route.id);measuring=true;measured_last_usec=0;var start:int=Time.get_ticks_msec()
		while Time.get_ticks_msec()-start<18000:
			var p:Vector3=a.lerp(c,float(Time.get_ticks_msec()-start)/18000);p.y=m.world.height_at(p.x,p.z)+2;m.player.position=p;m.watch_camera.position=p
			var target:Vector3=Vector3(480,130,-530) if route.id=="floating_corner" else p+(c-a).normalized()*50+Vector3.UP*7
			m.watch_camera.look_at(target);await m.get_tree().process_frame
		measuring=false;var values:Array=sampled.get(phase,[]);var total:=0.0
		for value in values:total+=float(value)
		values.sort();var fps:float=1000*values.size()/maxf(total,.01);var p95:float=values[int(values.size()*.95)] if not values.is_empty() else INF
		record(phase,fps>=30 and p95<=40,{"average_fps":fps,"p95_ms":p95,"duration_ms":total,"frames":values.size(),"render_scale":m.get_viewport().scaling_3d_scale,"route_a":a,"route_c":c})
	await media_smoke();m.player.set_physics_process(true)

func route_performance_final():
	m.player.enabled=false;m.player.set_physics_process(false);m.ui.show();m.player.figure.hide();m.watch_camera.current=true
	var routes:Array=[
		{"id":"north_to_old_woodland","points":[[-20,-420],[-60,-430],[-160,-455],[-240,-500],[-330,-530],[-440,-470],[-465,-385],[-440,-310],[-355,-265],[-240,-228]],"time":0},
		{"id":"cherry_to_life","points":[[-440,-310],[-355,-265],[-240,-228]],"time":0},
		{"id":"cliff_to_islands","points":[[440,100],[472,190],[450,270],[410,320],[408,337]],"time":2}]
	for route in routes:
		m.set_time(route.time);var first:Array=route.points[0];var anchor:=Vector3(first[0],m.world.height_at(first[0],first[1])+1.7,first[1]);m.player.position=anchor;await m.world.prepare_region(anchor,24)
		for i in 90:await m.get_tree().process_frame
		phase="perf_"+str(route.id);measuring=true;measured_last_usec=0;var start:int=Time.get_ticks_msec();var slow:Array=[]
		while Time.get_ticks_msec()-start<30000:
			var t:float=float(Time.get_ticks_msec()-start)/30000.0;var along:float=(t/.75 if t<.75 else 1-(t-.75)*2)*(route.points.size()-1);var index:int=mini(route.points.size()-2,floori(along));var fraction:float=along-index
			var a:=Vector2(route.points[index][0],route.points[index][1]);var c:=Vector2(route.points[index+1][0],route.points[index+1][1]);var q:Vector2=a.lerp(c,fraction)
			var eye:=Vector3(q.x,m.world.height_at(q.x,q.y)+1.7,q.y);m.player.position=eye;m.watch_camera.position=eye
			var yaw:float=atan2(c.x-a.x,c.y-a.y)+sin(t*TAU)*.9+(PI if t>.75 else 0);m.watch_camera.look_at(eye+Vector3(sin(yaw)*40,4,cos(yaw)*40))
			var before:int=Time.get_ticks_usec();await m.get_tree().process_frame;var ms:float=(Time.get_ticks_usec()-before)/1000.0
			if ms>100:slow.append({"frame_ms":ms,"position":eye})
		measuring=false;performance_result(phase,slow,{"points":route.points,"time_index":route.time,"method":"camera traversal and reversal; physical walking checked separately"})
	await move_to(Vector3(252,15.8,-195));await m.show_video("B06","sunset");phase="perf_existing_media";measuring=true;measured_last_usec=0
	var slow:Array=[];var start:int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<12000:
		var before:int=Time.get_ticks_usec();await m.get_tree().process_frame;var ms:float=(Time.get_ticks_usec()-before)/1000.0
		if ms>100:slow.append({"frame_ms":ms,"position":m.player.position})
	measuring=false;record("existing_media_playback_under_load",m.video.is_playing() and m.video.stream_position>5,{"seconds":m.video.stream_position});performance_result(phase,slow,{"screen":"B06","local_media":"sunset"});m.stop_media("landscape150_perf");m.close_modal();m.player.set_physics_process(true)

func performance_result(id:String,slow:Array,details:Dictionary):
	var values:Array=sampled.get(id,[]);var total:=0.0
	for value in values:total+=float(value)
	var sorted:Array=values.duplicate();sorted.sort();var fps:float=1000*values.size()/maxf(total,.01);var p95:float=sorted[int(sorted.size()*.95)] if not sorted.is_empty() else INF
	details.merge({"average_fps":fps,"p95_ms":p95,"duration_ms":total,"frames":values.size(),"over_100ms":slow,"render_scale":m.get_viewport().scaling_3d_scale})
	record(id,fps>=30 and p95<=40,details)

func water_patch():
	phase="affected_cove_navigation";var boats=m.bay.boats
	for route in [{"id":"forest_south_cove","a":Vector2(-130,580),"c":Vector2(-10,580)},{"id":"coral_south_cove","a":Vector2(165,530),"c":Vector2(245,530)}]:
		var invalid:Array=[]
		for i in 41:
			var q:Vector2=route.a.lerp(route.c,i/40.0);var water:Dictionary=boats.water_at(Vector3(q.x,-2.2,q.y))
			if water.is_empty():invalid.append(q)
		record(str(route.id)+"_depth",invalid.is_empty(),{"invalid":invalid})
		await move_to(Vector3(route.a.x,-2.2,route.a.y));boats.leave_for_travel()
		var boarded:bool=await boats.begin_board("yacht",Vector3(route.a.x,-2.2,route.a.y),-PI*.5);boats.testing=true
		var reached:bool=boarded and await ship_to(route.c,30)
		record(str(route.id)+"_actual_hull_passage",reached,{"end":m.player.position,"method":"isolated boat fixture, actual move_and_slide hull, test throttle"});boats.testing=false;boats.leave_for_travel()

func scope_contracts():
	phase="scope"
	var counts:Dictionary=m.world.streamer.manifest.authored_counts;var missing:Array=[];var actual:Dictionary={}
	for action in m.world.interactions:actual[str(action.id)]=true
	var protected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/protected_interactions_0110.json"))
	for id in protected.ids:
		if not actual.has(id):missing.append(id)
	record("protected_501_ids",missing.is_empty(),{"missing":missing,"total":actual.size()});record("unique_ids",actual.size()==m.world.interactions.size())
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/creative_places110.json"));var rebuilt:Dictionary=counts.get("design120",{});missing=[]
	for p in expected.places:
		if not rebuilt.has(str(p.id)):missing.append(p.id)
	record("all_83_buildings_have_authored_changes",missing.is_empty() and rebuilt.size()==83,{"missing":missing,"records":rebuilt.size()})
	record("58_outdoor_contracts",counts.get("outdoors120",[]).size()==58)
	var total_floors:=0
	for p in m.world.layout.creative_places:total_floors+=p.floors.size()
	record("130_registered_floor_surfaces",total_floors==130,{"actual":total_floors})
	var map=preload("res://scripts/bay_map_view.gd").new();map.spec=m.world.spec;map.layout_reference=m.world.layout
	var actual_map:Dictionary={}
	for item in map.places():actual_map[item.id]=item
	var protected_map:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/protected_map_0110.json"));var changed:Array=[]
	for item in protected_map.places:
		if not actual_map.has(item.id) or str(actual_map[item.id].get("kind",""))!=str(item.kind) or str(actual_map[item.id].get("parent",""))!=str(item.parent):changed.append(item.id)
	record("278_original_map_entries",map.places().size()==284 and changed.is_empty(),{"actual":map.places().size(),"missing_or_reparented":changed});map.free()
	record("all_63_item_definitions",m.creative.items.defs.size()==63,{"actual":m.creative.items.defs.size()})
	var protected_items:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/protected_items_0110.json"));changed=[]
	for id in protected_items.defs:
		if not m.creative.items.defs.has(id):changed.append(id);continue
		for field in ["name","kind","category","cost","wall"]:
			if not equivalent(protected_items.defs[id].get(field),m.creative.items.defs[id].get(field)):changed.append(id+":"+field)
	record("original_item_ids_categories_and_costs",changed.is_empty(),{"changed":changed})
	var drift:Array=[]
	for path in m.world.streamer.manifest.source_hashes:
		if not OS.has_feature("editor") and str(path).begins_with("res://tools/"):continue
		if not OS.has_feature("editor") and str(path).ends_with(".gd"):
			if not ResourceLoader.exists(path):drift.append(path)
		elif not OS.has_feature("editor") and str(path).ends_with("biome_field130.png"):
			# Exported textures are .ctex resources. Compare the decoded RGBA rather than raw PNG bytes.
			var contract:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/scenic130_texture_contract.json"));var tex:Texture2D=load(path);var decoded:Image=tex.get_image()
			if decoded.is_compressed():decoded.decompress()
			decoded.clear_mipmaps();decoded.convert(Image.FORMAT_RGBA8);var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(decoded.get_data())
			if decoded.get_width()!=int(contract.width) or decoded.get_height()!=int(contract.height) or hash.finish().hex_encode()!=str(contract.rgba_sha256):drift.append(path+":decoded_rgba")
		elif not OS.has_feature("editor") and str(path).ends_with(".glb"):
			if not ResourceLoader.exists(path):drift.append(path)
		elif FileAccess.get_sha256(path)!=m.world.streamer.manifest.source_hashes[path]:drift.append(path)
	record("bake_matches_all_sources",drift.is_empty(),{"drift":drift})
func real_save_migration():
	phase="real_normal_save_copies"
	var samples:Array=JSON.parse_string(FileAccess.get_file_as_string("user://landscape150_fixtures/manifest.json"));var original_directory:String=m.store.directory
	for index in samples.size():
		var sample:Dictionary=samples[index];var original:Dictionary=m.store.decode(str(sample.file));var copy_dir:String="user://migration150_"+str(index)
		DirAccess.make_dir_recursive_absolute(copy_dir);DirAccess.copy_absolute(str(sample.file),copy_dir+"/progress.json");m.store.directory=copy_dir;m.store.import_directory=""
		await m.start_game(true)
		var lost:Array=[]
		for field in ["stamps","cards","photos","shots","discovered"]:
			for value in original.get(field,[]):
				if value not in m.state.get(field,[]):lost.append(field+":"+str(value))
		for uid in original.get("creative110",{}).get("works",{}):
			var work:Dictionary=original.creative110.works[uid];var actual:Dictionary=m.creative.items.data().works.get(uid,{})
			for key in ["item","quantity","variant","location","position","yaw","area"]:
				if not equivalent(work.get(key),actual.get(key)):lost.append(str(uid)+":"+key)
		for id in original.get("creative110",{}).get("stacks",{}):
			if m.creative.items.count(id)<int(original.creative110.stacks[id]):lost.append("material:"+id)
		record("real_save_preserves_progress_"+str(index),not original.is_empty() and lost.is_empty(),{"sample":sample.id,"lost":lost})
		record("real_source_fixture_unchanged_"+str(index),FileAccess.get_sha256(sample.file)==sample.sha256)
	m.store.configure_palace();var selected:String=m.store.import_directory;var source_hash:String=FileAccess.get_sha256("user://save/palace_v1/progress.json")
	await m.start_game(true)
	record("first_landscape_reads_actual_latest_palace",selected=="user://save/palace_v1" and m.store.imported_legacy and m.store.import_source_checksum==source_hash)
	record("landscape_writes_new_namespace",m.save_game(false) and m.store.directory=="user://save/landscape_v1")
	record("old_palace_source_not_rewritten",FileAccess.get_sha256("user://save/palace_v1/progress.json")==source_hash)
	var current:Dictionary=m.store.read();var expected:Dictionary=current.get("palace_play_v1",{}).duplicate(true)
	await m.start_game(true);record("palace_current_save_restores_without_reimport",not m.store.imported_legacy and equivalent(expected,m.state.get("palace_play_v1",{})))
	var corrupt_dir:="user://landscape150_corrupt";DirAccess.make_dir_recursive_absolute(corrupt_dir);m.store.directory=corrupt_dir
	var f:=FileAccess.open(corrupt_dir+"/progress.json",FileAccess.WRITE);f.store_string("broken envelope");f.close()
	DirAccess.copy_absolute("user://save/landscape_v1/progress.json",corrupt_dir+"/progress.bak")
	record("corrupt_main_recovers_valid_backup",not m.store.read().is_empty())
	f=FileAccess.open(corrupt_dir+"/progress.bak",FileAccess.WRITE);f.store_string("also broken");f.close();var hash_before:String=FileAccess.get_sha256(corrupt_dir+"/progress.json")
	await m.start_game(true);record("two_corrupt_files_do_not_restart_or_overwrite",not m.active_game and FileAccess.get_sha256(corrupt_dir+"/progress.json")==hash_before and m.store.read().is_empty())
	m.store.directory=original_directory;m.store.import_directory="";await m.start_game(false)
