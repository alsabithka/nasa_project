extends CanvasLayer

# Echoes Beyond Earth — Pause Menu (Phase 3)
# Layer: UITokens.LAYER_SYSTEM (40)
# Signals: resume_requested, open_journal_requested, open_settings_requested

signal resume_requested
signal open_journal_requested
signal open_settings_requested

const UITokens = preload("res://scripts/ui/ui_tokens.gd")

var _overlay: ColorRect
var _card: PanelContainer
var _visible: bool = false

func _ready() -> void:
	layer = UITokens.LAYER_SYSTEM
	_build_ui()
	hide_pause()

func _build_ui() -> void:
	# Dark full-screen overlay
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.color = Color(UITokens.INK_900, 0.88)
	add_child(_overlay)

	# Central card — left-aligned at 40% width, vertically centred
	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_card.anchor_left = 0.0
	_card.anchor_top = 0.5
	_card.anchor_right = 0.0
	_card.anchor_bottom = 0.5
	_card.offset_left = 80.0
	_card.offset_top = -200.0
	_card.offset_right = 480.0
	_card.offset_bottom = 200.0
	_card.grow_horizontal = Control.GROW_DIRECTION_END
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = UITokens.INK_800
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = UITokens.PAPER_500
	card_style.corner_radius_top_left = 0
	card_style.corner_radius_top_right = 0
	card_style.corner_radius_bottom_left = 0
	card_style.corner_radius_bottom_right = 0
	card_style.content_margin_left = 36.0
	card_style.content_margin_top = 32.0
	card_style.content_margin_right = 36.0
	card_style.content_margin_bottom = 32.0
	_card.add_theme_stylebox_override("panel", card_style)
	add_child(_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_card.add_child(vbox)

	# Header rule
	var header := Label.new()
	header.text = "— PAUSED —"
	header.add_theme_color_override("font_color", UITokens.PAPER_300)
	header.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(header)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	vbox.add_child(sep)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer1)

	# Menu items
	_add_menu_item(vbox, "RESUME",        "R / Esc",  UITokens.SIGNAL_CYAN,  _on_resume)
	_add_menu_item(vbox, "JOURNAL",       "J",        UITokens.PAPER_100,    _on_journal)
	_add_menu_item(vbox, "SETTINGS",      "—",        UITokens.PAPER_100,    _on_settings)
	_add_menu_item(vbox, "QUIT TO MENU",  "M",        UITokens.SIGNAL_RED,   _on_quit)


func _add_menu_item(parent: VBoxContainer, label_text: String, key_hint: String,
		col: Color, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	# Key hint badge
	var key_lbl := Label.new()
	key_lbl.text = "[ %s ]" % key_hint
	key_lbl.custom_minimum_size = Vector2(80, 0)
	key_lbl.add_theme_color_override("font_color", UITokens.PAPER_500)
	key_lbl.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	row.add_child(key_lbl)

	# Clickable label styled as a button
	var btn := Button.new()
	btn.text = label_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", UITokens.PAPER_100)
	btn.add_theme_font_size_override("font_size", UITokens.TEXT_LEAD)
	btn.pressed.connect(callback)
	row.add_child(btn)


func _unhandled_input(event: InputEvent) -> void:
	if not _visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_on_resume()
				get_viewport().set_input_as_handled()
			KEY_J:
				_on_journal()
				get_viewport().set_input_as_handled()
			KEY_M:
				_on_quit()
				get_viewport().set_input_as_handled()


func _on_resume() -> void:
	hide_pause()
	emit_signal("resume_requested")


func _on_journal() -> void:
	hide_pause()
	emit_signal("open_journal_requested")


func _on_settings() -> void:
	emit_signal("open_settings_requested")


func _on_quit() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Quit to Menu?"
	dlg.dialog_text = "Any unsaved progress will be lost."
	dlg.ok_button_text = "Quit"
	dlg.cancel_button_text = "Cancel"
	dlg.confirmed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	add_child(dlg)
	dlg.popup_centered()


func show_pause() -> void:
	_visible = true
	_overlay.visible = true
	_card.visible = true
	get_tree().paused = true


func hide_pause() -> void:
	_visible = false
	if _overlay:
		_overlay.visible = false
	if _card:
		_card.visible = false
	get_tree().paused = false
