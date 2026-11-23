class_name TitleScreen
extends Control

signal start_requested

var _bg_rect: TextureRect
var _center_wrap: Control
var _sticker_btn: TextureButton
var _shine_mat: ShaderMaterial
var _time: float = 0.0
var _hovered: bool = false
var _starting: bool = false
var _pixel_tex: Texture2D
var _audio: AudioManager


func setup(audio_mgr: AudioManager) -> void:
	_audio = audio_mgr


func _ready() -> void:
	var vp_sz := get_viewport_rect().size
	if vp_sz == Vector2.ZERO:
		vp_sz = Vector2(1280, 720)
	position = Vector2.ZERO
	size = vp_sz
	mouse_filter = Control.MOUSE_FILTER_STOP
	_pixel_tex = load("res://assets/textures/abtal_pixel_sticker.png")
	_build_ui()


func _build_ui() -> void:
	# Crisp tiled bubble-sticker wallpaper (أبطال)
	_bg_rect = TextureRect.new()
	_bg_rect.texture = load("res://assets/textures/abtal_collage_bg.png")
	_bg_rect.position = Vector2.ZERO
	_bg_rect.size = size
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.pivot_offset = size * 0.5
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_center_wrap = Control.new()
	var btn_w := 760.0
	var btn_h := 315.0
	_center_wrap.size = Vector2(btn_w, btn_h)
	_center_wrap.position = (size - _center_wrap.size) * 0.5
	_center_wrap.pivot_offset = Vector2(btn_w * 0.5, btn_h * 0.5)
	add_child(_center_wrap)

	var center_tex: Texture2D = load("res://assets/textures/abtal_center_sticker.png")

	_sticker_btn = TextureButton.new()
	_sticker_btn.ignore_texture_size = true
	_sticker_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_sticker_btn.texture_normal = center_tex
	_sticker_btn.position = Vector2.ZERO
	_sticker_btn.custom_minimum_size = _center_wrap.size
	_sticker_btn.size = _center_wrap.size
	_sticker_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_shine_mat = ShaderMaterial.new()
	_shine_mat.shader = load("res://shaders/sticker_shine.gdshader")
	_shine_mat.set_shader_parameter("shine_intensity", 0.34)
	_sticker_btn.material = _shine_mat

	_sticker_btn.mouse_entered.connect(_on_hover_enter)
	_sticker_btn.mouse_exited.connect(_on_hover_exit)
	_sticker_btn.pressed.connect(_on_sticker_clicked)
	_center_wrap.add_child(_sticker_btn)


func _process(delta: float) -> void:
	_time += delta
	var vp_sz := get_viewport_rect().size
	if vp_sz != Vector2.ZERO and size != vp_sz:
		size = vp_sz
	if _bg_rect:
		_bg_rect.size = size
		var bg_sc := 1.03 + 0.012 * sin(_time * 0.65)
		_bg_rect.pivot_offset = size * 0.5
		_bg_rect.scale = Vector2(bg_sc, bg_sc)
		var mpos := get_viewport().get_mouse_position()
		var safe_sz := size.max(Vector2.ONE)
		var norm := (mpos / safe_sz) - Vector2(0.5, 0.5)
		norm.x = clampf(norm.x, -0.5, 0.5)
		norm.y = clampf(norm.y, -0.5, 0.5)
		var off: Vector2 = norm * -14.0
		_bg_rect.position = _bg_rect.position.lerp(off, delta * 5.0)

	if _center_wrap and not _starting:
		_center_wrap.position = (size - _center_wrap.size) * 0.5 + Vector2(0, sin(_time * 2.1) * 5.0)
		var target_sc := 1.065 if _hovered else (1.0 + 0.012 * sin(_time * 2.5))
		_center_wrap.scale = _center_wrap.scale.lerp(Vector2(target_sc, target_sc), delta * 12.0)

	if _shine_mat:
		var cycle := fmod(_time * 0.42, 1.9) - 0.35
		_shine_mat.set_shader_parameter("shine_pos", cycle)


func _on_hover_enter() -> void:
	_hovered = true
	if _audio:
		_audio.play("click", 1.15, -14.0)


func _on_hover_exit() -> void:
	_hovered = false


func _on_sticker_clicked() -> void:
	if _starting:
		return
	_starting = true
	if _audio:
		_audio.play("click", 1.0, -8.0)

	for i in range(10):
		var sp := TextureRect.new()
		sp.texture = _pixel_tex
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.size = Vector2(110, 44)
		sp.position = size * 0.5 - sp.size * 0.5
		sp.pivot_offset = sp.size * 0.5
		sp.rotation = randf_range(-0.5, 0.5)
		add_child(sp)
		var ang := (float(i) / 10.0) * TAU + randf_range(-0.15, 0.15)
		var dest := sp.position + Vector2(cos(ang), sin(ang)) * randf_range(340.0, 620.0)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "position", dest, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sp, "rotation", sp.rotation + randf_range(-2.0, 2.0), 0.42)
		tw.tween_property(sp, "modulate:a", 0.0, 0.42)
		tw.chain().tween_callback(sp.queue_free)

	var tw_main := create_tween()
	tw_main.set_parallel(true)
	tw_main.tween_property(_center_wrap, "scale", Vector2(1.18, 1.18), 0.14).set_trans(Tween.TRANS_BACK)
	tw_main.tween_property(self, "modulate:a", 0.0, 0.28).set_delay(0.08)
	tw_main.chain().tween_callback(func():
		visible = false
		_starting = false
		modulate.a = 1.0
		_center_wrap.scale = Vector2.ONE
		start_requested.emit()
	)
