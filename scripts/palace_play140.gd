extends Node3D
## References always point to original works. Public contributions never become inventory copies.
const Models=preload("res://scripts/creative_models110.gd")
const Biomes=preload("res://scripts/scenic_biomes130.gd")
var m
var models=Models.new()
var clock:=0.0
var initialized:=false
var boards:Dictionary={}
var props:Dictionary={}
var signature:=""
var submitting:=false
var combo:Node3D
var preview_choices:Dictionary={}
var curation_edit:Dictionary={}
var extension_readonly:=false
const JOBS=[["海湾点灯","coral_lamp","海湾波纹","Z02"],["林间来信","poem_journal","林间叶脉","ISLAND_02"],["小镇开幕","street_box","城郭窗纹","Z03"]]
const CARDS={
	"Z01":{"anchor":"B01","goal":"启程、取景、制作自己的第一张印片；也可直接自由游览。","topics":["daily"],"outputs":["photo_print","travel_frame"],"steps":["在宫式门殿领取旅行册，选择本次方向。","P 取景、F12 保存本机旅行照。","到摄影间裁切、冲印，再用 G 布置到自己的房间。"]},
	"Z02":{"anchor":"H01","goal":"沿岸拾物、制作海玻璃灯，为公共海湾点灯。","topics":["coral","azure_tide"],"outputs":["coral_lamp","drift_chime"],"steps":["在海岸和珊瑚岛寻找海玻璃与漂木。","完成镶嵌，制作独立海玻璃灯。","自愿提交海湾点灯；沿码头查看真实灯组变化。"]},
	"Z03":{"anchor":"B11","goal":"做封套、拼街景，把自己的作品送进开幕橱窗。","topics":["everyday","waiting"],"outputs":["everyday_cover","street_box"],"steps":["到留声间辨认房灯与街景，或为唱片排色。","自由选择配色、预览、制作。","小镇开幕提交的街景盒会在 B11 侧边橱窗留展。"]},
	"Z04":{"anchor":"B13","goal":"保留完整肖像取景，整理自己的旅行与公共贡献。","topics":["daily"],"outputs":["photo_print","travel_frame"],"steps":["中央肖像可直接观看，不要求先完成活动。","侧边旅行册按真实时间列出拍摄与作品。","查看三项公共贡献，标记其现场位置。"]},
	"Z05":{"anchor":"B10","goal":"比较灯组、垂幕和布景，保存自己的小舞台。","topics":["frost"],"outputs":["frost_light","mini_stage"],"steps":["在霜月舞台完成三联灯光操作。","在本页切换并预览三项现场设置。","选择保存，再到原座席观看原节目。"]},
	"Z06":{"anchor":"B05","goal":"选已有照片与作品，排成一次自己的旅行小展。","topics":["poem","blossom","daily"],"outputs":["poem_journal","flower_screen","photo_print"],"steps":["在书画藏影院选择真实拥有的作品与旅行照。","设定展题、顺序，预览后保存。","展廊引用原作品；取回、换展不会复制作品。"]},
	"Z07":{"anchor":"B12","goal":"为自己的小屋搭配阅读角、庭院或摄影墙。","topics":["blossom","castle"],"outputs":["flower_stand","castle_screen","paper_lamp"],"steps":["从已有独立作品中组合预览，不扣物品。","进入自己房间后查看原布置。","通过 G 逐件确认位置、旋转、取回；取消组合不动原档。"]},
	"Z08":{"anchor":"SUMMIT_TEA","goal":"步行或缆车登高，留下山海照片与木纹作品。","topics":["forest"],"outputs":["woodgrain_lamp","forest_print","star_bookmark"],"steps":["选择原步道或山脚缆车，两条路线都保留。","在山顶实际拍摄山海照片。","木纹灯、拓印可带回家；茶寮可自由停留。"]},
	"Z09":{"anchor":"Z09_B2","goal":"观察水闸、水轮与制作过程，保留原三级街巷。","topics":["castle"],"outputs":["legacy_pottery","glass_tile"],"steps":["在原水闸调节水线，观察实际轮速。","在陶艺坊选择器形、釉色，制作自己的陶器。","织机、晒架与原三层石街继续独立可用。"]},
	"AZURE":{"anchor":"AZURE_VIEW","goal":"八处宫苑各做一件不同的观察、调节或拼装。","topics":["azure_view","azure_light","azure_weave","azure_water","azure_glass","azure_tide","azure_model","azure_sail"],"outputs":["water_garden","glass_tile","bay_model","sail_flag"],"steps":["观景楼对准真实地标，折光馆调节三色片。","织染、调流、拼片、观鱼、造景、帆形分别操作。","每台装置保留自己的草稿、可见反馈与成品。"]},
	"CASTLE":{"anchor":"CASTLE_MAIN","goal":"登七层宫阁，做纸木、织染与三项公共贡献。","topics":["castle"],"outputs":["castle_table","castle_cushion","castle_screen","paper_lamp","flower_stand","woodbuckle_pack"],"steps":["主阁记录已经完成的旅程，不清空旧进度。","配院分别承担材料、纸木、织染和陈列。","自愿完成三项委托，随后去对应现场看结果。"]},
	"ISLAND_01":{"anchor":"ISLAND_LOBBY","goal":"沿岸步行、乘船或涉水取材，再回私人水榭陈列。","topics":["coral"],"outputs":["coral_lamp","drift_chime","tidal_pack"],"steps":["找齐原三处潮汐拾物线索。","在迎宾院镶嵌，制作灯、风铃或背包。","水屋甲板继续可布置，原上下岸点与船位保留。"]},
	"ISLAND_02":{"anchor":"FOREST_OBSERVATORY","goal":"记录三幅独立星图、森林拓印与可选来信。","topics":["forest","star"],"outputs":["woodgrain_lamp","forest_print","leaf_pack","poem_journal"],"steps":["找到三处木纹线索，观察原萤火节点。","三幅星图分别保留未完成的转盘状态。","可在原邮点写信；公共来信贡献不会自动发送邮件。"]},
	"CAPE":{"anchor":"LIGHTHOUSE","goal":"从真实灯塔位置辨认海岛方位并留下取景记录。","topics":[],"outputs":["travel_frame"],"steps":["登上原灯塔平台，面对山海地标。","在本页选择地标并核对当前镜头方位。","实际取景才进入旅行册，不按到站次数发奖励。"]},
	"CREEK":{"anchor":"CREEK_TEA","goal":"在溪谷茶亭停留，比较水轮、声音和取景。","topics":[],"outputs":["forest_print","legacy_fruit"],"steps":["沿原入口到溪岸水轮和茶座。","使用原茶饮、座位或摄影。","旅行册留下这里的真实照片，随时可再回来。"]}}

func setup(main):m=main
func data()->Dictionary:
	if not m.state.get("palace_play_v1") is Dictionary:m.state.palace_play_v1={}
	var d:Dictionary=m.state.palace_play_v1
	if (d.get("schema",1) is int or d.get("schema",1) is float) and int(d.get("schema",1))>1:extension_readonly=true;return d
	for key in ["world_projects","region_records","display_sets","scene_choices","onboarding","transaction_receipts"]:
		if not d.get(key) is Dictionary:
			if d.has(key):
				if not d.get("repairs140") is Array:d.repairs140=[]
				d.repairs140.append({"field":key,"original":d[key]})
			d[key]={}
	d.schema=1
	return d
func origin()->Dictionary:
	var r:Dictionary=Biomes.nearest_region(Vector2(m.player.position.x,m.player.position.z))
	return {"region":r.id,"at":Time.get_datetime_string_from_system(),"position":[m.player.position.x,m.player.position.y,m.player.position.z],"time":m.state.get("time",0),"weather":m.state.get("weather",0)}
func place(id:String)->Dictionary:
	for p in m.world.layout.creative_places:
		if str(p.id)==id:return p
	return {}
func vec(a:Array)->Vector3:return Vector3(a[0],a[1],a[2])
func initialize_state():
	cancel_combo();preview_choices.clear();curation_edit.clear();extension_readonly=false;data();initialized=not extension_readonly;signature=""
	if extension_readonly:m.notify("此档含更新版本的玩法数据，已完整保留。请用对应新版继续编辑公共贡献和展览。");return
	for index in 3:
		var old:Dictionary=m.creative.items.data().commissions.get(str(index),{})
		if int(old.get("runs",0))<=0 or data().world_projects.has(str(index)):continue
		var references:Array=[]
		for work in m.creative.items.data().works.values():
			if work.get("location","")=="commission:"+str(index):references.append(str(work.uid))
		references.sort_custom(func(a,b):
			var left:Dictionary=m.creative.items.data().works[a];var right:Dictionary=m.creative.items.data().works[b]
			return str(left.get("created",""))+str(a)<str(right.get("created",""))+str(b))
		data().world_projects[str(index)]={"completed":true,"uids":references,"active_uid":references.back() if not references.is_empty() else "","legacy":true,"runs":int(old.runs),"memorial_only":references.is_empty()}
	if not data().onboarding.has("choice"):
		data().onboarding.choice="returning" if not str(m.state.get("updated_at","")).is_empty() or not m.state.shots.is_empty() else "unselected"
	ensure_boards();apply_scene();refresh_world()
func ensure_boards():
	if not boards.is_empty():return
	for id in CARDS:
		var p:Dictionary=place(CARDS[id].anchor)
		if p.is_empty():continue
		var q:Vector3=vec(p.door)+Basis(Vector3.UP,float(p.get("door_yaw",0)))*Vector3(3.3,0,1.7)
		var node:=Node3D.new();add_child(node);node.position=q;node.rotation.y=float(p.get("door_yaw",0))
		models.box(node,Vector3(0,.88,0),Vector3(1.35,.95,.12),"854737")
		models.box(node,Vector3(0,.88,.075),Vector3(1.20,.80,.035),"E3D4B3")
		for x in [-.52,.52]:models.box(node,Vector3(x,.38,0),Vector3(.10,.76,.14),"854737")
		var label:=Label3D.new();label.font=m.font;label.text=region_name(id)+"\n旅行与手作 · E";label.font_size=30;label.pixel_size=.006;label.position=Vector3(0,.93,.11);label.modulate=Color("4F493B");node.add_child(label)
		boards[id]=node;m.world.interact("P140_BOARD_"+id,q,"旅行册 · "+region_name(id),"palace140",{"region":id})
func region_name(id:String)->String:
	for r in Biomes.spec.regions:
		if r.id==id:return r.name
	return id
func _process(delta:float):
	if m==null or not m.active_game or not initialized:return
	clock+=delta
	if clock<.5:return
	clock=0;refresh_world();apply_scene()
	if is_instance_valid(combo) and m.world.inside_building(m.player.position)!=str(combo.get_meta("owner","")):cancel_combo()
	for id in boards:boards[id].visible=boards[id].position.distance_to(m.player.position)<115
func handle_input(event)->bool:
	if not initialized:return false
	if not event is InputEventKey or not event.pressed or event.echo:return false
	if event.physical_keycode==KEY_J and m.active_game and not m.modal.visible:
		panel(str(Biomes.nearest_region(Vector2(m.player.position.x,m.player.position.z)).id));return true
	return false
func navigate(id:String):
	var p:Dictionary=place(id)
	if p.is_empty():return
	m.target_zone={"name":p.name,"x":p.door[0],"z":p.door[2],"safe":p.door.duplicate()};m.close_modal();m.notify("已标记 "+str(p.name)+"；保留自由路线。")
func lesson_runs(topic:String)->int:return int(m.creative.items.data().lessons.get(topic,{}).get("runs",0))
func panel(id:String):
	if extension_readonly:m.notify("更新版本的玩法数据完整保留，请用对应新版编辑。");return
	if not CARDS.has(id):return
	var card:Dictionary=CARDS[id];m.open_modal("旅行册 · "+region_name(id),1220)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1100,650);m.modal_box.add_child(scroll);var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	m.label(list,card.goal,25)
	for i in card.steps.size():m.label(list,str(i+1)+". "+str(card.steps[i]),21)
	var completed:=0
	for topic in card.topics:
		var runs:int=lesson_runs(topic)
		if runs>0:completed+=1
		m.label(list,("● " if runs>0 else "○ ")+str(m.creative.LESSON_NAMES.get(topic,"独立星图"))+" · 完成 "+str(runs)+" 次",20)
	var records:Array=data().region_records.get(id,[])
	m.label(list,"这里的真实旅行照："+str(records.size())+" 张 · 已完成活动 "+str(completed)+" / "+str(card.topics.size()),21)
	var row:=HBoxContainer.new();list.add_child(row)
	m.button(row,"标记本区起点",func():navigate(card.anchor));m.button(row,"查看旅行时间线",timeline);m.button(row,"全部十五区",region_index)
	if id=="Z01":
		m.button(list,"本次自由游览",func():choose_start("free"));m.button(list,"本次从照片与手作开始",func():choose_start("photo"));m.label(list,"当前选择："+str(data().onboarding.get("choice","unselected"))+"；随时可更换。",20)
	if id in ["Z02","Z03","Z04","CASTLE","ISLAND_02"]:m.button(list,"查看三项公共贡献",commissions)
	if id=="Z05":m.button(list,"灯组、垂幕与布景",stage_panel)
	if id=="Z06":m.button(list,"编排旅行小展",curation_panel)
	if id=="Z07":m.button(list,"已有作品组合预览",combo_panel)
	if id=="CAPE":m.button(list,"核对真实地标方向",bearing_panel)
	if id=="ISLAND_02":m.label(list,"独立星图记录："+str(m.bay.dual.island_data().star_records.size())+" / 3；切换星图不会覆盖另一幅草稿。",21)
	for topic in card.topics:
		var selected:String=topic
		m.button(list,"标记工作台 · "+str(m.creative.LESSON_NAMES.get(topic,"星图")),func():
			var p:Dictionary=m.workshop_feedback.topic_place(selected)
			if not p.is_empty():navigate(str(p.id)))
	var footer:=HBoxContainer.new();m.modal_box.add_child(footer);m.button(footer,"继续旅行",m.close_modal)
	if is_instance_valid(combo):m.button(footer,"撤回组合预览",cancel_combo)
func region_index():
	m.open_modal("十五区旅行方向",1180)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1050,640);m.modal_box.add_child(scroll);var list:=VBoxContainer.new();scroll.add_child(list)
	for id in CARDS:
		var selected:String=id;m.button(list,region_name(id)+" · "+str(CARDS[id].goal),func():panel(selected))
func choose_start(choice:String):
	var before:Dictionary=m.state.duplicate(true);data().onboarding.choice=choice
	if not persist(before):return
	if choice=="photo":navigate("THEME_DAILY")
	else:m.close_modal();m.notify("已选择自由游览。J 可随时打开旅行册。")
func persist(before:Dictionary)->bool:
	if m.save_game(false):signature="";return true
	m.state=before;m.creative.equipment_signature="";m.creative.placed_signature="";signature=""
	m.notify("保存失败，本次操作已撤回，作品与材料保持原状。请检查可写目录后重试。");return false
func record_photo(file:String):
	if not initialized:return
	var record:Dictionary=origin();record.file=file;var id:String=record.region
	if not data().region_records.get(id) is Array:data().region_records[id]=[]
	data().region_records[id].append(record)
func timeline():
	m.open_modal("自己的旅行时间线",1220);var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1100,650);m.modal_box.add_child(scroll);var list:=VBoxContainer.new();scroll.add_child(list)
	var records:Array=[]
	for region in data().region_records:
		for r in data().region_records[region]:records.append({"at":r.at,"text":r.at+" · "+region_name(region)+" · "+str(r.file)})
	for work in m.creative.items.data().works.values():
		var at:String=str(work.get("created",""));var source:Dictionary=work.get("origin",{});records.append({"at":at,"text":at+" · "+str(m.creative.items.defs.get(work.item,{}).get("name",work.item))+" · "+region_name(str(source.get("region","旧旅途，未记录取材区")))+" · "+str(work.uid)})
	records.sort_custom(func(a,b):return str(a.at)>str(b.at))
	for r in records.slice(0,180):m.label(list,r.text,20)
	if records.is_empty():m.label(list,"还没有本版旅行照或作品记录；原收藏、进度与节目均可直接使用。",23)
func commissions():
	if extension_readonly:m.notify("更新版本的玩法数据已保留，当前版本停止修改公共贡献。");return
	m.open_modal("三项可选公共贡献",1220)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1100,650);m.modal_box.add_child(scroll);var list:=VBoxContainer.new();scroll.add_child(list)
	for index in 3:
		var selected:int=index;var project:Dictionary=data().world_projects.get(str(index),{});var runs:int=int(m.creative.items.data().commissions.get(str(index),{}).get("runs",0))
		m.label(list,str(JOBS[index][0])+" · 已完成 "+str(runs)+" 次 · "+("保留旧完成纪念" if project.get("memorial_only",false) else "现场引用作品 "+str(project.get("active_uid","尚未提交"))),23)
		m.button(list,"选择背包中的作品提交 · "+str(JOBS[index][0]),func():commission_picker(selected))
		m.button(list,"查看或更换已提交展品",func():submitted_gallery(selected))
		m.button(list,"标记贡献现场",func():navigate_project(selected))
	m.label(list,"每次提交消耗所选独立作品，原规则赠木料、手作纸、纤维各 2。首次建立现场变化；重做只更新展品与原奖励，不重复建灯或自动寄信。",21)
func submitted_gallery(index:int):
	m.open_modal(str(JOBS[index][0])+" · 已提交作品",1220)
	var project:Dictionary=data().world_projects.get(str(index),{})
	for uid in project.get("uids",[]):
		var selected:String=uid;var work:Dictionary=m.creative.items.data().works.get(uid,{})
		if work.is_empty() or work.get("location","")!="commission:"+str(index):continue
		var row:=HBoxContainer.new();m.modal_box.add_child(row);m.label(row,str(work.created)+" · "+uid,21)
		var preview:Dictionary=work.duplicate(true);m.button(row,"查看原作品",func():m.creative.preview_work(preview,func():submitted_gallery(index)))
		m.button(row,"选为当前展品",func():var before:Dictionary=m.state.duplicate(true);data().world_projects[str(index)].active_uid=selected;if persist(before):refresh_world();m.notify("已更换原提交作品；没有取回或再次发奖。"))
	if index==1:
		var letters:Array=m.bay.dual.island_data().letters
		m.label(m.modal_box,"已有来信 "+str(letters.size())+" 封；缺照片时可查看原文字记录。",23)
		for letter in letters.slice(maxi(0,letters.size()-6)):
			var reference:Dictionary=letter.duplicate(true);m.button(m.modal_box,"查看原来信 · "+str(letter.get("time","")),func():m.bay.dual.show_letter(reference))
	if project.get("memorial_only",false):m.label(m.modal_box,"旧旅途贡献已继承；没有可核对的提交 UID，保留完成纪念。",23)
func commission_picker(index:int):
	m.open_modal("选择提交 · "+str(JOBS[index][0]),1180)
	var owned:Array=m.creative.items.owned(str(JOBS[index][1]),true)
	if owned.is_empty():m.label(m.modal_box,"背包中没有所需作品。房间中已陈列的作品保留原位。",24)
	for work in owned:
		var uid:String=work.uid;m.button(m.modal_box,str(m.creative.items.defs[work.item].name)+" · "+uid+" · "+str(work.created),func():confirm_commission(index,uid))
func confirm_commission(index:int,uid:String):
	m.open_modal("确认提交 · "+str(JOBS[index][0]));m.label(m.modal_box,"提交 "+uid+" 后，作品会成为公共贡献，不能从橱窗取回。现场保留作品的原配色与制作记录。",24)
	m.button(m.modal_box,"确认提交并保存",func():
		if submit(index,uid):commissions())
	m.button(m.modal_box,"取消，保留作品",commissions)
func submit(index:int,uid:String)->bool:
	if submitting or index<0 or index>=3:return false
	var items=m.creative.items;var work:Dictionary=items.data().works.get(uid,{})
	if work.is_empty() or work.get("location","")!="bag" or work.get("item","")!=JOBS[index][1]:m.notify("作品已不在背包，未提交。请重新选择。");return false
	submitting=true;var before:Dictionary=m.state.duplicate(true)
	if not items.transfer(uid,"commission:"+str(index)):submitting=false;return false
	var history:Dictionary=items.data().commissions.get(str(index),{});history.runs=int(history.get("runs",0))+1;history.pattern=JOBS[index][2];items.data().commissions[str(index)]=history
	if not items.data().knowledge.get("unlocked_patterns") is Array:items.data().knowledge.unlocked_patterns=[]
	if history.pattern not in items.data().knowledge.unlocked_patterns:items.data().knowledge.unlocked_patterns.append(history.pattern)
	var project:Dictionary=data().world_projects.get(str(index),{"uids":[]})
	if not project.get("uids") is Array:project.uids=[]
	if uid not in project.uids:project.uids.append(uid)
	project.merge({"completed":true,"active_uid":uid,"runs":history.runs,"memorial_only":false,"at":Time.get_datetime_string_from_system()},true);data().world_projects[str(index)]=project
	for material in ["wood","paper","fiber"]:items.grant(material,2)
	data().transaction_receipts[uid]={"job":index,"reward":{"wood":2,"paper":2,"fiber":2},"at":project.at}
	var ok:bool=persist(before);submitting=false
	if ok:refresh_world();m.notify("贡献已保存；"+str(JOBS[index][0])+"的现场已更新。")
	return ok
func prop(key:String,at:Vector3)->Node3D:
	if props.has(key) and is_instance_valid(props[key]):return props[key]
	var root:=Node3D.new();root.name=key;add_child(root);root.position=at;props[key]=root;return root
func project_position(index:int)->Vector3:
	if index==0:
		var point:Vector3=m.world.surface(-52,m.world.layout.shore_z(-52)-10,.04);return point
	if index==1:
		for action in m.world.interactions:
			if str(action.id)=="FOREST_POSTCARD":return action.pos+Vector3(-.7,0,.9)
	var p:Dictionary=place("FOREST_LODGE" if index==1 else "B11")
	return vec(p.center)+Vector3(float(p.size[0])*.5+1.0,0,-float(p.size[1])*.22)
func navigate_project(index:int):
	var p:Vector3=project_position(index);m.target_zone={"name":JOBS[index][0],"x":p.x,"z":p.z,"safe":[p.x,p.y,p.z]};m.close_modal()
func clear_children(node:Node):
	for child in node.get_children():node.remove_child(child);child.queue_free()
func refresh_world():
	var state_key:String=JSON.stringify([data().world_projects,data().display_sets])
	if state_key==signature:
		for node in props.values():node.visible=node.position.distance_to(m.player.position)<130
		return
	signature=state_key
	for i in 3:
		var at:Vector3=project_position(i)
		var root:Node3D=prop("PublicContribution"+str(i),at);clear_children(root)
		var project:Dictionary=data().world_projects.get(str(i),{})
		if not project.get("completed",false):continue
		var uid:String=project.get("active_uid","");var work:Dictionary=m.creative.items.data().works.get(uid,{})
		if i==0:
			# One stable group, not eight new inventory lamps per visit or per submission.
			for j in 8:
				var tone:int=posmod(int(work.get("variant",{}).get("tone",0)),3);var x:float=(j-3.5)*2.5;var y:float=m.world.height_at(at.x+x,at.z)-at.y;var q:=Vector3(x,y,0);models.box(root,q+Vector3.UP*1.0,Vector3(.12,2,.12),"854737");models.box(root,q+Vector3.UP*1.85,Vector3(.5,.65,.5),["AAD6CC","D6AEC5","E1C68E"][tone],0,true)
				if j%2==0:
					var lamp:=OmniLight3D.new();root.add_child(lamp);lamp.position=q+Vector3.UP*1.8;lamp.light_color=Color(["AAD6CC","D6AEC5","E1C68E"][tone]);lamp.light_energy=.6;lamp.omni_range=5;lamp.shadow_enabled=false
		else:
			var width:float=.65 if i==1 else 2.2;models.box(root,Vector3(0,.45,0),Vector3(width,.9,.55 if i==1 else 1.0),"80523D");models.box(root,Vector3(0,1.3,-.25 if i==1 else -.44),Vector3(width,.85,.10),"DDD0B5")
		if not work.is_empty() and work.get("location","")=="commission:"+str(i):
			var actual:Node3D=models.make(str(work.item),m.creative.canonical_variant(work));root.add_child(actual);actual.position=Vector3(0,1.0,.12)
		var label:=Label3D.new();label.font=m.font;label.text=str(JOBS[i][0])+"\n"+(uid if not work.is_empty() else "旧旅途贡献纪念");label.font_size=28;label.pixel_size=.006;label.position=Vector3(0,2.65,0);root.add_child(label)
	refresh_exhibition()
	for node in props.values():node.visible=node.position.distance_to(m.player.position)<130
func curation()->Dictionary:
	if not data().display_sets.get("travel") is Dictionary:data().display_sets.travel={"title":"我的山海旅行","uids":[],"photos":[]}
	return data().display_sets.travel
func curation_panel():
	if curation_edit.is_empty():curation_edit=curation().duplicate(true)
	m.open_modal("旅行小展 · 先预览，再确认展出",1220);var exhibit:Dictionary=curation_edit;var edit:=LineEdit.new();edit.text=str(exhibit.title);edit.placeholder_text="展览标题";edit.text_changed.connect(func(text):curation_edit.title=text.left(40));m.modal_box.add_child(edit)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(1100,420);m.modal_box.add_child(scroll);var list:=VBoxContainer.new();scroll.add_child(list)
	for index in exhibit.uids.size():
		var selected:int=index;var uid:String=exhibit.uids[index];var work:Dictionary=m.creative.items.data().works.get(uid,{})
		var row:=HBoxContainer.new();list.add_child(row);m.label(row,str(index+1)+". "+str(m.creative.items.defs.get(work.get("item",""),{}).get("name","引用失效"))+" · "+uid,21)
		m.button(row,"上移",func():move_exhibit(selected,-1));m.button(row,"下移",func():move_exhibit(selected,1));m.button(row,"撤下引用",func():curation_edit.uids.remove_at(selected);curation_panel())
		if not work.is_empty():
			var preview:Dictionary=work.duplicate(true);m.button(row,"实物预览",func():m.creative.preview_work(preview,curation_panel))
	for work in m.creative.items.data().works.values():
		if work.get("location","") not in ["bag","placed"] or work.uid in exhibit.uids:continue
		var uid:String=work.uid;m.button(list,"加入作品 · "+str(m.creative.items.defs.get(work.item,{}).get("name",work.item))+" · "+uid,func():toggle_exhibit(uid))
	for shot in m.state.shots:
		var filename:String=str(shot);m.button(list,("撤下照片 · " if filename in exhibit.photos else "加入照片 · ")+filename,func():toggle_photo(filename))
	var footer:=HBoxContainer.new();m.modal_box.add_child(footer);m.button(footer,"确认展出并保存",save_exhibition);m.button(footer,"取消本次编辑",func():curation_edit.clear();m.close_modal());m.button(footer,"标记展廊现场",func():navigate("B05"));m.label(m.modal_box,"最多 6 件作品、6 张本机照片。确认前现场保持原展览；展出只引用原作品，不改变其位置与库存。",20)
func save_exhibition()->bool:
	if curation_edit.is_empty():return false
	var before:Dictionary=m.state.duplicate(true);data().display_sets.travel=curation_edit.duplicate(true)
	var ok:bool=persist(before)
	if ok:curation_edit.clear();refresh_world();m.notify("旅行小展已保存并展出。")
	return ok
func toggle_exhibit(uid:String)->bool:
	var work:Dictionary=m.creative.items.data().works.get(uid,{})
	if curation_edit.is_empty():curation_edit=curation().duplicate(true)
	if work.is_empty() or work.get("location","") not in ["bag","placed"] or curation_edit.uids.size()>=6:return false
	if uid not in curation_edit.uids:curation_edit.uids.append(uid)
	curation_panel();return true
func toggle_photo(file:String):
	if file not in m.state.shots:return
	if curation_edit.is_empty():curation_edit=curation().duplicate(true)
	if file in curation_edit.photos:curation_edit.photos.erase(file)
	elif curation_edit.photos.size()<6:curation_edit.photos.append(file)
	curation_panel()
func move_exhibit(index:int,delta:int):
	var ids:Array=curation_edit.uids;var target:int=index+delta
	if target<0 or target>=ids.size():return
	var uid=ids[index];ids[index]=ids[target];ids[target]=uid;curation_panel()
func refresh_exhibition():
	var p:Dictionary=place("B05");var root:Node3D=prop("TravelExhibition",vec(p.center)+Vector3(0,0,-float(p.size[1])*.5-.42));clear_children(root)
	var exhibit:Dictionary=curation();var index:=0
	for uid in exhibit.uids:
		var work:Dictionary=m.creative.items.data().works.get(uid,{})
		if work.is_empty() or work.get("location","") not in ["bag","placed"]:continue
		var actual:Node3D=models.make(str(work.item),m.creative.canonical_variant(work));root.add_child(actual);actual.position=Vector3((index-2.5)*2.2,1.0,0);index+=1
	for i in exhibit.photos.size():
		var frame:Node3D=models.make("travel_frame",{"file":m.photo_directory()+"/"+str(exhibit.photos[i]).get_file()});root.add_child(frame);frame.position=Vector3((i-2.5)*2.2,2.4,0)
	var title:=Label3D.new();title.font=m.font;title.text=str(exhibit.title);title.font_size=40;title.pixel_size=.007;title.position=Vector3(0,3.8,0);root.add_child(title)
func stage()->Dictionary:
	if not data().scene_choices.get("B10") is Dictionary:data().scene_choices.B10={"lighting":0,"curtain":0,"scenery":0}
	for key in ["lighting","curtain","scenery"]:data().scene_choices.B10[key]=clampi(int(data().scene_choices.B10.get(key,0)),0,2)
	return data().scene_choices.B10
func stage_panel():
	m.bay.light_show=false
	m.open_modal("宫式戏楼 · 灯组、垂幕与布景",1180);var choice:Dictionary=stage();preview_choices=choice.duplicate(true)
	for key in ["lighting","curtain","scenery"]:
		var selected:String=key;var row:=HBoxContainer.new();m.modal_box.add_child(row);m.label(row,{"lighting":"灯组","curtain":"垂幕","scenery":"布景"}[key],23)
		for value in 3:
			var number:int=value;m.button(row,{"lighting":"灯组","curtain":"垂幕","scenery":"布景"}[key]+" · "+["暖金","月紫","青蓝"][value],func():preview_choices[selected]=number;apply_scene())
	m.button(m.modal_box,"保存本次舞台配置",func():var before:Dictionary=m.state.duplicate(true);data().scene_choices.B10=preview_choices.duplicate(true);if persist(before):preview_choices.clear();m.notify("舞台三项配置已保存。"))
	m.button(m.modal_box,"撤回预览",func():preview_choices.clear();apply_scene();m.close_modal())
	m.button(m.modal_box,"原三段灯光编排",m.bay.show_form)
func set_stage_lighting(index:int):
	if extension_readonly:return
	var before:Dictionary=m.state.duplicate(true);stage().lighting=posmod(index,3);m.bay.light_show=false
	if persist(before):apply_scene()
func apply_scene():
	var choices:Dictionary=preview_choices if not preview_choices.is_empty() and m.modal.visible else stage()
	if not preview_choices.is_empty() and not m.modal.visible:preview_choices.clear()
	if not m.bay.light_show:m.world.set_venue_lighting("B10",int(choices.lighting))
	var p:Dictionary=place("B10");var root:Node3D=prop("StageBackdrop140",vec(p.center))
	var mark:String=JSON.stringify([choices.curtain,choices.scenery])
	if root.get_meta("choice","")==mark:return
	root.set_meta("choice",mark);clear_children(root)
	var colors:Array=["B99362","9575A4","769EAA"]
	for sign in [-1,1]:
		for i in 6:models.box(root,Vector3(sign*(12.2+i*.28),4.0,-8.40),Vector3(.26,7.6,.11),colors[int(choices.curtain)])
		for i in 3:models.box(root,Vector3(sign*(7.4+i*.9),2.45+i%2*.3,-11.4),Vector3(.65+int(choices.scenery)*.08,2.4+i%2*.6,.16),colors[int(choices.scenery)])
	root.set_meta("curtain_panels",12);root.set_meta("scenery_panels",6);root.set_meta("screen_clear_half_width",5.3)
func combo_panel():
	m.open_modal("自己的房间 · 组合预览",1180);m.label(m.modal_box,"从已有作品预览阅读角、庭院或摄影墙。预览只是临时影像，退出后消失；原布置和库存保持。",23)
	for row in [["阅读角",["castle_table","castle_cushion","paper_lamp"]],["庭院",["flower_stand","castle_screen","woodgrain_lamp"]],["摄影墙",["travel_frame","photo_print","flower_screen"]]]:
		var chosen:Array=row[1];m.button(m.modal_box,row[0]+" · 预览已有作品",func():preview_combo(chosen))
	m.button(m.modal_box,"撤回全部组合预览",cancel_combo);m.button(m.modal_box,"逐件选择真实摆放",func():cancel_combo();m.creative.open_bag())
func preview_combo(ids:Array)->bool:
	cancel_combo();var current:Dictionary={}
	for p in m.world.layout.creative_places:
		if p.get("private",false) and str(p.id)==m.world.inside_building(m.player.position):current=p;break
	if current.is_empty():m.notify("请先进入自己的小屋、水屋或树屋，再预览已有作品。");return false
	combo=Node3D.new();combo.name="TemporaryComposition140";add_child(combo);combo.position=Vector3(current.center[0],m.player.position.y+.08,current.center[2]);combo.set_meta("owner",str(current.id))
	var count:=0
	for id in ids:
		var owned:Array=m.creative.items.owned(str(id))
		if owned.is_empty():continue
		var work:Dictionary=owned[0];var node:Node3D=models.make(str(work.item),m.creative.canonical_variant(work));combo.add_child(node);node.position=Vector3((count-1)*1.8,0,0);count+=1
		for mesh in node.find_children("*","GeometryInstance3D",true,false):mesh.transparency=.55
	if count==0:cancel_combo();m.notify("尚未拥有这组作品；没有移动、扣除或新建物品。");return false
	m.close_modal();m.notify("组合影像已预览。J 可撤回，G 可逐件布置实际作品。");return true
func cancel_combo():
	if is_instance_valid(combo):combo.queue_free()
	combo=null
func bearing_panel():
	m.open_modal("灯塔观测 · 核对真实方位",1180)
	if m.player.position.distance_to(vec(place("LIGHTHOUSE").center))>30:m.label(m.modal_box,"先到灯塔平台，再核对当前镜头与地标方向。",24);m.button(m.modal_box,"标记灯塔",func():navigate("LIGHTHOUSE"));return
	var camera:Camera3D=m.get_viewport().get_camera_3d();var heading:Vector3=-camera.global_basis.z;heading.y=0
	for row in [["珊瑚岛","ISLAND_LOBBY"],["森屿","FOREST_OBSERVATORY"],["花霞主阁","CASTLE_MAIN"]]:
		var direction:Vector3=vec(place(row[1]).center)-m.player.position;direction.y=0;var error:float=rad_to_deg(absf(heading.signed_angle_to(direction,Vector3.UP)))
		m.label(m.modal_box,str(row[0])+" · 当前镜头偏差 %.1f°"%error+(" · 已对准，可退出拍摄" if error<12 else " · 转动镜头后重新核对"),24)
	m.button(m.modal_box,"返回平台取景",m.close_modal)
