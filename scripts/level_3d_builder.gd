class_name Level3DBuilder
extends Node3D

const GROUND_Y := 0.0
const MUD_PIT_Y := -3.45
const LEVEL_LENGTHS := {
	1: 260.0, 2: 290.0, 3: 320.0, 4: 335.0, 5: 350.0,
	6: 360.0, 7: 375.0, 8: 385.0, 9: 400.0, 10: 430.0,
	11: 445.0, 12: 452.0, 13: 460.0, 14: 468.0, 15: 476.0,
	16: 484.0, 17: 492.0, 18: 500.0, 19: 508.0, 20: 516.0,
	21: 524.0, 22: 532.0, 23: 540.0, 24: 548.0, 25: 556.0,
	26: 564.0, 27: 572.0, 28: 578.0, 29: 584.0, 30: 592.0
}

static var FINISH_X := 310.0
static var force_hide_pickup_hearts_for_test: int = -1


static func should_spawn_pickup_hearts() -> bool:
	if force_hide_pickup_hearts_for_test == 1:
		return false
	if force_hide_pickup_hearts_for_test == 0:
		return true
	return not (OS.has_feature("android") or OS.has_feature("mobile"))


static func should_spawn_journey_hearts() -> bool:
	return true

var player: Haneen3DPlayer
var current_level: int = 1

static var _cache_ready: bool = false
static var _sc_road: PackedScene
static var _sc_crossing: PackedScene
static var _sc_lamp: PackedScene
static var _sc_bridge: PackedScene
static var _sc_crate: PackedScene
static var _sc_flowers: PackedScene
static var _sc_coin: PackedScene
static var _sc_heart: PackedScene
static var _sc_star: PackedScene
static var _sc_spikes: PackedScene
static var _sc_spike_wide: PackedScene
static var _sc_spike_block: PackedScene
static var _sc_saw: PackedScene
static var _sc_mushroom: PackedScene
static var _sc_boulder: PackedScene
static var _sc_bee_bot: PackedScene
static var _sc_bat: PackedScene
static var _sc_cyborg: PackedScene
static var _sc_giant_bee: PackedScene
static var _sc_cannonball: PackedScene
static var _sc_bomb: PackedScene
static var _sc_bouncer: PackedScene
static var _sc_crystal1: PackedScene
static var _sc_crystal2: PackedScene
static var _sc_flag: PackedScene

static var _gem_mesh: ArrayMesh
static var _coin_gold_mat: StandardMaterial3D
static var _gem_mat: StandardMaterial3D
static var _deck_top_mat: StandardMaterial3D
static var _deck_side_mat: StandardMaterial3D
static var _deck_trim_mat: StandardMaterial3D
static var _grass_trim_mat: StandardMaterial3D
static var _tunnel_wall_mat: StandardMaterial3D
static var _tunnel_glow_mat: StandardMaterial3D
static var _raft_wood_mat: StandardMaterial3D
static var _mud_mat: StandardMaterial3D
static var _water_shader_mat: ShaderMaterial

var _spinners: Array[Node3D] = []
var _animated_hazards: Array[Dictionary] = []
var _moving_plats: Array[Dictionary] = []
var _crumbling: Array[Dictionary] = []
var _water_meshes: Array[MeshInstance3D] = []
var _mud_blocked_ranges: Array[Vector2] = []
var _safe_road_ranges: Array[Vector3] = []
var _finish_triggered: bool = false
var _ribbon_mesh: MeshInstance3D
var _confetti_parent: Node3D
var _finish_sign: CityBillboard3D


func update_language() -> void:
	if is_instance_valid(_finish_sign):
		_finish_sign.update_message(Loc.t("finish_line"))


static func get_level_length(lvl: int) -> float:
	return float(LEVEL_LENGTHS.get(lvl, 310.0))


func _ensure_cached_assets() -> void:
	if _cache_ready:
		return
	_cache_ready = true

	_sc_road = load("res://assets/3d/kenney/city-roads/road-straight.glb")
	_sc_crossing = load("res://assets/3d/kenney/city-roads/road-crossing.glb")
	_sc_lamp = load("res://assets/3d/kenney/city-roads/light-curved-double.glb")
	_sc_bridge = load("res://assets/3d/kenney/platformer/platform-fortified.glb")
	_sc_crate = load("res://assets/3d/gdquest/props/box.glb")
	_sc_flowers = load("res://assets/3d/kenney/platformer/flowers.glb")
	_sc_coin = load("res://assets/3d/gdquest/props/coin_model.glb")
	_sc_heart = load("res://assets/3d/quaternius/platformer_pack/Heart_Full.glb")
	_sc_star = load("res://assets/3d/quaternius/rpg_items_pack/Coin_Star.glb")
	_sc_spikes = load("res://assets/3d/kenney/platformer/trap-spikes-large.glb")
	_sc_spike_wide = load("res://assets/3d/kenney/platformer/spike-block-wide.glb")
	_sc_spike_block = load("res://assets/3d/kenney/platformer/spike-block.glb")
	_sc_saw = load("res://assets/3d/kenney/platformer/saw.glb")
	_sc_mushroom = load("res://assets/3d/gdquest/props/mushroom.glb")
	_sc_boulder = load("res://assets/3d/polyhaven/boulder_01/boulder_01_1k.gltf")
	_sc_bee_bot = load("res://assets/3d/gdquest/gdquest_bee_bot/model/bee_bot.glb")
	_sc_bat = load("res://assets/3d/kingdom/monsters/bat.glb")
	_sc_cyborg = load("res://assets/3d/quaternius/cyberpunk_pack/Enemy_Flying.glb")
	_sc_giant_bee = load("res://assets/3d/quaternius/platformer_game_pack/Bee.glb")
	_sc_cannonball = load("res://assets/3d/quaternius/platformer_game_pack/Cannonball.glb")
	_sc_bomb = load("res://assets/3d/kenney/platformer/bomb.glb")
	_sc_bouncer = load("res://assets/3d/quaternius/platformer_game_pack/Bouncer.glb")
	_sc_crystal1 = load("res://assets/3d/quaternius/rpg_items_pack/Crystal1.glb")
	_sc_crystal2 = load("res://assets/3d/quaternius/rpg_items_pack/Crystal2.glb")
	_sc_flag = load("res://assets/3d/quaternius/platformer_pack/Flag.glb")

	_coin_gold_mat = StandardMaterial3D.new()
	_coin_gold_mat.albedo_color = Color(1.0, 0.80, 0.16)
	_coin_gold_mat.metallic = 0.82
	_coin_gold_mat.roughness = 0.22

	_gem_mat = StandardMaterial3D.new()
	_gem_mat.albedo_color = Color(0.14, 0.78, 1.0)
	_gem_mat.metallic = 0.78
	_gem_mat.roughness = 0.14

	_gem_mesh = _build_faceted_diamond_mesh()

	_deck_top_mat = StandardMaterial3D.new()
	_deck_top_mat.albedo_color = Color(0.24, 0.28, 0.36)
	_deck_top_mat.roughness = 0.78

	_deck_side_mat = StandardMaterial3D.new()
	_deck_side_mat.albedo_color = Color(0.84, 0.88, 0.94)
	_deck_side_mat.roughness = 0.65

	_deck_trim_mat = StandardMaterial3D.new()
	_deck_trim_mat.albedo_color = Color(0.12, 0.56, 0.96)
	_deck_trim_mat.roughness = 0.42

	_grass_trim_mat = StandardMaterial3D.new()
	_grass_trim_mat.albedo_texture = load("res://assets/textures/ground/aerial_grass_rock_Diffuse.jpg")
	_grass_trim_mat.normal_enabled = true
	_grass_trim_mat.normal_texture = load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	_grass_trim_mat.albedo_color = Color(0.88, 1.0, 0.88)
	_grass_trim_mat.uv1_scale = Vector3(16.0, 1.0, 1.0)
	_grass_trim_mat.roughness = 0.85

	_water_shader_mat = ShaderMaterial.new()
	_water_shader_mat.shader = load("res://shaders/realistic_water.gdshader")

	_tunnel_wall_mat = StandardMaterial3D.new()
	_tunnel_wall_mat.albedo_texture = load("res://assets/textures/stone/stone_tiles_02_Diffuse.jpg")
	_tunnel_wall_mat.normal_enabled = true
	_tunnel_wall_mat.normal_texture = load("res://assets/textures/stone/stone_tiles_02_nor_gl.jpg")
	_tunnel_wall_mat.roughness_texture = load("res://assets/textures/stone/stone_tiles_02_Rough.jpg")
	_tunnel_wall_mat.albedo_color = Color(0.55, 0.62, 0.72)
	_tunnel_wall_mat.uv1_scale = Vector3(12.0, 2.0, 1.0)

	_tunnel_glow_mat = StandardMaterial3D.new()
	_tunnel_glow_mat.albedo_color = Color(0.14, 0.76, 0.88)
	_tunnel_glow_mat.roughness = 0.35

	_raft_wood_mat = StandardMaterial3D.new()
	_raft_wood_mat.albedo_color = Color(0.76, 0.50, 0.26)
	_raft_wood_mat.roughness = 0.72

	_mud_mat = StandardMaterial3D.new()
	_mud_mat.normal_enabled = true
	_mud_mat.normal_texture = load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	_mud_mat.normal_scale = 1.6
	_mud_mat.roughness_texture = load("res://assets/textures/ground/aerial_grass_rock_Rough.jpg")
	_mud_mat.albedo_color = Color(0.24, 0.13, 0.07)
	_mud_mat.roughness = 0.28
	_mud_mat.uv1_scale = Vector3(14.0, 2.5, 1.0)


static func _build_faceted_diamond_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 8
	var r_mid := 0.26
	var r_top := 0.15
	var y_top := 0.22
	var y_mid := 0.08
	var y_bot := -0.26
	var top_c := Vector3(0, y_top, 0)
	var bot_c := Vector3(0, y_bot, 0)

	for i in range(sides):
		var a0 := (float(i) / float(sides)) * TAU
		var a1 := (float(i + 1) / float(sides)) * TAU
		var t0 := Vector3(cos(a0) * r_top, y_top, sin(a0) * r_top)
		var t1 := Vector3(cos(a1) * r_top, y_top, sin(a1) * r_top)
		var m0 := Vector3(cos(a0) * r_mid, y_mid, sin(a0) * r_mid)
		var m1 := Vector3(cos(a1) * r_mid, y_mid, sin(a1) * r_mid)
		st.add_vertex(top_c); st.add_vertex(t1); st.add_vertex(t0)
		st.add_vertex(t0); st.add_vertex(t1); st.add_vertex(m1)
		st.add_vertex(t0); st.add_vertex(m1); st.add_vertex(m0)
		st.add_vertex(m0); st.add_vertex(m1); st.add_vertex(bot_c)

	st.generate_normals()
	return st.commit()


func _apply_cull_and_mat(root: Node, mat: Material = null, dist: float = 82.0) -> void:
	if root is GeometryInstance3D:
		var gi := root as GeometryInstance3D
		gi.visibility_range_end = dist
		gi.visibility_range_end_margin = 10.0
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mat != null and root is MeshInstance3D:
			(root as MeshInstance3D).material_override = mat
	for c in root.get_children():
		_apply_cull_and_mat(c, mat, dist)


func _ready() -> void:
	process_physics_priority = -10


func build_level(p: Haneen3DPlayer, level_num: int = 1) -> void:
	player = p
	current_level = clampi(level_num, 1, 30)
	FINISH_X = get_level_length(current_level)
	_ensure_cached_assets()
	_spinners.clear()
	_animated_hazards.clear()
	_moving_plats.clear()
	_crumbling.clear()
	_water_meshes.clear()
	_mud_blocked_ranges.clear()
	_safe_road_ranges.clear()
	_finish_triggered = false

	_confetti_parent = Node3D.new()
	add_child(_confetti_parent)

	match current_level:
		1: _build_level_1()
		2: _build_level_2()
		3: _build_level_3()
		4: _build_level_4()
		5: _build_level_5()
		6: _build_level_6()
		7: _build_level_7()
		8: _build_level_8()
		9: _build_level_9()
		10: _build_level_10()
		_: _build_evolved_level(current_level)

	# Solid textured mud-earth pit catchers under all open chasms (so falling NEVER clips underground!)
	_build_mud_catchers_between(-14.0, FINISH_X + 24.0, MUD_PIT_Y)
	_build_finish_arch(FINISH_X, GROUND_Y)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var px := player.position.x
	var t := Time.get_ticks_msec() * 0.001
	for mp in _moving_plats:
		var origin: Vector3 = mp["origin"]
		if absf(origin.x - px) > 46.0:
			continue
		var body: AnimatableBody3D = mp["body"]
		if not is_instance_valid(body):
			continue
		var amp: Vector3 = mp["amp"]
		var freq: float = mp["freq"]
		var ph: float = mp["phase"]
		body.position = origin + amp * sin(t * freq + ph)
		if mp.get("raft", false):
			body.rotation_degrees.z = cos(t * freq + ph) * 3.2
			body.rotation_degrees.x = sin(t * freq * 0.7 + ph) * 1.8


func _process(delta: float) -> void:
	if player == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	var px := player.position.x

	for sp in _spinners:
		if is_instance_valid(sp):
			if absf(sp.position.x - px) > 44.0 and sp.position.x < FINISH_X - 6.0:
				continue
			var base_y: float = sp.get_meta("base_y", sp.position.y)
			var ph: float = sp.get_meta("phase", 0.0)
			sp.rotation_degrees.y += delta * 145.0
			var knd := str(sp.get_meta("trigger_kind", ""))
			if player._spring_feather_timer > 0.0 and (knd == "coin" or knd == "gem"):
				var hero_c := player.position + Vector3(0.0, 0.72, 0.0)
				var d_mag := sp.position.distance_to(hero_c)
				if d_mag < 4.8 and d_mag > 0.05:
					sp.position = sp.position.move_toward(hero_c, delta * 13.5)
					sp.set_meta("base_y", sp.position.y)
					continue
			sp.position.y = base_y + sin(t * 3.4 + ph) * 0.13

	if is_instance_valid(_ribbon_mesh) and absf(FINISH_X - px) <= 55.0:
		_ribbon_mesh.rotation_degrees.y = sin(t * 4.5) * 8.0

	for wm in _water_meshes:
		if is_instance_valid(wm) and absf(wm.position.x - px) <= 54.0:
			var base_y: float = wm.get_meta("base_y", wm.position.y)
			wm.position.y = base_y + sin(t * 2.8 + wm.position.x * 0.15) * 0.07

	for h in _animated_hazards:
		var node: Node3D = h["node"]
		if not is_instance_valid(node):
			continue
		var kind: String = h["kind"]
		if kind != "boulder" and absf(node.position.x - px) > 46.0:
			continue
		if kind == "boulder":
			var trig_x: float = h["trigger_x"]
			if not h["active"] and px >= trig_x:
				h["active"] = true
			if h["active"]:
				if node.position.x < px - 28.0:
					continue
				node.position.x -= h["speed"] * delta
				node.rotation_degrees.z += delta * 240.0
		elif kind == "pendulum":
			var ang: float = sin(t * h["freq"] + h["phase"]) * h["max_ang"]
			node.rotation.z = ang
			var blade: Node3D = h["blade"]
			blade.rotation_degrees.z += delta * 420.0
		elif kind == "crusher":
			var cycle := fmod(t * h["freq"] + h["phase"], 1.0)
			var drop_k := 0.0
			if cycle < 0.24:
				drop_k = ease(cycle / 0.24, 2.4)
			elif cycle < 0.54:
				drop_k = 1.0
			elif cycle < 0.85:
				drop_k = 1.0 - (cycle - 0.54) / 0.31
			node.position.y = lerpf(h["top_y"], h["bot_y"], drop_k)
			if cycle > 0.86:
				node.position.x = h["base_x"] + sin(t * 58.0) * 0.05
			else:
				node.position.x = h["base_x"]
		elif kind == "drone":
			var cx: float = h["center_x"]
			var cy: float = h["center_y"]
			var ph: float = t * h["freq"] + h["phase"]
			var vx := cos(ph)
			var ek := str(h.get("ekind", "bee"))
			node.position.x = cx + sin(ph) * h["amp_x"]
			if ek == "bat":
				node.position.y = cy - absf(sin(ph)) * 1.15
			elif ek == "cyborg":
				node.position.y = cy + sin(ph * 2.0) * 0.55
			elif ek == "giant_bee":
				node.position.y = cy + cos(t * 3.4 + h["phase"]) * 0.38
			else:
				node.position.y = cy + cos(t * 2.6 + h["phase"]) * 0.18
			var vis: Node3D = h.get("vis", null)
			if is_instance_valid(vis):
				var dir_s := 1.0 if vx >= 0.0 else -1.0
				var base_yaw := -90.0 if ek == "bee" else 90.0
				var target_yaw := base_yaw if dir_s >= 0.0 else -base_yaw
				vis.rotation_degrees.y = lerpf(vis.rotation_degrees.y, target_yaw, minf(1.0, delta * 9.0))
				vis.rotation_degrees.z = lerpf(vis.rotation_degrees.z, -vx * 11.0, minf(1.0, delta * 8.0))
		elif kind == "cannon":
			var cx: float = h["origin_x"]
			var span: float = h["span"]
			var spd: float = h["speed"]
			node.position.x -= spd * delta
			node.rotation_degrees.z += delta * 360.0
			if node.position.x < cx - span:
				node.position.x = cx
		elif kind == "ambush":
			var ax: float = h["x"]
			var gy: float = h["ground_y"]
			var st: int = int(h["state"])
			var d_px := absf(px - ax)
			if st == 0:
				if d_px <= 5.8 and px < ax + 1.5:
					h["state"] = 1
					node.visible = true
			elif st == 1:
				node.position.y = move_toward(node.position.y, gy + 0.06, delta * 14.0)
				if absf(node.position.y - (gy + 0.06)) < 0.02:
					h["state"] = 2
			elif st == 2:
				if d_px > 10.5:
					h["state"] = 3
			elif st == 3:
				node.position.y = move_toward(node.position.y, gy - 1.55, delta * 8.0)
				if node.position.y <= gy - 1.50:
					node.visible = false
					h["state"] = 0

	for cp in _crumbling:
		if absf(float(cp["cx"]) - px) > 42.0:
			continue
		var vis_node: Node3D = cp["vis"]
		var col_node: CollisionShape3D = cp["col"]
		if cp["state"] == 1:
			cp["timer"] -= delta
			vis_node.position.x = sin(t * 50.0) * 0.06
			if cp["timer"] <= 0.0:
				cp["state"] = 2
				cp["timer"] = 2.6
				col_node.set_deferred("disabled", true)
				var tw: Tween = vis_node.create_tween()
				tw.tween_property(vis_node, "position:y", -2.8, 0.35)
				tw.parallel().tween_property(vis_node, "scale", Vector3(0.45, 0.45, 0.45), 0.35)
		elif cp["state"] == 2:
			cp["timer"] -= delta
			if cp["timer"] <= 0.0 and absf(px - float(cp["cx"])) > float(cp["half_len"]) + 1.2:
				cp["state"] = 0
				col_node.set_deferred("disabled", false)
				vis_node.position = Vector3.ZERO
				vis_node.scale = Vector3.ONE


# ==============================================================================
# LEVEL 1 (SUNNY CITY PARKWAY - ACCESSIBLE STARTER - 260m)
# ==============================================================================

func _build_level_1() -> void:
	_add_road_segment(-8.0, 30.0, GROUND_Y)
	_add_coin_arc(8.0, 1.35, 13.0, 4)
	_add_spikes(18.0, GROUND_Y, 1)
	_add_coin_arc(16.5, 2.0, 20.5, 4)
	_add_rescue_star(25.0, 1.35)

	# Gentle Gap #1 + Optional Sky Bridge
	_add_road_segment(33.0, 74.0, GROUND_Y)
	_add_coin_arc(29.8, 1.9, 33.8, 4)
	_add_oneway_bridge(40.0, 54.0, 2.35)
	_add_gem_line(42.0, 3.05, 52.0, 4)
	_add_boost_pad(46.0, GROUND_Y)
	_add_spikes(59.0, GROUND_Y, 2)
	_add_overhead_spikes(64.5, 1.15, 3.0)
	_add_coin_line(64.5, 0.55, 67.5, 4)

	# Scenic Gentle Moving Glider #1
	_add_moving_platform(79.0, 0.4, 4.4, Vector3(2.4, 0.0, 0.0), 1.35, 0.0, true)
	_add_coin_line(77.5, 1.45, 80.5, 3)

	_add_road_segment(85.0, 132.0, GROUND_Y)
	_add_downhill_ramp(92.0, GROUND_Y, 100.0, GROUND_Y - 1.2)
	_add_road_segment(100.0, 132.0, GROUND_Y - 1.2)
	_add_coin_line(93.5, 0.50, 98.5, 4)
	_add_spikes(110.0, GROUND_Y - 1.2, 2)
	_add_heart(118.0, 0.15)
	_add_boost_pad(126.0, GROUND_Y - 1.2)

	_add_road_segment(136.0, 188.0, GROUND_Y)
	_add_drone(146.0, 1.65, 1.6, 1.55)
	_add_oneway_bridge(155.0, 169.0, 2.35)
	_add_gem_line(157.0, 3.05, 167.0, 4)
	_add_pendulum_saw(177.0, 4.6, 3.0, 1.65, 0.58)
	_add_rescue_star(183.5, 1.40)

	# Easy Crumbling Crates + Final City Sprint
	_add_crumbling_platform(191.0, 195.5, 0.0)
	_add_crumbling_platform(198.0, 202.5, -0.1)
	_add_road_segment(205.0, 276.0, GROUND_Y)
	_add_boost_pad(211.0, GROUND_Y)
	_add_drone(223.0, 1.65, 1.8, 1.6)
	_add_spikes(233.0, GROUND_Y, 2)
	_add_heart(241.0, 1.35)
	_add_coin_line(245.0, 0.90, 255.0, 7)


# ==============================================================================
# LEVEL 2 (GOLDEN SUNSET MOVING BRIDGES - FUN & FAIR - 290m)
# ==============================================================================

func _build_level_2() -> void:
	_add_road_segment(-8.0, 28.0, GROUND_Y)
	_add_coin_line(7.0, 0.90, 14.0, 5)
	_add_spikes(19.0, GROUND_Y, 2)
	_add_boost_pad(26.6, GROUND_Y)

	# Smooth Rhythmic Moving Bridges + Helper Stepping Stones over Sunset Chasm (28..49)
	_add_moving_platform(32.5, 0.65, 5.0, Vector3(1.4, 0.0, 0.0), 1.25, 0.0, true)
	_add_coin_line(31.5, 1.65, 34.5, 3)
	_add_road_segment(36.8, 39.8, 0.55)
	_add_moving_platform(43.2, 1.05, 4.8, Vector3(0.0, 0.65, 0.0), 1.45, 1.1, false)
	_add_gem_line(41.5, 2.55, 44.5, 3)

	_add_road_segment(49.0, 102.0, GROUND_Y)
	_add_overhead_spikes(55.0, 1.15, 3.2)
	_add_crusher_piston(66.0, GROUND_Y, 0.0, 0.56)
	_add_spikes(76.0, GROUND_Y, 2)
	_add_rescue_star(85.0, 1.45)
	_add_drone(93.0, 1.60, 2.0, 1.75)
	_add_boost_pad(100.6, GROUND_Y)

	_add_moving_platform(107.2, 0.6, 5.0, Vector3(1.6, 0.0, 0.0), 1.35, 0.5, false)
	_add_road_segment(113.5, 117.2, 0.55)
	_add_pendulum_saw(115.5, 4.9, 3.0, 1.75, 0.60)
	_add_moving_platform(122.4, 1.0, 4.8, Vector3(0.0, 0.70, 0.0), 1.55, 1.6, true)

	_add_road_segment(128.5, 186.0, GROUND_Y)
	_add_boost_pad(133.0, GROUND_Y)
	_add_oneway_bridge(142.0, 160.0, 2.40)
	_add_gem_line(145.0, 3.10, 156.0, 5)
	_add_overhead_spikes(151.0, 1.15, 3.2)
	_add_rolling_boulder(178.0, GROUND_Y, 3.9, 163.0)
	_add_heart(182.0, 1.45)
	_add_boost_pad(184.6, GROUND_Y)

	# Chained Helper Stones & Downhill Sprint
	_add_crumbling_platform(189.0, 193.5, 0.1)
	_add_road_segment(194.2, 196.8, 0.35)
	_add_moving_platform(200.2, 0.45, 4.8, Vector3(1.6, 0.40, 0.0), 1.40, 0.0, false)
	_add_road_segment(206.0, 254.0, GROUND_Y)
	_add_downhill_ramp(212.0, GROUND_Y, 222.0, GROUND_Y - 1.4)
	_add_road_segment(222.0, 254.0, GROUND_Y - 1.4)
	_add_spikes(230.0, GROUND_Y - 1.4, 2)
	_add_boost_pad(252.2, GROUND_Y - 1.4)
	_add_road_segment(253.6, 257.4, GROUND_Y - 0.55)

	_add_road_segment(257.0, 306.0, GROUND_Y)
	_add_drone(265.0, 1.60, 2.0, 1.9)
	_add_spikes(274.0, GROUND_Y, 2)
	_add_coin_line(279.0, 1.0, 286.5, 6)


# ==============================================================================
# LEVEL 3 (COASTAL LAGOONS & CRYSTAL UNDERGROUND SHORTCUT - BALANCED - 320m)
# ==============================================================================

func _build_level_3() -> void:
	_add_road_segment(-8.0, 26.0, GROUND_Y)
	_add_coin_line(7.0, 0.90, 13.0, 4)
	_add_spikes(17.5, GROUND_Y, 2)

	# Section A: Sunny Coastal Lagoon with Wide Floating Rafts (26..68)
	_add_water_lagoon(25.0, 69.0, -1.75)
	_add_water_raft(29.5, 36.0, -0.35, 0.12, 2.0)
	_add_coin_arc(34.5, 1.15, 39.5, 4)
	_add_water_raft(40.0, 46.5, -0.35, 0.14, 2.2)
	_add_boost_pad(44.0, -0.30)
	_add_water_raft(52.0, 58.5, -0.30, 0.14, 2.3)
	_add_gem_line(53.5, 0.75, 57.0, 3)
	_add_water_raft(61.5, 67.5, -0.25, 0.12, 2.4)
	_add_rescue_star(64.5, 0.95)

	# Section B: Playable Crystal Stone Underground Tunnel ("انزل للأسفل لو تحب")
	_add_road_segment(68.0, 77.0, GROUND_Y)
	_add_oneway_bridge(77.0, 118.0, GROUND_Y)
	_add_spikes(88.0, GROUND_Y, 2)
	_add_drone(102.0, 1.50, 2.0, 1.95)

	_add_underground_tunnel(75.0, 120.0, -3.8, -0.8)
	_add_gem_line(82.0, -2.95, 95.0, 6)
	_add_spikes(99.0, -3.8, 2)
	_add_heart(105.5, -2.65)
	_add_boost_pad(113.5, -3.8)
	_add_coin_arc(114.5, 1.25, 120.5, 4)

	_add_road_segment(118.0, 162.0, GROUND_Y)
	_add_overhead_spikes(128.0, 1.15, 3.2)
	_add_pendulum_saw(138.0, 4.6, 3.1, 1.95, 0.64)
	_add_rolling_boulder(156.0, GROUND_Y, 4.0, 143.0)

	# Section C: Mid Lagoon & Sky Lifts (162..214)
	_add_water_lagoon(161.0, 214.0, -1.75)
	_add_moving_platform(167.0, -0.1, 4.2, Vector3(2.5, 0.5, 0.0), 1.55, 0.0, true)
	_add_water_raft(175.0, 182.0, -0.30, 0.14, 2.2)
	_add_drone(178.5, 1.55, 1.8, 1.9)
	_add_rescue_orb(185.5, 1.45)
	_add_water_raft(190.0, 197.0, -0.25, 0.13, 2.4)
	_add_moving_platform(203.0, 0.2, 4.2, Vector3(2.8, 0.0, 0.0), 1.65, 0.8, true)

	_add_road_segment(213.0, 258.0, GROUND_Y)
	_add_crusher_piston(226.0, GROUND_Y, 0.0, 0.62)
	_add_spikes(237.0, GROUND_Y, 2)
	_add_heart(246.0, 1.35)
	_add_boost_pad(253.0, GROUND_Y)

	# Section D: Final Water Sprint -> 320m
	_add_water_lagoon(257.0, 288.0, -1.75)
	_add_water_raft(263.0, 270.0, -0.25, 0.14, 2.2)
	_add_moving_platform(277.0, 0.1, 4.2, Vector3(2.6, 0.4, 0.0), 1.65, 0.4, false)
	_add_gem_line(281.0, 1.75, 287.0, 4)

	_add_road_segment(287.5, 336.0, GROUND_Y)
	_add_spikes(297.0, GROUND_Y, 2)
	_add_coin_line(305.0, 0.90, 316.0, 8)


# ==============================================================================
# LEVELS 4..10 (EXPANDED 10-STAGE ADVENTURE CAMPAIGN!)
# ==============================================================================

func _build_level_4() -> void:
	# Pine Highlands: Spring mushroom chains & elevated timber skyways
	_add_road_segment(-8.0, 26.0, GROUND_Y)
	_add_coin_line(7.0, 0.9, 15.0, 5)
	_add_spikes(19.5, GROUND_Y, 2)
	_add_boost_pad(24.6, GROUND_Y)

	_add_moving_platform(32.5, 0.4, 4.4, Vector3(2.2, 0.0, 0.0), 1.55, 0.0, true)
	_add_road_segment(36.8, 40.6, 0.0)
	_add_boost_pad(38.5, 0.0)
	_add_crumbling_platform(44.5, 49.0, 1.6)
	_add_gem_line(45.5, 2.7, 48.5, 3)

	_add_road_segment(52.5, 110.0, GROUND_Y)
	_add_drone(63.0, 1.55, 2.4, 2.15)
	_add_oneway_bridge(70.0, 92.0, 2.45)
	_add_overhead_spikes(77.0, 1.15, 3.6)
	_add_spikes(84.0, 2.45, 2)
	_add_heart(98.0, 1.45)
	_add_crusher_piston(103.0, GROUND_Y, 0.2, 0.68)

	_add_moving_platform(117.2, 0.4, 4.2, Vector3(0.0, 1.0, 0.0), 1.65, 0.6, false)
	_add_road_segment(122.7, 126.3, -0.35)
	_add_boost_pad(124.8, -0.35)
	_add_coin_line(123.3, 0.45, 125.7, 3)
	_add_pendulum_saw(124.5, 5.15, 3.15, 1.85, 0.62)
	_add_moving_platform(130.6, 0.8, 4.2, Vector3(2.2, 0.0, 0.0), 1.65, 1.2, true)

	_add_road_segment(139.0, 200.0, GROUND_Y)
	_add_downhill_ramp(146.0, GROUND_Y, 156.0, GROUND_Y - 1.5)
	_add_road_segment(156.0, 200.0, GROUND_Y - 1.5)
	_add_rolling_boulder(184.0, GROUND_Y - 1.5, 4.5, 165.0)
	_add_rescue_star(190.0, -0.1)
	_add_boost_pad(196.0, GROUND_Y - 1.5)

	_add_crumbling_platform(205.0, 209.5, 0.6)
	_add_moving_platform(216.0, 0.8, 3.8, Vector3(3.0, 0.6, 0.0), 1.85, 0.0, true)
	_add_road_segment(223.0, 276.0, GROUND_Y)
	_add_crusher_piston(234.0, GROUND_Y, 0.0, 0.72)
	_add_drone(246.0, 1.55, 2.6, 2.25)
	_add_spikes(258.0, GROUND_Y, 2)
	_add_rescue_orb(272.0, 1.5)

	_add_water_lagoon(276.5, 306.0, -1.75)
	_add_water_raft(281.5, 288.0, -0.30, 0.15, 2.4)
	_add_water_raft(294.5, 301.0, -0.25, 0.15, 2.6)
	_add_road_segment(305.5, 352.0, GROUND_Y)
	_add_spikes(315.0, GROUND_Y, 2)
	_add_coin_line(321.0, 1.0, 331.0, 8)


func _build_level_5() -> void:
	# Sunset Canyon Ruins: Rolling boulders, crumbling timber & saw pendulums
	_add_road_segment(-8.0, 28.0, GROUND_Y)
	_add_spikes(14.0, GROUND_Y, 2)
	_add_rolling_boulder(26.0, GROUND_Y, 4.2, 14.0)

	_add_crumbling_platform(30.5, 35.0, 0.2)
	_add_moving_platform(41.5, 0.7, 3.6, Vector3(3.4, 0.0, 0.0), 1.85, 0.2, false)
	_add_crumbling_platform(48.0, 52.5, 0.8)
	_add_gem_line(49.0, 1.9, 52.0, 3)

	_add_road_segment(55.5, 116.0, GROUND_Y)
	_add_pendulum_saw(65.0, 4.6, 3.3, 2.25, 0.72)
	_add_crusher_piston(76.0, GROUND_Y, 0.0, 0.76)
	_add_crusher_piston(83.0, GROUND_Y, 0.45, 0.76)
	_add_overhead_spikes(92.0, 1.15, 3.6)
	_add_heart(102.0, 1.35)
	_add_drone(109.0, 1.55, 2.4, 2.35)

	_add_moving_platform(122.0, 0.6, 3.6, Vector3(0.0, 1.4, 0.0), 2.15, 0.0, true)
	_add_pendulum_saw(129.0, 4.7, 3.3, 2.30, 0.74)
	_add_moving_platform(136.5, 0.9, 3.6, Vector3(3.2, 0.0, 0.0), 1.95, 1.0, false)

	_add_road_segment(143.0, 206.0, GROUND_Y)
	_add_boost_pad(147.0, GROUND_Y)
	_add_oneway_bridge(156.0, 180.0, 2.45)
	_add_spikes(164.0, 2.45, 2)
	_add_spikes(170.0, GROUND_Y, 3)
	_add_rolling_boulder(199.0, GROUND_Y, 4.8, 182.0)
	_add_rescue_star(202.0, 1.45)

	_add_crumbling_platform(209.0, 213.0, 0.2)
	_add_crumbling_platform(216.0, 220.0, 0.5)
	_add_moving_platform(226.5, 0.8, 3.6, Vector3(3.4, 0.7, 0.0), 2.0, 0.5, true)
	_add_road_segment(233.5, 294.0, GROUND_Y)
	_add_downhill_ramp(240.0, GROUND_Y, 250.0, GROUND_Y - 1.5)
	_add_road_segment(250.0, 294.0, GROUND_Y - 1.5)
	_add_pendulum_saw(263.0, 3.2, 3.1, 2.35, 0.74)
	_add_drone(276.0, 0.05, 2.6, 2.4)
	_add_boost_pad(288.0, GROUND_Y - 1.5)

	_add_road_segment(298.0, 366.0, GROUND_Y)
	_add_crusher_piston(310.0, GROUND_Y, 0.2, 0.78)
	_add_spikes(322.0, GROUND_Y, 3)
	_add_coin_line(332.0, 0.95, 344.0, 8)


func _build_level_6() -> void:
	# Twilight Glacier Skyway: Crisp high platforms, long lifts & air bees
	_add_road_segment(-8.0, 26.0, GROUND_Y)
	_add_spikes(15.0, GROUND_Y, 2)
	_add_rescue_star(22.0, 1.4)

	_add_moving_platform(32.0, 0.5, 3.6, Vector3(3.6, 0.0, 0.0), 1.95, 0.0, false)
	_add_drone(39.0, 1.95, 1.8, 2.3)
	_add_moving_platform(45.5, 1.1, 3.6, Vector3(0.0, 1.35, 0.0), 2.15, 0.8, true)
	_add_moving_platform(54.0, 0.8, 3.6, Vector3(3.4, 0.0, 0.0), 2.0, 1.4, false)

	_add_road_segment(61.0, 118.0, GROUND_Y)
	_add_crusher_piston(72.0, GROUND_Y, 0.0, 0.78)
	_add_spikes(82.0, GROUND_Y, 3)
	_add_overhead_spikes(91.0, 1.15, 3.8)
	_add_pendulum_saw(102.0, 4.6, 3.3, 2.40, 0.76)
	_add_heart(112.0, 1.4)

	_add_water_lagoon(118.0, 166.0, -1.75)
	_add_water_raft(123.0, 129.5, -0.35, 0.16, 2.5)
	_add_boost_pad(127.0, -0.30)
	_add_moving_platform(136.0, 0.4, 3.6, Vector3(2.8, 0.6, 0.0), 2.0, 0.0, true)
	_add_water_raft(145.0, 151.5, -0.30, 0.16, 2.7)
	_add_drone(155.0, 1.45, 2.2, 2.35)
	_add_water_raft(158.0, 164.0, -0.25, 0.14, 2.6)

	_add_road_segment(165.5, 224.0, GROUND_Y)
	_add_oneway_bridge(174.0, 198.0, 2.45)
	_add_gem_line(177.0, 3.15, 194.0, 6)
	_add_crusher_piston(184.0, GROUND_Y, 0.3, 0.80)
	_add_rolling_boulder(216.0, GROUND_Y, 5.0, 198.0)

	_add_crumbling_platform(227.0, 231.0, 0.3)
	_add_moving_platform(238.0, 0.8, 3.6, Vector3(3.4, 0.8, 0.0), 2.1, 0.5, false)
	_add_crumbling_platform(245.5, 249.5, 1.0)
	_add_rescue_orb(253.5, 1.75)

	_add_road_segment(257.0, 316.0, GROUND_Y)
	_add_pendulum_saw(268.0, 4.6, 3.3, 2.45, 0.78)
	_add_overhead_spikes(278.0, 1.15, 3.8)
	_add_spikes(290.0, GROUND_Y, 3)
	_add_boost_pad(304.0, GROUND_Y)

	_add_moving_platform(322.0, 0.7, 3.8, Vector3(3.2, 0.0, 0.0), 2.05, 0.2, true)
	_add_road_segment(329.0, 376.0, GROUND_Y)
	_add_spikes(338.0, GROUND_Y, 2)
	_add_coin_line(345.0, 0.95, 355.0, 8)


func _build_level_7() -> void:
	# Deep Stone Vaults: Dual multi-tier underground drop tunnels + crystal corridors
	_add_road_segment(-8.0, 34.0, GROUND_Y)
	_add_spikes(15.0, GROUND_Y, 2)

	_add_oneway_bridge(34.0, 82.0, GROUND_Y)
	_add_pendulum_saw(47.0, 4.6, 3.2, 2.3, 0.72)
	_add_drone(64.0, 1.45, 2.5, 2.3)

	_add_underground_tunnel(32.0, 84.0, -3.8, -0.8)
	_add_gem_line(40.0, -2.95, 54.0, 6)
	_add_crusher_piston(59.0, -3.8, 0.2, 0.78)
	_add_heart(67.0, -2.65)
	_add_boost_pad(77.0, -3.8)

	_add_road_segment(82.0, 134.0, GROUND_Y)
	_add_overhead_spikes(92.0, 1.15, 3.8)
	_add_rolling_boulder(126.0, GROUND_Y, 5.0, 106.0)
	_add_rescue_star(129.0, 1.45)

	_add_moving_platform(140.5, 0.6, 3.5, Vector3(3.6, 0.0, 0.0), 2.1, 0.0, true)
	_add_crumbling_platform(148.0, 152.0, 0.7)
	_add_moving_platform(159.0, 1.0, 3.5, Vector3(0.0, 1.4, 0.0), 2.25, 1.0, false)

	_add_road_segment(166.0, 178.0, GROUND_Y)
	_add_oneway_bridge(178.0, 232.0, GROUND_Y)
	_add_crusher_piston(192.0, GROUND_Y, 0.0, 0.80)
	_add_spikes(210.0, GROUND_Y, 3)

	_add_underground_tunnel(176.0, 234.0, -3.8, -0.8)
	_add_coin_line(184.0, -2.95, 198.0, 6)
	_add_drone(204.0, -2.25, 2.4, 2.4)
	_add_gem_line(210.0, -2.9, 222.0, 5)
	_add_boost_pad(227.5, -3.8)

	_add_road_segment(232.0, 286.0, GROUND_Y)
	_add_downhill_ramp(240.0, GROUND_Y, 250.0, GROUND_Y - 1.5)
	_add_road_segment(250.0, 286.0, GROUND_Y - 1.5)
	_add_pendulum_saw(264.0, 3.1, 3.1, 2.4, 0.75)
	_add_boost_pad(280.0, GROUND_Y - 1.5)

	_add_water_lagoon(287.0, 332.0, -1.75)
	_add_water_raft(292.0, 298.5, -0.30, 0.16, 2.6)
	_add_moving_platform(306.0, 0.2, 3.5, Vector3(3.0, 0.5, 0.0), 2.1, 0.3, false)
	_add_water_raft(315.0, 321.5, -0.25, 0.16, 2.7)
	_add_rescue_orb(326.0, 1.5)

	_add_road_segment(331.5, 392.0, GROUND_Y)
	_add_crusher_piston(344.0, GROUND_Y, 0.4, 0.82)
	_add_spikes(356.0, GROUND_Y, 3)
	_add_coin_line(362.0, 0.95, 372.0, 7)


func _build_level_8() -> void:
	# Twin Lagoon Archipelago: Long buoyant ocean crossings & sky platforms
	_add_road_segment(-8.0, 24.0, GROUND_Y)
	_add_spikes(14.5, GROUND_Y, 2)

	_add_water_lagoon(23.5, 86.0, -1.75)
	_add_water_raft(28.0, 34.0, -0.35, 0.16, 2.5)
	_add_water_raft(38.0, 44.0, -0.30, 0.18, 2.8)
	_add_boost_pad(42.0, -0.25)
	_add_drone(47.2, 1.55, 2.2, 2.4)
	_add_water_raft(50.2, 56.5, -0.30, 0.16, 2.6)
	_add_moving_platform(65.0, 0.3, 3.6, Vector3(3.2, 0.6, 0.0), 2.1, 0.0, true)
	_add_water_raft(74.0, 80.5, -0.25, 0.16, 2.8)

	_add_road_segment(85.0, 144.0, GROUND_Y)
	_add_pendulum_saw(96.0, 4.6, 3.3, 2.45, 0.78)
	_add_crusher_piston(108.0, GROUND_Y, 0.0, 0.82)
	_add_overhead_spikes(118.0, 1.15, 3.8)
	_add_heart(128.0, 1.40)
	_add_rolling_boulder(140.0, GROUND_Y, 5.2, 126.0)

	_add_crumbling_platform(147.0, 151.0, 0.2)
	_add_moving_platform(158.0, 0.7, 3.5, Vector3(3.6, 0.0, 0.0), 2.2, 0.6, false)
	_add_crumbling_platform(165.0, 169.0, 0.9)
	_add_moving_platform(176.0, 1.1, 3.5, Vector3(0.0, 1.4, 0.0), 2.3, 1.3, true)

	_add_road_segment(182.0, 236.0, GROUND_Y)
	_add_oneway_bridge(190.0, 214.0, 2.45)
	_add_spikes(198.0, 2.45, 2)
	_add_drone(204.0, 1.10, 2.6, 2.5)
	_add_rescue_star(226.0, 1.45)
	_add_boost_pad(232.0, GROUND_Y)

	_add_water_lagoon(235.0, 304.0, -1.75)
	_add_water_raft(240.0, 246.0, -0.35, 0.16, 2.6)
	_add_pendulum_saw(250.5, 4.4, 3.2, 2.45, 0.76)
	_add_water_raft(255.0, 261.0, -0.30, 0.16, 2.8)
	_add_rescue_orb(265.0, 1.45)
	_add_moving_platform(273.0, 0.2, 3.6, Vector3(3.4, 0.5, 0.0), 2.15, 0.4, false)
	_add_water_raft(282.0, 288.0, -0.28, 0.17, 2.7)
	_add_water_raft(293.0, 299.5, -0.25, 0.16, 2.9)

	_add_road_segment(303.0, 402.0, GROUND_Y)
	_add_crusher_piston(316.0, GROUND_Y, 0.0, 0.84)
	_add_crusher_piston(324.0, GROUND_Y, 0.48, 0.84)
	_add_spikes(336.0, GROUND_Y, 3)
	_add_drone(352.0, 1.55, 2.6, 2.55)
	_add_coin_line(366.0, 0.95, 380.0, 9)


func _build_level_9() -> void:
	# Golden Cloud Citadel: Rapid sky gauntlets, downslopes & synchronized saws
	_add_road_segment(-8.0, 28.0, GROUND_Y)
	_add_boost_pad(10.0, GROUND_Y)
	_add_spikes(20.0, GROUND_Y, 2)

	_add_moving_platform(34.0, 0.8, 3.4, Vector3(3.6, 0.5, 0.0), 2.25, 0.0, true)
	_add_crumbling_platform(41.0, 45.0, 1.2)
	_add_moving_platform(52.0, 1.2, 3.4, Vector3(0.0, 1.45, 0.0), 2.4, 1.1, false)
	_add_gem_line(50.5, 3.2, 54.0, 3)

	_add_road_segment(59.0, 120.0, GROUND_Y)
	_add_pendulum_saw(70.0, 4.6, 3.3, 2.55, 0.80)
	_add_pendulum_saw(79.0, 4.6, 3.3, 2.55, 0.80)
	_add_overhead_spikes(88.0, 1.15, 4.0)
	_add_crusher_piston(99.0, GROUND_Y, 0.0, 0.86)
	_add_heart(108.0, 1.4)
	_add_rolling_boulder(118.0, GROUND_Y, 5.4, 102.0)

	_add_oneway_bridge(120.0, 174.0, GROUND_Y)
	_add_drone(134.0, 1.50, 2.8, 2.55)
	_add_spikes(148.0, GROUND_Y, 3)
	_add_underground_tunnel(118.0, 176.0, -3.8, -0.8)
	_add_crusher_piston(136.0, -3.8, 0.25, 0.84)
	_add_gem_line(144.0, -2.9, 158.0, 6)
	_add_boost_pad(168.0, -3.8)

	_add_road_segment(174.0, 232.0, GROUND_Y)
	_add_downhill_ramp(182.0, GROUND_Y, 192.0, GROUND_Y - 1.5)
	_add_road_segment(192.0, 232.0, GROUND_Y - 1.5)
	_add_drone(204.0, 0.05, 2.8, 2.6)
	_add_crusher_piston(215.0, GROUND_Y - 1.5, 0.35, 0.86)
	_add_boost_pad(226.0, GROUND_Y - 1.5)

	_add_crumbling_platform(237.0, 241.0, 0.6)
	_add_moving_platform(248.0, 0.9, 3.4, Vector3(3.6, 0.0, 0.0), 2.3, 0.2, false)
	_add_pendulum_saw(256.0, 4.7, 3.3, 2.6, 0.80)
	_add_moving_platform(264.0, 1.0, 3.4, Vector3(3.4, 0.8, 0.0), 2.25, 1.4, true)

	_add_road_segment(271.0, 336.0, GROUND_Y)
	_add_spikes(282.0, GROUND_Y, 3)
	_add_rolling_boulder(310.0, GROUND_Y, 5.4, 290.0)
	_add_rescue_star(318.0, 1.45)
	_add_overhead_spikes(326.0, 1.15, 4.0)

	_add_water_lagoon(336.0, 368.0, -1.75)
	_add_water_raft(341.0, 347.0, -0.32, 0.17, 2.8)
	_add_moving_platform(355.0, 0.2, 3.6, Vector3(3.2, 0.6, 0.0), 2.2, 0.5, false)
	_add_road_segment(367.0, 418.0, GROUND_Y)
	_add_spikes(377.0, GROUND_Y, 3)
	_add_coin_line(384.0, 0.95, 396.0, 8)


func _build_level_10() -> void:
	# Grand Summit Finale: Every biome & mechanic combined across 430m!
	_add_road_segment(-8.0, 26.0, GROUND_Y)
	_add_coin_line(6.0, 0.95, 14.0, 5)
	_add_spikes(18.0, GROUND_Y, 2)

	_add_moving_platform(32.0, 0.6, 3.4, Vector3(3.8, 0.0, 0.0), 2.35, 0.0, true)
	_add_crumbling_platform(39.0, 43.0, 0.8)
	_add_pendulum_saw(47.0, 4.7, 3.3, 2.65, 0.82)
	_add_moving_platform(54.0, 1.1, 3.4, Vector3(0.0, 1.5, 0.0), 2.45, 0.9, false)

	_add_road_segment(61.0, 120.0, GROUND_Y)
	_add_crusher_piston(72.0, GROUND_Y, 0.0, 0.88)
	_add_crusher_piston(80.0, GROUND_Y, 0.45, 0.88)
	_add_drone(92.0, 1.55, 2.8, 2.65)
	_add_overhead_spikes(102.0, 1.15, 4.0)
	_add_heart(112.0, 1.45)

	# Lagoon Crossing + Stone Vault Combo (120..226)
	_add_water_lagoon(120.0, 166.0, -1.75)
	_add_water_raft(125.0, 131.0, -0.35, 0.17, 2.8)
	_add_boost_pad(129.0, -0.30)
	_add_drone(137.0, 1.55, 2.2, 2.55)
	_add_water_raft(142.0, 148.0, -0.30, 0.17, 2.9)
	_add_moving_platform(156.0, 0.3, 3.5, Vector3(3.4, 0.7, 0.0), 2.3, 0.4, false)

	_add_road_segment(165.5, 176.0, GROUND_Y)
	_add_oneway_bridge(176.0, 228.0, GROUND_Y)
	_add_pendulum_saw(190.0, 4.6, 3.3, 2.6, 0.80)
	_add_spikes(206.0, GROUND_Y, 3)

	_add_underground_tunnel(174.0, 230.0, -3.8, -0.8)
	_add_gem_line(182.0, -2.95, 196.0, 6)
	_add_crusher_piston(204.0, -3.8, 0.3, 0.88)
	_add_rescue_star(214.0, -2.65)
	_add_boost_pad(222.5, -3.8)

	_add_road_segment(228.0, 294.0, GROUND_Y)
	_add_downhill_ramp(236.0, GROUND_Y, 246.0, GROUND_Y - 1.5)
	_add_road_segment(246.0, 294.0, GROUND_Y - 1.5)
	_add_rolling_boulder(282.0, GROUND_Y - 1.5, 5.6, 256.0)
	_add_boost_pad(288.0, GROUND_Y - 1.5)

	# Finale Skyway & Water Dash -> 430m Victory!
	_add_crumbling_platform(299.0, 303.0, 0.6)
	_add_moving_platform(310.0, 0.9, 3.4, Vector3(3.8, 0.0, 0.0), 2.35, 0.0, true)
	_add_crumbling_platform(318.0, 322.0, 1.0)
	_add_rescue_orb(326.5, 1.75)

	_add_water_lagoon(331.0, 374.0, -1.75)
	_add_water_raft(336.0, 342.0, -0.32, 0.18, 2.9)
	_add_pendulum_saw(347.0, 4.5, 3.3, 2.65, 0.82)
	_add_water_raft(352.0, 358.0, -0.28, 0.17, 2.9)
	_add_moving_platform(365.0, 0.2, 3.5, Vector3(3.4, 0.6, 0.0), 2.3, 0.5, false)

	_add_road_segment(373.5, 448.0, GROUND_Y)
	_add_crusher_piston(385.0, GROUND_Y, 0.2, 0.88)
	_add_drone(398.0, 1.55, 2.8, 2.65)
	_add_spikes(408.0, GROUND_Y, 3)
	_add_gem_line(415.0, 1.0, 425.0, 6)


func _build_evolved_level(lvl: int) -> void:
	# Levels 11..30: Progressive evolved architecture featuring Swooping Bats, Mecha Drones, Giant Wasps,
	# Flying Cannonballs, Sudden Pop-Up Ambush Traps, Bouncer Springs, & Crystal Triple-Jump / Magnet Abilities!
	var tier := lvl - 10 # 1..20
	var total_len := get_level_length(lvl)
	var spd_k := 1.0 + float(tier) * 0.022
	var rng := RandomNumberGenerator.new()
	rng.seed = 11000 + lvl * 137

	# Safe Starter Runway
	_add_road_segment(-8.0, 26.0, GROUND_Y)
	_add_coin_line(6.0, 0.95, 14.0, 5)
	_add_ambush_trap(18.5, GROUND_Y, "spikes" if lvl % 2 == 1 else "bomb")

	var enemy_cycle := ["bat", "cyborg", "giant_bee", "bee"]
	var cur_x := 26.0
	var chunk_idx := 0
	var end_limit := total_len - 34.0

	while cur_x < end_limit - 36.0:
		var mode := (chunk_idx + lvl) % 6
		var e_kind: String = enemy_cycle[(chunk_idx + tier) % enemy_cycle.size()]
		var has_heart := (chunk_idx == 3)

		match mode:
			0:
				# Aerial Swarm & Crystal Triple-Jump Skyway (~52m)
				_add_moving_platform(cur_x + 5.5, 0.55, 3.8, Vector3(2.8, 0.0, 0.0), 1.9 * spd_k, 0.0, true)
				_add_road_segment(cur_x + 11.5, cur_x + 52.0, GROUND_Y)
				_add_ability_crystal(cur_x + 15.0, 1.35, "turbo_crystal")
				_add_oneway_bridge(cur_x + 20.0, cur_x + 36.0, 2.45)
				_add_drone(cur_x + 28.0, 3.85 if e_kind == "bat" else 3.45, 3.0, 2.25 * spd_k, e_kind)
				_add_gem_line(cur_x + 22.0, 3.15, cur_x + 34.0, 5)
				_add_ambush_trap(cur_x + 27.0, GROUND_Y, "bomb")
				_add_drone(cur_x + 43.0, 1.55, 2.6, 2.15 * spd_k, enemy_cycle[(chunk_idx + 1) % enemy_cycle.size()])
				cur_x += 52.0
			1:
				# Ambush Boulevard & Flying Cannonball Run (~54m)
				_add_road_segment(cur_x, cur_x + 54.0, GROUND_Y)
				_add_downhill_ramp(cur_x + 6.0, GROUND_Y, cur_x + 15.0, GROUND_Y - 1.4)
				_add_road_segment(cur_x + 15.0, cur_x + 54.0, GROUND_Y - 1.4)
				_add_ambush_trap(cur_x + 21.0, GROUND_Y - 1.4, "spikes")
				_add_overhead_spikes(cur_x + 27.0, -0.25, 4.0)
				_add_coin_line(cur_x + 27.0, -0.85, cur_x + 31.0, 4)
				_add_flying_cannon(cur_x + 48.0, GROUND_Y - 0.35, 6.2 + float(tier) * 0.14, 17.0)
				if has_heart:
					_add_heart(cur_x + 38.0, 0.10)
				_add_bouncer(cur_x + 49.5, GROUND_Y - 1.4)
				cur_x += 54.0
			2:
				# Wide Water Lagoon + Buoyant Rafts + Giant Wasp/Bat (~48m)
				_add_water_lagoon(cur_x, cur_x + 46.0, -1.75)
				_add_water_raft(cur_x + 4.5, cur_x + 10.5, -0.32, 0.18, 2.6)
				_add_bouncer(cur_x + 8.5, -0.30)
				_add_drone(cur_x + 16.5, 1.85, 2.3, 2.25 * spd_k, e_kind)
				_add_water_raft(cur_x + 21.0, cur_x + 27.5, -0.28, 0.18, 2.75)
				_add_moving_platform(cur_x + 35.5, 0.25, 3.8, Vector3(2.8, 0.6, 0.0), 2.1 * spd_k, 0.4, false)
				_add_gem_line(cur_x + 22.0, 0.90, cur_x + 26.5, 3)
				_add_road_segment(cur_x + 46.0, cur_x + 52.0, GROUND_Y)
				cur_x += 52.0
			3:
				# Crusher Vault + Sky Feather Magnet Underground Secret (~54m)
				_add_road_segment(cur_x, cur_x + 4.2, GROUND_Y)
				_add_oneway_bridge(cur_x + 4.0, cur_x + 48.0, GROUND_Y)
				_add_road_segment(cur_x + 47.8, cur_x + 54.0, GROUND_Y)
				_add_pendulum_saw(cur_x + 18.0, 4.65, 3.3, 2.3 * spd_k, 0.78)
				_add_drone(cur_x + 34.0, 1.70, 2.8, 2.35 * spd_k, e_kind)
				_add_underground_tunnel(cur_x + 2.0, cur_x + 50.0, -3.8, -0.8)
				_add_ability_crystal(cur_x + 10.0, -2.8, "sky_feather")
				_add_crusher_piston(cur_x + 21.0, -3.8, 0.1, 0.82 * spd_k)
				_add_crusher_piston(cur_x + 30.0, -3.8, 0.55, 0.82 * spd_k)
				_add_gem_line(cur_x + 14.0, -2.9, cur_x + 38.0, 7)
				_add_boost_pad(cur_x + 44.5, -3.8)
				cur_x += 54.0
			4:
				# Pendulum Sawmill Sky-Hops & Crumbling Crates (~46m)
				_add_crumbling_platform(cur_x + 4.5, cur_x + 8.8, 0.6)
				_add_moving_platform(cur_x + 15.5, 0.85, 3.8, Vector3(3.2, 0.0, 0.0), 2.15 * spd_k, 0.0, true)
				_add_pendulum_saw(cur_x + 23.0, 4.7, 3.3, 2.35 * spd_k, 0.78)
				_add_crumbling_platform(cur_x + 29.5, cur_x + 33.8, 0.85)
				_add_rescue_orb(cur_x + 38.5, 1.55)
				_add_road_segment(cur_x + 42.0, cur_x + 48.0, GROUND_Y)
				cur_x += 48.0
			_:
				# Dual-Threat Fortress Blitz (~50m)
				_add_road_segment(cur_x, cur_x + 50.0, GROUND_Y)
				_add_crusher_piston(cur_x + 10.0, GROUND_Y, 0.0, 0.86 * spd_k)
				_add_ambush_trap(cur_x + 18.5, GROUND_Y, "bomb")
				_add_drone(cur_x + 27.0, 1.75, 2.8, 2.4 * spd_k, "cyborg" if tier >= 4 else e_kind)
				_add_flying_cannon(cur_x + 44.0, GROUND_Y + 0.95, 6.6 + float(tier) * 0.14, 15.0)
				if has_heart:
					_add_heart(cur_x + 34.0, 1.45)
				_add_rescue_star(cur_x + 46.0, 1.45)
				cur_x += 50.0
		chunk_idx += 1

	# Final Sprint & Celebratory Gem Approach to Finish Arch
	_add_road_segment(cur_x - 1.0, total_len + 18.0, GROUND_Y)
	if cur_x + 10.0 < total_len - 10.0:
		_add_ambush_trap(cur_x + 8.0, GROUND_Y, "spikes")
	_add_gem_line(total_len - 22.0, 1.05, total_len - 8.0, 6)


# ==============================================================================
# SPECIAL 3D MECHANICS (WATER LAGOON, BUOYANT RAFTS, MOVING BRIDGES, TUNNELS)
# ==============================================================================

func _build_mud_catchers_between(min_x: float, max_x: float, surface_y: float) -> void:
	# Sort blocked intervals (lagoons & playable stone underground tunnels)
	var sorted := _mud_blocked_ranges.duplicate()
	sorted.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
	var cur_x := min_x
	for rng in sorted:
		if rng.x > cur_x + 0.5:
			_add_mud_floor_strip(cur_x, rng.x, surface_y)
		cur_x = maxf(cur_x, rng.y)
	if max_x > cur_x + 0.5:
		_add_mud_floor_strip(cur_x, max_x, surface_y)


func _add_mud_floor_strip(x0: float, x1: float, top_y: float) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5

	# Solid Ground/Mud Basin Body ("الأرض الطينية الصلبة - مفيش نزول تحت الأرض")
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, top_y, 0.0)
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 1.2, 6.0)
	col.shape = box
	col.position = Vector3(0.0, -0.60, 0.0)
	body.add_child(col)

	var mud_mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(length, 0.45, 7.6)
	mud_mesh.mesh = bm
	mud_mesh.material_override = _mud_mat
	mud_mesh.position = Vector3(0.0, -0.225, -0.5)
	mud_mesh.visibility_range_end = 0.0
	body.add_child(mud_mesh)

	# Side retaining wall curbs preventing falling off front/back sides of lower floor
	for sz_side in [-1.52, 1.52]:
		var rail_col := CollisionShape3D.new()
		var rbox := BoxShape3D.new()
		rbox.size = Vector3(length, 8.0, 0.24)
		rail_col.shape = rbox
		rail_col.position = Vector3(0.0, 3.8, sz_side)
		body.add_child(rail_col)

		var rail_vis := MeshInstance3D.new()
		var rvm := BoxMesh.new()
		rvm.size = Vector3(length, 0.34, 0.22)
		rail_vis.mesh = rvm
		rail_vis.material_override = _tunnel_wall_mat
		rail_vis.position = Vector3(0.0, 0.15, sz_side)
		rail_vis.visibility_range_end = 90.0
		body.add_child(rail_vis)

	# Mud Pit Trigger right at the surface of the mud floor
	var trap := Area3D.new()
	trap.collision_layer = 4
	trap.collision_mask = 0
	trap.monitoring = false
	trap.monitorable = true
	trap.set_meta("trigger_kind", "mud")
	trap.set_meta("surface_y", top_y)
	trap.position = Vector3(cx, top_y, 0.0)
	add_child(trap)

	var tcol := CollisionShape3D.new()
	var tbox := BoxShape3D.new()
	tbox.size = Vector3(length, 0.35, 3.6)
	tcol.shape = tbox
	tcol.position = Vector3(0.0, 0.10, 0.0)
	trap.add_child(tcol)


func _add_water_lagoon(x0: float, x1: float, top_y: float) -> void:
	_mud_blocked_ranges.append(Vector2(x0 - 0.5, x1 + 0.5))
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "water")
	area.set_meta("surface_y", top_y)
	area.position = Vector3(cx, top_y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 2.2, 3.6)
	col.shape = box
	col.position = Vector3(0, -1.1, 0)
	area.add_child(col)

	var water := MeshInstance3D.new()
	var wm := PlaneMesh.new()
	# Deep wide water basin spanning well behind back bank and past camera foreground so edges never clip when falling!
	wm.size = Vector2(length + 3.2, 24.0)
	wm.subdivide_width = maxi(16, int(length * 1.3))
	wm.subdivide_depth = 10
	water.mesh = wm
	water.material_override = _water_shader_mat
	water.position = Vector3(cx, top_y, 5.0)
	water.visibility_range_end = 104.0
	add_child(water)

	# Deep dark underwater ocean seabed & side banks sealing water basin completely below and on both flanks
	var sea_body := StaticBody3D.new()
	sea_body.collision_layer = 1
	sea_body.position = Vector3(cx, top_y - 2.0, 5.0)
	add_child(sea_body)
	var sea_col := CollisionShape3D.new()
	var sea_box := BoxShape3D.new()
	sea_box.size = Vector3(length + 3.2, 0.8, 24.0)
	sea_col.shape = sea_box
	sea_body.add_child(sea_col)

	var sea_mat := StandardMaterial3D.new()
	sea_mat.albedo_color = Color(0.03, 0.16, 0.28)
	sea_mat.roughness = 0.88

	var seabed := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(length + 3.2, 0.9, 24.0)
	seabed.mesh = sbm
	seabed.material_override = sea_mat
	seabed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seabed.visibility_range_end = 104.0
	sea_body.add_child(seabed)

	for end_x in [-length * 0.5 - 0.3, length * 0.5 + 0.3]:
		var bank := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 2.6, 24.0)
		bank.mesh = bm
		bank.material_override = _tunnel_wall_mat
		bank.position = Vector3(end_x, 0.85, 0.0)
		bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bank.visibility_range_end = 100.0
		sea_body.add_child(bank)


func _add_water_raft(x0: float, x1: float, y: float, bob_amp: float, bob_freq: float) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var body := AnimatableBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, y, 0.0)
	body.sync_to_physics = true
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.36, 2.4)
	col.shape = box
	col.position = Vector3(0, -0.18, 0)
	body.add_child(col)

	var vis := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(length, 0.34, 2.4)
	vis.mesh = vm
	vis.material_override = _raft_wood_mat
	vis.position = Vector3(0, -0.17, 0)
	vis.visibility_range_end = 82.0
	body.add_child(vis)

	# Natural dark-oak hull trim underneath wooden raft (removed awkward blue slab on top!)
	var hull_mat := StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.46, 0.28, 0.14)
	hull_mat.roughness = 0.80
	var trim := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(length - 0.12, 0.12, 2.46)
	trim.mesh = tm
	trim.material_override = hull_mat
	trim.position = Vector3(0, -0.28, 0)
	trim.visibility_range_end = 82.0
	body.add_child(trim)

	_moving_plats.append({
		"body": body, "origin": Vector3(cx, y, 0.0),
		"amp": Vector3(0.0, bob_amp, 0.0), "freq": bob_freq, "phase": cx * 0.3,
		"raft": true
	})


func _add_moving_platform(cx: float, y: float, length: float, amp: Vector3, freq: float, phase: float, one_way: bool) -> void:
	var body := AnimatableBody3D.new()
	body.collision_layer = 2 if one_way else 1
	body.position = Vector3(cx, y, 0.0)
	body.sync_to_physics = true
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.18 if one_way else 0.42, 2.4)
	col.shape = box
	col.position = Vector3(0, -0.09 if one_way else -0.21, 0)
	body.add_child(col)

	var vis := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(length, 0.28, 2.3)
	vis.mesh = vm
	vis.material_override = _deck_side_mat
	vis.position = Vector3(0, -0.14, 0)
	vis.visibility_range_end = 86.0
	body.add_child(vis)

	var accent := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(length - 0.08, 0.10, 2.38)
	accent.mesh = am
	accent.material_override = _deck_top_mat
	accent.position = Vector3(0, -0.18, 0)
	accent.visibility_range_end = 86.0
	body.add_child(accent)

	_moving_plats.append({
		"body": body, "origin": Vector3(cx, y, 0.0),
		"amp": amp, "freq": freq, "phase": phase
	})


func _add_underground_tunnel(x0: float, x1: float, floor_y: float, roof_y: float) -> void:
	_mud_blocked_ranges.append(Vector2(x0 - 2.0, x1 + 2.0))
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, floor_y, 0.0)
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.65, 3.2)
	col.shape = box
	col.position = Vector3(0, -0.325, 0)
	body.add_child(col)

	var floor_m := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(length, 0.55, 3.1)
	floor_m.mesh = fm
	floor_m.material_override = _tunnel_wall_mat
	floor_m.position = Vector3(0, -0.275, 0)
	floor_m.visibility_range_end = 86.0
	body.add_child(floor_m)

	# Back underground wall & glowing neon cyan strip lights showing playable underground tunnel clearly!
	var back_wall := MeshInstance3D.new()
	var bwm := BoxMesh.new()
	bwm.size = Vector3(length, (roof_y - floor_y), 0.35)
	back_wall.mesh = bwm
	back_wall.material_override = _tunnel_wall_mat
	back_wall.position = Vector3(0, (roof_y - floor_y) * 0.5, -1.75)
	back_wall.visibility_range_end = 86.0
	body.add_child(back_wall)

	var strip := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(length - 0.6, 0.14, 0.14)
	strip.mesh = sm
	strip.material_override = _tunnel_glow_mat
	strip.position = Vector3(0, roof_y - floor_y - 0.25, -1.52)
	strip.visibility_range_end = 86.0
	body.add_child(strip)

	# Vertical pillars along underground tunnel background
	var px := -length * 0.5 + 3.0
	while px < length * 0.5 - 2.0:
		var pil := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.45, roof_y - floor_y, 0.45)
		pil.mesh = pm
		pil.material_override = _deck_side_mat
		pil.position = Vector3(px, (roof_y - floor_y) * 0.5, -1.55)
		pil.visibility_range_end = 82.0
		body.add_child(pil)
		px += 9.0


# ==============================================================================
# SLEEK ARCHITECTURAL ROAD & PROPS
# ==============================================================================

func get_safe_revive_pos(near_x: float) -> Vector3:
	var best := Vector3(1.5, GROUND_Y + 0.2, 0.0)
	var best_score := 99999.0
	var ideal_x := maxf(1.5, near_x - 2.6)
	for seg in _safe_road_ranges:
		var x0: float = seg.x + 1.4
		var x1: float = seg.y - 1.4
		if x1 <= x0:
			continue
		var clamped := clampf(ideal_x, x0, x1)
		if clamped > near_x + 1.0:
			continue
		var d := absf(clamped - ideal_x) + (0.0 if ideal_x >= x0 and ideal_x <= x1 else 3.5)
		if d < best_score:
			best_score = d
			best = Vector3(clamped, seg.z + 0.15, 0.0)
	return best


func _add_road_segment(x0: float, x1: float, top_y: float) -> void:
	var length := x1 - x0
	if length >= 2.8:
		_safe_road_ranges.append(Vector3(x0, x1, top_y))
	var cx := (x0 + x1) * 0.5
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, top_y, 0.0)
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(0.4, length - 0.08), 0.72, 3.2)
	col.shape = box
	col.position = Vector3(0, -0.36, 0)
	body.add_child(col)

	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(length, 0.58, 3.1)
	deck.mesh = dm
	deck.material_override = _deck_side_mat
	deck.position = Vector3(0, -0.31, 0)
	deck.visibility_range_end = 90.0
	body.add_child(deck)

	var trim := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(length, 0.14, 3.16)
	trim.mesh = tm
	trim.material_override = _deck_trim_mat
	trim.position = Vector3(0, -0.10, 0)
	trim.visibility_range_end = 90.0
	body.add_child(trim)

	var curb := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(length, 0.22, 0.75)
	curb.mesh = cm
	curb.material_override = _grass_trim_mat
	curb.position = Vector3(0, -0.08, -1.75)
	curb.visibility_range_end = 86.0
	body.add_child(curb)

	var px := -length * 0.5 + 2.5
	while px < length * 0.5 - 1.5:
		var pil := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.28
		pm.bottom_radius = 0.36
		pm.height = 4.2
		pil.mesh = pm
		pil.material_override = _deck_side_mat
		pil.position = Vector3(px, -2.6, 0.0)
		pil.visibility_range_end = 86.0
		body.add_child(pil)
		px += 12.0

	var tile_count := maxi(1, int(ceil(length / 4.0)))
	var actual_tile_len := length / float(tile_count)
	for i in range(tile_count):
		var tx := -length * 0.5 + (float(i) + 0.5) * actual_tile_len
		var sc: PackedScene = _sc_crossing if (i % 6 == 3 and actual_tile_len > 3.2) else _sc_road
		var rd := sc.instantiate()
		rd.position = Vector3(tx, -0.02, 0)
		rd.scale = Vector3(actual_tile_len, 1.0, 2.55)
		_apply_cull_and_mat(rd, null, 88.0)
		body.add_child(rd)

		if i % 3 == 0:
			var lamp := _sc_lamp.instantiate()
			lamp.position = Vector3(tx, 0.0, -1.60)
			lamp.scale = Vector3.ONE * 4.8
			_apply_cull_and_mat(lamp, null, 76.0)
			body.add_child(lamp)
		elif i % 4 == 2:
			var fl := _sc_flowers.instantiate()
			fl.position = Vector3(tx, 0.02, -1.72)
			fl.scale = Vector3.ONE * 1.25
			_apply_cull_and_mat(fl, null, 68.0)
			body.add_child(fl)


func _add_downhill_ramp(x0: float, y0: float, x1: float, y1: float) -> void:
	var dx := x1 - x0
	var dy := y1 - y0
	var slope_len := sqrt(dx * dx + dy * dy)
	var ang := atan2(dy, dx)
	var mid := Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0.0)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = mid
	body.rotation.z = ang
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(slope_len + 0.15, 0.72, 3.2)
	col.shape = box
	col.position = Vector3(0, -0.36, 0)
	body.add_child(col)

	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(slope_len + 0.15, 0.58, 3.0)
	deck.mesh = dm
	deck.material_override = _deck_side_mat
	deck.position = Vector3(0, -0.31, 0)
	deck.visibility_range_end = 86.0
	body.add_child(deck)

	var tile_count := maxi(1, int(ceil(slope_len / 4.0)))
	var tile_w := (slope_len + 0.12) / float(tile_count)
	for i in range(tile_count):
		var tx := -(slope_len * 0.5) + (float(i) + 0.5) * tile_w
		var rd := _sc_road.instantiate()
		rd.position = Vector3(tx, 0.01, 0)
		rd.scale = Vector3(tile_w, 1.0, 2.55)
		_apply_cull_and_mat(rd, null, 86.0)
		body.add_child(rd)


func _add_oneway_bridge(x0: float, x1: float, top_y: float) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.position = Vector3(cx, top_y, 0.0)
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.06, 2.4)
	col.shape = box
	col.position = Vector3(0, -0.03, 0)
	body.add_child(col)

	var cnt := maxi(1, int(round(length / 2.0)))
	var tile_w := length / float(cnt)
	for i in range(cnt):
		var tx := -length * 0.5 + (float(i) + 0.5) * tile_w
		var vis := _sc_bridge.instantiate()
		vis.position = Vector3(tx, -0.22, 0)
		vis.scale = Vector3(tile_w, 0.36, 2.0)
		_apply_cull_and_mat(vis, null, 78.0)
		body.add_child(vis)


func _add_crumbling_platform(x0: float, x1: float, top_y: float) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = Vector3(cx, top_y, 0.0)
	add_child(body)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, 0.65, 2.4)
	col.shape = box
	col.position = Vector3(0, -0.325, 0)
	body.add_child(col)

	var vis := Node3D.new()
	body.add_child(vis)
	var cnt := maxi(2, int(round(length / 1.05)))
	var step := length / float(cnt)
	for i in range(cnt):
		var crate := _sc_crate.instantiate()
		var tx := -length * 0.5 + (float(i) + 0.5) * step
		crate.position = Vector3(tx, -0.35, 0)
		crate.scale = Vector3(step * 0.94, 0.72, 1.9)
		_apply_cull_and_mat(crate, null, 75.0)
		vis.add_child(crate)

	var cp_data := {"state": 0, "timer": 0.0, "col": col, "vis": vis, "cx": cx, "half_len": length * 0.5}
	_crumbling.append(cp_data)

	var sensor := Area3D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 16
	body.add_child(sensor)
	var scol := CollisionShape3D.new()
	var sbox := BoxShape3D.new()
	sbox.size = Vector3(length, 0.35, 2.2)
	scol.shape = sbox
	scol.position = Vector3(0, 0.16, 0)
	sensor.add_child(scol)
	sensor.body_entered.connect(func(b):
		if b == player and cp_data["state"] == 0:
			cp_data["state"] = 1
			cp_data["timer"] = 0.55
	)


func _add_spikes(x0: float, ground_y: float, count: int) -> void:
	var step := 1.15
	var total_w := count * step
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(x0 + total_w * 0.5, ground_y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(0.45, total_w - 0.35), 0.38, 1.4)
	col.shape = box
	col.position = Vector3(0, 0.19, 0)
	area.add_child(col)

	for i in range(count):
		var sp := _sc_spikes.instantiate()
		sp.position = Vector3((float(i) + 0.5 - float(count) * 0.5) * step, 0.0, 0.0)
		sp.scale = Vector3.ONE * 1.55
		_apply_cull_and_mat(sp, null, 72.0)
		area.add_child(sp)


func _add_overhead_spikes(x0: float, bottom_y: float, width: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(x0 + width * 0.5, bottom_y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width - 0.35, 1.5, 1.6)
	col.shape = box
	col.position = Vector3(0, 0.78, 0)
	area.add_child(col)

	var cnt := maxi(1, int(round(width / 1.8)))
	var tile_w := width / float(cnt)
	for i in range(cnt):
		var tx := -width * 0.5 + (float(i) + 0.5) * tile_w
		var vis := _sc_spike_wide.instantiate()
		vis.rotation_degrees.z = 180.0
		vis.position = Vector3(tx, 1.25, 0)
		vis.scale = Vector3(tile_w * 0.65, 1.25, 1.6)
		_apply_cull_and_mat(vis, null, 75.0)
		area.add_child(vis)


func _add_rolling_boulder(start_x: float, ground_y: float, speed: float, trigger_x: float) -> void:
	var radius := 0.76
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(start_x, ground_y + radius, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = radius * 0.80
	col.shape = cs
	area.add_child(col)

	var vis := _sc_boulder.instantiate()
	vis.scale = Vector3.ONE * 1.1
	vis.position = Vector3(0, -0.38, 0)
	_apply_cull_and_mat(vis, null, 82.0)
	area.add_child(vis)

	_animated_hazards.append({
		"kind": "boulder", "node": area, "speed": speed,
		"trigger_x": trigger_x, "active": false
	})


func _add_pendulum_saw(pivot_x: float, pivot_y: float, arm_len: float, freq: float, max_ang: float) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(pivot_x, pivot_y, 0.0)
	add_child(pivot)

	var rod := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.07
	cyl.height = arm_len
	rod.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.28, 0.38)
	mat.metallic = 0.75
	rod.material_override = mat
	rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rod.position = Vector3(0, -arm_len * 0.5, 0)
	rod.visibility_range_end = 78.0
	pivot.add_child(rod)

	var blade_area := Area3D.new()
	blade_area.collision_layer = 4
	blade_area.collision_mask = 0
	blade_area.monitoring = false
	blade_area.monitorable = true
	blade_area.set_meta("trigger_kind", "hazard")
	blade_area.position = Vector3(0, -arm_len, 0)
	pivot.add_child(blade_area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.62
	col.shape = cs
	blade_area.add_child(col)

	var vis := _sc_saw.instantiate()
	vis.scale = Vector3.ONE * 1.8
	_apply_cull_and_mat(vis, null, 78.0)
	blade_area.add_child(vis)

	_animated_hazards.append({
		"kind": "pendulum", "node": pivot, "blade": blade_area,
		"freq": freq, "max_ang": max_ang, "phase": pivot_x * 0.04
	})


func _add_crusher_piston(x: float, ground_y: float, phase: float, freq: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(x, ground_y + 3.4, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 1.25, 1.5)
	col.shape = box
	col.position = Vector3(0, 0.65, 0)
	area.add_child(col)

	var vis := _sc_spike_block.instantiate()
	vis.scale = Vector3.ONE * 1.65
	_apply_cull_and_mat(vis, null, 78.0)
	area.add_child(vis)

	_animated_hazards.append({
		"kind": "crusher", "node": area, "base_x": x,
		"top_y": ground_y + 3.4, "bot_y": ground_y + 0.06,
		"phase": phase, "freq": freq
	})


func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find_anim(c)
		if r:
			return r
	return null


func _add_drone(cx: float, cy: float, amp_x: float, freq: float, ekind: String = "bee") -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(cx, cy, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.54 if ekind == "giant_bee" else 0.45
	col.shape = cs
	area.add_child(col)

	var sc: PackedScene = _sc_bee_bot
	var sc_val := 0.85
	var yaw_val := -90.0
	if ekind == "bat" and _sc_bat:
		sc = _sc_bat
		sc_val = 0.72
		yaw_val = 90.0
	elif ekind == "cyborg" and _sc_cyborg:
		sc = _sc_cyborg
		sc_val = 0.62
		yaw_val = 90.0
	elif ekind == "giant_bee" and _sc_giant_bee:
		sc = _sc_giant_bee
		sc_val = 0.88
		yaw_val = 90.0

	var vis := sc.instantiate()
	vis.scale = Vector3.ONE * sc_val
	vis.rotation_degrees.y = yaw_val
	_apply_cull_and_mat(vis, null, 78.0)
	area.add_child(vis)
	var ap := _find_anim(vis)
	if ap:
		var played := false
		for pref: String in ["Idle", "Flying", "Fly", "Walk"]:
			if ap.has_animation(pref):
				ap.get_animation(pref).loop_mode = Animation.LOOP_LINEAR
				ap.play(pref)
				played = true
				break
		if not played:
			for aname in ap.get_animation_list():
				if "fly" in aname.to_lower() or "idle" in aname.to_lower() or "walk" in aname.to_lower():
					ap.get_animation(aname).loop_mode = Animation.LOOP_LINEAR
					ap.play(aname)
					break

	_animated_hazards.append({
		"kind": "drone", "ekind": ekind, "node": area, "vis": vis,
		"center_x": cx, "center_y": cy, "amp_x": amp_x, "freq": freq, "phase": cx * 0.05
	})


func _add_flying_cannon(start_x: float, cy: float, speed: float = 6.2, span: float = 16.0) -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(start_x, cy, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.44
	col.shape = cs
	area.add_child(col)

	var vis := (_sc_cannonball if _sc_cannonball else _sc_boulder).instantiate()
	vis.scale = Vector3.ONE * 0.72
	_apply_cull_and_mat(vis, null, 78.0)
	area.add_child(vis)

	_animated_hazards.append({
		"kind": "cannon", "node": area, "origin_x": start_x, "speed": speed, "span": span
	})


func _add_ambush_trap(x: float, ground_y: float, trap_style: String = "spikes") -> void:
	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "hazard")
	area.position = Vector3(x, ground_y - 1.55, 0.0)
	area.visible = false
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.15, 0.65, 1.4)
	col.shape = box
	col.position = Vector3(0.0, 0.32, 0.0)
	area.add_child(col)

	if trap_style == "bomb" and _sc_bomb:
		var vis := _sc_bomb.instantiate()
		vis.scale = Vector3.ONE * 1.35
		vis.position = Vector3(0.0, 0.15, 0.0)
		_apply_cull_and_mat(vis, null, 74.0)
		area.add_child(vis)
	else:
		var vis := _sc_spikes.instantiate()
		vis.scale = Vector3.ONE * 1.55
		_apply_cull_and_mat(vis, null, 74.0)
		area.add_child(vis)

	_animated_hazards.append({
		"kind": "ambush", "node": area, "x": x, "ground_y": ground_y, "state": 0
	})


func _add_bouncer(x: float, ground_y: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "boost")
	area.set_meta("ground_y", -3.0)
	area.position = Vector3(x, ground_y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.45, 0.72, 1.8)
	col.shape = box
	col.position = Vector3(0, 0.36, 0)
	area.add_child(col)

	var vis := (_sc_bouncer if _sc_bouncer else _sc_mushroom).instantiate()
	vis.scale = Vector3.ONE * (0.72 if _sc_bouncer else 0.58)
	_apply_cull_and_mat(vis, null, 78.0)
	area.add_child(vis)
	area.set_meta("boost_vis", vis)


func _add_ability_crystal(x: float, y: float, kind_s: String) -> void:
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", kind_s)
	area.set_meta("burst_col", Color(0.24, 0.92, 1.0) if kind_s == "turbo_crystal" else Color(0.95, 0.45, 1.0))
	area.position = Vector3(x, y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.62
	col.shape = cs
	area.add_child(col)

	var sc := _sc_crystal1 if kind_s == "turbo_crystal" else _sc_crystal2
	if sc:
		var vis := sc.instantiate()
		vis.scale = Vector3.ONE * 1.15
		_apply_cull_and_mat(vis, null, 74.0)
		area.add_child(vis)

	area.set_meta("base_y", y)
	area.set_meta("phase", x * 0.25)
	_spinners.append(area)


func _add_boost_pad(x: float, ground_y: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "boost")
	area.set_meta("ground_y", ground_y)
	area.position = Vector3(x, ground_y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.72, 1.8)
	col.shape = box
	col.position = Vector3(0, 0.36, 0)
	area.add_child(col)

	var halo := MeshInstance3D.new()
	var hm := TorusMesh.new()
	hm.inner_radius = 0.42; hm.outer_radius = 0.50
	halo.mesh = hm
	halo.material_override = _coin_gold_mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(0, 0.02, 0)
	halo.visibility_range_end = 74.0
	area.add_child(halo)

	var vis := _sc_mushroom.instantiate()
	vis.scale = Vector3.ONE * 0.58
	_apply_cull_and_mat(vis, null, 78.0)
	area.add_child(vis)
	area.set_meta("boost_vis", vis)


func _add_rescue_orb(x: float, y: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "rescue_orb")
	area.position = Vector3(x, y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.80
	col.shape = cs
	area.add_child(col)

	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.58
	ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.88, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.14, 0.88, 1.0)
	mat.emission_energy_multiplier = 1.6
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visibility_range_end = 78.0
	area.add_child(ring)

	area.set_meta("base_y", y)
	area.set_meta("phase", x * 0.2)
	_spinners.append(area)


func _add_rescue_star(x: float, y: float) -> void:
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "rescue_star")
	area.set_meta("burst_col", Color(1.0, 0.88, 0.18))
	area.position = Vector3(x, y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.62
	col.shape = cs
	area.add_child(col)

	var vis := _sc_star.instantiate()
	vis.scale = Vector3.ONE * 1.15
	_apply_cull_and_mat(vis, null, 74.0)
	area.add_child(vis)

	area.set_meta("base_y", y)
	area.set_meta("phase", x * 0.2)
	_spinners.append(area)


func _add_heart(x: float, y: float) -> void:
	if not should_spawn_pickup_hearts():
		return
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "heart")
	area.set_meta("burst_col", Color(1.0, 0.28, 0.40))
	area.position = Vector3(x, y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.55
	col.shape = cs
	area.add_child(col)

	var vis := _sc_heart.instantiate()
	vis.scale = Vector3.ONE * 0.90
	_apply_cull_and_mat(vis, null, 74.0)
	area.add_child(vis)

	area.set_meta("base_y", y)
	area.set_meta("phase", x * 0.2)
	_spinners.append(area)


func _add_coin(x: float, y: float, is_gem: bool = false) -> void:
	var area := Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.set_meta("trigger_kind", "gem" if is_gem else "coin")
	area.set_meta("burst_col", Color(0.18, 0.84, 1.0) if is_gem else Color(1.0, 0.82, 0.22))
	area.position = Vector3(x, y, 0.0)
	add_child(area)

	var col := CollisionShape3D.new()
	var cs := SphereShape3D.new()
	cs.radius = 0.50
	col.shape = cs
	area.add_child(col)

	if is_gem:
		var gem_mi := MeshInstance3D.new()
		gem_mi.mesh = _gem_mesh
		gem_mi.material_override = _gem_mat
		gem_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gem_mi.scale = Vector3.ONE * 1.15
		gem_mi.visibility_range_end = 74.0
		area.add_child(gem_mi)
	else:
		var vis := _sc_coin.instantiate()
		vis.scale = Vector3.ONE * 2.85
		_apply_cull_and_mat(vis, _coin_gold_mat, 74.0)
		area.add_child(vis)

	area.set_meta("base_y", y)
	area.set_meta("phase", x * 0.25)
	_spinners.append(area)


func _add_coin_line(x0: float, y: float, x1: float, count: int) -> void:
	for i in range(count):
		var t := float(i) / maxf(1.0, float(count - 1))
		_add_coin(lerpf(x0, x1, t), y, false)


func _add_gem_line(x0: float, y: float, x1: float, count: int) -> void:
	for i in range(count):
		var t := float(i) / maxf(1.0, float(count - 1))
		_add_coin(lerpf(x0, x1, t), y, true)


func _add_coin_arc(x0: float, peak_y: float, x1: float, count: int) -> void:
	for i in range(count):
		var t := float(i) / maxf(1.0, float(count - 1))
		var arc_y := maxf(0.55, peak_y - pow((t - 0.5) * 2.0, 2.0) * 0.90)
		_add_coin(lerpf(x0, x1, t), arc_y, i == count / 2)


func _build_finish_arch(x: float, ground_y: float) -> void:
	var gate := Node3D.new()
	gate.position = Vector3(x, ground_y, 0.0)
	add_child(gate)

	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.08, 0.40, 0.94)
	pillar_mat.metallic = 0.35
	pillar_mat.roughness = 0.28

	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.18, 0.84, 0.96)
	cap_mat.metallic = 0.65
	cap_mat.roughness = 0.22

	for pz in [-1.5, 1.5]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.16
		pm.bottom_radius = 0.20
		pm.height = 3.25
		post.mesh = pm
		post.material_override = pillar_mat
		post.position = Vector3(0, 1.62, pz)
		gate.add_child(post)

		var cap := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.25
		cap.mesh = sm
		cap.material_override = cap_mat
		cap.position = Vector3(0, 3.35, pz)
		gate.add_child(cap)

		var fl := _sc_flag.instantiate()
		fl.position = Vector3(2.2, 0.0, pz * 1.05)
		fl.scale = Vector3.ONE * 1.1
		_apply_cull_and_mat(fl, null, 85.0)
		gate.add_child(fl)

	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.50, 0.50, 3.6)
	beam.mesh = bm
	beam.material_override = pillar_mat
	beam.position = Vector3(0, 3.05, 0)
	gate.add_child(beam)

	var arch_sign := CityBillboard3D.new()
	arch_sign.setup(Loc.t("finish_line"), 1, 4.6, 1.45, 0.45)
	arch_sign.position = Vector3(-0.20, 4.40, 0.35)
	arch_sign.rotation_degrees.y = -6.0
	gate.add_child(arch_sign)
	_finish_sign = arch_sign

	var star_top := _sc_star.instantiate()
	star_top.position = Vector3(0, 5.45, 0.0)
	star_top.scale = Vector3.ONE * 1.35
	star_top.set_meta("base_y", 5.45)
	star_top.set_meta("phase", 0.0)
	_spinners.append(star_top)
	gate.add_child(star_top)

	_ribbon_mesh = MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.08, 0.20, 2.8)
	_ribbon_mesh.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.96, 0.24, 0.32)
	rmat.emission_enabled = true
	rmat.emission = Color(0.96, 0.24, 0.32)
	rmat.emission_energy_multiplier = 0.35
	_ribbon_mesh.material_override = rmat
	_ribbon_mesh.position = Vector3(0, 1.05, 0)
	gate.add_child(_ribbon_mesh)

	var trigger := Area3D.new()
	trigger.collision_layer = 8
	trigger.collision_mask = 0
	trigger.monitoring = false
	trigger.monitorable = true
	trigger.set_meta("trigger_kind", "finish")
	trigger.set_meta("builder_ref", self)
	gate.add_child(trigger)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 4.5, 3.2)
	col.shape = box
	col.position = Vector3(0, 2.2, 0)
	trigger.add_child(col)


func _on_finish_triggered(_a: Area3D) -> void:
	if _finish_triggered:
		return
	_finish_triggered = true
	if is_instance_valid(_ribbon_mesh):
		var tw := _ribbon_mesh.create_tween()
		tw.tween_property(_ribbon_mesh, "scale", Vector3(1.0, 0.1, 2.2), 0.25)
		tw.parallel().tween_property(_ribbon_mesh, "position:y", 2.8, 0.25)
		tw.chain().tween_callback(_ribbon_mesh.queue_free)
	_spawn_3d_confetti(Vector3(FINISH_X, GROUND_Y + 2.5, 0.0))
	player.reach_victory()


func _spawn_3d_confetti(origin: Vector3) -> void:
	var cols := [
		Color(0.18, 0.62, 1.0), Color(0.16, 0.85, 0.72),
		Color(0.98, 0.34, 0.50), Color(0.45, 0.42, 0.98)
	]
	for i in range(28):
		var c := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.16, 0.10, 0.04)
		c.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = cols[i % cols.size()]
		c.material_override = mat
		c.position = origin + Vector3(randf_range(-0.6, 0.6), randf_range(-0.4, 0.6), randf_range(-1.1, 1.1))
		_confetti_parent.add_child(c)
		var dest := c.position + Vector3(randf_range(-2.6, 2.8), randf_range(0.8, 3.2), randf_range(-1.4, 1.4))
		var tw := c.create_tween()
		tw.set_parallel(true)
		tw.tween_property(c, "position", dest, randf_range(0.7, 1.3)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "rotation_degrees", Vector3(randf_range(180, 720), randf_range(180, 720), 0), 1.3)
