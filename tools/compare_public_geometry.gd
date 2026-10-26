extends "res://tools/public_scene_audit.gd"
func run():
	var baseline:String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):baseline=arg.trim_prefix("--baseline=")
	assert(not baseline.is_empty())
	var folder:String="res://assets/world/stream_precision160";var records:Array=[];var total:int=0
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".scn"):continue
		total+=1
		var path:String=folder+"/"+file;var previous:String=baseline+"/"+file
		if FileAccess.get_sha256(path)==FileAccess.get_sha256(previous):continue
		mesh_hashes.clear();var before:Dictionary={};var n=ResourceLoader.load(previous,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate();root.add_child(n);RenderingServer.force_sync();geometry(n,before);n.free();await process_frame
		mesh_hashes.clear();var after:Dictionary={};n=ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate();root.add_child(n);RenderingServer.force_sync();geometry(n,after);n.free();await process_frame
		assert(before==after,"Geometry or collision mismatch: "+file);records.append({"scene":file,"geometry_collision_equal":true})
	var report:Dictionary={"passed":true,"total_scenes":total,"identical_files":total-records.size(),"affected_scenes":records}
	var f:=FileAccess.open("res://reports/public_geometry_comparison.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("PUBLIC_GEOMETRY_COMPARE ",JSON.stringify(report));quit()
