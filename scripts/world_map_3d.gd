class_name WorldMap3D
extends Node3D

signal stage_selected_by_proximity(lvl: int)

const MOVE_SPEED := 8.8
const JUMP_VY := 9.8
const GRAVITY := 26.0
const STAGE_SPACING_Z := 16.0

var stage_pts: Array[Vector3] = []
var crown_pts: Array[Vector3] = []
var crowns_3d: Array[Node3D] = []

var _unlocked_level: int = 1
var _selected_level: int = 1
var _char_id: String = "haneen"

var _hero_body: CharacterBody3D
var _hero_vis: Haneen3DCharacter
var _beacon: MeshInstance3D
var _lock_barrier_node: Node3D
var _lock_barrier_body: StaticBody3D
var _lock_barrier_col: CollisionShape3D

var _touch_move: Vector2 = Vector2.ZERO
var _touch_jump_req: bool = false
var _facing_yaw: float = 180.0
var _near_stage: int = 1
var _world_env: WorldEnvironment
var _env_res: Environment


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_instance_valid(_world_env):
		_world_env.environment = _env_res if visible else null


func build_map(unlocked_lvl: int, selected_lvl: int, c_id: String, crown_builder: Callable) -> void:
	_unlocked_level = clampi(unlocked_lvl, 1, GameProgress.IMPLEMENTED_LEVELS)
	_selected_level = clampi(selected_lvl, 1, _unlocked_level)
	_char_id = c_id

	_compute_stage_points()
	_build_sky_and_fog()
	_build_endless_landscape(crown_builder)
	_build_perimeter_and_lock_gate()
	_build_hero_explorer()
	refresh_state(_unlocked_level, _selected_level, _char_id, true)


func _compute_stage_points() -> void:
	stage_pts.clear()
	crown_pts.clear()
	for i in range(GameProgress.IMPLEMENTED_LEVELS):
		var sx := sin(float(i) * 0.72) * 11.2
		var sz := -float(i) * STAGE_SPACING_Z
		var sy := _road_height_at_z(sz)
		stage_pts.append(Vector3(sx, sy, sz))
	for k in range(1, GameProgress.IMPLEMENTED_LEVELS):
		var mid := (stage_pts[k - 1] + stage_pts[k]) * 0.5
		crown_pts.append(mid + Vector3(0.0, 0.72, 0.0))


func _road_height_at_z(z: float) -> float:
	var dist := clampf(-z, 0.0, float(GameProgress.IMPLEMENTED_LEVELS - 1) * STAGE_SPACING_Z)
	return dist * 0.045


func _build_sky_and_fog() -> void:
	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := PanoramaSkyMaterial.new()
	sm.panorama = load("res://assets/hdri/kloofendal_48d_partly_cloudy_puresky_2k.hdr")
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = false
	# Atmospheric mystery horizon haze so distant locked stages disappear into an infinite horizon!
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.74, 0.87, 0.98)
	env.fog_depth_begin = 38.0
	env.fog_depth_end = 135.0
	env.fog_density = 0.24
	_env_res = env
	_world_env.environment = _env_res if visible else null
	add_child(_world_env)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.15
	sun.rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	add_child(sun)


func _cull_scenery(root: Node, dist: float = 122.0) -> void:
	if root is GeometryInstance3D:
		var gi := root as GeometryInstance3D
		gi.visibility_range_end = dist
		gi.visibility_range_end_margin = 12.0
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in root.get_children():
		_cull_scenery(c, dist)


func _build_endless_landscape(crown_builder: Callable) -> void:
	# 1. Vast Endless Shader Ocean Horizon covering full 30-stage Archipelago
	var ocean := MeshInstance3D.new()
	var om := PlaneMesh.new()
	om.size = Vector2(540.0, 680.0)
	om.subdivide_width = 40
	om.subdivide_depth = 48
	ocean.mesh = om
	var omat := ShaderMaterial.new()
	omat.shader = load("res://shaders/realistic_water.gdshader")
	ocean.material_override = omat
	ocean.position = Vector3(0.0, -1.65, -240.0)
	add_child(ocean)

	# 2. Sloped Winding Adventure Mainland Terrain with Solid Collider
	var land_mat := StandardMaterial3D.new()
	land_mat.albedo_texture = load("res://assets/textures/ground/aerial_grass_rock_Diffuse.jpg")
	land_mat.normal_enabled = true
	land_mat.normal_texture = load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	land_mat.uv1_scale = Vector3(20.0, 88.0, 1.0)
	land_mat.roughness = 0.94

	var road_mat := StandardMaterial3D.new()
	road_mat.albedo_texture = load("res://assets/textures/stone/stone_tiles_02_Diffuse.jpg")
	road_mat.normal_enabled = true
	road_mat.normal_texture = load("res://assets/textures/stone/stone_tiles_02_nor_gl.jpg")
	road_mat.albedo_color = Color(0.96, 0.87, 0.68)
	road_mat.uv1_scale = Vector3(1.5, 1.0, 1.0)

	var total_z := float(GameProgress.IMPLEMENTED_LEVELS - 1) * STAGE_SPACING_Z + 44.0
	var tilt_ang := atan(0.045)
	var mid_z := -total_z * 0.5 + 14.0
	var mid_y := _road_height_at_z(mid_z)

	var ground_body := StaticBody3D.new()
	ground_body.collision_layer = 1
	ground_body.position = Vector3(0.0, mid_y, mid_z)
	ground_body.rotation.x = tilt_ang
	add_child(ground_body)

	var gcol := CollisionShape3D.new()
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(58.0, 3.0, total_z)
	gcol.shape = gbs
	gcol.position = Vector3(0.0, -1.5, 0.0)
	ground_body.add_child(gcol)

	var gvis := MeshInstance3D.new()
	var gbm := BoxMesh.new()
	gbm.size = Vector3(58.0, 3.0, total_z)
	gvis.mesh = gbm
	gvis.material_override = land_mat
	gvis.position = Vector3(0.0, -1.5, 0.0)
	ground_body.add_child(gvis)

	# Biome Accent Ground Strips with Natural Terrain Texture (Oasis 13..18, Frost 19..24, Royal Citadel 25..30)
	var biome_overlays := [
		{"i0": 12, "i1": 17, "col": Color(0.96, 0.82, 0.56)},
		{"i0": 18, "i1": 23, "col": Color(0.92, 0.97, 1.00)},
		{"i0": 24, "i1": 29, "col": Color(0.46, 0.42, 0.58)},
	]
	for ov: Dictionary in biome_overlays:
		var z_s := stage_pts[int(ov["i0"])].z + 8.0
		var z_e := stage_pts[int(ov["i1"])].z - 8.0
		var ov_len := absf(z_s - z_e)
		var ov_mid_z := (z_s + z_e) * 0.5
		var ov_m := MeshInstance3D.new()
		var obm := BoxMesh.new()
		obm.size = Vector3(57.8, 0.10, ov_len)
		ov_m.mesh = obm
		var om_mat := land_mat.duplicate() as StandardMaterial3D
		om_mat.albedo_color = ov["col"]
		om_mat.uv1_scale = Vector3(20.0, 14.0, 1.0)
		ov_m.material_override = om_mat
		ov_m.position = Vector3(0.0, _road_height_at_z(ov_mid_z) - 0.042, ov_mid_z)
		ov_m.rotation.x = tilt_ang
		_cull_scenery(ov_m, 165.0)
		add_child(ov_m)

	# Subdivided curving Stone Adventure Path connecting Castles 1..30 smoothly
	for i in range(stage_pts.size() - 1):
		var a := stage_pts[i]
		var b := stage_pts[i + 1]
		for sub in range(3):
			var t0 := float(sub) / 3.0
			var t1 := float(sub + 1) / 3.0
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			var seg := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(3.6, 0.14, p0.distance_to(p1) + 0.55)
			seg.mesh = sm
			seg.material_override = road_mat
			seg.position = (p0 + p1) * 0.5 + Vector3(0.0, -0.02, 0.0)
			var d := p1 - p0
			seg.rotation.y = atan2(-d.x, -d.z)
			seg.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())
			_cull_scenery(seg, 130.0)
			add_child(seg)

	# 3. 30 Castles, 5 Regional Biomes (Meadows, Autumn, Desert Oasis, Crystal Frost, Obsidian Citadel) & Evolving Crowns
	var kc_first: PackedScene = load("res://assets/3d/kingdom/gates/TownCenter_FirstAge_Level3.glb")
	var kc_second: PackedScene = load("res://assets/3d/kingdom/gates/TownCenter_SecondAge_Level3.glb")
	var kc_gate: PackedScene = load("res://assets/3d/kingdom/gates/WallTowers_Door_SecondAge.glb")
	var kc_entrance: PackedScene = load("res://assets/3d/kingdom/gates/TallWallEntrance.glb")
	var kc_pointy: PackedScene = load("res://assets/3d/kingdom/gates/PointyTower.glb")
	var kc_large: PackedScene = load("res://assets/3d/kingdom/gates/LargeTower.glb")
	var kc_wonder: PackedScene = load("res://assets/3d/kingdom/gates/Wonder_SecondAge_Level3.glb")
	var kc_banner: PackedScene = load("res://assets/3d/kingdom/gates/Banner.glb")

	var tree_p: PackedScene = load("res://assets/3d/quaternius/nature_pack/PineTree_1.glb")
	var tree_a: PackedScene = load("res://assets/3d/quaternius/nature_pack/CommonTree_Autumn_1.glb")
	var tree_palm: PackedScene = load("res://assets/3d/quaternius/nature_pack/PalmTree_1.glb")
	var cactus_s: PackedScene = load("res://assets/3d/quaternius/nature_pack/CactusFlower_1.glb")
	var tree_snow: PackedScene = load("res://assets/3d/quaternius/nature_pack/PineTree_Snow_1.glb")
	var bush_snow: PackedScene = load("res://assets/3d/quaternius/nature_pack/Bush_Snow_1.glb")
	var tree_willow: PackedScene = load("res://assets/3d/quaternius/nature_pack/Willow_1.glb")
	var crys1: PackedScene = load("res://assets/3d/quaternius/rpg_items_pack/Crystal1.glb")
	var crys2: PackedScene = load("res://assets/3d/quaternius/rpg_items_pack/Crystal2.glb")
	var rock_s: PackedScene = load("res://assets/3d/quaternius/nature_pack/Rock_Moss_1.glb")
	var rock_des: PackedScene = load("res://assets/3d/quaternius/nature_pack/Rock_1.glb")

	for i in range(stage_pts.size()):
		var pt := stage_pts[i]
		var side := -1.0 if (i % 2 == 0) else 1.0
		var region := int(i / 6) # 0: Meadows, 1: Autumn, 2: Oasis, 3: Frost, 4: Obsidian Citadel
		var castle_sc: PackedScene = kc_first
		match region:
			0: castle_sc = kc_gate if i % 3 == 1 else kc_first
			1: castle_sc = kc_gate if i % 3 == 0 else kc_second
			2: castle_sc = kc_entrance if i % 2 == 0 else kc_second
			3: castle_sc = kc_pointy if i % 2 == 0 else kc_gate
			_: castle_sc = kc_wonder if (i >= 28 or i % 2 == 0) else kc_large

		var castle := castle_sc.instantiate() as Node3D
		castle.position = pt + Vector3(side * 5.6, 0.0, -1.2)
		castle.rotation_degrees.y = side * -32.0
		castle.scale = Vector3.ONE * (2.25 if region >= 3 else 1.95)
		_cull_scenery(castle, 132.0)
		add_child(castle)

		var bnr := kc_banner.instantiate() as Node3D
		bnr.position = pt + Vector3(-side * 2.7, 0.0, 0.4)
		bnr.scale = Vector3.ONE * 1.45
		_cull_scenery(bnr, 115.0)
		add_child(bnr)

		for t_side: float in [-1.0, 1.0]:
			var tr_sc: PackedScene = tree_p
			var rk_sc: PackedScene = rock_s
			match region:
				1: tr_sc = tree_a
				2:
					tr_sc = tree_palm if (i + int(t_side)) % 2 == 0 else cactus_s
					rk_sc = rock_des
				3:
					tr_sc = tree_snow if int(t_side) > 0 else bush_snow
					rk_sc = crys1
				4:
					tr_sc = tree_willow
					rk_sc = crys2
			var tr := tr_sc.instantiate() as Node3D
			tr.position = Vector3(clampf(pt.x + t_side * randf_range(8.5, 22.0), -25.0, 25.0), _road_height_at_z(pt.z - 2.0), pt.z - randf_range(2.0, 10.0))
			tr.scale = Vector3.ONE * randf_range(0.75, 1.15)
			_cull_scenery(tr, 118.0)
			add_child(tr)

			var rk := rk_sc.instantiate() as Node3D
			rk.position = Vector3(clampf(pt.x + t_side * randf_range(6.4, 18.0), -25.0, 25.0), _road_height_at_z(pt.z), pt.z + randf_range(-4.0, 4.0))
			rk.scale = Vector3.ONE * randf_range(0.90, 1.50)
			_cull_scenery(rk, 115.0)
			add_child(rk)

	crowns_3d.clear()
	for k in range(crown_pts.size()):
		var cn: Node3D = crown_builder.call(k + 1)
		cn.position = crown_pts[k] - Vector3(0.0, 0.35, 0.0)
		cn.scale *= 1.12
		_cull_scenery(cn, 118.0)
		add_child(cn)
		crowns_3d.append(cn)

	# Distant Misty Horizon Islands & Mountain Silhouettes across full 480m World Map
	var mtn_mat := StandardMaterial3D.new()
	mtn_mat.albedo_color = Color(0.28, 0.38, 0.48)
	mtn_mat.roughness = 0.92
	for m_i in range(44):
		var mz := 16.0 - float(m_i) * 12.2
		for sgn: float in [-1.0, 1.0]:
			var pk := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 1.8
			pm.bottom_radius = 12.0 + float(m_i % 3) * 3.8
			pm.height = 15.0 + float(m_i % 4) * 5.2
			pk.mesh = pm
			pk.material_override = mtn_mat
			pk.position = Vector3(sgn * (54.0 + float((m_i * 7) % 22)), pm.height * 0.35 - 2.5, mz)
			_cull_scenery(pk, 175.0)
			add_child(pk)


func _build_perimeter_and_lock_gate() -> void:
	# Invisible island perimeter walls preventing player from straying off bounds
	var wall_body := StaticBody3D.new()
	wall_body.collision_layer = 1
	add_child(wall_body)

	var total_len := float(GameProgress.IMPLEMENTED_LEVELS) * STAGE_SPACING_Z + 46.0
	for sgn: float in [-1.0, 1.0]:
		var wc := CollisionShape3D.new()
		var wbs := BoxShape3D.new()
		wbs.size = Vector3(2.0, 18.0, total_len)
		wc.shape = wbs
		wc.position = Vector3(sgn * 28.0, 6.0, -total_len * 0.5 + 14.0)
		wall_body.add_child(wc)

	var south_c := CollisionShape3D.new()
	var south_bs := BoxShape3D.new()
	south_bs.size = Vector3(60.0, 18.0, 2.0)
	south_c.shape = south_bs
	south_c.position = Vector3(0.0, 6.0, 8.5)
	wall_body.add_child(south_c)

	var north_c := CollisionShape3D.new()
	var north_bs := BoxShape3D.new()
	north_bs.size = Vector3(60.0, 18.0, 2.0)
	north_c.shape = north_bs
	north_c.position = Vector3(0.0, 12.0, -(float(GameProgress.IMPLEMENTED_LEVELS - 1) * STAGE_SPACING_Z + 12.0))
	wall_body.add_child(north_c)

	# Dynamic Sealed Stone Fortress Barrier blocking access past unlocked_level!
	_lock_barrier_node = Node3D.new()
	add_child(_lock_barrier_node)

	_lock_barrier_body = StaticBody3D.new()
	_lock_barrier_body.collision_layer = 1
	_lock_barrier_node.add_child(_lock_barrier_body)
	_lock_barrier_col = CollisionShape3D.new()
	var lbm := BoxShape3D.new()
	lbm.size = Vector3(58.0, 12.0, 1.8)
	_lock_barrier_col.shape = lbm
	_lock_barrier_col.position = Vector3(0.0, 5.0, 0.0)
	_lock_barrier_body.add_child(_lock_barrier_col)

	var sc_gate: PackedScene = load("res://assets/3d/kingdom/gates/TallWallBricks.glb")
	for xoff: float in [-17.0, -8.5, 0.0, 8.5, 17.0]:
		var wall_vis := sc_gate.instantiate() as Node3D
		wall_vis.position = Vector3(xoff, -0.2, 0.0)
		wall_vis.rotation_degrees.y = 90.0
		wall_vis.scale = Vector3.ONE * 2.4
		_lock_barrier_node.add_child(wall_vis)

	var shield_vis := MeshInstance3D.new()
	var svm := BoxMesh.new()
	svm.size = Vector3(56.0, 6.5, 0.35)
	shield_vis.mesh = svm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.45, 0.12, 0.28)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield_vis.material_override = smat
	shield_vis.position = Vector3(0.0, 3.2, 0.0)
	_lock_barrier_node.add_child(shield_vis)


func _build_hero_explorer() -> void:
	_hero_body = CharacterBody3D.new()
	_hero_body.collision_layer = 16
	_hero_body.collision_mask = 1
	_hero_body.floor_max_angle = deg_to_rad(50.0)
	_hero_body.floor_snap_length = 0.35
	add_child(_hero_body)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35; cap.height = 1.48
	col.shape = cap
	col.position = Vector3(0.0, 0.74, 0.0)
	_hero_body.add_child(col)

	_hero_vis = Haneen3DCharacter.new()
	_hero_vis.scale = Vector3.ONE * 0.98
	_hero_body.add_child(_hero_vis)

	_beacon = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95; tm.outer_radius = 1.25
	_beacon.mesh = tm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.62, 0.12)
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.55, 0.10)
	bmat.emission_energy_multiplier = 2.0
	_beacon.material_override = bmat
	add_child(_beacon)


func refresh_state(unlocked_lvl: int, selected_lvl: int, c_id: String, reset_hero_pos: bool = false) -> void:
	_unlocked_level = clampi(unlocked_lvl, 1, GameProgress.IMPLEMENTED_LEVELS)
	_selected_level = clampi(selected_lvl, 1, _unlocked_level)
	_char_id = c_id
	if is_instance_valid(_hero_vis):
		_hero_vis.set_character(_char_id)
		_hero_vis.clear_sad_sit()
		_hero_vis.play_anim("idle", 1.0, 0.0)
	var sel_pt := stage_pts[_selected_level - 1]
	if is_instance_valid(_beacon):
		_beacon.position = sel_pt + Vector3(0.0, 0.12, 0.0)
	if reset_hero_pos and is_instance_valid(_hero_body):
		var spawn_z := sel_pt.z + 2.2
		_hero_body.position = Vector3(sel_pt.x, _road_height_at_z(spawn_z), spawn_z)
		_hero_body.velocity = Vector3.ZERO
		_facing_yaw = 90.0
		_hero_vis.rotation_degrees.y = _facing_yaw
		_near_stage = _selected_level
	if is_instance_valid(_lock_barrier_node):
		if _unlocked_level >= GameProgress.IMPLEMENTED_LEVELS:
			_lock_barrier_node.visible = false
			_lock_barrier_col.disabled = true
		else:
			_lock_barrier_node.visible = true
			_lock_barrier_col.disabled = false
			var gap_pt := (stage_pts[_unlocked_level - 1] + stage_pts[_unlocked_level]) * 0.5
			_lock_barrier_node.position = Vector3(0.0, gap_pt.y, gap_pt.z - 1.2)


func set_touch_move(dir_vec: Vector2) -> void:
	_touch_move = Vector2(clampf(dir_vec.x, -1.0, 1.0), clampf(dir_vec.y, -1.0, 1.0))


func trigger_jump() -> void:
	_touch_jump_req = true


func update_map_step(delta: float, cam: Camera3D) -> void:
	if not is_instance_valid(_hero_body) or not visible:
		return
	var kb_fwd := (1.0 if (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) else 0.0) - (1.0 if (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) else 0.0)
	var kb_side := (1.0 if (Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) else 0.0) - (1.0 if (Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)) else 0.0)
	# Screen forward (up) walks North (-Z) down the Kingdom trail; right steers +X!
	var vx := clampf(kb_side + _touch_move.x, -1.0, 1.0)
	var vz := clampf(-kb_fwd + _touch_move.y, -1.0, 1.0)
	var mv := Vector2(vx, vz)
	if mv.length() > 1.0:
		mv = mv.normalized()

	var k := 1.0 - exp(-22.0 * delta)
	_hero_body.velocity.x = lerpf(_hero_body.velocity.x, mv.x * MOVE_SPEED, k)
	_hero_body.velocity.z = lerpf(_hero_body.velocity.z, mv.y * MOVE_SPEED, k)

	if mv.length() > 0.12:
		var tgt_yaw := rad_to_deg(atan2(-mv.y, mv.x))
		_facing_yaw = rad_to_deg(lerp_angle(deg_to_rad(_facing_yaw), deg_to_rad(tgt_yaw), minf(1.0, delta * 18.0)))
	_hero_vis.rotation_degrees.y = _facing_yaw

	if _hero_body.is_on_floor():
		if Input.is_key_pressed(KEY_SPACE) or _touch_jump_req:
			_touch_jump_req = false
			_hero_body.velocity.y = JUMP_VY
	else:
		_touch_jump_req = false
		_hero_body.velocity.y -= GRAVITY * delta

	_hero_body.move_and_slide()
	if not _hero_body.is_on_floor():
		_hero_vis.play_anim("jump" if _hero_body.velocity.y > 0.0 else "fall", 1.15, 0.10)
	elif mv.length() > 0.14:
		_hero_vis.play_anim("run", 1.30, 0.10)
	else:
		_hero_vis.play_anim("idle", 1.0, 0.14)

	var t := Time.get_ticks_msec() * 0.001
	if is_instance_valid(_beacon):
		_beacon.scale = Vector3.ONE * (1.0 + sin(t * 4.0) * 0.10)
	for cn in crowns_3d:
		if is_instance_valid(cn):
			cn.rotation_degrees.y += delta * 62.0

	# Proximity check to nearest unlocked Castle/Stage station (in local _map_stage coords!)
	var h_loc := _hero_body.position
	var hpos := _hero_body.global_position
	var best_lvl := _near_stage
	var best_d := 5.6
	for i in range(_unlocked_level):
		var d := Vector2(h_loc.x - stage_pts[i].x, h_loc.z - stage_pts[i].z).length()
		if d < best_d:
			best_d = d
			best_lvl = i + 1
	if best_lvl != _near_stage:
		_near_stage = best_lvl
		stage_selected_by_proximity.emit(_near_stage)

	if cam:
		var des := hpos + Vector3(0.0, 5.8, 10.8)
		cam.position = cam.position.lerp(des, 1.0 - exp(-10.0 * delta))
		cam.look_at(hpos + Vector3(0.0, 1.3, -13.0))


func get_hero_global_pos() -> Vector3:
	return _hero_body.global_position if is_instance_valid(_hero_body) else stage_pts[0]
