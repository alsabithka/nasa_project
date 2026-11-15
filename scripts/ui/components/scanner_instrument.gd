class_name ScannerInstrument
extends HudPanel

## Echoes Beyond Earth — ScannerInstrument (Phase 4)
## The proximity scanner as an instrument: big mono distance, segmented signal meter, and a state
## row where the STATE IS A SHAPE (icon) plus words, never colour alone.
## Mystery rule is unchanged: it shows distance and strength only, NEVER what is buried.
##   scanner.update_reading(target_id, distance_m, strength_0_to_1)
## Emits state_changed(state) when the coarse state flips (used for toasts).

signal state_changed(new_state: int)

enum State { NONE, FAINT, MODERATE, STRONG, DIG }

## Merge D8: thresholds follow integrated1 (radar range 65 m; DIG <= 4; STRONG < 15; MODERATE < 35).
const MAX_RANGE := 65.0
const DIG_RANGE := 4.0
const STRONG_RANGE := 15.0
const MODERATE_RANGE := 35.0
const STATE_TEXT := {
	State.NONE: "Searching for signals",
	State.FAINT: "Faint signal",
	State.MODERATE: "Moderate signal",
	State.STRONG: "Strong subsurface anomaly",
	State.DIG: "Anomaly below. Dig here",
}
const STATE_ICON := {
	State.NONE: "signal_none",
	State.FAINT: "signal_faint",
	State.MODERATE: "signal_moderate",
	State.STRONG: "signal_strong",
	State.DIG: "signal_dig",
}

var radar: RadarDial
var _pos_label: Label
var _distance: Label
var _meter: SegmentedMeter
var _icon: TextureRect
var _state_label: Label
var _state: int = State.NONE


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(264, 0)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", UITokens.SP_2)
	add_child(col)

	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	var title := Label.new()
	title.text = "PROXIMITY SCANNER"
	title.theme_type_variation = &"CaptionLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(title)
	head.add_child(Badge.make(Badge.Kind.LIVE))

	radar = RadarDial.new()
	radar.radar_range = MAX_RANGE
	radar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(radar)

	_pos_label = Label.new()
	_pos_label.theme_type_variation = &"CaptionLabel"
	_pos_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	_pos_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos_label.text = "POS  --  --"
	col.add_child(_pos_label)

	_distance = Label.new()
	_distance.theme_type_variation = &"StatLabelLarge"
	_distance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_distance)

	_meter = SegmentedMeter.new()
	_meter.segment_count = 10
	col.add_child(_meter)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.SP_2)
	col.add_child(row)
	_icon = UITokens.make_icon("signal_none", UITokens.PAPER_500, 18)
	row.add_child(_icon)
	_state_label = Label.new()
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_state_label.custom_minimum_size = Vector2(190, 22)   # merge: stops autowrap collapsing to a 1-char column; one line by default, grows only if text wraps
	_state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_state_label)

	reset()


func _process(_delta: float) -> void:
	if radar != null and radar.visible:
		var p: Vector3 = radar.get_player_position()
		_pos_label.text = "POS  %+06.1f  %+06.1f" % [p.x, p.z]


func get_state() -> int:
	return _state


## Back to "nothing in range".
func reset() -> void:
	_apply(State.NONE, -1.0, 0.0)


func update_reading(target_id: String, distance: float, strength: float) -> void:
	if target_id == "" or distance > MAX_RANGE:
		_apply(State.NONE, -1.0, 0.0)
		return
	var s: int = State.FAINT
	if distance <= DIG_RANGE:
		s = State.DIG
	elif distance < STRONG_RANGE:
		s = State.STRONG
	elif distance < MODERATE_RANGE:
		s = State.MODERATE
	_apply(s, distance, strength)


func _accent_for(s: int) -> Color:
	match s:
		State.DIG:
			return UITokens.SIGNAL_GOLD
		State.STRONG, State.MODERATE:
			return UITokens.SIGNAL_CYAN
		State.FAINT:
			return UITokens.PAPER_300
		_:
			return UITokens.PAPER_500


func _apply(s: int, distance: float, strength: float) -> void:
	var accent: Color = _accent_for(s)
	_distance.text = "-- m" if distance < 0.0 else "%.1f m" % distance
	_distance.add_theme_color_override("font_color", accent)
	_meter.accent = accent
	_meter.value = clampf(strength, 0.0, 1.0)
	_icon.texture = UITokens.icon(String(STATE_ICON[s]))
	_icon.modulate = accent
	_state_label.text = String(STATE_TEXT[s])
	if s != _state:
		_state = s
		state_changed.emit(s)
