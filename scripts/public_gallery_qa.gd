extends "res://scripts/precision160_qa.gd"
func run(main):
	m=main;qa_label="public_gallery"
	await m.start_game(false)
	m.set_time(0)
	var p:Dictionary=m.palace.place("CASTLE_MAIN");var o:Vector3=m.palace.vec(p.center)
	await capture("architecture",o+Vector3(78,39,105),o+Vector3.UP*23,o)
	var fields:Dictionary=load("res://scripts/terrain_fields110.gd").diagnostics()
	record("full_precision_terrain_loaded",fields.success and fields.bytes==150994944,fields)
	p=m.palace.place("B05");o=m.palace.vec(p.center);m.set_time(2)
	await capture("night",o+Vector3(14,5,23),o+Vector3.UP*3,o)
	var failures:Array=results.filter(func(r):return not r.ok)
	var f:=FileAccess.open(m.evidence_root+"reports/public_gallery.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":results,"poses":poses,"version":ProjectSettings.get_setting("application/config/version")},"\t"));f.close()
	print("PUBLIC_GALLERY_COMPLETE ",JSON.stringify({"passed":failures.is_empty(),"checks":results.size()}));m.get_tree().quit(0 if failures.is_empty() else 1)
