extends Control

# Echoes Beyond Earth - Main Menu Controller

@onready var play_moon_btn: Button = $CenterContainer/MainCard/VBoxContainer/PlayMoonBtn
@onready var play_mars_btn: Button = $CenterContainer/MainCard/VBoxContainer/PlayMarsBtn
@onready var controls_btn: Button = $CenterContainer/MainCard/VBoxContainer/ControlsBtn
@onready var quit_btn: Button = $CenterContainer/MainCard/VBoxContainer/QuitBtn

@onready var controls_modal: PanelContainer = $ControlsModal
@onready var close_controls_btn: Button = $ControlsModal/MarginContainer/VBoxContainer/CloseControlsBtn

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	controls_modal.visible = false
	
	play_moon_btn.pressed.connect(_on_play_moon_pressed)
	play_mars_btn.pressed.connect(_on_play_mars_pressed)
	controls_btn.pressed.connect(func(): controls_modal.visible = true)
	close_controls_btn.pressed.connect(func(): controls_modal.visible = false)
	quit_btn.pressed.connect(func(): get_tree().quit())
	
	_update_mars_button()

func _update_mars_button() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var unlocked = gs.is_planet_unlocked("Mars")
		if unlocked:
			play_mars_btn.disabled = false
			play_mars_btn.text = "Explore Mars [UNLOCKED]"
			play_mars_btn.modulate = Color(1.0, 0.9, 0.4)
		else:
			play_mars_btn.disabled = false # Allow clicking to inform user
			play_mars_btn.text = "Explore Mars (Complete Moon Survey First)"
			play_mars_btn.modulate = Color(0.7, 0.75, 0.85)

func _on_play_moon_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/moon.tscn")

func _on_play_mars_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and not gs.is_planet_unlocked("Mars"):
		# If user wants to jump directly to Mars for testing or play, we allow it with notification
		print("[MainMenu] Mars selected. Unlocking for direct exploration.")
		gs.unlock_planet("Mars")
	get_tree().change_scene_to_file("res://scenes/levels/mars.tscn")
