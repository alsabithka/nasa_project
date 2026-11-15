extends Node

## Echoes Beyond Earth — Flashback skin (merge Phase 8)
## Child of the FlashbackSystem layer. `flashback_system.gd` stays byte-identical to integrated1 and
## harsh (plan §5.B), so everything the design system needs but that script does not know about
## is built here:
##   - gold rule + RECONSTRUCTION badge (honest label: this is a written reconstruction, not footage)
##   - SegmentedMeter + "SCENE n / N" replace the glyph progress dots (no glyph icons, MASTER.md)
##   - key-cap hints for the skip keys (Space action "jump" is what the system script reads)
##   - Esc skips too, and is consumed so the HUD never opens pause on the same press
## Nothing here changes timing or content: the system script still owns scenes, timer and fade.

const CARD_MAX_WIDTH := 780.0
const CARD_MARGIN := 96.0

var _sys: CanvasLayer
var _meter: SegmentedMeter
var _count_label: Label
var _built_for_scenes: int = -1
var _last_idx: int = -1


func _ready() -> void:
	_sys = get_parent() as CanvasLayer
	var card := _sys.get_node("CenterContainer/Card") as PanelContainer
	var vp_w: float = _sys.get_viewport().get_visible_rect().size.x
	card.custom_minimum_size.x = minf(CARD_MAX_WIDTH, vp_w - CARD_MARGIN)
	# The system script fades `background.color.a` towards 0.95 — keep the token colour, same alpha.
	var bg := _sys.get_node("Background") as ColorRect
	bg.color = Color(UITokens.INK_900, 0.95)

	var margin := _sys.get_node("CenterContainer/Card/MarginContainer") as MarginContainer
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, UITokens.SP_6)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UITokens.SP_4)

	var header := _sys.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/HeaderBox") as VBoxContainer
	var rule := ColorRect.new()
	rule.color = UITokens.SIGNAL_GOLD
	rule.custom_minimum_size = Vector2(0, 3)
	header.add_child(rule)
	header.move_child(rule, 0)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", UITokens.SP_2)
	badge_row.add_child(Badge.make(Badge.Kind.ARCHIVE, "HISTORICAL RECONSTRUCTION"))
	header.add_child(badge_row)
	header.move_child(badge_row, 1)

	var sub := header.get_node("SubtitleLabel") as Label
	sub.add_theme_color_override("font_color", UITokens.PAPER_300)

	var vbox := header.get_parent() as VBoxContainer
	var line := ColorRect.new()
	line.color = UITokens.INK_600
	line.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(line)
	vbox.move_child(line, header.get_index() + 1)

	var narrative := _sys.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/ContentBox/NarrativeText") as RichTextLabel
	narrative.add_theme_color_override("default_color", UITokens.PAPER_100)

	_build_footer()


func _build_footer() -> void:
	var footer := _sys.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/FooterBox") as HBoxContainer
	var spacer := footer.get_node("Spacer")
	var skip := footer.get_node("SkipHint") as Label
	skip.text = "SKIP"
	skip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var progress := HBoxContainer.new()
	progress.name = "ProgressRow"
	progress.add_theme_constant_override("separation", UITokens.SP_3)
	_count_label = Label.new()
	_count_label.theme_type_variation = &"CaptionLabel"
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress.add_child(_count_label)
	_meter = SegmentedMeter.new()
	_meter.accent = UITokens.SIGNAL_GOLD
	_meter.segment_count = 1
	_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress.add_child(_meter)
	footer.add_child(progress)
	footer.move_child(progress, 0)

	var cap_space := KeyCap.new()
	cap_space.action_name = "jump"
	cap_space.label_override = "Space"
	var cap_esc := KeyCap.new()
	cap_esc.label_override = "Esc"
	footer.add_child(cap_space)
	footer.move_child(cap_space, skip.get_index())
	footer.add_child(cap_esc)
	footer.move_child(cap_esc, skip.get_index())
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _process(_delta: float) -> void:
	if _sys == null or not is_instance_valid(_sys):
		return
	var scenes: Array = _sys.get("scenes")
	if scenes.is_empty():
		return
	if _built_for_scenes != scenes.size():
		_built_for_scenes = scenes.size()
		_meter.segment_count = scenes.size()
		_meter.custom_minimum_size.x = 24.0 * scenes.size()
	var idx: int = _sys.get("current_scene_idx")
	if idx == _last_idx:
		return
	_last_idx = idx
	var shown := mini(idx + 1, scenes.size())
	_meter.value = float(shown) / float(scenes.size())
	_count_label.text = "SCENE %d / %d" % [shown, scenes.size()]


## Esc skips (Space is read by the system script itself). Consumed so pause never opens on this press.
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if not _sys.get("is_active") or _sys.get("is_fading_out"):
		return
	get_viewport().set_input_as_handled()
	_sys.call("_finish_flashback")
