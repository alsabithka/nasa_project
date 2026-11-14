extends CanvasLayer

# Echoes Beyond Earth - Reusable Cinematic Historical Flashback System
# Presents a verified historical narrative reconstruction for each discovered artifact.

signal flashback_complete()

@export var artifact_id: String = ""

@onready var background: ColorRect = $Background
@onready var title_label: Label = $CenterContainer/Card/MarginContainer/VBoxContainer/HeaderBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Card/MarginContainer/VBoxContainer/HeaderBox/SubtitleLabel
@onready var scene_header: Label = $CenterContainer/Card/MarginContainer/VBoxContainer/ContentBox/SceneHeader
@onready var narrative_text: RichTextLabel = $CenterContainer/Card/MarginContainer/VBoxContainer/ContentBox/NarrativeText
@onready var progress_dots: Label = $CenterContainer/Card/MarginContainer/VBoxContainer/FooterBox/ProgressDots
@onready var skip_hint: Label = $CenterContainer/Card/MarginContainer/VBoxContainer/FooterBox/SkipHint

var flashback_data: Dictionary = {}
var scenes: Array = []
var current_scene_idx: int = 0
var scene_timer: float = 0.0
var scene_duration: float = 4.5
var is_active: bool = false
var fade_alpha: float = 0.0
var is_fading_out: bool = false

func _ready() -> void:
	layer = 20 # Above all other HUD elements
	_load_flashback_data()
	_start_flashback()

func _load_flashback_data() -> void:
	var path = "res://data/flashbacks.json"
	if not FileAccess.file_exists(path):
		printerr("[Flashback] flashbacks.json not found!")
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		var root_dict = json.data
		if root_dict.has("flashbacks") and root_dict["flashbacks"].has(artifact_id):
			flashback_data = root_dict["flashbacks"][artifact_id]
			scenes = flashback_data.get("scenes", [])

func _start_flashback() -> void:
	if scenes.is_empty():
		# Fallback if no specific flashback entry
		flashback_complete.emit()
		queue_free()
		return
	
	is_active = true
	title_label.text = flashback_data.get("title", "HISTORICAL RECONSTRUCTION")
	subtitle_label.text = flashback_data.get("subtitle", "NASA Historical Archives")
	current_scene_idx = 0
	_display_current_scene()

func _display_current_scene() -> void:
	if current_scene_idx >= scenes.size():
		_finish_flashback()
		return
	
	var cur = scenes[current_scene_idx]
	scene_header.text = cur.get("header", "HISTORICAL ARCHIVE")
	narrative_text.text = "[font_size=19]" + cur.get("narrative", "") + "[/font_size]"
	scene_duration = cur.get("duration", 4.5)
	scene_timer = 0.0
	
	# Update progress dots
	var dots = ""
	for i in range(scenes.size()):
		if i == current_scene_idx:
			dots += " [ ◆ ] "
		else:
			dots += "   ◇   "
	progress_dots.text = dots

func _process(delta: float) -> void:
	if not is_active:
		return
	
	if is_fading_out:
		fade_alpha -= delta * 2.0
		if background:
			background.color.a = clamp(fade_alpha * 0.95, 0.0, 0.95)
		var card = get_node_or_null("CenterContainer/Card")
		if card:
			card.modulate.a = clamp(fade_alpha, 0.0, 1.0)
		if fade_alpha <= 0.0:
			is_active = false
			flashback_complete.emit()
			queue_free()
		return
	
	# Skip with Space
	if Input.is_action_just_pressed("jump"):
		_finish_flashback()
		return
	
	scene_timer += delta
	if scene_timer >= scene_duration:
		current_scene_idx += 1
		_display_current_scene()

func _finish_flashback() -> void:
	is_fading_out = true
	fade_alpha = 1.0
