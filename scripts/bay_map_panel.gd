extends RefCounted
var m
var map
var floor_plan
var search:LineEdit
var list:GridContainer
var detail:VBoxContainer
var directory_title:Label
var selected:Dictionary={}
var collapsed_regions:Dictionary={}
var region_initialized:=false
func build(main):
	m=main;m.open_modal("山海全景导览 · 建筑、双岛与云麓",1760)
	var panel:PanelContainer=m.modal_box.get_parent();panel.position=Vector2(80,32);panel.size=Vector2(1760,1016)
	var tools:=HBoxContainer.new();m.modal_box.add_child(tools)
	search=LineEdit.new();search.name="MapSearch110";search.placeholder_text="搜索中文名称、主题、船点或楼层 · 按区域、收藏或最近访问查找";search.custom_minimum_size=Vector2(940,42);search.add_theme_font_size_override("font_size",21);tools.add_child(search)
	m.button(tools,"返回全图",func():floor_plan.hide();map.reset_view();selected={};refresh_detail())
	m.button(tools,"我的附近",func():map.focus_region({"id":"附近","x":m.player.position.x,"z":m.player.position.z});refresh_list())
	m.label(m.modal_box,"滚轮放大依次展开建筑、名称与设施。远景只显示区域和地标；全部地点始终可在目录搜索。",18)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);m.modal_box.add_child(row)
	map=Control.new();map.set_script(preload("res://scripts/scenic_map130.gd"));map.name="VisitorMap106";map.spec=m.world.spec;map.layout_reference=m.world.layout;map.font=m.font;map.player_pos=m.player.position;map.yaw=m.player.yaw;map.target=m.target_zone;map.discovered=m.state.discovered;map.clues=m.state.activities.get("clues",[]);map.interaction_points=m.world.interactions;map.custom_minimum_size=Vector2(1050,650);map.clip_contents=true;row.add_child(map)
	var sidebar:=VBoxContainer.new();sidebar.custom_minimum_size=Vector2(600,650);sidebar.add_theme_constant_override("separation",6);row.add_child(sidebar)
	directory_title=m.label(sidebar,"地点目录 · 全部可查",20)
	var scroll:=ScrollContainer.new();scroll.name="AllMapLocations110";scroll.custom_minimum_size=Vector2(600,430);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;sidebar.add_child(scroll)
	list=GridContainer.new();list.name="MapDirectoryGrid110";list.columns=2;list.custom_minimum_size=Vector2(578,0);list.add_theme_constant_override("h_separation",6);list.add_theme_constant_override("v_separation",4);scroll.add_child(list)
	var detail_scroll:=ScrollContainer.new();detail_scroll.custom_minimum_size=Vector2(600,176);detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;sidebar.add_child(detail_scroll)
	detail=VBoxContainer.new();detail.custom_minimum_size=Vector2(578,0);detail.add_theme_constant_override("separation",5);detail_scroll.add_child(detail)
	floor_plan=preload("res://scripts/floor_plan120.gd").new();floor_plan.name="FloorPlan120";map.add_child(floor_plan);floor_plan.setup(m)
	map.destination.connect(choose);map.view_changed.connect(refresh_list);search.text_changed.connect(func(text):map.search_query=text;map.queue_redraw();refresh_list())
	m.label(m.modal_box,"图标区分住所、场馆、商店、餐饮、码头与车站。悬停查看名称；右键拖动；目录中的区域可折叠。",18)
	var routes:=HBoxContainer.new();m.modal_box.add_child(routes)
	for route in m.world.layout.config.tour_routes:
		var id:String=route.id;m.button(routes,route.name,func():m.bay.workshops.tour_panel(id))
	m.button(routes,"森屿旅行册",m.bay.dual.travel_book)
	refresh_list();refresh_detail()

func compact_button(button:Button,width:float=285):
	button.add_theme_font_size_override("font_size",16);button.custom_minimum_size=Vector2(width,29);button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	for state in ["normal","hover","pressed","focus"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("365c58") if state=="normal" else Color("4d7269") if state=="hover" else Color("294b49");style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=4;style.content_margin_bottom=4;style.corner_radius_top_left=3;style.corner_radius_bottom_right=3
		if state=="focus":style.draw_center=false;style.border_width_left=1;style.border_width_right=1;style.border_width_top=1;style.border_width_bottom=1;style.border_color=Color("bcd2bd")
		button.add_theme_stylebox_override(state,style)
func directory_rank(place:Dictionary)->int:
	if str(place.id) in ["B01","B02","B03","B04","B05","B06","B07","B08","B09","B10","B11","B12","B13"]:return 0
	if str(place.id).begins_with("THEME_") or str(place.id).begins_with("CASTLE_") or str(place.id).begins_with("AZURE_") or place.get("role","")=="cable":return 1
	if place.get("kind","")=="upper":return 6
	if place.get("kind","") in ["zone","island"]:return 4
	return 5 if map.secondary_point(place) else 2
func add_entry(parent:Node,place:Dictionary):
	var item:Dictionary=place;var button:Button=m.button(parent,map.short_name(place),func():
		selected=item;refresh_detail())
	compact_button(button);button.tooltip_text=map.clean_name(place)
func group_entries(title:String,id:String,entries:Array,folded:bool):
	var button:Button=m.button(list,("＋ " if folded else "－ ")+title+" · "+str(entries.size()),func():collapsed_regions[id]=not bool(collapsed_regions.get(id,false));refresh_list())
	compact_button(button,578)
	if folded:return
	var group:=GridContainer.new();group.columns=2;group.add_theme_constant_override("h_separation",6);group.add_theme_constant_override("v_separation",4);list.add_child(group)
	for place in entries:add_entry(group,place)
func refresh_list():
	if m.scenic!=null:m.scenic.defaults()
	for child in list.get_children():list.remove_child(child);child.queue_free()
	list.columns=1
	var query:String=search.text.strip_edges().to_lower();var all:Array=map.places().duplicate();var entries:Array=[]
	all.sort_custom(func(a,b):return map.short_name(a).naturalnocasecmp_to(map.short_name(b))<0)
	for place in all:
		if place.get("kind","")=="reserved":continue
		if not query.is_empty():
			if not query in (map.short_name(place)+map.clean_name(place)+str(place.get("subtitle",""))+str(place.id)).to_lower():continue
		elif place.get("kind","")=="upper":continue
		entries.append(place)
	if not query.is_empty():
		var results:=GridContainer.new();results.columns=2;results.add_theme_constant_override("h_separation",6);list.add_child(results)
		for place in entries:add_entry(results,place)
		directory_title.text="搜索结果 · "+str(entries.size())+"处（含楼层）";return
	var favorites:Array=[];var recent:Array=[]
	for id in m.state.get("map_favorites",[]):
		for place in all:
			if str(place.id)==str(id):favorites.append(place);break
	for id in m.state.get("map_recent",[]):
		for place in all:
			if str(place.id)==str(id):recent.append(place);break
	if not favorites.is_empty():group_entries("收藏","FAVORITES",favorites,bool(collapsed_regions.get("FAVORITES",false)))
	if not recent.is_empty():group_entries("最近去过（最多5处）","RECENT",recent,bool(collapsed_regions.get("RECENT",false)))
	var nearest:String=str(load("res://scripts/scenic_biomes130.gd").nearest_region(Vector2(m.player.position.x,m.player.position.z)).id)
	for region in load("res://scripts/scenic_biomes130.gd").spec.regions:
		var group:Array=[]
		for place in entries:
			if map.region_for(place)==str(region.id):group.append(place)
		if not region_initialized:collapsed_regions[str(region.id)]=str(region.id)!=nearest
		group_entries(str(region.name),str(region.id),group,bool(collapsed_regions.get(str(region.id),true)))
	region_initialized=true;directory_title.text="区域目录 · "+str(entries.size())+"地点 / "+str(all.size())+"条（含楼层）"

func choose(place:Dictionary):
	if place.has("region"):selected=place.region;refresh_detail();return
	if place.has("choices"):
		for child in detail.get_children():child.queue_free()
		m.label(detail,"选择地点与楼层",21)
		for item in place.choices:
			var choice:Dictionary=item;var choice_button:Button=m.button(detail,map.clean_name(choice),func():selected=choice;refresh_detail());compact_button(choice_button,570)
		return
	selected=place;refresh_detail()

func refresh_detail():
	for child in detail.get_children():detail.remove_child(child);child.queue_free()
	if selected.is_empty():m.label(detail,"选中地点后查看详情与楼层",20);m.label(detail,"展开区域或搜索名称；星标收藏和最近访问会随本版进度保存。",17);return
	if selected.get("kind","")=="cluster":
		m.label(detail,"附近地点 · 已展开详图",20);var group:=GridContainer.new();group.columns=2;group.add_theme_constant_override("h_separation",6);detail.add_child(group)
		for member in selected.get("members",[]):
			var choice:Dictionary=member;var choice_button:Button=m.button(group,map.short_name(choice),func():selected=choice;refresh_detail());compact_button(choice_button)
		return
	map.target=selected;map.queue_redraw();m.target_zone=selected
	m.label(detail,map.clean_name(selected),21)
	var description:Label=m.label(detail,str(selected.get("subtitle","已选定地点，可立即前往安全入口。")),16);description.max_lines_visible=2
	if selected.has("level"):m.label(detail,"楼层："+str(selected.level),18)
	if selected.get("private",false):m.label(detail,"私人住处 · 进入后可使用对应展示与生活功能",18)
	var chosen:Dictionary=selected
	if m.scenic!=null:m.scenic.defaults()
	var favorite:bool=str(chosen.id) in m.state.get("map_favorites",[])
	compact_button(m.button(detail,"取消收藏" if favorite else "☆ 收藏地点",func():
		if str(chosen.id) in m.state.map_favorites:m.state.map_favorites.erase(str(chosen.id))
		else:m.state.map_favorites.append(str(chosen.id))
		m.save_game(false);refresh_list();refresh_detail()),570)
	var plan_id:String=str(selected.get("parent",selected.id))
	if m.world.layout.creative_places.any(func(p):return str(p.id)==plan_id):compact_button(m.button(detail,"查看本层布局",func():floor_plan.open(chosen)),570)
	var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",6);detail.add_child(actions)
	var button:Button=m.button(actions,"立即前往",func():await m.teleport_zone(chosen);m.close_modal();m.save_game(false));button.disabled=not selected.get("enabled",true);compact_button(button)
	compact_button(m.button(actions,"标记并继续探索",func():m.target_zone=chosen;m.close_modal()))
	var floors:Array=[]
	for place in map.places():
		if place.get("kind","")!="upper":continue
		var parent:String=str(place.get("parent",""))
		if parent==str(selected.id) or str(place.id).begins_with(str(selected.id)+"_"):floors.append(place)
	if not floors.is_empty():
		m.label(detail,"楼层与附属廊",18)
		var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(578,72);detail.add_child(scroll);var box:=GridContainer.new();box.columns=2;box.custom_minimum_size.x=570;box.add_theme_constant_override("h_separation",6);scroll.add_child(box)
		for floor in floors:
			var landing:Dictionary=floor;var floor_button:Button=m.button(box,str(floor.get("level",map.clean_name(floor))),func():selected=landing;refresh_detail());compact_button(floor_button,280)
