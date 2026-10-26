extends RefCounted
## Authored curved/openwork meshes. Existing collision and interaction anchors remain authoritative.
static var meshes:Dictionary={}
static var materials:Dictionary={}
static var columns:Dictionary={}
var w
var owner_id:String=""
func _init(world,id:String=""):
	w=world;owner_id=id
static func load_library():
	if not meshes.is_empty():return
	var scene:Node=load("res://assets/craft160/models/precision_library.glb").instantiate()
	for node in scene.find_children("*","MeshInstance3D",true,false):
		meshes[str(node.name)]=node.mesh
		for surface in node.mesh.get_surface_count():
			var m:Material=node.mesh.surface_get_material(surface)
			if m!=null:materials[m.resource_name]=m
	scene.free()
	# glTF discards materials unused by the library's own triangles.
	if not materials.has("tile_dark"):
		var dark:StandardMaterial3D=materials.tile.duplicate();dark.albedo_color=Color("214d49");dark.roughness=.5;materials.tile_dark=dark
func mesh_node(mesh:Mesh,transform:Transform3D,role:String="joinery",far:bool=false)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=mesh;node.transform=transform
	node.set_meta("craft160",true);node.set_meta("craft160_owner",owner_id);node.set_meta("craft160_role",role)
	if far:node.set_meta("craft160_far",true)
	w.add_child(node)
	return node
func asset(name:String,p:Vector3,basis:Basis=Basis.IDENTITY)->MeshInstance3D:
	load_library()
	assert(meshes.has(name),"Missing authored precision mesh "+name)
	return mesh_node(meshes[name],Transform3D(basis,p),name)
func column(p:Vector3,height:float,radius:float=.16):
	load_library();asset("column_base",p,Basis.IDENTITY.scaled(Vector3(radius/.29,.8,radius/.29)))
	var key:String="%.3f:%.3f"%[height,radius]
	if not columns.has(key):
		var shape:=CylinderMesh.new();shape.bottom_radius=radius;shape.top_radius=radius*.84;shape.height=maxf(.2,height-.3);shape.radial_segments=24;shape.rings=1;shape.material=materials.red;columns[key]=shape
	var shaft:CylinderMesh=columns[key]
	mesh_node(shaft,Transform3D(Basis.IDENTITY,p+Vector3.UP*(.3+shaft.height*.5)),"column",true)
func painted_beam(p:Vector3,length:float,height:float,turn:Basis=Basis.IDENTITY):
	asset("paint_beam",p,turn.scaled_local(Vector3(length/3.0,height/.38,1)))
func roof_point(u:float,v:float,side:float,width:float,depth:float,rise:float,form:String)->Vector3:
	var hx:float=width*.5;var hz:float=depth*.5
	var ridge:float=hx if form in ["hard_gable","hanging_gable"] else maxf(.12,hx-hz*.72)
	return Vector3((u*2-1)*lerpf(ridge,hx,v),rise*pow(1-v,1.75)+.28*pow(v,7)+.20*pow(v,4)*pow(absf(u*2-1),6),side*hz*v)
func grid_mesh(points:PackedVector3Array,nu:int,nv:int,mat:Material,reverse:bool=false)->ArrayMesh:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_smooth_group(0)
	for j in nv:
		for i in nu:
			var a:int=j*(nu+1)+i;var c:int=a+nu+1
			for ix in ([a,c,a+1,a+1,c,c+1] if not reverse else [a,a+1,c,a+1,c+1,c]):
				tool.set_uv(Vector2(points[ix].x,points[ix].z)*.35);tool.add_vertex(points[ix])
	tool.generate_normals();tool.set_material(mat)
	return tool.commit()
func batch(mesh:Mesh,transforms:Array,role:String):
	if transforms.is_empty():return
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=transforms.size()
	for i in transforms.size():mm.set_instance_transform(i,transforms[i])
	var node:=MultiMeshInstance3D.new();node.multimesh=mm;node.set_meta("craft160",true);node.set_meta("craft160_role",role);node.set_meta("craft160_owner",owner_id);w.add_child(node)
func roof(p:Vector3,size:Vector2,rise:float,form:String="hip",yaw:float=0):
	load_library()
	var turn:=Basis(Vector3.UP,yaw);var width:float=maxf(1,size.x);var depth:float=maxf(1,size.y)
	var tiles:Array=[];var ends:Array=[];var rafters:Array=[]
	var count:int=maxi(4,ceili(width/.28));var rows:int=maxi(3,ceili(sqrt(pow(depth*.5,2)+rise*rise)/.4))
	for side in [-1.0,1.0]:
		var points:=PackedVector3Array();var underside:=PackedVector3Array()
		for j in 25:
			for i in 33:
				var q:Vector3=roof_point(float(i)/32,float(j)/24,side,width,depth,rise,form);points.append(q);underside.append(q-Vector3.UP*.14)
		mesh_node(grid_mesh(points,32,24,materials.tile_dark,side>0),Transform3D(turn,p),"roof_surface",true)
		mesh_node(grid_mesh(underside,32,24,materials.wood,side<0),Transform3D(turn,p),"roof_underside",true)
		for i in count+1:
			var u:float=float(i)/count
			for j in rows:
				var va:float=float(j)/rows;var vb:float=float(j+1)/rows
				var a:Vector3=roof_point(u,va,side,width,depth,rise,form);var c:Vector3=roof_point(u,vb,side,width,depth,rise,form)
				var forward:Vector3=(c-a).normalized();var right:=Vector3(side,0,0);var up:Vector3=forward.cross(right).normalized()
				var basis:=Basis(right,up,forward).scaled_local(Vector3(1,1,a.distance_to(c)/.42+0.03))
				tiles.append(Transform3D(turn*basis,p+turn*((a+c)*.5+Vector3.UP*.035)))
			var end:Vector3=roof_point(u,1,side,width,depth,rise,form)
			ends.append(Transform3D(turn*Basis(Vector3.UP,0 if side>0 else PI),p+turn*(end+Vector3(0,.055,side*.025))))
		for i in maxi(3,ceili(width/.46))+1:
			var u:float=float(i)/maxi(3,ceili(width/.46));var a:Vector3=roof_point(u,.62,side,width,depth,rise,form)-Vector3.UP*.23;var c:Vector3=roof_point(u,1,side,width,depth,rise,form)-Vector3.UP*.23
			var forward:Vector3=(c-a).normalized();var right:Vector3=Vector3.UP.cross(forward).normalized();var basis:=Basis(right,forward.cross(right),forward).scaled_local(Vector3(1,1,a.distance_to(c)))
			rafters.append(Transform3D(turn*basis,p+turn*a))
		painted_beam(p+turn*Vector3(0,.12,side*depth*.5),width,.18,turn)
	if form not in ["hard_gable","hanging_gable"]:
		var hx:float=width*.5;var hz:float=depth*.5;var ridge:float=maxf(.12,hx-hz*.72)
		for sx in [-1.0,1.0]:
			var points:=PackedVector3Array();var underside:=PackedVector3Array()
			for j in 25:
				for i in 25:
					var u:float=float(i)/24;var v:float=float(j)/24
					var q:=Vector3(sx*lerpf(ridge,hx,v),rise*pow(1-v,1.75)+.28*pow(v,7)+.20*pow(v,4)*pow(absf(u*2-1),6),(u*2-1)*hz*v)
					points.append(q);underside.append(q-Vector3.UP*.14)
			mesh_node(grid_mesh(points,24,24,materials.tile,sx<0),Transform3D(turn,p),"roof_hip_end",true)
			mesh_node(grid_mesh(underside,24,24,materials.wood,sx>0),Transform3D(turn,p),"roof_hip_under",true)
			# Cover the triangular hip faces as well as the two principal slopes.
			var hip_rows:int=maxi(3,ceili(sqrt(pow(hx-ridge,2)+rise*rise)/.4))
			for j in hip_rows:
				var va:float=float(j)/hip_rows;var vb:float=float(j+1)/hip_rows
				var strips:int=maxi(1,floori(depth*(va+vb)*.5/.28))
				for i in strips:
					var u:float=(float(i)+.5)/strips
					var a:Vector3=hip_point(u,va,sx,hx,hz,ridge,rise);var c:Vector3=hip_point(u,vb,sx,hx,hz,ridge,rise)
					var forward:Vector3=(c-a).normalized();var right:Vector3=Vector3.UP.cross(forward).normalized()
					var basis:=Basis(right,forward.cross(right).normalized(),forward).scaled_local(Vector3(1,1,a.distance_to(c)/.42+.03))
					tiles.append(Transform3D(turn*basis,p+turn*((a+c)*.5+Vector3.UP*.035)))
			var hip_ends:int=maxi(3,floori(depth/.28))
			for i in hip_ends:
				var end:Vector3=hip_point((float(i)+.5)/hip_ends,1,sx,hx,hz,ridge,rise)
				ends.append(Transform3D(turn*Basis(Vector3.UP,sx*PI*.5),p+turn*(end+Vector3(sx*.025,.055,0))))
	var ridge:float=width*.5 if form in ["hard_gable","hanging_gable"] else maxf(.12,width*.5-depth*.36)
	for sx in [-1.0,1.0]:
		asset("roof_finial",p+turn*Vector3(sx*ridge,rise+.1,0),turn*Basis(Vector3.UP,0 if sx>0 else PI))
		for sz in [-1.0,1.0]:asset("roof_finial",p+turn*roof_point(1 if sx>0 else 0,1,sz,width,depth,rise,form),turn*Basis(Vector3.UP,0 if sx>0 else PI))
	batch(meshes.tile_strip,tiles,"tile_strips");batch(meshes.tile_end,ends,"tile_ends");batch(meshes.rafter,rafters,"rafters")
func hip_point(u:float,v:float,sx:float,hx:float,hz:float,ridge:float,rise:float)->Vector3:
	return Vector3(sx*lerpf(ridge,hx,v),rise*pow(1-v,1.75)+.28*pow(v,7)+.20*pow(v,4)*pow(absf(u*2-1),6),(u*2-1)*hz*v)
func eaves(p:Vector3,width:float,depth:float):
	load_library();var tiles:Array=[];var ends:Array=[]
	for face in 4:
		var turn:=Basis(Vector3.UP,face*PI*.5);var span:float=width if face%2==0 else depth;var reach:float=depth if face%2==0 else width
		var points:=PackedVector3Array();var underside:=PackedVector3Array()
		for j in 13:
			for i in 65:
				var q:Vector3=eave_point(float(i)/64,float(j)/12,span,reach);points.append(q);underside.append(q-Vector3.UP*.12)
		mesh_node(grid_mesh(points,64,12,materials.tile,true),Transform3D(turn,p),"curved_floor_eave",true)
		mesh_node(grid_mesh(underside,64,12,materials.wood,false),Transform3D(turn,p),"curved_floor_eave_under",true)
		var count:int=ceili((span+4)/.28)
		for i in count+1:
			var u:float=float(i)/count
			for j in 8:
				var a:Vector3=eave_point(u,float(j)/8,span,reach);var c:Vector3=eave_point(u,float(j+1)/8,span,reach);var forward:Vector3=(c-a).normalized();var right:=Vector3.RIGHT;var basis:=Basis(right,forward.cross(right).normalized(),forward).scaled_local(Vector3(1,1,a.distance_to(c)/.42+.04))
				tiles.append(Transform3D(turn*basis,p+turn*((a+c)*.5+Vector3.UP*.035)))
			ends.append(Transform3D(turn,p+turn*(eave_point(u,1,span,reach)+Vector3(0,.055,.025))))
		painted_beam(p+turn*Vector3(0,4.72,reach*.5+1.9),span+4,.24,turn)
	batch(meshes.tile_strip,tiles,"tier_tiles");batch(meshes.tile_end,ends,"tier_tile_ends")
func eave_point(u:float,v:float,span:float,reach:float)->Vector3:
	return Vector3((u*2-1)*lerpf(span*.5-1.1,span*.5+2,v),4.6+.62*pow(1-v,1.3)+.22*pow(v,5),lerpf(reach*.5-1.1,reach*.5+2,v))
static func finish(world):
	# Merge only precision meshes after all existing placement rotations have completed.
	var batches:Dictionary={};var owners:Dictionary={};var source_nodes:Array=[]
	for node in world.get_children():
		if not node is GeometryInstance3D or not node.has_meta("craft160"):continue
		var use_far:bool=node.get_meta("craft160_far",false)
		var mesh:Mesh=node.mesh if node is MeshInstance3D else node.multimesh.mesh
		var transforms:Array=[]
		if node is MultiMeshInstance3D:
			for i in node.multimesh.instance_count:transforms.append(node.transform*node.multimesh.get_instance_transform(i))
		else:transforms.append(node.transform)
		for transform in transforms:
			var coord:=Vector2i(floori(transform.origin.x/96),floori(transform.origin.z/96));var key:String=str(coord)+":"+str(mesh.get_instance_id())
			key+=":"+str(use_far)+":"+str(node.get_meta("craft160_owner",""))
			if not batches.has(key):batches[key]={"mesh":mesh,"coord":coord,"transforms":[],"role":node.get_meta("craft160_role"),"far":use_far}
			batches[key].transforms.append(transform)
		var id:String=str(node.get_meta("craft160_owner",""));owners[id]=int(owners.get(id,0))+transforms.size();source_nodes.append(node)
	for row in batches.values():
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=row.mesh;mm.instance_count=row.transforms.size()
		for i in row.transforms.size():mm.set_instance_transform(i,row.transforms[i])
		var node:=MultiMeshInstance3D.new();node.multimesh=mm;node.set_meta("stream_cell",row.coord);node.set_meta("craft160",true);node.set_meta("craft160_role",row.role)
		if row.far:node.set_meta("craft160_far",true)
		world.add_child(node)
	for node in source_nodes:world.remove_child(node);node.free()
	world.set_meta("precision160_batches",{"groups":batches.size(),"authored_sources":source_nodes.size(),"instances_by_owner":owners})
