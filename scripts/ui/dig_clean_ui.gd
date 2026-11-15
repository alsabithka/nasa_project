extends CanvasLayer

# Echoes Beyond Earth - Artifact Surface Cleaning Mini-Game (Phase 5 updated)
# Phase 5: UITokens colours applied throughout.

signal cleaning_done(artifact_id: String)

const UITokens = preload("res://scripts/ui/ui_tokens.gd")

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
	layer = UITokens.LAYER_OVERLAYS  # 10 — above HUD, below modals
	progress_bar.value = 0
	percent_label.text = "0% Cleaned"
	dust_overlay.color = Color(0.38, 0.40, 0.42, 0.95) # Thick regolith coat
	object_preview_label.text = "[ UNIDENTIFIED SUBSURFACE ANOMALY ]"
	object_preview_label.add_theme_color_override("font_color", UITokens.PAPER_500)
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
		
		# B5 FIX: blend dust overlay from grey-brown → warm tan as cleaning progresses
		# This hints at warm metallic surfaces beneath, instead of a flat grey box
		var dust_alpha = lerp(0.95, 0.0, clean_progress)
		var r = lerp(0.38, 0.55, clean_progress)
		var g = lerp(0.40, 0.42, clean_progress)
		var b = lerp(0.42, 0.30, clean_progress)
		dust_overlay.color = Color(r, g, b, dust_alpha)
		
		# Update label at meaningful thresholds
		if clean_progress >= 1.0:
			object_preview_label.text = "[ ARTEFACT RESTORED — CATALOGUING ]"
			object_preview_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
		elif clean_progress >= 0.9:
			object_preview_label.text = "[ IDENTIFICATION IMMINENT ]"
			object_preview_label.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
		elif clean_progress >= 0.6:
			object_preview_label.text = "[ Spacecraft Structure Emerging... ]"
			object_preview_label.add_theme_color_override("font_color", UITokens.PAPER_300)
		elif clean_progress >= 0.3:
			object_preview_label.text = "Metallic Structure Detected..."
			object_preview_label.add_theme_color_override("font_color", UITokens.PAPER_300)
		
		brush_hint.text = "Brushing away lunar dust..."
		brush_hint.add_theme_color_override("font_color", UITokens.SIGNAL_GREEN)
		
		if clean_progress >= 1.0:
			_on_cleaning_complete()
	else:
		brush_hint.text = "Hold [E] or Left Click to brush away dust"
		brush_hint.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)

func _on_cleaning_complete() -> void:
	is_complete = true
	brush_hint.text = "CLEANING COMPLETE — ARTEFACT RESTORED!"
	brush_hint.add_theme_color_override("font_color", UITokens.SIGNAL_GREEN)
	object_preview_label.text = "[ Cleaned & Preserved ]"
	object_preview_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	
	# Slight pause to admire clean artifact then emit done
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		cleaning_done.emit(artifact_id)
	)
