extends RefCounted
static func fingerprint()->Dictionary:
	var scene=load("res://assets/craft160/models/precision_library.glb").instantiate()
	var records:Dictionary={}
	for node in scene.find_children("*","MeshInstance3D",true,false):
		var hashes:Array=[]
		for i in node.mesh.get_surface_count():
			var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(var_to_bytes(node.mesh.surface_get_arrays(i)));hashes.append(hash.finish().hex_encode())
		records[str(node.name)]={"transform":var_to_str(node.transform),"surfaces":hashes}
	scene.free();return records
