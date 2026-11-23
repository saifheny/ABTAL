class_name Haneen3DCharacter
extends Node3D

var character_id: String = "haneen"
var model_root: Node3D
var skeleton: Skeleton3D
var anim_player: AnimationPlayer
var _cur_anim: String = ""
var _eye_mats: Array[Material] = []
var _blink_timer: float = 1.8
var _is_blinking: bool = false
var _gobot_open_tex: Texture2D
var _gobot_closed_tex: Texture2D
var _gdbot_eye_l: TextureRect
var _gdbot_eye_r: TextureRect
var _gdbot_eye_open: Texture2D
var _gdbot_eye_close: Texture2D
var _gdbot_vp: SubViewport
var _gdbot_vp_frames: int = 0
class SwordArmModifier extends SkeletonModifier3D:
	var owner_char: Node = null
	func _process_modification_with_delta(_delta: float) -> void:
		if owner_char and is_instance_valid(owner_char):
			owner_char._apply_arm_swing_mod()
	func _process_modification() -> void:
		if owner_char and is_instance_valid(owner_char):
			owner_char._apply_arm_swing_mod()


var _sword_att: BoneAttachment3D
var _sword_pivot: Node3D
var _sword_enabled: bool = false
var _sword_swing_tw: Tween
var _atk_anim_t: float = -1.0
var _sad_anim_t: float = -1.0
var _drown_anim_t: float = -1.0
const ATK_SWING_DUR := 0.34
var _uarm_idx: int = -1
var _uarm_l_idx: int = -1
var _farm_idx: int = -1
var _hand_idx: int = -1
var _spine_idx: int = -1
var _head_idx: int = -1
var _thigh_l_idx: int = -1
var _thigh_r_idx: int = -1
var _shin_l_idx: int = -1
var _shin_r_idx: int = -1
var _arm_mod: SwordArmModifier = null
var _mod_applied_frame: int = -1
var _sword_base_basis: Basis = Basis.IDENTITY
static var _sword_sc: PackedScene = null


func _ready() -> void:
	_build_character(character_id)


func set_character(char_id: String) -> void:
	if not (char_id in ["haneen", "seif", "youssef"]):
		char_id = "haneen"
	if character_id == char_id and is_instance_valid(model_root):
		return
	character_id = char_id
	_build_character(char_id)


func _process(delta: float) -> void:
	if _atk_anim_t >= 0.0:
		_atk_anim_t += delta
		if _atk_anim_t >= ATK_SWING_DUR:
			_atk_anim_t = -1.0
	if _sad_anim_t >= 0.0:
		_sad_anim_t += delta
		if is_instance_valid(model_root):
			model_root.position.y = lerpf(model_root.position.y, -0.22, minf(1.0, delta * 9.0))
	elif _drown_anim_t >= 0.0:
		_drown_anim_t += delta
		if is_instance_valid(model_root):
			var bob := -0.18 + sin(_drown_anim_t * 7.2) * 0.09
			model_root.position.y = lerpf(model_root.position.y, bob, minf(1.0, delta * 10.0))
	if _gdbot_vp_frames > 0 and _gdbot_vp:
		_gdbot_vp_frames -= 1
		if _gdbot_vp_frames <= 0:
			_gdbot_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		if _is_blinking:
			_is_blinking = false
			_blink_timer = randf_range(1.6, 3.8)
			_apply_blink(false)
		else:
			_is_blinking = true
			_blink_timer = 0.14
			_apply_blink(true)


func _apply_blink(closed: bool) -> void:
	if character_id == "haneen":
		for em in _eye_mats:
			if em:
				em.set("uv1_offset", Vector3(0.0, 0.5, 0.0) if closed else Vector3.ZERO)
	elif character_id == "seif":
		var tex := _gobot_closed_tex if closed else _gobot_open_tex
		for em in _eye_mats:
			if em is StandardMaterial3D and tex:
				(em as StandardMaterial3D).albedo_texture = tex
	elif character_id == "youssef":
		var tex := _gdbot_eye_close if closed else _gdbot_eye_open
		if _gdbot_eye_l and tex:
			_gdbot_eye_l.texture = tex
		if _gdbot_eye_r and tex:
			_gdbot_eye_r.texture = tex
		if _gdbot_vp:
			_gdbot_vp_frames = 2
			_gdbot_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var r := _find_skel(c)
		if r:
			return r
	return null


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _find_anim_player(c)
		if r:
			return r
	return null


func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n as MeshInstance3D
	for c in n.get_children():
		var r := _find_mesh(c)
		if r:
			return r
	return null


func _build_character(char_id: String) -> void:
	for c in get_children():
		c.queue_free()
	_eye_mats.clear()
	_cur_anim = ""
	_atk_anim_t = -1.0
	_sad_anim_t = -1.0
	_drown_anim_t = -1.0
	_gdbot_eye_l = null
	_gdbot_eye_r = null
	_gdbot_vp = null

	var glb_path := "res://assets/3d/gdquest/gdquest_sophia/model/sophia.glb"
	var sc_val := 0.90
	if char_id == "seif":
		glb_path = "res://assets/3d/gdquest/gdquest_gobot/model/gobot.glb"
		sc_val = 1.02
	elif char_id == "youssef":
		glb_path = "res://assets/3d/gdquest/gdquest_gdbot/model/gdbot.glb"
		sc_val = 0.92

	var base_sc: PackedScene = load(glb_path)
	model_root = base_sc.instantiate()
	model_root.rotation_degrees = Vector3(0, 90, 0)
	model_root.position = Vector3.ZERO
	model_root.scale = Vector3.ONE * sc_val
	add_child(model_root)

	skeleton = _find_skel(model_root)
	anim_player = _find_anim_player(model_root)
	_ensure_loops()
	_cache_arm_bones()
	if skeleton:
		_arm_mod = SwordArmModifier.new()
		_arm_mod.owner_char = self
		skeleton.add_child(_arm_mod)

	var body_mesh := _find_mesh(model_root)
	if char_id == "haneen":
		if body_mesh and body_mesh.mesh:
			for s_idx in [1, 2]:
				if s_idx < body_mesh.mesh.get_surface_count():
					var m: Material = body_mesh.get_active_material(s_idx)
					if m:
						var dup := m.duplicate()
						body_mesh.set_surface_override_material(s_idx, dup)
						_eye_mats.append(dup)
		_attach_gloves()
	elif char_id == "seif":
		_gobot_open_tex = load("res://assets/3d/gdquest/gdquest_gobot/model/textures/open_eye.png")
		_gobot_closed_tex = load("res://assets/3d/gdquest/gdquest_gobot/model/textures/closed_eyes.png")
		if body_mesh and body_mesh.mesh:
			for s_idx in [1, 2]:
				if s_idx < body_mesh.mesh.get_surface_count():
					var em := StandardMaterial3D.new()
					em.albedo_texture = _gobot_open_tex
					em.roughness = 0.5
					em.uv1_offset = Vector3(0.1, 0, 0)
					em.texture_repeat = false
					body_mesh.set_surface_override_material(s_idx, em)
					_eye_mats.append(em)
	elif char_id == "youssef":
		_setup_gdbot_materials(body_mesh)

	play_anim("idle")
	if anim_player:
		anim_player.advance(0.0)
	if _sword_enabled:
		_rebuild_sword_attachment(true)


func _cache_arm_bones() -> void:
	_uarm_idx = -1
	_uarm_l_idx = -1
	_farm_idx = -1
	_hand_idx = -1
	_spine_idx = -1
	_head_idx = -1
	_thigh_l_idx = -1
	_thigh_r_idx = -1
	_shin_l_idx = -1
	_shin_r_idx = -1
	if skeleton == null:
		return
	if character_id == "seif":
		_uarm_idx = skeleton.find_bone("UpperArm.R")
		_uarm_l_idx = skeleton.find_bone("UpperArm.L")
		_farm_idx = skeleton.find_bone("LowerArm.R")
		_hand_idx = _farm_idx
		_spine_idx = skeleton.find_bone("Body")
		_head_idx = skeleton.find_bone("Head")
		_thigh_l_idx = skeleton.find_bone("UpperLeg.L")
		_thigh_r_idx = skeleton.find_bone("UpperLeg.R")
		_shin_l_idx = skeleton.find_bone("LowerLeg.L")
		_shin_r_idx = skeleton.find_bone("LowerLeg.R")
	elif character_id == "youssef":
		_uarm_idx = skeleton.find_bone("upperarm.R")
		_uarm_l_idx = skeleton.find_bone("upperarm.L")
		_farm_idx = skeleton.find_bone("lowerarm.R")
		_hand_idx = skeleton.find_bone("hand.R")
		_spine_idx = skeleton.find_bone("torso")
		_head_idx = skeleton.find_bone("head")
		_thigh_l_idx = skeleton.find_bone("upperleg.L")
		_thigh_r_idx = skeleton.find_bone("upperleg.R")
		_shin_l_idx = skeleton.find_bone("lowerleg.L")
		_shin_r_idx = skeleton.find_bone("lowerleg.R")
	else:
		_uarm_idx = skeleton.find_bone("DEF-upper_arm.R")
		_uarm_l_idx = skeleton.find_bone("DEF-upper_arm.L")
		_farm_idx = skeleton.find_bone("DEF-forearm.R")
		_hand_idx = skeleton.find_bone("DEF-hand.R")
		_spine_idx = skeleton.find_bone("DEF-spine.002")
		_head_idx = skeleton.find_bone("DEF-spine.005")
		_thigh_l_idx = skeleton.find_bone("DEF-thigh.L")
		_thigh_r_idx = skeleton.find_bone("DEF-thigh.R")
		_shin_l_idx = skeleton.find_bone("DEF-shin.L")
		_shin_r_idx = skeleton.find_bone("DEF-shin.R")


func _apply_skel_rot(bone_idx: int, axis_model: Vector3, angle_rad: float) -> void:
	if bone_idx < 0 or absf(angle_rad) < 0.001 or skeleton == null or model_root == null:
		return
	var skel_world: Basis = skeleton.global_transform.basis.orthonormalized()
	var model_world: Basis = model_root.global_transform.basis.orthonormalized()
	var axis_skel: Vector3 = (skel_world.inverse() * (model_world * axis_model)).normalized()
	var p_idx: int = skeleton.get_bone_parent(bone_idx)
	var p_basis_skel: Basis = skeleton.get_bone_global_pose(p_idx).basis.orthonormalized() if p_idx >= 0 else Basis.IDENTITY
	var axis_parent: Vector3 = (p_basis_skel.inverse() * axis_skel).normalized()
	var cur_rot: Quaternion = skeleton.get_bone_pose_rotation(bone_idx)
	skeleton.set_bone_pose_rotation(bone_idx, (Quaternion(axis_parent, angle_rad) * cur_rot).normalized())


func play_sad_sit() -> void:
	_atk_anim_t = -1.0
	_drown_anim_t = -1.0
	_sad_anim_t = 0.0
	play_anim("idle", 0.35, 0.14)


func play_drown_struggle() -> void:
	_atk_anim_t = -1.0
	_sad_anim_t = -1.0
	_drown_anim_t = 0.0
	play_anim("fall", 1.25, 0.12)


func clear_sad_sit() -> void:
	_atk_anim_t = -1.0
	_sad_anim_t = -1.0
	_drown_anim_t = -1.0
	if is_instance_valid(model_root):
		model_root.position = Vector3.ZERO
		model_root.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	if is_instance_valid(skeleton):
		skeleton.reset_bone_poses()


func _apply_arm_swing_mod() -> void:
	if skeleton == null or model_root == null:
		return
	if _drown_anim_t >= 0.0:
		var kd := smoothstep(0.0, 0.22, _drown_anim_t)
		var ph := _drown_anim_t * 9.8
		var flail_r := 118.0 + sin(ph) * 40.0
		var flail_l := 118.0 - sin(ph) * 40.0
		_apply_skel_rot(_uarm_idx, Vector3(-1, 0, 0), deg_to_rad(flail_r * kd))
		_apply_skel_rot(_uarm_idx, Vector3(0, 0, -1), deg_to_rad((24.0 + cos(ph) * 18.0) * kd))
		_apply_skel_rot(_uarm_l_idx, Vector3(-1, 0, 0), deg_to_rad(flail_l * kd))
		_apply_skel_rot(_uarm_l_idx, Vector3(0, 0, 1), deg_to_rad((24.0 - cos(ph) * 18.0) * kd))
		_apply_skel_rot(_spine_idx, Vector3(0, 0, 1), deg_to_rad(sin(ph * 0.7) * 14.0 * kd))
		_apply_skel_rot(_head_idx, Vector3(-1, 0, 0), deg_to_rad(26.0 * kd))
		_apply_skel_rot(_head_idx, Vector3(0, 1, 0), deg_to_rad(sin(ph * 0.85) * 22.0 * kd))
		_apply_skel_rot(_thigh_l_idx, Vector3(-1, 0, 0), deg_to_rad(sin(ph * 1.2) * 34.0 * kd))
		_apply_skel_rot(_thigh_r_idx, Vector3(-1, 0, 0), deg_to_rad(-sin(ph * 1.2) * 34.0 * kd))
		_apply_skel_rot(_shin_l_idx, Vector3(-1, 0, 0), deg_to_rad(-32.0 * kd))
		_apply_skel_rot(_shin_r_idx, Vector3(-1, 0, 0), deg_to_rad(-32.0 * kd))
		return
	if _sad_anim_t >= 0.0:
		var ks := smoothstep(0.0, 0.34, _sad_anim_t)
		var sway := sin(_sad_anim_t * 3.0) * 10.0 * ks
		_apply_skel_rot(_thigh_l_idx, Vector3(-1, 0, 0), deg_to_rad(74.0 * ks))
		_apply_skel_rot(_thigh_r_idx, Vector3(-1, 0, 0), deg_to_rad(74.0 * ks))
		_apply_skel_rot(_shin_l_idx, Vector3(-1, 0, 0), deg_to_rad(-74.0 * ks))
		_apply_skel_rot(_shin_r_idx, Vector3(-1, 0, 0), deg_to_rad(-74.0 * ks))
		_apply_skel_rot(_spine_idx, Vector3(1, 0, 0), deg_to_rad(20.0 * ks))
		_apply_skel_rot(_head_idx, Vector3(1, 0, 0), deg_to_rad(30.0 * ks))
		_apply_skel_rot(_head_idx, Vector3(0, 1, 0), deg_to_rad(sway))
		_apply_skel_rot(_uarm_idx, Vector3(-1, 0, 0), deg_to_rad(18.0 * ks))
		_apply_skel_rot(_uarm_idx, Vector3(0, 0, -1), deg_to_rad(28.0 * ks))
		_apply_skel_rot(_uarm_l_idx, Vector3(-1, 0, 0), deg_to_rad(18.0 * ks))
		_apply_skel_rot(_uarm_l_idx, Vector3(0, 0, 1), deg_to_rad(28.0 * ks))
		return
	if _atk_anim_t < 0.0 or not _sword_enabled:
		if is_instance_valid(_sword_pivot):
			_sword_pivot.transform.basis = _sword_base_basis
		return
	var cur_frame := Engine.get_process_frames()
	if _mod_applied_frame == cur_frame:
		return
	_mod_applied_frame = cur_frame
	var p := clampf(_atk_anim_t / ATK_SWING_DUR, 0.0, 1.0)
	var lift_deg := 0.0
	var sweep_deg := 0.0
	var elbow_deg := 0.0
	var wrist_deg := 0.0
	if p < 0.22:
		var k := smoothstep(0.0, 0.22, p)
		lift_deg = lerpf(0.0, 82.0, k)
		sweep_deg = lerpf(0.0, -26.0, k)
		elbow_deg = lerpf(0.0, 24.0, k)
		wrist_deg = lerpf(0.0, -10.0, k)
	elif p < 0.58:
		var k := smoothstep(0.22, 0.58, p)
		lift_deg = lerpf(82.0, -14.0, k)
		sweep_deg = lerpf(-26.0, 52.0, k)
		elbow_deg = lerpf(24.0, -10.0, k)
		wrist_deg = lerpf(-10.0, 20.0, k)
	else:
		var k := smoothstep(0.58, 1.0, p)
		lift_deg = lerpf(-14.0, 0.0, k)
		sweep_deg = lerpf(52.0, 0.0, k)
		elbow_deg = lerpf(-10.0, 0.0, k)
		wrist_deg = lerpf(20.0, 0.0, k)

	# In model_root space (+Z forward, -X right shoulder, +Y up):
	# Rotating hanging arm around (-1, 0, 0) by +angle raises arm FORWARD & UP; (0, 1, 0) sweeps across body.
	_apply_skel_rot(_uarm_idx, Vector3(-1, 0, 0), deg_to_rad(lift_deg))
	_apply_skel_rot(_uarm_idx, Vector3(0, 1, 0), deg_to_rad(sweep_deg))
	if _farm_idx != _uarm_idx and _farm_idx >= 0:
		_apply_skel_rot(_farm_idx, Vector3(-1, 0, 0), deg_to_rad(elbow_deg))
	if is_instance_valid(_sword_pivot):
		_sword_pivot.transform.basis = (_sword_base_basis * Basis(Vector3(0, 0, -1), deg_to_rad(wrist_deg))).orthonormalized()


func attach_sword(enabled: bool) -> void:
	_sword_enabled = enabled
	_rebuild_sword_attachment(enabled)


func _rebuild_sword_attachment(enabled: bool) -> void:
	if is_instance_valid(_sword_att):
		_sword_att.queue_free()
		_sword_att = null
		_sword_pivot = null
	if not enabled or skeleton == null:
		return

	var bone_name := "DEF-hand.R"
	if character_id == "seif":
		bone_name = "LowerArm.R"
	elif character_id == "youssef":
		bone_name = "hand.R"
	var att_idx := skeleton.find_bone(bone_name)
	if att_idx < 0:
		return

	_sword_att = BoneAttachment3D.new()
	_sword_att.bone_name = bone_name
	skeleton.add_child(_sword_att)

	_sword_pivot = Node3D.new()
	if character_id == "seif":
		_sword_pivot.position = Vector3(0.0, 0.16, 0.02)
	elif character_id == "youssef":
		_sword_pivot.position = Vector3(0.0, 0.08, 0.01)
	else:
		_sword_pivot.position = Vector3(0.01, 0.06, 0.03)

	# Mathematically orient Sword_Golden.glb (+Y blade tip) to point forward-up-right in Hero ready guard
	skeleton.force_update_all_bone_transforms()
	var skel_world: Basis = skeleton.global_transform.basis.orthonormalized()
	var model_world: Basis = model_root.global_transform.basis.orthonormalized() if is_instance_valid(model_root) else Basis.IDENTITY
	var b_basis: Basis = skeleton.get_bone_global_pose(att_idx).basis.orthonormalized()
	var m_to_b: Basis = (b_basis.inverse() * (skel_world.inverse() * model_world).orthonormalized()).orthonormalized()
	var tip_b: Vector3 = (m_to_b * Vector3(-0.30, 0.28, 0.91).normalized()).normalized()
	var flat_ref_b: Vector3 = (m_to_b * Vector3(-0.88, 0.30, -0.36).normalized()).normalized()
	var edge_b: Vector3 = tip_b.cross(flat_ref_b).normalized()
	var face_b: Vector3 = edge_b.cross(tip_b).normalized()
	_sword_base_basis = Basis(edge_b, tip_b, face_b).orthonormalized()
	_sword_pivot.transform.basis = _sword_base_basis
	_sword_att.add_child(_sword_pivot)

	if _sword_sc == null:
		_sword_sc = load("res://assets/3d/kingdom/weapons/Sword_Golden.glb")
	if _sword_sc:
		var sw := _sword_sc.instantiate()
		sw.scale = Vector3.ONE * 0.58
		_sword_pivot.add_child(sw)


func play_sword_swing() -> void:
	if not _sword_enabled:
		return
	_atk_anim_t = 0.0
	if _sword_swing_tw and _sword_swing_tw.is_valid():
		_sword_swing_tw.kill()
	_sword_swing_tw = create_tween()
	if is_instance_valid(model_root):
		_sword_swing_tw.tween_property(model_root, "rotation_degrees:x", 12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_sword_swing_tw.tween_property(model_root, "rotation_degrees:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func set_facing_dir(dir: float, delta: float) -> void:
	if model_root == null:
		return
	var target_yaw := 90.0 if dir >= 0.0 else -90.0
	model_root.rotation_degrees.y = lerpf(model_root.rotation_degrees.y, target_yaw, minf(1.0, delta * 24.0))


func _ensure_loops() -> void:
	if anim_player == null:
		return
	for a in ["Idle", "Run", "run", "Walk", "walk", "Fall", "fall", "WallSlide", "VictorySign"]:
		if anim_player.has_animation(a):
			anim_player.get_animation(a).loop_mode = Animation.LOOP_LINEAR


func _setup_gdbot_materials(body_mesh: MeshInstance3D) -> void:
	if body_mesh == null or body_mesh.mesh == null:
		return
	_gdbot_eye_open = load("res://assets/3d/gdquest/gdquest_gdbot/model/texture/parts/eye_open.png")
	_gdbot_eye_close = load("res://assets/3d/gdquest/gdquest_gdbot/model/texture/parts/eye_close.png")
	var mouth_tex: Texture2D = load("res://assets/3d/gdquest/gdquest_gdbot/model/texture/parts/smile.png")

	_gdbot_vp = SubViewport.new()
	_gdbot_vp.disable_3d = true
	_gdbot_vp.size = Vector2i(256, 160)
	_gdbot_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_gdbot_vp_frames = 3
	model_root.add_child(_gdbot_vp)

	var bg := ColorRect.new()
	bg.size = Vector2(256, 160)
	bg.color = Color(0.05, 0.12, 0.22)
	_gdbot_vp.add_child(bg)

	_gdbot_eye_l = TextureRect.new()
	_gdbot_eye_l.texture = _gdbot_eye_open
	_gdbot_eye_l.modulate = Color(0.30, 0.92, 1.0)
	_gdbot_eye_l.position = Vector2(56, 46)
	_gdbot_eye_l.size = Vector2(44, 44)
	_gdbot_eye_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gdbot_vp.add_child(_gdbot_eye_l)

	_gdbot_eye_r = TextureRect.new()
	_gdbot_eye_r.texture = _gdbot_eye_open
	_gdbot_eye_r.modulate = Color(0.30, 0.92, 1.0)
	_gdbot_eye_r.position = Vector2(156, 46)
	_gdbot_eye_r.size = Vector2(44, 44)
	_gdbot_eye_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gdbot_vp.add_child(_gdbot_eye_r)

	var mouth := TextureRect.new()
	mouth.texture = mouth_tex
	mouth.modulate = Color(0.30, 0.92, 1.0)
	mouth.position = Vector2(104, 102)
	mouth.size = Vector2(48, 24)
	mouth.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gdbot_vp.add_child(mouth)

	var vtex := _gdbot_vp.get_texture()
	if body_mesh.mesh.get_surface_count() > 1:
		var face_mat := StandardMaterial3D.new()
		face_mat.albedo_texture = vtex
		face_mat.emission_enabled = true
		face_mat.emission_texture = vtex
		face_mat.emission_energy_multiplier = 1.4
		body_mesh.set_surface_override_material(1, face_mat)
	if body_mesh.mesh.get_surface_count() > 2:
		var heart_mat := StandardMaterial3D.new()
		heart_mat.albedo_color = Color(0.18, 0.88, 1.0)
		heart_mat.emission_enabled = true
		heart_mat.emission = Color(0.18, 0.88, 1.0)
		heart_mat.emission_energy_multiplier = 1.8
		body_mesh.set_surface_override_material(2, heart_mat)
	if body_mesh.mesh.get_surface_count() > 3:
		var glass_mat := StandardMaterial3D.new()
		glass_mat.albedo_color = Color(0.75, 0.94, 1.0, 0.22)
		glass_mat.roughness = 0.08
		glass_mat.metallic = 0.15
		glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		body_mesh.set_surface_override_material(3, glass_mat)


func _make_mat(col: Color, rough: float = 0.35, metal: float = 0.28) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = rough
	mat.metallic = metal
	return mat


func _attach_gloves() -> void:
	if skeleton == null:
		return
	var glove_navy := _make_mat(Color(0.06, 0.22, 0.56), 0.34, 0.26)
	var glove_trim := _make_mat(Color(0.20, 0.86, 0.96), 0.25, 0.48)

	for b_name in ["DEF-forearm.L.001", "DEF-forearm.R.001"]:
		var att := BoneAttachment3D.new()
		att.bone_name = b_name
		skeleton.add_child(att)

		var cuff := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.056
		cm.bottom_radius = 0.068
		cm.height = 0.125
		cuff.mesh = cm
		cuff.material_override = glove_navy
		cuff.position = Vector3(0.0, 0.02, 0.0)
		att.add_child(cuff)

		var band := MeshInstance3D.new()
		var bm := TorusMesh.new()
		bm.inner_radius = 0.052
		bm.outer_radius = 0.068
		band.mesh = bm
		band.material_override = glove_trim
		band.position = Vector3(0.0, -0.025, 0.0)
		att.add_child(band)


func play_anim(anim_name: String, speed_scale: float = 1.0, blend: float = 0.16) -> void:
	if anim_player == null:
		return
	var target := "Idle"
	if character_id == "youssef":
		match anim_name:
			"idle", "victory":
				target = "Idle"
			"run":
				target = "run"
			"walk":
				target = "walk"
			"jump", "flip":
				target = "jump"
			"fall":
				target = "fall"
			"crouch", "impact":
				target = "ground_impact"
			_:
				target = "Idle"
	elif character_id == "seif":
		match anim_name:
			"idle":
				target = "Idle"
			"victory":
				target = "VictorySign"
			"run":
				target = "Run"
			"walk":
				target = "Walk"
			"jump":
				target = "Jump"
			"flip":
				target = "Flip"
			"fall":
				target = "Fall"
			"crouch":
				target = "WallSlide"
			_:
				target = "Idle"
	else:
		match anim_name:
			"idle", "victory":
				target = "Idle"
			"run":
				target = "Run"
			"walk":
				target = "Run"
			"jump", "flip":
				target = "Jump"
			"fall":
				target = "Fall"
			"crouch":
				target = "WallSlide"
			_:
				target = "Idle"

	if not anim_player.has_animation(target):
		target = "Idle" if anim_player.has_animation("Idle") else ""
	if target == "":
		return
	if _cur_anim == target:
		anim_player.speed_scale = speed_scale
		return
	_cur_anim = target
	anim_player.play(target, blend, speed_scale)


func update_scarf(_delta: float, _forward_speed: float, _vel_y: float) -> void:
	pass
