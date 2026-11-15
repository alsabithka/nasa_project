extends CanvasLayer

# Echoes Beyond Earth - Field Specimen Decontamination Chamber
# Allows astronaut to ultrasonic-brush away lunar regolith and stabilize the preserved artifact.

signal cleaning_done(artifact_id: String)

@export var artifact_id: String = ""
@export var clean_duration: float = 6.0

@onready var progress_bar: ProgressBar = $CenterContainer/PanelContainer/VBoxContainer/ProgressBar
@onready var percent_label: Label = $CenterContainer/PanelContainer/VBoxContainer/PercentLabel
@onready var dust_overlay: ColorRect = $CenterContainer/PanelContainer/VBoxContainer/PreviewBox/DustOverlay
@onready var brush_hint: Label = $CenterContainer/PanelContainer/VBoxContainer/BrushHint
@onready var object_preview_label: Label = $CenterContainer/PanelContainer/VBoxContainer/PreviewBox/ObjectPreviewLabel

var clean_progress: float = 0.0
var is_complete: bool = false

func _ready() -> void:
	layer = 15 # Render above regular HUD
	progress_bar.value = 0
	percent_label.text = "0% DECONTAMINATED"
	dust_overlay.color = Color(0.25, 0.28, 0.32, 0.95)
	object_preview_label.text = "[ SPECTRAL SENSOR SCAN: SUBSURFACE TARGET ]"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if is_complete:
		return
	
	var is_cleaning = Input.is_action_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if is_cleaning:
		clean_progress += delta / clean_duration
		clean_progress = clamp(clean_progress, 0.0, 1.0)
		
		progress_bar.value = clean_progress * 100.0
		percent_label.text = "%d%% DECONTAMINATED" % int(clean_progress * 100.0)
		
		var dust_alpha = lerp(0.95, 0.0, clean_progress)
		dust_overlay.color = Color(0.25, 0.28, 0.32, dust_alpha)
		
		brush_hint.text = "DISLODGING LUNAR SURFACE REGOLITH (ULTRASONIC SWEEP)..."
		brush_hint.modulate = AerospaceTheme.COLOR_CYAN
		
		if clean_progress > 0.6:
			object_preview_label.text = "[ HISTORICAL STRUCTURE STABILIZED & EMERGING... ]"
			object_preview_label.modulate = AerospaceTheme.COLOR_STATUS_GREEN
		
		if clean_progress >= 1.0:
			_on_cleaning_complete()
	else:
		brush_hint.text = "HOLD [E] OR LEFT CLICK TO DISLODGE REGOLITH"
		brush_hint.modulate = AerospaceTheme.COLOR_AMBER

func _on_cleaning_complete() -> void:
	is_complete = true
	brush_hint.text = "DECONTAMINATION COMPLETE // SPECIMEN PRESERVED & STABILIZED"
	brush_hint.modulate = AerospaceTheme.COLOR_STATUS_GREEN
	object_preview_label.text = "[ SPECIMEN RESTORED & CATALOGED ]"
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		cleaning_done.emit(artifact_id)
	)
