extends Node
## Smooth local atmosphere, region arrival card and new map-memory fields.
var m
var card:Label
var card_time:=0.0
var tick:=0.0
var region:=""
var last_room:=""
var active_region:Dictionary={}
var height_fog:=false
var finishing=preload("res://scripts/scenic_runtime130.gd").new()
func setup(main):
	m=main;card=Label.new();card.name="ScenicRegionArrival130";card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);card.position=Vector2(-400,85);card.size=Vector2(800,95);card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_theme_font_size_override("font_size",30);card.add_theme_color_override("font_outline_color",Color("263D39"));card.add_theme_constant_override("outline_size",5);m.hud.add_child(card);card.hide()
	for property in m.environment.environment.get_property_list():
		if property.name=="fog_height_density":height_fog=true
func defaults():
	for key in ["map_favorites","map_recent"]:
		if not m.state.get(key) is Array:m.state[key]=[]
func visit(id:String):
	if id.is_empty():return
	defaults();m.state.map_recent.erase(id);m.state.map_recent.push_front(id)
	if m.state.map_recent.size()>5:m.state.map_recent.resize(5)
func _process(delta):
	if m==null or not m.active_game or m.player==null:return
	tick+=delta;card_time=maxf(0,card_time-delta)
	card.visible=card_time>0 and not m.modal.visible and not m.photo_mode;card.modulate.a=minf(1.0,card_time/.5)
	if tick>.25:
		tick=0;finishing.attach(m.world);active_region=load("res://scripts/scenic_biomes130.gd").nearest_region(Vector2(m.player.position.x,m.player.position.z))
		if str(active_region.id)!=region:
			region=str(active_region.id);card_time=2.5;var subtitle:String="山海之间，自有不同风景"
			for zone in m.world.spec.zones:
				if str(zone.id)==region:subtitle=str(zone.subtitle)
			card.text=str(active_region.name)+"\n"+subtitle
		var room:String=m.world.inside_building(m.player.position)
		if room!=last_room:
			last_room=room
			if not room.is_empty():visit(room)
	if active_region.is_empty():return
	var env:Environment=m.environment.environment;var active_camera:Camera3D=m.get_viewport().get_camera_3d();var distant:bool=(m.environment_controls!=null and m.environment_controls.overview) or (active_camera!=null and active_camera.global_position.y-m.player.position.y>280)
	var data:Dictionary=load("res://scripts/scenic_biomes130.gd").biome(Vector2(m.player.position.x,m.player.position.z),m.player.position.y)
	var time_index:int=int(m.state.time);var sky:Color=[Color("D6E8DF"),Color("EDC8A7"),Color("4A6275")][time_index]
	var target:Color=Color(data.fog).lerp(sky,.35 if time_index==0 else .75)
	var weather:int=int(m.state.get("weather",0));var begin:float=280 if distant else 120 if weather==0 else 90 if weather==1 else 55;var end:float=3600 if distant else 1150 if weather==0 else 900 if weather==1 else 680
	var factor:float=1-exp(-delta/.95);env.fog_light_color=env.fog_light_color.lerp(target,factor);env.fog_depth_begin=lerpf(env.fog_depth_begin,begin,factor);env.fog_depth_end=lerpf(env.fog_depth_end,end,factor)
	if distant:env.fog_depth_begin=300;env.fog_depth_end=4800
	if height_fog:
		env.set("fog_height",35.0 if data.landform=="block_ridge" else 6.0)
		env.set("fog_height_density",lerpf(float(env.get("fog_height_density")),.008 if data.landform in ["block_ridge","root_valley"] and not distant else 0.0,factor))
	var ambient:Color=Color(data.fog).lerp(Color("E7EDE0"),.8);env.ambient_light_color=env.ambient_light_color.lerp(ambient,factor*.4)
	if bool(m.state.get("scenic_dawn",false)):
		m.sun.light_color=Color("F4D4B1");m.sun.light_energy=.64;m.sun.rotation_degrees.x=-16;env.ambient_light_energy=.40
		var shader:ShaderMaterial=env.sky.sky_material;shader.set_shader_parameter("top_color",Color("9CB6C5"));shader.set_shader_parameter("horizon_color",Color("E7CDBB"));shader.set_shader_parameter("cloud_color",Color("F0DDCC"))
