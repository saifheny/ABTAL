class_name ParticlePool3D
extends Node3D

const POOL_SIZE := 26

var _mesh: SphereMesh
var _items: Array[Dictionary] = []
var _cursor: int = 0
var _mat_cache: Dictionary = {}


func _ready() -> void:
	_mesh = SphereMesh.new()
	_mesh.radius = 0.09
	_mesh.height = 0.18
	_mesh.radial_segments = 6
	_mesh.rings = 3
	for _i in range(POOL_SIZE):
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_items.append({
			"node": mi,
			"active": false,
			"vel": Vector3.ZERO,
			"t": 0.0,
			"dur": 0.28,
		})
	set_process(false)


func _get_mat(col: Color) -> StandardMaterial3D:
	var key := col.to_rgba32()
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_cache[key] = mat
	return mat


func spawn_burst(pos: Vector3, count: int, col: Color, radial_spread: float = 0.85, speed_y: float = 2.1, radial_ring: bool = false) -> void:
	if _items.is_empty():
		return
	var n := maxi(2, count / 2) if (OS.has_feature("mobile") or OS.has_feature("web")) else count
	var mat := _get_mat(col)
	for i in range(n):
		var entry: Dictionary = _items[_cursor]
		_cursor = (_cursor + 1) % POOL_SIZE
		var mi: MeshInstance3D = entry["node"]
		if not is_instance_valid(mi):
			continue
		mi.material_override = mat
		mi.position = pos + Vector3(randf_range(-0.12, 0.12), randf_range(0.0, 0.14), randf_range(-0.14, 0.14))
		mi.scale = Vector3.ONE * randf_range(0.75, 1.30)
		mi.visible = true
		var vel := Vector3.ZERO
		if radial_ring:
			var ang := (float(i) / float(maxi(1, n))) * TAU
			vel = Vector3(cos(ang) * 2.5, sin(ang) * 1.6 + speed_y, randf_range(-0.9, 0.9))
		else:
			vel = Vector3(randf_range(-radial_spread, radial_spread) * 2.2, randf_range(0.8, 2.4) * speed_y * 0.55, randf_range(-radial_spread, radial_spread) * 1.4)
		entry["vel"] = vel
		entry["t"] = 0.0
		entry["dur"] = 0.28
		entry["active"] = true
	set_process(true)


func clear_all() -> void:
	for entry in _items:
		entry["active"] = false
		var mi: MeshInstance3D = entry["node"]
		if is_instance_valid(mi):
			mi.visible = false
	set_process(false)


func _process(delta: float) -> void:
	var any_active := false
	for entry in _items:
		if not bool(entry["active"]):
			continue
		var mi: MeshInstance3D = entry["node"]
		if not is_instance_valid(mi):
			entry["active"] = false
			continue
		var t: float = float(entry["t"]) + delta
		var dur: float = float(entry["dur"])
		if t >= dur:
			entry["active"] = false
			mi.visible = false
			continue
		any_active = true
		entry["t"] = t
		var vel: Vector3 = entry["vel"]
		vel.y -= 5.8 * delta
		entry["vel"] = vel
		mi.position += vel * delta
		var k := 1.0 - (t / dur)
		var sc := maxf(0.05, k)
		mi.scale = Vector3(sc, sc, sc)
	if not any_active:
		set_process(false)
