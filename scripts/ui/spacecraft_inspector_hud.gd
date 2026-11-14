extends CanvasLayer
class_name SpacecraftInspectorHUD

# Echoes Beyond Earth - NASA Spacecraft Component Inspector HUD
# Displays historical mission context, engineering telemetry, and lets the player
# cycle through and inspect individual mechanical subsystems in detail.

signal inspection_closed()

var spacecraft_root: Node3D = null
var artifact_id: String = ""

var _components: Array[Dictionary] = []
var _current_idx: int = 0

var title_label: Label
var subtitle_label: Label
var comp_name_label: Label
var comp_desc_label: Label
var comp_spec_label: Label
var counter_label: Label

func open_inspector(target_node: Node3D, target_artifact_id: String) -> void:
	spacecraft_root = target_node
	artifact_id = target_artifact_id
	_scan_components()
	_update_display()
	show()

func _ready() -> void:
	layer = 12
	_build_ui()

func _scan_components() -> void:
	_components.clear()
	if not spacecraft_root:
		return

	# Collect all nodes with component metadata
	_recursive_scan(spacecraft_root)
	if _components.is_empty():
		_components.append({
			"name": spacecraft_root.get_meta("component_name", spacecraft_root.name),
			"desc": spacecraft_root.get_meta("component_desc", "Historical NASA space exploration hardware."),
			"spec": spacecraft_root.get_meta("component_spec", "Authentic space mission engineering asset.")
		})
	_current_idx = 0

func _recursive_scan(node: Node) -> void:
	if node.has_meta("component_name"):
		_components.append({
			"node": node,
			"name": node.get_meta("component_name"),
			"desc": node.get_meta("component_desc"),
			"spec": node.get_meta("component_spec")
		})
	for child in node.get_children():
		_recursive_scan(child)

func _build_ui() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Bottom Center Inspection Panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 64
	panel.offset_right = -64
	panel.offset_bottom = -24
	panel.offset_top = -220
	root.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.90)
	style.border_color = Color(0.24, 0.58, 0.88, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Header HBox
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_box)

	title_label = Label.new()
	title_label.text = "NASA HISTORICAL HARDWARE INSPECTION"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
	title_box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Geographical Surface Telemetry: Active"
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	title_box.add_child(subtitle_label)

	counter_label = Label.new()
	counter_label.text = "COMPONENT [1/1]"
	counter_label.add_theme_font_size_override("font_size", 14)
	counter_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	header_hbox.add_child(counter_label)

	var h_sep = HSeparator.new()
	vbox.add_child(h_sep)

	# Component Details
	comp_name_label = Label.new()
	comp_name_label.text = "COMPONENT NAME"
	comp_name_label.add_theme_font_size_override("font_size", 16)
	comp_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(comp_name_label)

	comp_desc_label = Label.new()
	comp_desc_label.text = "Component description and engineering function..."
	comp_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comp_desc_label.add_theme_font_size_override("font_size", 13)
	comp_desc_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95))
	vbox.add_child(comp_desc_label)

	comp_spec_label = Label.new()
	comp_spec_label.text = "Technical Specifications: -"
	comp_spec_label.add_theme_font_size_override("font_size", 12)
	comp_spec_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.65))
	vbox.add_child(comp_spec_label)

	# Navigation Controls HBox
	var nav_hbox = HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(nav_hbox)

	var prev_btn = Button.new()
	prev_btn.text = "< Previous Component [Q / Left]"
	prev_btn.pressed.connect(_on_prev_pressed)
	nav_hbox.add_child(prev_btn)

	var next_btn = Button.new()
	next_btn.text = "Next Component [E / Right] >"
	next_btn.pressed.connect(_on_next_pressed)
	nav_hbox.add_child(next_btn)

	var close_btn = Button.new()
	close_btn.text = "Resume Exploration [ESC / Space]"
	close_btn.pressed.connect(close_inspector)
	nav_hbox.add_child(close_btn)

func _update_display() -> void:
	if _components.is_empty():
		return

	_current_idx = clampi(_current_idx, 0, _components.size() - 1)
	var comp = _components[_current_idx]

	if spacecraft_root and spacecraft_root.has_meta("component_name"):
		title_label.text = spacecraft_root.get_meta("component_name").to_upper()
		subtitle_label.text = spacecraft_root.get_meta("component_desc")

	counter_label.text = "COMPONENT [%d / %d]" % [_current_idx + 1, _components.size()]
	comp_name_label.text = "• " + str(comp.get("name", "Component"))
	comp_desc_label.text = str(comp.get("desc", ""))
	comp_spec_label.text = "SPECIFICATIONS: " + str(comp.get("spec", "Standard NASA Flight Hardware"))

func _on_prev_pressed() -> void:
	if _components.size() > 0:
		_current_idx = (_current_idx - 1 + _components.size()) % _components.size()
		_update_display()

func _on_next_pressed() -> void:
	if _components.size() > 0:
		_current_idx = (_current_idx + 1) % _components.size()
		_update_display()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_inspector()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and (event.keycode == KEY_Q or event.keycode == KEY_LEFT)):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_RIGHT)):
		_on_next_pressed()
		get_viewport().set_input_as_handled()

func close_inspector() -> void:
	hide()
	inspection_closed.emit()
	queue_free()
