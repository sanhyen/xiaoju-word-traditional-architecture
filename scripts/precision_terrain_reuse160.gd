extends RefCounted
## Reuse 0150's unchanged native terrain subtree and its original collider.
static func install(world):
	var manifest=load("res://assets/world/stream_precision160/manifest.tres")
	var cells:=0;var parts:=0;var trims:=0
	for row in manifest.cells:
		var cached:Node=load(row.path).instantiate()
		for node in cached.get_children():
			if node is MeshInstance3D and node.has_meta("stream_terrain") and not node.get_meta("terrain_partition110_part",false):
				node.owner=null
				for child in node.find_children("*","",true,false):child.owner=null
				cached.remove_child(node);world.add_child(node);world.terrain_chunks.append(node);cells+=1
				parts+=node.find_children("*","MeshInstance3D",true,false).size()
			elif node is MultiMeshInstance3D and node.multimesh!=null and node.multimesh.mesh is BoxMesh:
				# Preserve the two original roadcut trim modules by their full size and color.
				var mm:MultiMesh=node.multimesh;var selected:Array=[]
				for i in mm.instance_count:
					var t:Transform3D=mm.get_instance_transform(i);var s:Vector3=t.basis.get_scale().abs();var c:Color=mm.get_instance_color(i)
					var coping:bool=absf(s.x-.14)<.0001 and absf(s.y-.1)<.0001 and c.is_equal_approx(Color("999e8d"))
					var drain:bool=s.distance_to(Vector3(.16,.09,.028))<.0001 and c.is_equal_approx(Color("637064"))
					if coping or drain:selected.append(i)
				if not selected.is_empty():
					var copy:=MultiMesh.new();copy.transform_format=mm.transform_format;copy.use_colors=mm.use_colors;copy.use_custom_data=mm.use_custom_data;copy.mesh=mm.mesh;copy.instance_count=selected.size()
					for i in selected.size():copy.set_instance_transform(i,mm.get_instance_transform(selected[i]));copy.set_instance_color(i,mm.get_instance_color(selected[i]))
					var trim:MultiMeshInstance3D=node.duplicate();trim.multimesh=copy;trim.set_meta("precision160_terrain_trim_reuse",true);world.add_child(trim);trims+=selected.size()
		cached.free()
		if cells%32==0:print("PRECISION_TERRAIN_REUSE ",cells)
	assert(cells==manifest.cells.size())
	var rock:Dictionary=manifest.authored_counts.rock_faces_094
	world.terrain_art.rock_faces_094=rock.faces;world.terrain_art.rock_panels_094=rock.panels;world.terrain_art.rock_normals_094=rock.normal_faces;world.terrain_art.inward_normals_094=rock.inward_normals
	world.set_meta("precision160_cached_terrain",{"cells":cells,"parts":parts,"roadcut_trim_instances":trims,"original_collision":true,"source":"0150a native PackedScene subtrees"})
