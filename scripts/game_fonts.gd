class_name GameFonts
extends RefCounted

# Curated Arabic & display fonts (explicitly avoiding Cairo font as requested)
static var _lalezar: Font = null
static var _el_messiri: Font = null
static var _aref_ruqaa: Font = null
static var _marhey: Font = null
static var _readex_bold: Font = null
static var _readex_regular: Font = null
static var _cjk_fallbacks: Array[Font] = []


static func _get_fallbacks() -> Array[Font]:
	if _cjk_fallbacks.is_empty():
		if ResourceLoader.exists("res://assets/fonts/NotoSansSC-Regular.otf"):
			var cjk: Font = load("res://assets/fonts/NotoSansSC-Regular.otf")
			if cjk:
				_cjk_fallbacks.append(cjk)
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Noto Sans SC", "Microsoft YaHei", "PingFang SC", "Roboto", "sans-serif"])
		_cjk_fallbacks.append(sf)
	return _cjk_fallbacks


static func _wrap_with_fallback(base_font: Font, weight: int = 0) -> Font:
	var v := FontVariation.new()
	v.base_font = base_font
	if weight > 0:
		v.variation_opentype = {"wght": weight}
	v.fallbacks = _get_fallbacks()
	return v


static func lalezar() -> Font:
	if _lalezar == null:
		_lalezar = _wrap_with_fallback(load("res://assets/fonts/Lalezar-Regular.ttf"))
	return _lalezar


static func el_messiri() -> Font:
	if _el_messiri == null:
		_el_messiri = _wrap_with_fallback(load("res://assets/fonts/ElMessiri-Bold.ttf"), 700)
	return _el_messiri


static func aref_ruqaa() -> Font:
	if _aref_ruqaa == null:
		_aref_ruqaa = _wrap_with_fallback(load("res://assets/fonts/ArefRuqaa-Bold.ttf"))
	return _aref_ruqaa


static func marhey() -> Font:
	if _marhey == null:
		_marhey = _wrap_with_fallback(load("res://assets/fonts/Marhey-Bold.ttf"), 700)
	return _marhey


static func readex_bold() -> Font:
	if _readex_bold == null:
		_readex_bold = _wrap_with_fallback(load("res://assets/fonts/ReadexPro-Variable.ttf"), 700)
	return _readex_bold


static func readex_regular() -> Font:
	if _readex_regular == null:
		_readex_regular = _wrap_with_fallback(load("res://assets/fonts/ReadexPro-Variable.ttf"), 500)
	return _readex_regular


static func apply_rtl_label(lbl: Label, font: Font, size: int, color: Color = Color.WHITE) -> void:
	lbl.layout_direction = Loc.dir_layout()
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)


static func make_panel_style(
	bg: Color,
	border: Color,
	border_w: int = 3,
	radius: int = 20,
	shadow_col: Color = Color(0.02, 0.06, 0.22, 0.45),
	shadow_sz: int = 16
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = shadow_col
	sb.shadow_size = shadow_sz
	sb.shadow_offset = Vector2(0, 8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb


static var _tex_pill: Texture2D
static var _tex_pill_h: Texture2D
static var _tex_locked: Texture2D
static var _tex_circle: Texture2D
static var _tex_circle_h: Texture2D


static func _make_9slice(tex: Texture2D, ml: int = 48, mt: int = 20, mr: int = 48, mb: int = 20) -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = tex
	st.texture_margin_left = ml
	st.texture_margin_top = mt
	st.texture_margin_right = mr
	st.texture_margin_bottom = mb
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 8
	st.content_margin_bottom = 12
	return st


static func make_orange_pill_btn(txt: String, width: float = 200.0, height: float = 64.0, fsize: int = 22, secondary: bool = false) -> Button:
	if _tex_pill == null:
		_tex_pill = load("res://assets/textures/ui/btn_orange_pill.png")
		_tex_pill_h = load("res://assets/textures/ui/btn_orange_pill_hover.png")
		_tex_locked = load("res://assets/textures/ui/btn_orange_locked.png")

	var btn := Button.new()
	btn.text = txt
	btn.layout_direction = Loc.dir_layout()
	btn.custom_minimum_size = Vector2(width, height)
	btn.size = Vector2(width, height)
	btn.pivot_offset = Vector2(width * 0.5, height * 0.5)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", el_messiri())
	btn.add_theme_font_size_override("font_size", fsize)

	if secondary:
		var sb := _make_9slice(_tex_locked)
		sb.modulate_color = Color(0.24, 0.27, 0.34)
		btn.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate()
		sbh.modulate_color = Color(0.32, 0.36, 0.45)
		btn.add_theme_stylebox_override("hover", sbh)
		btn.add_theme_stylebox_override("pressed", sbh)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color(0.08, 0.10, 0.14, 0.95))
	else:
		var sbn := _make_9slice(_tex_pill)
		var sbh := _make_9slice(_tex_pill_h)
		var sbl := _make_9slice(_tex_locked)
		btn.add_theme_stylebox_override("normal", sbn)
		btn.add_theme_stylebox_override("hover", sbh)
		var sbp := sbn.duplicate()
		sbp.modulate_color = Color(0.92, 0.90, 0.88)
		btn.add_theme_stylebox_override("pressed", sbp)
		btn.add_theme_stylebox_override("disabled", sbl)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.92))
		btn.add_theme_color_override("font_disabled_color", Color(0.96, 0.97, 0.99, 0.90))
		btn.add_theme_color_override("font_outline_color", Color(0.76, 0.30, 0.04, 0.95))

	btn.add_theme_constant_override("outline_size", 5)

	btn.mouse_entered.connect(func():
		if btn.disabled:
			return
		var tw := btn.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)
	return btn


static func make_orange_circle_btn(sz: float = 64.0, icon_path: String = "res://assets/textures/ui/icon_back_white.png", icon_ratio: float = 0.54) -> Button:
	if _tex_circle == null:
		_tex_circle = load("res://assets/textures/ui/btn_orange_circle.png")
		_tex_circle_h = load("res://assets/textures/ui/btn_orange_circle_hover.png")

	var btn := Button.new()
	btn.text = ""
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.custom_minimum_size = Vector2(sz, sz)
	btn.size = Vector2(sz, sz)
	btn.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var sbn := StyleBoxTexture.new()
	sbn.texture = _tex_circle
	var sbh := StyleBoxTexture.new()
	sbh.texture = _tex_circle_h
	var sbp := StyleBoxTexture.new()
	sbp.texture = _tex_circle
	sbp.modulate_color = Color(0.88, 0.85, 0.82)
	var sbd := StyleBoxTexture.new()
	sbd.texture = _tex_circle
	sbd.modulate_color = Color(0.58, 0.62, 0.68, 0.72)
	btn.add_theme_stylebox_override("normal", sbn)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbp)
	btn.add_theme_stylebox_override("disabled", sbd)
	btn.add_theme_stylebox_override("focus", sbn)

	if icon_path != "":
		var wrap := CenterContainer.new()
		wrap.name = "IconWrap"
		wrap.layout_direction = Control.LAYOUT_DIRECTION_LTR
		wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(wrap)

		var ico := TextureRect.new()
		ico.name = "Icon"
		ico.texture = load(icon_path)
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var isz := sz * icon_ratio
		ico.custom_minimum_size = Vector2(isz, isz)
		ico.size = Vector2(isz, isz)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(ico)

	btn.mouse_entered.connect(func():
		if DisplayServer.is_touchscreen_available():
			return
		var tw := btn.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2(1.09, 1.09), 0.12).set_trans(Tween.TRANS_BACK)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12)
	)
	return btn


static func make_orange_icon_btn(width: float, height: float, icon_path: String, icon_size: float = 38.0, circular: bool = false) -> Button:
	var btn := make_orange_circle_btn(maxf(width, height), "", 0.56) if circular else make_orange_pill_btn("", width, height, 18, false)
	# Strictly keep LTR so child icon stays centered inside button even when locale is Arabic RTL!
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.custom_minimum_size = Vector2(width, height)
	btn.size = Vector2(width, height)
	btn.pivot_offset = Vector2(width * 0.5, height * 0.5)
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	if icon_path != "":
		var wrap := CenterContainer.new()
		wrap.name = "IconWrap"
		wrap.layout_direction = Control.LAYOUT_DIRECTION_LTR
		wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrap.offset_bottom = -3.0
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(wrap)

		var ico := TextureRect.new()
		ico.name = "Icon"
		ico.texture = load(icon_path)
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.custom_minimum_size = Vector2(icon_size, icon_size)
		ico.size = Vector2(icon_size, icon_size)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(ico)
	return btn


static func is_touch_ui() -> bool:
	return OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())
