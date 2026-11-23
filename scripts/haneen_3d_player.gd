class_name Haneen3DPlayer
extends CharacterBody3D

signal hp_changed(new_hp: int, max_hp: int)
signal rescue_changed(has_rescue: bool)
signal gem_collected(total_gems: int)
signal defeated(reason: String)
signal victory_reached

const MOVE_SPEED := 6.6
const BACK_SPEED := 6.6
const SLIDE_BOOST_SPEED := 6.6
const GRAVITY := 28.0
const JUMP_VELOCITY := 11.6
const DOUBLE_JUMP_VELOCITY := 10.6
const FAST_FALL_VY := -17.5
const COYOTE_TIME := 0.14
const JUMP_BUFFER_TIME := 0.14
const DOWN_BUFFER_TIME := 0.24
const SLIDE_DURATION := 0.50
const INVULN_DURATION := 1.25
const PIT_Y := -7.2

var char_vis: Haneen3DCharacter
var audio: AudioManager
var level_length: float = 310.0

var active: bool = false
var is_dead: bool = false
var is_victory: bool = false

var max_hp: int = 3
var hp: int = 3
var has_rescue_wing: bool = false
var gems: int = 0
var progress: float = 0.0

var _facing_dir: float = 1.0
var _touch_move_x: float = 0.0
var _touch_down_held: bool = false
var _jumps_left: int = 2
var _coyote_timer: float = 0.0
var _jump_buffer: float = 0.0
var _down_buffer: float = 0.0
var _slide_timer: float = 0.0
var _drop_through_timer: float = 0.0
var _boost_timer: float = 0.0
var _boost_speed: float = 8.6
var _triple_jump_timer: float = 0.0
var _spring_feather_timer: float = 0.0
var _invuln_timer: float = 0.0
var _step_timer: float = 0.0
var _was_on_floor: bool = false
var _double_jumping: bool = false
var _fall_spin: float = 0.0
var _flip_spin: float = 0.0
var _victory_t: float = 0.0
var _squash_sc: Vector3 = Vector3.ONE
var _death_reason: String = ""
var _water_surface_y: float = -1.75

var _col_stand: CollisionShape3D
var _col_slide: CollisionShape3D
var _hurt_area: Area3D
var _hurt_stand: CollisionShape3D
var _hurt_slide: CollisionShape3D
var _bridge_overlap_area: Area3D
var _shield_ring: MeshInstance3D
var _particles_parent: Node3D
var _particle_pool: ParticlePool3D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1 | 2
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 0.36
	floor_stop_on_slope = true
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_VELOCITY
	safe_margin = 0.005
	wall_min_slide_angle = deg_to_rad(12.0)

	char_vis = Haneen3DCharacter.new()
	add_child(char_vis)

	_build_colliders()
	_build_vfx()


func _build_colliders() -> void:
	_col_stand = CollisionShape3D.new()
	var sc := CapsuleShape3D.new()
	sc.radius = 0.28
	sc.height = 1.44
	_col_stand.shape = sc
	_col_stand.position = Vector3(0, 0.72, 0)
	add_child(_col_stand)

	_col_slide = CollisionShape3D.new()
	var slc := CapsuleShape3D.new()
	slc.radius = 0.28
	slc.height = 0.76
	_col_slide.shape = slc
	_col_slide.position = Vector3(0, 0.38, 0)
	_col_slide.disabled = true
	add_child(_col_slide)

	_hurt_area = Area3D.new()
	_hurt_area.collision_layer = 32
	_hurt_area.collision_mask = 4 | 8
	_hurt_area.area_entered.connect(_on_hurt_area_entered)
	add_child(_hurt_area)

	_hurt_stand = CollisionShape3D.new()
	var hs := BoxShape3D.new()
	hs.size = Vector3(0.46, 1.30, 0.60)
	_hurt_stand.shape = hs
	_hurt_stand.position = Vector3(0, 0.70, 0)
	_hurt_area.add_child(_hurt_stand)

	_hurt_slide = CollisionShape3D.new()
	var hsl := BoxShape3D.new()
	hsl.size = Vector3(0.56, 0.64, 0.60)
	_hurt_slide.shape = hsl
	_hurt_slide.position = Vector3(0, 0.34, 0)
	_hurt_slide.disabled = true
	_hurt_area.add_child(_hurt_slide)

	_bridge_overlap_area = Area3D.new()
	_bridge_overlap_area.collision_layer = 0
	_bridge_overlap_area.collision_mask = 2
	add_child(_bridge_overlap_area)
	var bcol := CollisionShape3D.new()
	var bbox := BoxShape3D.new()
	bbox.size = Vector3(0.55, 1.25, 0.80)
	bcol.shape = bbox
	bcol.position = Vector3(0, 0.76, 0)
	_bridge_overlap_area.add_child(bcol)


func _build_vfx() -> void:
	_shield_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.46
	tm.outer_radius = 0.51
	_shield_ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.90, 1.0, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.88, 1.0)
	mat.emission_energy_multiplier = 1.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_ring.material_override = mat
	_shield_ring.position = Vector3(0, 0.22, 0)
	_shield_ring.visible = false
	add_child(_shield_ring)


func set_particles_parent(p: Node3D) -> void:
	_particles_parent = p
	if _particles_parent == null:
		return
	for ch in _particles_parent.get_children():
		if ch is ParticlePool3D:
			_particle_pool = ch as ParticlePool3D
			return
	_particle_pool = ParticlePool3D.new()
	_particles_parent.add_child(_particle_pool)


func set_character(char_id: String) -> void:
	if char_vis:
		char_vis.set_character(char_id)


func reset_player(start_pos: Vector3) -> void:
	global_position = start_pos
	velocity = Vector3.ZERO
	_facing_dir = 1.0
	hp = max_hp
	has_rescue_wing = false
	gems = 0
	is_dead = false
	is_victory = false
	active = false
	_touch_move_x = 0.0
	_touch_down_held = false
	_jumps_left = 2
	_coyote_timer = 0.0
	_jump_buffer = 0.0
	_down_buffer = 0.0
	_slide_timer = 0.0
	_drop_through_timer = 0.0
	_boost_timer = 0.0
	_triple_jump_timer = 0.0
	_spring_feather_timer = 0.0
	_invuln_timer = 0.0
	_double_jumping = false
	_fall_spin = 0.0
	_flip_spin = 0.0
	_victory_t = 0.0
	_squash_sc = Vector3.ONE
	_death_reason = ""
	char_vis.position = Vector3.ZERO
	char_vis.rotation_degrees = Vector3.ZERO
	char_vis.scale = Vector3.ONE
	char_vis.set_facing_dir(1.0, 1.0)
	char_vis.visible = true
	collision_layer = 16
	collision_mask = 1 | 2
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	_hurt_area.set_deferred("monitoring", true)
	_hurt_area.monitoring = true
	_set_slide_collision(false)
	char_vis.clear_sad_sit()
	char_vis.play_anim("idle", 1.0, 0.0)
	hp_changed.emit(hp, max_hp)
	rescue_changed.emit(has_rescue_wing)
	gem_collected.emit(gems)


func _unhandled_input(event: InputEvent) -> void:
	if not active or is_dead or is_victory:
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed("jump"):
		trigger_jump_input()
	elif event is InputEventMouseButton and event.pressed and not GameFonts.is_touch_ui():
		if event.button_index == MOUSE_BUTTON_LEFT:
			trigger_jump_input()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			trigger_down_input()
	elif event.is_action_pressed("down"):
		trigger_down_input()

	if event.is_action_released("jump") or (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not GameFonts.is_touch_ui()):
		trigger_jump_release()


func set_touch_move_x(axis_x: float) -> void:
	_touch_move_x = clampf(axis_x, -1.0, 1.0)


func set_touch_down_held(held: bool) -> void:
	_touch_down_held = held
	if held:
		trigger_down_input()
	elif not Input.is_action_pressed("down") and _slide_timer > 0.0:
		_slide_timer = 0.0
		_set_slide_collision(false)


func trigger_jump_input() -> void:
	if not active or is_dead or is_victory:
		return
	_jump_buffer = JUMP_BUFFER_TIME


func trigger_jump_release() -> void:
	if velocity.y > 4.8 and _boost_timer <= 0.0:
		velocity.y *= 0.74


func trigger_down_input() -> void:
	if not active or is_dead or is_victory:
		return
	_queue_down_action()


func _vibrate_mobile(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _queue_down_action() -> void:
	_down_buffer = DOWN_BUFFER_TIME
	if is_on_floor():
		_execute_floor_down()
	else:
		velocity.y = minf(velocity.y, FAST_FALL_VY)
		if audio:
			audio.play("slide", 1.15, -12.0, 180)


func _execute_floor_down() -> void:
	if _is_standing_on_one_way():
		_drop_through_timer = 0.34
		_down_buffer = 0.0
		_slide_timer = 0.0
		_set_slide_collision(false)
		set_collision_mask_value(2, false)
		velocity.y = minf(velocity.y, -4.6)
		if audio:
			audio.play("slide", 1.1, -11.0, 150)
	else:
		_down_buffer = 0.0
		if _slide_timer <= 0.05 and audio:
			audio.play("slide", 1.0, -10.0, 150)
		_slide_timer = SLIDE_DURATION
		_set_slide_collision(true)
		_spawn_dust(global_position + Vector3(-0.25 * _facing_dir, 0.08, 0), 4, Color(0.86, 0.86, 0.84))


func _is_standing_on_one_way() -> bool:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is CollisionObject3D and collider.get_collision_layer_value(2):
			return true
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 0.25, 0),
		global_position + Vector3(0, -0.35, 0),
		2
	)
	return not space.intersect_ray(q).is_empty()


func _set_slide_collision(sliding: bool) -> void:
	_col_stand.set_deferred("disabled", sliding)
	_col_slide.set_deferred("disabled", not sliding)
	_hurt_stand.set_deferred("disabled", sliding)
	_hurt_slide.set_deferred("disabled", not sliding)


func _physics_process(delta: float) -> void:
	global_position.z = 0.0

	if is_dead:
		if _death_reason == "water":
			# Struggle frantically calling for help while slowly sinking in water
			var sink_t := char_vis._drown_anim_t if char_vis._drown_anim_t >= 0.0 else 0.0
			var target_water_y := _water_surface_y - 0.10 - minf(0.42, sink_t * 0.32) + sin(Time.get_ticks_msec() * 0.011) * 0.055
			velocity.x = lerpf(velocity.x, 0.0, delta * 5.0)
			if global_position.y > target_water_y + 0.08:
				velocity.y -= GRAVITY * 0.72 * delta
				global_position.y += velocity.y * delta
			else:
				velocity.y = 0.0
				global_position.y = lerpf(global_position.y, target_water_y, minf(1.0, delta * 9.0))
				if char_vis._drown_anim_t < 0.0:
					char_vis.play_drown_struggle()
			global_position.x += velocity.x * delta
			char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, sin(Time.get_ticks_msec() * 0.014) * 14.0, delta * 8.0)
		elif _death_reason == "mud":
			# Settle ON TOP of mud floor in sitting sad pose
			velocity.x = lerpf(velocity.x, 0.0, delta * 12.0)
			velocity.y -= GRAVITY * 0.92 * delta
			move_and_slide()
			if is_on_floor():
				velocity.y = 0.0
				if char_vis._sad_anim_t < 0.0:
					char_vis.play_sad_sit()
				char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, -6.0 * _facing_dir, delta * 10.0)
		else:
			velocity.x = lerpf(velocity.x, 0.0, delta * 3.5)
			velocity.y -= GRAVITY * 0.90 * delta
			move_and_slide()
			if is_on_floor():
				velocity.x = lerpf(velocity.x, 0.0, delta * 10.0)
				char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, -6.0 * _facing_dir, delta * 10.0)
				if char_vis._sad_anim_t < 0.0:
					char_vis.play_sad_sit()
			else:
				_fall_spin += delta * 180.0
				char_vis.rotation_degrees.z = _fall_spin
				char_vis.play_anim("fall", 1.1, 0.10)
		if global_position.y < -4.2:
			global_position.y = -4.2
			velocity.y = 0.0
		return

	if is_victory:
		_victory_t += delta
		velocity.x = lerpf(velocity.x, 0.0, delta * 4.5)
		velocity.y -= GRAVITY * delta
		move_and_slide()
		char_vis.rotation_degrees = char_vis.rotation_degrees.lerp(Vector3(0, -68, 0), delta * 6.0)
		char_vis.position.y = absf(sin(_victory_t * 6.2)) * 0.24
		char_vis.scale = Vector3(1.0 - sin(_victory_t * 12.4) * 0.06, 1.0 + sin(_victory_t * 12.4) * 0.06, 1.0)
		char_vis.play_anim("victory", 1.05, 0.15)
		return

	if not active:
		if char_vis._drown_anim_t >= 0.0 or char_vis._sad_anim_t >= 0.0:
			char_vis.clear_sad_sit()
		char_vis.play_anim("idle", 1.0, 0.15)
		var breath := sin(Time.get_ticks_msec() * 0.0032) * 0.018
		char_vis.scale = Vector3(1.0 - breath * 0.5, 1.0 + breath, 1.0)
		return

	progress = clampf(global_position.x / level_length, 0.0, 1.0)

	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	if _jump_buffer > 0.0:
		_jump_buffer -= delta
	if _down_buffer > 0.0:
		_down_buffer -= delta
	if _drop_through_timer > 0.0:
		_drop_through_timer -= delta
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		char_vis.visible = (int(_invuln_timer * 18.0) % 2 == 0)
	else:
		char_vis.visible = true

	if _boost_timer > 0.0:
		_boost_timer -= delta
	if _triple_jump_timer > 0.0:
		_triple_jump_timer -= delta
	if _spring_feather_timer > 0.0:
		_spring_feather_timer -= delta

	_shield_ring.visible = has_rescue_wing or _boost_timer > 0.0 or _triple_jump_timer > 0.0 or _spring_feather_timer > 0.0
	if _shield_ring.visible:
		_shield_ring.rotation_degrees.y += delta * 200.0
		_shield_ring.rotation_degrees.x = sin(Time.get_ticks_msec() * 0.005) * 16.0

	var touching_bridge_torso := _bridge_overlap_area.has_overlapping_bodies()
	if _drop_through_timer > 0.0 or velocity.y > 0.25 or touching_bridge_torso:
		set_collision_mask_value(2, false)
	else:
		set_collision_mask_value(2, true)

	# Crisp Controllable Platformer Horizontal Movement:
	# D / Right / Right-Drag -> Forward (+X), A / Left / Left-Drag -> Backward (-X), Idle -> Stand Still!
	var go_right := Input.is_action_pressed("move_right")
	var go_left := Input.is_action_pressed("move_left")
	var dir := clampf((1.0 if go_right else 0.0) - (1.0 if go_left else 0.0) + _touch_move_x, -1.0, 1.0)
	if dir > 0.1:
		_facing_dir = 1.0
	elif dir < -0.1:
		_facing_dir = -1.0
	char_vis.set_facing_dir(_facing_dir, delta)

	var on_floor := is_on_floor()
	var target_vx := 0.0
	if absf(dir) > 0.12:
		target_vx = (MOVE_SPEED if dir > 0.0 else BACK_SPEED) * dir
	if _slide_timer > 0.0 and on_floor and absf(dir) > 0.1:
		target_vx = _facing_dir * SLIDE_BOOST_SPEED
	if _boost_timer > 0.0:
		target_vx = _facing_dir * maxf(absf(target_vx), _boost_speed)

	var accel := (38.0 if on_floor else 28.0) if absf(dir) > 0.1 else 42.0
	velocity.x = lerpf(velocity.x, target_vx, 1.0 - exp(-accel * delta))
	if absf(dir) < 0.1 and absf(velocity.x) < 0.25 and _boost_timer <= 0.0:
		velocity.x = 0.0

	var down_held := _touch_down_held or Input.is_action_pressed("down")
	if on_floor:
		_coyote_timer = COYOTE_TIME
		_jumps_left = 3 if _triple_jump_timer > 0.0 else 2
		_double_jumping = false
		if down_held:
			if _slide_timer <= 0.0:
				_execute_floor_down()
			else:
				_slide_timer = 0.08
				_set_slide_collision(true)
		else:
			if _slide_timer > 0.0:
				_slide_timer = 0.0
				_set_slide_collision(false)
			if not _was_on_floor:
				_squash_sc = Vector3(1.18, 0.80, 1.14)
				_flip_spin = 0.0
				_spawn_dust(global_position + Vector3(0, 0.05, 0), 5, Color(0.92, 0.92, 0.90))
				if audio:
					audio.play("land", randf_range(0.95, 1.05), -13.0, 180)
	_was_on_floor = on_floor

	if _slide_timer > 0.0 and not down_held:
		_slide_timer = 0.0
		_set_slide_collision(false)

	var jump_mult := 1.15 if _spring_feather_timer > 0.0 else 1.0
	if _jump_buffer > 0.0:
		if _coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY * jump_mult
			_coyote_timer = 0.0
			_jump_buffer = 0.0
			_down_buffer = 0.0
			_touch_down_held = false
			_jumps_left = 2 if _triple_jump_timer > 0.0 else 1
			_flip_spin = 0.0
			_squash_sc = Vector3(0.84, 1.22, 0.84)
			_slide_timer = 0.0
			_set_slide_collision(false)
			set_collision_mask_value(2, false)
			_spawn_dust(global_position + Vector3(0, 0.06, 0), 5, Color(0.95, 0.96, 1.0))
			if audio:
				audio.play("jump", randf_range(0.96, 1.04), -9.0, 120)
		elif _jumps_left > 0:
			velocity.y = DOUBLE_JUMP_VELOCITY * jump_mult
			_jump_buffer = 0.0
			_down_buffer = 0.0
			_jumps_left -= 1
			_slide_timer = 0.0
			_double_jumping = true
			_flip_spin = 0.0
			_squash_sc = Vector3(0.88, 1.16, 0.88)
			_set_slide_collision(false)
			set_collision_mask_value(2, false)
			_spawn_dust(global_position + Vector3(0, 0.25, 0), 7, Color(0.28, 0.90, 1.0))
			if audio:
				audio.play("double_jump", randf_range(0.98, 1.06), -9.0, 120)

	if not on_floor:
		var float_k := 0.70 if (_boost_timer > 0.0 or _spring_feather_timer > 0.0) and velocity.y < 0.0 else 1.0
		var grav := GRAVITY * float_k
		velocity.y -= grav * delta

	move_and_slide()

	if global_position.x < -5.5:
		global_position.x = -5.5
		velocity.x = maxf(0.0, velocity.x)

	_squash_sc = _squash_sc.lerp(Vector3.ONE, minf(1.0, delta * 13.5))

	if on_floor:
		if _slide_timer > 0.0:
			char_vis.play_anim("crouch", 1.25, 0.08)
			char_vis.position.y = lerpf(char_vis.position.y, -0.02, delta * 18.0)
			char_vis.scale = char_vis.scale.lerp(Vector3(1.06, 0.64, 1.0), delta * 18.0)
			char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, -20.0 * _facing_dir, delta * 16.0)
			_step_timer += delta
			if _step_timer >= 0.10 and absf(velocity.x) > 0.5:
				_step_timer = 0.0
				_spawn_dust(global_position + Vector3(-0.30 * _facing_dir, 0.05, 0), 2, Color(0.84, 0.84, 0.80))
		else:
			char_vis.position.y = lerpf(char_vis.position.y, 0.0, delta * 18.0)
			if absf(velocity.x) > 0.35:
				var anim_spd := clampf(absf(velocity.x) / MOVE_SPEED * 1.28, 0.90, 1.75)
				var anim_id := "walk" if absf(velocity.x) < 3.0 else "run"
				char_vis.play_anim(anim_id, anim_spd, 0.10)
				var run_bob := absf(sin(Time.get_ticks_msec() * 0.019)) * 0.035
				char_vis.scale = char_vis.scale.lerp(_squash_sc * Vector3(1.0 - run_bob * 0.4, 1.0 + run_bob, 1.0), delta * 22.0)
				char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, -7.5 * (velocity.x / MOVE_SPEED), delta * 18.0)
				_step_timer += delta
				if _step_timer >= 0.19:
					_step_timer = 0.0
					_spawn_dust(global_position + Vector3(-0.20 * _facing_dir, 0.04, 0), 2, Color(0.86, 0.86, 0.82))
			else:
				char_vis.play_anim("idle", 1.0, 0.18)
				var breath := sin(Time.get_ticks_msec() * 0.0035) * 0.016
				char_vis.scale = char_vis.scale.lerp(_squash_sc * Vector3(1.0 - breath * 0.5, 1.0 + breath, 1.0), delta * 14.0)
				char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, 0.0, delta * 16.0)
	else:
		char_vis.position.y = lerpf(char_vis.position.y, 0.0, delta * 12.0)
		char_vis.scale = char_vis.scale.lerp(_squash_sc, delta * 12.0)
		if _double_jumping:
			# Crisp upright double-jump pose with gentle forward pitch — NO 360 fan flip!
			var target_pitch := clampf(-velocity.y * 1.4, -14.0, 10.0) * _facing_dir
			char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, target_pitch, delta * 10.0)
			if velocity.y > 0.2:
				char_vis.play_anim("jump", 1.22, 0.10)
			else:
				char_vis.play_anim("fall", 1.0, 0.14)
		else:
			var lean := clampf(velocity.y * 1.15, -13.0, 11.0) * _facing_dir
			char_vis.rotation_degrees.z = lerpf(char_vis.rotation_degrees.z, -lean, delta * 10.0)
			if velocity.y > 0.4:
				char_vis.play_anim("jump", 1.15, 0.12)
			else:
				char_vis.play_anim("fall", 1.0, 0.15)

	if global_position.y < PIT_Y:
		hp = 0
		hp_changed.emit(0, max_hp)
		has_rescue_wing = false
		rescue_changed.emit(false)
		trigger_defeat("fall")


func trigger_vertical_bounce(lift_vy: float = 13.4) -> void:
	if is_dead or is_victory:
		return
	_boost_timer = 0.0
	velocity.y = maxf(velocity.y, lift_vy)
	_jumps_left = max(1, _jumps_left)
	_coyote_timer = 0.0
	_slide_timer = 0.0
	_touch_down_held = false
	_set_slide_collision(false)
	_squash_sc = Vector3(0.84, 1.24, 0.84)
	_spawn_dust(global_position + Vector3(0, 0.35, 0), 7, Color(0.25, 0.92, 1.0))
	if audio:
		audio.play("boost", 1.06, -9.0, 220)


func trigger_boost(speed: float, duration: float, lift_vy: float = 5.5) -> void:
	if is_dead or is_victory:
		return
	_boost_speed = maxf(_boost_speed, speed)
	_boost_timer = maxf(_boost_timer, duration)
	if lift_vy > 0.0:
		velocity.y = maxf(velocity.y, lift_vy)
	_jumps_left = max(1, _jumps_left)
	_spawn_dust(global_position + Vector3(0, 0.5, 0), 6, Color(0.25, 0.92, 1.0))
	if audio:
		audio.play("boost", 1.0, -9.0, 220)


func grant_rescue_wing() -> void:
	if is_dead or is_victory:
		return
	has_rescue_wing = true
	rescue_changed.emit(true)
	if audio:
		audio.play("rescue", 1.1, -9.0, 250)


func grant_triple_jump_power(dur: float = 5.8) -> void:
	if is_dead or is_victory:
		return
	_triple_jump_timer = maxf(_triple_jump_timer, dur)
	_jumps_left = maxi(_jumps_left + 1, 2)
	_spawn_dust(global_position + Vector3(0, 0.7, 0), 8, Color(0.24, 0.92, 1.0), true)
	if audio:
		audio.play("gem", 1.24, -8.5, 180)


func grant_sky_feather_power(dur: float = 6.8) -> void:
	if is_dead or is_victory:
		return
	_spring_feather_timer = maxf(_spring_feather_timer, dur)
	_spawn_dust(global_position + Vector3(0, 0.7, 0), 8, Color(0.95, 0.45, 1.0), true)
	if audio:
		audio.play("rescue", 1.2, -8.5, 180)


func heal_heart() -> void:
	if is_dead or is_victory:
		return
	if hp < max_hp:
		hp += 1
		hp_changed.emit(hp, max_hp)
	if audio:
		audio.play("gem", 1.15, -9.0, 150)


func add_gem(amount: int = 1) -> void:
	if is_dead or is_victory:
		return
	gems += amount
	gem_collected.emit(gems)
	if audio:
		audio.play("coin" if amount == 1 else "gem", randf_range(0.96, 1.10), -10.0, 80)


func take_hazard_hit(lethal_big_danger: bool = false) -> void:
	if is_dead or is_victory or _invuln_timer > 0.0 or _boost_timer > 0.05:
		return

	if lethal_big_danger:
		if has_rescue_wing:
			_activate_rescue_save()
			return
		hp = 0
		hp_changed.emit(0, max_hp)
		trigger_defeat("big_danger")
		return

	hp -= 1
	hp_changed.emit(maxi(0, hp), max_hp)
	if hp <= 0:
		if has_rescue_wing:
			hp = 1
			hp_changed.emit(1, max_hp)
			_activate_rescue_save()
		else:
			trigger_defeat("hazard")
	else:
		_invuln_timer = INVULN_DURATION
		velocity.y = 6.2
		_spawn_dust(global_position + Vector3(0, 0.7, 0), 6, Color(1.0, 0.30, 0.30))
		if audio:
			audio.play("hit", 1.0, -8.0, 250)


func _activate_rescue_save() -> void:
	has_rescue_wing = false
	rescue_changed.emit(false)
	_invuln_timer = 1.65
	_boost_timer = 1.15
	_boost_speed = 8.8
	global_position.y = maxf(global_position.y, 1.8)
	velocity = Vector3(8.8, 8.6, 0.0)
	_jumps_left = 1
	_spawn_dust(global_position + Vector3(0, 0.5, 0), 8, Color(1.0, 0.86, 0.25))
	if audio:
		audio.play("rescue", 1.0, -8.0, 250)


func trigger_mud_defeat(surface_y: float) -> void:
	if is_dead or is_victory:
		return
	hp = 0
	hp_changed.emit(0, max_hp)
	has_rescue_wing = false
	rescue_changed.emit(false)
	global_position.y = maxf(global_position.y, surface_y)
	_spawn_dust(Vector3(global_position.x, surface_y + 0.08, 0.0), 12, Color(0.32, 0.20, 0.11))
	trigger_defeat("mud")


func trigger_water_defeat(surface_y: float) -> void:
	if is_dead or is_victory:
		return
	hp = 0
	hp_changed.emit(0, max_hp)
	has_rescue_wing = false
	rescue_changed.emit(false)
	_water_surface_y = surface_y
	_spawn_dust(Vector3(global_position.x, surface_y + 0.08, 0.0), 12, Color(0.32, 0.86, 1.0))
	trigger_defeat("water")


func trigger_defeat(reason: String) -> void:
	if is_dead or is_victory:
		return
	_vibrate_mobile(65)
	is_dead = true
	active = false
	_death_reason = reason
	_boost_timer = 0.0
	_triple_jump_timer = 0.0
	_spring_feather_timer = 0.0
	_shield_ring.visible = false
	char_vis.visible = true
	char_vis.scale = Vector3.ONE
	# Keep solid layer 1 collision active so character NEVER clips below roads, earth, or mud floor!
	collision_mask = 1
	_hurt_area.set_deferred("monitoring", false)
	if reason == "mud":
		velocity = Vector3.ZERO
		char_vis.play_sad_sit()
	elif reason == "water":
		velocity = Vector3(0.4 * _facing_dir, -1.0, 0.0)
		char_vis.play_drown_struggle()
	elif reason == "fall":
		velocity = Vector3(0.6 * _facing_dir, -3.0, 0.0)
		char_vis.play_anim("fall", 1.0, 0.12)
	else:
		velocity = Vector3(-1.5 * _facing_dir, 4.4, 0.0)
		char_vis.play_anim("fall", 1.0, 0.12)
	if audio:
		audio.play("lose", 1.0, -8.0, 300)
	defeated.emit(reason)


func reach_victory() -> void:
	if is_dead or is_victory:
		return
	is_victory = true
	active = false
	_boost_timer = 0.0
	_shield_ring.visible = false
	char_vis.visible = true
	char_vis.scale = Vector3.ONE
	if audio:
		audio.play("win", 1.0, -6.0, 400)
	victory_reached.emit()


func revive_at(safe_pos: Vector3) -> void:
	is_dead = false
	is_victory = false
	active = true
	hp = max_hp
	_death_reason = ""
	_boost_timer = 0.0
	_triple_jump_timer = 0.0
	_spring_feather_timer = 0.0
	_slide_timer = 0.0
	_drop_through_timer = 0.0
	_double_jumping = false
	_flip_spin = 0.0
	_fall_spin = 0.0
	_invuln_timer = 2.6
	_touch_move_x = 0.0
	_touch_down_held = false
	_jumps_left = 2
	_coyote_timer = COYOTE_TIME
	velocity = Vector3.ZERO
	global_position = safe_pos
	collision_layer = 16
	collision_mask = 1 | 2
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	_hurt_area.set_deferred("monitoring", true)
	_hurt_area.monitoring = true
	_set_slide_collision(false)
	char_vis.visible = true
	char_vis.clear_sad_sit()
	char_vis.position = Vector3.ZERO
	char_vis.rotation_degrees = Vector3.ZERO
	char_vis.scale = Vector3.ONE
	char_vis.set_facing_dir(1.0, 1.0)
	char_vis.play_anim("idle", 1.0, 0.1)
	hp_changed.emit(hp, max_hp)
	_spawn_dust(safe_pos + Vector3(0, 0.85, 0), 14, Color(1.0, 0.86, 0.25))
	if audio:
		audio.play("rescue", 1.05, -7.0, 120)


func _on_hurt_area_entered(area: Area3D) -> void:
	if not is_instance_valid(area):
		return
	var kind := str(area.get_meta("trigger_kind", ""))
	if kind == "":
		return
	if kind in ["coin", "gem", "heart", "rescue_star", "turbo_crystal", "sky_feather"]:
		if bool(area.get_meta("collected", false)):
			return
		area.set_meta("collected", true)
		var col: Color = area.get_meta("burst_col", Color(1.0, 0.82, 0.22))
		_spawn_dust(area.position, 5, col, true)
		if kind == "coin":
			add_gem(1)
		elif kind == "gem":
			add_gem(3)
		elif kind == "heart":
			heal_heart()
		elif kind == "rescue_star":
			grant_rescue_wing()
		elif kind == "turbo_crystal":
			grant_triple_jump_power(5.8)
		elif kind == "sky_feather":
			grant_sky_feather_power(6.8)
		area.queue_free()
	elif kind == "rescue_orb":
		trigger_boost(8.6, 0.65, 11.2)
	elif kind == "boost":
		var gy: float = float(area.get_meta("ground_y", 0.0))
		trigger_vertical_bounce(14.8 if gy < -2.0 else 13.4)
		var vis: Node3D = area.get_meta("boost_vis", null)
		if is_instance_valid(vis):
			var tw := vis.create_tween()
			tw.tween_property(vis, "scale", Vector3(0.78, 0.28, 0.78), 0.07)
			tw.tween_property(vis, "scale", Vector3(0.50, 0.78, 0.50), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(vis, "scale", Vector3.ONE * 0.58, 0.14)
	elif kind == "hazard":
		take_hazard_hit(false)
	elif kind == "mud":
		trigger_mud_defeat(float(area.get_meta("surface_y", -3.45)))
	elif kind == "water":
		trigger_water_defeat(float(area.get_meta("surface_y", -1.75)))
	elif kind == "finish":
		var b_ref = area.get_meta("builder_ref", null)
		if is_instance_valid(b_ref) and b_ref.has_method("_on_finish_triggered"):
			b_ref._on_finish_triggered(area)


func _spawn_dust(pos: Vector3, count: int, col: Color, radial_ring: bool = false) -> void:
	if is_instance_valid(_particle_pool):
		_particle_pool.spawn_burst(pos, count, col, 0.65, 2.0, radial_ring)
		return
	if _particles_parent == null:
		return
	_particle_pool = ParticlePool3D.new()
	_particles_parent.add_child(_particle_pool)
	_particle_pool.spawn_burst(pos, count, col, 0.65, 2.0, radial_ring)
