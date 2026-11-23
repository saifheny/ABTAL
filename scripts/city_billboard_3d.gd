class_name CityBillboard3D
extends Node3D

var message: String = "أبطال"
var style_idx: int = 0
var board_width: float = 8.4
var board_height: float = 3.3
var leg_height: float = 5.2
var _lbl: Label
var _vp: SubViewport
var _pending_frames: int = 0

static var _shared_steel_mat: StandardMaterial3D
static var _shared_trim_mat: StandardMaterial3D
static var _shared_lamp_mat: StandardMaterial3D


func setup(msg: String, st_idx: int, w: float = 8.4, h: float = 3.3, leg_h: float = 5.2) -> void:
	message = msg
	style_idx = st_idx
	board_width = w
	board_height = h
	leg_height = leg_h


func update_message(new_msg: String) -> void:
	message = new_msg
	if _lbl:
		_lbl.layout_direction = Loc.dir_layout()
		_lbl.text = new_msg
		var fsize := 72 if new_msg.length() <= 10 else (56 if new_msg.length() <= 20 else 44)
		_lbl.add_theme_font_size_override("font_size", fsize)
	_schedule_vp_refresh()


func _schedule_vp_refresh() -> void:
	if _vp:
		_pending_frames = 4
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		set_process(true)


func _process(_delta: float) -> void:
	if _pending_frames > 0:
		_pending_frames -= 1
		if _pending_frames <= 0:
			if _vp:
				_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
			set_process(false)
	else:
		set_process(false)


func _ready() -> void:
	set_process(false)
	_build_3d_billboard()
	_schedule_vp_refresh()


func _build_3d_billboard() -> void:
	if _shared_steel_mat == null:
		_shared_steel_mat = StandardMaterial3D.new()
		_shared_steel_mat.albedo_color = Color(0.14, 0.17, 0.24)
		_shared_steel_mat.metallic = 0.65
		_shared_steel_mat.roughness = 0.40
		_shared_trim_mat = StandardMaterial3D.new()
		_shared_trim_mat.albedo_color = Color(0.32, 0.38, 0.48)
		_shared_trim_mat.metallic = 0.72
		_shared_trim_mat.roughness = 0.32
		_shared_lamp_mat = StandardMaterial3D.new()
		_shared_lamp_mat.albedo_color = Color(1.0, 0.96, 0.82)
		_shared_lamp_mat.emission_enabled = true
		_shared_lamp_mat.emission = Color(1.0, 0.96, 0.86)
		_shared_lamp_mat.emission_energy_multiplier = 0.90

	var hw := board_width * 0.5
	var hh := board_height * 0.5

	for sx in [-hw * 0.58, hw * 0.58]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.32, leg_height, 0.32)
		post.mesh = pm
		post.material_override = _shared_steel_mat
		post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		post.position = Vector3(sx, -hh - leg_height * 0.5 + 0.1, -0.18)
		add_child(post)

	var hbar := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(board_width * 0.68, 0.20, 0.22)
	hbar.mesh = hm
	hbar.material_override = _shared_trim_mat
	hbar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hbar.position = Vector3(0.0, -hh - leg_height * 0.35, -0.18)
	add_child(hbar)

	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(board_width + 0.50, board_height + 0.50, 0.38)
	frame.mesh = fm
	frame.material_override = _shared_steel_mat
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	frame.position = Vector3(0, 0, -0.20)
	add_child(frame)

	for lx in [-hw * 0.55, hw * 0.55]:
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.10, 0.10, 0.85)
		arm.mesh = am
		arm.material_override = _shared_trim_mat
		arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arm.position = Vector3(lx, hh + 0.32, 0.22)
		add_child(arm)

		var bulb := MeshInstance3D.new()
		var bm := SphereMesh.new()
		bm.radius = 0.11
		bm.radial_segments = 8
		bm.rings = 4
		bulb.mesh = bm
		bulb.material_override = _shared_lamp_mat
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bulb.position = Vector3(lx, hh + 0.22, 0.60)
		add_child(bulb)

	var vp_w := 560 if OS.has_feature("mobile") else 720
	var vp_h := 220 if OS.has_feature("mobile") else 280
	_vp = SubViewport.new()
	_vp.disable_3d = true
	_vp.size = Vector2i(vp_w, vp_h)
	_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.transparent_bg = false
	add_child(_vp)
	var vp := _vp

	var bg_col := Color(0.05, 0.13, 0.34)
	var accent_col := Color(0.96, 0.76, 0.22)
	var text_col := Color.WHITE

	match style_idx % 3:
		0:
			bg_col = Color(0.06, 0.18, 0.44)
			accent_col = Color(0.24, 0.88, 0.98)
		1:
			bg_col = Color(0.12, 0.22, 0.48)
			accent_col = Color(1.0, 0.56, 0.14)
		_:
			bg_col = Color(0.07, 0.24, 0.30)
			accent_col = Color(0.24, 0.92, 0.78)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = bg_col
	vp.add_child(bg)

	var stripe := ColorRect.new()
	stripe.anchor_left = 0.0; stripe.anchor_right = 1.0
	stripe.anchor_top = 1.0; stripe.anchor_bottom = 1.0
	stripe.offset_top = -18.0
	stripe.color = accent_col
	vp.add_child(stripe)

	var side_bar := ColorRect.new()
	side_bar.anchor_left = 0.0; side_bar.anchor_right = 0.0
	side_bar.anchor_top = 0.0; side_bar.anchor_bottom = 1.0
	side_bar.offset_right = 16.0
	side_bar.color = accent_col
	vp.add_child(side_bar)

	var chosen_font: Font = GameFonts.el_messiri() if (style_idx % 2 == 0) else GameFonts.lalezar()

	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 28)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 24)
	vp.add_child(pad)

	_lbl = Label.new()
	var lbl := _lbl
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fsize := 72 if message.length() <= 10 else (56 if message.length() <= 20 else 44)
	GameFonts.apply_rtl_label(lbl, chosen_font, fsize, text_col)
	lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.14, 0.92))
	lbl.add_theme_constant_override("outline_size", 7)
	pad.add_child(lbl)

	var screen := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(board_width, board_height)
	screen.mesh = qm
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	screen.position = Vector3(0, 0, 0.02)

	var mat := StandardMaterial3D.new()
	var vp_tex := vp.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = vp_tex
	screen.material_override = mat
	add_child(screen)
