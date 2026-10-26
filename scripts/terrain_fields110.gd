extends RefCounted
## One runtime-only numeric field texture shared by streamed terrain materials.
## Never call this from terrain authoring/baking: serialized cells must stay texture-free.

const DATA_PATH: String = "res://assets/materials/terrain_field110.bin"
const WIDTH: int = 6144
const HEIGHT: int = 6144
const EXPECTED_BYTES: int = WIDTH * HEIGHT * 2 * 2
const FIELD_BOUNDS: Vector4 = Vector4(-800.0, -800.0, 1600.0, 1600.0)

static var _load_attempted: bool = false
static var _load_attempts: int = 0
static var _shared_texture: ImageTexture = null
static var _successful_binds: int = 0
static var _state: Dictionary = {
	"attempted": false,
	"success": false,
	"status": "not_attempted",
	"path": DATA_PATH,
	"width": 0,
	"height": 0,
	"bytes": 0,
	"expected_bytes": EXPECTED_BYTES,
	"format": "RG16F / Image.FORMAT_RGH",
	"mipmaps": false,
	"headless": false,
}


static func bind(material: ShaderMaterial) -> bool:
	if material == null:
		return false
	# Missing/invalid data leaves the shader's analytic fallback enabled.
	material.set_shader_parameter("terrain_field_enabled110", false)
	_ensure_loaded()
	if _shared_texture == null:
		return false
	material.set_shader_parameter("terrain_field110", _shared_texture)
	material.set_shader_parameter("terrain_field_size110", Vector2(WIDTH, HEIGHT))
	material.set_shader_parameter("terrain_field_bounds110", FIELD_BOUNDS)
	material.set_shader_parameter("terrain_field_enabled110", true)
	_successful_binds += 1
	return true


static func diagnostics() -> Dictionary:
	var result: Dictionary = _state.duplicate(true)
	result["load_attempts"] = _load_attempts
	result["successful_binds"] = _successful_binds
	result["texture_ready"] = _shared_texture != null
	return result


static func _ensure_loaded() -> void:
	if _load_attempted:
		return
	_load_attempted = true
	_load_attempts += 1
	_state["attempted"] = true
	if DisplayServer.get_name() == "headless":
		_state["headless"] = true
		_state["status"] = "headless_analytic_fallback"
		return
	var data:=PackedByteArray()
	for i in 3:
		var path:String=DATA_PATH.replace(".bin",".part"+str(i))
		if not FileAccess.file_exists(path):
			_state["status"]="file_unavailable_analytic_fallback";return
		data.append_array(FileAccess.get_file_as_bytes(path))
	_state["bytes"]=data.size()
	if data.size() != EXPECTED_BYTES:
		_state["status"] = "short_read_analytic_fallback"
		_state["read_bytes"] = data.size()
		return
	var image: Image = Image.create_from_data(WIDTH, HEIGHT, false, Image.FORMAT_RGH, data)
	if image == null or image.is_empty():
		_state["status"] = "invalid_image_analytic_fallback"
		return
	if image.get_width() != WIDTH or image.get_height() != HEIGHT or image.get_format() != Image.FORMAT_RGH or image.has_mipmaps():
		_state["status"] = "invalid_image_contract_analytic_fallback"
		return
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	if texture == null or not texture.get_rid().is_valid():
		_state["status"] = "texture_unavailable_analytic_fallback"
		return
	_shared_texture = texture
	_state["width"] = image.get_width()
	_state["height"] = image.get_height()
	_state["success"] = true
	_state["status"] = "shared_runtime_texture_ready"
