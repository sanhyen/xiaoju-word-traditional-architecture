extends RefCounted
## Clip each paving ribbon against the exact terrain triangles. No coarse diagonal can sink into grass.
var w
var counter:=0
func _init(world):w=world
func path(a:Vector2,c:Vector2,width:float,legacy_tone:String):
	var physical_width:float=width
	width=6.4 if width>=4.2 else 3.4 if width>=2.4 else clampf(width,1.2,2.0)
	w.reserve_path(a,c,width)
	var length:float=a.distance_to(c)
	if length<.01:return
	var side:=Vector2(-(c-a).y,(c-a).x).normalized();var broad:float=width*.5+.50
	var polygon:=PackedVector2Array([a+side*broad,c+side*broad,c-side*broad,a-side*broad])
	contact(polygon,a,c,width)
	# The original 0120 physical surface is reconstructed verbatim, independently of the finer paint.
	var local_garden:bool=a.distance_to(Vector2(-237,-169))<65 or c.distance_to(Vector2(-237,-169))<65
	var n:int=maxi(1,ceili(length/(1.0 if local_garden else 4.0)));var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var p:Vector2=a.lerp(c,float(i)/n);var q:Vector2=a.lerp(c,float(i+1)/n);var vertices:Array=[]
		for v in [p+side*physical_width*.5,p-side*physical_width*.5,q-side*physical_width*.5,q+side*physical_width*.5]:vertices.append(w.surface(v.x,v.y,.035))
		for j in [0,1,2,0,2,3]:st.add_vertex(vertices[j])
	var carrier:=MeshInstance3D.new();carrier.mesh=st.commit();w.add_child(carrier);carrier.create_trimesh_collision()
	for child in carrier.get_children().duplicate():child.reparent(w)
	w.remove_child(carrier);carrier.free()
	var report:Dictionary=w.get_meta("scenic130_roads",{"ribbons":0,"R1":0,"R2":0,"R3":0,"triangles":0,"offset_m":.045,"edge_transition_m":.5,"collision":"unchanged 0120 sampled collision"})
	report.ribbons+=1;report["R1" if width>=6 else "R2" if width>=3 else "R3"]+=1;w.set_meta("scenic130_roads",report)
	for endpoint in [a,c]:
		var id:String="%.2f_%.2f"%[endpoint.x,endpoint.y]
		if float(w.scenic_path_junctions.get(id,0))>=width:continue
		w.scenic_path_junctions[id]=width;var disc:=PackedVector2Array()
		for i in 12:disc.append(endpoint+Vector2(cos(i*TAU/12),sin(i*TAU/12))*(width*.5+.15))
		contact(disc,endpoint,endpoint,width)
func contact(poly:PackedVector2Array,a:Vector2,c:Vector2,width:float,elevation:Array=[]):
	var bounds:=Rect2(poly[0],Vector2.ZERO)
	for v in poly:bounds=bounds.expand(v)
	for x in range(floori(bounds.position.x/2),floori(bounds.end.x/2)+1):
		for z in range(floori(bounds.position.y/2),floori(bounds.end.y/2)+1):
			var p:=Vector2(x*2,z*2)
			for triangle in [PackedVector2Array([p,p+Vector2(2,0),p+Vector2(2,2)]),PackedVector2Array([p,p+Vector2(2,2),p+Vector2(0,2)])]:
				var pieces:Array[PackedVector2Array]=Geometry2D.intersect_polygons(poly,triangle)
				for piece in pieces:
					if piece.size()<3:continue
					var key:=Vector2i(floori((p.x+1)/96),floori((p.y+1)/96))
					if not w.scenic_path_builders.has(key):
						var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);w.scenic_path_builders[key]=tool
					var tool:SurfaceTool=w.scenic_path_builders[key]
					var indices:PackedInt32Array=Geometry2D.triangulate_polygon(piece)
					for idx in indices:
						var v:Vector2=piece[idx];var nearest:Vector2=Geometry2D.get_closest_point_to_segment(v,a,c);var across:float=v.distance_to(nearest)
						var edge:float=smoothstep(width*.5-.10,width*.5+.5,across);var data:Dictionary=load("res://scripts/scenic_biomes130.gd").biome(v)
						var tone:=Color(data.secondary).lerp(load("res://scripts/scenic_biomes130.gd").color_at(v),edge)
						var at:Vector3=w.surface(v.x,v.y,.045)
						if not elevation.is_empty():
							var t:float=clampf((nearest-a).dot(c-a)/maxf(.001,(c-a).length_squared()),0,1);at.y=maxf(at.y,lerpf(float(elevation[0]),float(elevation[1]),t)+.015)*(1-edge)+at.y*edge
						tool.set_color(tone);tool.set_normal(Vector3.UP);tool.add_vertex(at)
func flush():
	var shader:Shader=load("res://assets/materials/path_paving_079.gdshader");var triangles:=0
	for cell in w.scenic_path_builders:
		var tool:SurfaceTool=w.scenic_path_builders[cell];var mesh:ArrayMesh=tool.commit()
		if mesh==null:continue
		var node:=MeshInstance3D.new();node.name="ContinuousRibbon130";node.mesh=mesh;node.set_meta("stream_cell",cell);node.set_meta("scenic130_road",true)
		var material:=ShaderMaterial.new();material.shader=shader;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;w.add_child(node)
		triangles+=mesh.surface_get_array_len(0)/3
	w.scenic_path_builders.clear();var report:Dictionary=w.get_meta("scenic130_roads",{});report.triangles=triangles;report.junctions=w.scenic_path_junctions.size();w.set_meta("scenic130_roads",report)
