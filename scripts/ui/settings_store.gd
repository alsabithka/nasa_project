class_name SettingsStore
extends RefCounted

## Echoes Beyond Earth — SettingsStore (Phase 3)
## Standalone persistence for player settings in user://settings.cfg.
## No Autoload and GameState is untouched. Everything is static:
##   SettingsStore.get_value("master_volume")
##   SettingsStore.set_value("reduced_motion", true)   # then SettingsStore.save()
##   SettingsStore.apply(get_tree())                   # push values to buses / player
## Motion code multiplies durations by SettingsStore.motion_scale() (0.0 when reduced motion is on).

const CFG_PATH := "user://settings.cfg"
const SECTION := "settings"
## player.gd's own default; the stored setting is a multiplier of this.
const BASE_MOUSE_SENSITIVITY := 0.0028
const MOUSE_MULT_MIN := 0.25
const MOUSE_MULT_MAX := 2.0

const DEFAULTS := {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
	"mouse_sensitivity": 1.0,
	"reduced_motion": false,
	"fullscreen": false,
	"first_run_shown": false,
}

static var _cache: Dictionary = {}
static var _loaded: bool = false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_cache = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		if cfg.has_section(SECTION):
			for key in cfg.get_section_keys(SECTION):
				_cache[key] = cfg.get_value(SECTION, key)
	# Older scaffolds stored sensitivity on a different scale; keep it in range.
	_cache["mouse_sensitivity"] = clampf(float(_cache["mouse_sensitivity"]), MOUSE_MULT_MIN, MOUSE_MULT_MAX)


## Re-read the file (used when a menu opens, in case another surface changed it).
static func reload() -> void:
	_loaded = false
	_ensure_loaded()


static func get_value(key: String) -> Variant:
	_ensure_loaded()
	return _cache.get(key, DEFAULTS.get(key))


static func set_value(key: String, value: Variant) -> void:
	_ensure_loaded()
	_cache[key] = value


static func save() -> void:
	_ensure_loaded()
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)  # keep keys we do not know about
	for key in _cache.keys():
		cfg.set_value(SECTION, key, _cache[key])
	var err: int = cfg.save(CFG_PATH)
	if err != OK:
		push_warning("SettingsStore: could not write %s (error %d)" % [CFG_PATH, err])


## 0.0 when reduced motion is on, otherwise 1.0. Multiply tween durations by this.
static func motion_scale() -> float:
	return 0.0 if bool(get_value("reduced_motion")) else 1.0


static func mouse_sensitivity_value() -> float:
	return BASE_MOUSE_SENSITIVITY * float(get_value("mouse_sensitivity"))


## True when the project has an audio bus with this name (Master always exists).
static func has_bus(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1


static func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


## Push stored values to the engine. Safe to call at any time, in any scene.
static func apply(tree: SceneTree) -> void:
	_ensure_loaded()
	_set_bus_linear("Master", float(get_value("master_volume")))
	_set_bus_linear("Music", float(get_value("music_volume")))
	_set_bus_linear("SFX", float(get_value("sfx_volume")))
	_apply_fullscreen()
	if tree != null:
		var player: Node = tree.get_first_node_in_group("player")
		if player != null and "mouse_sensitivity" in player:
			player.set("mouse_sensitivity", mouse_sensitivity_value())


## Window mode from the stored "fullscreen" flag. No-op on headless / when already in that mode.
static func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var want: bool = bool(get_value("fullscreen"))
	var is_fs: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if want != is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if want else DisplayServer.WINDOW_MODE_WINDOWED)


## First-run flag shared with the Field Manual.
static func first_run_pending() -> bool:
	return not bool(get_value("first_run_shown"))


static func mark_first_run_done() -> void:
	set_value("first_run_shown", true)
	save()
