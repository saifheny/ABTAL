class_name World3DBackdrop
extends Node3D

const LEVEL_LENGTH := 680.0

var world_env: WorldEnvironment
var env_res: Environment
var cam_attrs: CameraAttributesPractical
var sun_light: DirectionalLight3D
var _sky_mat: PanoramaSkyMaterial
var _meadow_mat: StandardMaterial3D
var _lawn_mat: StandardMaterial3D
var _water_mat: ShaderMaterial
var _clouds: Array[Node3D] = []
var _trees: Array[Node3D] = []
var _billboards: Array[CityBillboard3D] = []
var _hdr_day: Texture2D
var _hdr_sunset: Texture2D
var _cur_level: int = 1
var _cur_char_id: String = "haneen"


func _ready() -> void:
	_hdr_day = load("res://assets/hdri/kloofendal_48d_partly_cloudy_puresky_2k.hdr")
	_hdr_sunset = load("res://assets/hdri/belfast_sunset_puresky_2k.hdr")
	_build_environment_and_lights()
	_build_3d_park_and_nature()
	_build_3d_city_skyline_and_billboards()
	_build_3d_clouds()
	set_level_theme(1)


func _apply_cull_distance(root: Node, dist: float = 95.0) -> void:
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).visibility_range_end = dist
		(root as GeometryInstance3D).visibility_range_end_margin = 10.0
		(root as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in root.get_children():
		_apply_cull_distance(c, dist)


func _build_environment_and_lights() -> void:
	world_env = WorldEnvironment.new()
	env_res = Environment.new()
	env_res.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = PanoramaSkyMaterial.new()
	_sky_mat.panorama = _hdr_day
	_sky_mat.energy_multiplier = 1.05
	sky.sky_material = _sky_mat
	env_res.sky = sky
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_res.ambient_light_energy = 0.62
	env_res.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env_res.tonemap_mode = Environment.TONE_MAPPER_ACES
	# Disable bloom/glow glare ("ما يكونش فيه توهج يبوظ شكل اللعبة")
	env_res.glow_enabled = false
	env_res.fog_enabled = true
	env_res.fog_mode = Environment.FOG_MODE_DEPTH
	env_res.fog_light_color = Color(0.76, 0.87, 0.99)
	env_res.fog_depth_begin = 28.0
	env_res.fog_depth_end = 118.0
	env_res.fog_density = 0.16
	env_res.fog_sky_affect = 0.08
	world_env.environment = env_res

	cam_attrs = CameraAttributesPractical.new()
	cam_attrs.dof_blur_far_enabled = false
	cam_attrs.dof_blur_far_distance = 6.5
	cam_attrs.dof_blur_far_transition = 6.0
	cam_attrs.dof_blur_amount = 0.0
	world_env.camera_attributes = cam_attrs
	add_child(world_env)

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-42, 34, 0)
	sun_light.light_color = Color(1.0, 0.96, 0.90)
	sun_light.light_energy = 0.92
	sun_light.shadow_enabled = true
	sun_light.directional_shadow_max_distance = 36.0 if OS.has_feature("mobile") else 58.0
	add_child(sun_light)


func set_character_name(char_id: String) -> void:
	_cur_char_id = char_id
	var hero := Loc.hero_name(char_id)
	var msgs := [hero, Loc.t("bb_msg_1"), Loc.t("bb_msg_2")]
	for i in range(_billboards.size()):
		if is_instance_valid(_billboards[i]):
			_billboards[i].update_message(msgs[i % msgs.size()])


func set_level_theme(lvl: int) -> void:
	_cur_level = lvl
	if _sky_mat == null:
		return
	const THEMES := [
		{"sunset": false, "energy": 1.05, "sun_col": Color(1.0, 0.96, 0.90), "pitch": -42.0, "fog": Color(0.76, 0.87, 0.99), "meadow": Color(0.86, 0.94, 0.86), "lawn": Color(0.92, 1.0, 0.92), "ws": Color(0.10, 0.68, 0.90, 0.86), "wd": Color(0.04, 0.30, 0.62, 0.95)},
		{"sunset": true,  "energy": 1.15, "sun_col": Color(1.0, 0.82, 0.64), "pitch": -28.0, "fog": Color(0.95, 0.78, 0.64), "meadow": Color(0.92, 0.86, 0.76), "lawn": Color(0.95, 0.90, 0.80), "ws": Color(0.18, 0.56, 0.82, 0.86), "wd": Color(0.06, 0.24, 0.52, 0.95)},
		{"sunset": false, "energy": 0.98, "sun_col": Color(0.92, 0.98, 1.0),  "pitch": -36.0, "fog": Color(0.64, 0.86, 0.96), "meadow": Color(0.80, 0.92, 0.88), "lawn": Color(0.84, 0.96, 0.90), "ws": Color(0.06, 0.74, 0.90, 0.86), "wd": Color(0.02, 0.28, 0.58, 0.95)},
		{"sunset": false, "energy": 1.02, "sun_col": Color(0.96, 0.99, 0.88), "pitch": -40.0, "fog": Color(0.70, 0.88, 0.80), "meadow": Color(0.72, 0.90, 0.72), "lawn": Color(0.78, 0.96, 0.76), "ws": Color(0.08, 0.68, 0.76, 0.86), "wd": Color(0.03, 0.32, 0.48, 0.95)},
		{"sunset": true,  "energy": 1.10, "sun_col": Color(1.0, 0.76, 0.54), "pitch": -24.0, "fog": Color(0.96, 0.72, 0.52), "meadow": Color(0.94, 0.80, 0.62), "lawn": Color(0.98, 0.85, 0.66), "ws": Color(0.14, 0.62, 0.84, 0.86), "wd": Color(0.05, 0.28, 0.54, 0.95)},
		{"sunset": false, "energy": 0.94, "sun_col": Color(0.84, 0.93, 1.0),  "pitch": -34.0, "fog": Color(0.76, 0.88, 1.0),  "meadow": Color(0.86, 0.94, 1.0),  "lawn": Color(0.90, 0.96, 1.0),  "ws": Color(0.18, 0.78, 0.98, 0.86), "wd": Color(0.06, 0.36, 0.68, 0.95)},
		{"sunset": false, "energy": 0.92, "sun_col": Color(0.90, 0.94, 1.0),  "pitch": -38.0, "fog": Color(0.62, 0.74, 0.90), "meadow": Color(0.74, 0.82, 0.86), "lawn": Color(0.80, 0.88, 0.90), "ws": Color(0.05, 0.64, 0.86, 0.86), "wd": Color(0.02, 0.22, 0.52, 0.95)},
		{"sunset": false, "energy": 1.08, "sun_col": Color(0.96, 0.99, 0.96), "pitch": -44.0, "fog": Color(0.68, 0.90, 0.98), "meadow": Color(0.84, 0.94, 0.84), "lawn": Color(0.88, 0.98, 0.88), "ws": Color(0.04, 0.78, 0.92, 0.86), "wd": Color(0.02, 0.32, 0.64, 0.95)},
		{"sunset": true,  "energy": 1.18, "sun_col": Color(1.0, 0.88, 0.58), "pitch": -30.0, "fog": Color(0.98, 0.84, 0.62), "meadow": Color(0.96, 0.90, 0.72), "lawn": Color(1.0, 0.94, 0.78),  "ws": Color(0.12, 0.70, 0.90, 0.86), "wd": Color(0.04, 0.28, 0.58, 0.95)},
		{"sunset": true,  "energy": 1.20, "sun_col": Color(1.0, 0.90, 0.72), "pitch": -34.0, "fog": Color(0.92, 0.82, 0.96), "meadow": Color(0.88, 0.92, 0.88), "lawn": Color(0.94, 0.98, 0.92), "ws": Color(0.08, 0.76, 0.96, 0.86), "wd": Color(0.03, 0.30, 0.66, 0.95)},
		{"sunset": false, "energy": 1.12, "sun_col": Color(1.0, 0.93, 0.76), "pitch": -32.0, "fog": Color(0.94, 0.84, 0.66), "meadow": Color(0.96, 0.86, 0.64), "lawn": Color(0.98, 0.90, 0.70), "ws": Color(0.08, 0.74, 0.82, 0.86), "wd": Color(0.03, 0.32, 0.52, 0.95)},
		{"sunset": true,  "energy": 1.14, "sun_col": Color(1.0, 0.68, 0.44), "pitch": -22.0, "fog": Color(0.95, 0.66, 0.50), "meadow": Color(0.86, 0.72, 0.64), "lawn": Color(0.92, 0.78, 0.68), "ws": Color(0.22, 0.52, 0.78, 0.86), "wd": Color(0.08, 0.20, 0.48, 0.95)},
		{"sunset": false, "energy": 0.96, "sun_col": Color(0.86, 0.96, 1.0),  "pitch": -39.0, "fog": Color(0.78, 0.92, 1.0),  "meadow": Color(0.90, 0.96, 1.0),  "lawn": Color(0.95, 0.99, 1.0),  "ws": Color(0.14, 0.82, 0.98, 0.86), "wd": Color(0.05, 0.38, 0.74, 0.95)},
		{"sunset": true,  "energy": 1.16, "sun_col": Color(0.98, 0.80, 0.96), "pitch": -26.0, "fog": Color(0.84, 0.72, 0.94), "meadow": Color(0.80, 0.86, 0.92), "lawn": Color(0.86, 0.92, 0.96), "ws": Color(0.16, 0.64, 0.94, 0.86), "wd": Color(0.06, 0.24, 0.62, 0.95)},
		{"sunset": false, "energy": 1.06, "sun_col": Color(0.94, 1.0, 0.86),  "pitch": -43.0, "fog": Color(0.68, 0.90, 0.78), "meadow": Color(0.74, 0.92, 0.74), "lawn": Color(0.80, 0.98, 0.80), "ws": Color(0.04, 0.72, 0.74, 0.86), "wd": Color(0.02, 0.28, 0.48, 0.95)},
	]
	var idx := clampi(lvl - 1, 0, 29) % THEMES.size()
	var th: Dictionary = THEMES[idx]
	_sky_mat.panorama = _hdr_sunset if th["sunset"] else _hdr_day
	_sky_mat.energy_multiplier = th["energy"]
	sun_light.light_color = th["sun_col"]
	sun_light.rotation_degrees = Vector3(th["pitch"], 34.0, 0.0)
	env_res.fog_light_color = th["fog"]
	if _meadow_mat:
		_meadow_mat.albedo_color = th["meadow"]
		_lawn_mat.albedo_color = th["lawn"]
	if _water_mat:
		_water_mat.set_shader_parameter("shallow_color", th["ws"])
		_water_mat.set_shader_parameter("deep_color", th["wd"])


func set_intro_blur(amount: float, far_dist: float = 5.5) -> void:
	if cam_attrs == null:
		return
	if amount > 0.02:
		cam_attrs.dof_blur_far_enabled = true
		cam_attrs.dof_blur_far_distance = far_dist
		cam_attrs.dof_blur_far_transition = 5.0
		cam_attrs.dof_blur_amount = amount
	else:
		cam_attrs.dof_blur_far_enabled = false
		cam_attrs.dof_blur_amount = 0.0


func _build_3d_park_and_nature() -> void:
	# Real Poly Haven PBR Grass & Earth Ground Textures ("الأرض بجد")!
	var diff := load("res://assets/textures/ground/aerial_grass_rock_Diffuse.jpg")
	var norm := load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	var rough := load("res://assets/textures/ground/aerial_grass_rock_Rough.jpg")

	_meadow_mat = StandardMaterial3D.new()
	_meadow_mat.albedo_texture = diff
	_meadow_mat.albedo_color = Color(0.86, 0.94, 0.86)
	_meadow_mat.normal_enabled = true
	_meadow_mat.normal_texture = norm
	_meadow_mat.normal_scale = 1.2
	_meadow_mat.roughness_texture = rough
	_meadow_mat.uv1_scale = Vector3(85.0, 12.0, 1.0)

	var meadow := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(820.0, 140.0)
	meadow.mesh = pm
	meadow.material_override = _meadow_mat
	meadow.position = Vector3(325.0, -3.9, -4.0)
	add_child(meadow)

	# Solid subterranean earth wall below/ahead so sky NEVER peeks underneath the ground!
	var earth_skirt := MeshInstance3D.new()
	var esm := BoxMesh.new()
	esm.size = Vector3(820.0, 18.0, 90.0)
	earth_skirt.mesh = esm
	var earth_mat := StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.20, 0.14, 0.09)
	earth_mat.roughness = 0.92
	earth_skirt.material_override = earth_mat
	earth_skirt.position = Vector3(325.0, -13.0, 10.0)
	add_child(earth_skirt)

	_lawn_mat = _meadow_mat.duplicate()
	_lawn_mat.albedo_color = Color(0.92, 1.0, 0.92)
	_lawn_mat.uv1_scale = Vector3(110.0, 3.0, 1.0)
	var back_lawn := MeshInstance3D.new()
	var blm := BoxMesh.new()
	# Keep front bank behind z = -3.4 so stage water lagoons span freely in front without grass slicing them!
	blm.size = Vector3(800.0, 2.8, 16.0)
	back_lawn.mesh = blm
	back_lawn.material_override = _lawn_mat
	back_lawn.position = Vector3(325.0, -2.15, -11.4)
	add_child(back_lawn)

	# Realistic Animated 3D Water Shader River ("المية بجد")
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = load("res://shaders/realistic_water.gdshader")
	var lake := MeshInstance3D.new()
	var lm := PlaneMesh.new()
	lm.size = Vector2(800.0, 8.2)
	lm.subdivide_width = 96
	lm.subdivide_depth = 6
	lake.mesh = lm
	lake.material_override = _water_mat
	lake.position = Vector3(325.0, -0.95, -21.0)
	add_child(lake)

	var tree_paths := [
		"res://assets/3d/quaternius/nature_pack/CommonTree_1.glb",
		"res://assets/3d/quaternius/nature_pack/CommonTree_2.glb",
		"res://assets/3d/quaternius/nature_pack/CommonTree_3.glb",
		"res://assets/3d/quaternius/nature_pack/PineTree_1.glb",
		"res://assets/3d/quaternius/nature_pack/PineTree_2.glb",
		"res://assets/3d/quaternius/nature_pack/PineTree_3.glb",
		"res://assets/3d/quaternius/nature_pack/BirchTree_1.glb",
		"res://assets/3d/quaternius/nature_pack/BirchTree_2.glb",
		"res://assets/3d/quaternius/nature_pack/Willow_1.glb",
	]
	var tree_scenes: Array[PackedScene] = []
	for p in tree_paths:
		if ResourceLoader.exists(p):
			tree_scenes.append(load(p))

	var bush_scenes: Array[PackedScene] = []
	for bp in [
		"res://assets/3d/quaternius/nature_pack/Bush_1.glb",
		"res://assets/3d/quaternius/nature_pack/Bush_2.glb",
		"res://assets/3d/quaternius/nature_pack/BushBerries_1.glb",
		"res://assets/3d/quaternius/nature_pack/Rock_1.glb",
		"res://assets/3d/kenney/platformer/flowers.glb",
	]:
		if ResourceLoader.exists(bp):
			bush_scenes.append(load(bp))

	var rng := RandomNumberGenerator.new()
	rng.seed = 20263
	var x := -16.0
	while x < 670.0:
		for row in range(2):
			if tree_scenes.size() > 0:
				var sc := tree_scenes[rng.randi() % tree_scenes.size()]
				var t_inst := sc.instantiate()
				var tz := rng.randf_range(-4.8, -8.8) if row == 0 else rng.randf_range(-11.0, -16.2)
				t_inst.position = Vector3(x + rng.randf_range(-1.6, 1.6), -0.80, tz)
				t_inst.rotation_degrees.y = rng.randf_range(0.0, 360.0)
				t_inst.scale = Vector3.ONE * rng.randf_range(1.25, 1.95)
				t_inst.set_meta("sway_phase", x * 0.35 + row)
				_apply_cull_distance(t_inst, 82.0)
				add_child(t_inst)
				if row == 0:
					_trees.append(t_inst)

		if bush_scenes.size() > 0:
			var b_inst := bush_scenes[rng.randi() % bush_scenes.size()].instantiate()
			b_inst.position = Vector3(x + rng.randf_range(-1.5, 1.5), -0.78, rng.randf_range(-3.8, -6.5))
			b_inst.rotation_degrees.y = rng.randf_range(0.0, 360.0)
			b_inst.scale = Vector3.ONE * rng.randf_range(0.95, 1.45)
			_apply_cull_distance(b_inst, 72.0)
			add_child(b_inst)

		x += rng.randf_range(9.2, 13.5)


func _build_3d_city_skyline_and_billboards() -> void:
	var bld_paths := [
		"res://assets/3d/kenney/city-commercial/building-skyscraper-a.glb",
		"res://assets/3d/kenney/city-commercial/building-skyscraper-b.glb",
		"res://assets/3d/kenney/city-commercial/building-skyscraper-c.glb",
		"res://assets/3d/kenney/city-commercial/building-skyscraper-d.glb",
		"res://assets/3d/kenney/city-commercial/building-skyscraper-e.glb",
		"res://assets/3d/kenney/city-commercial/building-a.glb",
		"res://assets/3d/kenney/city-commercial/building-b.glb",
		"res://assets/3d/kenney/city-commercial/building-c.glb",
		"res://assets/3d/kenney/city-commercial/building-d.glb",
		"res://assets/3d/kenney/city-commercial/building-e.glb",
		"res://assets/3d/kenney/city-commercial/building-f.glb",
		"res://assets/3d/quaternius/buildings_pack_2/Building1_Large.glb",
		"res://assets/3d/quaternius/buildings_pack_2/Building2_Large.glb",
		"res://assets/3d/quaternius/buildings_pack_2/Building3_Big.glb",
	]
	var bld_scenes: Array[PackedScene] = []
	for p in bld_paths:
		if ResourceLoader.exists(p):
			bld_scenes.append(load(p))

	var rng := RandomNumberGenerator.new()
	rng.seed = 7712
	var x := -22.0
	while x < 680.0 and bld_scenes.size() > 0:
		var b1 := bld_scenes[rng.randi() % bld_scenes.size()].instantiate()
		b1.position = Vector3(x, -1.25, rng.randf_range(-27.5, -32.5))
		b1.scale = Vector3.ONE * rng.randf_range(4.0, 6.2)
		_apply_cull_distance(b1, 105.0)
		add_child(b1)

		var b2 := bld_scenes[rng.randi() % 5].instantiate()
		b2.position = Vector3(x + rng.randf_range(-3.0, 5.0), -1.25, rng.randf_range(-37.0, -45.0))
		b2.scale = Vector3.ONE * rng.randf_range(5.8, 9.0)
		_apply_cull_distance(b2, 115.0)
		add_child(b2)

		x += rng.randf_range(16.5, 23.0)

	var msgs := [Loc.hero_name(_cur_char_id), Loc.t("bb_msg_1"), Loc.t("bb_msg_2")]
	var bb_xs := [22.0, 108.0, 198.0, 298.0, 398.0, 498.0, 588.0]
	for i in range(bb_xs.size()):
		var msg: String = msgs[i % msgs.size()]
		var bb := CityBillboard3D.new()
		var w := 8.8 if msg.length() <= 16 else 10.4
		bb.setup(msg, i, w, 3.3, 7.2)
		bb.position = Vector3(bb_xs[i], 6.55 + (i % 2) * 0.60, -18.8)
		_apply_cull_distance(bb, 98.0)
		add_child(bb)
		_billboards.append(bb)


func _build_3d_clouds() -> void:
	var cloud_paths := [
		"res://assets/3d/quaternius/platformer_pack/Cloud1.glb",
		"res://assets/3d/quaternius/platformer_pack/Cloud2.glb",
		"res://assets/3d/quaternius/platformer_pack/Cloud3.glb",
		"res://assets/3d/quaternius/platformer_pack/Cloud4.glb",
	]
	var cloud_scs: Array[PackedScene] = []
	for p in cloud_paths:
		if ResourceLoader.exists(p):
			cloud_scs.append(load(p))
	if cloud_scs.is_empty():
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	var cx := -15.0
	while cx < 680.0:
		var c := cloud_scs[rng.randi() % cloud_scs.size()].instantiate()
		c.position = Vector3(cx, rng.randf_range(13.0, 20.5), rng.randf_range(-16.0, -32.0))
		c.scale = Vector3.ONE * rng.randf_range(2.2, 3.8)
		c.rotation_degrees.y = rng.randf_range(-25.0, 25.0)
		_apply_cull_distance(c, 105.0)
		add_child(c)
		_clouds.append(c)
		cx += rng.randf_range(24.0, 36.0)


func update_environment(delta: float, progress: float, cam_x: float = 0.0) -> void:
	if not visible:
		return
	var t_sec := Time.get_ticks_msec() * 0.001
	for c in _clouds:
		if is_instance_valid(c):
			if absf(c.position.x - cam_x) <= 95.0:
				c.position.x -= delta * 0.52
				c.position.y += sin(t_sec * 1.1 + c.position.x * 0.1) * delta * 0.14
	for tr in _trees:
		if is_instance_valid(tr) and absf(tr.position.x - cam_x) <= 72.0:
			var ph: float = tr.get_meta("sway_phase", 0.0)
			tr.rotation_degrees.z = sin(t_sec * 1.45 + ph) * 1.65

	var t := clampf(progress, 0.0, 1.0)
	var sunset_k := smoothstep(0.55, 1.0, t)
	if sun_light and _cur_level == 1:
		sun_light.light_color = Color(1.0, 0.96, 0.90).lerp(Color(1.0, 0.68, 0.38), sunset_k)
		sun_light.rotation_degrees.x = lerpf(-42.0, -18.0, sunset_k)
	if env_res and _cur_level == 1:
		env_res.fog_light_color = Color(0.76, 0.87, 0.99).lerp(Color(0.98, 0.74, 0.56), sunset_k)
