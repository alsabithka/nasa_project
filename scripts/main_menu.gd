extends Control

# Echoes Beyond Earth - Main Menu Controller (Phase 3 updated)

const UITokens    = preload("res://scripts/ui/ui_tokens.gd")
const SceneFade   = preload("res://scripts/ui/scene_fade.gd")

@onready var play_moon_btn: Button = $CenterContainer/MainCard/VBoxContainer/PlayMoonBtn
@onready var play_mars_btn: Button = $CenterContainer/MainCard/VBoxContainer/PlayMarsBtn
@onready var gallery_btn: Button = $CenterContainer/MainCard/VBoxContainer/SpacecraftGalleryBtn
@onready var controls_btn: Button = $CenterContainer/MainCard/VBoxContainer/ControlsBtn
@onready var quit_btn: Button = $CenterContainer/MainCard/VBoxContainer/QuitBtn

@onready var controls_modal: PanelContainer = $ControlsModal
@onready var close_controls_btn: Button = $ControlsModal/MarginContainer/VBoxContainer/CloseControlsBtn

var _settings_menu = null
var _field_manual = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	controls_modal.visible = false

	play_moon_btn.pressed.connect(_on_play_moon_pressed)
	play_mars_btn.pressed.connect(_on_play_mars_pressed)
	gallery_btn.pressed.connect(_on_gallery_pressed)
	controls_btn.pressed.connect(func(): controls_modal.visible = true)
	close_controls_btn.pressed.connect(func(): controls_modal.visible = false)
	quit_btn.pressed.connect(func(): get_tree().quit())

	_update_mars_button()
	_setup_settings()
	_check_field_manual()


func _setup_settings() -> void:
	var settings_scene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene:
		_settings_menu = settings_scene.instantiate()
		add_child(_settings_menu)
		_settings_menu.settings_closed.connect(func(): pass)


func _check_field_manual() -> void:
	# Field manual is relevant in the level scene; skip on main menu.
	# If you want a "How to Play" button here, connect it to _show_field_manual().
	pass


func _show_field_manual() -> void:
	if _field_manual == null:
		var fm_scene = load("res://scenes/ui/field_manual.tscn")
		if fm_scene:
			_field_manual = fm_scene.instantiate()
			add_child(_field_manual)
	if _field_manual:
		_field_manual.show_manual()


func _update_mars_button() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var unlocked = gs.is_planet_unlocked("Mars")
		# B8 FIX: truly disable the button when Mars is not yet unlocked
		play_mars_btn.disabled = not unlocked
		if unlocked:
			play_mars_btn.text = "Explore Mars [UNLOCKED]"
			play_mars_btn.modulate = Color(1.0, 0.9, 0.4)
		else:
			play_mars_btn.text = "Explore Mars — Complete Moon Survey First"
			play_mars_btn.modulate = Color(0.5, 0.55, 0.65)


func _on_play_moon_pressed() -> void:
	SceneFade.go(get_tree(), "res://scenes/levels/moon.tscn")


func _on_gallery_pressed() -> void:
	SceneFade.go(get_tree(), "res://scenes/spacecraft/spacecraft_gallery.tscn")


func _on_play_mars_pressed() -> void:
	# B8 FIX: removed auto-unlock; button is disabled until Moon survey is complete
	SceneFade.go(get_tree(), "res://scenes/levels/mars.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			controls_modal.visible = false
