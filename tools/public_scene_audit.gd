extends SceneTree
var replacements:Dictionary={}
var changes:int=0
var embedded_replacements:int=0
var seen:Dictionary={}
var texture_records:Dictionary={}
var errors:Array=[]
var mesh_hashes:Dictionary={}
var scene_name:String=""
var rewrite:bool=true
func _initialize():run.call_deferred()
func hash_bytes(bytes:PackedByteArray)->String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
func translated(value:String)->String:
	for a in replacements:value=value.replace(a,replacements[a])
	return value
func resource_scan(value):
	if value is Resource:
		if seen.has(value.get_instance_id()):return
		seen[value.get_instance_id()]=true
		if value is ImageTexture:
			var key:String=scene_name+"::"+value.resource_path
			if rewrite and scene_name=="far.scn":
				var img:=Image.load_from_file(ProjectSettings.globalize_path("res://assets/media/portrait_01.jpg"))
				img.resize(roundi(512.0*img.get_width()/img.get_height()),512,Image.INTERPOLATE_LANCZOS);img.generate_mipmaps()
				value.set_image(img);changes+=1;embedded_replacements+=1
			var img:Image=value.get_image()
			texture_records[key]={"type":value.get_class(),"size":img.get_size(),"sha256_pixels":hash_bytes(img.get_data())}
			if scene_name!="far.scn":errors.append("Unregistered embedded image: "+key)
		elif value is Texture2D:
			texture_records[value.resource_path]={"type":value.get_class(),"path":value.resource_path}
			if value.resource_path.is_empty():errors.append("Texture without origin: "+scene_name)
			return
		for prop in value.get_property_list():
			if int(prop.usage)&PROPERTY_USAGE_STORAGE:resource_scan(value.get(prop.name))
	elif value is Array:
		for v in value:resource_scan(v)
	elif value is Dictionary:
		for v in value.values():resource_scan(v)
func geometry(n:Node,d:Dictionary):
	var key:String=n.get_path()
	if n is MultiMeshInstance3D and n.multimesh!=null:
		assert(n.multimesh.instance_count==0 or not n.multimesh.buffer.is_empty())
		d[key]={"instances":n.multimesh.instance_count,"buffer":hash_bytes(n.multimesh.buffer.to_byte_array()),"transform":n.transform}
	if n is CollisionShape3D:d[key]={"transform":n.transform,"shape":var_to_str(n.shape.get("size")),"data":var_to_str(n.shape.get("data")),"disabled":n.disabled}
	if n is MeshInstance3D and n.mesh!=null and not n.mesh is TextMesh:
		var id:int=n.mesh.get_instance_id()
		if not mesh_hashes.has(id):
			var arrays:Array=[]
			for i in n.mesh.get_surface_count():arrays.append(hash_bytes(var_to_bytes(n.mesh.surface_get_arrays(i))))
			mesh_hashes[id]=arrays
		d[key]={"transform":n.transform,"surface_hashes":mesh_hashes[id]}
	for c in n.get_children():geometry(c,d)
func scan(n:Node):
	if n is Label3D and translated(n.text)!=n.text:n.text=translated(n.text);changes+=1
	if n is MeshInstance3D and n.mesh is TextMesh and translated(n.mesh.text)!=n.mesh.text:n.mesh.text=translated(n.mesh.text);changes+=1
	for prop in n.get_property_list():
		if int(prop.usage)&PROPERTY_USAGE_STORAGE:resource_scan(n.get(prop.name))
	for c in n.get_children():scan(c)
func run():
	if DisplayServer.get_name()=="headless":push_error("Real graphics backend required");quit(1);return
	rewrite=not "--audit-only" in OS.get_cmdline_user_args()
	replacements=JSON.parse_string(FileAccess.get_file_as_string("res://data/public_text_replacements.json"))
	var folder:String="res://assets/world/stream_precision160"
	var modified:Array=[];var checked:int=0
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".scn"):continue
		scene_name=file;seen.clear();mesh_hashes.clear()
		var path:String=folder+"/"+file
		var n:Node=load(path).instantiate();root.add_child(n);RenderingServer.force_sync()
		var before:Dictionary={};geometry(n,before)
		var old:int=changes;scan(n)
		if changes>old:
			if not rewrite:errors.append("Unsanitized text in "+file)
			else:
				var packed:=PackedScene.new();assert(packed.pack(n)==OK);assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS)==OK)
				var after:Dictionary={};geometry(n,after);assert(before==after)
				n.free();await process_frame
				n=ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate();root.add_child(n);RenderingServer.force_sync()
				var persisted:Dictionary={};geometry(n,persisted);assert(before==persisted)
				modified.append({"scene":file,"changes":changes-old,"geometry_collision_persisted_equal":true})
		n.free();checked+=1;await process_frame
		if checked%32==0:print("PUBLIC_SCENE_AUDIT ",checked)
	var manifest=load(folder+"/manifest.tres")
	if rewrite:
		for item in manifest.interactions:item.title=translated(str(item.title))
		for row in manifest.cells:row.bytes=FileAccess.get_file_as_bytes(row.path).size()
		manifest.source_hashes.erase("res://assets/materials/terrain_field110.bin")
		for i in 3:manifest.source_hashes["res://assets/materials/terrain_field110.part"+str(i)]=""
		for path in manifest.source_hashes:manifest.source_hashes[path]=FileAccess.get_sha256(path)
		manifest.authored_counts["public160_media"]={"scenes_checked":checked,"embedded_images_replaced":embedded_replacements,"geometry_collision_preserved":true}
		assert(ResourceSaver.save(manifest,folder+"/manifest.tres")==OK)
	var output:Dictionary={"passed":errors.is_empty(),"scenes":checked,"modified":modified,"embedded_replacements":embedded_replacements,"textures":texture_records,"errors":errors}
	var f:=FileAccess.open("res://reports/public_scene_"+("rewrite" if rewrite else "audit")+".json",FileAccess.WRITE);f.store_string(JSON.stringify(output,"\t"));f.close()
	print("PUBLIC_SCENES_COMPLETE ",JSON.stringify({"passed":errors.is_empty(),"scenes":checked,"modified":modified.size(),"embedded":embedded_replacements,"errors":errors}));quit(0 if errors.is_empty() else 1)
