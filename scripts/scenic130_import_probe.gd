extends SceneTree
var m
var checks:Array=[]
func _initialize():run.call_deferred()
func check(id:String,ok:bool,data:Dictionary={}):checks.append({"id":id,"ok":ok,"data":data});print("SCENIC_IMPORT ",id," ",ok)
func equivalent(a:Variant,b:Variant)->bool:
	if (a is float or a is int) and (b is float or b is int):return absf(float(a)-float(b))<.000001
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not equivalent(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not equivalent(a[i],b[i]):return false
		return true
	return a==b
func run():
	if not "scenic130" in OS.get_user_data_dir():push_error("Import probe requires the named isolated profile");quit(1);return
	var fixture:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):fixture=arg.trim_prefix("--fixture=")
	if fixture.is_empty() or not FileAccess.file_exists(fixture):push_error("Missing explicit copied fixture");quit(1);return
	DirAccess.make_dir_recursive_absolute("user://save/design_v1");DirAccess.copy_absolute(fixture,"user://save/design_v1/progress.json")
	var source_sha:String=FileAccess.get_sha256("user://save/design_v1/progress.json");var original:Dictionary=load("res://scripts/save_store.gd").new().decode("user://save/design_v1/progress.json")
	m=load("res://scenes/world/main.tscn").instantiate();root.add_child(m)
	check("production_namespace_is_scenic_v1",m.store.directory=="user://save/scenic_v1",{"actual":m.store.directory})
	check("production_import_order_starts_design_v1",m.store.import_directory=="user://save/design_v1",{"actual":m.store.import_directory})
	await m.start_game(true)
	check("old_favorites_default_empty",m.state.get("map_favorites",[])==[])
	var previous:Dictionary=original.get("creative110",{});var current:Dictionary=m.state.get("creative110",{})
	for key in ["works","stacks","shortcuts","equipped_hand","equipped_back"]:check("retained_"+key,equivalent(previous.get(key),current.get(key)))
	for key in ["stamps","cards","inventory","home_photo","home_card","home_shot","bouquet","pb_page"]:check("retained_progress_"+key,equivalent(original.get(key),m.state.get(key)))
	check("old_import_file_unchanged_before_write",FileAccess.get_sha256("user://save/design_v1/progress.json")==source_sha)
	m.state.map_favorites=["B03","CASTLE_MAIN"];m.state.map_recent=["CASTLE_MAIN","B03"];check("scenic_namespace_save",m.save_game(false));check("scenic_valid_backup",m.save_game(false))
	var cold=load("res://scripts/save_store.gd").new();cold.directory="user://save/scenic_v1";cold.import_directory="user://save/design_v1";var recovered:Dictionary=cold.read()
	check("new_save_preferred_over_old",not cold.imported_legacy and recovered.map_favorites==["B03","CASTLE_MAIN"] and recovered.map_recent==["CASTLE_MAIN","B03"])
	check("old_import_file_unchanged_after_write",FileAccess.get_sha256("user://save/design_v1/progress.json")==source_sha)
	var backup:String=FileAccess.get_sha256("user://save/scenic_v1/progress.bak");var bad:=FileAccess.open("user://save/scenic_v1/progress.json",FileAccess.WRITE);bad.store_string("corrupt isolated probe");bad.close();var repaired:Dictionary=cold.read()
	check("corrupt_scenic_main_uses_backup",not repaired.is_empty() and repaired.get("map_favorites",[])==["B03","CASTLE_MAIN"])
	check("last_good_backup_retained",cold.write(repaired) and FileAccess.get_sha256("user://save/scenic_v1/progress.bak")==backup)
	var f:=FileAccess.open("res://reports/scenic130_import_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"version":ProjectSettings.get_setting("application/config/version"),"checks":checks,"passed":checks.all(func(row):return row.ok),"source":"Read-only copied real 0120 save, seeded under isolated profile. Original normal save never written.","source_sha256":source_sha},"\t"));f.close();quit(0 if checks.all(func(row):return row.ok) else 1)
