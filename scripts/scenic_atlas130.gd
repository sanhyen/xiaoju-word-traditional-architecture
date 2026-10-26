extends RefCounted
func bake(w):
	var n:=512;var image:=Image.create(n,n,false,Image.FORMAT_RGB8);var bio=load("res://scripts/scenic_biomes130.gd")
	var samples:=PackedFloat32Array();samples.resize(n*n)
	for z in n:
		for x in n:
			var p:=Vector2(-672+1344.0*x/(n-1),-752+1504.0*z/(n-1));var h:float=w.height_at(p.x,p.y)
			if p.x< -640 or p.x>640 or p.y< -720 or p.y>720:h=-12.0
			samples[z*n+x]=h
	for z in n:
		for x in n:
			var p:=Vector2(-672+1344.0*x/(n-1),-752+1504.0*z/(n-1));var h:float=samples[z*n+x];var tone:Color
			if h< -2.15:tone=Color("86B9BF").lerp(Color("5F91A3"),smoothstep(2.15,10,-h))
			else:
				tone=bio.color_at(p).lightened(.20)
				var dx:float=samples[z*n+mini(n-1,x+1)]-samples[z*n+maxi(0,x-1)];var dz:float=samples[mini(n-1,z+1)*n+x]-samples[maxi(0,z-1)*n+x]
				var normal:=Vector3(-dx,5.0,-dz).normalized();var light:float=.79+.21*normal.dot(Vector3(-.6,.75,-.6).normalized());tone=tone.darkened(1-light)
				if h>15 and fposmod(h,8)<.45:tone=tone.darkened(.06)
			image.set_pixel(x,z,tone)
	image.resize(2048,2048,Image.INTERPOLATE_LANCZOS);DirAccess.make_dir_recursive_absolute("res://assets/maps");image.save_png("res://assets/maps/scenic130_atlas.png")
	print("SCENIC_ATLAS ",JSON.stringify({"pixels":[2048,2048],"height_samples":samples.size(),"bounds":[-672,-752,1344,1504],"source":"actual authoritative terrain height and shared biome field","hillshade":"northwest light"}))
