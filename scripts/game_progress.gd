class_name GameProgress
extends RefCounted

const SAVE_PATH := "user://abtal_progress.cfg"
const LEGACY_SAVE_PATH := "user://haneen_progress.cfg"
const TOTAL_MAP_LEVELS := 30
const IMPLEMENTED_LEVELS := 30
const COST_REVIVE := 100
const COST_SKIP := 200

var unlocked_level: int = 1
var journey_cleared_to: int = 1
var selected_level: int = 1
var selected_character: String = "haneen"
var selected_language: String = ""
var last_os_language: String = ""
var game_volume: float = 1.0
var total_coins: int = 0
var best_coins: Dictionary = {}


func load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		err = cfg.load(LEGACY_SAVE_PATH)
	if err == OK:
		unlocked_level = clampi(int(cfg.get_value("progress", "unlocked_level", 1)), 1, IMPLEMENTED_LEVELS)
		journey_cleared_to = clampi(int(cfg.get_value("progress", "journey_cleared_to", unlocked_level)), 1, unlocked_level)
		selected_level = clampi(int(cfg.get_value("progress", "selected_level", 1)), 1, unlocked_level)
		var ch: String = str(cfg.get_value("progress", "selected_character", "haneen"))
		if ch in ["haneen", "seif", "youssef"]:
			selected_character = ch
		var sl: String = str(cfg.get_value("progress", "selected_language", ""))
		if sl in Loc.SUPPORTED:
			selected_language = sl
		last_os_language = str(cfg.get_value("progress", "last_os_language", "")).strip_edges().to_lower()
		game_volume = clampf(float(cfg.get_value("progress", "game_volume", 1.0)), 0.0, 1.0)
		var sum_best := 0
		for i in range(1, IMPLEMENTED_LEVELS + 1):
			var c_val := int(cfg.get_value("coins", "lvl_%d" % i, 0))
			best_coins[i] = c_val
			sum_best += c_val
		if cfg.has_section_key("progress", "total_coins"):
			total_coins = maxi(0, int(cfg.get_value("progress", "total_coins", 0)))
		else:
			total_coins = maxi(0, sum_best)


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_level", unlocked_level)
	cfg.set_value("progress", "journey_cleared_to", journey_cleared_to)
	cfg.set_value("progress", "selected_level", selected_level)
	cfg.set_value("progress", "selected_character", selected_character)
	cfg.set_value("progress", "selected_language", selected_language)
	cfg.set_value("progress", "last_os_language", last_os_language)
	cfg.set_value("progress", "game_volume", game_volume)
	cfg.set_value("progress", "total_coins", total_coins)
	for i in range(1, IMPLEMENTED_LEVELS + 1):
		cfg.set_value("coins", "lvl_%d" % i, int(best_coins.get(i, 0)))
	cfg.save(SAVE_PATH)


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	total_coins += amount
	save_progress()


func can_afford(cost: int) -> bool:
	return total_coins >= cost


func spend_coins(cost: int) -> bool:
	if total_coins < cost:
		return false
	total_coins -= cost
	save_progress()
	return true


func needs_journey_to(lvl: int) -> bool:
	return lvl > 1 and lvl <= unlocked_level and journey_cleared_to < lvl


func record_level_win(lvl: int, coins: int) -> bool:
	var newly_unlocked := false
	var prev_best := int(best_coins.get(lvl, 0))
	if coins > prev_best:
		best_coins[lvl] = coins
	if lvl >= unlocked_level and unlocked_level < IMPLEMENTED_LEVELS:
		unlocked_level = lvl + 1
		selected_level = unlocked_level
		newly_unlocked = true
	save_progress()
	return newly_unlocked


func record_journey_arrival(target_lvl: int) -> void:
	if target_lvl > journey_cleared_to:
		journey_cleared_to = clampi(target_lvl, 1, IMPLEMENTED_LEVELS)
	if target_lvl > unlocked_level:
		unlocked_level = clampi(target_lvl, 1, IMPLEMENTED_LEVELS)
	selected_level = clampi(target_lvl, 1, IMPLEMENTED_LEVELS)
	save_progress()
