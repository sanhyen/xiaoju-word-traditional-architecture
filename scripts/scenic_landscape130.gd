extends RefCounted
var w
var b
var craft
var landmarks:Array=[]
func _init(world):w=world;b=w.b;craft=load("res://scripts/craft_components120.gd").new(w)
func build():
	load("res://scripts/scenic_paths130.gd").new(w).flush()
	coastal_skirt();distant_islands();landmark_set();wayside_scenes()
	w.set_meta("scenic130_landscape",{"landmarks":landmarks,"distant_islands":4,"coast_skirt":"Water fills omitted outer strips below the existing irregular shore. No extra playable land or collision.","wayside_scenes":18,"mountain_peaks":[[-350,-365],[-160,-410],[210,-370]],"mountain_pass":"preserved cable route between protected stations"})
func mesh(points:PackedVector3Array,colors:PackedColorArray,name:String)->MeshInstance3D:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size():tool.set_color(colors[i]);tool.add_vertex(points[i])
	tool.generate_normals();var node:=MeshInstance3D.new();node.name=name;node.mesh=tool.commit();var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.roughness=.96;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=mat;w.add_child(node);return node
func coastal_skirt():
	# The original ocean intentionally omitted the inland rectangle. Its outer
	# submerged terrain strips must also receive water, otherwise a square seabed
	# remains visible from above. Stay outside river channels and playable paths.
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rect in [Rect2(-480,-480,64,720),Rect2(416,-480,64,720),Rect2(-416,-480,832,64)]:
		for x in range(int(rect.position.x),int(rect.end.x),8):
			for z in range(int(rect.position.y),int(rect.end.y),8):
				var q:Array=[Vector3(x,-2.4,z),Vector3(x+8,-2.4,z),Vector3(x+8,-2.4,z+8),Vector3(x,-2.4,z+8)]
				for k in [0,1,2,0,2,3]:st.set_normal(Vector3.UP);st.add_vertex(q[k])
	var node:=MeshInstance3D.new();node.name="CoastalWaterContinuity130";node.mesh=st.commit();node.material_override=w.water_material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;w.add_child(node)
func distant_islands():
	for i in 4:
		var o:Vector3=[Vector3(-1060,-3,-180),Vector3(1080,-3,-260),Vector3(-750,-3,980),Vector3(910,-3,1050)][i];var points:=PackedVector3Array();var colors:=PackedColorArray()
		var radius:float=96+i*13;var h:float=38+i*14;var rings:Array=[]
		for level in 4:
			var ring:Array=[];var r:float=[1.0,.74,.42,.06][level]
			for j in 32:
				var a:float=j*TAU/32;var edge:float=1+.14*sin(a*3+i)+.08*cos(a*5)
				var y:float=[-1.5,h*.23,h*.65,h*.82][level]+h*.13*sin(a*2+i)*sin(level*PI/3)
				ring.append(o+Vector3(cos(a)*radius*r*edge-radius*.23*(1-r),y,sin(a)*radius*r*.67))
			rings.append(ring)
		for level in 3:
			for j in 32:
				var q:Array=[rings[level][j],rings[level][(j+1)%32],rings[level+1][(j+1)%32],rings[level+1][j]]
				for k in [0,1,2,0,2,3]:points.append(q[k]);colors.append(Color("7F9386").lerp(Color("A1A89B"),.2+.28*level) if level>0 else Color("899F94"))
		for j in 32:
			for p in [rings[3][j],rings[3][(j+1)%32],o+Vector3(-radius*.23,h*.84,0)]:points.append(p);colors.append(Color("9DA69A"))
		var node:MeshInstance3D=mesh(points,colors,"DistantIsland130_%d"%i);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func add_mark(id:String,p:Vector3,height:float):landmarks.append({"region":id,"position":p,"height":height,"far_geometry":true})
func windmill(p:Vector3,height:float,white:bool=false):
	for side in [-1,1]:b.beam(p+Vector3(side*2.2,0,0),p+Vector3(0,height-1,0),.50,"D6CBB0" if white else "9A7C55")
	b.box(p+Vector3.UP*(height-.8),Vector3(3.4,2.8,2.7),"E8DFCB",false,0,"plaster")
	var hub:=Node3D.new();hub.set_script(load("res://scripts/scenic_windmill130.gd"));hub.name="ScenicWindmill130";hub.position=p+Vector3(0,height,1.6);hub.set_meta("scenic_windmill",true);w.add_child(hub)
	for i in 4:
		var blade:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.55,height*.42,.14);blade.mesh=box;blade.material_override=b.material("F0E4CC");blade.position=Vector3(sin(i*PI*.5)*height*.23,cos(i*PI*.5)*height*.23,0);blade.rotation.z=-i*PI*.5;hub.add_child(blade)
func landmark_set():
	var station:=Vector3(309,3.6,250)
	for side in [-1,1]:b.box(station+Vector3(side*.9,7,0),Vector3(.25,14,.25),"5B7581",false,0,"metal")
	for y in [2,5,8,11]:b.beam(station+Vector3(-.9,y,0),station+Vector3(.9,y+2.2,0),.15,"7892A0")
	b.box(station+Vector3.UP*14.2,Vector3(2.7,1.5,1.1),"385D73",false,0,"metal");b.shape(station+Vector3(.55,14.2,.64),Vector3(.48,.48,.2),"B96962","cylinder");add_mark("Z01",station,15)
	var coast:Vector3=w.surface(28,280);windmill(coast,14,true);add_mark("Z02",coast,15)
	var street:Vector3=w.surface(-126,174)
	for side in [-1,1]:b.box(street+Vector3(side*6,3.2,0),Vector3(.7,6.4,.7),"E8D49A",false,0,"plaster")
	b.box(street+Vector3.UP*6.4,Vector3(13,.8,.8),"D9A9A3",false,0,"plaster");craft.sign("花 音 小 街",street+Vector3(0,6.4,.45),7);add_mark("Z03",street,7.4)
	add_mark("Z04",Vector3(0,4.1,40),20)
	var stage:=Vector3(-287,8.6,8);add_mark("Z05",stage,18)
	for side in [-1,1]:b.box(stage+Vector3(side*16,13,0),Vector3(.35,5,.35),"8C939B",false,0,"metal")
	b.beam(stage+Vector3(-16,15.4,0),stage+Vector3(16,15.4,0),.35,"8C939B")
	var chimney:Vector3=w.surface(204,-248);b.shape(chimney+Vector3.UP*9.5,Vector3(2.5,19,2.5),"9C6252","cylinder",0,"brick");b.shape(chimney+Vector3.UP*19,Vector3(3,.45,3),"4E5558","cylinder");add_mark("Z06",chimney,19.5)
	var farm:Vector3=w.surface(-282,-205);windmill(farm,16);add_mark("Z07",farm,17)
	add_mark("Z08",Vector3(-60,70.13,-358),17);add_mark("Z09",Vector3(255,21,-15),12);add_mark("AZURE",Vector3(193,29.2,-35),16);add_mark("CASTLE",Vector3(-112.5,7.4,10),40);add_mark("CAPE",Vector3(360,9.6,383),13)
	var giant:Vector3=w.surface(-100,488)
	var ecology=load("res://scripts/scenic_biomes130.gd").new()
	# This explicit giant is a landmark; its coarse crown is visible in the far scene.
	ecology.tree(b,giant,0,1.33,11);add_mark("ISLAND_02",giant,30)
func wayside_scenes():
	var points:Array=[Vector2(226,166),Vector2(104,165),Vector2(-2,208),Vector2(-183,147),Vector2(-237,108),Vector2(-304,-126),Vector2(-288,-261),Vector2(-134,-270),Vector2(25,-260),Vector2(125,-277),Vector2(287,-158),Vector2(303,-76),Vector2(371,104),Vector2(396,282),Vector2(-375,282),Vector2(80,278),Vector2(-74,463),Vector2(225,434)]
	for i in points.size():
		var p:Vector3=w.surface(points[i].x,points[i].y);var data:Dictionary=load("res://scripts/scenic_biomes130.gd").biome(points[i],p.y)
		match i%6:
			0:
				b.box(p+Vector3.UP*.42,Vector3(3,.18,.8),"B99A72",false,0,"wood");b.box(p+Vector3(2.3,1.1,0),Vector3(.7,1.0,.5),"B27865",false,0,"metal");b.box(p+Vector3(2.3,.4,0),Vector3(.15,.8,.15),"776350",false,0,"wood")
			1:
				for j in 5:b.shape(p+Vector3(cos(j*2.4)*2,.4,sin(j*2.4)*2),Vector3(1.2,.9,1),data.rock,"rock")
			2:load("res://scripts/scenic_styles130.gd").new(w).pergola(p,Vector2(3,2.5),"94775A",data.flower)
			3:
				for side in [-1,1]:b.box(p+Vector3(side*1.6,1.5,0),Vector3(.18,3,.18),"94775A",false,0,"wood")
				b.beam(p+Vector3(-1.6,3,0),p+Vector3(1.6,3,0),.18,"94775A");b.box(p+Vector3(0,1,0),Vector3(1.1,.16,.6),"B99A72",false,0,"wood")
			4:
				b.shape(p+Vector3.UP*.5,Vector3(2.0,1,2.0),data.rock,"cylinder");b.shape(p+Vector3.UP*.65,Vector3(1.4,.9,1.4),"769994","cylinder")
			5:
				b.box(p+Vector3.UP*.025,Vector3(3,.05,2.4),"B49A91",false,0,"fabric");b.shape(p+Vector3(.65,.25,.4),Vector3(.6,.45,.4),"B8996A","pot")
