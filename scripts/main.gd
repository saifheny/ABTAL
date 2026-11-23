extends Node3D

enum GameState {
	TITLE,
	HOME_HUB,
	CHARACTERS_PAGE,
	MAP_PAGE,
	INTRO_REVEAL,
	PLAYING,
	PAUSED,
	DYING,
	GAME_OVER,
	VICTORY,
	JOURNEY,
}

const CHAR_IDS := ["haneen", "seif", "youssef"]

var state: GameState = GameState.TITLE
var _progress: GameProgress
var _audio: AudioManager
var _backdrop: World3DBackdrop
var _level_holder: Node3D
var _level_builder: Level3DBuilder
var _player: Haneen3DPlayer
var _camera: Camera3D
var _particles_layer: Node3D

var _blur_layer: CanvasLayer
var _blur_rect: ColorRect
var _blur_mat: ShaderMaterial

# Home Hub (NO top banner, NO bottom bar container, ZERO blur — crisp HD!)
var _hub_layer: CanvasLayer
var _hub_btn_chars: Button
var _hub_btn_map: Button
var _hub_btn_play: Button
var _hub_wallet_lbl: Label
var _lang_btn: Button
var _lang_btn_flag: TextureRect
var _audio_btn: Button
var _audio_drawer: Control
var _audio_slider: HSlider
var _audio_val_lbl: Label
var _icon_volume_tex: Texture2D
var _icon_mute_tex: Texture2D

# Interactive Pop-Out Language Selector Popup
var _lang_layer: CanvasLayer
var _lang_dim: ColorRect
var _lang_card: PanelContainer
var _lang_badge_lbl: Label
var _lang_title_lbl: Label
var _lang_scroll: ScrollContainer
var _lang_rows: Array[Button] = []
var _lang_tween: Tween
var _lang_closing: bool = false
var _lang_opened_ms: int = 0

# Central Selected Character + Dedicated 3D Characters Showroom
var selected_character_id: String = "haneen"
var _chars_stage: Node3D
var _chars_models: Array[Haneen3DCharacter] = []
var _chars_ring_mats: Array[StandardMaterial3D] = []
var _chars_yaws: Array[float] = [0.0, 0.0, 0.0]
var _chars_drag_idx: int = -1
var _chars_touch_fid: int = -1
var _chars_touch_start: Vector2 = Vector2.ZERO
var _chars_touch_moved: float = 0.0
var _chars_layer: CanvasLayer
var _chars_cards: Array[Button] = []
var _chars_name_lbls: Array[Label] = []
var _chars_checks: Array[TextureRect] = []
var _chars_play_btn: Button

# Dedicated Interactive 3D Open-World Map Page (Playable Exploration + 10 Castles + Locked Gates)
var _map_stage: WorldMap3D
var _map_beacon: MeshInstance3D
var _map_hero_vis: Haneen3DCharacter
var _map_layer: CanvasLayer
var _map_pin_btns: Dictionary = {}
var _map_crown_btns: Dictionary = {}
var _map_crowns: Array[Node3D] = []
var _map_crown_pts: Array[Vector3] = []
var _map_stage_pts: Array[Vector3] = []
var _map_play_btn: Button
var _map_prev_btn: Button
var _map_next_btn: Button
var _map_joy_pad: Control
var _map_jump_btn: Button
var _map_hint_lbl: Label
var _map_wallet_lbl: Label

# In-Game HUD (Compact Pause Button + Upgraded Texture Hearts + Mobile Multi-Touch Controls)
var _hud_layer: CanvasLayer
var _hearts_box: Array[TextureRect] = []
var _stage_prev_hp: int = 3
var _tex_stage_heart_full: Texture2D
var _tex_stage_heart_empty: Texture2D
var _tex_jheart_full: Texture2D
var _tex_jheart_empty: Texture2D
var _rescue_star_poly: Polygon2D
var _coin_lbl: Label
var _pause_btn: Button
var _touch_left_col: VBoxContainer
var _touch_slide_btn: Button
var _touch_jump_btn: Button
var _touch_jump_held: bool = false
var _stage_joy_pad: Control
var _stage_joy_ring: Panel
var _stage_joy_knob: Panel
var _stage_joy_finger: int = -1
var _touch_action_btns: Array[Dictionary] = []
var _icon_pause_tex: Texture2D
var _icon_play_tex: Texture2D
var _icon_close_tex: Texture2D
var _icon_sword_tex: Texture2D
var _icon_crown_tex: Texture2D
var _icon_lock_tex: Texture2D
var _icon_check_tex: Texture2D
var _icon_coin_tex: Texture2D

# Kingdom Journey World & Dedicated Journey HUD (3 Evolved Hearts + Minecraft Hotbar & Build Tool)
var _journey_world: KingdomJourneyWorld
var _journey_hud_layer: CanvasLayer
var _j_pause_btn: Button
var _j_hearts_holder: HBoxContainer
var _j_hearts: Array[TextureRect] = []
var _j_prev_hp: int = 3
var _j_coin_lbl: Label
var _j_banner_lbl: Label
var _j_left_col: Control
var _j_sword_btn: Button
var _j_jump_btn: Button
var _j_jump_held: bool = false
var _j_dash_btn: Button
var _j_build_btn: Button
var _j_world_touch_pad: Control
var _j_hotbar: PanelContainer
var _j_slot_btns: Array[Button] = []
var _j_slot_cnt_lbls: Array[Label] = []
var _j_slot_frames: Array[StyleBoxFlat] = []
var _j_toast_lbl: Label
var _j_toast_tw: Tween
var _j_joy_pad: Control
var _j_joy_ring: Panel
var _j_joy_knob: Panel
var _j_joy_finger: int = -1
var _banked_run_coins: int = 0
var _journey_from_lvl: int = 1
var _journey_to_lvl: int = 2
var _was_in_journey_before_pause: bool = false
var _won_during_journey: bool = false
var _last_stage_fail_x: float = 1.5
var _panoramic_revive_t: float = -1.0
var _panoramic_revive_pos: Vector3 = Vector3.ZERO
var _ad_service: AdService
var _white_fog_layer: CanvasLayer
var _white_fog_rect: ColorRect

# Modals (White Cards + Crisp Large Icons & Typography)
var _modal_layer: CanvasLayer
var _modal_dim: ColorRect
var _gameover_card: PanelContainer
var _gameover_badge_lbl: Label
var _gameover_title_lbl: Label
var _gameover_sub_lbl: Label
var _gameover_retry_btn: Button
var _gameover_revive_btn: Button
var _gameover_skip_btn: Button
var _gameover_home_btn: Button
var _gameover_stats_lbl: Label
var _go_coins_lbl: Label
var _go_time_lbl: Label
var _victory_card: PanelContainer
var _victory_badge_lbl: Label
var _victory_title_lbl: Label
var _victory_again_btn: Button
var _victory_home_btn: Button
var _victory_stats_lbl: Label
var _win_lvl_lbl: Label
var _win_time_lbl: Label
var _win_coins_lbl: Label
var _win_hearts_lbl: Label
var _next_lvl_btn: Button
var _pause_card: PanelContainer
var _pause_badge_lbl: Label
var _pause_title_lbl: Label
var _pause_resume_btn: Button
var _pause_retry_btn: Button
var _pause_skip_btn: Button
var _pause_home_btn: Button
var _choice_card: PanelContainer
var _choice_title_lbl: Label
var _choice_wallet_lbl: Label
var _choice_hint_lbl: Label
var _choice_ad_btn: Button
var _choice_coins_btn: Button
var _choice_back_btn: Button
var _choice_cost: int = 100
var _choice_mode: String = "revive"
var _choice_ad_cb: Callable
var _choice_coin_cb: Callable
var _choice_cancel_cb: Callable

var _run_time: float = 0.0
var _shake_amp: float = 0.0
var _intro_tween: Tween
var _modal_tween: Tween
var _level_dirty: bool = false
var _closing_modal: bool = false

var _cam_pos_cur: Vector3 = Vector3(3.6, 2.0, 6.2)
var _cam_look_cur: Vector3 = Vector3(2.2, 0.90, -0.3)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_icon_pause_tex = load("res://assets/textures/ui/icon_pause_white.png")
	_icon_play_tex = load("res://assets/textures/ui/icon_play_white.png")
	_icon_close_tex = load("res://assets/textures/ui/icon_close_white.png")
	_icon_sword_tex = load("res://assets/textures/ui/icon_sword_white.png")
	_icon_crown_tex = load("res://assets/textures/ui/icon_crown_white.png")
	_icon_lock_tex = load("res://assets/textures/ui/icon_lock_white.png")
	_icon_check_tex = load("res://assets/textures/ui/icon_check_white.png")
	_icon_coin_tex = load("res://assets/textures/ui/icon_coin_gold.png")
	_icon_volume_tex = load("res://assets/textures/ui/icon_volume_white.png")
	_icon_mute_tex = load("res://assets/textures/ui/icon_mute_white.png")
	_tex_stage_heart_full = load("res://assets/textures/ui/heart_stage_full.png")
	_tex_stage_heart_empty = load("res://assets/textures/ui/heart_stage_empty.png")
	_tex_jheart_full = load("res://assets/textures/ui/heart_journey_full.png")
	_tex_jheart_empty = load("res://assets/textures/ui/heart_journey_empty.png")

	_progress = GameProgress.new()
	_progress.load_progress()
	selected_character_id = _progress.selected_character

	# Respect explicit CLI override --lang=xx first; otherwise follow smart OS sync + manual lock-until-OS-changes
	var has_cli_lang := false
	for arg_g in [OS.get_cmdline_user_args(), OS.get_cmdline_args()]:
		for a in arg_g:
			if str(a).begins_with("--lang="):
				has_cli_lang = true
	if has_cli_lang:
		Loc.get_lang()
	else:
		sync_language_with_device("", false)
	DisplayServer.window_set_title(Loc.t("game_title"))

	_audio = AudioManager.new()
	add_child(_audio)

	_backdrop = World3DBackdrop.new()
	_backdrop.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_backdrop)

	_level_holder = Node3D.new()
	_level_holder.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_level_holder)

	_particles_layer = Node3D.new()
	_particles_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_particles_layer)

	_player = Haneen3DPlayer.new()
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player.audio = _audio
	_player.set_particles_parent(_particles_layer)
	_player.hp_changed.connect(_on_hp_changed)
	_player.rescue_changed.connect(_on_rescue_changed)
	_player.gem_collected.connect(_on_gem_collected)
	_player.defeated.connect(_on_player_defeated)
	_player.victory_reached.connect(_on_player_victory)
	add_child(_player)

	_camera = Camera3D.new()
	_camera.fov = 45.0
	_camera.far = 280.0
	_camera.current = true
	add_child(_camera)

	_build_blur_layer()
	_build_white_fog_layer()
	_build_minimal_hud()
	_build_journey_hud()
	_build_home_hub()
	_build_language_modal()
	_build_characters_page()
	_build_map_page()
	_build_modals()

	_ad_service = AdService.new()
	add_child(_ad_service)

	get_tree().set_quit_on_go_back(false)
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_keep_on(true)
		var vp := get_viewport()
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		RenderingServer.directional_shadow_atlas_set_size(1024, false)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_player.set_character(selected_character_id)
	_backdrop.set_character_name(selected_character_id)
	_rebuild_level(_progress.selected_level)
	_audio.set_master_volume(_progress.game_volume)
	_sync_audio_ui()
	apply_language_refresh()
	_enter_home_hub()


func _on_viewport_size_changed() -> void:
	_update_characters_page_ui()
	_update_map_pins_layout()
	_update_modal_card_widths()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_android_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if OS.has_feature("mobile") and (state == GameState.PLAYING or state == GameState.JOURNEY):
			if _ad_service == null or (not _ad_service.visible and not _ad_service.is_showing_native_ad()):
				_toggle_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		sync_language_with_device("", true)


func sync_language_with_device(os_override: String = "", refresh_ui: bool = true) -> bool:
	if not is_instance_valid(_progress):
		return false
	var cur_os := Loc.get_os_lang_tag(os_override)
	var prev_os := _progress.last_os_language
	var os_changed := (prev_os != "" and cur_os != "" and cur_os != prev_os)
	if os_changed:
		_progress.selected_language = ""
		_progress.last_os_language = cur_os
		_progress.save_progress()
	elif prev_os == "" and cur_os != "":
		_progress.last_os_language = cur_os
		_progress.save_progress()

	var target_lang := _progress.selected_language if _progress.selected_language != "" else Loc.resolve_os_lang(os_override)
	if target_lang != Loc.get_lang():
		Loc.set_lang(target_lang)
		if refresh_ui:
			apply_language_refresh()
		else:
			DisplayServer.window_set_title(Loc.t("game_title"))
		return true
	return false


func _handle_android_back() -> void:
	if _lang_layer and _lang_layer.visible:
		_close_lang_modal()
		return
	if state == GameState.PLAYING or state == GameState.JOURNEY or state == GameState.PAUSED:
		_toggle_pause()
	elif state == GameState.CHARACTERS_PAGE or state == GameState.MAP_PAGE:
		_enter_home_hub()
	elif state == GameState.HOME_HUB:
		get_tree().quit()


func _rebuild_level(lvl: int) -> void:
	for c in _level_holder.get_children():
		c.queue_free()
	for p in _particles_layer.get_children():
		if p is ParticlePool3D:
			(p as ParticlePool3D).clear_all()
		else:
			p.queue_free()

	_backdrop.set_level_theme(lvl)
	_backdrop.set_character_name(selected_character_id)
	_player.set_character(selected_character_id)
	_player.level_length = Level3DBuilder.get_level_length(lvl)
	_level_builder = Level3DBuilder.new()
	_level_holder.add_child(_level_builder)
	_level_builder.build_level(_player, lvl)
	_player.reset_player(Vector3(1.5, Level3DBuilder.GROUND_Y, 0.0))
	_banked_run_coins = 0
	_run_time = 0.0

	_cam_pos_cur = Vector3(_player.global_position.x + 2.1, 1.95, 6.2)
	_cam_look_cur = Vector3(_player.global_position.x + 0.85, 0.90, -0.3)
	_camera.position = _cam_pos_cur
	_camera.look_at(_cam_look_cur)
	_level_dirty = false


func _build_blur_layer() -> void:
	_blur_layer = CanvasLayer.new()
	_blur_layer.layer = 14
	_blur_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_blur_layer)

	_blur_rect = ColorRect.new()
	_blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur_mat = ShaderMaterial.new()
	if not OS.has_feature("mobile"):
		_blur_mat.shader = load("res://shaders/gaussian_blur.gdshader")
		_blur_mat.set_shader_parameter("blur_amount", 0.0)
		_blur_mat.set_shader_parameter("tint_color", Color(0.06, 0.10, 0.20, 1.0))
		_blur_mat.set_shader_parameter("tint_alpha", 0.36)
		_blur_rect.material = _blur_mat
	else:
		# Lightweight translucent scrim on mobile instead of expensive 9-tap screen blur shader
		_blur_rect.color = Color(0.05, 0.08, 0.16, 0.50)
	_blur_rect.visible = false
	_blur_layer.add_child(_blur_rect)


func _build_white_fog_layer() -> void:
	_white_fog_layer = CanvasLayer.new()
	_white_fog_layer.layer = 16
	_white_fog_layer.visible = false
	_white_fog_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_white_fog_layer)

	_white_fog_rect = ColorRect.new()
	_white_fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_white_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white_fog_rect.color = Color(0.98, 0.99, 1.0, 0.0)
	_white_fog_layer.add_child(_white_fog_rect)


# ==============================================================================
# 1. HOME HUB (FLOATING ORANGE CARTOON BUTTONS + GLOSSY ORANGE LANGUAGE BUTTON)
# ==============================================================================

func _build_home_hub() -> void:
	_hub_layer = CanvasLayer.new()
	_hub_layer.layer = 11
	_hub_layer.visible = false
	_hub_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hub_layer)

	var root := Control.new()
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hub_layer.add_child(root)

	# Top-right Round Glossy Orange Language Button showing Selected Flag cleanly (Touch-Safe, Zero Intercept)
	_lang_btn = GameFonts.make_orange_circle_btn(72.0, "", 0.64)
	_lang_btn.focus_mode = Control.FOCUS_NONE
	_lang_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_lang_btn.pressed.connect(_open_lang_modal)
	root.add_child(_lang_btn)
	_lang_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_lang_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lang_btn.anchor_left = 1.0; _lang_btn.anchor_right = 1.0
	_lang_btn.anchor_top = 0.0; _lang_btn.anchor_bottom = 0.0
	_lang_btn.offset_left = -96.0; _lang_btn.offset_right = -24.0
	_lang_btn.offset_top = 18.0; _lang_btn.offset_bottom = 90.0

	var l_center := CenterContainer.new()
	l_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lang_btn.add_child(l_center)

	_lang_btn_flag = TextureRect.new()
	_lang_btn_flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lang_btn_flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lang_btn_flag.custom_minimum_size = Vector2(44, 44)
	_lang_btn_flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l_center.add_child(_lang_btn_flag)

	# Top-left Floating Coin Wallet on Home Hub (ZERO container box!)
	var hw_pill := PanelContainer.new()
	hw_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hw_pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(hw_pill)
	hw_pill.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hw_pill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hw_pill.anchor_left = 0.0; hw_pill.anchor_right = 0.0
	hw_pill.anchor_top = 0.0; hw_pill.anchor_bottom = 0.0
	hw_pill.offset_left = 24.0; hw_pill.offset_right = 24.0
	hw_pill.offset_top = 24.0; hw_pill.offset_bottom = 70.0
	hw_pill.grow_horizontal = Control.GROW_DIRECTION_END
	var hwhb := HBoxContainer.new()
	hwhb.add_theme_constant_override("separation", 8)
	hwhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hw_pill.add_child(hwhb)
	hwhb.add_child(_make_coin_badge(34.0))
	_hub_wallet_lbl = Label.new()
	_hub_wallet_lbl.text = "0"
	_hub_wallet_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_hub_wallet_lbl, GameFonts.readex_bold(), 24, Color.WHITE)
	_hub_wallet_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.94))
	_hub_wallet_lbl.add_theme_constant_override("outline_size", 6)
	hwhb.add_child(_hub_wallet_lbl)

	# Bottom-Left Circular Audio Button + Pop-Up In-Game Master Volume Slider Drawer
	_audio_btn = GameFonts.make_orange_circle_btn(76.0, "res://assets/textures/ui/icon_volume_white.png", 0.56)
	_audio_btn.focus_mode = Control.FOCUS_NONE
	_audio_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_audio_btn.pressed.connect(_toggle_audio_drawer)
	root.add_child(_audio_btn)
	_audio_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_audio_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_audio_btn.anchor_left = 0.0; _audio_btn.anchor_right = 0.0
	_audio_btn.anchor_top = 1.0; _audio_btn.anchor_bottom = 1.0
	_audio_btn.offset_left = 20.0; _audio_btn.offset_right = 96.0
	_audio_btn.offset_top = -96.0; _audio_btn.offset_bottom = -20.0

	# Containerless Floating Audio Slider Bar + Outlined Percentage directly above Speaker Button
	var aud_panel := PanelContainer.new()
	aud_panel.layout_direction = Control.LAYOUT_DIRECTION_LTR
	aud_panel.visible = false
	aud_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	aud_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	aud_panel.anchor_left = 0.0; aud_panel.anchor_right = 0.0
	aud_panel.anchor_top = 1.0; aud_panel.anchor_bottom = 1.0
	aud_panel.offset_left = 22.0; aud_panel.offset_right = 296.0
	aud_panel.offset_top = -158.0; aud_panel.offset_bottom = -110.0
	var ap_sb := StyleBoxEmpty.new()
	aud_panel.add_theme_stylebox_override("panel", ap_sb)
	root.add_child(aud_panel)
	_audio_drawer = aud_panel

	var aud_hb := HBoxContainer.new()
	aud_hb.layout_direction = Control.LAYOUT_DIRECTION_LTR
	aud_hb.add_theme_constant_override("separation", 10)
	aud_panel.add_child(aud_hb)

	_audio_slider = HSlider.new()
	_audio_slider.min_value = 0.0
	_audio_slider.max_value = 1.0
	_audio_slider.step = 0.01
	_audio_slider.value = 1.0
	_audio_slider.focus_mode = Control.FOCUS_NONE
	_audio_slider.custom_minimum_size = Vector2(204, 42)
	_audio_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_audio_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sl_bg := StyleBoxFlat.new()
	sl_bg.bg_color = Color(0.08, 0.12, 0.22, 0.72)
	sl_bg.border_color = Color(1.0, 1.0, 1.0, 0.45)
	sl_bg.set_border_width_all(2)
	sl_bg.set_corner_radius_all(8)
	sl_bg.content_margin_top = 8; sl_bg.content_margin_bottom = 8
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = Color(1.0, 0.56, 0.10, 1.0)
	sl_fill.set_corner_radius_all(8)
	sl_fill.content_margin_top = 8; sl_fill.content_margin_bottom = 8
	_audio_slider.add_theme_stylebox_override("slider", sl_bg)
	_audio_slider.add_theme_stylebox_override("grabber_area", sl_fill)
	_audio_slider.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
	_audio_slider.value_changed.connect(_on_audio_slider_changed)
	aud_hb.add_child(_audio_slider)

	_audio_val_lbl = Label.new()
	_audio_val_lbl.text = "100%"
	_audio_val_lbl.custom_minimum_size = Vector2(54, 0)
	_audio_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_audio_val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameFonts.apply_rtl_label(_audio_val_lbl, GameFonts.readex_bold(), 18, Color.WHITE)
	_audio_val_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.96))
	_audio_val_lbl.add_theme_constant_override("outline_size", 6)
	aud_hb.add_child(_audio_val_lbl)

	# Three PURELY FLOATING Glossy Orange Cartoon Sticker Buttons near bottom (NO background bar!)
	var btn_row := HBoxContainer.new()
	btn_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn_row.anchor_left = 0.5
	btn_row.anchor_right = 0.5
	btn_row.anchor_top = 1.0
	btn_row.anchor_bottom = 1.0
	btn_row.offset_left = -418.0
	btn_row.offset_right = 418.0
	btn_row.offset_top = -106.0
	btn_row.offset_bottom = -24.0
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(btn_row)

	_hub_btn_chars = GameFonts.make_orange_pill_btn(Loc.t("btn_chars"), 265.0, 82.0, 26)
	_hub_btn_chars.pressed.connect(_enter_characters_page)
	btn_row.add_child(_hub_btn_chars)

	_hub_btn_map = GameFonts.make_orange_pill_btn(Loc.t("btn_map"), 265.0, 82.0, 26)
	_hub_btn_map.pressed.connect(_enter_map_page)
	btn_row.add_child(_hub_btn_map)

	_hub_btn_play = GameFonts.make_orange_pill_btn(Loc.t("btn_play"), 265.0, 82.0, 26)
	_hub_btn_play.pressed.connect(_start_run_from_hub)
	btn_row.add_child(_hub_btn_play)


func _toggle_audio_drawer() -> void:
	if not is_instance_valid(_audio_drawer):
		return
	var next_vis := not _audio_drawer.visible
	_audio_drawer.visible = next_vis
	if is_instance_valid(_audio) and _audio.master_volume > 0.005:
		_audio.play("click", 1.08, -10.0)
	_sync_audio_ui()


func _on_audio_slider_changed(val: float) -> void:
	var v := clampf(val, 0.0, 1.0)
	if is_instance_valid(_audio):
		_audio.set_master_volume(v)
	if is_instance_valid(_progress):
		_progress.game_volume = v
		_progress.save_progress()
	_sync_audio_ui()


func _sync_audio_ui() -> void:
	if _icon_volume_tex == null:
		_icon_volume_tex = load("res://assets/textures/ui/icon_volume_white.png")
	if _icon_mute_tex == null:
		_icon_mute_tex = load("res://assets/textures/ui/icon_mute_white.png")
	var v := 1.0
	if is_instance_valid(_progress):
		v = clampf(_progress.game_volume, 0.0, 1.0)
	elif is_instance_valid(_audio):
		v = clampf(_audio.master_volume, 0.0, 1.0)
	if is_instance_valid(_audio_slider):
		_audio_slider.set_value_no_signal(v)
	if is_instance_valid(_audio_val_lbl):
		_audio_val_lbl.text = "%d%%" % roundi(v * 100.0)
	if is_instance_valid(_audio_btn):
		var ico := _audio_btn.find_child("Icon", true, false) as TextureRect
		if ico:
			ico.texture = _icon_mute_tex if v <= 0.005 else _icon_volume_tex


# ==============================================================================
# 1B. INTERACTIVE LANGUAGE PICKER MODAL (CALM STATES + CLEAN ANDROID TOUCH SCROLL)
# ==============================================================================

func _build_language_modal() -> void:
	_lang_layer = CanvasLayer.new()
	_lang_layer.layer = 22
	_lang_layer.visible = false
	_lang_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_lang_layer)

	_lang_dim = ColorRect.new()
	_lang_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lang_dim.color = Color(0.05, 0.08, 0.16, 0.50)
	_lang_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_lang_dim.gui_input.connect(func(ev: InputEvent):
		if Time.get_ticks_msec() - _lang_opened_ms < 220:
			return
		if ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed:
			_lang_dim.accept_event()
			_close_lang_modal()
		elif ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_lang_dim.accept_event()
			_close_lang_modal()
	)
	_lang_layer.add_child(_lang_dim)

	var lang_center := CenterContainer.new()
	lang_center.layout_direction = Control.LAYOUT_DIRECTION_LTR
	lang_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lang_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lang_layer.add_child(lang_center)

	_lang_card = PanelContainer.new()
	_lang_card.custom_minimum_size = Vector2(490, 475)
	_lang_card.pivot_offset = Vector2(245, 237)
	var lang_empty := StyleBoxEmpty.new()
	lang_empty.content_margin_left = 14; lang_empty.content_margin_right = 14
	lang_empty.content_margin_top = 10; lang_empty.content_margin_bottom = 12
	_lang_card.add_theme_stylebox_override("panel", lang_empty)
	_lang_card.mouse_filter = Control.MOUSE_FILTER_STOP
	lang_center.add_child(_lang_card)

	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 12)
	lv.mouse_filter = Control.MOUSE_FILTER_PASS
	_lang_card.add_child(lv)

	var hdr := HBoxContainer.new()
	hdr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hdr.mouse_filter = Control.MOUSE_FILTER_PASS
	lv.add_child(hdr)

	var close_btn := GameFonts.make_orange_circle_btn(62.0, "res://assets/textures/ui/icon_close_white.png")
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	close_btn.pressed.connect(_close_lang_modal)
	hdr.add_child(close_btn)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(sp)

	var badge := _make_badge_pill(Loc.t("lang_badge"), Color.TRANSPARENT, Color(1.0, 0.90, 0.56))
	_lang_badge_lbl = badge[1]
	hdr.add_child(badge[0])

	_lang_title_lbl = Label.new()
	_lang_title_lbl.text = Loc.t("lang_title")
	_lang_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameFonts.apply_rtl_label(_lang_title_lbl, GameFonts.lalezar(), 42, Color.WHITE)
	_style_cardless_label(_lang_title_lbl, 7)
	lv.add_child(_lang_title_lbl)

	_lang_scroll = ScrollContainer.new()
	_lang_scroll.custom_minimum_size = Vector2(406, 315)
	_lang_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lang_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_lang_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_lang_scroll.follow_focus = false
	_lang_scroll.scroll_deadzone = 12
	_lang_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	lv.add_child(_lang_scroll)

	var list_pad := MarginContainer.new()
	list_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_pad.mouse_filter = Control.MOUSE_FILTER_PASS
	list_pad.add_theme_constant_override("margin_top", 8)
	list_pad.add_theme_constant_override("margin_bottom", 14)
	list_pad.add_theme_constant_override("margin_left", 8)
	list_pad.add_theme_constant_override("margin_right", 10)
	_lang_scroll.add_child(list_pad)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 10)
	list_pad.add_child(vbox)

	for i in range(Loc.LANG_MENU.size()):
		var item: Dictionary = Loc.LANG_MENU[i]
		var code: String = item["code"]
		var row_btn := Button.new()
		row_btn.text = ""
		row_btn.custom_minimum_size = Vector2(360, 62)
		row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_btn.focus_mode = Control.FOCUS_NONE
		row_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		row_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		row_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row_btn.set_meta("lang_code", code)
		row_btn.set_meta("native_name", item["native"])

		var hbox := HBoxContainer.new()
		hbox.layout_direction = Control.LAYOUT_DIRECTION_LTR
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.add_theme_constant_override("separation", 12)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_btn.add_child(hbox)

		var pad_l := Control.new()
		pad_l.custom_minimum_size = Vector2(8, 0)
		pad_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(pad_l)

		var flag_tr := TextureRect.new()
		flag_tr.texture = load(item["flag"])
		flag_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag_tr.custom_minimum_size = Vector2(40, 40)
		flag_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(flag_tr)

		var name_lbl := Label.new()
		name_lbl.name = "NameLbl"
		name_lbl.text = item["native"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameFonts.apply_rtl_label(name_lbl, GameFonts.el_messiri(), 22, Color(0.12, 0.15, 0.22))
		hbox.add_child(name_lbl)

		var tag_lbl := Label.new()
		tag_lbl.name = "TagLbl"
		tag_lbl.text = item["tag"]
		tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameFonts.apply_rtl_label(tag_lbl, GameFonts.readex_bold(), 14, Color(0.45, 0.50, 0.58))
		hbox.add_child(tag_lbl)

		var chk_ico := TextureRect.new()
		chk_ico.name = "CheckIco"
		chk_ico.texture = _icon_check_tex
		chk_ico.modulate = Color(0.14, 0.48, 0.88)
		chk_ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chk_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chk_ico.custom_minimum_size = Vector2(22, 22)
		chk_ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chk_ico.visible = false
		chk_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(chk_ico)

		var pad_r := Control.new()
		pad_r.custom_minimum_size = Vector2(10, 0)
		pad_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(pad_r)

		row_btn.pressed.connect(func(): _select_language_code(code))
		vbox.add_child(row_btn)
		_lang_rows.append(row_btn)
	_refresh_lang_rows()


func _make_lang_row_style(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(16)
	sb.shadow_size = 0
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	return sb


func _refresh_lang_rows() -> void:
	var cur_lang := Loc.get_lang()
	for row_btn in _lang_rows:
		var code := str(row_btn.get_meta("lang_code", ""))
		var is_sel := (code == cur_lang)
		if is_sel:
			var sb_sel := _make_lang_row_style(Color(0.90, 0.95, 1.0), Color(0.18, 0.52, 0.90), 2)
			var sb_sel_h := _make_lang_row_style(Color(0.86, 0.93, 1.0), Color(0.14, 0.46, 0.84), 2)
			row_btn.add_theme_stylebox_override("normal", sb_sel)
			row_btn.add_theme_stylebox_override("hover", sb_sel_h)
			row_btn.add_theme_stylebox_override("pressed", _make_lang_row_style(Color(0.80, 0.89, 0.99), Color(0.12, 0.40, 0.78), 2))
		else:
			row_btn.add_theme_stylebox_override("normal", _make_lang_row_style(Color(0.97, 0.98, 0.995), Color(0.86, 0.89, 0.94), 1))
			row_btn.add_theme_stylebox_override("hover", _make_lang_row_style(Color(0.93, 0.95, 0.99), Color(0.68, 0.76, 0.88), 2))
			row_btn.add_theme_stylebox_override("pressed", _make_lang_row_style(Color(0.87, 0.91, 0.97), Color(0.32, 0.56, 0.88), 2))
		row_btn.add_theme_stylebox_override("disabled", _make_lang_row_style(Color(0.92, 0.93, 0.95, 0.65), Color(0.84, 0.86, 0.90, 0.65), 1))
		row_btn.add_theme_stylebox_override("focus", row_btn.get_theme_stylebox("normal"))

		var n_lbl := row_btn.find_child("NameLbl", true, false) as Label
		var t_lbl := row_btn.find_child("TagLbl", true, false) as Label
		var chk := row_btn.find_child("CheckIco", true, false) as TextureRect
		if n_lbl:
			n_lbl.add_theme_color_override("font_color", Color(0.08, 0.28, 0.58) if is_sel else Color(0.12, 0.15, 0.22))
		if t_lbl:
			t_lbl.add_theme_color_override("font_color", Color(0.18, 0.48, 0.84) if is_sel else Color(0.45, 0.50, 0.58))
		if chk:
			chk.visible = is_sel


func _open_lang_modal() -> void:
	if _lang_closing:
		return
	if is_instance_valid(_audio_drawer):
		_audio_drawer.visible = false
	_lang_opened_ms = Time.get_ticks_msec()
	_hide_all_modals_except("lang")
	if _audio:
		_audio.play("click", 1.08, -10.0)
	_lang_closing = false
	_lang_scroll.scroll_vertical = 0
	_refresh_lang_rows()
	_lang_layer.visible = true
	_blur_rect.visible = true
	_blur_mat.set_shader_parameter("blur_amount", 1.6)

	_lang_dim.modulate.a = 0.0
	_lang_card.pivot_offset = _lang_card.size * 0.5
	_lang_card.scale = Vector2(0.88, 0.88)
	_lang_card.modulate.a = 0.0
	if _lang_tween and _lang_tween.is_valid():
		_lang_tween.kill()
	_lang_tween = create_tween()
	_lang_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_lang_tween.set_parallel(true)
	_lang_tween.tween_property(_lang_dim, "modulate:a", 1.0, 0.16)
	_lang_tween.tween_property(_lang_card, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lang_tween.tween_property(_lang_card, "modulate:a", 1.0, 0.16)


func _close_lang_modal() -> void:
	if _lang_closing or not _lang_layer.visible:
		return
	_lang_closing = true
	if _audio:
		_audio.play("click", 0.96, -11.0)
	if _lang_tween and _lang_tween.is_valid():
		_lang_tween.kill()
	_lang_tween = create_tween()
	_lang_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_lang_tween.set_parallel(true)
	_lang_tween.tween_property(_lang_card, "scale", Vector2(0.86, 0.86), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_lang_tween.tween_property(_lang_card, "modulate:a", 0.0, 0.14)
	_lang_tween.tween_property(_lang_dim, "modulate:a", 0.0, 0.14)
	_lang_tween.chain().tween_callback(func():
		_lang_closing = false
		_lang_layer.visible = false
		_blur_rect.visible = false
		_blur_mat.set_shader_parameter("blur_amount", 0.0)
	)


func _select_language_code(code: String) -> void:
	if _audio:
		_audio.play("gem", 1.18, -8.0, 80)
	_progress.selected_language = code
	_progress.last_os_language = Loc.get_os_lang_tag()
	_progress.save_progress()
	Loc.set_lang(code)
	apply_language_refresh()
	_refresh_lang_rows()
	_close_lang_modal()


# ==============================================================================
# 2. FULL-SCREEN 3D CHARACTERS SHOWROOM ("الشخصيات" - TAP TO SELECT + SINGLE PLAY BUTTON)
# ==============================================================================

func _build_characters_page() -> void:
	_chars_stage = Node3D.new()
	_chars_stage.position = Vector3(-120.0, 0.0, 0.0)
	add_child(_chars_stage)

	# Large Seamless Courtyard Floor + Earth Base (eliminates horizon seams on all screen ratios)
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_texture = load("res://assets/textures/ground/aerial_grass_rock_Diffuse.jpg")
	grass_mat.normal_enabled = true
	grass_mat.normal_texture = load("res://assets/textures/ground/aerial_grass_rock_nor_gl.jpg")
	grass_mat.albedo_color = Color(0.84, 0.94, 0.84)
	grass_mat.roughness = 0.90
	grass_mat.uv1_scale = Vector3(16.0, 16.0, 1.0)

	var courtyard_lawn := MeshInstance3D.new()
	var cl_m := CylinderMesh.new()
	cl_m.top_radius = 28.0
	cl_m.bottom_radius = 30.0
	cl_m.height = 1.6
	courtyard_lawn.mesh = cl_m
	courtyard_lawn.material_override = grass_mat
	courtyard_lawn.position = Vector3(0.0, -1.08, -1.5)
	courtyard_lawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chars_stage.add_child(courtyard_lawn)

	var plaza_mat := StandardMaterial3D.new()
	plaza_mat.albedo_texture = load("res://assets/textures/stone/stone_tiles_02_Diffuse.jpg")
	plaza_mat.normal_enabled = true
	plaza_mat.normal_texture = load("res://assets/textures/stone/stone_tiles_02_nor_gl.jpg")
	plaza_mat.albedo_color = Color(0.95, 0.92, 0.86)
	plaza_mat.roughness = 0.72
	plaza_mat.uv1_scale = Vector3(6.0, 4.0, 1.0)

	var plaza_deck := MeshInstance3D.new()
	var pd_m := CylinderMesh.new()
	pd_m.top_radius = 6.2
	pd_m.bottom_radius = 6.6
	pd_m.height = 0.34
	plaza_deck.mesh = pd_m
	plaza_deck.material_override = plaza_mat
	plaza_deck.position = Vector3(0.0, -0.34, -0.35)
	plaza_deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chars_stage.add_child(plaza_deck)

	# Stylized Semi-Circular Castle Garden Backdrop Matching Game World
	var tree_pine: PackedScene = load("res://assets/3d/quaternius/nature_pack/PineTree_1.glb")
	var tree_oak: PackedScene = load("res://assets/3d/quaternius/nature_pack/CommonTree_1.glb")
	var rock_sc: PackedScene = load("res://assets/3d/quaternius/nature_pack/Rock_1.glb")
	var flow_sc: PackedScene = load("res://assets/3d/kenney/platformer/flowers.glb")
	var banner_sc: PackedScene = load("res://assets/3d/kingdom/gates/Banner.glb")
	var arch_sc: PackedScene = load("res://assets/3d/kingdom/gates/TallWallBricks.glb")

	var bg_wall := arch_sc.instantiate() as Node3D
	bg_wall.position = Vector3(0.0, -0.25, -4.6)
	bg_wall.scale = Vector3(3.6, 2.2, 2.2)
	_chars_stage.add_child(bg_wall)

	for bx in [-4.0, 4.0]:
		var w_side := arch_sc.instantiate() as Node3D
		w_side.position = Vector3(bx, -0.25, -4.1)
		w_side.rotation_degrees.y = -24.0 if bx > 0.0 else 24.0
		w_side.scale = Vector3(3.2, 2.0, 2.2)
		_chars_stage.add_child(w_side)

		var bnr := banner_sc.instantiate() as Node3D
		bnr.position = Vector3(bx * 0.84, 0.2, -3.55)
		bnr.scale = Vector3.ONE * 1.9
		_chars_stage.add_child(bnr)

	for tx in [-6.8, -4.8, 4.8, 6.8]:
		var tr: Node3D = (tree_pine if absf(tx) > 5.5 else tree_oak).instantiate()
		tr.position = Vector3(tx, -0.28, -3.4 - absf(tx) * 0.25)
		tr.scale = Vector3.ONE * 1.25
		_chars_stage.add_child(tr)

	for rx in [-3.4, -1.2, 1.2, 3.4]:
		var fl := flow_sc.instantiate() as Node3D
		fl.position = Vector3(rx, -0.20, -2.1)
		fl.scale = Vector3.ONE * 1.35
		_chars_stage.add_child(fl)
	for rx in [-5.6, 5.6]:
		var rk := rock_sc.instantiate() as Node3D
		rk.position = Vector3(rx, -0.25, -1.5)
		rk.scale = Vector3.ONE * 1.15
		_chars_stage.add_child(rk)

	# Soft Balanced Showroom Fill Lighting
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(0.0, 3.2, 4.4)
	fill_light.light_color = Color(1.0, 0.96, 0.90)
	fill_light.light_energy = 1.65
	fill_light.omni_range = 14.0
	fill_light.shadow_enabled = false
	_chars_stage.add_child(fill_light)

	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.95, 0.96, 0.99)
	ped_mat.roughness = 0.36

	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.98, 0.56, 0.14)
	rim_mat.metallic = 0.25
	rim_mat.roughness = 0.35

	var xs := [-2.20, 0.0, 2.20]
	for i in range(3):
		var ped := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.74
		pm.bottom_radius = 0.84
		pm.height = 0.30
		ped.mesh = pm
		ped.material_override = ped_mat
		ped.position = Vector3(xs[i], -0.15, 0.0)
		_chars_stage.add_child(ped)

		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.70
		rm.outer_radius = 0.80
		ring.mesh = rm
		var rmat := rim_mat.duplicate() as StandardMaterial3D
		_chars_ring_mats.append(rmat)
		ring.material_override = rmat
		ring.position = Vector3(xs[i], 0.01, 0.0)
		_chars_stage.add_child(ring)

		var ch := Haneen3DCharacter.new()
		ch.character_id = CHAR_IDS[i]
		ch.position = Vector3(xs[i], 0.0, 0.0)
		ch.rotation_degrees.y = -90.0
		_chars_stage.add_child(ch)
		_chars_models.append(ch)

	_chars_layer = CanvasLayer.new()
	_chars_layer.layer = 12
	_chars_layer.visible = false
	_chars_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_chars_layer)

	var root := Control.new()
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_characters_gui_input)
	_chars_layer.add_child(root)

	var back_btn := GameFonts.make_orange_circle_btn(68.0, "res://assets/textures/ui/icon_back_white.png")
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	back_btn.pressed.connect(func():
		_audio.play("click", 1.05, -10.0)
		_enter_home_hub()
	)
	root.add_child(back_btn)
	back_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.anchor_left = 0.0; back_btn.anchor_right = 0.0
	back_btn.anchor_top = 0.0; back_btn.anchor_bottom = 0.0
	back_btn.offset_left = 24.0; back_btn.offset_top = 18.0
	back_btn.offset_right = 92.0; back_btn.offset_bottom = 86.0

	# 3 Clean Clickable Character Selection Name Pills (tap hero OR name pill to select — NO individual play buttons!)
	for i in range(3):
		var cid: String = CHAR_IDS[i]
		var card := Button.new()
		card.text = ""
		card.focus_mode = Control.FOCUS_NONE
		card.custom_minimum_size = Vector2(180, 52)
		card.pivot_offset = Vector2(90, 26)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.pressed.connect(func(): _select_character(cid, true))

		var hb := HBoxContainer.new()
		hb.layout_direction = Control.LAYOUT_DIRECTION_LTR
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 8)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(hb)

		var nlbl := Label.new()
		nlbl.text = Loc.hero_name(cid)
		nlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameFonts.apply_rtl_label(nlbl, GameFonts.el_messiri(), 21, Color(0.10, 0.12, 0.18))
		hb.add_child(nlbl)

		var chk := TextureRect.new()
		chk.texture = _icon_check_tex
		chk.modulate = Color.WHITE
		chk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chk.custom_minimum_size = Vector2(20, 20)
		chk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chk.visible = false
		hb.add_child(chk)

		root.add_child(card)
		_chars_cards.append(card)
		_chars_name_lbls.append(nlbl)
		_chars_checks.append(chk)

	# ONE Single Bottom Play Button Starts Directly with Selected Character!
	_chars_play_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_play"), 320.0, 84.0, 27)
	_chars_play_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_chars_play_btn.anchor_left = 0.5; _chars_play_btn.anchor_right = 0.5
	_chars_play_btn.anchor_top = 1.0; _chars_play_btn.anchor_bottom = 1.0
	_chars_play_btn.offset_left = -160.0; _chars_play_btn.offset_right = 160.0
	_chars_play_btn.offset_top = -104.0; _chars_play_btn.offset_bottom = -20.0
	_chars_play_btn.pressed.connect(func():
		_audio.play("click", 1.06, -8.0)
		_chars_layer.visible = false
		_launch_selected_level()
	)
	root.add_child(_chars_play_btn)


func _on_characters_gui_input(ev: InputEvent) -> void:
	if state != GameState.CHARACTERS_PAGE:
		return
	if ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed and _chars_touch_fid == -1:
			_chars_touch_fid = st.index
			_chars_touch_start = st.position
			_chars_touch_moved = 0.0
			_chars_drag_idx = _pick_char_at_screen_pos(st.position)
			get_viewport().set_input_as_handled()
		elif not st.pressed and st.index == _chars_touch_fid:
			if _chars_drag_idx >= 0 and _chars_touch_moved <= 12.0:
				_select_character(CHAR_IDS[_chars_drag_idx], true)
			_chars_touch_fid = -1
			_chars_drag_idx = -1
			get_viewport().set_input_as_handled()
	elif ev is InputEventScreenDrag:
		var sd := ev as InputEventScreenDrag
		if sd.index == _chars_touch_fid and _chars_drag_idx >= 0 and _chars_drag_idx < _chars_models.size():
			var d := sd.relative
			_chars_touch_moved += d.length()
			_chars_yaws[_chars_drag_idx] += d.x * 0.62
			var m := _chars_models[_chars_drag_idx]
			if is_instance_valid(m):
				m.rotation_degrees.y = -90.0 + _chars_yaws[_chars_drag_idx]
			get_viewport().set_input_as_handled()
	elif not DisplayServer.is_touchscreen_available():
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := ev as InputEventMouseButton
			if mb.pressed:
				_chars_touch_start = mb.position
				_chars_touch_moved = 0.0
				_chars_drag_idx = _pick_char_at_screen_pos(mb.position)
			else:
				if _chars_drag_idx >= 0 and _chars_touch_moved <= 10.0:
					_select_character(CHAR_IDS[_chars_drag_idx], true)
				_chars_drag_idx = -1
		elif ev is InputEventMouseMotion and _chars_drag_idx >= 0 and _chars_drag_idx < _chars_models.size():
			var mm := ev as InputEventMouseMotion
			_chars_touch_moved += mm.relative.length()
			_chars_yaws[_chars_drag_idx] += mm.relative.x * 0.62
			var m := _chars_models[_chars_drag_idx]
			if is_instance_valid(m):
				m.rotation_degrees.y = -90.0 + _chars_yaws[_chars_drag_idx]


func _select_character(cid: String, play_fx: bool = true) -> void:
	if not (cid in CHAR_IDS):
		cid = "haneen"
	selected_character_id = cid
	_progress.selected_character = cid
	_progress.save_progress()
	if is_instance_valid(_player):
		_player.set_character(cid)
	if is_instance_valid(_backdrop):
		_backdrop.set_character_name(cid)
	if is_instance_valid(_map_hero_vis):
		_map_hero_vis.set_character(cid)
	if play_fx and _audio:
		_audio.play("gem", 1.12, -10.0, 80)
	_update_char_ring_highlights()
	for i in range(mini(3, _chars_models.size())):
		var m := _chars_models[i]
		if is_instance_valid(m):
			m.play_anim("victory" if (play_fx and CHAR_IDS[i] == cid) else "idle", 1.0, 0.14)


func _pick_char_at_screen_pos(scr_pos: Vector2) -> int:
	var best_idx := -1
	var best_dx := 99999.0
	var max_reach := get_viewport().get_visible_rect().size.x * 0.21
	for i in range(_chars_models.size()):
		if is_instance_valid(_chars_models[i]):
			var c_scr := _camera.unproject_position(_chars_models[i].global_position + Vector3(0, 0.70, 0))
			var dx := absf(scr_pos.x - c_scr.x)
			if dx < best_dx and dx <= max_reach:
				best_dx = dx
				best_idx = i
	return best_idx


func _update_char_ring_highlights() -> void:
	var sel_idx := CHAR_IDS.find(selected_character_id)
	if sel_idx < 0:
		sel_idx = 0
	for i in range(_chars_ring_mats.size()):
		var rm := _chars_ring_mats[i]
		var is_sel := (i == sel_idx)
		if rm:
			rm.emission_enabled = false
			rm.albedo_color = Color(0.20, 0.56, 0.90) if is_sel else Color(0.75, 0.80, 0.88)
		if i < _chars_cards.size() and is_instance_valid(_chars_cards[i]):
			var card := _chars_cards[i]
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(20)
			sb.shadow_size = 0
			if is_sel:
				sb.bg_color = Color(0.16, 0.50, 0.88, 0.96)
				sb.border_color = Color.WHITE
				sb.set_border_width_all(2)
			else:
				sb.bg_color = Color(0.98, 0.99, 1.0, 0.94)
				sb.border_color = Color(0.84, 0.88, 0.94, 1.0)
				sb.set_border_width_all(2)
			card.add_theme_stylebox_override("normal", sb)
			card.add_theme_stylebox_override("hover", sb)
			card.add_theme_stylebox_override("pressed", sb)
			card.add_theme_stylebox_override("focus", sb)
			card.scale = Vector2(1.04, 1.04) if is_sel else Vector2.ONE
		if i < _chars_name_lbls.size() and is_instance_valid(_chars_name_lbls[i]):
			_chars_name_lbls[i].add_theme_color_override("font_color", Color.WHITE if is_sel else Color(0.14, 0.16, 0.22))
		if i < _chars_checks.size() and is_instance_valid(_chars_checks[i]):
			_chars_checks[i].visible = is_sel


func _update_characters_page_ui() -> void:
	if state != GameState.CHARACTERS_PAGE or _chars_cards.size() < 3:
		return
	var vp_sz := get_viewport().get_visible_rect().size
	var scale_k := clampf(vp_sz.x / 1280.0, 0.72, 1.15)
	var btn_w := 178.0 * scale_k
	var btn_h := 50.0 * scale_k
	var fsz := clampi(int(round(20.0 * scale_k)), 15, 22)
	var xs := [-2.20, 0.0, 2.20]
	for i in range(3):
		var world_pt := Vector3(-120.0 + xs[i], -0.45, 0.45)
		var scr := _camera.unproject_position(world_pt)
		var c := _chars_cards[i]
		c.custom_minimum_size = Vector2(btn_w, btn_h)
		c.size = Vector2(btn_w, btn_h)
		c.pivot_offset = Vector2(btn_w * 0.5, btn_h * 0.5)
		if i < _chars_name_lbls.size():
			_chars_name_lbls[i].add_theme_font_size_override("font_size", fsz)
		c.position = Vector2(
			clampf(scr.x - btn_w * 0.5, 10.0, vp_sz.x - btn_w - 10.0),
			clampf(scr.y + 8.0, 96.0, vp_sz.y - btn_h - 110.0)
		)


# ==============================================================================
# 3. FULL-SCREEN 3D WORLD MAP PAGE (10-STAGE S-CURVE OCEAN ARCHIPELAGO)
# ==============================================================================

func _build_map_page() -> void:
	_map_stage = WorldMap3D.new()
	_map_stage.position = Vector3(-240.0, 20.0, 0.0)
	_map_stage.visible = false
	add_child(_map_stage)
	_map_stage.build_map(_progress.unlocked_level, _progress.selected_level, selected_character_id, _build_royal_crown_3d)
	_map_stage.stage_selected_by_proximity.connect(func(near_lvl: int):
		if state == GameState.MAP_PAGE and near_lvl <= _progress.unlocked_level:
			_progress.selected_level = near_lvl
			_progress.save_progress()
			_refresh_map_pins()
	)
	_map_stage_pts = _map_stage.stage_pts
	_map_crowns = _map_stage.crowns_3d
	_map_crown_pts = _map_stage.crown_pts
	_map_beacon = _map_stage._beacon
	_map_hero_vis = _map_stage._hero_vis

	_map_layer = CanvasLayer.new()
	_map_layer.layer = 12
	_map_layer.visible = false
	_map_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_map_layer)

	var root := Control.new()
	root.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_layer.add_child(root)

	var back_btn := GameFonts.make_orange_circle_btn(68.0, "res://assets/textures/ui/icon_back_white.png")
	back_btn.focus_mode = Control.FOCUS_NONE
	back_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	back_btn.pressed.connect(func():
		_audio.play("click", 1.05, -10.0)
		_enter_home_hub()
	)
	root.add_child(back_btn)
	back_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	back_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_btn.anchor_left = 0.0; back_btn.anchor_right = 0.0
	back_btn.anchor_top = 0.0; back_btn.anchor_bottom = 0.0
	back_btn.offset_left = 24.0; back_btn.offset_top = 18.0
	back_btn.offset_right = 92.0; back_btn.offset_bottom = 86.0

	# Top-right Floating Wallet Balance on Map (ZERO container box!)
	var mw_pill := PanelContainer.new()
	mw_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mw_pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(mw_pill)
	mw_pill.layout_direction = Control.LAYOUT_DIRECTION_LTR
	mw_pill.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mw_pill.anchor_left = 1.0; mw_pill.anchor_right = 1.0
	mw_pill.anchor_top = 0.0; mw_pill.anchor_bottom = 0.0
	mw_pill.offset_left = -160.0; mw_pill.offset_right = -24.0
	mw_pill.offset_top = 22.0; mw_pill.offset_bottom = 68.0
	mw_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var mwhb := HBoxContainer.new()
	mwhb.add_theme_constant_override("separation", 8)
	mwhb.alignment = BoxContainer.ALIGNMENT_END
	mwhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mw_pill.add_child(mwhb)
	mwhb.add_child(_make_coin_badge(34.0))
	_map_wallet_lbl = Label.new()
	_map_wallet_lbl.text = "0"
	_map_wallet_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_map_wallet_lbl, GameFonts.readex_bold(), 24, Color.WHITE)
	_map_wallet_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.94))
	_map_wallet_lbl.add_theme_constant_override("outline_size", 6)
	mwhb.add_child(_map_wallet_lbl)

	# Mobile Left Virtual Joystick (mounted BEFORE pins so Map Stage Pins always keep click priority!)
	var is_mob := GameFonts.is_touch_ui()
	var m_joy := _create_dynamic_joystick(root, func(axis: Vector2):
		if is_instance_valid(_map_stage) and state == GameState.MAP_PAGE:
			var d := Vector2.ZERO if axis.length() < 0.08 else Vector2(axis.x, axis.y)
			_map_stage.set_touch_move(d)
	)
	_map_joy_pad = m_joy["pad"]
	_map_joy_pad.visible = is_mob

	# ALL 10 Interactive Stage Pins (1..10, distant locked hidden behind mist & locked gate!)
	for lvl_num: int in range(1, GameProgress.IMPLEMENTED_LEVELS + 1):
		var pin := GameFonts.make_orange_pill_btn(Loc.t("stage_fmt") % lvl_num, 168.0, 58.0, 20)
		pin.expand_icon = true
		pin.add_theme_constant_override("icon_max_width", 24)
		pin.pressed.connect(func():
			if lvl_num <= _progress.unlocked_level:
				_audio.play("click", 1.1, -9.0)
				_progress.selected_level = lvl_num
				_progress.save_progress()
				_map_stage.refresh_state(_progress.unlocked_level, _progress.selected_level, selected_character_id, true)
				_refresh_map_pins()
		)
		root.add_child(pin)
		_map_pin_btns[lvl_num] = pin

	# 9 Interactive Evolving Crown Pins ("الدور الفاصل" between Kingdoms k -> k+1)
	for c_idx: int in range(1, GameProgress.IMPLEMENTED_LEVELS):
		var cbtn := GameFonts.make_orange_pill_btn("", 78.0, 42.0, 16)
		cbtn.icon = _icon_crown_tex
		cbtn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cbtn.expand_icon = true
		cbtn.add_theme_constant_override("icon_max_width", 28)
		cbtn.pressed.connect(func():
			var next_k := c_idx + 1
			if next_k <= _progress.unlocked_level:
				_audio.play("click", 1.12, -8.0)
				_map_layer.visible = false
				_start_kingdom_journey(c_idx, next_k)
		)
		root.add_child(cbtn)
		_map_crown_btns[c_idx] = cbtn

	_map_hint_lbl = Label.new()
	_map_hint_lbl.text = Loc.t("map_walk_hint")
	_map_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_map_hint_lbl, GameFonts.readex_bold(), 16, Color.WHITE)
	_map_hint_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.90))
	_map_hint_lbl.add_theme_constant_override("outline_size", 5)
	root.add_child(_map_hint_lbl)
	_map_hint_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_map_hint_lbl.anchor_left = 0.5; _map_hint_lbl.anchor_right = 0.5
	_map_hint_lbl.anchor_top = 0.0; _map_hint_lbl.anchor_bottom = 0.0
	_map_hint_lbl.offset_left = -280.0; _map_hint_lbl.offset_right = 280.0
	_map_hint_lbl.offset_top = 24.0; _map_hint_lbl.offset_bottom = 54.0

	_map_play_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_play"), 320.0, 84.0, 25)
	_map_play_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_map_play_btn.anchor_left = 0.5; _map_play_btn.anchor_right = 0.5
	_map_play_btn.anchor_top = 1.0; _map_play_btn.anchor_bottom = 1.0
	_map_play_btn.offset_left = -160.0; _map_play_btn.offset_right = 160.0
	_map_play_btn.offset_top = -106.0; _map_play_btn.offset_bottom = -22.0
	_map_play_btn.pressed.connect(func():
		_audio.play("click", 1.05, -8.0)
		_map_layer.visible = false
		_launch_selected_level()
	)
	root.add_child(_map_play_btn)

	_map_prev_btn = GameFonts.make_orange_circle_btn(64.0, "res://assets/textures/ui/icon_back_white.png", 0.50)
	_map_prev_btn.visible = false
	_map_prev_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_map_prev_btn.anchor_left = 0.5; _map_prev_btn.anchor_right = 0.5
	_map_prev_btn.anchor_top = 1.0; _map_prev_btn.anchor_bottom = 1.0
	_map_prev_btn.offset_top = -96.0; _map_prev_btn.offset_bottom = -32.0
	_map_prev_btn.pressed.connect(func():
		_step_map_selected_stage(-1)
	)
	root.add_child(_map_prev_btn)

	_map_next_btn = GameFonts.make_orange_circle_btn(64.0, "res://assets/textures/ui/icon_back_white.png", 0.50)
	_map_next_btn.visible = false
	var nico := _map_next_btn.find_child("Icon", true, false) as TextureRect
	if nico:
		nico.flip_h = true
	_map_next_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_map_next_btn.anchor_left = 0.5; _map_next_btn.anchor_right = 0.5
	_map_next_btn.anchor_top = 1.0; _map_next_btn.anchor_bottom = 1.0
	_map_next_btn.offset_top = -96.0; _map_next_btn.offset_bottom = -32.0
	_map_next_btn.pressed.connect(func():
		_step_map_selected_stage(1)
	)
	root.add_child(_map_next_btn)

	_map_jump_btn = GameFonts.make_orange_icon_btn(124.0, 124.0, "res://assets/textures/ui/icon_up_white.png", 62, true)
	_map_jump_btn.visible = is_mob
	root.add_child(_map_jump_btn)
	_map_jump_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_map_jump_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_map_jump_btn.anchor_left = 1.0; _map_jump_btn.anchor_right = 1.0
	_map_jump_btn.anchor_top = 1.0; _map_jump_btn.anchor_bottom = 1.0
	_map_jump_btn.offset_left = -148.0; _map_jump_btn.offset_right = -24.0
	_map_jump_btn.offset_top = -148.0; _map_jump_btn.offset_bottom = -24.0
	_bind_touch_action_btn(_map_jump_btn, func():
		if is_instance_valid(_map_stage):
			_map_stage.trigger_jump()
	)


func _build_royal_crown_3d(tier: int) -> Node3D:
	# Multi-tier procedurally evolving 3D Royal Crown across 29 Kingdoms (1..29), capped cleanly!
	var eff_tier := clampi(tier, 1, 29)
	var sc_lvl := minf(float(eff_tier - 1), 10.0)
	var root := Node3D.new()
	var sc := 0.92 + sc_lvl * 0.055
	root.scale = Vector3.ONE * sc

	var rim_mat := StandardMaterial3D.new()
	if tier <= 2:
		rim_mat.albedo_color = Color(0.84, 0.72, 0.36)
		rim_mat.metallic = 0.70; rim_mat.roughness = 0.25
	elif tier <= 5:
		rim_mat.albedo_color = Color(1.0, 0.80, 0.16)
		rim_mat.metallic = 0.85; rim_mat.roughness = 0.18
	else:
		rim_mat.albedo_color = Color(1.0, 0.86, 0.22)
		rim_mat.metallic = 0.92; rim_mat.roughness = 0.12
		rim_mat.emission_enabled = true
		rim_mat.emission = Color(1.0, 0.68, 0.12)
		rim_mat.emission_energy_multiplier = 0.22 + float(tier - 5) * 0.08

	var gem_mat := StandardMaterial3D.new()
	if tier <= 2:
		gem_mat.albedo_color = Color(0.18, 0.86, 0.95)
	elif tier <= 5:
		gem_mat.albedo_color = Color(0.95, 0.18, 0.32)
	elif tier <= 8:
		gem_mat.albedo_color = Color(0.24, 0.48, 1.0)
	else:
		gem_mat.albedo_color = Color(0.95, 0.85, 1.0)
	gem_mat.metallic = 0.35; gem_mat.roughness = 0.10
	gem_mat.emission_enabled = true
	gem_mat.emission = gem_mat.albedo_color
	gem_mat.emission_energy_multiplier = 0.45

	# Circular diadem base band
	var band := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.48; bm.bottom_radius = 0.42; bm.height = 0.22 + float(tier >= 5) * 0.06
	band.mesh = bm; band.material_override = rim_mat
	band.position.y = 0.12
	root.add_child(band)

	# Spikes evolve 4 -> 8 around crown
	var spikes := 4 + mini(4, eff_tier / 3)
	for i in range(spikes):
		var a := float(i) / float(spikes) * TAU
		var sp := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.02; pm.bottom_radius = 0.11; pm.height = 0.34 + sc_lvl * 0.028
		sp.mesh = pm; sp.material_override = rim_mat
		sp.position = Vector3(cos(a) * 0.39, 0.32 + sc_lvl * 0.014, sin(a) * 0.39)
		root.add_child(sp)

		var tip := MeshInstance3D.new()
		var gm := SphereMesh.new(); gm.radius = 0.075; gm.height = 0.15
		tip.mesh = gm; tip.material_override = gem_mat
		tip.position = Vector3(cos(a) * 0.39, 0.48 + sc_lvl * 0.025, sin(a) * 0.39)
		root.add_child(tip)

	# Royal velvet cushion + sovereign cross/diamond arches for higher Kingdoms (tier >= 4)
	if tier >= 4:
		var vel := MeshInstance3D.new()
		var vm := SphereMesh.new(); vm.radius = 0.36; vm.height = 0.40
		vel.mesh = vm
		var vmat := StandardMaterial3D.new()
		vmat.albedo_color = Color(0.68, 0.08, 0.18) if tier < 8 else Color(0.36, 0.08, 0.56)
		vel.material_override = vmat
		vel.position.y = 0.28
		root.add_child(vel)
	if tier >= 6:
		var orb := MeshInstance3D.new()
		var om := SphereMesh.new()
		om.radius = 0.15
		om.height = 0.30
		orb.mesh = om
		orb.material_override = gem_mat
		orb.position.y = 0.68 + sc_lvl * 0.022
		root.add_child(orb)
	if tier >= 9:
		var halo := MeshInstance3D.new()
		var hm := TorusMesh.new(); hm.inner_radius = 0.56; hm.outer_radius = 0.65
		halo.mesh = hm; halo.material_override = rim_mat
		halo.position.y = 0.40
		root.add_child(halo)
	return root


func _refresh_map_pins() -> void:
	if is_instance_valid(_map_wallet_lbl):
		_map_wallet_lbl.text = "%d" % _progress.total_coins
	if is_instance_valid(_map_hint_lbl):
		_map_hint_lbl.layout_direction = Loc.dir_layout()
		_map_hint_lbl.text = Loc.t("map_walk_hint")
	for lvl_num: int in range(1, GameProgress.IMPLEMENTED_LEVELS + 1):
		var pin: Button = _map_pin_btns[lvl_num]
		pin.layout_direction = Loc.dir_layout()
		var unlocked: bool = lvl_num <= _progress.unlocked_level
		var selected: bool = lvl_num == _progress.selected_level
		pin.disabled = not unlocked
		pin.text = Loc.t("stage_fmt") % lvl_num
		if not unlocked:
			pin.icon = _icon_lock_tex
		elif selected:
			pin.icon = _icon_check_tex
		else:
			pin.icon = null
		pin.scale = Vector2(1.10, 1.10) if selected else Vector2.ONE
	for c_idx: int in range(1, GameProgress.IMPLEMENTED_LEVELS):
		if not _map_crown_btns.has(c_idx):
			continue
		var cb: Button = _map_crown_btns[c_idx]
		var next_k := c_idx + 1
		var c_unlocked := next_k <= _progress.unlocked_level
		cb.disabled = not c_unlocked
		cb.text = ""
		var need_this := _progress.needs_journey_to(next_k)
		if not c_unlocked:
			cb.icon = _icon_lock_tex
			cb.modulate = Color(0.78, 0.80, 0.86, 0.90)
		elif need_this:
			cb.icon = _icon_sword_tex
			cb.modulate = Color.WHITE
		else:
			cb.icon = _icon_crown_tex
			cb.modulate = Color.WHITE
		cb.scale = Vector2(1.15, 1.15) if (need_this or _progress.selected_level == next_k) else Vector2.ONE
	_sync_map_play_btn_text()


func _step_map_selected_stage(delta_lvl: int) -> void:
	if _progress.unlocked_level <= 1:
		return
	var next_lvl := clampi(_progress.selected_level + delta_lvl, 1, _progress.unlocked_level)
	if next_lvl == _progress.selected_level:
		return
	_audio.play("click", 1.1, -9.0)
	_progress.selected_level = next_lvl
	_progress.save_progress()
	if is_instance_valid(_map_stage):
		_map_stage.refresh_state(_progress.unlocked_level, _progress.selected_level, selected_character_id, true)
		var hp := _map_stage.get_hero_global_pos()
		_camera.position = hp + Vector3(0.0, 5.8, 10.8)
		_camera.look_at(hp + Vector3(0.0, 1.3, -13.0))
	_refresh_map_pins()
	_update_map_pins_layout()


func _sync_map_play_btn_text() -> void:
	if not is_instance_valid(_map_play_btn):
		return
	_map_play_btn.layout_direction = Loc.dir_layout()
	var half_w := 160.0
	if _progress.needs_journey_to(_progress.selected_level):
		_map_play_btn.text = Loc.start_journey_text(_progress.selected_level)
		_map_play_btn.custom_minimum_size = Vector2(430.0, 84.0)
		half_w = 215.0
		_map_play_btn.offset_left = -half_w
		_map_play_btn.offset_right = half_w
		_map_play_btn.add_theme_font_size_override("font_size", 23)
	else:
		_map_play_btn.text = Loc.t("map_enter_stage_fmt") % _progress.selected_level
		_map_play_btn.custom_minimum_size = Vector2(320.0, 84.0)
		half_w = 160.0
		_map_play_btn.offset_left = -half_w
		_map_play_btn.offset_right = half_w
		_map_play_btn.add_theme_font_size_override("font_size", 25)
	var show_nav := _progress.unlocked_level > 1
	if is_instance_valid(_map_prev_btn):
		_map_prev_btn.visible = show_nav
		_map_prev_btn.disabled = _progress.selected_level <= 1
		_map_prev_btn.offset_left = -half_w - 78.0
		_map_prev_btn.offset_right = -half_w - 14.0
	if is_instance_valid(_map_next_btn):
		_map_next_btn.visible = show_nav
		_map_next_btn.disabled = _progress.selected_level >= _progress.unlocked_level
		_map_next_btn.offset_left = half_w + 14.0
		_map_next_btn.offset_right = half_w + 78.0


func _update_map_pins_layout() -> void:
	if state != GameState.MAP_PAGE or not is_instance_valid(_map_stage):
		return
	var vp_sz := get_viewport().get_visible_rect().size
	var scale_k := clampf(vp_sz.x / 1280.0, 0.72, 1.15)
	var bw := 168.0 * scale_k
	var bh := 58.0 * scale_k
	var max_show := mini(GameProgress.IMPLEMENTED_LEVELS, _progress.unlocked_level + 1)
	for lvl_num: int in range(1, GameProgress.IMPLEMENTED_LEVELS + 1):
		var pin: Button = _map_pin_btns[lvl_num]
		if lvl_num > max_show or lvl_num - 1 >= _map_stage_pts.size():
			pin.visible = false
			continue
		var wpt: Vector3 = _map_stage.position + _map_stage_pts[lvl_num - 1] + Vector3(0.0, 4.1, -1.2)
		if _camera.is_position_behind(wpt) or wpt.distance_to(_camera.position) > 54.0:
			pin.visible = false
			continue
		var scr := _camera.unproject_position(wpt)
		if scr.y < 64.0 or scr.y > vp_sz.y - 135.0 or scr.x < -30.0 or scr.x > vp_sz.x + 30.0:
			pin.visible = false
			continue
		pin.visible = true
		pin.custom_minimum_size = Vector2(bw, bh)
		pin.size = Vector2(bw, bh)
		pin.pivot_offset = Vector2(bw * 0.5, bh * 0.5)
		pin.add_theme_font_size_override("font_size", clampi(int(round(19.0 * scale_k)), 15, 22))
		pin.position = Vector2(
			clampf(scr.x - bw * 0.5, 16.0, vp_sz.x - bw - 16.0),
			clampf(scr.y - bh * 0.5, 82.0, vp_sz.y - 175.0)
		)
	var cw := 78.0 * scale_k
	var ch := 42.0 * scale_k
	for c_idx: int in range(1, GameProgress.IMPLEMENTED_LEVELS):
		if _map_crown_btns.has(c_idx) and c_idx - 1 < _map_crown_pts.size():
			var cb: Button = _map_crown_btns[c_idx]
			if c_idx > _progress.unlocked_level:
				cb.visible = false
				continue
			var cwpt: Vector3 = _map_stage.position + _map_crown_pts[c_idx - 1] + Vector3(0.0, 1.5, 0.0)
			if _camera.is_position_behind(cwpt) or cwpt.distance_to(_camera.position) > 54.0:
				cb.visible = false
				continue
			var cscr := _camera.unproject_position(cwpt)
			if cscr.y < 64.0 or cscr.y > vp_sz.y - 135.0 or cscr.x < -20.0 or cscr.x > vp_sz.x + 20.0:
				cb.visible = false
				continue
			cb.visible = true
			cb.custom_minimum_size = Vector2(cw, ch)
			cb.size = Vector2(cw, ch)
			cb.pivot_offset = Vector2(cw * 0.5, ch * 0.5)
			cb.position = Vector2(
				clampf(cscr.x - cw * 0.5, 14.0, vp_sz.x - cw - 14.0),
				clampf(cscr.y - ch * 0.5, 72.0, vp_sz.y - 155.0)
			)


# ==============================================================================
# 4. GAMEPLAY HUD & CARTOON ORANGE MODALS
# ==============================================================================

func _build_minimal_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	_hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud_layer)

	var root_ui := Control.new()
	root_ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root_ui)

	_pause_btn = GameFonts.make_orange_circle_btn(82.0, "res://assets/textures/ui/icon_pause_white.png")
	_pause_btn.focus_mode = Control.FOCUS_NONE
	_pause_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_pause_btn.pressed.connect(_toggle_pause)
	root_ui.add_child(_pause_btn)
	_pause_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_pause_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_pause_btn.anchor_left = 0.0; _pause_btn.anchor_right = 0.0
	_pause_btn.anchor_top = 0.0; _pause_btn.anchor_bottom = 0.0
	_pause_btn.offset_left = 20.0; _pause_btn.offset_top = 16.0
	_pause_btn.offset_right = 102.0; _pause_btn.offset_bottom = 98.0

	var floating_row := HBoxContainer.new()
	floating_row.layout_direction = Control.LAYOUT_DIRECTION_LTR
	floating_row.anchor_left = 1.0
	floating_row.anchor_right = 1.0
	floating_row.anchor_top = 0.0
	floating_row.anchor_bottom = 0.0
	floating_row.offset_left = -370.0
	floating_row.offset_top = 18.0
	floating_row.offset_right = -24.0
	floating_row.offset_bottom = 66.0
	floating_row.alignment = BoxContainer.ALIGNMENT_END
	floating_row.add_theme_constant_override("separation", 18)
	floating_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(floating_row)

	var hearts_holder := HBoxContainer.new()
	hearts_holder.add_theme_constant_override("separation", 6)
	hearts_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_row.add_child(hearts_holder)
	for i in range(3):
		var ht := TextureRect.new()
		ht.texture = _tex_stage_heart_full
		ht.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ht.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ht.custom_minimum_size = Vector2(36, 36)
		ht.pivot_offset = Vector2(18, 18)
		ht.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_holder.add_child(ht)
		_hearts_box.append(ht)

	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 8)
	coin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_row.add_child(coin_row)

	coin_row.add_child(_make_coin_badge(34.0))

	_coin_lbl = Label.new()
	_coin_lbl.text = "0"
	_coin_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_coin_lbl, GameFonts.readex_bold(), 27, Color.WHITE)
	_coin_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.14, 0.28, 0.90))
	_coin_lbl.add_theme_constant_override("outline_size", 6)
	coin_row.add_child(_coin_lbl)

	var star_holder := Control.new()
	star_holder.custom_minimum_size = Vector2(34, 34)
	star_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_row.add_child(star_holder)
	var st_out := Polygon2D.new()
	st_out.color = Color(0.08, 0.10, 0.18, 0.65)
	st_out.polygon = _star_poly(16.0, 7.2)
	st_out.position = Vector2(17, 17)
	star_holder.add_child(st_out)
	_rescue_star_poly = Polygon2D.new()
	_rescue_star_poly.color = Color(1.0, 1.0, 1.0, 0.38)
	_rescue_star_poly.polygon = _star_poly(13.2, 5.8)
	_rescue_star_poly.position = Vector2(17, 17)
	star_holder.add_child(_rescue_star_poly)

	# Mobile Touch Controls for Stages 1..10: LEFT Joystick + RIGHT Glossy Orange Jump/Slide Stack (Hidden on Desktop!)
	var is_mob := GameFonts.is_touch_ui()
	_touch_left_col = VBoxContainer.new()
	_touch_left_col.add_theme_constant_override("separation", 14)
	_touch_left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_left_col.visible = is_mob
	root_ui.add_child(_touch_left_col)
	_touch_left_col.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_touch_left_col.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_touch_left_col.anchor_left = 1.0; _touch_left_col.anchor_right = 1.0
	_touch_left_col.anchor_top = 1.0; _touch_left_col.anchor_bottom = 1.0
	_touch_left_col.offset_left = -156.0; _touch_left_col.offset_right = -24.0
	_touch_left_col.offset_top = -258.0; _touch_left_col.offset_bottom = -20.0

	_touch_jump_btn = GameFonts.make_orange_icon_btn(128.0, 110.0, "res://assets/textures/ui/icon_up_white.png", 58, false)
	_touch_jump_btn.visible = is_mob
	_bind_touch_action_btn(
		_touch_jump_btn,
		func():
			if _touch_jump_held:
				return
			_touch_jump_held = true
			if is_instance_valid(_player):
				_player.trigger_jump_input(),
		func():
			_touch_jump_held = false
			if is_instance_valid(_player):
				_player.trigger_jump_release()
	)
	_touch_left_col.add_child(_touch_jump_btn)

	_touch_slide_btn = GameFonts.make_orange_icon_btn(128.0, 110.0, "res://assets/textures/ui/icon_down_white.png", 58, false)
	_touch_slide_btn.visible = is_mob
	_bind_touch_action_btn(
		_touch_slide_btn,
		func():
			if is_instance_valid(_player):
				_player.set_touch_down_held(true),
		func():
			if is_instance_valid(_player):
				_player.set_touch_down_held(false)
	)
	_touch_left_col.add_child(_touch_slide_btn)

	# Dynamic Left-Side Floating Joystick for Left/Right movement on mobile Stages
	var stage_joy := _create_dynamic_joystick(root_ui, func(axis: Vector2):
		if is_instance_valid(_player) and state == GameState.PLAYING:
			var dx := 0.0 if absf(axis.x) < 0.08 else axis.x
			_player.set_touch_move_x(dx)
		elif is_instance_valid(_player):
			_player.set_touch_move_x(0.0)
	)
	_stage_joy_pad = stage_joy["pad"]
	_stage_joy_ring = stage_joy["ring"]
	_stage_joy_knob = stage_joy["knob"]
	_stage_joy_pad.visible = is_mob


func _star_poly(r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(10):
		var a := -PI * 0.5 + float(i) * (PI / 5.0)
		var r := r_out if (i % 2 == 0) else r_in
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	return pts


func _release_touch_btn_entry(entry: Dictionary, call_release: bool = true) -> void:
	var b := entry["btn"] as Control
	var was_pressed := bool(entry["pressed"])
	entry["finger"] = -1
	entry["is_mouse"] = false
	entry["pressed"] = false
	if is_instance_valid(b):
		b.scale = Vector2.ONE
		b.modulate = Color.WHITE
	if call_release and was_pressed:
		var rel := entry["release_fn"] as Callable
		if rel.is_valid():
			rel.call()


func _bind_touch_action_btn(btn: Control, on_press: Callable, on_release: Callable = Callable()) -> void:
	var entry := {
		"btn": btn,
		"finger": -1,
		"is_mouse": false,
		"pressed": false,
		"press_fn": on_press,
		"release_fn": on_release,
	}
	_touch_action_btns.append(entry)
	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed and int(entry["finger"]) == -1:
				for p: Control in [_stage_joy_pad, _j_joy_pad, _map_joy_pad]:
					if is_instance_valid(p) and p.has_meta("joy_finger_fn"):
						if int((p.get_meta("joy_finger_fn") as Callable).call()) == st.index:
							return
				entry["finger"] = st.index
				entry["is_mouse"] = false
				entry["pressed"] = true
				btn.pivot_offset = btn.size * 0.5
				btn.scale = Vector2(0.92, 0.92)
				btn.modulate = Color(1.08, 1.04, 0.96, 1.0)
				on_press.call()
				btn.accept_event()
			elif not st.pressed and int(entry["finger"]) == st.index:
				_release_touch_btn_entry(entry, true)
				btn.accept_event()
		elif event is InputEventScreenDrag:
			var sd := event as InputEventScreenDrag
			if int(entry["finger"]) == sd.index:
				btn.accept_event()
		elif not DisplayServer.is_touchscreen_available():
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				return
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.button_index == MOUSE_BUTTON_LEFT:
					if mb.pressed and not bool(entry["pressed"]):
						entry["is_mouse"] = true
						entry["pressed"] = true
						btn.pivot_offset = btn.size * 0.5
						btn.scale = Vector2(0.92, 0.92)
						btn.modulate = Color(1.08, 1.04, 0.96, 1.0)
						on_press.call()
						btn.accept_event()
					elif not mb.pressed and bool(entry["is_mouse"]):
						_release_touch_btn_entry(entry, true)
						btn.accept_event()
	)


func _create_dynamic_joystick(parent: Control, on_move: Callable) -> Dictionary:
	var pad := Control.new()
	pad.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(pad)
	# Strictly constrain left thumbpad to bottom-left 268x268 zone so mid/upper-left taps stay free!
	pad.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pad.anchor_left = 0.0; pad.anchor_right = 0.0
	pad.anchor_top = 1.0; pad.anchor_bottom = 1.0
	pad.offset_left = 10.0; pad.offset_right = 278.0
	pad.offset_top = -276.0; pad.offset_bottom = -8.0

	var ring_d := 232.0
	var knob_d := 102.0
	var max_r := 84.0
	var ring := Panel.new()
	ring.size = Vector2(ring_d, ring_d)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.modulate.a = 0.64
	ring.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	pad.add_child(ring)

	var ring_tex := TextureRect.new()
	ring_tex.texture = load("res://assets/textures/ui/joy_ring.png")
	ring_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.add_child(ring_tex)

	var knob := Panel.new()
	knob.size = Vector2(knob_d, knob_d)
	knob.position = Vector2((ring_d - knob_d) * 0.5, (ring_d - knob_d) * 0.5)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	ring.add_child(knob)

	var knob_tex := TextureRect.new()
	knob_tex.texture = load("res://assets/textures/ui/joy_knob.png")
	knob_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	knob_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	knob_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	knob_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_child(knob_tex)

	var jst := {"finger": -1, "origin": Vector2.ZERO, "origin_global": Vector2.ZERO, "is_mouse": false}
	pad.set_meta("joy_finger_fn", func() -> int: return int(jst["finger"]))
	var rest_pos_fn := func():
		var psz := pad.size
		if psz.x < 40.0 or psz.y < 40.0:
			ring.position = Vector2(18.0, 18.0)
		else:
			ring.position = Vector2(18.0, maxf(8.0, psz.y - ring_d - 16.0))
		knob.position = Vector2((ring_d - knob_d) * 0.5, (ring_d - knob_d) * 0.5)
		ring.modulate.a = 0.64

	pad.resized.connect(func():
		if int(jst["finger"]) == -1 and not bool(jst["is_mouse"]):
			rest_pos_fn.call()
	)
	pad.set_meta("reset_joy_fn", func():
		jst["finger"] = -1
		jst["is_mouse"] = false
		rest_pos_fn.call()
		on_move.call(Vector2.ZERO)
	)
	rest_pos_fn.call_deferred()

	var begin_fn := func(local_pos: Vector2, fid: int, is_mouse_ev: bool):
		var psz := pad.size
		var half_r := ring_d * 0.5
		# Keep logical drag origin strictly at the exact finger-down position so right/left never flips near edges!
		jst["finger"] = fid
		jst["is_mouse"] = is_mouse_ev
		jst["origin"] = local_pos
		jst["origin_global"] = pad.global_position + local_pos
		var vis_c := Vector2(
			clampf(local_pos.x, half_r + 4.0, maxf(half_r + 4.0, psz.x - half_r - 4.0)),
			clampf(local_pos.y, half_r + 4.0, maxf(half_r + 4.0, psz.y - half_r - 4.0))
		)
		ring.position = vis_c - Vector2(half_r, half_r)
		ring.modulate.a = 1.0
		knob.position = Vector2(half_r - knob_d * 0.5, half_r - knob_d * 0.5)
		on_move.call(Vector2.ZERO)

	var drag_local_fn := func(local_pos: Vector2):
		var orig: Vector2 = jst["origin"]
		var d := local_pos - orig
		if d.length() > max_r:
			d = d.normalized() * max_r
		knob.position = Vector2(ring_d * 0.5, ring_d * 0.5) + d - Vector2(knob_d * 0.5, knob_d * 0.5)
		on_move.call(d / max_r)

	var drag_global_fn := func(global_pos: Vector2):
		var d: Vector2 = global_pos - (jst["origin_global"] as Vector2)
		if d.length() > max_r:
			d = d.normalized() * max_r
		knob.position = Vector2(ring_d * 0.5, ring_d * 0.5) + d - Vector2(knob_d * 0.5, knob_d * 0.5)
		on_move.call(d / max_r)

	pad.set_meta("track_joy_input_fn", func(ev: InputEvent) -> bool:
		if ev is InputEventScreenDrag:
			var sd := ev as InputEventScreenDrag
			if int(jst["finger"]) == sd.index and not bool(jst["is_mouse"]):
				drag_global_fn.call(sd.position)
				return true
		elif ev is InputEventScreenTouch:
			var st := ev as InputEventScreenTouch
			if not st.pressed and int(jst["finger"]) == st.index and not bool(jst["is_mouse"]):
				(pad.get_meta("reset_joy_fn") as Callable).call()
				return true
		elif ev is InputEventMouseMotion and bool(jst["is_mouse"]) and ev.device != InputEvent.DEVICE_ID_EMULATION:
			drag_global_fn.call((ev as InputEventMouseMotion).position)
			return true
		elif ev is InputEventMouseButton and bool(jst["is_mouse"]) and ev.device != InputEvent.DEVICE_ID_EMULATION:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				(pad.get_meta("reset_joy_fn") as Callable).call()
				return true
		return false
	)

	pad.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed and int(jst["finger"]) == -1 and not bool(jst["is_mouse"]):
				for entry in _touch_action_btns:
					if int(entry["finger"]) == st.index:
						return
				begin_fn.call(st.position, st.index, false)
				pad.accept_event()
			elif not st.pressed and st.index == int(jst["finger"]) and not bool(jst["is_mouse"]):
				(pad.get_meta("reset_joy_fn") as Callable).call()
				pad.accept_event()
		elif event is InputEventScreenDrag:
			var sd := event as InputEventScreenDrag
			if sd.index == int(jst["finger"]) and not bool(jst["is_mouse"]):
				drag_local_fn.call(sd.position)
				pad.accept_event()
		elif not DisplayServer.is_touchscreen_available():
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				return
			if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				var mb := event as InputEventMouseButton
				if mb.pressed and int(jst["finger"]) == -1 and not bool(jst["is_mouse"]):
					begin_fn.call(mb.position, -1, true)
					pad.accept_event()
				elif not mb.pressed and bool(jst["is_mouse"]):
					(pad.get_meta("reset_joy_fn") as Callable).call()
					pad.accept_event()
			elif event is InputEventMouseMotion and bool(jst["is_mouse"]):
				drag_local_fn.call((event as InputEventMouseMotion).position)
				pad.accept_event()
	)
	rest_pos_fn.call()
	return {"pad": pad, "ring": ring, "knob": knob}


func _make_coin_badge(diam: float = 34.0) -> Control:
	var ico := TextureRect.new()
	ico.texture = _icon_coin_tex
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.custom_minimum_size = Vector2(diam, diam)
	ico.size = Vector2(diam, diam)
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ico


func _build_journey_hud() -> void:
	_journey_hud_layer = CanvasLayer.new()
	_journey_hud_layer.layer = 10
	_journey_hud_layer.visible = false
	_journey_hud_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_journey_hud_layer)

	var jroot := Control.new()
	jroot.layout_direction = Control.LAYOUT_DIRECTION_LTR
	jroot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	jroot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_journey_hud_layer.add_child(jroot)

	# Fullscreen World Interaction Layer BELOW all HUD buttons/joysticks: Hold-on-Block Mines, Open Swipe Rotates Camera 360!
	_j_world_touch_pad = Control.new()
	_j_world_touch_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_j_world_touch_pad.mouse_filter = Control.MOUSE_FILTER_PASS
	jroot.add_child(_j_world_touch_pad)

	var jw_touch := {"fid": -2, "is_mouse": false, "mode": "", "moved": 0.0}
	var end_world_touch_fn := func(allow_sword_tap: bool):
		var was_cam: bool = (str(jw_touch["mode"]) == "cam")
		var was_mouse: bool = bool(jw_touch["is_mouse"])
		var moved_d: float = float(jw_touch["moved"])
		if is_instance_valid(_journey_world):
			if jw_touch["mode"] == "mine":
				_journey_world.cancel_mining()
			elif allow_sword_tap and was_cam and was_mouse and moved_d < 10.0:
				_journey_world.trigger_sword_attack()
		jw_touch["fid"] = -2
		jw_touch["is_mouse"] = false
		jw_touch["mode"] = ""
		jw_touch["moved"] = 0.0

	_j_world_touch_pad.set_meta("reset_world_touch_fn", func():
		end_world_touch_fn.call(false)
	)
	_j_world_touch_pad.set_meta("track_world_touch_fn", func(ev: InputEvent) -> bool:
		if jw_touch["mode"] == "":
			return false
		if ev is InputEventScreenDrag and not bool(jw_touch["is_mouse"]):
			var sd := ev as InputEventScreenDrag
			if sd.index == int(jw_touch["fid"]):
				jw_touch["moved"] = float(jw_touch["moved"]) + sd.relative.length()
				if jw_touch["mode"] == "mine" and float(jw_touch["moved"]) > 28.0:
					if is_instance_valid(_journey_world):
						_journey_world.cancel_mining()
					jw_touch["mode"] = "cam"
				if jw_touch["mode"] == "cam" and is_instance_valid(_journey_world):
					_journey_world.rotate_camera(sd.relative.x, sd.relative.y)
				return true
		elif ev is InputEventScreenTouch and not bool(jw_touch["is_mouse"]):
			var st := ev as InputEventScreenTouch
			if not st.pressed and st.index == int(jw_touch["fid"]):
				end_world_touch_fn.call(false)
				return true
		elif ev is InputEventMouseMotion and bool(jw_touch["is_mouse"]) and ev.device != InputEvent.DEVICE_ID_EMULATION:
			var mm := ev as InputEventMouseMotion
			jw_touch["moved"] = float(jw_touch["moved"]) + mm.relative.length()
			if jw_touch["mode"] == "mine" and float(jw_touch["moved"]) > 28.0:
				if is_instance_valid(_journey_world):
					_journey_world.cancel_mining()
				jw_touch["mode"] = "cam"
			if jw_touch["mode"] == "cam" and is_instance_valid(_journey_world):
				_journey_world.rotate_camera(mm.relative.x, mm.relative.y)
			return true
		elif ev is InputEventMouseButton and bool(jw_touch["is_mouse"]) and ev.device != InputEvent.DEVICE_ID_EMULATION:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				end_world_touch_fn.call(true)
				return true
		return false
	)
	_j_world_touch_pad.gui_input.connect(func(ev: InputEvent):
		if state != GameState.JOURNEY or not is_instance_valid(_journey_world):
			return
		if ev is InputEventScreenTouch:
			var st := ev as InputEventScreenTouch
			if st.pressed and jw_touch["mode"] == "":
				for entry in _touch_action_btns:
					if int(entry["finger"]) == st.index:
						return
				if is_instance_valid(_j_joy_pad) and _j_joy_pad.has_meta("joy_finger_fn"):
					if int((_j_joy_pad.get_meta("joy_finger_fn") as Callable).call()) == st.index:
						return
				jw_touch["fid"] = st.index
				jw_touch["is_mouse"] = false
				jw_touch["moved"] = 0.0
				jw_touch["mode"] = "mine" if _journey_world.begin_mine_at_screen(st.position) else "cam"
				_j_world_touch_pad.accept_event()
		elif not DisplayServer.is_touchscreen_available() and ev.device != InputEvent.DEVICE_ID_EMULATION:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				var mb := ev as InputEventMouseButton
				if mb.pressed and jw_touch["mode"] == "":
					jw_touch["fid"] = -1
					jw_touch["is_mouse"] = true
					jw_touch["moved"] = 0.0
					jw_touch["mode"] = "mine" if _journey_world.begin_mine_at_screen(mb.position) else "cam"
					_j_world_touch_pad.accept_event()
	)

	_j_pause_btn = GameFonts.make_orange_circle_btn(82.0, "res://assets/textures/ui/icon_pause_white.png")
	_j_pause_btn.focus_mode = Control.FOCUS_NONE
	_j_pause_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_j_pause_btn.pressed.connect(_toggle_pause)
	jroot.add_child(_j_pause_btn)
	_j_pause_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_j_pause_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_j_pause_btn.anchor_left = 0.0; _j_pause_btn.anchor_right = 0.0
	_j_pause_btn.anchor_top = 0.0; _j_pause_btn.anchor_bottom = 0.0
	_j_pause_btn.offset_left = 20.0; _j_pause_btn.offset_top = 16.0
	_j_pause_btn.offset_right = 102.0; _j_pause_btn.offset_bottom = 98.0

	# Top-left Floating Journey Milestone Text (ZERO container box!)
	var j_pill := PanelContainer.new()
	j_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	j_pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	jroot.add_child(j_pill)
	j_pill.layout_direction = Control.LAYOUT_DIRECTION_LTR
	j_pill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	j_pill.anchor_left = 0.0; j_pill.anchor_right = 0.0
	j_pill.anchor_top = 0.0; j_pill.anchor_bottom = 0.0
	j_pill.offset_left = 114.0; j_pill.offset_right = 114.0
	j_pill.offset_top = 28.0; j_pill.offset_bottom = 72.0
	j_pill.grow_horizontal = Control.GROW_DIRECTION_END

	_j_banner_lbl = Label.new()
	_j_banner_lbl.text = ""
	_j_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_j_banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_j_banner_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_j_banner_lbl, GameFonts.readex_bold(), 20, Color.WHITE)
	_j_banner_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.94))
	_j_banner_lbl.add_theme_constant_override("outline_size", 6)
	j_pill.add_child(_j_banner_lbl)

	# Top-right 6 Evolved Royal Castle Hearts + Coin Count
	var top_r := HBoxContainer.new()
	top_r.layout_direction = Control.LAYOUT_DIRECTION_LTR
	top_r.anchor_left = 1.0; top_r.anchor_right = 1.0
	top_r.anchor_top = 0.0; top_r.anchor_bottom = 0.0
	top_r.offset_left = -465.0; top_r.offset_top = 18.0
	top_r.offset_right = -24.0; top_r.offset_bottom = 64.0
	top_r.alignment = BoxContainer.ALIGNMENT_END
	top_r.add_theme_constant_override("separation", 18)
	top_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jroot.add_child(top_r)

	_j_hearts_holder = HBoxContainer.new()
	_j_hearts_holder.add_theme_constant_override("separation", 5)
	_j_hearts_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_r.add_child(_j_hearts_holder)
	_j_hearts.clear()
	for i in range(6):
		var jht := TextureRect.new()
		jht.texture = _tex_jheart_full
		jht.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		jht.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		jht.custom_minimum_size = Vector2(36, 36)
		jht.pivot_offset = Vector2(18, 18)
		jht.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_j_hearts_holder.add_child(jht)
		_j_hearts.append(jht)

	var jc_row := HBoxContainer.new()
	jc_row.add_theme_constant_override("separation", 8)
	jc_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_r.add_child(jc_row)
	jc_row.add_child(_make_coin_badge(34.0))

	_j_coin_lbl = Label.new()
	_j_coin_lbl.text = "0"
	_j_coin_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_j_coin_lbl, GameFonts.readex_bold(), 27, Color.WHITE)
	_j_coin_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.14, 0.28, 0.90))
	_j_coin_lbl.add_theme_constant_override("outline_size", 6)
	jc_row.add_child(_j_coin_lbl)

	# Bottom-Center Minecraft Hotbar (2 Slots: Oak Planks & Cobblestone) + Proximity Hint Label
	_j_toast_lbl = Label.new()
	_j_toast_lbl.text = ""
	_j_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_j_toast_lbl.modulate.a = 0.0
	_j_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(_j_toast_lbl, GameFonts.readex_bold(), 17, Color(1.0, 0.94, 0.62))
	_j_toast_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.08, 0.14, 0.95))
	_j_toast_lbl.add_theme_constant_override("outline_size", 5)
	jroot.add_child(_j_toast_lbl)
	_j_toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_j_toast_lbl.anchor_left = 0.5; _j_toast_lbl.anchor_right = 0.5
	_j_toast_lbl.anchor_top = 1.0; _j_toast_lbl.anchor_bottom = 1.0
	_j_toast_lbl.offset_left = -280.0; _j_toast_lbl.offset_right = 280.0
	_j_toast_lbl.offset_top = -114.0; _j_toast_lbl.offset_bottom = -84.0

	_j_hotbar = PanelContainer.new()
	_j_hotbar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	jroot.add_child(_j_hotbar)
	_j_hotbar.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_j_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_j_hotbar.anchor_left = 0.5; _j_hotbar.anchor_right = 0.5
	_j_hotbar.anchor_top = 1.0; _j_hotbar.anchor_bottom = 1.0
	_j_hotbar.offset_left = -84.0; _j_hotbar.offset_right = 84.0
	_j_hotbar.offset_top = -84.0; _j_hotbar.offset_bottom = -12.0

	var hb_slots := HBoxContainer.new()
	hb_slots.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hb_slots.add_theme_constant_override("separation", 18)
	_j_hotbar.add_child(hb_slots)

	_j_slot_btns.clear()
	_j_slot_cnt_lbls.clear()
	_j_slot_frames.clear()
	var blk_icons := [
		load("res://assets/textures/ui/icon_block_oak.png"),
		load("res://assets/textures/ui/icon_block_stone.png"),
	]
	for si in range(2):
		var sbtn := Button.new()
		sbtn.text = ""
		sbtn.flat = true
		sbtn.focus_mode = Control.FOCUS_NONE
		sbtn.custom_minimum_size = Vector2(66, 62)
		sbtn.pivot_offset = Vector2(33, 31)
		var empty_sb := StyleBoxEmpty.new()
		sbtn.add_theme_stylebox_override("normal", empty_sb)
		sbtn.add_theme_stylebox_override("hover", empty_sb)
		sbtn.add_theme_stylebox_override("pressed", empty_sb)
		sbtn.add_theme_stylebox_override("focus", empty_sb)
		sbtn.add_theme_stylebox_override("disabled", empty_sb)

		var ico := TextureRect.new()
		ico.texture = blk_icons[si]
		ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		ico.offset_left = -24; ico.offset_right = 24
		ico.offset_top = -25; ico.offset_bottom = 23
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sbtn.add_child(ico)

		var clbl := Label.new()
		clbl.text = "0"
		clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		clbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		clbl.offset_left = -32; clbl.offset_right = -2
		clbl.offset_top = -24; clbl.offset_bottom = -1
		clbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		GameFonts.apply_rtl_label(clbl, GameFonts.readex_bold(), 17, Color(1.0, 0.90, 0.25) if si == 0 else Color.WHITE)
		clbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.95))
		clbl.add_theme_constant_override("outline_size", 5)
		sbtn.add_child(clbl)
		_j_slot_cnt_lbls.append(clbl)

		var slot_idx := si
		_bind_touch_action_btn(sbtn, func():
			if is_instance_valid(_journey_world):
				_journey_world.select_mc_slot(slot_idx)
		)
		hb_slots.add_child(sbtn)
		_j_slot_btns.append(sbtn)

	# Mobile Touch Controls for 3D Kingdom Journeys: LEFT Joystick + RIGHT 4-Button Arc (Large Sword, Jump, Build, Dash)
	var is_mob := GameFonts.is_touch_ui()
	_j_left_col = Control.new()
	_j_left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_j_left_col.visible = is_mob
	jroot.add_child(_j_left_col)
	_j_left_col.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_j_left_col.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_j_left_col.anchor_left = 1.0; _j_left_col.anchor_right = 1.0
	_j_left_col.anchor_top = 1.0; _j_left_col.anchor_bottom = 1.0
	_j_left_col.offset_left = -410.0; _j_left_col.offset_right = -14.0
	_j_left_col.offset_top = -350.0; _j_left_col.offset_bottom = -14.0

	_j_jump_btn = GameFonts.make_orange_icon_btn(108.0, 108.0, "res://assets/textures/ui/icon_up_white.png", 56, true)
	_j_jump_btn.visible = is_mob
	_j_left_col.add_child(_j_jump_btn)
	_j_jump_btn.position = Vector2(268.0, 44.0)
	_bind_touch_action_btn(
		_j_jump_btn,
		func():
			if _j_jump_held:
				return
			_j_jump_held = true
			if is_instance_valid(_journey_world):
				_journey_world.trigger_jump(),
		func():
			_j_jump_held = false
	)

	_j_build_btn = GameFonts.make_orange_icon_btn(108.0, 108.0, "res://assets/textures/ui/icon_build_white.png", 56, true)
	_j_build_btn.visible = is_mob
	_j_left_col.add_child(_j_build_btn)
	_j_build_btn.position = Vector2(120.0, 74.0)
	_bind_touch_action_btn(
		_j_build_btn,
		func():
			if is_instance_valid(_journey_world):
				_journey_world.trigger_place_block()
	)

	_j_dash_btn = GameFonts.make_orange_icon_btn(104.0, 104.0, "res://assets/textures/ui/icon_dash_white.png", 54, true)
	_j_dash_btn.visible = is_mob
	_j_left_col.add_child(_j_dash_btn)
	_j_dash_btn.position = Vector2(96.0, 212.0)
	_bind_touch_action_btn(
		_j_dash_btn,
		func():
			if is_instance_valid(_journey_world):
				_journey_world.trigger_dash()
	)

	_j_sword_btn = GameFonts.make_orange_icon_btn(150.0, 150.0, "res://assets/textures/ui/icon_sword_white.png", 78, true)
	_j_sword_btn.visible = is_mob
	_j_left_col.add_child(_j_sword_btn)
	_j_sword_btn.position = Vector2(236.0, 178.0)
	_bind_touch_action_btn(
		_j_sword_btn,
		func():
			if is_instance_valid(_journey_world):
				_journey_world.trigger_sword_attack()
	)

	var j_joy := _create_dynamic_joystick(jroot, func(axis: Vector2):
		if is_instance_valid(_journey_world):
			var d := Vector2.ZERO if axis.length() < 0.08 else Vector2(-axis.y, axis.x)
			_journey_world.set_touch_move(d)
	)
	_j_joy_pad = j_joy["pad"]
	_j_joy_ring = j_joy["ring"]
	_j_joy_knob = j_joy["knob"]
	_j_joy_pad.visible = is_mob


func _reset_joy_knob() -> void:
	_j_joy_finger = -1
	_stage_joy_finger = -1
	_touch_jump_held = false
	_j_jump_held = false
	for entry in _touch_action_btns:
		_release_touch_btn_entry(entry, false)
	for p: Control in [_j_joy_pad, _stage_joy_pad, _map_joy_pad]:
		if is_instance_valid(p) and p.has_meta("reset_joy_fn"):
			(p.get_meta("reset_joy_fn") as Callable).call()
	if is_instance_valid(_j_world_touch_pad) and _j_world_touch_pad.has_meta("reset_world_touch_fn"):
		(_j_world_touch_pad.get_meta("reset_world_touch_fn") as Callable).call()
	if is_instance_valid(_map_stage):
		_map_stage.set_touch_move(Vector2.ZERO)
	if is_instance_valid(_journey_world):
		_journey_world.set_touch_move(Vector2.ZERO)
	if is_instance_valid(_player):
		_player.set_touch_move_x(0.0)
		_player.set_touch_down_held(false)


func _circle_poly(radius: float, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps):
		var a := (float(i) / float(steps)) * TAU
		pts.append(Vector2(cos(a) * radius, sin(a) * radius))
	return pts


func _make_white_card_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.985)
	sb.border_color = Color(0.96, 0.88, 0.80, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(30)
	sb.shadow_color = Color(0.18, 0.08, 0.02, 0.18)
	sb.shadow_size = 28
	sb.shadow_offset = Vector2(0, 12)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 24
	sb.content_margin_bottom = 30
	return sb


func _make_badge_pill(title_txt: String, _pill_bg: Color, text_col: Color) -> Array:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var lbl := Label.new()
	lbl.text = title_txt
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(lbl, GameFonts.readex_bold(), 18, text_col)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.94))
	lbl.add_theme_constant_override("outline_size", 5)
	pc.add_child(lbl)
	return [pc, lbl]


func _make_stat_chip(_bg: Color, _border_col: Color, icon_tex: Texture2D, text_col: Color, with_heart: bool = false) -> Array:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pc.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.layout_direction = Control.LAYOUT_DIRECTION_LTR
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(hb)

	if icon_tex != null:
		var tr := TextureRect.new()
		tr.texture = icon_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(28, 28)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(tr)
	elif with_heart:
		var hw := Control.new()
		hw.custom_minimum_size = Vector2(26, 24)
		hw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hp := Polygon2D.new()
		hp.polygon = PackedVector2Array([
			Vector2(0, 7), Vector2(-10, -2), Vector2(-9, -8),
			Vector2(-4, -10), Vector2(0, -5), Vector2(4, -10),
			Vector2(9, -8), Vector2(10, -2),
		])
		hp.position = Vector2(12, 11)
		hp.color = Color(0.95, 0.22, 0.34, 1.0)
		hw.add_child(hp)
		hb.add_child(hw)

	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFonts.apply_rtl_label(lbl, GameFonts.readex_bold(), 20, text_col)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.94))
	lbl.add_theme_constant_override("outline_size", 6)
	hb.add_child(lbl)
	return [pc, lbl]


func _style_cardless_label(lbl: Label, out_sz: int = 7) -> void:
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.95))
	lbl.add_theme_constant_override("outline_size", out_sz)


func _sync_wallet_labels() -> void:
	if not is_instance_valid(_progress):
		return
	var bal := _progress.total_coins
	if is_instance_valid(_hub_wallet_lbl):
		_hub_wallet_lbl.text = "%d" % bal
	if is_instance_valid(_map_wallet_lbl):
		_map_wallet_lbl.text = "%d" % bal
	if is_instance_valid(_choice_wallet_lbl):
		_choice_wallet_lbl.text = Loc.t("wallet_fmt") % bal


func _build_modals() -> void:
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = 18
	_modal_layer.visible = false
	_modal_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_modal_layer)

	_modal_dim = ColorRect.new()
	_modal_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_dim.color = Color(0.05, 0.08, 0.16, 0.44)
	_modal_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(_modal_dim)

	var modal_center := CenterContainer.new()
	modal_center.layout_direction = Control.LAYOUT_DIRECTION_LTR
	modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_layer.add_child(modal_center)

	# Cardless floating UI directly over blurred backdrop (zero opaque white box container!)
	var cardless_style := StyleBoxEmpty.new()
	cardless_style.content_margin_left = 18
	cardless_style.content_margin_right = 18
	cardless_style.content_margin_top = 12
	cardless_style.content_margin_bottom = 16
	var float_title_col := Color.WHITE
	var float_sub_col := Color(0.95, 0.93, 0.86)
	var icon_revive_tex := load("res://assets/textures/ui/icon_revive_white.png")
	var icon_skip_tex := load("res://assets/textures/ui/icon_skip_white.png")
	var chip_bg := Color(0.08, 0.12, 0.22, 0.78)
	var chip_bd := Color(1.0, 0.72, 0.24, 0.65)
	var chip_txt := Color.WHITE

	# 1. GAME OVER OVERLAY (CARDLESS)
	_gameover_card = PanelContainer.new()
	_gameover_card.custom_minimum_size = Vector2(680, 440)
	_gameover_card.pivot_offset = Vector2(340, 220)
	_gameover_card.add_theme_stylebox_override("panel", cardless_style)
	modal_center.add_child(_gameover_card)

	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 16)
	_gameover_card.add_child(gv)

	var go_hdr := HBoxContainer.new()
	go_hdr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	gv.add_child(go_hdr)
	var go_back := GameFonts.make_orange_circle_btn(64.0, "res://assets/textures/ui/icon_back_white.png")
	go_back.pressed.connect(func(): _close_modal_with_anim(_gameover_card, _enter_home_hub))
	go_hdr.add_child(go_back)
	var go_sp := Control.new(); go_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; go_hdr.add_child(go_sp)
	var go_badge := _make_badge_pill(Loc.t("lose_badge_hit"), Color.TRANSPARENT, Color(1.0, 0.65, 0.60))
	_gameover_badge_lbl = go_badge[1]
	_gameover_badge_lbl.visible = false
	go_hdr.add_child(go_badge[0])

	_gameover_title_lbl = Label.new()
	_gameover_title_lbl.text = Loc.t("lose_badge_hit")
	_gameover_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gameover_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameFonts.apply_rtl_label(_gameover_title_lbl, GameFonts.lalezar(), 48, float_title_col)
	_style_cardless_label(_gameover_title_lbl, 8)
	gv.add_child(_gameover_title_lbl)

	_gameover_sub_lbl = Label.new()
	_gameover_sub_lbl.text = Loc.t("lose_title")
	_gameover_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gameover_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameFonts.apply_rtl_label(_gameover_sub_lbl, GameFonts.readex_bold(), 21, float_sub_col)
	_style_cardless_label(_gameover_sub_lbl, 6)
	gv.add_child(_gameover_sub_lbl)

	var go_chips := HBoxContainer.new()
	go_chips.alignment = BoxContainer.ALIGNMENT_CENTER
	go_chips.add_theme_constant_override("separation", 24)
	gv.add_child(go_chips)
	var go_c_chip := _make_stat_chip(chip_bg, chip_bd, _icon_coin_tex, chip_txt)
	_go_coins_lbl = go_c_chip[1]
	go_chips.add_child(go_c_chip[0])
	var go_t_chip := _make_stat_chip(chip_bg, chip_bd, null, chip_txt)
	_go_time_lbl = go_t_chip[1]
	go_chips.add_child(go_t_chip[0])

	_gameover_stats_lbl = Label.new()
	_gameover_stats_lbl.visible = false
	gv.add_child(_gameover_stats_lbl)

	var btn_col := VBoxContainer.new()
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_col.add_theme_constant_override("separation", 16)
	gv.add_child(btn_col)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	btn_col.add_child(btn_row)

	_gameover_retry_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_try_again"), 336.0, 84.0, 25)
	_gameover_retry_btn.pressed.connect(func(): _close_modal_with_anim(_gameover_card, _restart_from_modal))
	btn_row.add_child(_gameover_retry_btn)

	_gameover_revive_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_revive_reward"), 295.0, 74.0, 21)
	_gameover_revive_btn.icon = icon_revive_tex
	_gameover_revive_btn.expand_icon = true
	_gameover_revive_btn.add_theme_constant_override("icon_max_width", 26)
	_gameover_revive_btn.pressed.connect(_on_revive_requested)
	btn_row.add_child(_gameover_revive_btn)

	var btn_row2 := HBoxContainer.new()
	btn_row2.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row2.add_theme_constant_override("separation", 18)
	btn_col.add_child(btn_row2)

	_gameover_skip_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_skip_reward"), 356.0, 84.0, 23)
	_gameover_skip_btn.icon = icon_skip_tex
	_gameover_skip_btn.expand_icon = true
	_gameover_skip_btn.add_theme_constant_override("icon_max_width", 26)
	_gameover_skip_btn.pressed.connect(func(): _on_skip_requested(_gameover_card))
	btn_row2.add_child(_gameover_skip_btn)

	_gameover_home_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_home"), 336.0, 84.0, 24, true)
	_gameover_home_btn.pressed.connect(func(): _close_modal_with_anim(_gameover_card, _enter_home_hub))
	btn_row2.add_child(_gameover_home_btn)

	# 2. VICTORY OVERLAY (CARDLESS)
	_victory_card = PanelContainer.new()
	_victory_card.custom_minimum_size = Vector2(820, 420)
	_victory_card.pivot_offset = Vector2(410, 210)
	_victory_card.add_theme_stylebox_override("panel", cardless_style)
	modal_center.add_child(_victory_card)

	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 16)
	_victory_card.add_child(vv)

	var vi_hdr := HBoxContainer.new()
	vi_hdr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vv.add_child(vi_hdr)
	var vi_back := GameFonts.make_orange_circle_btn(64.0, "res://assets/textures/ui/icon_back_white.png")
	vi_back.pressed.connect(func(): _close_modal_with_anim(_victory_card, _enter_home_hub))
	vi_hdr.add_child(vi_back)
	var vi_sp := Control.new(); vi_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vi_hdr.add_child(vi_sp)
	var vi_badge := _make_badge_pill(Loc.t("win_badge"), Color.TRANSPARENT, Color(1.0, 0.88, 0.45))
	_victory_badge_lbl = vi_badge[1]
	vi_hdr.add_child(vi_badge[0])

	_victory_title_lbl = Label.new()
	_victory_title_lbl.text = Loc.t("win_title")
	_victory_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameFonts.apply_rtl_label(_victory_title_lbl, GameFonts.lalezar(), 54, float_title_col)
	_style_cardless_label(_victory_title_lbl, 8)
	vv.add_child(_victory_title_lbl)

	var win_chips := HBoxContainer.new()
	win_chips.alignment = BoxContainer.ALIGNMENT_CENTER
	win_chips.add_theme_constant_override("separation", 20)
	vv.add_child(win_chips)
	var w_lvl_c := _make_stat_chip(chip_bg, chip_bd, _icon_crown_tex, chip_txt)
	_win_lvl_lbl = w_lvl_c[1]
	win_chips.add_child(w_lvl_c[0])
	var w_time_c := _make_stat_chip(chip_bg, chip_bd, null, chip_txt)
	_win_time_lbl = w_time_c[1]
	win_chips.add_child(w_time_c[0])
	var w_coin_c := _make_stat_chip(chip_bg, chip_bd, _icon_coin_tex, chip_txt)
	_win_coins_lbl = w_coin_c[1]
	win_chips.add_child(w_coin_c[0])
	var w_hrt_c := _make_stat_chip(chip_bg, chip_bd, _tex_stage_heart_full, chip_txt)
	_win_hearts_lbl = w_hrt_c[1]
	win_chips.add_child(w_hrt_c[0])

	_victory_stats_lbl = Label.new()
	_victory_stats_lbl.visible = false
	vv.add_child(_victory_stats_lbl)

	var vbtns := HBoxContainer.new()
	vbtns.alignment = BoxContainer.ALIGNMENT_CENTER
	vbtns.add_theme_constant_override("separation", 16)
	vv.add_child(vbtns)

	_next_lvl_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_next_lvl"), 245.0, 72.0, 21)
	_next_lvl_btn.pressed.connect(_on_next_lvl_btn_pressed)
	vbtns.add_child(_next_lvl_btn)

	_victory_again_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_play_again"), 220.0, 72.0, 21)
	_victory_again_btn.pressed.connect(func(): _close_modal_with_anim(_victory_card, _restart_from_modal))
	vbtns.add_child(_victory_again_btn)

	_victory_home_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_home"), 265.0, 82.0, 23, true)
	_victory_home_btn.pressed.connect(func(): _close_modal_with_anim(_victory_card, _enter_home_hub))
	vbtns.add_child(_victory_home_btn)

	# 3. PAUSE OVERLAY (CARDLESS)
	_pause_card = PanelContainer.new()
	_pause_card.custom_minimum_size = Vector2(720, 400)
	_pause_card.pivot_offset = Vector2(360, 200)
	_pause_card.add_theme_stylebox_override("panel", cardless_style)
	modal_center.add_child(_pause_card)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 18)
	_pause_card.add_child(pv)

	var pa_hdr := HBoxContainer.new()
	pa_hdr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	pv.add_child(pa_hdr)
	var pa_back := GameFonts.make_orange_circle_btn(64.0, "res://assets/textures/ui/icon_back_white.png")
	pa_back.pressed.connect(_resume_from_pause)
	pa_hdr.add_child(pa_back)
	var pa_sp := Control.new(); pa_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; pa_hdr.add_child(pa_sp)
	var pa_badge := _make_badge_pill(Loc.t("pause_badge"), Color.TRANSPARENT, Color(1.0, 0.88, 0.45))
	_pause_badge_lbl = pa_badge[1]
	_pause_badge_lbl.visible = false
	pa_hdr.add_child(pa_badge[0])

	_pause_title_lbl = Label.new()
	_pause_title_lbl.text = Loc.t("pause_title")
	_pause_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameFonts.apply_rtl_label(_pause_title_lbl, GameFonts.lalezar(), 50, float_title_col)
	_style_cardless_label(_pause_title_lbl, 8)
	pv.add_child(_pause_title_lbl)

	var pcol := VBoxContainer.new()
	pcol.alignment = BoxContainer.ALIGNMENT_CENTER
	pcol.add_theme_constant_override("separation", 16)
	pv.add_child(pcol)

	var pbtns := HBoxContainer.new()
	pbtns.alignment = BoxContainer.ALIGNMENT_CENTER
	pbtns.add_theme_constant_override("separation", 18)
	pcol.add_child(pbtns)

	_pause_resume_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_resume"), 336.0, 84.0, 25)
	_pause_resume_btn.pressed.connect(_resume_from_pause)
	pbtns.add_child(_pause_resume_btn)

	_pause_retry_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_retry"), 336.0, 84.0, 25)
	_pause_retry_btn.pressed.connect(func(): _close_modal_with_anim(_pause_card, _restart_from_modal))
	pbtns.add_child(_pause_retry_btn)

	var pbtns2 := HBoxContainer.new()
	pbtns2.alignment = BoxContainer.ALIGNMENT_CENTER
	pbtns2.add_theme_constant_override("separation", 18)
	pcol.add_child(pbtns2)

	_pause_skip_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_skip_reward"), 356.0, 84.0, 23)
	_pause_skip_btn.icon = icon_skip_tex
	_pause_skip_btn.expand_icon = true
	_pause_skip_btn.add_theme_constant_override("icon_max_width", 26)
	_pause_skip_btn.pressed.connect(func(): _on_skip_requested(_pause_card))
	pbtns2.add_child(_pause_skip_btn)

	_pause_home_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_home"), 336.0, 84.0, 24, true)
	_pause_home_btn.pressed.connect(func(): _close_modal_with_anim(_pause_card, _enter_home_hub))
	pbtns2.add_child(_pause_home_btn)

	# 4. DUAL COIN WALLET OR WATCH-AD CHOICE OVERLAY (CARDLESS)
	_choice_card = PanelContainer.new()
	_choice_card.custom_minimum_size = Vector2(700, 340)
	_choice_card.pivot_offset = Vector2(350, 170)
	_choice_card.add_theme_stylebox_override("panel", cardless_style)
	modal_center.add_child(_choice_card)

	var chv := VBoxContainer.new()
	chv.add_theme_constant_override("separation", 16)
	_choice_card.add_child(chv)

	var ch_hdr := HBoxContainer.new()
	ch_hdr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	chv.add_child(ch_hdr)
	_choice_back_btn = GameFonts.make_orange_circle_btn(64.0, "res://assets/textures/ui/icon_back_white.png")
	_choice_back_btn.pressed.connect(_close_choice_and_cancel)
	ch_hdr.add_child(_choice_back_btn)
	var ch_sp := Control.new(); ch_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ch_hdr.add_child(ch_sp)
	var ch_wchip := _make_stat_chip(chip_bg, chip_bd, _icon_coin_tex, chip_txt)
	_choice_wallet_lbl = ch_wchip[1]
	ch_hdr.add_child(ch_wchip[0])

	_choice_title_lbl = Label.new()
	_choice_title_lbl.text = Loc.t("choice_revive_title")
	_choice_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameFonts.apply_rtl_label(_choice_title_lbl, GameFonts.lalezar(), 46, float_title_col)
	_style_cardless_label(_choice_title_lbl, 8)
	chv.add_child(_choice_title_lbl)

	_choice_hint_lbl = Label.new()
	_choice_hint_lbl.text = ""
	_choice_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameFonts.apply_rtl_label(_choice_hint_lbl, GameFonts.readex_bold(), 20, Color(1.0, 0.90, 0.56))
	_style_cardless_label(_choice_hint_lbl, 5)
	chv.add_child(_choice_hint_lbl)

	var ch_row := HBoxContainer.new()
	ch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ch_row.add_theme_constant_override("separation", 18)
	chv.add_child(ch_row)

	_choice_ad_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_watch_ad"), 295.0, 72.0, 21)
	_choice_ad_btn.icon = icon_revive_tex
	_choice_ad_btn.expand_icon = true
	_choice_ad_btn.add_theme_constant_override("icon_max_width", 26)
	_choice_ad_btn.pressed.connect(func():
		var cb := _choice_ad_cb
		_close_modal_with_anim(_choice_card, func():
			if cb.is_valid():
				cb.call()
		)
	)
	ch_row.add_child(_choice_ad_btn)

	_choice_coins_btn = GameFonts.make_orange_pill_btn(Loc.t("btn_use_coins_fmt") % 100, 305.0, 72.0, 21, true)
	_choice_coins_btn.icon = _icon_coin_tex
	_choice_coins_btn.expand_icon = true
	_choice_coins_btn.add_theme_constant_override("icon_max_width", 26)
	_choice_coins_btn.pressed.connect(_on_choice_coins_pressed)
	ch_row.add_child(_choice_coins_btn)

	_update_modal_card_widths()


func _update_modal_card_widths() -> void:
	var vp_w := get_viewport().get_visible_rect().size.x
	if vp_w <= 1.0:
		return
	var max_w := maxf(320.0, vp_w - 32.0)
	if is_instance_valid(_gameover_card):
		_gameover_card.custom_minimum_size.x = minf(780.0, max_w)
	if is_instance_valid(_victory_card):
		_victory_card.custom_minimum_size.x = minf(860.0, max_w)
	if is_instance_valid(_pause_card):
		_pause_card.custom_minimum_size.x = minf(780.0, max_w)
	if is_instance_valid(_choice_card):
		_choice_card.custom_minimum_size.x = minf(700.0, max_w)


func _hide_all_modals_except(keep: String = "") -> void:
	if keep != "lang" and is_instance_valid(_lang_layer):
		_lang_layer.visible = false
	if keep != "modal" and is_instance_valid(_modal_layer):
		_modal_layer.visible = false
		if is_instance_valid(_gameover_card):
			_gameover_card.visible = false
		if is_instance_valid(_victory_card):
			_victory_card.visible = false
		if is_instance_valid(_pause_card):
			_pause_card.visible = false
		if is_instance_valid(_choice_card):
			_choice_card.visible = false
	if keep == "" and is_instance_valid(_blur_rect):
		_blur_rect.visible = false


func apply_language_refresh() -> void:
	DisplayServer.window_set_title(Loc.t("game_title"))
	var dir := Loc.dir_layout()
	for b in [
		_hub_btn_chars, _hub_btn_map, _hub_btn_play, _map_play_btn, _chars_play_btn,
		_gameover_retry_btn, _gameover_revive_btn, _gameover_skip_btn, _gameover_home_btn,
		_next_lvl_btn, _victory_again_btn, _victory_home_btn,
		_pause_resume_btn, _pause_retry_btn, _pause_skip_btn, _pause_home_btn,
		_choice_ad_btn, _choice_coins_btn
	]:
		if is_instance_valid(b):
			b.layout_direction = dir
	for lbl in [
		_gameover_badge_lbl, _gameover_title_lbl, _gameover_sub_lbl, _gameover_stats_lbl,
		_go_coins_lbl, _go_time_lbl,
		_victory_badge_lbl, _victory_title_lbl, _victory_stats_lbl,
		_win_lvl_lbl, _win_time_lbl, _win_coins_lbl, _win_hearts_lbl,
		_pause_badge_lbl, _pause_title_lbl, _j_banner_lbl,
		_choice_title_lbl, _choice_wallet_lbl, _choice_hint_lbl, _map_hint_lbl
	]:
		if is_instance_valid(lbl):
			lbl.layout_direction = dir

	_hub_btn_chars.text = Loc.t("btn_chars")
	_hub_btn_map.text = Loc.t("btn_map")
	_hub_btn_play.text = Loc.t("btn_play")
	if is_instance_valid(_chars_play_btn):
		_chars_play_btn.text = Loc.t("btn_play")
	if is_instance_valid(_map_hint_lbl):
		_map_hint_lbl.text = Loc.t("map_walk_hint")
	for i in range(mini(3, _chars_name_lbls.size())):
		_chars_name_lbls[i].layout_direction = dir
		_chars_name_lbls[i].text = Loc.hero_name(CHAR_IDS[i])

	_gameover_badge_lbl.text = Loc.t("lose_badge_hit")
	_gameover_title_lbl.text = Loc.t("lose_badge_hit")
	if is_instance_valid(_gameover_sub_lbl):
		_gameover_sub_lbl.text = Loc.t("lose_title")
	_gameover_retry_btn.text = Loc.t("btn_try_again")
	_gameover_revive_btn.text = Loc.t("btn_revive_reward")
	_gameover_skip_btn.text = Loc.t("btn_skip_journey_reward") if _was_in_journey_before_pause else Loc.t("btn_skip_reward")
	_gameover_home_btn.text = Loc.t("btn_home")
	if _won_during_journey:
		_victory_badge_lbl.text = Loc.t("journey_win_badge")
		_victory_title_lbl.text = Loc.t("journey_win_title")
	else:
		_victory_badge_lbl.text = Loc.t("win_badge")
		_victory_title_lbl.text = Loc.t("win_title")
	_sync_next_lvl_btn_appearance()
	_victory_again_btn.text = Loc.t("btn_play_again")
	_victory_home_btn.text = Loc.t("btn_home")
	_pause_badge_lbl.text = Loc.t("pause_badge")
	_pause_title_lbl.text = Loc.t("pause_title")
	_pause_resume_btn.text = Loc.t("btn_resume")
	_pause_retry_btn.text = Loc.t("btn_retry")
	_pause_skip_btn.text = Loc.t("btn_skip_journey_reward") if _was_in_journey_before_pause else Loc.t("btn_skip_reward")
	_pause_home_btn.text = Loc.t("btn_home")
	if is_instance_valid(_choice_ad_btn):
		_choice_ad_btn.text = Loc.t("btn_watch_ad")
	if is_instance_valid(_choice_coins_btn):
		_choice_coins_btn.text = Loc.t("btn_use_coins_fmt") % _choice_cost
	if is_instance_valid(_choice_title_lbl):
		_choice_title_lbl.text = Loc.t("choice_revive_title") if _choice_mode == "revive" else Loc.t("choice_skip_title")
	_sync_wallet_labels()
	if is_instance_valid(_j_banner_lbl):
		_j_banner_lbl.text = Loc.journey_banner_text(_journey_to_lvl)
	_refresh_map_pins()
	if _backdrop:
		_backdrop.set_character_name(selected_character_id)
	if is_instance_valid(_level_builder) and _level_builder.has_method("update_language"):
		_level_builder.update_language()
	if is_instance_valid(_journey_world) and _journey_world.has_method("update_language"):
		_journey_world.update_language()
	if is_instance_valid(_lang_badge_lbl):
		_lang_badge_lbl.layout_direction = dir
		_lang_badge_lbl.text = Loc.t("lang_badge")
	if is_instance_valid(_lang_title_lbl):
		_lang_title_lbl.layout_direction = dir
		_lang_title_lbl.text = Loc.t("lang_title")
	if is_instance_valid(_lang_btn_flag):
		_lang_btn_flag.texture = load("res://assets/textures/ui/flag_%s.png" % Loc.get_lang())
	_refresh_lang_rows()


func _open_spend_or_ad_choice(mode: String, cost: int, on_ad: Callable, on_coin: Callable, on_cancel: Callable) -> void:
	_choice_mode = mode
	_choice_cost = cost
	_choice_ad_cb = on_ad
	_choice_coin_cb = on_coin
	_choice_cancel_cb = on_cancel
	var dir := Loc.dir_layout()
	_choice_title_lbl.layout_direction = dir
	_choice_title_lbl.text = Loc.t("choice_revive_title") if mode == "revive" else Loc.t("choice_skip_title")
	_choice_ad_btn.layout_direction = dir
	_choice_ad_btn.text = Loc.t("btn_watch_ad")
	_choice_coins_btn.layout_direction = dir
	_choice_coins_btn.text = Loc.t("btn_use_coins_fmt") % cost
	_sync_wallet_labels()
	var affordable := _progress.can_afford(cost)
	_choice_coins_btn.modulate = Color.WHITE if affordable else Color(0.85, 0.85, 0.88, 0.72)
	_choice_hint_lbl.layout_direction = dir
	_choice_hint_lbl.text = "" if affordable else (Loc.t("need_coins_fmt") % cost)
	_animate_modal_open(_choice_card, 2.3)


func _on_choice_coins_pressed() -> void:
	if _progress.can_afford(_choice_cost):
		_progress.spend_coins(_choice_cost)
		_sync_wallet_labels()
		var cb := _choice_coin_cb
		_close_modal_with_anim(_choice_card, func():
			if cb.is_valid():
				cb.call()
		)
	else:
		_audio.play("hit", 1.15, -10.0)
		_choice_hint_lbl.text = Loc.t("need_coins_fmt") % _choice_cost
		_choice_coins_btn.pivot_offset = _choice_coins_btn.size * 0.5
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_choice_coins_btn, "rotation_degrees", -6.0, 0.06)
		tw.tween_property(_choice_coins_btn, "rotation_degrees", 6.0, 0.08)
		tw.tween_property(_choice_coins_btn, "rotation_degrees", 0.0, 0.06)


func _close_choice_and_cancel() -> void:
	var cb := _choice_cancel_cb
	_close_modal_with_anim(_choice_card, func():
		if cb.is_valid():
			cb.call()
	)


func _animate_modal_open(card: PanelContainer, blur_val: float) -> void:
	_closing_modal = false
	_hide_all_modals_except("modal")
	_update_modal_card_widths()
	if _modal_tween and _modal_tween.is_valid():
		_modal_tween.kill()
	_blur_rect.visible = true
	if _blur_mat and not OS.has_feature("mobile"):
		_blur_mat.set_shader_parameter("blur_amount", blur_val)
	_modal_layer.visible = true
	_gameover_card.visible = (card == _gameover_card)
	_victory_card.visible = (card == _victory_card)
	_pause_card.visible = (card == _pause_card)
	if is_instance_valid(_choice_card):
		_choice_card.visible = (card == _choice_card)

	_modal_dim.modulate.a = 0.0
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.84, 0.84)
	card.modulate.a = 0.0
	_modal_tween = create_tween()
	_modal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_modal_tween.set_parallel(true)
	_modal_tween.tween_property(_modal_dim, "modulate:a", 1.0, 0.20)
	_modal_tween.tween_property(card, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_modal_tween.tween_property(card, "modulate:a", 1.0, 0.20)


func _close_modal_with_anim(card: PanelContainer, on_done: Callable) -> void:
	if _closing_modal:
		return
	_closing_modal = true
	_audio.play("click", 1.1, -10.0)
	if _modal_tween and _modal_tween.is_valid():
		_modal_tween.kill()
	_modal_tween = create_tween()
	_modal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_modal_tween.set_parallel(true)
	_modal_tween.tween_property(card, "scale", Vector2(0.82, 0.82), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_modal_tween.tween_property(card, "modulate:a", 0.0, 0.16)
	_modal_tween.tween_property(_modal_dim, "modulate:a", 0.0, 0.18)
	_modal_tween.chain().tween_callback(func():
		_closing_modal = false
		_modal_layer.visible = false
		card.visible = false
		_blur_rect.visible = false
		if _blur_mat and not OS.has_feature("mobile"):
			_blur_mat.set_shader_parameter("blur_amount", 0.0)
		on_done.call()
	)


func _set_pause_btn_icon(paused_mode: bool) -> void:
	for pb: Button in [_pause_btn, _j_pause_btn]:
		if not is_instance_valid(pb):
			continue
		var ico := pb.find_child("Icon", true, false) as TextureRect
		if ico:
			ico.texture = _icon_play_tex if paused_mode else _icon_pause_tex
		var tw := pb.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(pb, "rotation_degrees", 360.0 if paused_mode else 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ==============================================================================
# STATE TRANSITIONS
# ==============================================================================

func _on_title_start_requested() -> void:
	_enter_home_hub()


func _bank_current_run_coins(from_journey: bool) -> void:
	if not is_instance_valid(_progress):
		return
	var raw := 0
	if from_journey and is_instance_valid(_journey_world):
		raw = _journey_world.journey_coins
	elif is_instance_valid(_player):
		raw = _player.gems
	var delta := maxi(0, raw - _banked_run_coins)
	if delta > 0:
		_progress.add_coins(delta)
		_banked_run_coins += delta
	_sync_wallet_labels()


func _enter_home_hub() -> void:
	_bank_current_run_coins(is_instance_valid(_journey_world))
	get_tree().paused = false
	_audio.set_paused_duck(false)
	_set_pause_btn_icon(false)
	if is_instance_valid(_ad_service):
		_ad_service.abort_flow()
	_exit_journey_cleanup()
	if is_instance_valid(_map_stage):
		_map_stage.visible = false
	_was_in_journey_before_pause = false
	_won_during_journey = false
	_panoramic_revive_t = -1.0
	if is_instance_valid(_white_fog_layer):
		_white_fog_layer.visible = false
	state = GameState.HOME_HUB
	if _level_dirty:
		_rebuild_level(_progress.selected_level)
	_backdrop.set_level_theme(_progress.selected_level)
	_backdrop.set_character_name(selected_character_id)
	_backdrop.set_intro_blur(0.0)
	_backdrop.visible = true
	if is_instance_valid(_backdrop.world_env):
		_backdrop.world_env.environment = _backdrop.env_res
	if is_instance_valid(_level_holder):
		_level_holder.visible = true
	if is_instance_valid(_player):
		_player.visible = true
		_player.is_dead = false
		_player.is_victory = false
		_player.active = false
		if is_instance_valid(_player.char_vis):
			_player.char_vis.clear_sad_sit()
			_player.char_vis.position = Vector3.ZERO
			_player.char_vis.rotation_degrees = Vector3.ZERO
			_player.char_vis.scale = Vector3.ONE
			_player.char_vis.play_anim("idle", 1.0, 0.0)
	_hide_all_modals_except("")
	if is_instance_valid(_audio_drawer):
		_audio_drawer.visible = false
	_hud_layer.visible = false
	_chars_layer.visible = false
	_map_layer.visible = false
	_hub_layer.visible = true
	_sync_audio_ui()
	_sync_wallet_labels()
	_update_modal_card_widths()
	_cam_pos_cur = Vector3(_player.global_position.x + 1.85, 1.72, 5.55)
	_cam_look_cur = Vector3(_player.global_position.x + 0.75, 0.88, -0.3)
	_camera.position = _cam_pos_cur
	_camera.look_at(_cam_look_cur)
	_audio.start_title_bgm()


func _enter_characters_page() -> void:
	_bank_current_run_coins(is_instance_valid(_journey_world))
	_audio.play("click", 1.05, -10.0)
	_exit_journey_cleanup()
	_hide_all_modals_except("")
	if is_instance_valid(_audio_drawer):
		_audio_drawer.visible = false
	state = GameState.CHARACTERS_PAGE
	_hub_layer.visible = false
	_hud_layer.visible = false
	_map_layer.visible = false
	if is_instance_valid(_map_stage):
		_map_stage.visible = false
	_backdrop.visible = true
	if is_instance_valid(_backdrop.world_env):
		_backdrop.world_env.environment = _backdrop.env_res
	if is_instance_valid(_level_holder):
		_level_holder.visible = true
	if is_instance_valid(_player):
		_player.visible = true
		_player.active = false
		if is_instance_valid(_player.char_vis):
			_player.char_vis.clear_sad_sit()
			_player.char_vis.play_anim("idle", 1.0, 0.0)
	_backdrop.set_intro_blur(0.0)
	_chars_yaws = [0.0, 0.0, 0.0]
	_chars_drag_idx = -1
	_chars_touch_fid = -1
	_update_char_ring_highlights()
	for m in _chars_models:
		if is_instance_valid(m):
			m.clear_sad_sit()
			m.rotation_degrees.y = -90.0
			m.play_anim("idle", 1.0, 0.0)
	_camera.position = Vector3(-120.0, 1.85, 6.20)
	_camera.look_at(Vector3(-120.0, 0.85, -0.25))
	_chars_layer.visible = true
	_update_characters_page_ui()


func _enter_map_page() -> void:
	_bank_current_run_coins(is_instance_valid(_journey_world))
	_audio.play("click", 1.05, -10.0)
	_exit_journey_cleanup()
	_hide_all_modals_except("")
	if is_instance_valid(_audio_drawer):
		_audio_drawer.visible = false
	_progress.selected_level = clampi(_progress.selected_level, 1, _progress.unlocked_level)
	state = GameState.MAP_PAGE
	_hub_layer.visible = false
	_hud_layer.visible = false
	_chars_layer.visible = false
	_backdrop.visible = false
	_backdrop.set_intro_blur(0.0)
	if is_instance_valid(_backdrop.world_env):
		_backdrop.world_env.environment = null
	if is_instance_valid(_level_holder):
		_level_holder.visible = false
	if is_instance_valid(_player):
		_player.visible = false
		if is_instance_valid(_player.char_vis):
			_player.char_vis.clear_sad_sit()
	if is_instance_valid(_map_stage):
		_map_stage.visible = true
		_map_stage.refresh_state(_progress.unlocked_level, _progress.selected_level, selected_character_id, true)
		var hp := _map_stage.get_hero_global_pos()
		_camera.position = hp + Vector3(0.0, 5.8, 10.8)
		_camera.look_at(hp + Vector3(0.0, 1.3, -13.0))
	_sync_wallet_labels()
	_refresh_map_pins()
	_map_layer.visible = true
	_update_map_pins_layout()


func _start_run_from_hub() -> void:
	if state != GameState.HOME_HUB:
		return
	if is_instance_valid(_audio_drawer):
		_audio_drawer.visible = false
	_audio.play("click", 1.0, -8.0)
	_hub_layer.visible = false
	_launch_selected_level()


func _launch_selected_level() -> void:
	var target := clampi(_progress.selected_level, 1, GameProgress.IMPLEMENTED_LEVELS)
	if _progress.needs_journey_to(target):
		_start_kingdom_journey(target - 1, target)
	else:
		_rebuild_level(target)
		_start_stage_direct()


func _exit_journey_cleanup() -> void:
	_reset_joy_knob()
	if is_instance_valid(_journey_world):
		_journey_world.queue_free()
		_journey_world = null
		_level_dirty = true
	if is_instance_valid(_journey_hud_layer):
		_journey_hud_layer.visible = false
	if is_instance_valid(_white_fog_layer):
		_white_fog_layer.visible = false
	if is_instance_valid(_backdrop):
		_backdrop.visible = true
		_backdrop.process_mode = Node.PROCESS_MODE_PAUSABLE
		if is_instance_valid(_backdrop.world_env):
			_backdrop.world_env.environment = _backdrop.env_res
		if is_instance_valid(_backdrop.sun_light):
			_backdrop.sun_light.visible = true
	if is_instance_valid(_level_holder):
		_level_holder.visible = true
	if is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		_player.set_physics_process(true)
		_player.visible = true


func _start_kingdom_journey(from_lvl: int, to_lvl: int) -> void:
	get_tree().paused = false
	_audio.set_paused_duck(false)
	_set_pause_btn_icon(false)
	if is_instance_valid(_ad_service):
		_ad_service.abort_flow()
	_exit_journey_cleanup()
	if is_instance_valid(_map_stage):
		_map_stage.visible = false

	for c in _level_holder.get_children():
		c.queue_free()
	for p in _particles_layer.get_children():
		if p is ParticlePool3D:
			(p as ParticlePool3D).clear_all()
		else:
			p.queue_free()
	_level_dirty = true
	_player.active = false
	_player.visible = false
	_player.set_physics_process(false)
	_player.process_mode = Node.PROCESS_MODE_DISABLED

	_backdrop.visible = false
	_backdrop.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(_backdrop.world_env):
		_backdrop.world_env.environment = null
	if is_instance_valid(_backdrop.sun_light):
		_backdrop.sun_light.visible = false

	_hub_layer.visible = false
	_chars_layer.visible = false
	_map_layer.visible = false
	_hud_layer.visible = false
	_hide_all_modals_except("")
	if _blur_mat and not OS.has_feature("mobile"):
		_blur_mat.set_shader_parameter("blur_amount", 0.0)

	_journey_from_lvl = from_lvl
	_journey_to_lvl = to_lvl
	_won_during_journey = false
	_was_in_journey_before_pause = false
	_banked_run_coins = 0
	_run_time = 0.0

	_j_banner_lbl.layout_direction = Loc.dir_layout()
	_j_banner_lbl.text = Loc.journey_banner_text(to_lvl)
	_j_prev_hp = 6
	for jh: TextureRect in _j_hearts:
		if is_instance_valid(jh):
			jh.texture = _tex_jheart_full
			jh.scale = Vector2.ONE
			jh.rotation_degrees = 0.0
			jh.modulate = Color.WHITE
	_on_journey_hp_changed(6, 6)
	_on_journey_coins_changed(0)
	_on_journey_mc_inventory(0, 0, 0)
	if is_instance_valid(_j_toast_lbl):
		_j_toast_lbl.modulate.a = 0.0
	_journey_hud_layer.visible = true

	_journey_world = KingdomJourneyWorld.new()
	_journey_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	_journey_world.setup(from_lvl, to_lvl, selected_character_id, _audio, _camera)
	_journey_world.hero_hp_changed.connect(_on_journey_hp_changed)
	_journey_world.coins_changed.connect(_on_journey_coins_changed)
	_journey_world.dest_entered_fog.connect(_on_journey_dest_fog)
	_journey_world.journey_completed.connect(_on_journey_completed)
	_journey_world.journey_failed.connect(_on_journey_failed)
	_journey_world.mc_inventory_changed.connect(_on_journey_mc_inventory)
	_journey_world.mc_toast.connect(_on_journey_mc_toast)
	_journey_world.intro_finished.connect(func():
		_on_journey_mc_toast(Loc.t("mc_hint_gather"))
	)
	add_child(_journey_world)

	state = GameState.JOURNEY
	_audio.start_bgm()


func _start_stage_direct() -> void:
	# Direct stage start on single Play tap: controls active immediately, camera glides smoothly in _process
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	get_tree().paused = false
	_audio.set_paused_duck(false)
	_set_pause_btn_icon(false)
	_reset_joy_knob()
	if is_instance_valid(_map_stage):
		_map_stage.visible = false
	if _level_dirty:
		_rebuild_level(_progress.selected_level)
	_level_dirty = true
	_banked_run_coins = 0
	_hide_all_modals_except("")
	_hub_layer.visible = false
	_chars_layer.visible = false
	_map_layer.visible = false
	_journey_hud_layer.visible = false
	_hud_layer.visible = true
	_backdrop.visible = true
	if is_instance_valid(_backdrop.world_env):
		_backdrop.world_env.environment = _backdrop.env_res
	if is_instance_valid(_level_holder):
		_level_holder.visible = true
	if is_instance_valid(_player):
		_player.visible = true
	_backdrop.set_intro_blur(0.0)
	_cam_pos_cur = Vector3(_player.global_position.x + 1.85, 1.72, 5.55)
	_cam_look_cur = Vector3(_player.global_position.x + 0.75, 0.88, -0.3)
	_camera.position = _cam_pos_cur
	_camera.look_at(_cam_look_cur)
	_stage_prev_hp = _player.hp if is_instance_valid(_player) else 3
	for ht: TextureRect in _hearts_box:
		if is_instance_valid(ht):
			ht.texture = _tex_stage_heart_full
			ht.scale = Vector2.ONE
			ht.rotation_degrees = 0.0
			ht.modulate = Color.WHITE
	state = GameState.PLAYING
	_player.active = true
	_audio.start_bgm()


func _toggle_pause() -> void:
	if _closing_modal:
		return
	if state == GameState.PLAYING or state == GameState.JOURNEY:
		_reset_joy_knob()
		_was_in_journey_before_pause = (state == GameState.JOURNEY)
		state = GameState.PAUSED
		get_tree().paused = true
		_audio.set_paused_duck(true)
		_audio.play("click", 1.0, -10.0)
		_set_pause_btn_icon(true)
		if is_instance_valid(_pause_skip_btn):
			_pause_skip_btn.layout_direction = Loc.dir_layout()
			_pause_skip_btn.text = Loc.t("btn_skip_journey_reward") if _was_in_journey_before_pause else Loc.t("btn_skip_reward")
			_pause_skip_btn.visible = _was_in_journey_before_pause or (_progress.selected_level < GameProgress.IMPLEMENTED_LEVELS)
		_animate_modal_open(_pause_card, 2.2)
	elif state == GameState.PAUSED:
		_resume_from_pause()


func _resume_from_pause() -> void:
	if state != GameState.PAUSED:
		return
	_set_pause_btn_icon(false)
	_close_modal_with_anim(_pause_card, func():
		_audio.set_paused_duck(false)
		get_tree().paused = false
		if _was_in_journey_before_pause:
			state = GameState.JOURNEY
		else:
			state = GameState.PLAYING
	)


func _restart_from_modal() -> void:
	_bank_current_run_coins(is_instance_valid(_journey_world))
	_audio.play("click", 1.0, -10.0)
	_audio.set_paused_duck(false)
	_set_pause_btn_icon(false)
	if is_instance_valid(_ad_service):
		_ad_service.abort_flow()
	get_tree().paused = false
	_hide_all_modals_except("")
	if _blur_mat and not OS.has_feature("mobile"):
		_blur_mat.set_shader_parameter("blur_amount", 0.0)
	if is_instance_valid(_map_stage):
		_map_stage.visible = false
	if _was_in_journey_before_pause or _won_during_journey:
		_start_kingdom_journey(_journey_from_lvl, _journey_to_lvl)
		return
	_exit_journey_cleanup()
	_backdrop.set_intro_blur(0.0)
	_rebuild_level(_progress.selected_level)
	_level_dirty = true
	_hud_layer.visible = true
	_hub_layer.visible = false
	_chars_layer.visible = false
	_map_layer.visible = false
	_stage_prev_hp = _player.hp if is_instance_valid(_player) else 3
	for ht: TextureRect in _hearts_box:
		if is_instance_valid(ht):
			ht.texture = _tex_stage_heart_full
			ht.scale = Vector2.ONE
			ht.rotation_degrees = 0.0
			ht.modulate = Color.WHITE
	state = GameState.PLAYING
	_player.active = true
	_audio.start_bgm()


func _on_next_lvl_btn_pressed() -> void:
	if _won_during_journey:
		_won_during_journey = false
		_was_in_journey_before_pause = false
		_close_modal_with_anim(_victory_card, func():
			_exit_journey_cleanup()
			_rebuild_level(_progress.selected_level)
			_start_stage_direct()
		)
		return
	var next_lvl := mini(_progress.selected_level + 1, GameProgress.IMPLEMENTED_LEVELS)
	var from_lvl := _progress.selected_level
	_progress.selected_level = next_lvl
	_progress.save_progress()
	if _progress.needs_journey_to(next_lvl):
		_close_modal_with_anim(_victory_card, func():
			_start_kingdom_journey(from_lvl, next_lvl)
		)
	else:
		_close_modal_with_anim(_victory_card, _restart_from_modal)


func _input(event: InputEvent) -> void:
	if state == GameState.HOME_HUB and is_instance_valid(_audio_drawer) and _audio_drawer.visible:
		var press_pos := Vector2(-1.0, -1.0)
		var has_press := false
		if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			press_pos = (event as InputEventScreenTouch).position
			has_press = true
		elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				press_pos = mb.position
				has_press = true
		if has_press:
			var on_drawer := _audio_drawer.get_global_rect().grow(10.0).has_point(press_pos)
			var on_btn := is_instance_valid(_audio_btn) and _audio_btn.get_global_rect().grow(4.0).has_point(press_pos)
			if not on_drawer and not on_btn:
				_audio_drawer.visible = false

	if state == GameState.JOURNEY and is_instance_valid(_journey_world):
		if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
			var kcode := (event as InputEventKey).keycode
			if kcode == KEY_E or kcode == KEY_F:
				_journey_world.trigger_mc_build_or_mine()
				get_viewport().set_input_as_handled()
				return
			elif kcode == KEY_1:
				_journey_world.select_mc_slot(0)
				get_viewport().set_input_as_handled()
				return
			elif kcode == KEY_2:
				_journey_world.select_mc_slot(1)
				get_viewport().set_input_as_handled()
				return
		elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
			var rmb := event as InputEventMouseButton
			if rmb.button_index == MOUSE_BUTTON_RIGHT and rmb.pressed:
				_journey_world.trigger_mc_build_or_mine_at_screen(rmb.position)
				get_viewport().set_input_as_handled()
				return

	if state == GameState.PLAYING or state == GameState.JOURNEY or state == GameState.MAP_PAGE:
		if event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if not st.pressed:
				for entry in _touch_action_btns:
					if int(entry["finger"]) == st.index:
						_release_touch_btn_entry(entry, true)
						get_viewport().set_input_as_handled()
						return
		elif event is InputEventScreenDrag:
			var sd := event as InputEventScreenDrag
			for entry in _touch_action_btns:
				if int(entry["finger"]) == sd.index:
					get_viewport().set_input_as_handled()
					return
		elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				for entry in _touch_action_btns:
					if bool(entry["is_mouse"]):
						_release_touch_btn_entry(entry, true)
						get_viewport().set_input_as_handled()
						return
		for p: Control in [_stage_joy_pad, _j_joy_pad, _map_joy_pad]:
			if is_instance_valid(p) and p.is_visible_in_tree() and p.has_meta("track_joy_input_fn"):
				var fn := p.get_meta("track_joy_input_fn") as Callable
				if fn.call(event):
					get_viewport().set_input_as_handled()
					return
		if state == GameState.JOURNEY and is_instance_valid(_j_world_touch_pad) and _j_world_touch_pad.has_meta("track_world_touch_fn"):
			var wfn := _j_world_touch_pad.get_meta("track_world_touch_fn") as Callable
			if wfn.call(event):
				get_viewport().set_input_as_handled()
				return


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if _ad_service and _ad_service.is_showing_native_ad():
		return
	if _lang_layer and _lang_layer.visible:
		if event.is_action_pressed("pause"):
			_close_lang_modal()
		return
	if event.is_action_pressed("pause"):
		if state == GameState.PLAYING or state == GameState.JOURNEY or state == GameState.PAUSED:
			_toggle_pause()
			return
		elif state == GameState.CHARACTERS_PAGE or state == GameState.MAP_PAGE:
			_enter_home_hub()
			return
	if state == GameState.HOME_HUB and event.is_action_pressed("jump"):
		_start_run_from_hub()
	elif state == GameState.GAME_OVER and (event.is_action_pressed("retry") or event.is_action_pressed("jump")):
		_close_modal_with_anim(_gameover_card, _restart_from_modal)
	elif state == GameState.VICTORY and event.is_action_pressed("retry"):
		_close_modal_with_anim(_victory_card, _restart_from_modal)


func _process(delta: float) -> void:
	if state == GameState.PAUSED:
		return

	if state == GameState.JOURNEY:
		_run_time += delta
		return

	if state == GameState.PLAYING:
		_run_time += delta

	if state == GameState.CHARACTERS_PAGE:
		_camera.position = _camera.position.lerp(Vector3(-120.0, 1.85, 6.20), delta * 8.0)
		_camera.look_at(Vector3(-120.0, 0.85, -0.25))
		_update_characters_page_ui()
	elif state == GameState.MAP_PAGE:
		if is_instance_valid(_map_stage):
			_map_stage.update_map_step(delta, _camera)
		_update_map_pins_layout()
	elif _panoramic_revive_t >= 0.0:
		_panoramic_revive_t += delta
		var rk := clampf(_panoramic_revive_t / 0.95, 0.0, 1.0)
		var angle := lerpf(TAU * 0.85, 0.0, smoothstep(0.0, 1.0, rk))
		var orbit_r := lerpf(7.8, 3.2, rk)
		var orbit_z := lerpf(7.5, 9.6, rk)
		var c_pos := Vector3(
			_panoramic_revive_pos.x + sin(angle) * orbit_r + 3.2 * rk,
			clampf(_panoramic_revive_pos.y, -2.5, 4.5) + lerpf(4.6, 2.55, rk),
			orbit_z * cos(angle * 0.4)
		)
		_cam_pos_cur = c_pos
		_cam_look_cur = Vector3(_panoramic_revive_pos.x + 3.0 * rk, clampf(_panoramic_revive_pos.y, -2.5, 4.5) + 1.15, -0.5 * rk)
		_camera.position = _cam_pos_cur
		_camera.look_at(_cam_look_cur)
		if _panoramic_revive_t >= 0.95:
			_panoramic_revive_t = -1.0
			_player.active = true
			_player._invuln_timer = 2.6
			state = GameState.PLAYING
	elif state == GameState.HOME_HUB:
		_cam_pos_cur = _cam_pos_cur.lerp(Vector3(_player.global_position.x + 1.85, 1.72, 5.55), delta * 6.0)
		_cam_look_cur = _cam_look_cur.lerp(Vector3(_player.global_position.x + 0.75, 0.88, -0.3), delta * 6.0)
		_camera.position = _cam_pos_cur
		_camera.look_at(_cam_look_cur)
	elif state != GameState.TITLE:
		var target_y := clampf(_player.global_position.y, -4.2, 4.5)
		var target_pos := Vector3(_player.global_position.x + 3.2, target_y + 2.55, 9.6)
		var target_look := Vector3(_player.global_position.x + 3.0, target_y + 1.30, -1.0)
		var k := 1.0 - exp(-12.5 * delta)
		_cam_pos_cur = _cam_pos_cur.lerp(target_pos, k)
		_cam_look_cur = _cam_look_cur.lerp(target_look, k)

		var shake_off := Vector3.ZERO
		if _shake_amp > 0.02:
			shake_off = Vector3(randf_range(-_shake_amp, _shake_amp), randf_range(-_shake_amp, _shake_amp), 0.0)
			_shake_amp = lerpf(_shake_amp, 0.0, delta * 9.0)
		_camera.position = _cam_pos_cur + shake_off
		_camera.look_at(_cam_look_cur + shake_off * 0.4)

	_backdrop.update_environment(delta, _player.progress, _camera.position.x)


func _spawn_lost_heart_shards(htr: TextureRect) -> void:
	if not is_instance_valid(htr) or not is_instance_valid(htr.get_parent()):
		return
	var host: Node = htr.get_viewport()
	if not is_instance_valid(host):
		return
	var layer := htr.get_parent().get_parent()
	while is_instance_valid(layer) and not (layer is CanvasLayer):
		layer = layer.get_parent()
	if not is_instance_valid(layer) or layer.get_child_count() == 0:
		return
	var ui_root := layer.get_child(0)
	var center := htr.get_global_rect().get_center()
	for si in range(6):
		var sh := ColorRect.new()
		sh.color = Color(0.98, 0.16, 0.28, 0.96) if si % 2 == 0 else Color(1.0, 0.42, 0.48, 0.96)
		sh.size = Vector2(9, 9)
		sh.pivot_offset = Vector2(4.5, 4.5)
		sh.rotation_degrees = randf_range(0.0, 45.0)
		sh.position = center - Vector2(4.5, 4.5)
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(sh)
		var ang := deg_to_rad(float(si) * 60.0 + randf_range(-18.0, 18.0))
		var dest := sh.position + Vector2(cos(ang) * randf_range(16.0, 34.0), sin(ang) * randf_range(6.0, 20.0) + randf_range(26.0, 46.0))
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(sh, "position", dest, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sh, "rotation_degrees", sh.rotation_degrees + randf_range(-160.0, 160.0), 0.42)
		tw.tween_property(sh, "scale", Vector2(0.25, 0.25), 0.42)
		tw.tween_property(sh, "modulate:a", 0.0, 0.42)
		tw.chain().tween_callback(sh.queue_free)


func _animate_heart_change(htr: TextureRect, filled: bool, full_tex: Texture2D, empty_tex: Texture2D) -> void:
	if not is_instance_valid(htr):
		return
	if htr.has_meta("heart_tw"):
		var prev_tw = htr.get_meta("heart_tw")
		if prev_tw is Tween and (prev_tw as Tween).is_valid():
			(prev_tw as Tween).kill()
	htr.pivot_offset = htr.size * 0.5
	var tgt_tex := full_tex if filled else empty_tex
	if htr.texture == tgt_tex:
		htr.rotation_degrees = 0.0
		htr.scale = Vector2.ONE if filled else Vector2(0.86, 0.86)
		htr.modulate = Color.WHITE if filled else Color(0.84, 0.88, 0.94, 0.74)
		return
	if not filled:
		# Unmistakable heart-break loss animation: flash red + scale pop + shake + shattering shards + settle empty
		htr.texture = full_tex
		htr.scale = Vector2(1.38, 1.38)
		htr.modulate = Color(1.45, 0.35, 0.35, 1.0)
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		htr.set_meta("heart_tw", tw)
		tw.tween_property(htr, "rotation_degrees", -18.0, 0.05)
		tw.tween_property(htr, "rotation_degrees", 18.0, 0.06)
		tw.tween_property(htr, "rotation_degrees", -14.0, 0.06)
		tw.tween_property(htr, "rotation_degrees", 10.0, 0.05)
		tw.tween_callback(func():
			if is_instance_valid(htr):
				_spawn_lost_heart_shards(htr)
				htr.texture = empty_tex
				htr.rotation_degrees = 0.0
				htr.scale = Vector2(1.14, 0.64)
				htr.modulate = Color(0.84, 0.88, 0.94, 0.74)
		)
		tw.tween_property(htr, "scale", Vector2(0.86, 0.86), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		htr.texture = full_tex
		htr.rotation_degrees = 0.0
		htr.scale = Vector2(1.30, 1.30)
		htr.modulate = Color.WHITE
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		htr.set_meta("heart_tw", tw)
		tw.tween_property(htr, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_hp_changed(new_hp: int, _max_hp: int) -> void:
	var c := clampi(new_hp, 0, _hearts_box.size())
	var was_damaged := (c < _stage_prev_hp)
	_stage_prev_hp = c
	for i in range(_hearts_box.size()):
		_animate_heart_change(_hearts_box[i], i < c, _tex_stage_heart_full, _tex_stage_heart_empty)
	if was_damaged and c > 0:
		_shake_amp = 0.22


func _on_rescue_changed(has_r: bool) -> void:
	if is_instance_valid(_rescue_star_poly):
		_rescue_star_poly.color = Color(1.0, 0.88, 0.18, 1.0) if has_r else Color(1.0, 1.0, 1.0, 0.38)


func _on_gem_collected(total: int) -> void:
	_coin_lbl.text = "%d" % total


func _populate_gameover_ui(reason_txt: String, coins_cnt: int) -> void:
	var mins := int(_run_time) / 60
	var secs := int(_run_time) % 60
	_gameover_badge_lbl.text = reason_txt
	_gameover_title_lbl.text = reason_txt
	if is_instance_valid(_gameover_sub_lbl):
		_gameover_sub_lbl.text = Loc.t("lose_title")
	if is_instance_valid(_go_coins_lbl):
		_go_coins_lbl.text = "%s: %d" % [Loc.t("stats_coins_lbl"), coins_cnt]
	if is_instance_valid(_go_time_lbl):
		_go_time_lbl.text = "%s: %02d:%02d" % [Loc.t("stats_time_lbl"), mins, secs]
	_gameover_stats_lbl.text = Loc.t("stats_go_fmt") % [coins_cnt, mins, secs]


func _populate_victory_ui(badge_key: String, title_key: String, lvl_str: String, coins_cnt: int, cur_hp: int, cur_max: int, show_hearts: bool) -> void:
	var mins := int(_run_time) / 60
	var secs := int(_run_time) % 60
	_victory_badge_lbl.text = Loc.t(badge_key)
	_victory_title_lbl.text = Loc.t(title_key)
	if is_instance_valid(_win_lvl_lbl):
		_win_lvl_lbl.text = lvl_str
	if is_instance_valid(_win_time_lbl):
		_win_time_lbl.text = "%s: %02d:%02d" % [Loc.t("stats_time_lbl"), mins, secs]
	if is_instance_valid(_win_coins_lbl):
		_win_coins_lbl.text = "%s: %d" % [Loc.t("stats_coins_lbl"), coins_cnt]
	if is_instance_valid(_win_hearts_lbl):
		var chip := _win_hearts_lbl.get_parent().get_parent() as Control
		if chip:
			chip.visible = show_hearts
		_win_hearts_lbl.text = "%d / %d" % [cur_hp, cur_max]


func _on_player_defeated(reason: String) -> void:
	if state == GameState.DYING or state == GameState.GAME_OVER:
		return
	_reset_joy_knob()
	_bank_current_run_coins(false)
	_last_stage_fail_x = _player.global_position.x
	_won_during_journey = false
	_was_in_journey_before_pause = false
	state = GameState.DYING
	_shake_amp = 0.26
	var reason_txt := Loc.t("lose_badge_hit")
	if reason == "mud" or reason == "fall":
		reason_txt = Loc.t("lose_badge_mud")
	elif reason == "water":
		reason_txt = Loc.t("lose_badge_water")
	_populate_gameover_ui(reason_txt, _player.gems)

	var delay := 1.45 if reason == "water" else (0.90 if (reason == "mud" or reason == "fall") else 0.72)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(_show_gameover_modal)


func _show_gameover_modal() -> void:
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	var reason_txt := _gameover_badge_lbl.text
	_populate_gameover_ui(reason_txt, _player.gems if is_instance_valid(_player) else 0)
	_sync_gameover_reward_btns()
	_animate_modal_open(_gameover_card, 2.2)


func _on_player_victory() -> void:
	_reset_joy_knob()
	_bank_current_run_coins(false)
	state = GameState.VICTORY
	_won_during_journey = false
	_was_in_journey_before_pause = false
	var unlocked_next := _progress.record_level_win(_progress.selected_level, _player.gems)
	_next_lvl_btn.visible = (_progress.selected_level < GameProgress.IMPLEMENTED_LEVELS) and (_progress.selected_level + 1 <= _progress.unlocked_level)
	_populate_victory_ui(
		"win_badge", "win_title",
		Loc.t("stage_fmt") % _progress.selected_level,
		_player.gems, _player.hp, _player.max_hp, true
	)
	_sync_next_lvl_btn_appearance()
	if unlocked_next:
		_audio.play("gem", 1.15, -8.0, 200)
	var tw := create_tween()
	tw.tween_interval(1.05)
	tw.tween_callback(_show_victory_modal)


func _show_victory_modal() -> void:
	if _won_during_journey:
		return
	_populate_victory_ui(
		"win_badge", "win_title",
		Loc.t("stage_fmt") % _progress.selected_level,
		_player.gems, _player.hp, _player.max_hp, true
	)
	_animate_modal_open(_victory_card, 2.0)


func _sync_next_lvl_btn_appearance() -> void:
	if not is_instance_valid(_next_lvl_btn):
		return
	_next_lvl_btn.layout_direction = Loc.dir_layout()
	if _won_during_journey:
		_next_lvl_btn.text = Loc.t("journey_enter_btn")
		_next_lvl_btn.custom_minimum_size = Vector2(245.0, 64.0)
		_next_lvl_btn.add_theme_font_size_override("font_size", 19)
		return
	var nxt := mini(_progress.selected_level + 1, GameProgress.IMPLEMENTED_LEVELS)
	if _progress.selected_level < GameProgress.IMPLEMENTED_LEVELS and _progress.needs_journey_to(nxt):
		_next_lvl_btn.text = Loc.start_journey_text(nxt)
		_next_lvl_btn.custom_minimum_size = Vector2(335.0, 64.0)
		_next_lvl_btn.add_theme_font_size_override("font_size", 18)
	else:
		_next_lvl_btn.text = Loc.t("btn_next_lvl")
		_next_lvl_btn.custom_minimum_size = Vector2(215.0, 64.0)
		_next_lvl_btn.add_theme_font_size_override("font_size", 20)


func _on_journey_hp_changed(cur_hp: int, _max_hp: int) -> void:
	var c := clampi(cur_hp, 0, _j_hearts.size())
	var was_damaged := (c < _j_prev_hp)
	_j_prev_hp = c
	for i in range(_j_hearts.size()):
		_animate_heart_change(_j_hearts[i], i < c, _tex_jheart_full, _tex_jheart_empty)
	if was_damaged and c > 0:
		_shake_amp = 0.20


func _on_journey_mc_inventory(oak_cnt: int, stone_cnt: int, active_slot: int) -> void:
	var counts := [oak_cnt, stone_cnt]
	for i in range(mini(2, _j_slot_btns.size())):
		var is_act := (i == active_slot)
		if i < _j_slot_cnt_lbls.size() and is_instance_valid(_j_slot_cnt_lbls[i]):
			_j_slot_cnt_lbls[i].text = "%d" % counts[i]
			_j_slot_cnt_lbls[i].add_theme_color_override("font_color", Color(1.0, 0.90, 0.25) if is_act else Color.WHITE)
		var btn: Button = _j_slot_btns[i]
		if is_instance_valid(btn):
			btn.scale = Vector2(1.18, 1.18) if is_act else Vector2(0.92, 0.92)
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_act else Color(1.0, 1.0, 1.0, 0.78)


func _on_journey_mc_toast(msg: String) -> void:
	if not is_instance_valid(_j_toast_lbl) or msg == "":
		return
	_j_toast_lbl.layout_direction = Loc.dir_layout()
	_j_toast_lbl.text = msg
	if _j_toast_tw and _j_toast_tw.is_valid():
		_j_toast_tw.kill()
	_j_toast_tw = create_tween()
	_j_toast_tw.tween_property(_j_toast_lbl, "modulate:a", 1.0, 0.14)
	_j_toast_tw.tween_interval(2.85)
	_j_toast_tw.tween_property(_j_toast_lbl, "modulate:a", 0.0, 0.30)


func _on_journey_coins_changed(total_coins: int) -> void:
	if is_instance_valid(_j_coin_lbl):
		_j_coin_lbl.text = "%d" % total_coins


func _on_journey_dest_fog(_to_lvl: int, _coins_earned: int) -> void:
	if not is_instance_valid(_white_fog_layer) or not is_instance_valid(_white_fog_rect):
		return
	_white_fog_layer.visible = true
	_white_fog_rect.color = Color(0.98, 0.99, 1.0, 0.0)
	var tw := create_tween()
	tw.tween_property(_white_fog_rect, "color:a", 0.88, 0.44).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.45)
	tw.tween_property(_white_fog_rect, "color:a", 0.22, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_journey_completed(to_lvl: int, coins_earned: int) -> void:
	if state != GameState.JOURNEY:
		return
	_reset_joy_knob()
	_bank_current_run_coins(true)
	_won_during_journey = true
	_was_in_journey_before_pause = false
	state = GameState.VICTORY
	_progress.record_journey_arrival(to_lvl)
	_populate_victory_ui(
		"journey_win_badge", "journey_win_title",
		Loc.kingdom_label(to_lvl), coins_earned, 0, 0, false
	)
	_next_lvl_btn.visible = true
	_sync_next_lvl_btn_appearance()
	_audio.play("gem", 1.15, -8.0, 200)
	var tw := create_tween()
	tw.tween_interval(1.05)
	tw.tween_callback(func(): _animate_modal_open(_victory_card, 2.0))


func _on_journey_failed(reason: String, coins_earned: int) -> void:
	if state == GameState.DYING or state == GameState.GAME_OVER:
		return
	_reset_joy_knob()
	_bank_current_run_coins(true)
	_won_during_journey = false
	_was_in_journey_before_pause = true
	state = GameState.GAME_OVER
	var reason_txt := Loc.t("lose_badge_hit")
	if reason == "water":
		reason_txt = Loc.t("lose_badge_water")
	elif reason == "mud" or reason == "fall":
		reason_txt = Loc.t("lose_badge_mud")
	_populate_gameover_ui(reason_txt, coins_earned)
	_sync_gameover_reward_btns()
	_animate_modal_open(_gameover_card, 2.2)


func _sync_gameover_reward_btns() -> void:
	var dir := Loc.dir_layout()
	if is_instance_valid(_gameover_revive_btn):
		_gameover_revive_btn.layout_direction = dir
		_gameover_revive_btn.text = Loc.t("btn_revive_reward")
		_gameover_revive_btn.visible = true
	if is_instance_valid(_gameover_skip_btn):
		_gameover_skip_btn.layout_direction = dir
		_gameover_skip_btn.text = Loc.t("btn_skip_journey_reward") if _was_in_journey_before_pause else Loc.t("btn_skip_reward")
		_gameover_skip_btn.visible = _was_in_journey_before_pause or (_progress.selected_level < GameProgress.IMPLEMENTED_LEVELS)


func _on_revive_requested() -> void:
	var grant_revive := func():
		get_tree().paused = false
		_audio.set_paused_duck(false)
		_set_pause_btn_icon(false)
		_hide_all_modals_except("")
		if _blur_mat and not OS.has_feature("mobile"):
			_blur_mat.set_shader_parameter("blur_amount", 0.0)
		if _was_in_journey_before_pause and is_instance_valid(_journey_world):
			_was_in_journey_before_pause = false
			state = GameState.JOURNEY
			_journey_world.revive_near_spot()
		else:
			var safe_p := _level_builder.get_safe_revive_pos(_last_stage_fail_x) if is_instance_valid(_level_builder) else Vector3(1.5, Level3DBuilder.GROUND_Y, 0.0)
			_hud_layer.visible = true
			_player.revive_at(safe_p)
			_player.active = false
			_panoramic_revive_pos = safe_p
			_panoramic_revive_t = 0.0
			_stage_prev_hp = _player.hp if is_instance_valid(_player) else 3
			for ht: TextureRect in _hearts_box:
				if is_instance_valid(ht):
					ht.texture = _tex_stage_heart_full
					ht.scale = Vector2.ONE
					ht.rotation_degrees = 0.0
					ht.modulate = Color.WHITE
			state = GameState.PLAYING
	var cancel_revive := func():
		get_tree().paused = false
		_sync_gameover_reward_btns()
		_animate_modal_open(_gameover_card, 2.2)

	_close_modal_with_anim(_gameover_card, func():
		_open_spend_or_ad_choice(
			"revive", GameProgress.COST_REVIVE,
			func():
				get_tree().paused = true
				_ad_service.show_rewarded("revive", grant_revive, cancel_revive),
			grant_revive,
			cancel_revive
		)
	)


func _on_skip_requested(from_card: PanelContainer) -> void:
	var was_paused_card := (from_card == _pause_card)
	var grant_skip := func():
		get_tree().paused = false
		_audio.set_paused_duck(false)
		_set_pause_btn_icon(false)
		_reset_joy_knob()
		_hide_all_modals_except("")
		if _blur_mat and not OS.has_feature("mobile"):
			_blur_mat.set_shader_parameter("blur_amount", 0.0)
		if _was_in_journey_before_pause:
			_bank_current_run_coins(true)
			var dst := clampi(_journey_to_lvl, 2, GameProgress.IMPLEMENTED_LEVELS)
			var coins_got := _journey_world.journey_coins if is_instance_valid(_journey_world) else 0
			_progress.record_journey_arrival(dst)
			_progress.selected_level = dst
			_progress.save_progress()
			_won_during_journey = true
			_was_in_journey_before_pause = false
			state = GameState.VICTORY
			_populate_victory_ui(
				"journey_win_badge", "journey_win_title",
				Loc.kingdom_label(dst), coins_got, 0, 0, false
			)
			_next_lvl_btn.visible = true
			_sync_next_lvl_btn_appearance()
			_audio.play("gem", 1.15, -8.0, 200)
			_animate_modal_open(_victory_card, 1.8)
		else:
			_bank_current_run_coins(false)
			var cur_lvl := _progress.selected_level
			if is_instance_valid(_player):
				_player.active = false
			var gems_got := _player.gems if is_instance_valid(_player) else 0
			_progress.record_level_win(cur_lvl, gems_got)
			_won_during_journey = false
			_was_in_journey_before_pause = false
			state = GameState.VICTORY
			var cur_hp := _player.hp if is_instance_valid(_player) else 3
			var cur_max := _player.max_hp if is_instance_valid(_player) else 3
			_populate_victory_ui(
				"win_badge", "win_title",
				Loc.t("stage_fmt") % cur_lvl,
				gems_got, cur_hp, cur_max, true
			)
			_next_lvl_btn.visible = (cur_lvl < GameProgress.IMPLEMENTED_LEVELS) and (cur_lvl + 1 <= _progress.unlocked_level)
			_sync_next_lvl_btn_appearance()
			_audio.play("gem", 1.15, -8.0, 200)
			_animate_modal_open(_victory_card, 1.8)
	var cancel_skip := func():
		if was_paused_card:
			get_tree().paused = true
			_animate_modal_open(_pause_card, 2.2)
		else:
			get_tree().paused = false
			_sync_gameover_reward_btns()
			_animate_modal_open(_gameover_card, 2.2)

	_close_modal_with_anim(from_card, func():
		_open_spend_or_ad_choice(
			"skip", GameProgress.COST_SKIP,
			func():
				get_tree().paused = true
				_ad_service.show_rewarded("skip", grant_skip, cancel_skip),
			grant_skip,
			cancel_skip
		)
	)
