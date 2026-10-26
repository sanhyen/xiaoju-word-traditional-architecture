extends "res://scripts/scenic130_qa.gd"
func write_progress():
	if m==null:return
	var file:=FileAccess.open(m.evidence_root+"reports/palace140_progress.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"pid":OS.get_process_id(),"phase":phase,"checks":results.size(),"failed":results.filter(func(r):return not r.ok).size()}));file.close()
func run(main):
	m=main
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--part="):requested=arg.trim_prefix("--part=").split(",")
		if arg.begins_with("--label="):qa_label=arg.trim_prefix("--label=")
		if arg.begins_with("--place="):only_places=arg.trim_prefix("--place=").split(",")
	DirAccess.make_dir_recursive_absolute(m.evidence_root+"reports/scenic130_visual/final")
	await m.start_game(false);await m.get_tree().physics_frame
	if want("geometry"):
		scope_contracts();palace_contracts()
		if only_places.is_empty():await geometry()
		else:
			for p in m.world.layout.creative_places:
				if str(p.id) in only_places:await entrance(p);await floors_probe(p)
	if want("play"):await palace_play_checks();await feedback_checks();await puzzle_and_map()
	if want("systems"):await mode_checks();await item_integration();await media_smoke();await migration_checks();await memory_migration();await map_checks()
	if want("transport"):await cable_checks();await cable_downhill_checks()
	if want("migration"):await real_save_migration()
	if want("visual"):await palace_visuals()
	if want("visual_patch"):await final_visual_patch()
	if want("visual_cliff"):
		for id in ["Z09_B3","Z09_B5","Z09_B6"]:
			var p:Dictionary=m.palace.place(id);var o:Vector3=m.palace.vec(p.center);await capture("P140_final_"+id,o+Vector3(22,18,25),o+Vector3.UP*4,o)
		await capture("P140_creek_entry",Vector3(-192.6,5.0,-191.7),Vector3(-194,4.7,-186.8),Vector3(-192.6,3.3,-189.7))
		m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
	if want("visual_post"):
		var uid:String=m.creative.items.grant("poem_journal",1,{"tone":1})[0];m.palace.submit(1,uid);var q:Vector3=m.palace.project_position(1);await capture("P140_final_forest_mail",q+Vector3(1.2,1.9,4.5),q+Vector3.UP*1.4,q)
		m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
	if want("hardening"):await extension_checks()
	if want("perf"):await scenic_performance()
	var failures:Array=results.filter(func(r):return not r.ok)
	var report:Dictionary={"version":ProjectSettings.get_setting("application/config/version"),"label":qa_label,"parts":requested,"checks":results,"failures":failures,"floors":floor_measurements,"portals":portal_measurements,"poses":poses,"performance":sampled,"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name(),"resolution":m.get_viewport().get_visible_rect().size,"normal_saves":"isolated APPDATA and LOCALAPPDATA","pck_sha256":FileAccess.get_sha256(OS.get_executable_path().get_base_dir()+"/XiaojuWorld.pck") if OS.has_feature("standalone") else "source_candidate"}
	var f:=FileAccess.open(m.evidence_root+"reports/palace140_"+qa_label+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("PALACE140_COMPLETE ",JSON.stringify({"checks":results.size(),"failures":failures.size()}));m.get_tree().quit(0 if failures.is_empty() else 1)
func palace_contracts():
	phase="palace_architecture"
	var records:Dictionary=m.world.streamer.manifest.authored_counts.get("palace140_architecture",{});var families:Dictionary={};var grades:Dictionary={};var floors:=0
	for p in m.world.layout.creative_places:
		var r:Dictionary=records.get(str(p.id),{});var valid:bool=not r.is_empty()
		if valid:
			valid=r.get("roof","") in ["hip","hard_gable","hanging_gable"] and int(r.get("brackets",0))>0 and r.get("component_types",[]).size()>=8 and int(r.occupied_floors)==p.floors.size()
			families[r.family]=true;grades[str(r.grade)]=true;floors+=int(r.occupied_floors)
			record("palace_"+str(p.id),valid,{"roof":r.roof,"grade":r.grade,"components":r.component_types,"brackets":r.brackets,"windows":r.window_panels,"registered_floors":r.occupied_floors})
		else:record("palace_"+str(p.id),false)
	record("83_palaces_13_use_families_4_grades",records.size()==83 and families.size()==13 and grades.size()==4 and floors==130,{"count":records.size(),"families":families.keys(),"grades":grades.keys(),"floors":floors})
	record("castle_retains_copper_green_roof",records.get("CASTLE_MAIN",{}).get("color","")=="557F70")
func capture(id:String,eye:Vector3,target:Vector3,anchor:Vector3=Vector3.INF):
	phase="visual_"+id
	if not anchor.is_finite():anchor=target
	m.player.enabled=false;m.player.set_physics_process(false);m.player.position=anchor;m.world.streamer.set_foci([anchor])
	if not await m.world.prepare_region(anchor,24):record("capture_"+id,false);return
	m.watch_camera.position=eye;m.watch_camera.look_at(target);m.watch_camera.fov=67;m.watch_camera.current=true;m.player.figure.hide();m.ui.hide()
	for i in 14:await m.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:String=m.evidence_root+"reports/palace140_visual/"+qa_label;DirAccess.make_dir_recursive_absolute(folder);var file:String=folder+"/"+id+".png";m.get_viewport().get_texture().get_image().save_png(file)
	poses.append({"id":id,"file":file,"eye":[eye.x,eye.y,eye.z],"target":[target.x,target.y,target.z],"anchor":[anchor.x,anchor.y,anchor.z],"resolution":m.get_viewport().get_visible_rect().size,"version":ProjectSettings.get_setting("application/config/version"),"time":Time.get_datetime_string_from_system()});print("PALACE140_SHOT ",id)
func palace_play_checks():
	phase="palace_play"
	var p=m.palace;var items=m.creative.items
	record("15_regions_have_physical_journal_boards",p.boards.size()==15 and m.world.interactions.filter(func(r):return r.kind=="palace140").size()==15)
	for id in p.CARDS:
		p.panel(id);record("journal_opens_"+id,m.modal.visible and not p.place(str(p.CARDS[id].anchor)).is_empty());m.close_modal()
	for index in 3:
		var uid:String=items.grant(str(p.JOBS[index][1]),1,{"tone":index})[0];var count_before:int=items.count("wood");var letters:int=m.bay.dual.island_data().letters.size()
		var ok:bool=p.submit(index,uid)
		record("commission_uid_and_world_"+str(index),ok and items.data().works[uid].location=="commission:"+str(index) and p.data().world_projects[str(index)].active_uid==uid and items.count("wood")==count_before+2 and p.props["PublicContribution"+str(index)].get_child_count()>0)
		var after:String=JSON.stringify(m.state);record("commission_cannot_resubmit_same_uid_"+str(index),not p.submit(index,uid) and JSON.stringify(m.state)==after)
		record("commission_does_not_send_mail_"+str(index),m.bay.dual.island_data().letters.size()==letters)
	var uid:String=items.grant("street_box",1,{"tone":2})[0];var original_directory:String=m.store.directory;var before:Dictionary=m.state.duplicate(true)
	# A file used as a directory is a real filesystem failure, not a mocked save method.
	var block:=FileAccess.open("user://palace140_save_blocker",FileAccess.WRITE);block.store_string("block");block.close();m.store.directory="user://palace140_save_blocker/not_a_directory"
	record("commission_save_failure_restores_inventory_and_rewards",not p.submit(2,uid) and equivalent(before,m.state));m.store.directory=original_directory
	p.curation_edit.clear();var owns:String=JSON.stringify(items.data());p.toggle_exhibit(uid)
	record("exhibition_edit_does_not_publish_or_consume",uid in p.curation_edit.uids and uid not in p.curation().uids and owns==JSON.stringify(items.data()))
	record("exhibition_confirmation_persists_actual_uid",p.save_exhibition() and uid in p.curation().uids and owns==JSON.stringify(items.data()));m.close_modal()
	var choices:Dictionary=p.stage().duplicate(true);p.stage_panel();p.preview_choices={"lighting":2,"curtain":1,"scenery":2};p.apply_scene();var preview:Node3D=p.props.StageBackdrop140
	record("stage_three_physical_choices_preview",int(m.world.stage_presets.B10)==2 and preview.get_child_count()==18 and equivalent(choices,p.stage()) and preview.get_meta("curtain_panels",0)==12)
	m.close_modal();p.apply_scene();record("stage_cancel_restores_saved_choices",int(m.world.stage_presets.B10)==int(choices.lighting))
	for chart in 3:
		m.bay.dual.island_data().star_chart=chart;m.creative.begin_puzzle("star");m.creative.puzzle.moves=chart+3;m.close_modal()
	for chart in 3:
		m.bay.dual.island_data().star_chart=chart;m.creative.begin_puzzle("star");record("independent_star_draft_"+str(chart),m.creative.puzzle.moves==chart+3);m.close_modal()
	items.data().knowledge.daily_photo_file="user://missing-original-photo140.png";m.creative.begin_puzzle("daily")
	record("missing_selected_photo_is_not_silently_replaced",m.creative.puzzle==null and m.creative.daily_photo_file()=="user://missing-original-photo140.png");m.close_modal();items.data().knowledge.erase("daily_photo_file")
	var photo:Node3D=m.creative.models.make("photo_print",{"file":"user://missing-original-photo140.png"});record("missing_photo_has_explicit_placeholder",photo.has_meta("missing_photo"));photo.free()
	var saved:Dictionary=p.data().duplicate(true);record("palace_state_saves",m.save_game(false));var read:Dictionary=m.store.read();record("palace_state_cold_decode",equivalent(saved,read.get("palace_play_v1",{})))
func palace_visuals():
	phase="palace_visuals";m.set_time(0)
	var seen:Dictionary={}
	for region in load("res://scripts/scenic_biomes130.gd").spec.regions:
		var p:Dictionary=m.palace.place(str(m.palace.CARDS[region.id].anchor));var o:Vector3=m.palace.vec(p.center);var extent:float=maxf(p.size[0],p.size[1]);var high:float=maxf(6,float(p.floors[-1])-o.y+6)
		seen[str(p.id)]=true
		await capture("P140_"+str(region.id),o+Basis(Vector3.UP,float(p.door_yaw))*Vector3(extent*.9,high*.7+extent*.30,extent*1.15),o+Vector3.UP*high*.45,o)
	for p in m.world.layout.creative_places:
		if seen.has(str(p.id)):continue
		var o:Vector3=m.palace.vec(p.center);var extent:float=maxf(p.size[0],p.size[1]);var data:Dictionary=m.world.streamer.manifest.authored_counts.palace140_architecture.get(str(p.id),{});var high:float=maxf(6,float(data.get("eave_y",p.floors[-1]+3.5))-o.y+3.5)
		await capture("P140_building_"+str(p.id),o+Basis(Vector3.UP,float(p.door_yaw))*Vector3(extent*.9,high*.7+extent*.3,extent*1.15),o+Vector3.UP*high*.45,o)
	for id in ["CASTLE_MAIN","B10","B05","B13"]:
		var p:Dictionary=m.palace.place(id);var o:Vector3=m.palace.vec(p.center);await capture("P140_inside_"+id,o+Vector3(0,2.2,float(p.size[1])*.28),o+Vector3(0,2.4,-float(p.size[1])*.32),o)
	m.set_time(1);await capture("P140_castle_dusk",Vector3(-45,58,115),Vector3(-112,26,15),Vector3(-112,9,25));m.set_time(2);await capture("P140_castle_night",Vector3(-45,58,115),Vector3(-112,26,15),Vector3(-112,9,25));m.set_time(0)
	await capture("P140_world",Vector3(500,1040,1240),Vector3(-90,0,110),Vector3(0,5,80));await capture("P140_shore",Vector3(87,49,408),Vector3(0,-1,301),Vector3(0,1,290))
	m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
func real_save_migration():
	phase="real_normal_save_copies"
	var samples:Array=JSON.parse_string(FileAccess.get_file_as_string("user://palace140_fixtures/manifest.json"));var original_directory:String=m.store.directory
	for index in samples.size():
		var sample:Dictionary=samples[index];var original:Dictionary=m.store.decode(str(sample.file));var copy_dir:String="user://migration140_"+str(index)
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
	m.store.configure_palace();var selected:String=m.store.import_directory;var source_hash:String=FileAccess.get_sha256("user://save/scenic_v1/progress.json")
	await m.start_game(true)
	record("first_palace_reads_actual_latest_scenic",selected=="user://save/scenic_v1" and m.store.imported_legacy and m.store.import_source_checksum==source_hash)
	record("palace_writes_new_namespace",m.save_game(false) and m.store.directory=="user://save/palace_v1")
	record("old_scenic_source_not_rewritten",FileAccess.get_sha256("user://save/scenic_v1/progress.json")==source_hash)
	var current:Dictionary=m.store.read();var expected:Dictionary=current.get("palace_play_v1",{}).duplicate(true)
	await m.start_game(true);record("palace_current_save_restores_without_reimport",not m.store.imported_legacy and equivalent(expected,m.state.get("palace_play_v1",{})))
	var corrupt_dir:="user://palace140_corrupt";DirAccess.make_dir_recursive_absolute(corrupt_dir);m.store.directory=corrupt_dir
	var f:=FileAccess.open(corrupt_dir+"/progress.json",FileAccess.WRITE);f.store_string("broken envelope");f.close()
	DirAccess.copy_absolute("user://save/palace_v1/progress.json",corrupt_dir+"/progress.bak")
	record("corrupt_main_recovers_valid_backup",not m.store.read().is_empty())
	f=FileAccess.open(corrupt_dir+"/progress.bak",FileAccess.WRITE);f.store_string("also broken");f.close();var hash_before:String=FileAccess.get_sha256(corrupt_dir+"/progress.json")
	await m.start_game(true);record("two_corrupt_files_do_not_restart_or_overwrite",not m.active_game and FileAccess.get_sha256(corrupt_dir+"/progress.json")==hash_before and m.store.read().is_empty())
	m.store.directory=original_directory;m.store.import_directory="";await m.start_game(false)
func extension_checks():
	phase="extension_safety";var p=m.palace;var before:Dictionary=m.state.duplicate(true)
	m.state.palace_play_v1={"schema":9,"future_fields":{"kept":"original"}};var unknown:Dictionary=m.state.palace_play_v1.duplicate(true);p.initialize_state()
	record("unknown_higher_schema_preserved_and_read_only",p.extension_readonly and not p.initialized and equivalent(unknown,m.state.palace_play_v1));m.state=before;p.initialize_state()
	var items=m.creative.items;var materials:Dictionary=items.data().stacks.duplicate(true);var uids:Array=[]
	for i in 3:
		var uid:String=items.grant(str(p.JOBS[i][1]),1,{"tone":i})[0];items.transfer(uid,"commission:"+str(i));items.data().commissions[str(i)]={"runs":1,"pattern":p.JOBS[i][2]};uids.append(uid)
	p.data().world_projects.clear();p.initialize_state();p.initialize_state()
	var valid:=true
	for i in 3:
		if p.data().world_projects[str(i)].active_uid!=uids[i]:valid=false
	record("old_completed_commissions_gain_world_results_without_rewards",valid and equivalent(materials,items.data().stacks))
	for uid in items.data().works.keys():
		if items.data().works[uid].get("location","")=="commission:1":items.data().works.erase(uid)
	p.data().world_projects.erase("1");p.initialize_state();record("missing_legacy_uid_only_builds_memorial",p.data().world_projects["1"].get("memorial_only",false))
	m.state=before;p.initialize_state()
func final_visual_patch():
	phase="affected_visual_patch";m.set_time(0)
	var ids:Array=["VILLA_0","VILLA_1","VILLA_2","VILLA_3","ISLAND_LOBBY","LIGHTHOUSE","SUMMIT_TEA","CREEK_TEA","H10","THEME_FROST"]
	for id in ids:
		var p:Dictionary=m.palace.place(id);var o:Vector3=m.palace.vec(p.center);var extent:float=maxf(p.size[0],p.size[1]);var high:float=maxf(6,float(p.floors[-1])-o.y+6);var offset:=Vector3(-extent*.95,high*.75+6,extent*1.2)
		if id=="CREEK_TEA":offset=Vector3(-11,9,15)
		if id=="THEME_FROST":offset=Vector3(-25,18,28)
		await capture("P140_fixed_"+id,o+offset,o+Vector3.UP*high*.4,o)
	var p:Dictionary=m.palace.place("CASTLE_MAIN");var o:Vector3=m.palace.vec(p.center);await capture("P140_castle_ground_clear",o+Vector3(6,2.2,6),o+Vector3(5,1.6,-6),o)
	var theater:Vector3=m.palace.vec(m.palace.place("B10").center);m.palace.data().scene_choices.B10={"lighting":2,"curtain":1,"scenery":2};m.palace.apply_scene()
	await capture("P140_stage_choices_world",theater+Vector3(0,2.2,7),theater+Vector3(0,3.0,-10),theater)
	for i in 3:
		var uid:String=m.creative.items.grant(str(m.palace.JOBS[i][1]),1,{"tone":i})[0];m.palace.submit(i,uid);var q:Vector3=m.palace.project_position(i)
		await capture("P140_public_result_"+str(i),q+Vector3(8,7,16),q+Vector3.UP*1.4,q)
	m.watch_camera.current=false;m.environment_controls.enter();m.environment_controls.switch_mode();m.environment_controls.fit_world_view()
	for i in 30:await m.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder:String=m.evidence_root+"reports/palace140_visual/"+qa_label;DirAccess.make_dir_recursive_absolute(folder);var file:String=folder+"/P140_world_fitted.png";m.get_viewport().get_texture().get_image().save_png(file);poses.append({"id":"P140_world_fitted","file":file,"source":"Actual Home fit_world_view; original render scale","version":ProjectSettings.get_setting("application/config/version")});m.environment_controls.leave()
	m.ui.show();m.player.figure.show();m.player.set_physics_process(true);m.watch_camera.current=false;m.player.camera.current=true
