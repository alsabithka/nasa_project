class_name CatalogueStamp
extends Control

## Echoes Beyond Earth — CatalogueStamp (Phase 5)
## The "cataloguing" moment: a hard-edged, bordered mark (check icon + text) that presses onto the
## Catalogue Entry once. Brutalist job: square corners, 3 px rule, hard 4,4 offset shadow.
## slam() plays one short press-in. With reduced motion (SettingsStore.motion_scale() == 0) the stamp
## simply appears. Status is never colour alone: the check icon and the word carry the meaning.

signal stamped

var text: String = "CATALOGUED"
var accent: Color = UITokens.SIGNAL_GREEN

var _plate: PanelContainer
var _built := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_plate.modulate.a = 0.0   # hidden until slam()


func _build() -> void:
	if _built:
		return
	_built = true
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITokens.INK_900
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.shadow_color = UITokens.INK_900
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(4, 4)
	sb.content_margin_left = float(UITokens.SP_3)
	sb.content_margin_right = float(UITokens.SP_3)
	sb.content_margin_top = float(UITokens.SP_2)
	sb.content_margin_bottom = float(UITokens.SP_2)
	_plate.add_theme_stylebox_override("panel", sb)
	add_child(_plate)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(row)
	row.add_child(UITokens.make_icon("check", accent, 20))
	var lbl := Label.new()
	lbl.text = text
	lbl.theme_type_variation = &"LeadLabel"
	lbl.add_theme_color_override("font_color", accent)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lbl)

	# Reserve room for the rotated plate so neighbours in a container never overlap it.
	custom_minimum_size = _plate.get_combined_minimum_size() + Vector2(12, 12)


## Press the stamp onto the page. Safe to call before the node is ready (it builds itself).
func slam() -> void:
	_build()
	_plate.size = _plate.get_combined_minimum_size()
	_plate.position = Vector2(6, 6)
	_plate.pivot_offset = _plate.size * 0.5
	var m := SettingsStore.motion_scale()
	if m <= 0.0:
		_plate.modulate.a = 1.0
		_plate.scale = Vector2.ONE
		_plate.rotation = deg_to_rad(-4.0)
		stamped.emit()
		return
	_plate.modulate.a = 0.0
	_plate.scale = Vector2(1.6, 1.6)
	_plate.rotation = deg_to_rad(-12.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_plate, "modulate:a", 1.0, UITokens.DURATION_FAST * m)
	tw.tween_property(_plate, "scale", Vector2.ONE, UITokens.DURATION_BASE * m) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_plate, "rotation", deg_to_rad(-4.0), UITokens.DURATION_BASE * m)
	tw.chain().tween_callback(func() -> void: stamped.emit())
