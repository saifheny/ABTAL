class_name KingdomJourneyWorld
extends Node3D

signal journey_completed(to_level: int, coins_earned: int)
signal journey_failed(reason: String, coins_earned: int)
signal hero_hp_changed(cur_hp: int, max_hp: int)
signal coins_changed(total_coins: int)
signal intro_finished
signal dest_entered_fog(to_level: int, coins_earned: int)
signal mc_inventory_changed(oak_cnt: int, stone_cnt: int, active_slot: int)
signal mc_toast(msg: String)

enum JState {
	INTRO_CINEMATIC,
	PLAYING,
	VICTORY,
	DEFEATED,
	TRAP_RESET,
	REVIVING,
}

const MOVE_SPEED := 6.6
const WATER_SPEED_MULT := 1.0
const JUMP_VY := 10.6
const GRAVITY := 28.0
const HALF_WIDTH_Z := 11.4
const MC_CELL := 1.25
const MC_REACH := 5.0
const MC_MINE_DURATION := 0.58
const WATER_EAT_DURATION := 1.15

var from_level: int = 1
var to_level: int = 2
var char_id: String = "haneen"
var audio: AudioManager
var j_state: JState = JState.INTRO_CINEMATIC

var journey_len: float = 108.0
var _water_zones: Array[Vector2] = []

var _world_env: WorldEnvironment
var _sun: DirectionalLight3D
var _cam: Camera3D
var _cam_yaw: float = 0.0
var _cam_pitch: float = -0.32
var _cam_dist: float = 7.2

var _hero_body: CharacterBody3D
var _hero_vis: Haneen3DCharacter
var hero_hp: int = 6
var hero_max_hp: int = 6
var sword_damage: int = 25
var journey_coins: int = 0
var _defeat_delay_t: float = -1.0
var _defeat_reason: String = ""

var _mc_oak_cnt: int = 0
var _mc_stone_cnt: int = 0
var _mc_active_slot: int = 0 # 0 = oak planks, 1 = stone
var _mc_wall_blocks: Array[Dictionary] = []
var _mc_placed_cells: Dictionary = {} # Vector2i(gx, gz) -> Dictionary({"node", "pos", "kind", "hp", "seq"})
var _mc_place_seq: int = 0
var _mc_drops: Array[Dictionary] = [] # floating rotating mini-block pickups
var _mc_oak_mat: StandardMaterial3D
var _mc_stone_mat: StandardMaterial3D
var _mc_ghost_mesh: MeshInstance3D
var _mc_ghost_place_mat: StandardMaterial3D
var _mc_ghost_mine_mat: StandardMaterial3D
var _mc_box_mesh: BoxMesh
var _mc_drop_mesh: BoxMesh
var _mc_crack_mats: Array[StandardMaterial3D] = []
var _mc_crack_mesh: MeshInstance3D
var _mine_active: bool = false
var _mine_target: Dictionary = {}
var _mine_progress: float = 0.0
var _mine_sfx_cd: float = 0.0

var _facing_yaw: float = 0.0
var _attack_cd: float = 0.0
var _invuln_t: float = 0.0
var _water_step_t: float = 0.0
var _dry_step_t: float = 0.0
var _squash: Vector3 = Vector3.ONE
var _was_in_water: bool = false
var _touch_move: Vector2 = Vector2.ZERO
var _touch_jump_req: bool = false

var _origin_door_l: Node3D
var _origin_door_r: Node3D
var _origin_blocker: StaticBody3D
var _origin_bars: Node3D
var _gate_locked: bool = false

var _dest_door_l: Node3D
var _dest_door_r: Node3D
var _dest_doors_open: bool = false
var _trap_reset_t: float = 0.0
var _revive_t: float = 0.0
var _revive_center: Vector3 = Vector3.ZERO
var _last_fail_pos: Vector3 = Vector3(6.5, 0.0, 0.0)
var _shield_aura: MeshInstance3D
var _dash_cd: float = 0.0

var _intro_t: float = 0.0
var _intro_dur: float = 2.6
var _gate_opened_sfx: bool = false
var _gate_slammed_sfx: bool = false

var _monsters: Array[Dictionary] = []
var _mob_projectiles: Array[Dictionary] = []
var _water_eaters: Array[Dictionary] = []
var _proj_sphere_mesh: SphereMesh
var _proj_ring_mesh: TorusMesh
var _proj_web_mat: StandardMaterial3D
var _proj_fire_mat: StandardMaterial3D
var _proj_slime_mat: StandardMaterial3D
var _proj_gold_mat: StandardMaterial3D
var _traps: Array[Dictionary] = []
var _signs: Array[Node3D] = []
var _pickups: Array[Dictionary] = []
var _fx_parent: Node3D
var _fx_pool: ParticlePool3D
var _fx_mesh: SphereMesh
var _vfx_slash_mesh: MeshInstance3D
var _dest_sign: CityBillboard3D

var _sc_pine: PackedScene
var _sc_oak: PackedScene
var _sc_rock: PackedScene
var _sc_flowers: PackedScene
var _sc_crate: PackedScene
var _sc_arrow: PackedScene
var _sc_sign: PackedScene
var _sc_spikes: PackedScene
var _sc_coin: PackedScene
var _sc_heart: PackedScene

var _water_mat: ShaderMaterial
var _grass_mat: StandardMaterial3D
var _sand_mat: StandardMaterial3D
var _trail_mat: StandardMaterial3D
var _earth_mat: StandardMaterial3D


func setup(from_lvl: int, to_lvl: int, c_id: String, audio_mgr: AudioManager, cam: Camera3D) -> void:
	from_level = from_lvl
	to_level = to_lvl
	char_id = c_id
	audio = audio_mgr
	_cam = cam
	journey_len = clampf(108.0 + float(maxi(0, to_level - 2)) * 5.2, 108.0, 210.0)
	hero_max_hp = 6
	hero_hp = 6
	sword_damage = 25 + mini(35, maxi(0, to_level - 2) * 2)


func _ready() -> void:
	_load_assets()
	_compute_water_zones()
	_build_environment()
	_build_terrain_and_water()
	_build_water_eaters()
	_build_origin_citadel_gate()
	_build_destination_castle()
	_build_scenery_and_signs()
	_build_traps_and_pickups()
	_build_minecraft_world_blocks()
	_build_monsters()
	_build_hero()

	_fx_parent = Node3D.new()
	add_child(_fx_parent)
	_fx_pool = ParticlePool3D.new()
	_fx_parent.add_child(_fx_pool)

	hero_hp_changed.emit(hero_hp, hero_max_hp)
	coins_changed.emit(journey_coins)
	mc_inventory_changed.emit(_mc_oak_cnt, _mc_stone_cnt, _mc_active_slot)
	j_state = JState.INTRO_CINEMATIC
	_intro_t = 0.0
	_update_intro_camera(0.0)
	if audio:
		audio.set_nature_ambience(true)
		audio.play("sword_draw", 0.96, -8.0, 150)


func _exit_tree() -> void:
	if audio:
		audio.set_nature_ambience(false)


func _load_assets() -> void:
	var region := clampi((to_level - 2) / 6, 0, 4)
	match region:
		1:
			_sc_pine = load("res://assets/3d/quaternius/nature_pack/CommonTree_Autumn_1.glb")
			_sc_oak = load("res://assets/3d/quaternius/nature_pack/BirchTree_1.glb")
			_sc_rock = load("res://assets/3d/quaternius/nature_pack/Rock_2.glb")
		2:
			_sc_pine = load("res://assets/3d/quaternius/nature_pack/PalmTree_1.glb")
			_sc_oak = load("res://assets/3d/quaternius/nature_pack/CactusFlower_1.glb")
			_sc_rock = load("res://assets/3d/quaternius/nature_pack/Rock_1.glb")
		3:
			_sc_pine = load("res://assets/3d/quaternius/nature_pack/PineTree_Snow_1.glb")
			_sc_oak = load("res://assets/3d/quaternius/nature_pack/CommonTree_Snow_1.glb")
			_sc_rock = load("res://assets/3d/quaternius/rpg_items_pack/Crystal1.glb")
		4:
			_sc_pine = load("res://assets/3d/quaternius/nature_pack/Willow_1.glb")
			_sc_oak = load("res://assets/3d/quaternius/nature_pack/CommonTree_Dead_1.glb")
			_sc_rock = load("res://assets/3d/quaternius/rpg_items_pack/Crystal2.glb")
		_:
			_sc_pine = load("res://assets/3d/quaternius/nature_pack/PineTree_1.glb")
			_sc_oak = load("res://assets/3d/quaternius/nature_pack/CommonTree_1.glb")
			_sc_rock = load("res://assets/3d/quaternius/nature_pack/Rock_1.glb")
	_sc_flowers = load("res://assets/3d/kenney/platformer/flowers.glb")
	_sc_crate = load("res://assets/3d/gdquest/props/box.glb")
	_sc_arrow = load("res://assets/3d/kingdom/signs/Arrow_Side.glb")
	_sc_sign = load("res://assets/3d/kingdom/signs/Sign_Right.glb")
	_sc_spikes = load("res://assets/3d/kingdom/gates/Spikes.glb")
	_sc_coin = load("res://assets/3d/gdquest/props/coin_model.glb")
	_sc_heart = load("res://assets/3d/quaternius/platformer_pack/Heart_Full.glb")

	_water_mat = ShaderMaterial.new()
	_water_mat.shader = load("res://shaders/realistic_water.gdshader")
	var water_cols := [
		[Color(0.05, 0.66, 0.88, 0.80), Color(0.02, 0.30, 0.62, 0.90)],
		[Color(0.08, 0.62, 0.78, 0.80), Color(0.03, 0.28, 0.50, 0.90)],
		[Color(0.10, 0.76, 0.74, 0.82), Color(0.03, 0.36, 0.48, 0.92)],
		[Color(0.20, 0.84, 0.98, 0.82), Color(0.06, 0.40, 0.76, 0.92)],
		[Color(0.18, 0.44, 0.88, 0.82), Color(0.06, 0.14, 0.44, 0.92)],
	]
	_water_mat.set_shader_parameter("shallow_color", water_cols[region][0])
	_water_mat.set_shader_parameter("deep_color", water_cols[region][1])

	var grass_tints := [
		Color(0.76, 0.92, 0.72),
		Color(0.92, 0.80, 0.56),
		Color(0.96, 0.86, 0.62),
		Color(0.90, 0.96, 1.00),
		Color(0.54, 0.50, 0.68),
	]
	_grass_mat = StandardMaterial3D.new()
	_grass_mat.albedo_texture = load("res://assets/textures/ground/aerial_grass_rock_Diffuse.jpg")
	_grass_mat.normal_enabled = true
	_grass_mat.normal_texture = load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	_grass_mat.roughness_texture = load("res://assets/textures/ground/aerial_grass_rock_Rough.jpg")
	_grass_mat.albedo_color = grass_tints[region]
	_grass_mat.roughness = 0.94
	_grass_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_grass_mat.uv1_scale = Vector3.ONE

	_sand_mat = StandardMaterial3D.new()
	_sand_mat.normal_enabled = true
	_sand_mat.normal_texture = load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	_sand_mat.albedo_color = Color(0.54, 0.44, 0.31)
	_sand_mat.roughness = 0.95
	_sand_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_sand_mat.uv1_scale = Vector3.ONE

	_trail_mat = StandardMaterial3D.new()
	_trail_mat.albedo_texture = load("res://assets/textures/stone/stone_tiles_02_Diffuse.jpg")
	_trail_mat.normal_enabled = true
	_trail_mat.normal_texture = load("res://assets/textures/stone/stone_tiles_02_nor_gl.jpg")
	_trail_mat.albedo_color = Color(0.88, 0.83, 0.74)
	_trail_mat.roughness = 0.90
	_trail_mat.uv1_scale = Vector3.ONE

	_earth_mat = StandardMaterial3D.new()
	_earth_mat.albedo_color = Color(0.24, 0.16, 0.10)
	_earth_mat.roughness = 0.94

	_mc_oak_mat = StandardMaterial3D.new()
	_mc_oak_mat.albedo_texture = load("res://assets/textures/blocks/mc_oak_planks.png")
	_mc_oak_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mc_oak_mat.roughness = 0.85

	_mc_stone_mat = StandardMaterial3D.new()
	_mc_stone_mat.albedo_texture = load("res://assets/textures/blocks/mc_cobble.png")
	_mc_stone_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mc_stone_mat.roughness = 0.90

	_mc_box_mesh = BoxMesh.new()
	_mc_box_mesh.size = Vector3(MC_CELL - 0.02, 1.0, MC_CELL - 0.02)

	_mc_drop_mesh = BoxMesh.new()
	_mc_drop_mesh.size = Vector3(0.36, 0.36, 0.36)

	_mc_crack_mats.clear()
	for stage_i in range(4):
		var cimg := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		cimg.fill(Color(0, 0, 0, 0))
		var col_c := Color(0.06, 0.05, 0.05, 0.85)
		var lines := [
			[Vector2i(7, 7), Vector2i(8, 8), Vector2i(6, 8), Vector2i(8, 6)],
			[Vector2i(5, 6), Vector2i(9, 10), Vector2i(10, 5), Vector2i(4, 11), Vector2i(7, 4), Vector2i(7, 11)],
			[Vector2i(3, 4), Vector2i(12, 12), Vector2i(13, 3), Vector2i(2, 13), Vector2i(8, 2), Vector2i(8, 13), Vector2i(2, 8), Vector2i(13, 8)],
			[Vector2i(1, 2), Vector2i(14, 14), Vector2i(14, 1), Vector2i(1, 14), Vector2i(4, 1), Vector2i(11, 14), Vector2i(1, 6), Vector2i(14, 10), Vector2i(6, 14), Vector2i(10, 1)],
		]
		for st in range(stage_i + 1):
			for p: Vector2i in lines[st]:
				cimg.set_pixel(clampi(p.x, 0, 15), clampi(p.y, 0, 15), col_c)
				if st >= 1:
					cimg.set_pixel(clampi(p.x + 1, 0, 15), clampi(p.y, 0, 15), col_c)
					cimg.set_pixel(clampi(p.x, 0, 15), clampi(p.y + 1, 0, 15), col_c)
		var ctex := ImageTexture.create_from_image(cimg)
		var cm := StandardMaterial3D.new()
		cm.albedo_texture = ctex
		cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mc_crack_mats.append(cm)

	_mc_ghost_place_mat = StandardMaterial3D.new()
	_mc_ghost_place_mat.albedo_color = Color(0.22, 0.95, 0.45, 0.44)
	_mc_ghost_place_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mc_ghost_place_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_mc_ghost_mine_mat = StandardMaterial3D.new()
	_mc_ghost_mine_mat.albedo_color = Color(1.0, 0.72, 0.18, 0.46)
	_mc_ghost_mine_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mc_ghost_mine_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_proj_sphere_mesh = SphereMesh.new()
	_proj_sphere_mesh.radius = 0.24
	_proj_sphere_mesh.height = 0.48

	_proj_ring_mesh = TorusMesh.new()
	_proj_ring_mesh.inner_radius = 0.23
	_proj_ring_mesh.outer_radius = 0.30

	_proj_web_mat = StandardMaterial3D.new()
	_proj_web_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.94)
	_proj_web_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_proj_web_mat.emission_enabled = true
	_proj_web_mat.emission = Color(0.82, 0.92, 1.0)
	_proj_web_mat.emission_energy_multiplier = 0.75

	_proj_fire_mat = StandardMaterial3D.new()
	_proj_fire_mat.albedo_color = Color(1.0, 0.42, 0.10)
	_proj_fire_mat.emission_enabled = true
	_proj_fire_mat.emission = Color(1.0, 0.35, 0.08)
	_proj_fire_mat.emission_energy_multiplier = 1.2

	_proj_slime_mat = StandardMaterial3D.new()
	_proj_slime_mat.albedo_color = Color(0.24, 0.92, 0.34, 0.92)
	_proj_slime_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_proj_slime_mat.emission_enabled = true
	_proj_slime_mat.emission = Color(0.20, 0.85, 0.30)
	_proj_slime_mat.emission_energy_multiplier = 0.9

	_proj_gold_mat = StandardMaterial3D.new()
	_proj_gold_mat.albedo_color = Color(1.0, 0.84, 0.22)
	_proj_gold_mat.emission_enabled = true
	_proj_gold_mat.emission = Color(1.0, 0.76, 0.16)
	_proj_gold_mat.emission_energy_multiplier = 1.1


func _compute_water_zones() -> void:
	# Varied River Count (capped cleanly 1..3) with WIDENING Grand Rivers across higher Kingdoms!
	var count := 1
	var extra_w := 0.0
	if to_level == 3:
		count = 3
	elif to_level >= 4:
		if to_level % 3 == 2:
			count = 1
			extra_w = 2.8
		elif to_level % 3 == 1:
			count = 2
			extra_w = 1.2
		else:
			count = 3
			extra_w = 0.2

	var span_start := 26.0
	var span_end := journey_len - 20.0
	var step := (span_end - span_start) / float(count)
	for i in range(count):
		var mid := span_start + step * (float(i) + 0.5)
		var base_hw := 5.8 + minf(2.2, float(maxi(0, to_level - 3)) * 0.12)
		var half_w := clampf(base_hw + extra_w, 5.8, 10.6)
		_water_zones.append(Vector2(mid - half_w, mid + half_w))


func get_terrain_y(x: float) -> float:
	for wz in _water_zones:
		var inner_l := wz.x + 2.6
		var inner_r := wz.y - 2.6
		if x >= wz.x and x <= wz.y:
			if x < inner_l:
				var t := (x - wz.x) / 2.6
				return lerpf(0.0, -0.78, smoothstep(0.0, 1.0, t))
			elif x > inner_r:
				var t := (wz.y - x) / 2.6
				return lerpf(0.0, -0.78, smoothstep(0.0, 1.0, t))
			return -0.78
	return 0.0


func _is_in_water(x: float) -> bool:
	for wz in _water_zones:
		if x >= wz.x + 0.75 and x <= wz.y - 0.75:
			return true
	return false


func _get_land_segment_idx(x: float) -> int:
	var seg := 0
	for wz in _water_zones:
		if x >= wz.x - 0.35 and x <= wz.y + 0.35:
			return -1
		if x > wz.y + 0.35:
			seg += 1
	return seg


func _get_land_segment_bounds(seg_idx: int) -> Vector2:
	if seg_idx < 0 or _water_zones.is_empty():
		return Vector2(4.0, journey_len - 8.0)
	var start_x := 4.0 if seg_idx == 0 else (_water_zones[seg_idx - 1].y + 1.1 if seg_idx - 1 < _water_zones.size() else 4.0)
	var end_x := (_water_zones[seg_idx].x - 1.1) if seg_idx < _water_zones.size() else (journey_len - 8.0)
	return Vector2(start_x, maxf(start_x + 2.0, end_x))


func _build_environment() -> void:
	var compat := World3DBackdrop.is_compat_renderer()
	_world_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	if compat:
		var is_sunset := (to_level % 3 == 0)
		var psm := ProceduralSkyMaterial.new()
		psm.sky_top_color = Color(0.34, 0.42, 0.74) if is_sunset else Color(0.24, 0.56, 0.94)
		psm.sky_horizon_color = Color(0.99, 0.68, 0.44) if is_sunset else Color(0.74, 0.89, 1.0)
		psm.sky_curve = 0.18
		psm.ground_bottom_color = Color(0.32, 0.45, 0.34)
		psm.ground_horizon_color = psm.sky_horizon_color
		psm.ground_curve = 0.08
		psm.sun_angle_max = 18.0
		psm.energy_multiplier = 1.12
		sky.sky_material = psm
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.98, 0.86, 0.74) if is_sunset else Color(0.86, 0.92, 1.0)
		env.ambient_light_energy = 0.90
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.glow_enabled = false
		env.fog_enabled = false
	else:
		var sm := PanoramaSkyMaterial.new()
		var hdr_path := "res://assets/hdri/belfast_sunset_puresky_2k.hdr" if (to_level % 3 == 0) else "res://assets/hdri/kloofendal_48d_partly_cloudy_puresky_2k.hdr"
		sm.panorama = load(hdr_path)
		sm.energy_multiplier = 1.0
		sky.sky_material = sm
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 0.60
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		# Strictly zero bloom/glow glare!
		env.glow_enabled = false
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = Color(0.76, 0.88, 0.98)
		env.fog_depth_begin = 42.0
		env.fog_depth_end = 195.0
		env.fog_density = 0.11
	_world_env.environment = env
	add_child(_world_env)

	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	_sun.light_energy = 1.32 if compat else 0.95
	_sun.light_color = Color(1.0, 0.96, 0.90)
	_sun.shadow_enabled = true
	_sun.shadow_bias = 0.08
	_sun.directional_shadow_blend_splits = not (compat or OS.has_feature("mobile"))
	_sun.directional_shadow_max_distance = 32.0 if compat else (36.0 if OS.has_feature("mobile") else 58.0)
	add_child(_sun)


func _build_white_portal_mist(door_x: float, dir_sign: float) -> void:
	# Pure radiant white interior mist world behind Castle Doorways ("عالم مضيء أبيض وضباب ما تشوفش جواه")
	var white_mat := StandardMaterial3D.new()
	white_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white_mat.albedo_color = Color(0.99, 0.995, 1.0)

	var mist_root := Node3D.new()
	mist_root.position = Vector3(door_x + dir_sign * 13.0, 0.0, 0.0)
	add_child(mist_root)

	var floor_m := MeshInstance3D.new()
	var fm := BoxMesh.new(); fm.size = Vector3(26.0, 1.0, 28.0)
	floor_m.mesh = fm; floor_m.material_override = white_mat
	floor_m.position = Vector3(0.0, -0.49, 0.0)
	mist_root.add_child(floor_m)

	var back_m := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(1.5, 22.0, 28.0)
	back_m.mesh = bm; back_m.material_override = white_mat
	back_m.position = Vector3(dir_sign * 12.2, 10.0, 0.0)
	mist_root.add_child(back_m)

	for sgn: float in [-1.0, 1.0]:
		var wall_m := MeshInstance3D.new()
		var wm := BoxMesh.new(); wm.size = Vector3(26.0, 22.0, 1.0)
		wall_m.mesh = wm; wall_m.material_override = white_mat
		wall_m.position = Vector3(0.0, 10.0, sgn * 12.5)
		mist_root.add_child(wall_m)

	# Vertical translucent white fog curtains strictly framed inside the Fortress Archway
	for i in range(4):
		var veil := MeshInstance3D.new()
		var vm := QuadMesh.new()
		vm.size = Vector2(4.4, 6.2)
		veil.mesh = vm
		var vmat := StandardMaterial3D.new()
		vmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vmat.albedo_color = Color(0.99, 0.995, 1.0, 0.62 + float(i) * 0.11)
		vmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		veil.material_override = vmat
		veil.rotation_degrees.y = 90.0
		veil.position = Vector3(door_x + dir_sign * (0.65 + float(i) * 0.72), 3.05, 0.0)
		add_child(veil)


func _build_terrain_and_water() -> void:
	# 1. Pure Luminous White Mist World BEHIND Origin Castle Gate (x < 0)
	_build_white_portal_mist(-0.2, -1.0)

	# 2. Continuous Seamless Sculpted Ground Mesh (Zero overlapping BoxMesh Z-fighting or horizontal lighting stripes!)
	var step := 1.0
	var max_x := journey_len + 26.0
	var st_dry := SurfaceTool.new()
	st_dry.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_wet := SurfaceTool.new()
	st_wet.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_road := SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)

	var emit_quad := func(st: SurfaceTool, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, uv_s: float) -> void:
		st.set_uv(Vector2(x0 * uv_s, z0 * uv_s)); st.add_vertex(Vector3(x0, y0, z0))
		st.set_uv(Vector2(x1 * uv_s, z0 * uv_s)); st.add_vertex(Vector3(x1, y1, z0))
		st.set_uv(Vector2(x1 * uv_s, z1 * uv_s)); st.add_vertex(Vector3(x1, y1, z1))
		st.set_uv(Vector2(x0 * uv_s, z0 * uv_s)); st.add_vertex(Vector3(x0, y0, z0))
		st.set_uv(Vector2(x1 * uv_s, z1 * uv_s)); st.add_vertex(Vector3(x1, y1, z1))
		st.set_uv(Vector2(x0 * uv_s, z1 * uv_s)); st.add_vertex(Vector3(x0, y0, z1))

	var x := 0.0
	while x < max_x:
		var nx := minf(max_x, x + step)
		var y0 := get_terrain_y(x)
		var y1 := get_terrain_y(nx)
		var is_wet := (y0 < -0.10 or y1 < -0.10)
		emit_quad.call(st_wet if is_wet else st_dry, x, nx, y0, y1, -16.5, 16.5, 0.16)
		if not is_wet and x < journey_len + 0.5:
			emit_quad.call(st_road, x, nx, y0 + 0.025, y1 + 0.025, -2.2, 2.2, 0.24)
		x = nx

	# Merged ultra-fast primitive colliders (few flat + sloped spans instead of 130+ per-meter bodies)
	var cur_x := 0.0
	for wz in _water_zones:
		if wz.x > cur_x:
			_add_ground_box(cur_x, wz.x, 0.0, 33.0, null)
		var in_l := wz.x + 2.6
		var in_r := wz.y - 2.6
		var diag_len := sqrt(2.6 * 2.6 + 0.78 * 0.78)
		_add_sloped_floor((wz.x + in_l) * 0.5, -0.39, diag_len, 33.0, atan2(-0.78, 2.6), null)
		_add_ground_box(in_l, in_r, -0.78, 33.0, null)
		_add_sloped_floor((in_r + wz.y) * 0.5, -0.39, diag_len, 33.0, atan2(0.78, 2.6), null)
		cur_x = wz.y
	if max_x > cur_x:
		_add_ground_box(cur_x, max_x, 0.0, 33.0, null)

	st_dry.generate_normals()
	var dry_m := MeshInstance3D.new()
	dry_m.mesh = st_dry.commit()
	dry_m.material_override = _grass_mat
	dry_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dry_m)

	st_wet.generate_normals()
	var wet_m := MeshInstance3D.new()
	wet_m.mesh = st_wet.commit()
	wet_m.material_override = _sand_mat
	wet_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wet_m)

	st_road.generate_normals()
	var road_m := MeshInstance3D.new()
	road_m.mesh = st_road.commit()
	road_m.material_override = _trail_mat
	road_m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(road_m)

	# Deep solid earthen base skirt closing all ground underneath
	var sub_earth := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(journey_len + 96.0, 14.0, 38.0)
	sub_earth.mesh = sm
	sub_earth.material_override = _earth_mat
	sub_earth.position = Vector3(journey_len * 0.5, -8.2, 0.0)
	add_child(sub_earth)

	# 3. Walkable Minecraft-Realistic Shimmering Water River Planes across every crossing!
	for wz in _water_zones:
		var wlen := wz.y - wz.x
		var wcx := (wz.x + wz.y) * 0.5
		var water := MeshInstance3D.new()
		var wm := PlaneMesh.new()
		wm.size = Vector2(wlen + 2.4, 36.0)
		wm.subdivide_width = 24
		wm.subdivide_depth = 14
		water.mesh = wm
		water.material_override = _water_mat
		water.position = Vector3(wcx, -0.18, 0.0)
		water.visibility_range_end = 135.0
		add_child(water)

	# 4. Monumental Endless Sky-High Fortress Boundary Walls on both flanks (rising endlessly upward while framing luminous sky above!)
	var bound_wall_mat := StandardMaterial3D.new()
	bound_wall_mat.albedo_texture = load("res://assets/textures/stone/stone_tiles_02_Diffuse.jpg")
	bound_wall_mat.normal_enabled = true
	bound_wall_mat.normal_texture = load("res://assets/textures/stone/stone_tiles_02_nor_gl.jpg")
	bound_wall_mat.albedo_color = Color(0.70, 0.74, 0.80)
	bound_wall_mat.roughness = 0.88
	bound_wall_mat.uv1_scale = Vector3(28.0, 26.0, 1.0)

	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_texture = load("res://assets/textures/stone/stone_tiles_02_Diffuse.jpg")
	pillar_mat.normal_enabled = true
	pillar_mat.normal_texture = load("res://assets/textures/stone/stone_tiles_02_nor_gl.jpg")
	pillar_mat.albedo_color = Color(0.58, 0.62, 0.70)
	pillar_mat.roughness = 0.86
	pillar_mat.uv1_scale = Vector3(3.0, 28.0, 3.0)

	var wall_len := journey_len + 110.0
	var wall_cx := journey_len * 0.5 - 4.0
	for side_z in [-HALF_WIDTH_Z - 1.8, HALF_WIDTH_Z + 1.8]:
		var wall := StaticBody3D.new()
		wall.collision_layer = 1
		wall.position = Vector3(wall_cx, 4.0, side_z)
		add_child(wall)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(wall_len, 24.0, 2.2)
		col.shape = bs
		wall.add_child(col)

		# Soaring visual masonry boundary wall (165m high — rises endlessly skyward along both flanks!)
		var sgn := -1.0 if side_z < 0.0 else 1.0
		var vwall := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(wall_len, 165.0, 3.8)
		vwall.mesh = vm
		vwall.material_override = bound_wall_mat
		vwall.position = Vector3(wall_cx, 76.5, sgn * 15.6)
		add_child(vwall)

		# Massive Fortress Stone Buttresses along the soaring side wall
		var px := -26.0
		while px <= journey_len + 36.0:
			var pil := MeshInstance3D.new()
			var pm_box := BoxMesh.new()
			pm_box.size = Vector3(3.6, 172.0, 5.2)
			pil.mesh = pm_box
			pil.material_override = pillar_mat
			pil.position = Vector3(px, 80.0, sgn * 14.8)
			pil.visibility_range_end = 190.0
			add_child(pil)
			px += 18.0

	# Back towering wall behind Origin Castle (x = -38) & solid Destination Citadel horizon rampart (height 20m so sky shines above!)
	var back_body := StaticBody3D.new()
	back_body.collision_layer = 1
	back_body.position = Vector3(-38.0, 76.5, 0.0)
	add_child(back_body)
	var b_col := CollisionShape3D.new()
	var b_bs := BoxShape3D.new()
	b_bs.size = Vector3(4.5, 165.0, 40.0)
	b_col.shape = b_bs
	back_body.add_child(b_col)
	var b_vis := MeshInstance3D.new()
	var b_vm := BoxMesh.new()
	b_vm.size = Vector3(4.5, 165.0, 40.0)
	b_vis.mesh = b_vm
	b_vis.material_override = bound_wall_mat
	back_body.add_child(b_vis)

	var end_body := StaticBody3D.new()
	end_body.collision_layer = 1
	end_body.position = Vector3(journey_len + 42.0, 8.5, 0.0)
	add_child(end_body)
	var e_col := CollisionShape3D.new()
	var e_bs := BoxShape3D.new()
	e_bs.size = Vector3(4.5, 22.0, 40.0)
	e_col.shape = e_bs
	end_body.add_child(e_col)
	var e_vis := MeshInstance3D.new()
	var e_vm := BoxMesh.new()
	e_vm.size = Vector3(4.5, 22.0, 40.0)
	e_vis.mesh = e_vm
	e_vis.material_override = bound_wall_mat
	end_body.add_child(e_vis)


func _add_ground_box(x0: float, x1: float, top_y: float, width_z: float, mat: Material) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, top_y, 0.0)
	add_child(body)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(length, 2.4, width_z)
	col.shape = bs
	col.position = Vector3(0.0, -1.2, 0.0)
	body.add_child(col)
	var vis := MeshInstance3D.new()
	if mat != null:
		var bm := BoxMesh.new()
		bm.size = Vector3(length, 2.4, width_z)
		vis.mesh = bm
		vis.material_override = mat
		vis.position = Vector3(0.0, -1.2, 0.0)
		add_child(vis)
	else:
		vis.queue_free()


func _add_sloped_floor(cx: float, cy: float, length: float, width_z: float, rot_z: float, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, cy, 0.0)
	body.rotation.z = rot_z
	add_child(body)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(length, 1.4, width_z)
	col.shape = bs
	col.position = Vector3(0.0, -0.7, 0.0)
	body.add_child(col)
	if mat != null:
		var vis := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(length, 1.4, width_z)
		vis.mesh = bm
		vis.material_override = mat
		vis.position = Vector3(0.0, -0.7, 0.0)
		vis.visibility_range_end = 115.0
		body.add_child(vis)


func _build_origin_citadel_gate() -> void:
	# Giant Fortress Archway + Hinged Twin Doors at x = 0.0 (oriented across Z facing +X)
	var sc_arch: PackedScene = load("res://assets/3d/kingdom/gates/TallWallEntrance.glb")
	var sc_wall: PackedScene = load("res://assets/3d/kingdom/gates/TallWallBricks.glb")
	var sc_tower: PackedScene = load("res://assets/3d/kingdom/gates/LargeTower.glb")
	var sc_door: PackedScene = load("res://assets/3d/kingdom/gates/Door.glb")
	var sc_banner: PackedScene = load("res://assets/3d/kingdom/gates/Banner.glb")

	var gate_root := Node3D.new()
	gate_root.position = Vector3(0.0, 0.0, 0.0)
	add_child(gate_root)

	var arch := sc_arch.instantiate()
	arch.scale = Vector3.ONE * 3.4
	arch.rotation_degrees.y = 90.0
	gate_root.add_child(arch)

	for sz in [-5.2, 5.2, -9.8, 9.8]:
		var w := sc_wall.instantiate()
		w.scale = Vector3.ONE * 3.4
		w.rotation_degrees.y = 90.0
		w.position = Vector3(0.0, 0.0, sz)
		gate_root.add_child(w)

	for tz in [-3.4, 3.4]:
		var tw := sc_tower.instantiate()
		tw.scale = Vector3.ONE * 3.0
		tw.position = Vector3(-0.3, 0.0, tz)
		gate_root.add_child(tw)

		var bn := sc_banner.instantiate()
		bn.scale = Vector3.ONE * 2.8
		bn.rotation_degrees.y = 90.0
		bn.position = Vector3(1.1, 2.2, tz * 0.72)
		gate_root.add_child(bn)

	# Hinged Double Doors inside Giant Archway (open during intro, slam shut & lock permanently once hero steps out!)
	var hinge_l := Node3D.new()
	hinge_l.position = Vector3(0.15, 0.0, -1.55)
	gate_root.add_child(hinge_l)
	var dl := sc_door.instantiate()
	dl.scale = Vector3(1.75, 3.4, 2.2)
	dl.rotation_degrees.y = 90.0
	dl.position = Vector3(0.0, 0.0, 0.78)
	hinge_l.add_child(dl)
	_origin_door_l = hinge_l

	var hinge_r := Node3D.new()
	hinge_r.position = Vector3(0.15, 0.0, 1.55)
	gate_root.add_child(hinge_r)
	var dr := sc_door.instantiate()
	dr.scale = Vector3(1.75, 3.4, 2.2)
	dr.rotation_degrees.y = 90.0
	dr.position = Vector3(0.0, 0.0, -0.78)
	hinge_r.add_child(dr)
	_origin_door_r = hinge_r

	# Solid wall collider flanking gate so hero can ONLY go through center or stay outside once sealed!
	var flank_body := StaticBody3D.new()
	flank_body.collision_layer = 1
	gate_root.add_child(flank_body)
	for fz in [-7.2, 7.2]:
		var fc := CollisionShape3D.new()
		var fb := BoxShape3D.new()
		fb.size = Vector3(2.2, 8.0, 10.6)
		fc.shape = fb
		fc.position = Vector3(0.0, 4.0, fz)
		flank_body.add_child(fc)

	# Origin Blocker activated cleanly as soon as Hero exits Gate ("الحصن ده مقفل ما تعرفش تخش تاني")
	_origin_blocker = StaticBody3D.new()
	_origin_blocker.collision_layer = 1
	_origin_blocker.position = Vector3(0.4, 3.5, 0.0)
	add_child(_origin_blocker)
	var bcol := CollisionShape3D.new()
	var bbox := BoxShape3D.new()
	bbox.size = Vector3(1.8, 7.5, 4.2)
	bcol.shape = bbox
	bcol.disabled = true
	_origin_blocker.add_child(bcol)
	_origin_blocker.set_meta("col", bcol)


func _seal_origin_gate() -> void:
	if _gate_locked:
		return
	_gate_locked = true
	var col: CollisionShape3D = _origin_blocker.get_meta("col")
	if col:
		col.set_deferred("disabled", false)
	if is_instance_valid(_origin_door_l) and is_instance_valid(_origin_door_r):
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_origin_door_l, "rotation_degrees:y", 0.0, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_origin_door_r, "rotation_degrees:y", 0.0, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if audio and not _gate_slammed_sfx:
		_gate_slammed_sfx = true
		audio.play("gate_slam", 0.92, -5.0, 150)
		audio.play("gate_thud", 0.90, -4.0, 150)


func _build_destination_castle() -> void:
	var sc_arch: PackedScene = load("res://assets/3d/kingdom/gates/TallWallEntrance.glb")
	var sc_bricks: PackedScene = load("res://assets/3d/kingdom/gates/TallWallBricks.glb")
	var sc_tower: PackedScene = load("res://assets/3d/kingdom/gates/LargeTower.glb")
	var sc_door: PackedScene = load("res://assets/3d/kingdom/gates/Door.glb")
	var sc_town: PackedScene = load("res://assets/3d/kingdom/gates/TownCenter_SecondAge_Level3.glb")
	var sc_wonder: PackedScene = load("res://assets/3d/kingdom/gates/Wonder_SecondAge_Level3.glb")
	var sc_banner: PackedScene = load("res://assets/3d/kingdom/gates/Banner.glb")

	# Luminous blinding white mist chamber inside Destination Kingdom Gate
	_build_white_portal_mist(journey_len + 0.5, 1.0)

	var dest := Node3D.new()
	dest.position = Vector3(journey_len, 0.0, 0.0)
	add_child(dest)

	# Evolved Majestic Fortress Archway matching Origin Castle scale & craftsmanship!
	var arch := sc_arch.instantiate()
	arch.scale = Vector3.ONE * 3.6
	arch.rotation_degrees.y = -90.0
	dest.add_child(arch)

	for sz in [-5.4, 5.4, -10.2, 10.2]:
		var w := sc_bricks.instantiate()
		w.scale = Vector3.ONE * 3.6
		w.rotation_degrees.y = -90.0
		w.position = Vector3(0.0, 0.0, sz)
		dest.add_child(w)

	for tz in [-3.6, 3.6]:
		var tw := sc_tower.instantiate()
		tw.scale = Vector3.ONE * 3.2
		tw.position = Vector3(0.3, 0.0, tz)
		dest.add_child(tw)

		var b := sc_banner.instantiate()
		b.scale = Vector3.ONE * 3.0
		b.rotation_degrees.y = -90.0
		b.position = Vector3(-1.5, 2.2, tz * 0.72)
		dest.add_child(b)

	# Hinged Twin Castle Doors (open welcomingly as Hero approaches, SLAM SHUT behind Hero inside white mist!)
	var dhl := Node3D.new()
	dhl.position = Vector3(-0.15, 0.0, -1.60)
	dest.add_child(dhl)
	var ddl := sc_door.instantiate()
	ddl.scale = Vector3(1.80, 3.6, 2.2)
	ddl.rotation_degrees.y = -90.0
	ddl.position = Vector3(0.0, 0.0, 0.80)
	dhl.add_child(ddl)
	_dest_door_l = dhl

	var dhr := Node3D.new()
	dhr.position = Vector3(-0.15, 0.0, 1.60)
	dest.add_child(dhr)
	var ddr := sc_door.instantiate()
	ddr.scale = Vector3(1.80, 3.6, 2.2)
	ddr.rotation_degrees.y = -90.0
	ddr.position = Vector3(0.0, 0.0, -0.80)
	dhr.add_child(ddr)
	_dest_door_r = dhr

	# Towering Citadel spires rising above/behind the portal gate
	var citadel: Node3D = (sc_wonder if to_level >= 8 else sc_town).instantiate()
	citadel.scale = Vector3.ONE * (5.2 + float(mini(4, to_level - 2)) * 0.22)
	citadel.rotation_degrees.y = -90.0
	citadel.position = Vector3(11.5, 0.0, 0.0)
	dest.add_child(citadel)

	# Flanking colliders funneling Hero cleanly through Destination Portal
	var dfb := StaticBody3D.new()
	dfb.collision_layer = 1
	dest.add_child(dfb)
	for fz in [-7.6, 7.6]:
		var fc := CollisionShape3D.new()
		var fb := BoxShape3D.new()
		fb.size = Vector3(2.4, 9.0, 10.6)
		fc.shape = fb
		fc.position = Vector3(0.0, 4.5, fz)
		dfb.add_child(fc)

	# Destination Kingdom Title Sign above Fortress Archway
	var sign_3d := CityBillboard3D.new()
	sign_3d.setup(Loc.kingdom_label(to_level), 0, 5.8, 1.65, 0.5)
	sign_3d.position = Vector3(-1.4, 6.2, 0.0)
	sign_3d.rotation_degrees.y = -90.0
	dest.add_child(sign_3d)
	_dest_sign = sign_3d


func update_language() -> void:
	if is_instance_valid(_dest_sign):
		_dest_sign.update_message(Loc.kingdom_label(to_level))


func _build_scenery_and_signs() -> void:
	# Rich populated forest, flowers, boulders & wooden crates across BOTH left and right flanks!
	var rng := RandomNumberGenerator.new()
	rng.seed = 4000 + to_level * 91
	var x := 8.0
	while x < journey_len - 8.0:
		if not _is_in_water(x):
			for sgn: float in [-1.0, 1.0]:
				var tz: float = sgn * rng.randf_range(5.2, 9.6)
				var tr: Node3D = (_sc_pine if rng.randf() < 0.55 else _sc_oak).instantiate()
				tr.position = Vector3(x + rng.randf_range(-1.2, 1.2), get_terrain_y(x), tz)
				tr.rotation_degrees.y = rng.randf_range(0.0, 360.0)
				tr.scale = Vector3.ONE * rng.randf_range(1.15, 1.65)
				_set_cull(tr, 85.0)
				add_child(tr)

				if rng.randf() < 0.72:
					var rk := _sc_rock.instantiate()
					rk.position = Vector3(x + rng.randf_range(-1.8, 1.8), get_terrain_y(x), sgn * rng.randf_range(3.6, 8.6))
					rk.scale = Vector3.ONE * rng.randf_range(0.75, 1.25)
					_set_cull(rk, 76.0)
					add_child(rk)
				if _sc_flowers and rng.randf() < 0.78:
					var fl := _sc_flowers.instantiate()
					fl.position = Vector3(x + rng.randf_range(-1.5, 1.5), get_terrain_y(x), sgn * rng.randf_range(3.2, 7.6))
					fl.scale = Vector3.ONE * rng.randf_range(1.2, 1.7)
					_set_cull(fl, 68.0)
					add_child(fl)
				if _sc_crate and rng.randf() < 0.35:
					var cr := _sc_crate.instantiate()
					cr.position = Vector3(x + rng.randf_range(-1.0, 1.0), get_terrain_y(x) + 0.35, sgn * rng.randf_range(4.2, 6.8))
					cr.scale = Vector3.ONE * 0.72
					cr.rotation_degrees.y = rng.randf_range(0.0, 45.0)
					_set_cull(cr, 72.0)
					add_child(cr)
		x += 5.0

	# True Sky-Floating Directional Guide Arrows (hovering purely in air with NO wooden post, pointing +X toward Kingdom!)
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1.0, 0.72, 0.14)
	arrow_mat.metallic = 0.25
	arrow_mat.roughness = 0.28
	var arrow_rim_mat := StandardMaterial3D.new()
	arrow_rim_mat.albedo_color = Color(1.0, 0.96, 0.75)

	var sx := 14.0
	var g_idx := 0
	while sx < journey_len - 14.0:
		var sy := get_terrain_y(sx) + 3.40
		var gz := -3.1 if (g_idx % 2 == 0) else 3.1
		var guide := Node3D.new()
		guide.position = Vector3(sx, sy, gz)

		var shaft := MeshInstance3D.new()
		var shm := BoxMesh.new()
		shm.size = Vector3(1.05, 0.22, 0.48)
		shaft.mesh = shm
		shaft.material_override = arrow_mat
		shaft.position = Vector3(-0.35, 0.0, 0.0)
		guide.add_child(shaft)

		var head := MeshInstance3D.new()
		var hm := PrismMesh.new()
		hm.size = Vector3(1.35, 1.15, 0.24)
		head.mesh = hm
		head.material_override = arrow_mat
		head.rotation_degrees = Vector3(90.0, 90.0, 0.0)
		head.position = Vector3(0.65, 0.0, 0.0)
		guide.add_child(head)

		var cap := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.90, 0.08, 0.50)
		cap.mesh = cm
		cap.material_override = arrow_rim_mat
		cap.position = Vector3(-0.35, 0.14, 0.0)
		guide.add_child(cap)

		# Slanted slightly forward (+X) & tilted toward center road so chevron silhouette pops clearly in sky!
		guide.rotation_degrees = Vector3(12.0 if gz > 0.0 else -12.0, 0.0, -18.0)
		guide.set_meta("base_y", sy)
		guide.set_meta("phase", sx * 0.25)
		_set_cull(guide, 105.0)
		add_child(guide)
		_signs.append(guide)
		sx += 20.0
		g_idx += 1


func _build_traps_and_pickups() -> void:
	# Unmarked Hidden Spikes scattered unpredictably across all dry flanks & lanes (zero ground indicators!)
	var trap_count := 10 + mini(8, to_level)
	var span := journey_len - 24.0
	var rng_t := RandomNumberGenerator.new()
	rng_t.seed = 6100 + to_level * 73
	var lanes := [-8.2, -5.2, -2.2, 0.0, 2.2, 5.2, 8.2]

	for i in range(trap_count):
		var tx: float = 14.5 + span * ((float(i) + 0.35) / float(trap_count)) + rng_t.randf_range(-2.2, 2.2)
		var lane_z: float = float(lanes[(i + rng_t.randi_range(0, 4)) % lanes.size()]) + rng_t.randf_range(-0.9, 0.9)
		lane_z = clampf(lane_z, -9.2, 9.2)
		if _is_near_river_zone(tx, 3.2) or get_terrain_y(tx) < -0.05:
			continue
		var base_y := get_terrain_y(tx)

		var spikes := _sc_spikes.instantiate()
		spikes.scale = Vector3.ONE * 1.15
		spikes.position = Vector3(tx, base_y - 1.55, lane_z)
		spikes.visible = false
		_set_cull(spikes, 70.0)
		add_child(spikes)

		_traps.append({
			"node": spikes, "pos": Vector3(tx, base_y, lane_z),
			"base_y": base_y, "state": 0, "timer": 0.0, "hit_cd": 0.0
		})

	# Path Collectibles & Side-Flank Coins + Strictly 1 Healing Heart per Dry Land Island
	var cx := 12.0
	var coin_idx := 0
	while cx < journey_len - 10.0:
		var cy := maxf(0.0, get_terrain_y(cx)) + 0.95
		var p_node := Node3D.new()
		var cz := 0.0 if (coin_idx % 2 == 0) else (4.2 if (coin_idx % 4 == 1) else -4.2)
		p_node.position = Vector3(cx, cy, cz)
		var vis: Node3D = _sc_coin.instantiate()
		vis.scale = Vector3.ONE * 2.5
		_set_cull(vis, 72.0)
		p_node.add_child(vis)
		add_child(p_node)
		_pickups.append({"node": p_node, "base_y": cy, "is_heart": false, "taken": false})
		cx += 7.0
		coin_idx += 1

	if Level3DBuilder.should_spawn_journey_hearts():
		var seg_bounds: Array[Vector2] = []
		var prev_x := 10.0
		for wz in _water_zones:
			if wz.x - 1.5 - prev_x >= 6.0:
				seg_bounds.append(Vector2(prev_x, wz.x - 1.5))
			prev_x = wz.y + 1.5
		if (journey_len - 8.5) - prev_x >= 6.0:
			seg_bounds.append(Vector2(prev_x, journey_len - 8.5))
		for s_idx in range(seg_bounds.size()):
			var sb: Vector2 = seg_bounds[s_idx]
			var hx := clampf((sb.x + sb.y) * 0.5, sb.x + 1.5, sb.y - 1.5)
			var hy := maxf(0.0, get_terrain_y(hx)) + 0.95
			var hz := 2.0 if (s_idx % 2 == 0) else -2.0
			var h_node := Node3D.new()
			h_node.position = Vector3(hx, hy, hz)
			var hvis: Node3D = _sc_heart.instantiate()
			hvis.scale = Vector3.ONE * 0.98
			_set_cull(hvis, 72.0)
			h_node.add_child(hvis)
			add_child(h_node)
			_pickups.append({"node": h_node, "base_y": hy, "is_heart": true, "taken": false, "seg_idx": s_idx})


func _build_monsters() -> void:
	# Expanded multi-shape monster roster & Giant Kingdom Titan Bosses across 29 Kingdoms!
	var roster := [
		{"kind": "beetle", "path": "res://assets/3d/kingdom/monsters/beetle_bot.glb", "scale": 1.15, "anim_walk": "walk", "anim_atk": "headbutt", "hover_y": 0.0, "fly": false},
		{"kind": "frog", "path": "res://assets/3d/kingdom/monsters/Frog.glb", "scale": 0.88, "anim_walk": "FrogArmature|Frog_Jump", "anim_atk": "FrogArmature|Frog_Attack", "hover_y": 0.0, "fly": false},
		{"kind": "spider", "path": "res://assets/3d/kingdom/monsters/Spider.glb", "scale": 0.56, "anim_walk": "SpiderArmature|Spider_Walk", "anim_atk": "SpiderArmature|Spider_Attack", "hover_y": 0.0, "fly": false},
		{"kind": "knight", "path": "res://assets/3d/kingdom/monsters/KnightCharacter.glb", "scale": 0.36, "anim_walk": "HumanArmature|Run_swordRight", "anim_atk": "HumanArmature|Run_swordAttack", "hover_y": 0.0, "fly": false},
	]
	if to_level >= 3:
		roster.append({"kind": "bat", "path": "res://assets/3d/kingdom/monsters/bat.glb", "scale": 0.72, "anim_walk": "Flying", "anim_atk": "Attack", "hover_y": 0.78, "fly": true})
	if to_level >= 7:
		roster.append({"kind": "mech", "path": "res://assets/3d/quaternius/cyberpunk_pack/Enemy_Flying.glb", "scale": 0.64, "anim_walk": "Idle", "anim_atk": "Attack", "hover_y": 0.88, "fly": true})
	if to_level >= 10:
		roster.append({"kind": "warden", "path": "res://assets/3d/quaternius/cyberpunk_pack/Character.glb", "scale": 0.88, "anim_walk": "Run", "anim_atk": "Punch", "hover_y": 0.0, "fly": false})

	var mob_count := 3 + mini(7, to_level - 1)
	var step := (journey_len - 34.0) / float(mob_count + 1)
	for i in range(mob_count):
		var mx := 20.0 + step * float(i + 1)
		while _is_near_river_zone(mx, 4.5) and mx < journey_len - 14.0:
			mx += 4.5
		if mx > journey_len - 14.0:
			continue
		var spec: Dictionary = roster[(i + to_level) % roster.size()]
		var hover_y: float = float(spec.get("hover_y", 0.0))
		var my := get_terrain_y(mx) + hover_y
		var mz := randf_range(-2.6, 2.6)

		# Spawn Bigger Giant Titan Boss Monsters on Kingdoms >= 5 (keep Bat compact & strictly 2-hit)
		var is_giant := ((to_level >= 5 and i == mob_count - 1) or (to_level >= 12 and i == mob_count / 2)) and str(spec["kind"]) != "bat"
		var size_mult := 1.0
		if is_giant:
			size_mult = clampf(1.42 + float(to_level) * 0.015, 1.42, 1.82)

		var sc: PackedScene = load(spec["path"])
		var m_root := Node3D.new()
		m_root.position = Vector3(mx, my, mz)
		add_child(m_root)

		var vis := sc.instantiate()
		vis.scale = Vector3.ONE * float(spec["scale"]) * size_mult
		_set_cull(vis, 95.0)
		m_root.add_child(vis)

		var ap := _find_ap(vis)
		var chosen_walk: String = spec["anim_walk"]
		var chosen_atk: String = spec["anim_atk"]
		if ap:
			for aname in ap.get_animation_list():
				var low := str(aname).to_lower()
				if "walk" in low or "idle" in low or "jump" in low or "run" in low or "fly" in low:
					ap.get_animation(aname).loop_mode = Animation.LOOP_LINEAR
			if not ap.has_animation(chosen_walk):
				for aname in ap.get_animation_list():
					var low := str(aname).to_lower()
					if "run" in low or "walk" in low or "fly" in low or "idle" in low:
						chosen_walk = str(aname)
						break
			if not ap.has_animation(chosen_atk):
				for aname in ap.get_animation_list():
					var low := str(aname).to_lower()
					if "attack" in low or "punch" in low or "bite" in low:
						chosen_atk = str(aname)
						break
			if ap.has_animation(chosen_walk):
				ap.play(chosen_walk)

		# Clean Mini 3D HP Bar scaled cleanly above normal or Giant Boss Monster
		var bar_y := 2.15 * maxf(1.0, size_mult * 0.86) + hover_y * 0.35
		var bar_w := 1.25 * (1.35 if is_giant else 1.0)
		var hp_bg := MeshInstance3D.new()
		var hbm := BoxMesh.new(); hbm.size = Vector3(bar_w, 0.14, 0.08)
		hp_bg.mesh = hbm
		var bg_m := StandardMaterial3D.new(); bg_m.albedo_color = Color(0.15, 0.15, 0.2)
		hp_bg.material_override = bg_m
		hp_bg.position = Vector3(0.0, bar_y, 0.0)
		m_root.add_child(hp_bg)

		var hp_fill := MeshInstance3D.new()
		var hfm := BoxMesh.new(); hfm.size = Vector3(bar_w - 0.07, 0.10, 0.10)
		hp_fill.mesh = hfm
		var fm := StandardMaterial3D.new(); fm.albedo_color = Color(1.0, 0.45, 0.10) if is_giant else Color(0.95, 0.22, 0.28)
		hp_fill.material_override = fm
		hp_fill.position = Vector3(0.0, bar_y, 0.02)
		m_root.add_child(hp_fill)

		var kind_s: String = spec["kind"]
		var base_mhp := 100
		if kind_s == "frog":
			base_mhp = 110
		elif kind_s == "spider":
			base_mhp = 125
		elif kind_s == "knight" or kind_s == "warden":
			base_mhp = 160
		elif kind_s == "bat" or kind_s == "mech":
			base_mhp = 120
		var max_mhp := int(round(float(base_mhp + mini(180, maxi(0, to_level - 2) * 14)) * (1.55 if is_giant else 1.0)))
		if kind_s == "bat":
			max_mhp = maxi(2, sword_damage * 2)
		var seg_idx := _get_land_segment_idx(mx)
		if seg_idx < 0:
			seg_idx = 0
		_monsters.append({
			"node": m_root, "vis": vis, "ap": ap, "hp_fill": hp_fill, "hp_mat": fm,
			"kind": kind_s, "home": Vector3(mx, my, mz), "terr_radius": 58.0, "seg_idx": seg_idx, "aggroed": false,
			"hover_y": hover_y, "fly": bool(spec.get("fly", false)), "is_giant": is_giant,
			"hp": max_mhp, "max_hp": max_mhp,
			"dmg": (15 if is_giant or kind_s == "knight" or kind_s == "warden" else 10) + mini(8, to_level - 2),
			"speed": 4.45 if kind_s == "bat" or kind_s == "spider" else (4.10 if kind_s == "mech" or kind_s == "warden" else 3.75),
			"atk_cd": 0.0, "proj_cd": randf_range(0.85, 1.85), "bridge_cd": 0.0, "hurt_t": 0.0, "lunge_t": randf_range(1.2, 2.4), "phase": randf_range(0.0, TAU),
			"anim_walk": chosen_walk, "anim_atk": chosen_atk,
			"alive": true
		})


func _spawn_mc_wall_block(world_pos: Vector3, kind: int) -> void:
	var b_idx := _mc_wall_blocks.size()
	var body := StaticBody3D.new()
	body.collision_layer = 1 | 2
	body.position = world_pos
	body.set_meta("mc_wall_idx", b_idx)
	add_child(body)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(MC_CELL - 0.02, 1.0, MC_CELL - 0.02)
	col.shape = bs
	body.add_child(col)

	var mi := MeshInstance3D.new()
	mi.mesh = _mc_box_mesh
	mi.material_override = _mc_oak_mat if kind == 0 else _mc_stone_mat
	mi.visibility_range_end = 110.0
	body.add_child(mi)

	_mc_wall_blocks.append({"node": body, "pos": world_pos, "kind": kind, "broken": false})


func _build_minecraft_world_blocks() -> void:
	_mc_ghost_mesh = MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(MC_CELL * 1.03, 1.03, MC_CELL * 1.03)
	_mc_ghost_mesh.mesh = gm
	_mc_ghost_mesh.material_override = _mc_ghost_place_mat
	_mc_ghost_mesh.visible = false
	add_child(_mc_ghost_mesh)

	_mc_crack_mesh = MeshInstance3D.new()
	var cm_b := BoxMesh.new()
	cm_b.size = Vector3(MC_CELL * 1.018, 1.018, MC_CELL * 1.018)
	_mc_crack_mesh.mesh = cm_b
	_mc_crack_mesh.visible = false
	add_child(_mc_crack_mesh)

	# Rear resource stacks near the starting fortress walls + along side walls & right before each river crossing
	for step_i in range(4):
		var bx := 8.5 + float(step_i) * 1.32
		_spawn_mc_wall_block(Vector3(bx, 0.50, -8.2), 0 if step_i % 2 == 0 else 1)
		_spawn_mc_wall_block(Vector3(bx, 0.50, 8.2), 1 if step_i % 2 == 0 else 0)
		if step_i < 2:
			_spawn_mc_wall_block(Vector3(bx, 1.50, -8.2), 0)
			_spawn_mc_wall_block(Vector3(bx, 1.50, 8.2), 1)

	var wall_x := 18.0
	while wall_x < journey_len - 12.0:
		if not _is_in_water(wall_x) and get_terrain_y(wall_x) >= -0.05:
			for row_i in range(2):
				var wx := wall_x + float(row_i) * 1.30
				if not _is_in_water(wx):
					_spawn_mc_wall_block(Vector3(wx, 0.50, -8.8), (row_i + int(wall_x)) % 2)
					_spawn_mc_wall_block(Vector3(wx, 0.50, 8.8), (row_i + int(wall_x) + 1) % 2)
		wall_x += 17.5

	# Convenient riverbank lumber/stone stacks flanking EVERY river, scaled with river width!
	for wz in _water_zones:
		var river_w := wz.y - wz.x
		var bank_cols := maxi(3, int(ceil(river_w / 3.6)))
		for k in range(bank_cols):
			var rx_l := wz.x - 1.6 - float(k) * 1.32
			for sgn: float in [-1.0, 1.0]:
				_spawn_mc_wall_block(Vector3(rx_l, 0.50, sgn * 5.2), 0 if k % 2 == 0 else 1)
				if k < 2:
					_spawn_mc_wall_block(Vector3(rx_l, 1.50, sgn * 5.2), 0)
		for k in range(2):
			var rx_r := wz.y + 1.6 + float(k) * 1.32
			_spawn_mc_wall_block(Vector3(rx_r, 0.50, -5.2), 0)
			_spawn_mc_wall_block(Vector3(rx_r, 0.50, 5.2), 1)


func select_mc_slot(slot: int) -> void:
	_mc_active_slot = clampi(slot, 0, 1)
	mc_inventory_changed.emit(_mc_oak_cnt, _mc_stone_cnt, _mc_active_slot)


func get_active_block_count() -> int:
	return _mc_oak_cnt if _mc_active_slot == 0 else _mc_stone_cnt


func _is_near_river_zone(x: float, margin: float = 0.75) -> bool:
	for wz in _water_zones:
		if x >= wz.x - margin and x <= wz.y + margin:
			return true
	return false


func _find_nearest_mineable_any() -> Dictionary:
	if not is_instance_valid(_hero_body):
		return {}
	var hpos := _hero_body.global_position
	var f_dir := Vector3(cos(deg_to_rad(_facing_yaw)), 0.0, -sin(deg_to_rad(_facing_yaw))).normalized()
	var best_tgt: Dictionary = {}
	var best_score := 999.0

	for i in range(_mc_wall_blocks.size()):
		var b: Dictionary = _mc_wall_blocks[i]
		if bool(b["broken"]):
			continue
		var bp: Vector3 = b["pos"]
		var d2 := Vector2(bp.x - hpos.x, bp.z - hpos.z).length()
		if d2 > MC_REACH or absf(bp.y - (hpos.y + 0.5)) > 2.4:
			continue
		var dir_b := Vector3(bp.x - hpos.x, 0.0, bp.z - hpos.z)
		var align_pen := 0.0 if dir_b.length() < 0.05 else (1.0 - dir_b.normalized().dot(f_dir)) * 0.8
		var sc := d2 + align_pen
		if sc < best_score:
			best_score = sc
			best_tgt = {"type": "wall", "idx": i, "pos": bp, "kind": int(b["kind"]), "node": b["node"]}

	for cell_k: Vector2i in _mc_placed_cells.keys():
		var bd: Dictionary = _mc_placed_cells[cell_k]
		var bp: Vector3 = bd["pos"]
		var d2 := Vector2(bp.x - hpos.x, bp.z - hpos.z).length()
		if d2 > MC_REACH or absf(bp.y - hpos.y) > 2.4:
			continue
		var dir_b := Vector3(bp.x - hpos.x, 0.0, bp.z - hpos.z)
		var align_pen := 0.0 if dir_b.length() < 0.05 else (1.0 - dir_b.normalized().dot(f_dir)) * 0.8
		# Slight bonus to mining wall blocks first before dismantling bridge under Hero
		var sc := d2 + align_pen + 0.35
		if sc < best_score:
			best_score = sc
			best_tgt = {"type": "bridge", "key": cell_k, "pos": bp, "kind": int(bd["kind"]), "node": bd["node"]}

	return best_tgt


func _inspect_mine_hit(col_obj: Object) -> Dictionary:
	if col_obj == null or not is_instance_valid(_hero_body):
		return {"status": "none"}
	if col_obj.has_meta("mc_wall_idx"):
		var idx := int(col_obj.get_meta("mc_wall_idx"))
		if idx >= 0 and idx < _mc_wall_blocks.size() and not bool(_mc_wall_blocks[idx]["broken"]):
			var b: Dictionary = _mc_wall_blocks[idx]
			var bp: Vector3 = b["pos"]
			if Vector2(bp.x - _hero_body.global_position.x, bp.z - _hero_body.global_position.z).length() <= MC_REACH + 0.8:
				return {"status": "ok", "target": {"type": "wall", "idx": idx, "pos": bp, "kind": int(b["kind"]), "node": b["node"]}}
			return {"status": "far"}
	elif col_obj.has_meta("mc_bridge_key"):
		var key := col_obj.get_meta("mc_bridge_key") as Vector2i
		if _mc_placed_cells.has(key):
			var bd: Dictionary = _mc_placed_cells[key]
			var bp: Vector3 = bd["pos"]
			if Vector2(bp.x - _hero_body.global_position.x, bp.z - _hero_body.global_position.z).length() <= MC_REACH + 0.8:
				return {"status": "ok", "target": {"type": "bridge", "key": key, "pos": bp, "kind": int(bd["kind"]), "node": bd["node"]}}
			return {"status": "far"}
	return {"status": "none"}


func _find_target_at_screen(screen_pos: Vector2) -> Dictionary:
	if _cam == null or not is_instance_valid(_hero_body):
		return {"status": "none"}
	var space := get_world_3d().direct_space_state
	if not space:
		return {"status": "none"}
	var sample_offsets := [
		Vector2.ZERO,
		Vector2(16, 0), Vector2(-16, 0), Vector2(0, 16), Vector2(0, -16),
		Vector2(24, 20), Vector2(-24, 20), Vector2(24, -20), Vector2(-24, -20),
	]
	var saw_far := false
	for off: Vector2 in sample_offsets:
		var pt := screen_pos + off
		var ray_o := _cam.project_ray_origin(pt)
		var ray_d := _cam.project_ray_normal(pt)
		var q := PhysicsRayQueryParameters3D.create(ray_o, ray_o + ray_d * 52.0)
		q.collision_mask = 2
		var hit := space.intersect_ray(q)
		if hit.is_empty() or not is_instance_valid(hit.get("collider")):
			continue
		var res := _inspect_mine_hit(hit["collider"] as Object)
		if res["status"] == "ok":
			return res
		if res["status"] == "far":
			saw_far = true
	return {"status": "far"} if saw_far else {"status": "none"}


func _find_placeable_river_cell() -> Dictionary:
	if not is_instance_valid(_hero_body):
		return {}
	var hpos := _hero_body.global_position
	var f_dir := Vector3(cos(deg_to_rad(_facing_yaw)), 0.0, -sin(deg_to_rad(_facing_yaw))).normalized()
	var f2 := Vector2(f_dir.x, f_dir.z).normalized()
	var right2 := Vector2(-f2.y, f2.x)
	var center_gx := int(round(hpos.x / MC_CELL))
	var center_gz := int(round(hpos.z / MC_CELL))
	var best_key := Vector2i.ZERO
	var best_score := 999.0
	var found := false
	for dx in range(-4, 5):
		for dz in range(-4, 5):
			var gx := center_gx + dx
			var gz := center_gz + dz
			var wx := float(gx) * MC_CELL
			var wz := float(gz) * MC_CELL
			if absf(wz) > HALF_WIDTH_Z - 0.5 or not _is_near_river_zone(wx, 0.90):
				continue
			var key := Vector2i(gx, gz)
			if _mc_placed_cells.has(key):
				continue
			var rel := Vector2(wx - hpos.x, wz - hpos.z)
			var dist_hero := rel.length()
			if dist_hero > MC_REACH:
				continue
			var fwd_proj := rel.dot(f2)
			var lat_dist := absf(rel.dot(right2))
			var sc := lat_dist * 2.8 + (6.0 + absf(fwd_proj) if fwd_proj < -0.55 else (maxf(0.0, 0.35 - fwd_proj) * 2.5 + maxf(0.0, fwd_proj - 0.85) * 0.72))
			if sc < best_score:
				best_score = sc
				best_key = key
				found = true
	if not found:
		return {}
	return {"key": best_key, "pos": Vector3(float(best_key.x) * MC_CELL, -0.50, float(best_key.y) * MC_CELL)}


func _find_placeable_land_cell() -> Dictionary:
	if not is_instance_valid(_hero_body):
		return {}
	var hpos := _hero_body.global_position
	var f_dir := Vector3(cos(deg_to_rad(_facing_yaw)), 0.0, -sin(deg_to_rad(_facing_yaw))).normalized()
	var tgt := hpos + f_dir * (MC_CELL * 1.35)
	var gx := int(round(tgt.x / MC_CELL))
	var gz := int(round(tgt.z / MC_CELL))
	var wx := float(gx) * MC_CELL
	var wz := float(gz) * MC_CELL
	if absf(wz) > HALF_WIDTH_Z - 0.6 or wx < 4.5 or wx > journey_len - 4.0:
		return {}
	if _is_near_river_zone(wx, 0.90):
		return {}
	if Vector2(wx - hpos.x, wz - hpos.z).length() < 0.78:
		gx = int(round((hpos.x + f_dir.x * (MC_CELL * 1.7)) / MC_CELL))
		gz = int(round((hpos.z + f_dir.z * (MC_CELL * 1.7)) / MC_CELL))
		wx = float(gx) * MC_CELL
		wz = float(gz) * MC_CELL
	if absf(wz) > HALF_WIDTH_Z - 0.6 or _is_near_river_zone(wx, 0.90):
		return {}
	for b in _mc_wall_blocks:
		if not bool(b["broken"]):
			var bp: Vector3 = b["pos"]
			if Vector2(bp.x - wx, bp.z - wz).length() < MC_CELL * 0.72 and absf(bp.y - 0.50) < 0.6:
				return {}
	return {"pos": Vector3(wx, 0.50, wz)}


func _spawn_mc_drop(pos: Vector3, kind: int) -> void:
	var drop_node := Node3D.new()
	var spawn_p := pos + Vector3(0.0, 0.35, 0.0)
	if is_instance_valid(_hero_body):
		spawn_p = Vector3(
			lerpf(pos.x, _hero_body.global_position.x, 0.24),
			maxf(pos.y + 0.32, 0.36),
			lerpf(pos.z, _hero_body.global_position.z, 0.24)
		)
	drop_node.position = spawn_p
	add_child(drop_node)

	var mi := MeshInstance3D.new()
	mi.mesh = _mc_drop_mesh
	mi.material_override = _mc_oak_mat if kind == 0 else _mc_stone_mat
	mi.scale = Vector3(0.2, 0.2, 0.2)
	drop_node.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_mc_drops.append({
		"node": drop_node,
		"kind": kind,
		"base_y": spawn_p.y,
		"phase": randf_range(0.0, TAU),
		"age": 0.0,
		"taken": false,
	})


func _finish_break_target(tgt: Dictionary) -> void:
	if tgt.is_empty():
		return
	var kind := int(tgt.get("kind", 0))
	var bp: Vector3 = tgt.get("pos", Vector3.ZERO)
	if tgt["type"] == "wall":
		var idx := int(tgt["idx"])
		if idx < 0 or idx >= _mc_wall_blocks.size() or bool(_mc_wall_blocks[idx]["broken"]):
			return
		_mc_wall_blocks[idx]["broken"] = true
		var nd: Node3D = _mc_wall_blocks[idx]["node"]
		if is_instance_valid(nd):
			nd.queue_free()
	elif tgt["type"] == "bridge":
		var key := tgt["key"] as Vector2i
		if not _mc_placed_cells.has(key):
			return
		var bd: Dictionary = _mc_placed_cells[key]
		var nd: Node3D = bd["node"]
		_mc_placed_cells.erase(key)
		if is_instance_valid(nd):
			nd.queue_free()

	_spawn_mc_drop(bp, kind)
	_spawn_fx(bp + Vector3(0, 0.25, 0), 10, Color(0.76, 0.54, 0.30) if kind == 0 else Color(0.62, 0.66, 0.72))
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(24)
	if audio:
		audio.play("hit_heavy", randf_range(1.12, 1.28), -7.5, 80)


func begin_mine_at_screen(screen_pos: Vector2) -> bool:
	if j_state != JState.PLAYING or not is_instance_valid(_hero_body):
		return false
	var res := _find_target_at_screen(screen_pos)
	if res["status"] == "far":
		mc_toast.emit(Loc.t("mc_move_closer"))
		return false
	if res["status"] != "ok":
		return false
	_start_mining_target(res["target"])
	return true


func _start_mining_target(tgt: Dictionary) -> void:
	_mine_active = true
	_mine_target = tgt
	_mine_progress = 0.0
	_mine_sfx_cd = 0.0
	if is_instance_valid(_hero_vis):
		_hero_vis.play_sword_swing()
	if is_instance_valid(_mc_crack_mesh) and _mc_crack_mats.size() > 0:
		_mc_crack_mesh.visible = true
		_mc_crack_mesh.position = tgt["pos"]
		_mc_crack_mesh.material_override = _mc_crack_mats[0]


func cancel_mining() -> void:
	_mine_active = false
	_mine_target = {}
	_mine_progress = 0.0
	if is_instance_valid(_mc_crack_mesh):
		_mc_crack_mesh.visible = false


func trigger_place_block() -> void:
	if j_state != JState.PLAYING or not is_instance_valid(_hero_body):
		return
	var total_blk := _mc_oak_cnt + _mc_stone_cnt
	if total_blk <= 0:
		mc_toast.emit(Loc.t("mc_need_blocks"))
		return
	var cell_info := _find_placeable_river_cell()
	if not cell_info.is_empty():
		_place_mc_bridge_block(cell_info["key"], cell_info["pos"])
		if is_instance_valid(_hero_vis):
			_hero_vis.play_sword_swing()
		return
	if not _is_in_water(_hero_body.global_position.x):
		var land_info := _find_placeable_land_cell()
		if not land_info.is_empty():
			var use_slot := _mc_active_slot
			if use_slot == 0 and _mc_oak_cnt <= 0 and _mc_stone_cnt > 0:
				use_slot = 1
			elif use_slot == 1 and _mc_stone_cnt <= 0 and _mc_oak_cnt > 0:
				use_slot = 0
			if use_slot == 0:
				_mc_oak_cnt -= 1
			else:
				_mc_stone_cnt -= 1
			_mc_active_slot = use_slot
			var lp: Vector3 = land_info["pos"]
			_spawn_mc_wall_block(lp, use_slot)
			if is_instance_valid(_hero_vis):
				_hero_vis.play_sword_swing()
			_spawn_fx(lp + Vector3(0, 0.55, 0), 6, Color(0.82, 0.62, 0.36) if use_slot == 0 else Color(0.72, 0.76, 0.80))
			if audio:
				audio.play("land", randf_range(0.92, 1.06), -6.5, 90)
			mc_inventory_changed.emit(_mc_oak_cnt, _mc_stone_cnt, _mc_active_slot)
			return
	mc_toast.emit(Loc.t("mc_move_closer"))


func begin_mine_or_place_hold() -> void:
	if j_state != JState.PLAYING or not is_instance_valid(_hero_body):
		return
	var total_blk := _mc_oak_cnt + _mc_stone_cnt
	var near_tgt := _find_nearest_mineable_any()
	var cell_info := _find_placeable_river_cell()
	var near_river := _is_near_river_zone(_hero_body.global_position.x, 3.6)

	if not cell_info.is_empty() and total_blk > 0 and (near_tgt.is_empty() or near_tgt["type"] == "bridge"):
		_place_mc_bridge_block(cell_info["key"], cell_info["pos"])
		return
	if not near_tgt.is_empty():
		_start_mining_target(near_tgt)
		return
	if near_river and total_blk == 0:
		mc_toast.emit(Loc.t("mc_need_blocks"))
	elif total_blk > 0:
		trigger_place_block()
	else:
		mc_toast.emit(Loc.t("mc_hint_gather"))


func end_build_hold() -> void:
	cancel_mining()


func _advance_mining(delta: float) -> void:
	if not _mine_active or _mine_target.is_empty() or not is_instance_valid(_hero_body):
		cancel_mining()
		return
	# Verify target still exists & remains within reach
	var valid_tgt := false
	if _mine_target["type"] == "wall":
		var idx := int(_mine_target["idx"])
		valid_tgt = idx >= 0 and idx < _mc_wall_blocks.size() and not bool(_mc_wall_blocks[idx]["broken"])
	elif _mine_target["type"] == "bridge":
		valid_tgt = _mc_placed_cells.has(_mine_target["key"])
	if not valid_tgt:
		cancel_mining()
		return

	var bp: Vector3 = _mine_target["pos"]
	if Vector2(bp.x - _hero_body.global_position.x, bp.z - _hero_body.global_position.z).length() > MC_REACH + 0.7:
		cancel_mining()
		return

	_mine_progress += delta
	_mine_sfx_cd -= delta
	var frac := clampf(_mine_progress / MC_MINE_DURATION, 0.0, 0.999)
	var stage := clampi(int(floor(frac * 4.0)), 0, _mc_crack_mats.size() - 1)
	if is_instance_valid(_mc_crack_mesh):
		_mc_crack_mesh.visible = true
		_mc_crack_mesh.position = bp + Vector3(randf_range(-0.018, 0.018), randf_range(-0.014, 0.014), randf_range(-0.018, 0.018))
		_mc_crack_mesh.material_override = _mc_crack_mats[stage]

	if _mine_sfx_cd <= 0.0:
		_mine_sfx_cd = 0.21
		if is_instance_valid(_hero_vis):
			_hero_vis.play_sword_swing()
		var kind := int(_mine_target.get("kind", 0))
		_spawn_fx(bp + Vector3(0, 0.2, 0), 3, Color(0.76, 0.54, 0.30) if kind == 0 else Color(0.62, 0.66, 0.72))
		if audio:
			audio.play("hit", randf_range(0.85, 1.05), -13.0, 60)

	if _mine_progress >= MC_MINE_DURATION:
		var broken_tgt := _mine_target
		cancel_mining()
		_finish_break_target(broken_tgt)


func _place_mc_bridge_block(cell_key: Vector2i, place_pos: Vector3) -> void:
	var use_slot := _mc_active_slot
	if use_slot == 0 and _mc_oak_cnt <= 0 and _mc_stone_cnt > 0:
		use_slot = 1
	elif use_slot == 1 and _mc_stone_cnt <= 0 and _mc_oak_cnt > 0:
		use_slot = 0
	var avail := _mc_oak_cnt if use_slot == 0 else _mc_stone_cnt
	if avail <= 0:
		mc_toast.emit(Loc.t("mc_need_blocks"))
		return
	if _mc_placed_cells.has(cell_key):
		return

	if use_slot == 0:
		_mc_oak_cnt -= 1
	else:
		_mc_stone_cnt -= 1
	_mc_active_slot = use_slot

	var body := StaticBody3D.new()
	body.collision_layer = 1 | 2
	body.position = place_pos
	body.set_meta("mc_bridge_key", cell_key)
	add_child(body)

	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(MC_CELL + 0.04, 1.0, MC_CELL + 0.04)
	col.shape = bs
	body.add_child(col)

	var mi := MeshInstance3D.new()
	mi.mesh = _mc_box_mesh
	mi.material_override = _mc_oak_mat if use_slot == 0 else _mc_stone_mat
	mi.scale = Vector3(0.4, 0.4, 0.4)
	body.add_child(mi)
	var btw := mi.create_tween()
	btw.tween_property(mi, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_mc_place_seq += 1
	_mc_placed_cells[cell_key] = {"node": body, "pos": place_pos, "kind": use_slot, "hp": 2, "seq": _mc_place_seq}
	if is_instance_valid(_hero_body):
		var d_hero := Vector2(_hero_body.global_position.x - place_pos.x, _hero_body.global_position.z - place_pos.z).length()
		if d_hero < MC_CELL * 0.72 and _hero_body.global_position.y < 0.02:
			_hero_body.global_position.y = 0.04
	_spawn_fx(place_pos + Vector3(0, 0.55, 0), 6, Color(0.82, 0.62, 0.36) if use_slot == 0 else Color(0.72, 0.76, 0.80))
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(18)
	if audio:
		audio.play("land", randf_range(0.92, 1.06), -6.5, 90)
	mc_inventory_changed.emit(_mc_oak_cnt, _mc_stone_cnt, _mc_active_slot)


func trigger_mc_build_or_mine() -> void:
	trigger_place_block()


func trigger_mc_build_or_mine_at_screen(screen_pos: Vector2) -> void:
	if j_state != JState.PLAYING or _cam == null or not is_instance_valid(_hero_body):
		return
	var ray_o := _cam.project_ray_origin(screen_pos)
	var ray_d := _cam.project_ray_normal(screen_pos)
	if absf(ray_d.y) > 0.02:
		var t_plane := -ray_o.y / ray_d.y
		if t_plane > 0.0 and t_plane < 48.0:
			var wp := ray_o + ray_d * t_plane
			if _is_near_river_zone(wp.x, 0.90) and absf(wp.z) <= HALF_WIDTH_Z - 0.5:
				var d_h := Vector2(wp.x - _hero_body.global_position.x, wp.z - _hero_body.global_position.z).length()
				if d_h > MC_REACH + 0.6:
					mc_toast.emit(Loc.t("mc_move_closer"))
					return
				var key := Vector2i(int(round(wp.x / MC_CELL)), int(round(wp.z / MC_CELL)))
				var ppos := Vector3(float(key.x) * MC_CELL, -0.50, float(key.y) * MC_CELL)
				_place_mc_bridge_block(key, ppos)
				return
	trigger_place_block()


func _update_mc_ghost_preview() -> void:
	if not is_instance_valid(_mc_ghost_mesh) or j_state != JState.PLAYING or not is_instance_valid(_hero_body) or _mine_active:
		if is_instance_valid(_mc_ghost_mesh):
			_mc_ghost_mesh.visible = false
		return
	var total_blk := _mc_oak_cnt + _mc_stone_cnt
	var near_tgt := _find_nearest_mineable_any()
	var cell_info := _find_placeable_river_cell()
	if not cell_info.is_empty() and total_blk > 0:
		_mc_ghost_mesh.visible = true
		_mc_ghost_mesh.position = cell_info["pos"]
		_mc_ghost_mesh.material_override = _mc_ghost_place_mat
		return
	if total_blk > 0 and not _is_in_water(_hero_body.global_position.x):
		var land_info := _find_placeable_land_cell()
		if not land_info.is_empty():
			_mc_ghost_mesh.visible = true
			_mc_ghost_mesh.position = land_info["pos"]
			_mc_ghost_mesh.material_override = _mc_ghost_place_mat
			return
	if not near_tgt.is_empty():
		_mc_ghost_mesh.visible = true
		_mc_ghost_mesh.position = near_tgt["pos"]
		_mc_ghost_mesh.material_override = _mc_ghost_mine_mat
		return
	_mc_ghost_mesh.visible = false


func _build_hero() -> void:
	_hero_body = CharacterBody3D.new()
	_hero_body.collision_layer = 16
	_hero_body.collision_mask = 1
	_hero_body.floor_max_angle = deg_to_rad(52.0)
	_hero_body.floor_snap_length = 0.35
	_hero_body.position = Vector3(-2.4, 0.0, 0.0)
	add_child(_hero_body)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32; cap.height = 1.48
	col.shape = cap
	col.position = Vector3(0.0, 0.74, 0.0)
	_hero_body.add_child(col)

	_hero_vis = Haneen3DCharacter.new()
	_hero_vis.character_id = char_id
	_hero_vis.clear_sad_sit()
	_hero_vis.attach_sword(true)
	_hero_body.add_child(_hero_vis)

	# Crisp forward sword slash blade-wave VFX (compact forward arc in front of Hero, never rings enemies)
	_vfx_slash_mesh = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.62; tm.outer_radius = 0.80
	_vfx_slash_mesh.mesh = tm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.90, 0.35, 0.88)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_vfx_slash_mesh.material_override = smat
	_vfx_slash_mesh.scale = Vector3(0.85, 0.14, 0.70)
	_vfx_slash_mesh.rotation_degrees = Vector3(24.0, 0.0, -18.0)
	_vfx_slash_mesh.position = Vector3(0.85, 0.92, 0.0)
	_vfx_slash_mesh.visible = false
	_hero_body.add_child(_vfx_slash_mesh)

	_shield_aura = MeshInstance3D.new()
	var sam := TorusMesh.new(); sam.inner_radius = 0.68; sam.outer_radius = 0.80
	_shield_aura.mesh = sam
	var sa_mat := StandardMaterial3D.new()
	sa_mat.albedo_color = Color(1.0, 0.84, 0.22, 0.82)
	sa_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sa_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shield_aura.material_override = sa_mat
	_shield_aura.position = Vector3(0, 0.92, 0)
	_shield_aura.visible = false
	_hero_body.add_child(_shield_aura)


func skip_intro() -> void:
	if j_state != JState.INTRO_CINEMATIC:
		return
	_intro_t = _intro_dur
	if is_instance_valid(_hero_body):
		_hero_body.position = Vector3(7.6, 0.0, 0.0)
	_seal_origin_gate()
	j_state = JState.PLAYING
	intro_finished.emit()


func set_touch_move(dir_vec: Vector2) -> void:
	_touch_move = Vector2(clampf(dir_vec.x, -1.0, 1.0), clampf(dir_vec.y, -1.0, 1.0))


func trigger_jump() -> void:
	if j_state != JState.PLAYING:
		return
	_touch_jump_req = true


func trigger_dash() -> void:
	if j_state != JState.PLAYING or _dash_cd > 0.0:
		return
	_dash_cd = 0.95
	var dash_dir := Vector3(cos(deg_to_rad(_facing_yaw)), 0.0, -sin(deg_to_rad(_facing_yaw))).normalized()
	_hero_body.velocity.x = dash_dir.x * 20.5
	_hero_body.velocity.z = dash_dir.z * 20.5
	_spawn_fx(_hero_body.global_position + Vector3(0, 0.5, 0), 5, Color(1.0, 0.92, 0.5))
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(24)
	if audio:
		audio.play("boost", 1.1, -11.0, 120)


func trigger_sword_attack() -> void:
	if j_state != JState.PLAYING or _attack_cd > 0.0:
		return
	_attack_cd = 0.34
	_hero_vis.play_sword_swing()
	if audio:
		audio.play_variant(["sword_whoosh_1", "sword_whoosh_2"], 0.94, 1.07, -6.5, 90)
		audio.play_hero_voice(char_id, "effort")

	# Show swift forward slash wave anchored right in front of Hero along facing direction (+X when yaw=0)
	var f_dir := Vector3(cos(deg_to_rad(_facing_yaw)), 0.0, -sin(deg_to_rad(_facing_yaw))).normalized()
	if is_instance_valid(_vfx_slash_mesh):
		_vfx_slash_mesh.visible = true
		_vfx_slash_mesh.position = f_dir * 0.95 + Vector3(0, 0.92, 0)
		_vfx_slash_mesh.rotation_degrees = Vector3(22.0, _facing_yaw - 35.0, -18.0)
		_vfx_slash_mesh.scale = Vector3(0.55, 0.12, 0.45)
		var tw := _vfx_slash_mesh.create_tween()
		tw.set_parallel(true)
		tw.tween_property(_vfx_slash_mesh, "rotation_degrees:y", _facing_yaw + 55.0, 0.14)
		tw.tween_property(_vfx_slash_mesh, "scale", Vector3(1.05, 0.16, 0.85), 0.14)
		tw.chain().tween_callback(func(): _vfx_slash_mesh.visible = false)

	var forward_dir := Vector3(cos(deg_to_rad(_facing_yaw)), 0.0, -sin(deg_to_rad(_facing_yaw))).normalized()
	for m in _monsters:
		if not m["alive"]:
			continue
		var mn: Node3D = m["node"]
		var dvec := mn.global_position - _hero_body.global_position
		dvec.y = 0.0
		var dist_hit := dvec.length()
		var in_front := dist_hit <= 2.15 or (dist_hit <= 2.45 and dvec.normalized().dot(forward_dir) >= 0.15)
		if in_front:
			m["hp"] = maxi(0, int(m["hp"]) - sword_damage)
			m["aggroed"] = true
			m["hurt_t"] = 0.08
			var kb := 0.22 if (str(m["kind"]) == "knight" or str(m["kind"]) == "warden" or bool(m.get("is_giant", false))) else 0.42
			var push_dir := (dvec.normalized() if dist_hit > 0.05 else forward_dir)
			var knocked := mn.global_position + push_dir * kb
			if bool(m.get("fly", false)) or (not _is_in_water(knocked.x)) or (not _has_bridge_at(knocked.x, knocked.z).is_empty()):
				mn.global_position = knocked
			mn.global_position.y = _monster_floor_y(mn.position.x, mn.position.z) + float(m.get("hover_y", 0.0))
			var frac := clampf(float(m["hp"]) / float(m["max_hp"]), 0.0, 1.0)
			var hpf: MeshInstance3D = m["hp_fill"]
			if is_instance_valid(hpf):
				hpf.scale.x = maxf(0.01, frac)
				var hp_mat: StandardMaterial3D = m.get("hp_mat", null)
				if hp_mat:
					hp_mat.albedo_color = Color(0.96, 0.62, 0.14) if frac > 0.35 else Color(0.96, 0.18, 0.22)
			var mvis: Node3D = m["vis"]
			if is_instance_valid(mvis):
				var htw := mvis.create_tween()
				mvis.scale = Vector3.ONE * mvis.scale.x * 1.18 if absf(mvis.scale.x) > 0.01 else Vector3.ONE
				var rest_sc: float = mvis.scale.y
				mvis.scale = Vector3(rest_sc * 1.22, rest_sc * 0.84, rest_sc * 1.22)
				htw.tween_property(mvis, "scale", Vector3.ONE * rest_sc, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_spawn_fx(mn.global_position + Vector3(0, 0.9, 0), 5, Color(1.0, 0.92, 0.45))
			if OS.has_feature("mobile"):
				Input.vibrate_handheld(28)
			if audio:
				audio.play("hit_heavy", randf_range(0.92, 1.08), -6.5, 80)
				audio.play("metal_hit", randf_range(0.95, 1.06), -12.0, 80)
			if int(m["hp"]) <= 0:
				m["alive"] = false
				journey_coins += 5
				coins_changed.emit(journey_coins)
				_spawn_fx(mn.global_position + Vector3(0, 0.8, 0), 8, Color(1.0, 0.82, 0.22))
				mn.queue_free()


func rotate_camera(dx: float, dy: float) -> void:
	_cam_yaw = wrapf(_cam_yaw + dx * 0.0065, -PI, PI)
	_cam_pitch = clampf(_cam_pitch - dy * 0.0055, -0.95, 0.16)


func _has_bridge_at(wx: float, wz: float) -> Dictionary:
	var c_gx := int(round(wx / MC_CELL))
	var c_gz := int(round(wz / MC_CELL))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var k := Vector2i(c_gx + dx, c_gz + dz)
			if _mc_placed_cells.has(k):
				var bd: Dictionary = _mc_placed_cells[k]
				var bp: Vector3 = bd["pos"]
				if absf(wx - bp.x) <= MC_CELL * 0.62 and absf(wz - bp.z) <= MC_CELL * 0.62:
					return bd
	return {}


func _monster_floor_y(wx: float, wz: float) -> float:
	if not _has_bridge_at(wx, wz).is_empty():
		return 0.00
	return get_terrain_y(wx)


func _find_adjacent_bridge_cell(pos: Vector3) -> Variant:
	var best_k: Variant = null
	var best_d := 2.35
	for k: Vector2i in _mc_placed_cells.keys():
		var bd: Dictionary = _mc_placed_cells[k]
		var bp: Vector3 = bd["pos"]
		var d := Vector2(bp.x - pos.x, bp.z - pos.z).length()
		if d < best_d:
			best_d = d
			best_k = k
	return best_k


func _find_bridge_entry_near(mpos: Vector3) -> Variant:
	var best_p: Variant = null
	var best_d := 14.0
	for k: Vector2i in _mc_placed_cells.keys():
		var bd: Dictionary = _mc_placed_cells[k]
		var bp: Vector3 = bd["pos"]
		var d := Vector2(bp.x - mpos.x, bp.z - mpos.z).length()
		if d < best_d:
			best_d = d
			best_p = bp
	return best_p


func _update_mc_drops(delta: float) -> void:
	if _mc_drops.is_empty() or not is_instance_valid(_hero_body):
		return
	var t := Time.get_ticks_msec() * 0.001
	var hpos := _hero_body.global_position + Vector3(0.0, 0.55, 0.0)
	var idx := _mc_drops.size() - 1
	while idx >= 0:
		var d_entry: Dictionary = _mc_drops[idx]
		var dn: Node3D = d_entry["node"]
		if not is_instance_valid(dn) or bool(d_entry["taken"]):
			_mc_drops.remove_at(idx)
			idx -= 1
			continue
		d_entry["age"] = float(d_entry["age"]) + delta
		dn.rotation_degrees.y += delta * 135.0
		var bob_y: float = float(d_entry["base_y"]) + sin(t * 4.2 + float(d_entry["phase"])) * 0.11
		var dist_h := dn.position.distance_to(hpos)
		if float(d_entry["age"]) > 0.18 and dist_h < 2.25:
			# Smooth magnet suction toward Hero
			dn.position = dn.position.lerp(hpos, minf(1.0, delta * 14.0))
			if dn.position.distance_to(hpos) < 0.72:
				d_entry["taken"] = true
				dn.queue_free()
				var kind := int(d_entry["kind"])
				if kind == 0:
					_mc_oak_cnt += 1
					if _mc_stone_cnt == 0:
						_mc_active_slot = 0
				else:
					_mc_stone_cnt += 1
					if _mc_oak_cnt == 0:
						_mc_active_slot = 1
				if audio:
					audio.play("coin", 1.28, -9.0, 45)
				mc_inventory_changed.emit(_mc_oak_cnt, _mc_stone_cnt, _mc_active_slot)
				_mc_drops.remove_at(idx)
		else:
			dn.position.y = bob_y
		idx -= 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if j_state == JState.INTRO_CINEMATIC:
		if event.is_action_pressed("jump") or (not GameFonts.is_touch_ui() and event is InputEventMouseButton and event.pressed):
			skip_intro()
		return
	if j_state != JState.PLAYING:
		return
	if event.is_action_pressed("attack"):
		trigger_sword_attack()
	elif event is InputEventKey:
		var kev := event as InputEventKey
		if kev.keycode == KEY_E or kev.keycode == KEY_F:
			if kev.pressed:
				trigger_place_block()
		elif kev.pressed and kev.keycode == KEY_1:
			select_mc_slot(0)
		elif kev.pressed and kev.keycode == KEY_2:
			select_mc_slot(1)
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT and not GameFonts.is_touch_ui():
		trigger_mc_build_or_mine_at_screen((event as InputEventMouseButton).position)
	elif event.is_action_pressed("dash"):
		trigger_dash()


func _physics_process(delta: float) -> void:
	if j_state == JState.INTRO_CINEMATIC:
		_intro_t += delta
		_update_intro_camera(_intro_t)
		if _intro_t >= _intro_dur:
			_hero_body.position = Vector3(7.6, 0.0, 0.0)
			_seal_origin_gate()
			j_state = JState.PLAYING
			intro_finished.emit()
		return

	if j_state == JState.TRAP_RESET:
		_trap_reset_t += delta
		var tk := clampf(_trap_reset_t / 1.35, 0.0, 1.0)
		var sk := smoothstep(0.0, 1.0, tk)
		if is_instance_valid(_origin_door_l):
			_origin_door_l.rotation_degrees.y = lerpf(0.0, -92.0, minf(1.0, tk * 2.2))
		if is_instance_valid(_origin_door_r):
			_origin_door_r.rotation_degrees.y = lerpf(0.0, 92.0, minf(1.0, tk * 2.2))
		if is_instance_valid(_hero_body):
			_hero_body.position = Vector3(lerpf(-1.2, 5.2, sk), 0.0, 0.0)
			_hero_vis.rotation_degrees.y = 0.0
			_hero_vis.play_anim("walk", 1.08, 0.1)
		if _cam:
			_cam.position = Vector3(11.0, 4.2, 5.2).lerp(Vector3(-1.4, 3.6, 0.0), sk)
			_cam.look_at(Vector3(1.5, 1.8, 0.0).lerp(Vector3(11.0, 1.5, 0.0), sk))
		if _trap_reset_t >= 1.35:
			_seal_origin_gate()
			_facing_yaw = 0.0
			_invuln_t = 1.6
			j_state = JState.PLAYING
		return

	if j_state == JState.REVIVING:
		_revive_t += delta
		var rk := clampf(_revive_t / 0.95, 0.0, 1.0)
		if is_instance_valid(_shield_aura):
			_shield_aura.visible = true
			_shield_aura.rotation_degrees.y += delta * 360.0
			_shield_aura.rotation_degrees.x = sin(_revive_t * 8.0) * 18.0
		if _cam:
			var angle := lerpf(PI * 1.4, 0.0, smoothstep(0.0, 1.0, rk))
			var rad := lerpf(8.2, 6.8, rk)
			var h := lerpf(5.8, 3.45, rk)
			var c_pos := Vector3(_revive_center.x - cos(angle) * rad, _revive_center.y + h, _revive_center.z + sin(angle) * rad * 0.72)
			_cam.position = c_pos
			_cam.look_at(_revive_center + Vector3(lerpf(0.0, 9.5, rk), lerpf(1.2, 2.05, rk), 0.0))
		if _revive_t >= 0.95:
			j_state = JState.PLAYING
		return

	if j_state == JState.DEFEATED:
		if _defeat_reason == "water" and is_instance_valid(_hero_body):
			var elapsed := clampf(1.45 - maxf(0.0, _defeat_delay_t), 0.0, 1.45)
			var w_y := -0.16 - minf(0.42, elapsed * 0.28) + sin(Time.get_ticks_msec() * 0.011) * 0.055
			_hero_body.global_position.y = lerpf(_hero_body.global_position.y, w_y, minf(1.0, delta * 8.0))
			_water_step_t += delta
			if _water_step_t >= 0.28:
				_water_step_t = 0.0
				_spawn_fx(_hero_body.global_position + Vector3(0, 0.24, 0), 5, Color(0.55, 0.92, 1.0))
		if _defeat_delay_t > 0.0:
			_defeat_delay_t -= delta
			if _defeat_delay_t <= 0.0:
				_defeat_delay_t = -1.0
				journey_failed.emit(_defeat_reason, journey_coins)
		return

	if j_state != JState.PLAYING:
		return

	if _attack_cd > 0.0:
		_attack_cd -= delta
	if _dash_cd > 0.0:
		_dash_cd -= delta
	if _mine_active:
		_advance_mining(delta)
	_update_mc_drops(delta)

	if _invuln_t > 0.0:
		_invuln_t -= delta
		if is_instance_valid(_shield_aura):
			_shield_aura.visible = true
			_shield_aura.rotation_degrees.y += delta * 240.0
	else:
		if is_instance_valid(_shield_aura):
			_shield_aura.visible = false
	_hero_vis.visible = true

	# Camera-relative 360-degree Movement (Joystick/WASD always follows where camera faces!)
	var kb_fwd := (1.0 if (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) else 0.0) - (1.0 if (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) else 0.0)
	var kb_side := (1.0 if (Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) else 0.0) - (1.0 if (Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)) else 0.0)
	var fwd := clampf(kb_fwd + _touch_move.x, -1.0, 1.0)
	var side := clampf(kb_side + _touch_move.y, -1.0, 1.0)
	var cam_fwd := Vector3(cos(_cam_yaw), 0.0, sin(_cam_yaw))
	var cam_right := Vector3(-sin(_cam_yaw), 0.0, cos(_cam_yaw))
	var move_v := cam_fwd * fwd + cam_right * side
	if move_v.length() > 1.0:
		move_v = move_v.normalized()

	var in_water := _is_in_water(_hero_body.global_position.x) and (_hero_body.global_position.y < -0.10)
	var spd := MOVE_SPEED * (WATER_SPEED_MULT if in_water else 1.0)
	var j_accel := 28.0 if move_v.length() > 0.1 else 34.0
	var j_k := 1.0 - exp(-j_accel * delta)
	_hero_body.velocity.x = lerpf(_hero_body.velocity.x, move_v.x * spd, j_k)
	_hero_body.velocity.z = lerpf(_hero_body.velocity.z, move_v.z * spd, j_k)

	if move_v.length() > 0.12:
		var tgt_yaw := rad_to_deg(atan2(-move_v.z, move_v.x))
		_facing_yaw = rad_to_deg(lerp_angle(deg_to_rad(_facing_yaw), deg_to_rad(tgt_yaw), minf(1.0, delta * 22.0)))
	_hero_vis.rotation_degrees.y = _facing_yaw

	if _hero_body.is_on_floor():
		if not in_water and _hero_body.global_position.x > 6.0 and _hero_body.global_position.x < journey_len - 4.0:
			_last_fail_pos = _hero_body.global_position
		if Input.is_key_pressed(KEY_SPACE) or _touch_jump_req:
			_touch_jump_req = false
			_hero_body.velocity.y = JUMP_VY
			_squash = Vector3(0.86, 1.18, 0.86)
			if OS.has_feature("mobile"):
				Input.vibrate_handheld(20)
			if audio:
				audio.play("jump", 1.0, -9.0, 120)
				audio.play_hero_voice(char_id, "effort")
	else:
		_touch_jump_req = false
		_hero_body.velocity.y -= GRAVITY * delta

	_hero_body.move_and_slide()
	_hero_body.global_position.z = clampf(_hero_body.global_position.z, -HALF_WIDTH_Z, HALF_WIDTH_Z)

	# River Hazard Check: Falling into open deep water without a Minecraft bridge triggers drown struggle!
	if _is_in_water(_hero_body.global_position.x) and _hero_body.global_position.y < -0.26 and _has_bridge_at(_hero_body.global_position.x, _hero_body.global_position.z).is_empty():
		_spawn_fx(_hero_body.global_position + Vector3(0, 0.25, 0), 12, Color(0.36, 0.86, 1.0))
		if audio:
			audio.play("water_plunge", 0.94, -6.5, 160)
		_trigger_journey_defeat("water")
		return

	if _hero_body.global_position.x >= 4.2 and not _gate_locked:
		_seal_origin_gate()

	if _hero_body.global_position.x >= journey_len - 8.5 and not _dest_doors_open:
		_open_dest_doors()

	# Realistic Living Footsteps & Water Splashes ("أصوات حية")
	if in_water:
		if not _was_in_water:
			_spawn_fx(_hero_body.global_position + Vector3(0, 0.15, 0), 7, Color(0.45, 0.88, 1.0))
			if audio:
				audio.play("water_plunge", randf_range(0.94, 1.05), -8.5, 180)
		if move_v.length() > 0.15:
			_water_step_t += delta
			if _water_step_t >= 0.28:
				_water_step_t = 0.0
				_spawn_fx(_hero_body.global_position + Vector3(0, 0.12, 0), 4, Color(0.55, 0.92, 1.0))
				if audio:
					audio.play_variant(["water_splash_1", "water_splash_2"], 0.92, 1.08, -9.5, 180)
	elif _hero_body.is_on_floor() and move_v.length() > 0.20:
		_dry_step_t += delta
		if _dry_step_t >= 0.30:
			_dry_step_t = 0.0
			if audio:
				if absf(_hero_body.global_position.z) <= 2.3:
					audio.play_variant(["step_stone_1", "step_stone_2"], 0.95, 1.08, -14.0, 180)
				else:
					audio.play_variant(["step_grass_1", "step_grass_2"], 0.94, 1.07, -13.0, 180)
	_was_in_water = in_water

	_squash = _squash.lerp(Vector3.ONE, minf(1.0, delta * 14.0))
	_hero_vis.scale = _squash
	if not _hero_body.is_on_floor():
		_hero_vis.play_anim("jump" if _hero_body.velocity.y > 0.0 else "fall", 1.25, 0.10)
	elif move_v.length() > 0.15:
		_hero_vis.play_anim("walk" if in_water else "run", 1.15 if in_water else 1.38, 0.10)
	else:
		_hero_vis.play_anim("idle", 1.0, 0.14)

	_update_traps_pickups_monsters(delta)
	_update_water_eaters(delta)
	_update_mc_ghost_preview()
	_update_chase_camera(delta)

	# Destination Kingdom Arrival Check: walk cleanly up to open doorway without stepping blindly into white chamber
	if _hero_body.global_position.x >= journey_len - 0.65:
		j_state = JState.VICTORY
		_close_dest_doors()
		_spawn_fx(_hero_body.global_position + Vector3(0, 1.8, 0), 14, Color(1.0, 0.82, 0.22))
		if audio:
			audio.play("win", 1.0, -6.0, 250)
		journey_completed.emit(to_level, journey_coins)


func _update_intro_camera(t: float) -> void:
	if _cam == null:
		return
	if t < 1.10:
		var k := smoothstep(0.0, 1.0, t / 1.10)
		if is_instance_valid(_origin_door_l):
			_origin_door_l.rotation_degrees.y = lerpf(0.0, -92.0, k)
		if is_instance_valid(_origin_door_r):
			_origin_door_r.rotation_degrees.y = lerpf(0.0, 92.0, k)
		if t > 0.12 and not _gate_opened_sfx and audio:
			_gate_opened_sfx = true
			audio.play("gate_open", 0.92, -6.5, 200)
			audio.play("gate_creak", 0.90, -10.0, 200)
		if is_instance_valid(_hero_body):
			_hero_body.position.x = lerpf(1.4, 7.6, k)
			_hero_vis.play_anim("walk", 1.05, 0.12)
		_cam.position = Vector3(11.5, 4.2, 6.0).lerp(Vector3(14.2, 4.9, 4.6), k)
		_cam.look_at(Vector3(2.8, 2.2, 0.0))
	else:
		var k2 := smoothstep(0.0, 1.0, (t - 1.10) / (_intro_dur - 1.10))
		var target_cam := Vector3(2.2, 3.6, 0.0)
		_cam.position = Vector3(14.2, 4.9, 4.6).lerp(target_cam, k2)
		_cam.look_at(Vector3(2.8, 2.2, 0.0).lerp(Vector3(17.1, 2.05, 0.0), k2))


func _update_chase_camera(delta: float) -> void:
	if _cam == null:
		return
	var hp := _hero_body.global_position
	var cam_fwd := Vector3(cos(_cam_yaw), 0.0, sin(_cam_yaw))
	var horiz_r := cos(_cam_pitch) * _cam_dist
	var vert_h := -sin(_cam_pitch) * _cam_dist + 1.55
	var desired := hp - cam_fwd * horiz_r + Vector3(0.0, vert_h, 0.0)
	desired.x = clampf(desired.x, 1.5, journey_len + 4.5)
	desired.y = clampf(desired.y, maxf(0.85, hp.y + 0.65), 14.0)
	desired.z = clampf(desired.z, -10.8, 10.8)
	_cam.position = _cam.position.lerp(desired, 1.0 - exp(-12.5 * delta))
	var look_pt := hp + Vector3(0.0, 1.35, 0.0) + cam_fwd * 2.4
	_cam.look_at(look_pt)


func _update_traps_pickups_monsters(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var hpos := _hero_body.position

	for sg in _signs:
		if is_instance_valid(sg) and absf(sg.position.x - hpos.x) <= 46.0:
			var by: float = sg.get_meta("base_y", sg.position.y)
			var ph: float = sg.get_meta("phase", 0.0)
			sg.position.y = by + sin(t * 2.6 + ph) * 0.16

	for tr in _traps:
		var sp_node: Node3D = tr["node"]
		var pos: Vector3 = tr["pos"]
		if tr["hit_cd"] > 0.0:
			tr["hit_cd"] -= delta
		if absf(pos.x - hpos.x) > 34.0 and int(tr["state"]) == 0:
			continue
		var base_y: float = tr["base_y"]
		var d := Vector2(hpos.x - pos.x, hpos.z - pos.z).length()
		if int(tr["state"]) == 0:
			if d < 2.65:
				tr["state"] = 1
				tr["timer"] = 0.0
				sp_node.visible = true
				var tw := sp_node.create_tween()
				tw.tween_property(sp_node, "position:y", base_y + 0.06, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				if audio:
					audio.play("hit", 1.45, -13.0, 80)
		elif int(tr["state"]) == 1:
			tr["timer"] += delta
			if float(tr["timer"]) >= 0.18 and d < 1.42 and absf(hpos.y - base_y) < 1.15 and tr["hit_cd"] <= 0.0 and _invuln_t <= 0.0:
				tr["hit_cd"] = 1.2
				_on_trap_hit_hero(pos)
				return
			if float(tr["timer"]) > 1.75:
				tr["state"] = 2
				var tw2 := sp_node.create_tween()
				tw2.tween_property(sp_node, "position:y", base_y - 1.65, 0.25)
				tw2.tween_callback(func(): sp_node.visible = false)
		elif int(tr["state"]) == 2 and d > 6.5:
			tr["state"] = 0

	for pk in _pickups:
		if pk["taken"]:
			continue
		var pn: Node3D = pk["node"]
		if not is_instance_valid(pn):
			continue
		if absf(pn.position.x - hpos.x) > 36.0:
			continue
		pn.rotation_degrees.y += delta * 140.0
		pn.position.y = float(pk["base_y"]) + sin(t * 3.0 + pn.position.x * 0.2) * 0.12
		if pn.position.distance_to(hpos + Vector3(0, 0.7, 0)) < 1.35:
			pk["taken"] = true
			pn.queue_free()
			if pk["is_heart"]:
				hero_hp = mini(hero_max_hp, hero_hp + 1)
				hero_hp_changed.emit(hero_hp, hero_max_hp)
				if audio: audio.play("gem", 1.1, -9.0, 100)
			else:
				journey_coins += 1
				coins_changed.emit(journey_coins)
				if audio: audio.play("coin", 1.05, -10.0, 60)

	# Smart Monsters: stay distracted on their own island until Hero steps feet onto THAT land!
	var hero_seg := _get_land_segment_idx(hpos.x)
	for m in _monsters:
		if not m["alive"]:
			continue
		var mn: Node3D = m["node"]
		var home: Vector3 = m["home"]
		if absf(home.x - hpos.x) > 58.0 and absf(mn.position.x - hpos.x) > 52.0:
			continue
		var kind_s: String = m["kind"]
		if float(m["atk_cd"]) > 0.0:
			m["atk_cd"] -= delta
		if float(m.get("proj_cd", 0.0)) > 0.0:
			m["proj_cd"] = float(m["proj_cd"]) - delta
		if float(m.get("bridge_cd", 0.0)) > 0.0:
			m["bridge_cd"] = float(m["bridge_cd"]) - delta
		if float(m.get("hurt_t", 0.0)) > 0.0:
			m["hurt_t"] = float(m["hurt_t"]) - delta
		m["lunge_t"] = float(m["lunge_t"]) - delta

		var mob_seg: int = int(m.get("seg_idx", 0))
		var hero_on_mob_land := (hero_seg == mob_seg) and (mob_seg >= 0)
		var hero_feet_on_land := hero_on_mob_land and (absf(hpos.y - get_terrain_y(hpos.x)) <= 0.45)
		if hero_feet_on_land:
			m["aggroed"] = true
		elif hero_seg != -1 and hero_seg != mob_seg:
			m["aggroed"] = false

		var dist_m_hero := Vector2(hpos.x - mn.position.x, hpos.z - mn.position.z).length()
		var engaged := bool(m.get("aggroed", false)) and (hero_on_mob_land or hero_seg == -1)

		if engaged:
			# Ranged threat ONLY when Hero is actually on this monster's island (never snipe across rivers!)
			var p_min_r := 2.75 if kind_s == "spider" else 3.35
			var p_max_r := 15.5 if kind_s == "spider" else 13.5
			if hero_on_mob_land and dist_m_hero >= p_min_r and dist_m_hero <= p_max_r and float(m.get("proj_cd", 0.0)) <= 0.0:
				m["proj_cd"] = 2.05 if kind_s == "spider" else 2.55
				var p_origin := mn.global_position + Vector3(0.0, 0.85, 0.0)
				var p_tgt := _hero_body.global_position + Vector3(0.0, 0.78, 0.0)
				var p_dir := (p_tgt - p_origin).normalized()
				var vis_p: Node3D = m["vis"]
				vis_p.rotation_degrees.y = rad_to_deg(atan2(p_dir.x, p_dir.z))
				var ap_p: AnimationPlayer = m["ap"]
				if ap_p and ap_p.has_animation(m["anim_atk"]):
					ap_p.play(m["anim_atk"])
				_spawn_mob_projectile(p_origin, p_dir, kind_s)

			# Check if aggroed monster can sabotage/smash an adjacent built bridge block!
			var near_bkey: Variant = _find_adjacent_bridge_cell(mn.position)
			if near_bkey != null and dist_m_hero > 1.75 and float(m.get("bridge_cd", 0.0)) <= 0.0:
				var bd: Dictionary = _mc_placed_cells[near_bkey]
				var bp: Vector3 = bd["pos"]
				if Vector2(bp.x - mn.position.x, bp.z - mn.position.z).length() > 0.55:
					m["bridge_cd"] = 1.45
					var vis_b: Node3D = m["vis"]
					var bdir := Vector3(bp.x - mn.position.x, 0.0, bp.z - mn.position.z).normalized()
					vis_b.rotation_degrees.y = rad_to_deg(atan2(bdir.x, bdir.z))
					var ap_b: AnimationPlayer = m["ap"]
					if ap_b and ap_b.has_animation(m["anim_atk"]):
						ap_b.play(m["anim_atk"])
					bd["hp"] = int(bd.get("hp", 2)) - 1
					_spawn_fx(bp + Vector3(0, 0.45, 0), 5, Color(0.86, 0.56, 0.24))
					if audio:
						audio.play("hit_heavy", 0.88, -9.0, 90)
					if int(bd["hp"]) <= 0:
						var bnode: Node3D = bd["node"]
						_mc_placed_cells.erase(near_bkey)
						if is_instance_valid(bnode):
							bnode.queue_free()
						_spawn_fx(bp + Vector3(0, 0.45, 0), 10, Color(0.75, 0.52, 0.28))
					continue

			if dist_m_hero > 1.85:
				var target_pt := hpos
				var cur_dir := Vector3(target_pt.x - mn.position.x, 0.0, target_pt.z - mn.position.z).normalized()
				var probe := mn.position + cur_dir * 1.4
				if _is_in_water(probe.x) and _has_bridge_at(probe.x, probe.z).is_empty():
					var b_entry: Variant = _find_bridge_entry_near(mn.position)
					if b_entry != null:
						target_pt = b_entry as Vector3
						cur_dir = Vector3(target_pt.x - mn.position.x, 0.0, target_pt.z - mn.position.z).normalized()

				var perp := Vector3(-cur_dir.z, 0.0, cur_dir.x)
				var move_dir := cur_dir
				var spd_mult := 1.0
				var hop_y := 0.0
				if kind_s == "spider":
					move_dir = (cur_dir + perp * sin(t * 3.2 + float(m["phase"])) * 0.35).normalized()
					if float(m["lunge_t"]) <= 0.0:
						spd_mult = 1.25
						if float(m["lunge_t"]) <= -0.55:
							m["lunge_t"] = randf_range(1.8, 2.8)
				elif kind_s == "frog":
					hop_y = absf(sin(t * 5.2 + float(m["phase"]))) * 1.10
					spd_mult = 1.05
				elif kind_s == "beetle" or kind_s == "knight":
					if float(m["lunge_t"]) <= 0.0 and dist_m_hero < 6.5:
						spd_mult = 1.22
						if float(m["lunge_t"]) <= -0.60:
							m["lunge_t"] = randf_range(2.0, 3.0)
				var can_fly := bool(m.get("fly", false))
				var hover_y := float(m.get("hover_y", 0.0))
				var step_pos := mn.position + move_dir * (float(m["speed"]) * spd_mult) * delta
				step_pos.z = clampf(step_pos.z, -HALF_WIDTH_Z + 0.6, HALF_WIDTH_Z - 0.6)
				var on_bridge := _has_bridge_at(step_pos.x, step_pos.z)
				var can_step := can_fly or (not _is_in_water(step_pos.x)) or (not on_bridge.is_empty())
				if can_step:
					mn.position.x = step_pos.x
					mn.position.z = step_pos.z
					var fly_bob := sin(t * 4.5 + float(m["phase"])) * 0.22 if can_fly else 0.0
					mn.position.y = (0.00 if (not can_fly and not on_bridge.is_empty()) else get_terrain_y(mn.position.x)) + hover_y + hop_y + fly_bob
				var vis: Node3D = m["vis"]
				vis.rotation_degrees.y = rad_to_deg(atan2(move_dir.x, move_dir.z))
			else:
				if float(m["atk_cd"]) <= 0.0:
					m["atk_cd"] = 0.95
					var ap: AnimationPlayer = m["ap"]
					if ap and ap.has_animation(m["anim_atk"]):
						ap.play(m["anim_atk"])
					_damage_hero(1, mn.global_position.direction_to(hpos))
		else:
			# Busy wandering casually on its own dry island ("ملهية في أرضها")
			var seg_b := _get_land_segment_bounds(mob_seg)
			var wx := clampf(home.x + cos(t * 0.55 + float(m["phase"])) * 3.8, seg_b.x + 0.8, seg_b.y - 0.8)
			var wz_idle := clampf(home.z + sin(t * 0.44 + float(m["phase"]) * 1.6) * 2.8, -HALF_WIDTH_Z + 1.2, HALF_WIDTH_Z - 1.2)
			var wander_tgt := Vector3(wx, mn.position.y, wz_idle)
			var w_vec := Vector3(wander_tgt.x - mn.position.x, 0.0, wander_tgt.z - mn.position.z)
			var hover_idle := float(m.get("hover_y", 0.0))
			var can_fly_idle := bool(m.get("fly", false))
			if w_vec.length() > 0.25:
				var w_dir := w_vec.normalized()
				var w_step := mn.position + w_dir * (float(m["speed"]) * 0.44) * delta
				w_step.x = clampf(w_step.x, seg_b.x + 0.4, seg_b.y - 0.4)
				w_step.z = clampf(w_step.z, -HALF_WIDTH_Z + 0.8, HALF_WIDTH_Z - 0.8)
				if not _is_in_water(w_step.x):
					mn.position.x = w_step.x
					mn.position.z = w_step.z
					var fly_bob_i := sin(t * 4.2 + float(m["phase"])) * 0.18 if can_fly_idle else 0.0
					var hop_i := absf(sin(t * 4.4 + float(m["phase"]))) * 0.65 if kind_s == "frog" else 0.0
					mn.position.y = get_terrain_y(mn.position.x) + hover_idle + fly_bob_i + hop_i
				var vis_i: Node3D = m["vis"]
				vis_i.rotation_degrees.y = rad_to_deg(atan2(w_dir.x, w_dir.z))

	_update_mob_projectiles(delta)


func _build_water_eaters() -> void:
	_water_eaters.clear()
	var sea_specs := [
		{"path": "res://assets/3d/kingdom/monsters/Anglerfish.glb", "scale": 0.50},
		{"path": "res://assets/3d/kingdom/monsters/GoblinShark.glb", "scale": 0.48},
		{"path": "res://assets/3d/kingdom/monsters/Piranha.glb", "scale": 0.54},
	]
	var crack_box := BoxMesh.new()
	crack_box.size = Vector3(MC_CELL * 1.03, 1.03, MC_CELL * 1.03)

	for wi in range(_water_zones.size()):
		var wz: Vector2 = _water_zones[wi]
		var spec: Dictionary = sea_specs[(wi + maxi(0, to_level - 2)) % sea_specs.size()]
		var sc: PackedScene = load(str(spec["path"]))
		var root := Node3D.new()
		root.position = Vector3((wz.x + wz.y) * 0.5, -1.65, 2.2)
		add_child(root)

		var vis := sc.instantiate()
		vis.scale = Vector3.ONE * float(spec["scale"])
		_set_cull(vis, 95.0)
		root.add_child(vis)

		var ap := _find_ap(vis)
		if ap:
			for aname in ap.get_animation_list():
				var low := str(aname).to_lower()
				if "swim" in low or "attack" in low:
					ap.get_animation(aname).loop_mode = Animation.LOOP_LINEAR
			if ap.has_animation("Fish_Armature|Swimming_Normal"):
				ap.play("Fish_Armature|Swimming_Normal")

		var crack_mi := MeshInstance3D.new()
		crack_mi.mesh = crack_box
		crack_mi.visible = false
		add_child(crack_mi)

		_water_eaters.append({
			"river_idx": wi,
			"wz": wz,
			"node": root,
			"vis": vis,
			"ap": ap,
			"cur_anim": "Fish_Armature|Swimming_Normal",
			"crack_mesh": crack_mi,
			"awakened": false,
			"active_key": null,
			"eat_progress": 0.0,
			"sfx_cd": 0.0,
		})


func _pick_next_eater_cell(river_cells: Array[Dictionary]) -> Variant:
	if river_cells.is_empty():
		return null
	# Start strictly at the FIRST placed block on this river (#1) and eat forward in placement order!
	var best_k: Variant = null
	var best_seq: int = 999999999
	var best_x: float = INF
	for rc in river_cells:
		var rseq: int = int(rc.get("seq", 999999))
		var rx: float = float((rc["pos"] as Vector3).x)
		if rseq < best_seq or (rseq == best_seq and rx < best_x):
			best_seq = rseq
			best_x = rx
			best_k = rc["key"]
	return best_k


func _update_water_eaters(delta: float) -> void:
	if _water_eaters.is_empty():
		return
	var t := Time.get_ticks_msec() * 0.001
	var can_act := (j_state == JState.PLAYING)

	for eater in _water_eaters:
		var wz: Vector2 = eater["wz"]
		var root: Node3D = eater["node"]
		var ap: AnimationPlayer = eater.get("ap", null)
		var crack_mi: MeshInstance3D = eater["crack_mesh"]
		if not can_act:
			if is_instance_valid(crack_mi):
				crack_mi.visible = false
			continue

		var river_cells: Array[Dictionary] = []
		var max_bx := -INF
		for k: Vector2i in _mc_placed_cells.keys():
			var bd: Dictionary = _mc_placed_cells[k]
			var bp: Vector3 = bd["pos"]
			if bp.x >= wz.x - 0.55 and bp.x <= wz.y + 0.55:
				river_cells.append({"key": k, "pos": bp, "seq": int(bd.get("seq", 999999))})
				max_bx = maxf(max_bx, bp.x)

		if river_cells.is_empty():
			eater["awakened"] = false
			eater["active_key"] = null
			eater["eat_progress"] = 0.0
			if is_instance_valid(crack_mi):
				crack_mi.visible = false
			if is_instance_valid(root):
				root.position.y = lerpf(root.position.y, -1.65, minf(1.0, delta * 3.5))
			continue

		var is_awakened := bool(eater["awakened"])
		if not is_awakened and river_cells.size() >= 3 and max_bx >= wz.y - 3.0 * MC_CELL:
			is_awakened = true
			eater["awakened"] = true
			eater["active_key"] = _pick_next_eater_cell(river_cells)
			eater["eat_progress"] = 0.0
			if is_instance_valid(root):
				_spawn_fx(Vector3(root.position.x, -0.05, root.position.z), 9, Color(0.55, 0.88, 1.0))
			if audio:
				audio.play("splash", 0.84, -7.0, 220)

		if not is_awakened:
			if is_instance_valid(crack_mi):
				crack_mi.visible = false
			if is_instance_valid(root):
				root.position.y = lerpf(root.position.y, -1.65, minf(1.0, delta * 3.5))
			continue

		var cur_key: Variant = eater["active_key"]
		if cur_key == null or not _mc_placed_cells.has(cur_key):
			cur_key = _pick_next_eater_cell(river_cells)
			eater["active_key"] = cur_key
			eater["eat_progress"] = 0.0
		if cur_key == null or not _mc_placed_cells.has(cur_key):
			if is_instance_valid(crack_mi):
				crack_mi.visible = false
			continue

		var tgt_bd: Dictionary = _mc_placed_cells[cur_key]
		var bp: Vector3 = tgt_bd["pos"]
		var z_side := 1.48 if bp.z <= 0.0 else -1.48
		var wx_tgt := clampf(bp.x + 0.15, wz.x + 0.85, wz.y - 0.85)
		var target_pos := Vector3(wx_tgt, 0.04 + sin(t * 6.5) * 0.06, bp.z + z_side)
		root.position = root.position.lerp(target_pos, minf(1.0, delta * 7.5))
		var face_dir := Vector3(bp.x - root.position.x, 0.0, bp.z - root.position.z)
		if face_dir.length() > 0.05:
			root.rotation.y = atan2(face_dir.x, face_dir.z)

		var horiz_d := Vector2(bp.x - root.position.x, bp.z - root.position.z).length()
		if horiz_d <= 2.45:
			if ap and ap.has_animation("Fish_Armature|Attack") and str(eater.get("cur_anim", "")) != "Fish_Armature|Attack":
				eater["cur_anim"] = "Fish_Armature|Attack"
				ap.speed_scale = 1.65
				ap.play("Fish_Armature|Attack")

			eater["eat_progress"] = float(eater["eat_progress"]) + delta
			var frac := clampf(float(eater["eat_progress"]) / WATER_EAT_DURATION, 0.0, 0.999)
			var stage := clampi(int(floor(frac * 4.0)), 0, maxi(0, _mc_crack_mats.size() - 1))
			if is_instance_valid(crack_mi) and not _mc_crack_mats.is_empty():
				crack_mi.visible = true
				crack_mi.position = bp + Vector3(randf_range(-0.015, 0.015), randf_range(-0.012, 0.012), randf_range(-0.015, 0.015))
				crack_mi.material_override = _mc_crack_mats[stage]

			eater["sfx_cd"] = float(eater["sfx_cd"]) - delta
			if float(eater["sfx_cd"]) <= 0.0:
				eater["sfx_cd"] = 0.28
				_spawn_fx(bp + Vector3(0, 0.18, 0), 3, Color(0.55, 0.85, 0.98))
				if audio:
					audio.play("hit", randf_range(0.78, 0.95), -11.5, 80)

			if float(eater["eat_progress"]) >= WATER_EAT_DURATION:
				var bnode: Node3D = tgt_bd["node"]
				_mc_placed_cells.erase(cur_key)
				if is_instance_valid(bnode):
					bnode.queue_free()
				_spawn_fx(bp + Vector3(0, 0.35, 0), 10, Color(0.75, 0.52, 0.28))
				_spawn_fx(bp + Vector3(0, 0.22, 0), 7, Color(0.55, 0.85, 0.98))
				if audio:
					audio.play("hit_heavy", 0.82, -7.5, 90)
				if is_instance_valid(crack_mi):
					crack_mi.visible = false
				var rem_cells: Array[Dictionary] = []
				for rc in river_cells:
					if rc["key"] != cur_key:
						rem_cells.append(rc)
				eater["active_key"] = _pick_next_eater_cell(rem_cells)
				eater["eat_progress"] = 0.0
		else:
			if ap and ap.has_animation("Fish_Armature|Swimming_Fast") and str(eater.get("cur_anim", "")) != "Fish_Armature|Swimming_Fast":
				eater["cur_anim"] = "Fish_Armature|Swimming_Fast"
				ap.speed_scale = 1.4
				ap.play("Fish_Armature|Swimming_Fast")
			if is_instance_valid(crack_mi):
				crack_mi.visible = false


func _clear_mob_projectiles() -> void:
	for p_entry in _mob_projectiles:
		var nd: Node3D = p_entry.get("node", null)
		if is_instance_valid(nd):
			nd.queue_free()
	_mob_projectiles.clear()


func _spawn_mob_projectile(origin: Vector3, dir: Vector3, kind_s: String) -> void:
	var p_root := Node3D.new()
	p_root.position = origin
	add_child(p_root)

	var core := MeshInstance3D.new()
	core.mesh = _proj_sphere_mesh
	var mat := _proj_web_mat
	var spd := 11.5
	var fx_col := Color(0.95, 0.98, 1.0)
	if kind_s == "beetle":
		mat = _proj_fire_mat
		spd = 12.0
		fx_col = Color(1.0, 0.45, 0.12)
	elif kind_s == "frog":
		mat = _proj_slime_mat
		spd = 10.8
		fx_col = Color(0.28, 0.92, 0.36)
	elif kind_s == "knight" or kind_s == "warden":
		mat = _proj_gold_mat
		spd = 12.2
		fx_col = Color(1.0, 0.86, 0.24)
	elif kind_s == "bat" or kind_s == "mech":
		mat = _proj_fire_mat if kind_s == "mech" else _proj_slime_mat
		spd = 12.8
		fx_col = Color(0.95, 0.35, 0.20) if kind_s == "mech" else Color(0.65, 0.35, 1.0)
	core.material_override = mat
	p_root.add_child(core)

	if kind_s == "spider":
		# Distinct glowing Spider Web Sphere with crossed silk rings!
		p_root.scale = Vector3.ONE * 1.18
		for r_rot: Vector3 in [Vector3(45, 0, 0), Vector3(0, 45, 45), Vector3(-45, 90, 0)]:
			var wr := MeshInstance3D.new()
			wr.mesh = _proj_ring_mesh
			wr.material_override = _proj_web_mat
			wr.rotation_degrees = r_rot
			p_root.add_child(wr)
	else:
		var aura := MeshInstance3D.new()
		aura.mesh = _proj_ring_mesh
		aura.material_override = mat
		p_root.add_child(aura)

	_mob_projectiles.append({
		"node": p_root,
		"vel": dir.normalized() * spd,
		"kind": kind_s,
		"fx_col": fx_col,
		"age": 0.0,
		"spin": 240.0 if kind_s == "spider" else 180.0,
	})
	_spawn_fx(origin, 4, fx_col)


func _update_mob_projectiles(delta: float) -> void:
	if _mob_projectiles.is_empty() or not is_instance_valid(_hero_body):
		return
	var hero_hit_center := _hero_body.global_position + Vector3(0.0, 0.78, 0.0)
	var i := _mob_projectiles.size() - 1
	while i >= 0:
		if i >= _mob_projectiles.size():
			i = _mob_projectiles.size() - 1
			continue
		var pr: Dictionary = _mob_projectiles[i]
		var nd: Node3D = pr["node"]
		if not is_instance_valid(nd):
			_mob_projectiles.remove_at(i)
			i -= 1
			continue
		pr["age"] = float(pr["age"]) + delta
		var vel: Vector3 = pr["vel"]
		nd.position += vel * delta
		nd.rotation_degrees.y += delta * float(pr["spin"])
		nd.rotation_degrees.x += delta * float(pr["spin"]) * 0.7

		var hit_wall := false
		if absf(nd.position.z) >= HALF_WIDTH_Z or nd.position.y < -0.5 or float(pr["age"]) >= 1.95:
			hit_wall = true
		var d_hero := nd.position.distance_to(hero_hit_center)
		if d_hero <= 0.74:
			var push_d := Vector3(vel.x, 0.0, vel.z).normalized()
			_spawn_fx(nd.position, 8, pr["fx_col"])
			nd.queue_free()
			_mob_projectiles.remove_at(i)
			_damage_hero(1, push_d)
			if j_state != JState.PLAYING or _mob_projectiles.is_empty():
				return
			i = mini(i - 1, _mob_projectiles.size() - 1)
			continue
		if hit_wall:
			_spawn_fx(nd.position, 3, pr["fx_col"])
			nd.queue_free()
			_mob_projectiles.remove_at(i)
		i -= 1


func _on_trap_hit_hero(trap_pos: Vector3) -> void:
	for tr in _traps:
		if int(tr["state"]) == 1:
			tr["state"] = 2
			(tr["node"] as Node3D).visible = false
	if _invuln_t > 0.0:
		return
	_last_fail_pos = _hero_body.global_position
	hero_hp = maxi(0, hero_hp - 1)
	hero_hp_changed.emit(hero_hp, hero_max_hp)
	_invuln_t = 1.25
	_spawn_fx(trap_pos + Vector3(0, 0.8, 0), 8, Color(1.0, 0.35, 0.25))
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(45)
	if audio:
		audio.play("hit_heavy", 0.95, -6.5, 120)
		audio.play_hero_voice(char_id, "hurt")
	if hero_hp <= 0:
		_trigger_journey_defeat("trap")
		return
	# Non-lethal knockback upward & safely away (never teleport Hero inside white gate fog!)
	_invuln_t = 1.45
	_hero_body.velocity.y = 5.4
	_hero_body.velocity.x = -3.4


func _open_dest_doors() -> void:
	if _dest_doors_open:
		return
	_dest_doors_open = true
	if is_instance_valid(_dest_door_l) and is_instance_valid(_dest_door_r):
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_dest_door_l, "rotation_degrees:y", 92.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_dest_door_r, "rotation_degrees:y", -92.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if audio:
		audio.play("gate_open", 0.92, -6.5, 200)
		audio.play("gate_creak", 0.92, -10.0, 200)


func _close_dest_doors() -> void:
	if is_instance_valid(_dest_door_l) and is_instance_valid(_dest_door_r):
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_dest_door_l, "rotation_degrees:y", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_dest_door_r, "rotation_degrees:y", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if audio:
		audio.play("gate_slam", 0.94, -5.0, 150)
		audio.play("gate_thud", 0.92, -4.0, 150)


func revive_near_spot() -> void:
	_clear_mob_projectiles()
	for ea in _water_eaters:
		ea["active_key"] = null
		ea["eat_progress"] = 0.0
		var cm: MeshInstance3D = ea.get("crack_mesh", null)
		if is_instance_valid(cm):
			cm.visible = false
	var rx := clampf(_last_fail_pos.x - 2.4, 6.2, journey_len - 8.5)
	while rx > 6.2 and (_is_in_water(rx) or get_terrain_y(rx) < -0.05):
		rx -= 1.2
	var ry := get_terrain_y(rx) + 0.15
	var rz := clampf(_last_fail_pos.z * 0.4, -4.5, 4.5)
	var safe_p := Vector3(rx, ry, rz)
	for tr in _traps:
		var tpos: Vector3 = tr["pos"]
		if Vector2(tpos.x - safe_p.x, tpos.z - safe_p.z).length() < 5.0:
			tr["state"] = 2
			(tr["node"] as Node3D).visible = false
	hero_hp = hero_max_hp
	hero_hp_changed.emit(hero_hp, hero_max_hp)
	_hero_body.velocity = Vector3.ZERO
	_hero_body.global_position = safe_p
	_facing_yaw = 0.0
	_hero_vis.clear_sad_sit()
	_hero_vis.rotation_degrees.y = 0.0
	_hero_vis.visible = true
	_invuln_t = 2.8
	_revive_center = safe_p
	_revive_t = 0.0
	j_state = JState.REVIVING
	_spawn_fx(safe_p + Vector3(0, 1.1, 0), 16, Color(1.0, 0.86, 0.22))
	if audio:
		audio.play("rescue", 1.05, -6.5, 120)


func _trigger_journey_defeat(reason: String) -> void:
	if j_state == JState.DEFEATED:
		return
	cancel_mining()
	_clear_mob_projectiles()
	j_state = JState.DEFEATED
	_defeat_reason = reason
	_defeat_delay_t = 1.45 if reason == "water" else 0.90
	if is_instance_valid(_mc_ghost_mesh):
		_mc_ghost_mesh.visible = false
	if is_instance_valid(_hero_body):
		_hero_body.velocity = Vector3.ZERO
	if is_instance_valid(_hero_vis):
		if reason == "water":
			_hero_vis.play_drown_struggle()
		else:
			_hero_vis.play_sad_sit()
	if audio:
		audio.play("lose", 1.0, -7.0, 200)


func _damage_hero(dmg: int, push_dir: Vector3) -> void:
	if _invuln_t > 0.0 or j_state != JState.PLAYING:
		return
	_last_fail_pos = _hero_body.global_position
	hero_hp = maxi(0, hero_hp - dmg)
	hero_hp_changed.emit(hero_hp, hero_max_hp)
	_invuln_t = 0.95
	var push := Vector3(push_dir.x, 0.0, push_dir.z).normalized()
	_hero_body.velocity.x += push.x * 5.2
	_hero_body.velocity.z += push.z * 5.2
	_hero_body.velocity.y = 4.2
	if audio:
		audio.play("hit_heavy", 0.94, -7.0, 140)
		audio.play_hero_voice(char_id, "hurt")
	if hero_hp <= 0:
		_trigger_journey_defeat("hazard")


func _spawn_fx(pos: Vector3, count: int, col: Color) -> void:
	if is_instance_valid(_fx_pool):
		_fx_pool.spawn_burst(pos, count, col, 0.9, 2.2, false)


func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find_ap(c)
		if r:
			return r
	return null


func _set_cull(root: Node, dist: float) -> void:
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).visibility_range_end = dist
		(root as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in root.get_children():
		_set_cull(c, dist)
