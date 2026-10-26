extends RefCounted
var w
var b
func _init(world):w=world;b=w.b
func extend(h:Dictionary,p:Vector3,size:Vector2):
	var id:String=h.id
	if id not in ["Z09_B3","Z09_B5","Z09_B6"]:return
	var palace=load("res://scripts/palace_styles160.gd").new(w);var old:String=b.venue_context;b.venue_context="PALACE:"+id
	var top:float=4.75
	if id=="Z09_B5":
		top=10.0
		for x in [-3.9,3.9]:
			for z in [-3.9,3.9]:
				b.box(p+Vector3(x,7.2,z),Vector3(.42,5.4,.42),"854B3B",true,0,"wood");palace.bracket(p+Vector3(x,9.65,z),Basis.IDENTITY,"854B3B","B59C65",3)
		for sign in [-1,1]:
			b.box(p+Vector3(0,8.25,sign*2.7),Vector3(2.2,2.2,.16),"E7D9AD",false,0,"plaster")
			b.box(p+Vector3(.2,8.35,sign*2.8),Vector3(.08,.9,.08),"854B3B");b.box(p+Vector3(.3,8.1,sign*2.8),Vector3(.8,.08,.08),"854B3B")
		palace.roof_piece(id,p+Vector3.UP*top,Vector2(8.4,8.4),1.55,"","hip")
	elif id=="Z09_B6":
		# Cover only the rear pavilion; the original lower sunset terrace stays open.
		palace.roof_piece(id,p+Vector3(0,top,-size.y*.20),Vector2(size.x+1,size.y*.68+1),1.25,"","hard_gable")
	else:palace.roof_piece(id,p+Vector3.UP*top,size+Vector2.ONE,1.45,"","hard_gable")
	b.venue_context=old
	var records:Dictionary=w.get_meta("palace140_cliff_repairs",{});records[id]={"eave_y":p.y+top,"clock_posts_restored":4 if id=="Z09_B5" else 0,"clock_faces_restored":2 if id=="Z09_B5" else 0,"open_front_terrace":id=="Z09_B6","scope":"Retained base envelope; localized palace upper roof and original clock structure."};w.set_meta("palace140_cliff_repairs",records)
