extends Control

# Echoes Beyond Earth - Main Menu & Spacecraft Flight Computer Interface

@onready var play_moon_btn: Button = $CenterContainer/MainCard/VBoxContainer/PlayMoonBtn
@onready var play_mars_btn: Button = $CenterContainer/MainCard/VBoxContainer/PlayMarsBtn
@onready var controls_btn: Button = $CenterContainer/MainCard/VBoxContainer/ControlsBtn
@onready var settings_btn: Button = get_node_or_null("CenterContainer/MainCard/VBoxContainer/SettingsBtn")
@onready var credits_btn: Button = get_node_or_null("CenterContainer/MainCard/VBoxContainer/CreditsBtn")
@onready var quit_btn: Button = $CenterContainer/MainCard/VBoxContainer/QuitBtn

@onready var controls_modal: PanelContainer = $ControlsModal
@onready var close_controls_btn: Button = $ControlsModal/MarginContainer/VBoxContainer/CloseControlsBtn

@onready var settings_modal: PanelContainer = get_node_or_null("SettingsModal")
@onready var close_settings_btn: Button = get_node_or_null("SettingsModal/Margin/VBox/CloseSettingsBtn")
@onready var vol_slider: HSlider = get_node_or_null("SettingsModal/Margin/VBox/VolHBox/VolSlider")
@onready var vol_val: Label = get_node_or_null("SettingsModal/Margin/VBox/VolHBox/VolVal")
@onready var sens_slider: HSlider = get_node_or_null("SettingsModal/Margin/VBox/SensHBox/SensSlider")
@onready var sens_val: Label = get_node_or_null("SettingsModal/Margin/VBox/SensHBox/SensVal")
@onready var fullscreen_btn: Button = get_node_or_null("SettingsModal/Margin/VBox/FullscreenBtn")

@onready var credits_modal: PanelContainer = get_node_or_null("CreditsModal")
@onready var close_credits_btn: Button = get_node_or_null("CreditsModal/Margin/VBox/CloseCreditsBtn")

@onready var mission_time_label: Label = get_node_or_null("TopTelemetryBar/Margin/HBox/MissionTime")

var _elapsed_sec: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if controls_modal: controls_modal.visible = false
	if settings_modal: settings_modal.visible = false
	if credits_modal: credits_modal.visible = false
	
	play_moon_btn.pressed.connect(_on_play_moon_pressed)
	play_mars_btn.pressed.connect(_on_play_mars_pressed)
	controls_btn.pressed.connect(func(): _show_modal(controls_modal))
	close_controls_btn.pressed.connect(func(): controls_modal.visible = false)
	
	if settings_btn:
		settings_btn.pressed.connect(func(): _show_modal(settings_modal))
	if close_settings_btn:
		close_settings_btn.pressed.connect(func(): settings_modal.visible = false)
	
	if credits_btn:
		credits_btn.pressed.connect(func(): _show_modal(credits_modal))
	if close_credits_btn:
		close_credits_btn.pressed.connect(func(): credits_modal.visible = false)
	
	quit_btn.pressed.connect(func(): get_tree().quit())
	
	_setup_settings_controls()
	_update_mars_button()

func _process(delta: float) -> void:
	_elapsed_sec += delta
	if mission_time_label:
		var hr = int(_elapsed_sec / 3600.0) + 72
		var mn = int(fmod(_elapsed_sec, 3600.0) / 60.0) + 14
		var sc = int(fmod(_elapsed_sec, 60.0)) + 38
		mission_time_label.text = "MET: %03d:%02d:%02d" % [hr, mn, sc % 60]

func _show_modal(m: PanelContainer) -> void:
	if controls_modal: controls_modal.visible = false
	if settings_modal: settings_modal.visible = false
	if credits_modal: credits_modal.visible = false
	if m: m.visible = true

func _setup_settings_controls() -> void:
	if vol_slider:
		vol_slider.value_changed.connect(func(val):
			AudioServer.set_bus_volume_db(0, linear_to_db(val))
			if vol_val: vol_val.text = "%d%%" % int(val * 100.0)
		)
	
	if sens_slider:
		sens_slider.value_changed.connect(func(val):
			if sens_val: sens_val.text = "%.1fx" % val
		)
	
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(func():
			var mode = DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				fullscreen_btn.text = "[ TOGGLE FULLSCREEN DISPLAY: OFF ]"
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				fullscreen_btn.text = "[ TOGGLE FULLSCREEN DISPLAY: ON ]"
		)

func _update_mars_button() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var unlocked = gs.is_planet_unlocked("Mars")
		if unlocked:
			play_mars_btn.disabled = false
			play_mars_btn.text = "[ SURVEY MARS EXPEDITION — UNLOCKED ]"
			play_mars_btn.modulate = AerospaceTheme.COLOR_AMBER
		else:
			play_mars_btn.disabled = false
			play_mars_btn.text = "[ SURVEY MARS (COMPLETE MOON EXPEDITION FIRST) ]"
			play_mars_btn.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY

func _on_play_moon_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/moon.tscn")

func _on_play_mars_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and not gs.is_planet_unlocked("Mars"):
		print("[MainMenu] Mars selected. Unlocking for direct exploration.")
		gs.unlock_planet("Mars")
	get_tree().change_scene_to_file("res://scenes/levels/mars.tscn")
