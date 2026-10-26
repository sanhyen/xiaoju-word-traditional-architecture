extends RefCounted
## Only decorative rendering changes. Continuous roofs, posts and all physics stay.
static func apply(node:GeometryInstance3D):
	var role:String=node.get_meta("craft160_role","")
	var bounds:AABB=node.get_aabb()
	var radius:float=minf(32.0,bounds.size.length()*.5)
	if role in ["tile_strips","tile_ends","tier_tiles","tier_tile_ends"]:
		node.visibility_range_end=48.0+radius
		node.visibility_range_end_margin=6.0
		# A continuous roof casts the architectural shadow; tiny coplanar tiles
		# no longer repeat hundreds of thousands of triangles into shadow maps.
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	elif not node.get_meta("craft160_far",false):
		node.visibility_range_end=60.0+radius
		if role in ["table","round_table","chair","settee","daybed","bookcase","cabinet","vase","screen","coffer","caisson"]:
			node.visibility_range_end=38.0+radius
		node.visibility_range_end_margin=6.0
		if role in ["paint_beam","carved_panel","coffer","rafters","column_base","roof_finial","caisson"]:
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
