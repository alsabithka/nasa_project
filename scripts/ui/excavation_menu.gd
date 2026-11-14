extends CanvasLayer

# Echoes Beyond Earth - Minimalist Lunar Excavation Direction Menu
# Appears unobtrusively near lower screen when an anomaly is verified by the detector.
# Requirements:
# - Minimal interface, small typography
# - Subtle translucent dark background, crisp light-grey text
# - Direct keyboard triggers: [E] Excavate, [Q] Inspect, [ESC] Cancel
# - No oversized buttons or bright yellow circles

signal begin_excavation_requested()
signal inspect_signal_requested()
signal menu_cancelled()

var site_name: String = "Unidentified Anomaly"
var depth_cm: float = 14.0
var signal_type: String = "Conductive Metal"

var _panel: PanelContainer
var _title_label: Label
var _details_label: Label
var _btn_excavate: Button
var _btn_inspect: Button
var _btn_cancel: Button

func _ready() -> void:
	layer = 110
	_build_minimalist_menu()

func _build_minimalist_menu() -> void:
	# Root container anchored near bottom center (Y offset 72% - 88%)
	var root_box = Control.new()
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_box)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(340, 115)
	
	# Translucent dark slate styling
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.10, 0.88) # Low-profile dark background
	sb.border_color = Color(0.35, 0.45, 0.55, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 12.0
	_panel.add_theme_stylebox_override("panel", sb)

	# Center horizontally, position near bottom
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_top = -140
	_panel.offset_bottom = -25
	_panel.offset_left = -170
	_panel.offset_right = 170
	root_box.add_child(_panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panel.add_child(vb)

	# Title: EXCAVATION SITE CONFIRMED
	_title_label = Label.new()
	_title_label.text = "EXCAVATION SITE CONFIRMED"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 12)
	_title_label.modulate = Color(0.88, 0.93, 1.0)
	vb.add_child(_title_label)

	# Subtitle: Depth & Signal
	_details_label = Label.new()
	_details_label.text = "Estimated Depth: ~%.1f cm  •  Signal: %s" % [depth_cm, signal_type]
	_details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details_label.add_theme_font_size_override("font_size", 10)
	_details_label.modulate = Color(0.65, 0.72, 0.82)
	vb.add_child(_details_label)

	var sep = HSeparator.new()
	sep.modulate = Color(0.3, 0.4, 0.5, 0.4)
	vb.add_child(sep)

	# Action options row
	var action_row = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 14)
	vb.add_child(action_row)

	_btn_excavate = _create_action_label(action_row, "[ E ]", "Begin Excavation", Color(0.4, 0.9, 0.5))
	_btn_inspect = _create_action_label(action_row, "[ Q ]", "Inspect Signal", Color(0.5, 0.8, 1.0))
	_btn_cancel = _create_action_label(action_row, "[ ESC ]", "Cancel", Color(0.7, 0.75, 0.8))

func _create_action_label(parent: Node, key_tag: String, label_text: String, col: Color) -> Button:
	var btn = Button.new()
	btn.flat = true
	btn.text = "%s %s" % [key_tag, label_text]
	btn.add_theme_font_size_override("font_size", 11)
	btn.modulate = col
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if key_tag == "[ E ]":
		btn.pressed.connect(func(): _on_excavate_pressed())
	elif key_tag == "[ Q ]":
		btn.pressed.connect(func(): _on_inspect_pressed())
	elif key_tag == "[ ESC ]":
		btn.pressed.connect(func(): _on_cancel_pressed())
	
	parent.add_child(btn)
	return btn

func set_anomaly_details(title: String, depth: float, sig: String) -> void:
	site_name = title
	depth_cm = depth
	signal_type = sig
	if _details_label:
		_details_label.text = "Estimated Depth: ~%.1f cm  •  Signal: %s" % [depth_cm, signal_type]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_on_excavate_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		_on_inspect_pressed()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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
