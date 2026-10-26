extends SceneTree
func _initialize():
	var records:Dictionary=load("res://scripts/precision_library_contract.gd").fingerprint()
	assert(records.size()==26)
	var f:=FileAccess.open("res://data/precision_library_contract.json",FileAccess.WRITE);f.store_string(JSON.stringify(records,"\t"));f.close();print("PRECISION_LIBRARY_CONTRACT ",records.size());quit()
