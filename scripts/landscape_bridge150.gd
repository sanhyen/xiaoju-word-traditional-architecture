extends RefCounted
## A shared miter seam prevents the flat bridge slab from overhanging its approach ramp.
var replaced:=0
var sections:Array=[]
func apply(root:Node)->int:
	replaced=0;sections=[]
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/world_layout_bay_v1.json"))
	var road:Dictionary={}
	for item in config.roads:
		if item.id=="landscape150_sky_footbridge":road=item;break
	assert(not road.is_empty())
	var points:Array=[]
	for p in road.points:points.append(Vector3(p[0],p[1]+config.sea_y,p[2]))
	var sides:Array=[]
	for i in points.size()-1:
		var direction:Vector3=points[i+1]-points[i];sides.append(Vector3(-direction.z,0,direction.x).normalized())
	var cuts:Array=[];var half:float=(float(road.width)+.04)*.5
	for i in points.size():
		var side:Vector3=sides[0] if i==0 else sides[-1] if i==points.size()-1 else (sides[i-1]+sides[i]).normalized()
		if i>0 and i<points.size()-1:side*=1.0/side.dot(sides[i-1])
		cuts.append([points[i]+side*half+Vector3.UP*.12,points[i]-side*half+Vector3.UP*.12])
	for i in points.size()-1:
		sections.append({"center":(points[i]+points[i+1])*.5,"length":points[i].distance_to(points[i+1])+.6,"quad":[cuts[i][0],cuts[i][1],cuts[i+1][1],cuts[i+1][0]]})
	# Bury the approach edge in the existing ground instead of presenting a lip.
	var extension:Vector3=(points[1]-points[0]).normalized()*1.2
	sections[0].quad[0]-=extension;sections[0].quad[1]-=extension
	visit(root,Transform3D.IDENTITY)
	return replaced
func visit(node:Node,parent:Transform3D):
	var t:Transform3D=parent*node.transform if node is Node3D else parent
	if node is CollisionShape3D and node.get_parent() is StaticBody3D:
		for section in sections:
			if t.origin.distance_to(section.center)>.015:continue
			if node.shape is BoxShape3D and (absf(node.shape.size.z-section.length)>.015 or absf(node.shape.size.x-3.24)>.015):continue
			var vertices:=PackedVector3Array();var inverse:Transform3D=t.affine_inverse()
			for p in section.quad:vertices.append(inverse*p);vertices.append(inverse*(p-Vector3.UP*.24))
			var shape:=ConvexPolygonShape3D.new();shape.points=vertices;node.shape=shape;replaced+=1
	for child in node.get_children():visit(child,t)
