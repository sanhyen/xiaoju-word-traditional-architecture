extends "res://scripts/landscape150_qa.gd"
func write_progress():
	if m==null:return
	var f:=FileAccess.open(m.evidence_root+"reports/precision160_progress.json",FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify({"pid":OS.get_process_id(),"phase":phase,"checks":results.size(),"failed":results.filter(func(r):return not r.ok).size()}));f.close()
func run(main):
	m=main
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--part="):requested=arg.trim_prefix("--part=").split(",")
		if arg.begins_with("--label="):qa_label=arg.trim_prefix("--label=")
	await m.start_game(false);await m.get_tree().physics_frame
	if want("engineering"):
		scope_contracts();palace_contracts();await landscape_contracts();precision_contracts();await geometry();await media_smoke()
	if want("engineering_resume"):
		scope_contracts();var active:=false
		for p in m.world.layout.creative_places:
			if p.id=="THEME_FROST":active=true
			if active:await entrance(p);await floors_probe(p)
		await media_smoke()
	if want("package_contracts"):scope_contracts();palace_contracts();precision_contracts();await media_smoke()
	if want("migration"):await precision_migration()
	if want("import_patch"):await precision_import_check()
	if want("visual"):await precision_visuals()
	if want("visual_patch"):await visual_precision_patch()
	if want("visual_final"):await final_visuals()
	if want("furniture_final"):
		m.set_time(0);var p:Dictionary=m.palace.place("H10");var o:Vector3=m.palace.vec(p.center)
		await capture("H10_final_furniture",o+Vector3(-4,2.1,6),o+Vector3(1,1,-1),o)
	if want("night_final"):
		m.set_time(2);var p:Dictionary=m.palace.place("B05");var o:Vector3=m.palace.vec(p.center)
		await capture("B05_final_moon_shadows",o+Vector3(14,5,23),o+Vector3.UP*3,o)
	if want("seat_visual"):
		var p:Dictionary=m.palace.place("B10");var o:Vector3=m.palace.vec(p.center);await capture("theater_seats_final",o+Vector3(0,1.72,float(p.size[1])*.28),o+Vector3(0,2.6,-float(p.size[1])*.32),o)
	if want("perf") or want("perf_patch") or want("perf_street"):await precision_performance()
	if want("streaming"):await precision_streaming()
	var failures:Array=results.filter(func(r):return not r.ok)
	var output:Dictionary={"version":ProjectSettings.get_setting("application/config/version"),"label":qa_label,"parts":requested,"checks":results,"failures":failures,"floors":floor_measurements,"portals":portal_measurements,"poses":poses,"performance":sampled,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":m.get_viewport().get_visible_rect().size,"render_scale":m.get_viewport().scaling_3d_scale,"pck_sha256":FileAccess.get_sha256(OS.get_executable_path().get_base_dir()+"/XiaojuWorld.pck") if not OS.has_feature("editor") else "source_candidate","normal_saves":"isolated copies only"}
	var f:=FileAccess.open(m.evidence_root+"reports/precision160_"+qa_label+".json",FileAccess.WRITE);f.store_string(JSON.stringify(output,"\t"));f.close();print("PRECISION160_COMPLETE ",results.size()," failures ",failures.size());m.get_tree().quit(0 if failures.is_empty() else 1)
func precision_contracts():
	phase="precision_contracts"
	var built:Dictionary=m.world.streamer.manifest.authored_counts.get("precision160_architecture",{})
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/palace_v14.json"))
	record("83_precision_buildings",built.size()==83,{"count":built.size()})
	for id in built:
		var row:Dictionary=built[id];var counts:Dictionary=row.precision_counts
		record("precision_joinery_"+str(id),int(counts.columns)>0 and int(counts.dougong)>0 and int(counts.openwork)>0 and row.purpose_preserved and int(row.colliders_added)==0,counts)
	record("new_namespace_configured",load("res://scripts/save_store.gd").new().has_method("configure_palace"))
	var cases:Array=[]
	for id in ["B05","H10","CASTLE_MAIN"]:
		var p:Dictionary=m.palace.place(id);var door:Vector3=m.palace.vec(p.door);var forward:Vector3=Basis(Vector3.UP,float(p.door_yaw))*Vector3.BACK;var points:Array=[]
		for distance in [3.0,1.0,-1.0,-3.0]:
			var q:Vector3=door+forward*distance;points.append([q.x,q.y+.12,q.z])
		cases.append({"id":id,"start":points[0],"points":points,"time":2 if id=="H10" else 0})
	var f:=FileAccess.open(m.evidence_root+"reports/precision160_native_points.json",FileAccess.WRITE);f.store_string(JSON.stringify(cases,"\t"));f.close()
func capture(id:String,eye:Vector3,target:Vector3,anchor:Vector3=Vector3.INF):
	phase="visual_"+id
	if not anchor.is_finite():anchor=target
	m.player.enabled=false;m.player.set_physics_process(false);m.player.position=anchor;m.world.streamer.set_foci([anchor])
	if not await m.world.prepare_region(anchor,24):record("capture_"+id,false);return
	m.world.set_observation_cutaway(anchor,false)
	m.watch_camera.position=eye;m.watch_camera.look_at(target);m.watch_camera.fov=67;m.watch_camera.current=true;m.player.figure.hide();m.ui.hide()
	for i in 45:await m.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:String=m.evidence_root+"reports/precision160_visual/"+qa_label;DirAccess.make_dir_recursive_absolute(folder);var file:String=folder+"/"+id+".png"
	var error:int=m.get_viewport().get_texture().get_image().save_png(file)
	record("capture_"+id,error==OK)
	poses.append({"id":id,"file":file,"eye":[eye.x,eye.y,eye.z],"target":[target.x,target.y,target.z],"anchor":[anchor.x,anchor.y,anchor.z],"time":m.state.time});print("PRECISION_SHOT ",id)
func precision_visuals():
	m.set_time(0)
	for id in ["CASTLE_MAIN","B05","B10","H10","Z09_B3","ISLAND_LOBBY"]:
		var p:Dictionary=m.palace.place(id);var o:Vector3=m.palace.vec(p.center);var extent:float=maxf(p.size[0],p.size[1]);var high:float=maxf(6,float(p.floors[-1])-o.y+6)
		await capture("outside_"+id,o+Basis(Vector3.UP,float(p.door_yaw))*Vector3(extent*.70,high*.62+extent*.2,extent*1.18),o+Vector3.UP*high*.44,o)
	for id in ["B05","B10","CASTLE_MAIN"]:
		var p:Dictionary=m.palace.place(id);var o:Vector3=m.palace.vec(p.center)
		await capture("inside_"+id,o+Vector3(0,1.72,float(p.size[1])*.28),o+Vector3(0,2.6,-float(p.size[1])*.32),o)
	await ground_capture("floating_ground",Vector2(438,-435),Vector3(480,132,-530))
	for time_index in [1,2]:
		m.set_time(time_index);var p:Dictionary=m.palace.place("B05");var o:Vector3=m.palace.vec(p.center)
		await capture("B05_light_"+str(time_index),o+Vector3(14,5,23),o+Vector3.UP*3,o)
	m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
func precision_migration():
	phase="normal_save_copies"
	var samples:Array=JSON.parse_string(FileAccess.get_file_as_string("user://precision160_fixtures/manifest.json"))
	for index in samples.size():
		var sample:Dictionary=samples[index];var original:Dictionary=m.store.decode(str(sample.file));var folder:String="user://precision160_migration_"+str(index)
		DirAccess.make_dir_recursive_absolute(folder);DirAccess.copy_absolute(str(sample.file),folder+"/progress.json");m.store.directory=folder;m.store.import_directory=""
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
		record("copy_preserved_"+str(index),not original.is_empty() and lost.is_empty(),{"source":sample.id,"lost":lost})
		record("fixture_unchanged_"+str(index),FileAccess.get_sha256(sample.file)==sample.sha256)
	await precision_import_check()
func precision_import_check():
	phase="latest_actual_normal_import"
	m.store.configure_palace();var expected_directory:String=m.store.import_directory
	var source:String=expected_directory+"/progress.json"
	if m.store.decode(source).is_empty():source=expected_directory+"/progress.bak"
	var checksum:String=FileAccess.get_sha256(source)
	await m.start_game(true)
	record("readonly_latest_actual_import",not expected_directory.is_empty() and m.store.imported_legacy and m.store.import_source_file==source and m.store.import_source_checksum==checksum,{"source":source,"sha256":checksum})
	record("writes_precision_namespace",m.save_game(false) and m.store.directory=="user://save/precision_v1")
	record("original_copy_not_rewritten",FileAccess.get_sha256(source)==checksum)
	var expected:Dictionary=m.state.duplicate(true);await m.start_game(true)
	var before:Dictionary=expected.get("creative110",{}).duplicate(true);var after:Dictionary=m.state.get("creative110",{}).duplicate(true)
	var before_clock:float=float(before.get("online",0));var after_clock:float=float(after.get("online",0));before.erase("online");after.erase("online")
	record("current_save_restores_without_import",not m.store.imported_legacy and equivalent(before,after) and after_clock>=before_clock and equivalent(expected.get("palace_play_v1"),m.state.get("palace_play_v1")),{"imported":m.store.imported_legacy,"creative_equal_except_elapsed_clock":equivalent(before,after),"online_before":before_clock,"online_after":after_clock,"palace_equal":equivalent(expected.get("palace_play_v1"),m.state.get("palace_play_v1"))})
func precision_performance():
	m.player.enabled=false;m.player.set_physics_process(false);m.ui.show();m.player.figure.hide();m.watch_camera.current=true
	for route in [{"id":"castle","a":Vector2(-140,84),"c":Vector2(-100,70),"target":Vector3(-112.5,30,10)},{"id":"street","a":Vector2(-75,238),"c":Vector2(-75,192),"target":Vector3(-97,8,182)},{"id":"floating","a":Vector2(438,-435),"c":Vector2(478,-400),"target":Vector3(480,132,-530)}]:
		if want("perf_patch") and route.id=="floating":continue
		if want("perf_street") and route.id!="street":continue
		m.set_time(2 if route.id=="street" else 0);var a:=Vector3(route.a.x,m.world.height_at(route.a.x,route.a.y)+1.72,route.a.y);var c:=Vector3(route.c.x,m.world.height_at(route.c.x,route.c.y)+1.72,route.c.y)
		m.player.position=a;m.world.streamer.set_foci([a]);await m.world.prepare_region(a,24)
		for i in 90:await m.get_tree().process_frame
		phase="perf_"+str(route.id);measuring=true;measured_last_usec=0;var start:int=Time.get_ticks_msec()
		while Time.get_ticks_msec()-start<15000:
			var p:Vector3=a.lerp(c,float(Time.get_ticks_msec()-start)/15000);p.y=m.world.height_at(p.x,p.z)+1.72;m.player.position=p;m.watch_camera.position=p;m.watch_camera.look_at(route.target);await m.get_tree().process_frame
		measuring=false;var values:Array=sampled.get(phase,[]);var total:=0.0;var slow:=0
		for value in values:total+=float(value);slow+=int(float(value)>100)
		values.sort();var fps:float=1000*values.size()/maxf(total,.01);var p95:float=values[int(values.size()*.95)] if not values.is_empty() else INF
		record(phase,fps>=30 and p95<=40,{"average_fps":fps,"p95_ms":p95,"over100ms":slow,"frames":values.size(),"seconds":total/1000,"a":a,"c":c,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	m.player.set_physics_process(true)
func precision_streaming():
	phase="streaming_travel";m.player.enabled=false;m.player.set_physics_process(false)
	for id in ["THEME_POEM","THEME_FROST","ISLAND_LOBBY","CASTLE_MAIN","THEME_POEM","THEME_FROST"]:
		var place:Dictionary=m.palace.place(id);var point:Vector3=m.palace.vec(place.door);m.player.position=point;m.world.streamer.set_foci([point]);var start:int=Time.get_ticks_msec()
		var ready:bool=await m.world.prepare_region(point,24)
		record("stream_transition_"+id+"_"+str(results.size()),ready,{"milliseconds":Time.get_ticks_msec()-start,"diagnostics":m.world.streamer.diagnostics()})
	m.player.set_physics_process(true)

func visual_precision_patch():
	m.set_time(0)
	var p:Dictionary=m.palace.place("CASTLE_MAIN");var o:Vector3=m.palace.vec(p.center)
	await capture("castle_complete",o+Vector3(78,39,105),o+Vector3.UP*23,o)
	await capture("castle_ceiling",o+Vector3(7,1.72,7),o+Vector3(3,4,-7),o)
	for id in ["Z09_B3","ISLAND_LOBBY"]:
		p=m.palace.place(id);o=m.palace.vec(p.center);var extent:float=maxf(p.size[0],p.size[1]);await capture("roof_final_"+id,o+Vector3(extent*.8,10,extent*1.2),o+Vector3.UP*3,o)
	p=m.palace.place("H10");o=m.palace.vec(p.center);var door:Vector3=m.palace.vec(p.door);var forward:Vector3=Basis(Vector3.UP,float(p.door_yaw))*Vector3.BACK
	await capture("H10_ground",door+forward*8+Vector3.UP*1.72,o+Vector3.UP*2,door)
	m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
func final_visuals():
	m.set_time(0)
	var p:Dictionary=m.palace.place("CASTLE_MAIN");var o:Vector3=m.palace.vec(p.center)
	await capture("castle_final_distance",o+Vector3(78,39,105),o+Vector3.UP*23,o)
	await capture("castle_final_ceiling",o+Vector3(7,1.72,7),o+Vector3(3,4,-7),o)
	p=m.palace.place("ISLAND_LOBBY");o=m.palace.vec(p.center);var extent:float=maxf(p.size[0],p.size[1])
	await capture("island_final_hip_tiles",o+Vector3(extent*.8,10,extent*1.2),o+Vector3.UP*3,o)
	p=m.palace.place("B05");o=m.palace.vec(p.center)
	for time_index in [0,2]:
		m.set_time(time_index);await capture("B05_final_"+str(time_index),o+Vector3(14,5,23),o+Vector3.UP*3,o)
	m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
