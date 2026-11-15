extends CanvasLayer
class_name SpacecraftInspectorHUD

# Echoes Beyond Earth - NASA Spacecraft Component Inspector HUD
# Phase 6: rebuilt from shared components (ArchiveCard, SegmentedMeter, KeyCap, Theme buttons).
# No hard-coded colours, no glyph bullets. Input is action-based (no raw KEY_ literals).
# Displays historical mission context, engineering notes, and lets the player cycle through
# and inspect individual mechanical subsystems in detail.
#
# Public contract (test_historical_spacecraft_assets.gd depends on it):
#   open_inspector(node, id)  close_inspector()  _on_prev_pressed()  _on_next_pressed()
#   fields: _components, title_label, subtitle_label, comp_name_label, comp_desc_label,
#           comp_spec_label (text always begins with "SPECIFICATIONS:"), counter_label
#   signal inspection_closed

signal inspection_closed()

const UITokens    = preload("res://scripts/ui/ui_tokens.gd")
const InputSetup  = preload("res://scripts/input/input_setup.gd")

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
var progress_meter: SegmentedMeter
var next_button: Button
var prev_button: Button
var close_button: Button
var panel: Control

func open_inspector(target_node: Node3D, target_artifact_id: String) -> void:
	spacecraft_root = target_node
	artifact_id = target_artifact_id
	_scan_components()
	_update_display()
	show()
	# Keyboard / gamepad: start on "Next component" so Enter / A steps through the parts.
	if next_button != null and next_button.is_inside_tree():
		next_button.grab_focus.call_deferred()

func _ready() -> void:
	layer = UITokens.LAYER_OVERLAYS  # 10
	InputSetup.ensure()
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
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITokens.theme()
	add_child(root)

	# Bottom panel: same ArchiveCard language as the gallery and the journal.
	var card := ArchiveCard.new()
	card.show_offset_shadow = true
	card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card.offset_left = UITokens.SP_6
	card.offset_right = -UITokens.SP_6
	card.offset_bottom = -UITokens.SP_6
	root.add_child(card)
	panel = card

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_2)
	card.add_child(col)

	# Header: craft (left) · counter + meter (right)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UITokens.SP_4)
	col.add_child(head)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	head.add_child(title_box)

	title_label = Label.new()
	title_label.text = "COMPONENT INSPECTION"
	title_label.theme_type_variation = &"TitleLabel"
	title_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	title_box.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = ""
	subtitle_label.theme_type_variation = &"CaptionLabel"
	subtitle_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(subtitle_label)

	var count_box := VBoxContainer.new()
	count_box.add_theme_constant_override("separation", UITokens.SP_1)
	head.add_child(count_box)
	counter_label = Label.new()
	counter_label.text = "COMPONENT 01 / 01"
	counter_label.theme_type_variation = &"StatLabel"
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_box.add_child(counter_label)
	progress_meter = SegmentedMeter.new()
	progress_meter.accent = UITokens.SIGNAL_CYAN
	progress_meter.custom_minimum_size = Vector2(160, 10)
	count_box.add_child(progress_meter)

	var rule := ColorRect.new()
	rule.color = UITokens.INK_600
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)

	# Component details
	comp_name_label = Label.new()
	comp_name_label.text = "Component"
	comp_name_label.theme_type_variation = &"LeadLabel"
	col.add_child(comp_name_label)

	comp_desc_label = Label.new()
	comp_desc_label.text = ""
	comp_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comp_desc_label.add_theme_color_override("font_color", UITokens.PAPER_100)
	col.add_child(comp_desc_label)

	comp_spec_label = Label.new()
	comp_spec_label.text = "SPECIFICATIONS: -"
	comp_spec_label.theme_type_variation = &"StatLabel"
	comp_spec_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comp_spec_label.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
	col.add_child(comp_spec_label)

	# Navigation: [cap] Previous · [cap] Next · .... · [Esc] Resume exploration
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(nav)

	var prev_row := _nav_button("Previous component", "chevron_left", "gallery_prev", _on_prev_pressed, &"GhostButton")
	nav.add_child(prev_row)
	prev_button = prev_row.get_child(1) as Button
	var next_row := _nav_button("Next component", "chevron_right", "gallery_next", _on_next_pressed, &"GhostButton")
	nav.add_child(next_row)
	next_button = next_row.get_child(1) as Button

	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav.add_child(grow)

	var close_row := HBoxContainer.new()
	close_row.add_theme_constant_override("separation", UITokens.SP_2)
	var esc_cap := KeyCap.new()
	esc_cap.label_override = "Esc"
	esc_cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_row.add_child(esc_cap)
	close_button = Button.new()
	close_button.text = "Resume exploration"
	close_button.icon = UITokens.icon("close")
	close_button.theme_type_variation = &"PrimaryButton"
	close_button.pressed.connect(close_inspector)
	close_row.add_child(close_button)
	nav.add_child(close_row)

## [KeyCap] [Button] pair. The cap reads the InputMap, so rebinding shows up automatically.
func _nav_button(text: String, icon_name: String, action: String, cb: Callable, variation: StringName) -> HBoxContainer:
	var holder := HBoxContainer.new()
	holder.add_theme_constant_override("separation", UITokens.SP_2)
	var cap := KeyCap.new()
	cap.action_name = action
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(cap)
	var b := Button.new()
	b.text = text
	b.icon = UITokens.icon(icon_name)
	b.theme_type_variation = variation
	b.pressed.connect(cb)
	holder.add_child(b)
	return holder

func _update_display() -> void:
	if _components.is_empty():
		return

	_current_idx = clampi(_current_idx, 0, _components.size() - 1)
	var comp = _components[_current_idx]

	if spacecraft_root and spacecraft_root.has_meta("component_name"):
		title_label.text = str(spacecraft_root.get_meta("component_name")).to_upper()
		subtitle_label.text = str(spacecraft_root.get_meta("component_desc", ""))

	counter_label.text = "COMPONENT %02d / %02d" % [_current_idx + 1, _components.size()]
	progress_meter.value = float(_current_idx + 1) / float(_components.size())
	comp_name_label.text = str(comp.get("name", "Component"))
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
	# Pure action-based input — no raw KEY_ literals
	if event.is_action_pressed("ui_cancel"):
		close_inspector()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("gallery_prev"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("gallery_next"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()

func close_inspector() -> void:
	hide()
	inspection_closed.emit()
	queue_free()
