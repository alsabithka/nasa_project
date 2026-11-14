extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	print("Main menu initialized.")
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	print("Start button pressed! Starting game...")

func _on_quit_button_pressed() -> void:
	print("Quit button pressed! Exiting game...")
	get_tree().quit()
