extends RefCounted
## Small streamed finishing pieces share near/far positions and never alter collision.
var roots:Array=[]
func attach(world):
	if world.streamer==null:return
	if world.streamer.far_root!=null:
		for cell in world.streamer.far_root.get_children():finish_cell(world,cell,true)
	for cell in world.streamer.loaded.values():finish_cell(world,cell,false)
func finish_cell(world,cell:Node,far:bool):
	if cell.get_meta("scenic130_runtime_finish",false):return
	cell.set_meta("scenic130_runtime_finish",true)
	var id:String=str(cell.name).trim_prefix("Far_").trim_prefix("Cell_")
	if id=="3_3":beacon(cell,Vector3(360,9.6,383),far)
	if id=="-1_5":
		var o:=Vector3(-21,8.8,481);var points:=PackedVector3Array([o+Vector3(-3.4,3.9,2.7),o+Vector3(3.4,4.6,2.7),o+Vector3(3.0,4.0,4.4),o+Vector3(-3.1,3.6,4.4)])
		polygon(cell,points,Color("D6D1B3"),true)
		var parts:Array=[];var center:=Vector3(-39,7.6,501)
		for i in 8:
			var a:float=i*TAU/8;var r:float=1.3 if i%2 else 2.35;var y:float=4.8+1.43*sqrt(1-pow(r/4.08,2))+.035;parts.append([Transform3D(Basis.IDENTITY.scaled(Vector3(.38,.09,.38)),center+Vector3(cos(a)*r,y,sin(a)*r)),Color("E8E1CA")])
		batch(cell,parts,far)
func batch(parent:Node,parts:Array,far:bool):
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;var mesh:=BoxMesh.new();mesh.size=Vector3.ONE;mm.mesh=mesh;mm.instance_count=parts.size()
	for i in parts.size():mm.set_instance_transform(i,parts[i][0]);mm.set_instance_color(i,parts[i][1])
	var node:=MultiMeshInstance3D.new();node.name="ScenicFinishing130";node.multimesh=mm;var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=.92;node.material_override=mat;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if far else GeometryInstance3D.SHADOW_CASTING_SETTING_ON;parent.add_child(node)
func polygon(parent:Node,points:PackedVector3Array,tone:Color,two_sided:bool):
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,1,2,0,2,3]:st.add_vertex(points[i])
	st.generate_normals();var node:=MeshInstance3D.new();node.mesh=st.commit();var mat:=StandardMaterial3D.new();mat.albedo_color=tone;mat.roughness=.95;mat.cull_mode=BaseMaterial3D.CULL_DISABLED if two_sided else BaseMaterial3D.CULL_BACK;node.material_override=mat;parent.add_child(node)
func beacon(parent:Node,o:Vector3,far:bool):
	var parts:Array=[]
	for row in 4:
		var y:float=.9+row*1.8
		for side in [-1,1]:
			parts.append([Transform3D(Basis.IDENTITY.scaled(Vector3(.055,1,4.65)),o+Vector3(side*2.34,y,0)),Color("B96D64")])
			if side<0 or y>3.3:parts.append([Transform3D(Basis.IDENTITY.scaled(Vector3(4.65,1,.055)),o+Vector3(0,y,side*2.34)),Color("B96D64")])
			else:
				for x in [-1.98,1.98]:parts.append([Transform3D(Basis.IDENTITY.scaled(Vector3(.68,1,.055)),o+Vector3(x,y,2.34)),Color("B96D64")])
	batch(parent,parts,far)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 12:
		var a:float=i*TAU/12;var c:float=(i+1)*TAU/12
		for p in [o+Vector3(cos(a)*3.1,11.34,sin(a)*3.1),o+Vector3(0,12.4,0),o+Vector3(cos(c)*3.1,11.34,sin(c)*3.1)]:st.add_vertex(p)
	st.generate_normals();var roof:=MeshInstance3D.new();roof.mesh=st.commit();var mat:=StandardMaterial3D.new();mat.albedo_color=Color("373D41");mat.roughness=.88;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;roof.material_override=mat;roof.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if far else GeometryInstance3D.SHADOW_CASTING_SETTING_ON;parent.add_child(roof)
