extends CanvasLayer

## Echoes Beyond Earth — Artifact Surface Cleaning (Phase 1 B5 fix, Phase 2 components, Phase 5 feedback)
## The specimen is a vector drawing (SpecimenReveal) that emerges as dust cells fall away.
## Phase 5: tool row (brush glyph + state in words), neutral stage wording (works for rocks and
## hardware alike), optional gamepad rumble while brushing, hint with an InputMap key-cap.
## Contract kept: signal cleaning_done(artifact_id), exports artifact_id / clean_duration.

signal cleaning_done(artifact_id: String)

@export var artifact_id: String = ""
@export var clean_duration: float = 6.0

const ROOT := "CenterContainer/PanelContainer/VBoxContainer/"
@onready var reveal: SpecimenReveal = get_node(ROOT + "PreviewBox/Reveal")
@onready var meter: SegmentedMeter = get_node(ROOT + "MeterRow/Meter")
@onready var percent_label: Label = get_node(ROOT + "MeterRow/PercentLabel")
@onready var brush_hint: Label = get_node(ROOT + "HintRow/BrushHint")
@onready var object_preview_label: Label = get_node(ROOT + "ObjectPreviewLabel")

var clean_progress: float = 0.0
var is_complete: bool = false

var _tool_icon: TextureRect
var _tool_state: Label

func _ready() -> void:
	layer = UITokens.LAYER_MODALS
	percent_label.text = "0%"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_state("Unidentified subsurface anomaly", UITokens.PAPER_300)
	_build_tool_row()

func _process(delta: float) -> void:
	if is_complete:
		return
	var cleaning := Input.is_action_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	reveal.brushing = cleaning
	_set_tool_state(cleaning)
	if not cleaning:
		brush_hint.text = "Hold to brush away dust, or hold the left mouse button"
		return
	# Optional haptic: a faint rumble on any connected pad while brushing (no-op without one).
	for dev in Input.get_connected_joypads():
		Input.start_joy_vibration(dev, 0.25, 0.0, 0.1)
	clean_progress = clampf(clean_progress + delta / clean_duration, 0.0, 1.0)
	reveal.progress = clean_progress
	meter.value = clean_progress
	percent_label.text = "%d%%" % int(clean_progress * 100.0)
	brush_hint.text = "Brushing…"
	if clean_progress >= 1.0:
		_on_cleaning_complete()
	elif clean_progress >= 0.9:
		_set_state("Identification imminent", UITokens.SIGNAL_CYAN)
	elif clean_progress >= 0.6:
		_set_state("Form emerging from the dust", UITokens.PAPER_100)
	elif clean_progress >= 0.3:
		_set_state("Surface structure detected", UITokens.PAPER_100)

## Tool row under the subtitle: brush glyph + words. Idle vs brushing differs in TEXT and glyph
## colour, never colour alone.
func _build_tool_row() -> void:
	var vb: VBoxContainer = get_node(ROOT.trim_suffix("/"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_tool_icon = UITokens.make_icon("brush", UITokens.PAPER_500, 16)
	row.add_child(_tool_icon)
	var name_lbl := Label.new()
	name_lbl.text = "GEOLOGICAL BRUSH"
	name_lbl.theme_type_variation = &"CaptionLabel"
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	_tool_state = Label.new()
	_tool_state.theme_type_variation = &"StatLabel"
	_tool_state.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	row.add_child(_tool_state)
	vb.add_child(row)
	vb.move_child(row, 2)   # after Title and Subtitle
	_set_tool_state(false)


func _set_tool_state(brushing: bool) -> void:
	if _tool_state == null:
		return
	_tool_state.text = "BRUSHING" if brushing else "IDLE"
	_tool_state.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD if brushing else UITokens.PAPER_300)
	_tool_icon.modulate = UITokens.SIGNAL_GOLD if brushing else UITokens.PAPER_500


func _set_state(text: String, color: Color) -> void:
	object_preview_label.text = text
	object_preview_label.add_theme_color_override("font_color", color)

func _on_cleaning_complete() -> void:
	is_complete = true
	reveal.brushing = false
	brush_hint.text = "Cleaning complete. Opening the catalogue entry."
	_set_state("Cleaned and preserved", UITokens.SIGNAL_GOLD)
	get_tree().create_timer(1.2).timeout.connect(func(): cleaning_done.emit(artifact_id))

## Visual preview / QA helper: shows the screen at a given progress (0–1) without input.
func set_progress_preview(p: float) -> void:
	clean_progress = clampf(p, 0.0, 1.0)
	reveal.progress = clean_progress
	meter.value = clean_progress
	percent_label.text = "%d%%" % int(clean_progress * 100.0)
