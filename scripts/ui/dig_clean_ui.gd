extends CanvasLayer

# Echoes Beyond Earth - Artifact Surface Cleaning Mini-Game
# Allows player to brush away lunar regolith and expose the preserved artifact.

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
var brush_particle_timer: float = 0.0

func _ready() -> void:
	layer = 15 # Render above regular HUD
	progress_bar.value = 0
	percent_label.text = "0% Cleaned"
	dust_overlay.color = Color(0.38, 0.40, 0.42, 0.95) # Thick regolith coat
	object_preview_label.text = "[ Unidentified Surface Coating ]"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if is_complete:
		return
	
	# Holding E or clicking cleans the artifact
	var is_cleaning = Input.is_action_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if is_cleaning:
		clean_progress += delta / clean_duration
		clean_progress = clamp(clean_progress, 0.0, 1.0)
		
		progress_bar.value = clean_progress * 100.0
		percent_label.text = "%d%% Cleaned" % int(clean_progress * 100.0)
		
		# Fade away dust layer as cleaning progresses
		var dust_alpha = lerp(0.95, 0.0, clean_progress)
		dust_overlay.color = Color(0.38, 0.40, 0.42, dust_alpha)
		
		brush_hint.text = "Brushing away lunar dust..."
		brush_hint.modulate = Color(0.3, 1.0, 0.6)
		
		if clean_progress > 0.6:
			object_preview_label.text = "[ Spacecraft Structure Emerging... ]"
		
		if clean_progress >= 1.0:
			_on_cleaning_complete()
	else:
		brush_hint.text = "Hold [E] or Left Click to brush away dust"
		brush_hint.modulate = Color(1.0, 0.85, 0.2)

func _on_cleaning_complete() -> void:
	is_complete = true
	brush_hint.text = "CLEANING COMPLETE — ARTIFACT RESTORED!"
	brush_hint.modulate = Color(0.2, 1.0, 0.4)
	object_preview_label.text = "[ Cleaned & Preserved ]"
	
	# Slight pause to admire clean artifact then emit done
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		cleaning_done.emit(artifact_id)
	)
