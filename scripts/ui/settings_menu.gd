extends CanvasLayer

# Echoes Beyond Earth — Settings Menu (Phase 3)
# Persists to user://settings.cfg via ConfigFile
# Layer: UITokens.LAYER_SYSTEM (40)

signal settings_closed

const UITokens = preload("res://scripts/ui/ui_tokens.gd")
const CFG_PATH := "user://settings.cfg"

# Sliders / toggles (populated in _build_ui)
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _mouse_slider: HSlider
var _text_scale_opts: OptionButton

# Persistent settings
var _settings := {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
	"mouse_sensitivity": 0.3,
	"text_scale": 100,
}

var _overlay: ColorRect
var _card: PanelContainer


func _ready() -> void:
	layer = UITokens.LAYER_SYSTEM
	_load_settings()
	_build_ui()
	visible = false


# ─── Persistence ───────────────────────────────────────────────────────────────

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		for key in _settings.keys():
			if cfg.has_section_key("settings", key):
				_settings[key] = cfg.get_value("settings", key)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	# Preserve any existing keys (e.g. first_run_shown)
	cfg.load(CFG_PATH)
	for key in _settings.keys():
		cfg.set_value("settings", key, _settings[key])
	cfg.save(CFG_PATH)
	_apply_settings()


func _apply_settings() -> void:
	# Audio buses  (graceful if fewer buses exist)
	AudioServer.set_bus_volume_db(0, linear_to_db(_settings["master_volume"]))
	if AudioServer.bus_count > 1:
		AudioServer.set_bus_volume_db(1, linear_to_db(_settings["music_volume"]))
	if AudioServer.bus_count > 2:
		AudioServer.set_bus_volume_db(2, linear_to_db(_settings["sfx_volume"]))
	# Mouse sensitivity — broadcast so player.gd can read it
	var player = get_tree().get_first_node_in_group("player")
	if player and "mouse_sensitivity" in player:
		player.mouse_sensitivity = _settings["mouse_sensitivity"]


# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.color = Color(UITokens.INK_900, 0.90)
	_overlay.gui_input.connect(func(_e): pass)   # consume clicks on overlay
	add_child(_overlay)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -300.0
	_card.offset_top = -260.0
	_card.offset_right = 300.0
	_card.offset_bottom = 260.0
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH

	var sty := StyleBoxFlat.new()
	sty.bg_color = UITokens.INK_800
	sty.border_width_left = 3
	sty.border_width_top = 3
	sty.border_width_right = 3
	sty.border_width_bottom = 3
	sty.border_color = UITokens.PAPER_500
	sty.content_margin_left = 36.0
	sty.content_margin_top = 28.0
	sty.content_margin_right = 36.0
	sty.content_margin_bottom = 28.0
	_card.add_theme_stylebox_override("panel", sty)
	add_child(_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_card.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	title.add_theme_font_size_override("font_size", UITokens.TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "[ CLOSE ]"
	close_btn.flat = true
	close_btn.add_theme_color_override("font_color", UITokens.PAPER_300)
	close_btn.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	close_btn.pressed.connect(_on_close)
	title_row.add_child(close_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Audio section
	_add_section_header(vbox, "AUDIO")
	_master_slider = _add_slider_row(vbox, "Master Volume",
		_settings["master_volume"], 0.0, 1.0, 0.05,
		func(v): _settings["master_volume"] = v; _apply_settings())
	_music_slider = _add_slider_row(vbox, "Music Volume",
		_settings["music_volume"], 0.0, 1.0, 0.05,
		func(v): _settings["music_volume"] = v; _apply_settings())
	_sfx_slider = _add_slider_row(vbox, "SFX Volume",
		_settings["sfx_volume"], 0.0, 1.0, 0.05,
		func(v): _settings["sfx_volume"] = v; _apply_settings())

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Controls section
	_add_section_header(vbox, "CONTROLS")
	_mouse_slider = _add_slider_row(vbox, "Mouse Sensitivity",
		_settings["mouse_sensitivity"], 0.05, 1.0, 0.05,
		func(v): _settings["mouse_sensitivity"] = v; _apply_settings())

	var sep3 := HSeparator.new()
	vbox.add_child(sep3)

	# Accessibility section
	_add_section_header(vbox, "ACCESSIBILITY")

	var scale_row := HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 16)
	vbox.add_child(scale_row)

	var scale_lbl := Label.new()
	scale_lbl.text = "Text Scale"
	scale_lbl.add_theme_color_override("font_color", UITokens.PAPER_300)
	scale_lbl.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	scale_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_row.add_child(scale_lbl)

	_text_scale_opts = OptionButton.new()
	_text_scale_opts.add_item("100%", 0)
	_text_scale_opts.add_item("125%", 1)
	_text_scale_opts.add_item("150%", 2)
	match _settings["text_scale"]:
		125: _text_scale_opts.selected = 1
		150: _text_scale_opts.selected = 2
		_:   _text_scale_opts.selected = 0
	_text_scale_opts.item_selected.connect(_on_text_scale_selected)
	scale_row.add_child(_text_scale_opts)


func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", UITokens.PAPER_500)
	lbl.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	parent.add_child(lbl)


func _add_slider_row(parent: VBoxContainer, label_text: String,
		init_val: float, min_val: float, max_val: float, step: float,
		on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", UITokens.PAPER_300)
	lbl.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	lbl.custom_minimum_size = Vector2(160, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = init_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
	val_lbl.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	val_lbl.custom_minimum_size = Vector2(42, 0)
	val_lbl.text = "%.0f%%" % (init_val * 100)
	row.add_child(val_lbl)

	# Keep label in sync
	slider.value_changed.connect(func(v): val_lbl.text = "%.0f%%" % (v * 100))
	return slider


func _on_text_scale_selected(index: int) -> void:
	match index:
		1: _settings["text_scale"] = 125
		2: _settings["text_scale"] = 150
		_: _settings["text_scale"] = 100
	# Theme font size scaling is applied in Phase 7; store for now.
	_save_settings()


func _on_close() -> void:
	_save_settings()
	visible = false
	emit_signal("settings_closed")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()


func show_settings() -> void:
	_load_settings()
	if _master_slider: _master_slider.value = _settings["master_volume"]
	if _music_slider:  _music_slider.value  = _settings["music_volume"]
	if _sfx_slider:    _sfx_slider.value    = _settings["sfx_volume"]
	if _mouse_slider:  _mouse_slider.value  = _settings["mouse_sensitivity"]
	visible = true
