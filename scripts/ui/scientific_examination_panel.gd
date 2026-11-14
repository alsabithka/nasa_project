extends CanvasLayer

# Echoes Beyond Earth - NASA Scientific Examination & Geological Documentation Panel
# Formatted according to NASA Apollo Lunar Sample Compendium standards:
# - Clearly distinguishes measured vs estimated properties
# - Documents stratigraphic depth, discovery coordinates, and classification

signal documentation_closed(artifact_id: String)

var artifact_id: String = ""
var artifact_data: Dictionary = {}

var panel_container: PanelContainer
var title_label: Label
var category_badge: Label
var context_label: Label
var measured_label: Label
var estimated_label: Label
var history_text: RichTextLabel
var close_button: Button

func _ready() -> void:
	if not close_button:
		_build_ui_fallback()
	else:
		close_button.pressed.connect(_on_close_pressed)
	populate_data()

func _build_ui_fallback() -> void:
	layer = 120
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)

	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(680, 520)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	sb.border_color = Color(0.3, 0.6, 0.85, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	cc.add_child(p)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)

	# Header
	var hb = HBoxContainer.new()
	vb.add_child(hb)

	title_label = Label.new()
	title_label.text = "NASA LUNAR SPECIMEN DOCUMENTATION"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.modulate = Color(0.9, 0.95, 1.0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title_label)

	category_badge = Label.new()
	category_badge.text = "[GEOLOGICAL SAMPLE]"
	category_badge.add_theme_font_size_override("font_size", 13)
	category_badge.modulate = Color(1.0, 0.8, 0.2)
	hb.add_child(category_badge)

	# Divider
	var sep1 = HSeparator.new()
	vb.add_child(sep1)

	# Context & Stratigraphy
	context_label = Label.new()
	context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_label.add_theme_font_size_override("font_size", 13)
	context_label.modulate = Color(0.75, 0.85, 0.95)
	vb.add_child(context_label)

	# Properties (Measured vs Estimated)
	var prop_box = VBoxContainer.new()
	prop_box.add_theme_constant_override("separation", 6)
	vb.add_child(prop_box)

	var m_title = Label.new()
	m_title.text = "MEASURED PROPERTIES (In-Situ & Laboratory):"
	m_title.add_theme_font_size_override("font_size", 12)
	m_title.modulate = Color(0.3, 0.9, 0.5)
	prop_box.add_child(m_title)

	measured_label = Label.new()
	measured_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	measured_label.add_theme_font_size_override("font_size", 12)
	prop_box.add_child(measured_label)

	var e_title = Label.new()
	e_title.text = "ESTIMATED / THEORETICAL INFERENCES:"
	e_title.add_theme_font_size_override("font_size", 12)
	e_title.modulate = Color(1.0, 0.75, 0.3)
	prop_box.add_child(e_title)

	estimated_label = Label.new()
	estimated_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	estimated_label.add_theme_font_size_override("font_size", 12)
	prop_box.add_child(estimated_label)

	# Scientific History
	history_text = RichTextLabel.new()
	history_text.custom_minimum_size = Vector2(0, 110)
	history_text.fit_content = false
	history_text.scroll_active = true
	history_text.add_theme_font_size_override("normal_font_size", 12)
	vb.add_child(history_text)

	# Close button
	close_button = Button.new()
	close_button.text = "CATALOG & STORE SPECIMEN [E / Click]"
	close_button.custom_minimum_size = Vector2(0, 42)
	close_button.pressed.connect(_on_close_pressed)
	vb.add_child(close_button)

func populate_data() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and artifact_data.is_empty():
		artifact_data = game_state.get_artifact_data(artifact_id)
	
	if artifact_data.is_empty():
		return
	
	var art_name = artifact_data.get("name", artifact_id)
	var cat = artifact_data.get("category", "Scientific Discoveries")
	var strat = artifact_data.get("stratigraphic_layer", "Compacted Regolith")
	var depth = artifact_data.get("discovery_depth_cm", 12.0)
	var geo = artifact_data.get("geological_context", "Lunar Surface")
	var det = artifact_data.get("detection_signature", "Electromagnetic Anomaly")
	var measured = artifact_data.get("measured_properties", "Conductive metallic matrix")
	var estimated = artifact_data.get("estimated_properties", "Age: ~3.8 Ga")
	var hist = artifact_data.get("history", "")

	if title_label:
		title_label.text = art_name.to_upper()
	if category_badge:
		category_badge.text = "[%s]" % cat.to_upper()
	if context_label:
		context_label.text = "STRATIGRAPHY: %s  |  EXCAVATION DEPTH: %.1f cm\nLOCATION CONTEXT: %s\nDETECTION METHOD: %s" % [strat, depth, geo, det]
	if measured_label:
		measured_label.text = "• " + measured
	if estimated_label:
		estimated_label.text = "• " + estimated
	if history_text:
		history_text.text = "[b]Scientific & Mission Notes:[/b]\n" + hist

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	documentation_closed.emit(artifact_id)
	queue_free()
