extends ModalShell

# Echoes Beyond Earth — Settings (Phase 3)
# Persists through SettingsStore (user://settings.cfg). GameState is not touched.
# Rows: master volume, music/SFX volume (only when those audio buses exist),
# mouse sensitivity (multiplier of the player's default), fullscreen, reduced motion.
# Text scale and high contrast arrive in Phase 7 — they are not shown until they work.

signal settings_closed

var _rows: Array[Dictionary] = []   # {slider, label, key, fmt}
var _motion_btn: Button
var _fullscreen_btn: Button
var _first_focus: Control = null


func _init() -> void:
	title_text = "Settings"
	card_width = 600


func _build_content() -> void:
	closed.connect(_on_closed)

	_add_section("AUDIO")
	_add_slider_row("Master volume", "master_volume", 0.0, 1.0, 0.05, "pct")
	if SettingsStore.has_bus("Music"):
		_add_slider_row("Music volume", "music_volume", 0.0, 1.0, 0.05, "pct")
	if SettingsStore.has_bus("SFX"):
		_add_slider_row("Effects volume", "sfx_volume", 0.0, 1.0, 0.05, "pct")

	_add_section("DISPLAY")
	_fullscreen_btn = _add_toggle_row("Fullscreen", "Fill the whole screen. Takes effect immediately.", "fullscreen")

	_add_section("CONTROLS")
	_add_slider_row("Mouse sensitivity", "mouse_sensitivity",
		SettingsStore.MOUSE_MULT_MIN, SettingsStore.MOUSE_MULT_MAX, 0.05, "mult")

	_add_section("ACCESSIBILITY")
	_add_motion_row()

	var rule := ColorRect.new()
	rule.color = UITokens.INK_600
	rule.custom_minimum_size = Vector2(0, 1)
	body.add_child(rule)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", UITokens.SP_3)
	body.add_child(foot)
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.theme_type_variation = &"GhostButton"
	reset.pressed.connect(_on_reset)
	foot.add_child(reset)


func _add_section(text: String) -> void:
	var h := SectionHeader.new()
	h.title = text
	body.add_child(h)


func _fmt(kind: String, v: float) -> String:
	return "%d%%" % int(round(v * 100.0)) if kind == "pct" else "%.2f×" % v


func _add_slider_row(label_text: String, key: String, lo: float, hi: float, step: float, kind: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_4)
	body.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(170, 0)
	row.add_child(lbl)

	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(SettingsStore.get_value(key))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ModalShell.style_slider(s)
	row.add_child(s)

	var val := Label.new()
	val.theme_type_variation = &"StatLabel"
	val.custom_minimum_size = Vector2(64, 0)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.text = _fmt(kind, s.value)
	row.add_child(val)

	s.value_changed.connect(func(v: float) -> void:
		SettingsStore.set_value(key, v)
		val.text = _fmt(kind, v)
		SettingsStore.apply(get_tree())
	)
	s.drag_ended.connect(func(_changed: bool) -> void: SettingsStore.save())
	# Keyboard / gamepad changes do not emit drag_ended; save on focus loss too.
	s.focus_exited.connect(SettingsStore.save)

	_rows.append({"slider": s, "label": val, "key": key, "kind": kind})
	if _first_focus == null:
		_first_focus = s


func _add_motion_row() -> void:
	_motion_btn = _add_toggle_row("Reduced motion", "Removes fades and slide-ins. Scene changes become instant cuts.", "reduced_motion")


## Label + hint on the left, On/Off toggle on the right. State is carried by text AND icon.
func _add_toggle_row(label_text: String, hint_text: String, key: String) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_4)
	body.add_child(row)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var lbl := Label.new()
	lbl.text = label_text
	col.add_child(lbl)
	var hint := Label.new()
	hint.text = hint_text
	hint.theme_type_variation = &"CaptionLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)

	var b := Button.new()
	b.toggle_mode = true
	b.theme_type_variation = &"GhostButton"
	b.custom_minimum_size = Vector2(96, 0)
	b.button_pressed = bool(SettingsStore.get_value(key))
	b.toggled.connect(func(_p: bool) -> void:
		SettingsStore.set_value(key, b.button_pressed)
		SettingsStore.save()
		SettingsStore.apply(get_tree())
		_refresh_toggle(b)
	)
	row.add_child(b)
	_refresh_toggle(b)
	return b


func _refresh_toggle(b: Button) -> void:
	var on: bool = b.button_pressed
	b.text = "On" if on else "Off"
	b.icon = UITokens.icon("check") if on else null


func _on_reset() -> void:
	for key in ["master_volume", "music_volume", "sfx_volume", "mouse_sensitivity", "reduced_motion", "fullscreen"]:
		SettingsStore.set_value(key, SettingsStore.DEFAULTS[key])
	for r in _rows:
		var s: HSlider = r["slider"]
		s.value = float(SettingsStore.get_value(r["key"]))
	_motion_btn.button_pressed = false
	_fullscreen_btn.button_pressed = false
	SettingsStore.save()
	SettingsStore.apply(get_tree())


func _on_closed() -> void:
	SettingsStore.save()
	settings_closed.emit()


## Public entry point (kept from the earlier scaffold): refresh from disk and show.
func show_settings() -> void:
	SettingsStore.reload()
	for r in _rows:
		var s: HSlider = r["slider"]
		s.value = float(SettingsStore.get_value(r["key"]))
	if _motion_btn != null:
		_motion_btn.set_pressed_no_signal(bool(SettingsStore.get_value("reduced_motion")))
		_refresh_toggle(_motion_btn)
	if _fullscreen_btn != null:
		_fullscreen_btn.set_pressed_no_signal(bool(SettingsStore.get_value("fullscreen")))
		_refresh_toggle(_fullscreen_btn)
	open(_first_focus)
