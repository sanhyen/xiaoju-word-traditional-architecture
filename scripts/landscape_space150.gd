extends RefCounted
## Shared bounds for terrain, map, material fields and scene generation.
const BOUNDS=Vector4(-640,-720,1280,1440)
const MAP=Rect2(-672,-752,1344,1504)
const CELLS=Rect2i(-7,-8,14,16)
static func outside_core(p:Vector2)->bool:return absf(p.x)>390 or p.y< -390
static func height(p:Vector2,original:float,sea:float)->float:
	var edge:float=maxf(absf(p.x)-390,-p.y-390)
	if edge<=0:return island_shores(p,original,sea)
	var blend:float=smoothstep(0,65,edge)
	var north:float=1.0-smoothstep(-520,-160,p.y)
	# The valley floor and side ridges have different axes and broad climbable shoulders.
	var h:float=8+60*north+4*sin(p.x*.014)*sin(p.y*.011)
	if p.y< -410:
		var valley:float=sin((p.y+440)*.011)*70-25
		h=53+12*(1.0-smoothstep(-655,-430,p.y))+5*sin(p.y*.017)
		h+=62*exp(-pow((p.x-valley-230)/130,2)-pow((p.y+570)/155,2))
		h+=46*exp(-pow((p.x-valley+280)/145,2)-pow((p.y+565)/125,2))
		h+=20*exp(-pow((p.x-470)/130,2)-pow((p.y+490)/145,2))
	elif p.x< -390:
		h+=12*exp(-pow((p.y+210)/140,2))+6*sin(p.y*.018)
	else:
		h+=18*exp(-pow((p.y+80)/240,2))+7*sin(p.y*.013)
	var coast:float=310+35*sin(p.x*.012)+22*cos(p.x*.024)
	h=lerpf(h,sea-10,smoothstep(coast-32,coast+58,p.y))
	var rim_fade:float=maxf(smoothstep(588,620,absf(p.x)+8*sin(p.y*.018)),smoothstep(668,700,-p.y+7*sin(p.x*.016)))
	h=lerpf(h,sea-12,rim_fade)
	return lerpf(original,h,blend)
static func island_shores(p:Vector2,h:float,sea:float)->float:
	# Small coves add to the islands' outward southern flanks, leaving all old routes and boat channels.
	for item in [[-70.0,546.0,45.0,25.0],[203.0,492.0,33.0,17.0]]:
		var r:float=Vector2((p.x-item[0])/item[2],(p.y-item[1])/item[3]).length()
		if r<1.5:h=maxf(h,sea+1.8-3.2*smoothstep(.25,1.5,r)+.15*sin(p.x*.17))
	return h
