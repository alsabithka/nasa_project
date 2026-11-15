extends Control

# Echoes Beyond Earth — Main Menu (Phase 3)
# Archive register: drawn hero backdrop, left-aligned column on the grid, planets as chapters with
# progress, Mars locked with its reason (never a clickable contradiction), full keyboard/gamepad focus.
# Built in code from Theme + components; the scene file only holds the root node.

const MOON_SCENE := "res://scenes/levels/moon.tscn"
const MARS_SCENE := "res://scenes/levels/mars.tscn"
const GALLERY_SCENE := "res://scenes/spacecraft/spacecraft_gallery.tscn"
const COLUMN_WIDTH := 480

var _moon_btn: ChapterButton
var _mars_btn: ChapterButton
var _settings: Node = null
var _manual: Node = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	theme = UITokens.theme()
	SettingsStore.apply(get_tree())
	_build()
	_moon_btn.grab_focus.call_deferred()


func _build() -> void:
	var backdrop := HeroBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", UITokens.SP_12 + UITokens.SP_4)
	margin.add_theme_constant_override("margin_right", UITokens.SP_12)
	margin.add_theme_constant_override("margin_top", UITokens.SP_12)
	margin.add_theme_constant_override("margin_bottom", UITokens.SP_8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_theme_constant_override("separation", UITokens.SP_3)
	margin.add_child(col)

	# Title block
	var title := Label.new()
	title.text = "ECHOES\nBEYOND EARTH"
	title.theme_type_variation = &"HeroLabel"
	title.add_theme_color_override("font_color", UITokens.PAPER_100)
	col.add_child(title)

	var tag := Label.new()
	tag.text = "A NASA archaeological expedition"
	tag.theme_type_variation = &"LeadLabel"
	tag.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	col.add_child(tag)

	col.add_child(_spacer(UITokens.SP_6))

	# Chapters
	var head := SectionHeader.new()
	head.title = "CHAPTERS"
	col.add_child(head)

	_moon_btn = ChapterButton.new()
	col.add_child(_moon_btn)
	_mars_btn = ChapterButton.new()
	col.add_child(_mars_btn)
	_update_chapters()
	_moon_btn.pressed.connect(func() -> void: SceneFade.go(get_tree(), MOON_SCENE))
	_mars_btn.pressed.connect(func() -> void: SceneFade.go(get_tree(), MARS_SCENE))

	col.add_child(_spacer(UITokens.SP_4))

	# Secondary actions
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UITokens.SP_2)
	grid.add_theme_constant_override("v_separation", UITokens.SP_2)
	col.add_child(grid)
	_add_secondary(grid, "Spacecraft gallery", "archive", func() -> void: SceneFade.go(get_tree(), GALLERY_SCENE))
	_add_secondary(grid, "Field manual", "scan", _show_field_manual)
	_add_secondary(grid, "Settings", "settings", _show_settings)
	_add_secondary(grid, "Credits", "stamp", _show_credits)
	_add_secondary(grid, "Quit", "close", func() -> void: get_tree().quit())


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _add_secondary(parent: Control, text: String, icon_name: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.icon = UITokens.icon(icon_name)
	b.theme_type_variation = &"GhostButton"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(float(COLUMN_WIDTH - UITokens.SP_2) / 2.0, 40)
	b.pressed.connect(cb)
	parent.add_child(b)


# ── Chapters ───────────────────────────────────────────────────────────────────────────

func _update_chapters() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var moon_found: int = 0
	var moon_total: int = 0
	var mars_found: int = 0
	var mars_total: int = 0
	var mars_open: bool = false
	if gs != null:
		moon_found = int(gs.call("get_recovered_count", "Moon"))
		moon_total = int(gs.call("get_total_count", "Moon"))
		mars_found = int(gs.call("get_recovered_count", "Mars"))
		mars_total = int(gs.call("get_total_count", "Mars"))
		mars_open = bool(gs.call("is_planet_unlocked", "Mars"))
	_moon_btn.setup("MOON", "moon", moon_found, moon_total)
	if mars_open:
		_mars_btn.setup("MARS", "mars", mars_found, mars_total)
	else:
		_mars_btn.setup("MARS", "mars", 0, mars_total, "Locked. Catalogue every Moon artifact to unlock.")


# ── Modals ─────────────────────────────────────────────────────────────────────────────

func _show_settings() -> void:
	if _settings == null or not is_instance_valid(_settings):
		var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn") as PackedScene
		if scene == null:
			return
		_settings = scene.instantiate()
		add_child(_settings)
	_settings.show_settings()


func _show_field_manual() -> void:
	if _manual == null or not is_instance_valid(_manual):
		var scene: PackedScene = load("res://scenes/ui/field_manual.tscn") as PackedScene
		if scene == null:
			return
		_manual = scene.instantiate()
		add_child(_manual)
	_manual.show_manual()


func _show_credits() -> void:
	var m := ModalShell.new()
	m.title_text = "Credits"
	m.card_width = 600
	add_child(m)  # builds the shell, so m.body exists from here on
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.body.add_child(scroll)
	var text := Label.new()
	text.text = _credits_text()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("font_color", UITokens.PAPER_300)
	scroll.add_child(text)
	m.closed.connect(m.queue_free)
	m.open(scroll)


## CREDITS.md is not exported with the game by default, so fall back to a short built-in text.
func _credits_text() -> String:
	var path := "res://CREDITS.md"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var raw: String = f.get_as_text()
			return raw.replace("**", "").replace("`", "").replace("## ", "").replace("# ", "").strip_edges()
	return "Fonts: IBM Plex Sans and IBM Plex Mono (SIL Open Font License 1.1).\nIcons: original artwork made for this project."
