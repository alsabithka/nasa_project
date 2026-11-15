extends CanvasLayer

# Echoes Beyond Earth - Excavation prompt (Phase 5)
# Instrument register: a translucent HudPanel in the same bottom-centre "prompt zone" as the
# WorldHud contextual prompt. 14 px minimum, key-caps read from the InputMap, ONE primary action
# (interact), secondary (inspect_signal) and cancel (ui_cancel).
# Contract kept: signals begin_excavation_requested / inspect_signal_requested / menu_cancelled,
# set_anomaly_details(title, depth, sig), fields _title_label / _details_label.

signal begin_excavation_requested()
signal inspect_signal_requested()
signal menu_cancelled()

const InputSetup = preload("res://scripts/input/input_setup.gd")

var site_name: String = "Unidentified Anomaly"
var depth_cm: float = 14.0
var signal_type: String = "Conductive Metal"

var _panel: HudPanel
var _title_label: Label
var _details_label: Label
var _btn_excavate: Button
var _btn_inspect: Button
var _btn_cancel: Button


func _ready() -> void:
	layer = UITokens.LAYER_SYSTEM  # 40 — above pause menu, below debug
	InputSetup.ensure()
	_build_menu()


func _build_menu() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITokens.theme()
	add_child(root)

	_panel = HudPanel.new()
	root.add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -float(WorldHud.MARGIN + 96)   # same zone as WorldHud.show_prompt()

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(col)

	# Header: icon + title (left), SIM badge (right). Depth and signal are in-game survey readings.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UITokens.SP_2)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	head.add_child(UITokens.make_icon("signal_dig", UITokens.SIGNAL_CYAN, 18))
	_title_label = Label.new()
	_title_label.text = "EXCAVATION SITE CONFIRMED"
	_title_label.theme_type_variation = &"LeadLabel"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_title_label)
	head.add_child(Badge.make(Badge.Kind.SIM, "FIELD READING"))

	_details_label = Label.new()
	_details_label.theme_type_variation = &"StatLabel"   # Plex Mono — readout
	_details_label.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	_details_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	_details_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_details_label)
	_refresh_details()

	var rule := ColorRect.new()
	rule.color = UITokens.INK_600
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", UITokens.SP_4)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(actions)

	_btn_excavate = _make_action(actions, "interact", "BEGIN EXCAVATION", &"PrimaryButton", _on_excavate_pressed)
	_btn_inspect = _make_action(actions, "inspect_signal", "INSPECT SIGNAL", &"GhostButton", _on_inspect_pressed)
	_btn_cancel = _make_action(actions, "ui_cancel", "CANCEL", &"GhostButton", _on_cancel_pressed)


## One action = key-cap + button. Buttons never take focus: the mouse is normally captured here,
## and Space/Enter must not trigger them by accident while walking.
func _make_action(parent: Control, action: String, label_text: String, variation: StringName, handler: Callable) -> Button:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", UITokens.SP_2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	var cap := KeyCap.new()
	cap.action_name = action
	if action == "ui_cancel":
		cap.label_override = "Esc"
	box.add_child(cap)
	var btn := Button.new()
	btn.text = label_text
	btn.theme_type_variation = variation
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(handler)
	box.add_child(btn)
	return btn


func _refresh_details() -> void:
	if _details_label:
		_details_label.text = "Est. depth ~%.1f cm  ·  Signal: %s" % [depth_cm, signal_type]


func set_anomaly_details(title: String, depth: float, sig: String) -> void:
	site_name = title
	depth_cm = depth
	signal_type = sig
	_refresh_details()


# E / Q keep their previous (unhandled) timing so the dig hand-over to artifact.gd is unchanged.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_on_excavate_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inspect_signal"):
		_on_inspect_pressed()
		get_viewport().set_input_as_handled()


# Esc is taken in _input so it is consumed BEFORE the HUD (opens pause) and the player (releases
# the mouse) see it. One key, one meaning: "cancel the topmost thing".
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


func _on_excavate_pressed() -> void:
	begin_excavation_requested.emit()
	queue_free()


func _on_inspect_pressed() -> void:
	inspect_signal_requested.emit()
	queue_free()


func _on_cancel_pressed() -> void:
	menu_cancelled.emit()
	queue_free()
