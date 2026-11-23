class_name AdService
extends CanvasLayer

# Rewarded-Only AdMob Integration Layer (STRICTLY zero interstitial or banner ads)
const ADMOB_ENABLED := true
const INTERSTITIAL_ENABLED := false
const ANDROID_APP_ID := "ca-app-pub-2386934146313362~8112924071"
const ANDROID_REWARDED_AD_UNIT_ID := "ca-app-pub-2386934146313362/2251444492"
const IOS_REWARDED_AD_UNIT_ID := "ca-app-pub-3940256099942544/1712485313"

const SKIP_REQUIRED_ADS := 2
const LOAD_TIMEOUT_SEC := 15.0

enum AdState {
	IDLE,
	LOADING_FIRST,
	SHOWING_FIRST,
	OFFER_SECOND,
	LOADING_SECOND,
	SHOWING_SECOND,
	REWARDED,
	CANCELLED,
	FAILED,
}

signal ad_state_changed(new_state: int)

var _state: AdState = AdState.IDLE
var _placement: String = "skip"
var _ads_total: int = 1
var _earned_this_ad: bool = false
var _reward_dispatched: bool = false
var _load_elapsed: float = 0.0
var _on_rewarded: Callable
var _on_cancelled: Callable

var _overlay: ColorRect
var _center_wrap: CenterContainer
var _card: PanelContainer
var _badge_lbl: Label
var _title_lbl: Label
var _sub_lbl: Label
var _action_btn: Button
var _close_btn: Button
var _tween: Tween

var _mobile_admob_plugin: Object = null
var _init_listener: OnInitializationCompleteListener
var _reward_listener: OnUserEarnedRewardListener
var _load_callback: RewardedAdLoadCallback
var _content_callback: FullScreenContentCallback
var _rewarded_ad: RewardedAd = null
var _is_loading_native: bool = false


func _ready() -> void:
	layer = 30
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detect_mobile_sdk()
	_build_ad_ui()


func get_ad_state() -> AdState:
	return _state


func has_native_mobile_sdk() -> bool:
	return _mobile_admob_plugin != null


func is_showing_native_ad() -> bool:
	return _state != AdState.IDLE


func get_rewarded_unit_id() -> String:
	return IOS_REWARDED_AD_UNIT_ID if OS.get_name() == "iOS" else ANDROID_REWARDED_AD_UNIT_ID


func _set_state(new_state: AdState) -> void:
	if _state == new_state:
		return
	_state = new_state
	ad_state_changed.emit(_state)


func _detect_mobile_sdk() -> void:
	if not ADMOB_ENABLED:
		return
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		return
	if not Engine.has_singleton("PoingGodotAdMob"):
		return
	_mobile_admob_plugin = Engine.get_singleton("PoingGodotAdMob")

	_reward_listener = OnUserEarnedRewardListener.new()
	_reward_listener.on_user_earned_reward = _on_native_reward_earned

	_load_callback = RewardedAdLoadCallback.new()
	_load_callback.on_ad_loaded = _on_native_ad_loaded
	_load_callback.on_ad_failed_to_load = _on_native_ad_failed

	_content_callback = FullScreenContentCallback.new()
	_content_callback.on_ad_dismissed_full_screen_content = _on_native_ad_dismissed
	_content_callback.on_ad_failed_to_show_full_screen_content = _on_native_ad_show_failed

	var req_cfg := RequestConfiguration.new()
	req_cfg.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	MobileAds.set_request_configuration(req_cfg)

	_init_listener = OnInitializationCompleteListener.new()
	_init_listener.on_initialization_complete = _on_admob_init_complete
	MobileAds.initialize(_init_listener)


func _on_admob_init_complete(_status: InitializationStatus) -> void:
	_preload_native_rewarded()


func _preload_native_rewarded() -> void:
	if not has_native_mobile_sdk() or _is_loading_native or _rewarded_ad != null:
		return
	_is_loading_native = true
	RewardedAdLoader.new().load(get_rewarded_unit_id(), AdRequest.new(), _load_callback)


func _build_ad_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.05, 0.08, 0.16, 0.58)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_center_wrap = CenterContainer.new()
	_center_wrap.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_center_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center_wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_center_wrap)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(580, 320)
	_card.pivot_offset = Vector2(290, 160)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 18
	_card.add_theme_stylebox_override("panel", sb)
	_center_wrap.add_child(_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(vb)

	var hdr := HBoxContainer.new()
	hdr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vb.add_child(hdr)

	_close_btn = GameFonts.make_orange_circle_btn(46.0, "res://assets/textures/ui/icon_close_white.png")
	_close_btn.pressed.connect(_on_close_pressed)
	hdr.add_child(_close_btn)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr.add_child(sp)

	var badge_pill := PanelContainer.new()
	var bps := StyleBoxFlat.new()
	bps.bg_color = Color(0.96, 0.54, 0.08, 0.92)
	bps.set_corner_radius_all(14)
	bps.content_margin_left = 14
	bps.content_margin_right = 14
	bps.content_margin_top = 6
	bps.content_margin_bottom = 6
	badge_pill.add_theme_stylebox_override("panel", bps)
	hdr.add_child(badge_pill)

	_badge_lbl = Label.new()
	_badge_lbl.text = Loc.t("ad_badge")
	GameFonts.apply_rtl_label(_badge_lbl, GameFonts.readex_bold(), 15, Color.WHITE)
	badge_pill.add_child(_badge_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_lbl.custom_minimum_size = Vector2(500, 0)
	GameFonts.apply_rtl_label(_title_lbl, GameFonts.lalezar(), 38, Color.WHITE)
	_title_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.95))
	_title_lbl.add_theme_constant_override("outline_size", 7)
	vb.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_lbl.custom_minimum_size = Vector2(500, 0)
	GameFonts.apply_rtl_label(_sub_lbl, GameFonts.readex_bold(), 19, Color(0.96, 0.92, 0.84))
	_sub_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.16, 0.92))
	_sub_lbl.add_theme_constant_override("outline_size", 5)
	vb.add_child(_sub_lbl)

	var btn_box := CenterContainer.new()
	vb.add_child(btn_box)

	_action_btn = GameFonts.make_orange_pill_btn(Loc.t("ad_watch_second_btn"), 440.0, 68.0, 20)
	_action_btn.pressed.connect(_on_action_btn_pressed)
	btn_box.add_child(_action_btn)


func _open_modal_card(badge_txt: String, title_txt: String, sub_txt: String, btn_txt: String, show_btn: bool) -> void:
	var dir := Loc.dir_layout()
	_badge_lbl.layout_direction = dir
	_title_lbl.layout_direction = dir
	_sub_lbl.layout_direction = dir
	_action_btn.layout_direction = dir

	_badge_lbl.text = badge_txt
	_title_lbl.text = title_txt
	_sub_lbl.text = sub_txt
	_sub_lbl.visible = sub_txt != ""
	_action_btn.text = btn_txt
	_action_btn.visible = show_btn

	visible = true
	_overlay.modulate.a = 0.0
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.86, 0.86)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(_overlay, "modulate:a", 1.0, 0.16)
	_tween.tween_property(_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide_modal_card() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	visible = false


func show_rewarded(placement: String, on_rewarded: Callable, on_cancelled: Callable = Callable()) -> void:
	# Strictly block overlapping/duplicate ad flows
	if _state != AdState.IDLE:
		return
	_placement = placement
	_on_rewarded = on_rewarded
	_on_cancelled = on_cancelled
	_ads_total = SKIP_REQUIRED_ADS if placement == "skip" else 1
	_earned_this_ad = false
	_reward_dispatched = false
	_load_elapsed = 0.0

	_set_state(AdState.LOADING_FIRST)
	_start_current_ad_load_or_show()


func _start_current_ad_load_or_show() -> void:
	_earned_this_ad = false
	_load_elapsed = 0.0
	var is_second := (_state == AdState.LOADING_SECOND)

	if has_native_mobile_sdk():
		if _rewarded_ad != null:
			_transition_to_show_loaded_ad()
			return
		var badge_t := (Loc.t("ad_step_fmt") % [2 if is_second else 1, _ads_total]) if _ads_total > 1 else Loc.t("ad_badge")
		var load_t := Loc.t("ad_loading_second") if is_second else Loc.t("ad_loading_first")
		_open_modal_card(badge_t, load_t, "", Loc.t("btn_close"), false)
		_preload_native_rewarded()
		return

	# Non-SDK platforms (Desktop Windows): show loading only if testing SDK explicitly, or fail honestly (zero timer rewards!)
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_enter_failed_state(Loc.t("ad_failed_msg"))
	elif _test_sdk_mode:
		var badge_t := (Loc.t("ad_step_fmt") % [2 if is_second else 1, _ads_total]) if _ads_total > 1 else Loc.t("ad_badge")
		var load_t := Loc.t("ad_loading_second") if is_second else Loc.t("ad_loading_first")
		_open_modal_card(badge_t, load_t, "", Loc.t("btn_close"), false)
	else:
		_enter_failed_state(Loc.t("ad_pc_unavailable"))


var _test_sdk_mode: bool = false

func enable_test_sdk_mode(enabled: bool) -> void:
	_test_sdk_mode = enabled


func _transition_to_show_loaded_ad() -> void:
	if _state == AdState.LOADING_FIRST:
		_set_state(AdState.SHOWING_FIRST)
	elif _state == AdState.LOADING_SECOND:
		_set_state(AdState.SHOWING_SECOND)
	else:
		return
	_earned_this_ad = false
	_hide_modal_card()
	if _rewarded_ad != null and has_native_mobile_sdk():
		_rewarded_ad.show(_reward_listener)


func _process(delta: float) -> void:
	if _state == AdState.LOADING_FIRST or _state == AdState.LOADING_SECOND:
		_load_elapsed += delta
		if _load_elapsed >= LOAD_TIMEOUT_SEC:
			_enter_failed_state(Loc.t("ad_failed_msg"))


func _on_native_ad_loaded(ad: RewardedAd) -> void:
	_is_loading_native = false
	_rewarded_ad = ad
	if _rewarded_ad and _content_callback:
		_rewarded_ad.full_screen_content_callback = _content_callback
	if _state == AdState.LOADING_FIRST or _state == AdState.LOADING_SECOND:
		_transition_to_show_loaded_ad()


func _on_native_ad_failed(_err: LoadAdError) -> void:
	_is_loading_native = false
	if _state == AdState.LOADING_FIRST or _state == AdState.LOADING_SECOND:
		_enter_failed_state(Loc.t("ad_failed_msg"))


func _on_native_ad_show_failed(_err: AdError) -> void:
	_cleanup_native_ad()
	if _state == AdState.SHOWING_FIRST or _state == AdState.SHOWING_SECOND or _state == AdState.LOADING_FIRST or _state == AdState.LOADING_SECOND:
		_enter_failed_state(Loc.t("ad_failed_msg"))


func _on_native_reward_earned(_item: RewardedItem) -> void:
	# Earned flag applies ONLY when currently showing Ad 1 or Ad 2
	if _state == AdState.SHOWING_FIRST or _state == AdState.SHOWING_SECOND:
		_earned_this_ad = true


func _on_native_ad_dismissed() -> void:
	# Guard against duplicate SDK dismiss callbacks
	if _state != AdState.SHOWING_FIRST and _state != AdState.SHOWING_SECOND:
		return
	var finished_state := _state
	_cleanup_native_ad()
	_preload_native_rewarded()

	if not _earned_this_ad:
		_finish_cancelled()
		return

	if finished_state == AdState.SHOWING_FIRST:
		if _ads_total <= 1:
			_finish_rewarded_once()
		else:
			# Step 2 -> 3 of Phase 6: Strictly open intermediate window & wait for explicit player button click!
			_set_state(AdState.OFFER_SECOND)
			call_deferred("_show_offer_second_window")
	elif finished_state == AdState.SHOWING_SECOND:
		_finish_rewarded_once()


func _show_offer_second_window() -> void:
	if _state != AdState.OFFER_SECOND:
		return
	var badge_txt := Loc.t("ad_step_fmt") % [1, _ads_total]
	_open_modal_card(
		badge_txt,
		Loc.t("ad_first_done"),
		Loc.t("ad_first_done_sub"),
		Loc.t("ad_watch_second_btn"),
		true
	)


func _on_action_btn_pressed() -> void:
	if _state == AdState.OFFER_SECOND:
		# Step 4: Second ad ONLY starts after explicit user click!
		_set_state(AdState.LOADING_SECOND)
		_start_current_ad_load_or_show()
	elif _state == AdState.FAILED:
		_finish_cancelled()


func _on_close_pressed() -> void:
	if _state == AdState.LOADING_FIRST or _state == AdState.OFFER_SECOND or _state == AdState.LOADING_SECOND or _state == AdState.FAILED:
		_finish_cancelled()


func _enter_failed_state(msg: String) -> void:
	_set_state(AdState.FAILED)
	_open_modal_card(
		Loc.t("ad_badge"),
		Loc.t("ad_failed_title"),
		msg,
		Loc.t("btn_close"),
		true
	)


func _finish_rewarded_once() -> void:
	if _reward_dispatched:
		return
	_reward_dispatched = true
	_set_state(AdState.REWARDED)
	_hide_modal_card()
	var cb := _on_rewarded
	_on_rewarded = Callable()
	_on_cancelled = Callable()
	_set_state(AdState.IDLE)
	if cb.is_valid():
		cb.call_deferred()


func _finish_cancelled() -> void:
	_set_state(AdState.CANCELLED)
	_hide_modal_card()
	var cb := _on_cancelled
	_on_rewarded = Callable()
	_on_cancelled = Callable()
	_set_state(AdState.IDLE)
	if cb.is_valid():
		cb.call_deferred()


func _cleanup_native_ad() -> void:
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null


func abort_flow() -> void:
	_on_rewarded = Callable()
	_on_cancelled = Callable()
	_earned_this_ad = false
	_reward_dispatched = false
	_hide_modal_card()
	_set_state(AdState.IDLE)


# Deterministic SDK simulation helpers for automated verification (strictly follow real callback path!)
func debug_sim_ad_loaded() -> void:
	if _state == AdState.LOADING_FIRST or _state == AdState.LOADING_SECOND:
		_transition_to_show_loaded_ad()


func debug_sim_ad_failed() -> void:
	_is_loading_native = false
	if _state == AdState.LOADING_FIRST or _state == AdState.SHOWING_FIRST or _state == AdState.LOADING_SECOND or _state == AdState.SHOWING_SECOND:
		_enter_failed_state(Loc.t("ad_failed_msg"))


func debug_sim_user_earned_reward() -> void:
	_on_native_reward_earned(null)


func debug_sim_ad_dismissed() -> void:
	_on_native_ad_dismissed()
