extends Control

# Echoes Beyond Earth - In-Game HUD, Mystery Scanner Radar, Discovery & Flashback Flow

@export var current_planet: String = "Moon"

# UI Nodes
@onready var location_label: Label = $TopBar/MarginContainer/HBoxContainer/LocationLabel
@onready var counter_label: Label = $TopBar/MarginContainer/HBoxContainer/CounterBadge/CounterLabel
@onready var journal_button: Button = $TopBar/MarginContainer/HBoxContainer/JournalButton
@onready var menu_button: Button = $TopBar/MarginContainer/HBoxContainer/MenuButton

# Radar Widget
@onready var radar_panel: PanelContainer = $RadarWidget
@onready var distance_label: Label = $RadarWidget/VBoxContainer/DistanceLabel
@onready var strength_bar: ProgressBar = $RadarWidget/VBoxContainer/StrengthBar
@onready var target_name_label: Label = $RadarWidget/VBoxContainer/TargetNameLabel
@onready var compass_needle: Control = $RadarWidget/VBoxContainer/RadarCircle/Needle

# Discovery Popup
@onready var discovery_popup: PanelContainer = $DiscoveryPopup
@onready var popup_title: Label = $DiscoveryPopup/MarginContainer/VBoxContainer/TitleLabel
@onready var popup_name: Label = $DiscoveryPopup/MarginContainer/VBoxContainer/ArtifactNameLabel
@onready var popup_mission: Label = $DiscoveryPopup/MarginContainer/VBoxContainer/MissionLabel
@onready var popup_history: RichTextLabel = $DiscoveryPopup/MarginContainer/VBoxContainer/HistoryLabel
@onready var popup_close_btn: Button = $DiscoveryPopup/MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var popup_journal_btn: Button = $DiscoveryPopup/MarginContainer/VBoxContainer/ButtonContainer/OpenJournalButton

# Journal Modal
@onready var journal_modal: PanelContainer = $JournalModal
@onready var journal_list: VBoxContainer = $JournalModal/MarginContainer/VBoxContainer/ContentHBox/ScrollContainer/ArtifactList
@onready var journal_detail_name: Label = $JournalModal/MarginContainer/VBoxContainer/ContentHBox/DetailPanel/VBoxContainer/DetailName
@onready var journal_detail_text: RichTextLabel = $JournalModal/MarginContainer/VBoxContainer/ContentHBox/DetailPanel/VBoxContainer/DetailText
@onready var journal_close_btn: Button = $JournalModal/MarginContainer/VBoxContainer/HeaderHBox/CloseJournalBtn
@onready var moon_tab_btn: Button = $JournalModal/MarginContainer/VBoxContainer/TabHBox/MoonTabBtn
@onready var mars_tab_btn: Button = $JournalModal/MarginContainer/VBoxContainer/TabHBox/MarsTabBtn

# Mission Complete Banner
@onready var completion_modal: PanelContainer = $CompletionModal
@onready var completion_desc: Label = $CompletionModal/MarginContainer/VBoxContainer/DescLabel
@onready var travel_mars_btn: Button = $CompletionModal/MarginContainer/VBoxContainer/BtnContainer/TravelMarsBtn
@onready var continue_btn: Button = $CompletionModal/MarginContainer/VBoxContainer/BtnContainer/ContinueBtn

var selected_journal_planet: String = "Moon"
var _last_discovered_id: String = ""

func _ready() -> void:
	_update_header()
	_connect_gamestate()
	_connect_scanner()
	_setup_buttons()
	
	discovery_popup.visible = false
	journal_modal.visible = false
	completion_modal.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle_journal()

func _setup_buttons() -> void:
	journal_button.pressed.connect(toggle_journal)
	menu_button.pressed.connect(_on_menu_pressed)
	popup_close_btn.pressed.connect(_on_popup_closed)
	popup_journal_btn.pressed.connect(_open_journal_to_last_discovered)
	journal_close_btn.pressed.connect(func(): journal_modal.visible = false)
	
	moon_tab_btn.pressed.connect(func(): _populate_journal("Moon"))
	mars_tab_btn.pressed.connect(func(): _populate_journal("Mars"))
	
	if continue_btn:
		continue_btn.pressed.connect(func(): completion_modal.visible = false)
	if travel_mars_btn:
		travel_mars_btn.pressed.connect(_travel_to_mars)

func _connect_gamestate() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	gs.artifact_recovered.connect(_on_artifact_recovered)
	gs.mission_completed.connect(_on_mission_completed)
	_update_header()

func _connect_scanner() -> void:
	var scanners = get_tree().get_nodes_in_group("scanner")
	for s in scanners:
		if s.has_signal("scan_updated"):
			s.scan_updated.connect(_on_scan_updated)

# Mystery Scanner: Proximity and Signal Strength only, NEVER reveals artifact identity!
func _on_scan_updated(target_id: String, distance: float, signal_strength: float) -> void:
	if target_id == "" or distance > 60.0:
		distance_label.text = "-- m"
		strength_bar.value = 0
		target_name_label.text = "Searching for signals..."
		target_name_label.modulate = Color(0.65, 0.7, 0.75)
		distance_label.modulate = Color(0.6, 0.65, 0.7)
		if compass_needle:
			compass_needle.rotation = 0.0
		return
	
	distance_label.text = "%.1f m" % distance
	strength_bar.value = signal_strength * 100.0
	
	# Mystery-based signal categorization
	if distance <= 4.0:
		target_name_label.text = "● ANOMALY BENEATH SURFACE — DIG HERE"
		target_name_label.modulate = Color(0.2, 1.0, 0.4)
		distance_label.modulate = Color(0.2, 1.0, 0.4)
	elif distance < 12.0:
		target_name_label.text = "▲ STRONG SUBSURFACE ANOMALY"
		target_name_label.modulate = Color(0.3, 0.9, 1.0)
		distance_label.modulate = Color(0.3, 0.9, 1.0)
	elif distance < 25.0:
		target_name_label.text = "◆ MODERATE SIGNAL DETECTED"
		target_name_label.modulate = Color(1.0, 0.85, 0.2)
		distance_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		target_name_label.text = "~ FAINT SIGNAL DETECTED"
		target_name_label.modulate = Color(0.75, 0.8, 0.9)
		distance_label.modulate = Color(0.75, 0.8, 0.9)

func _on_artifact_recovered(artifact_id: String) -> void:
	_last_discovered_id = artifact_id
	_update_header()
	_show_discovery_popup(artifact_id)
	if journal_modal.visible:
		_populate_journal(selected_journal_planet)

func _on_popup_closed() -> void:
	discovery_popup.visible = false
	# Trigger cinematic historical flashback after discovery
	if _last_discovered_id != "":
		_trigger_flashback(_last_discovered_id)

func _trigger_flashback(artifact_id: String) -> void:
	var flashback_scene = load("res://scenes/ui/flashback.tscn")
	if flashback_scene:
		var fb = flashback_scene.instantiate()
		fb.artifact_id = artifact_id
		add_child(fb)

func _on_mission_completed(planet: String) -> void:
	if completion_modal:
		completion_modal.visible = true
		if planet == "Moon":
			completion_desc.text = "You have excavated, restored, and cataloged all historical Apollo lunar equipment! Mars exploration coordinates are now unlocked."
			if travel_mars_btn:
				travel_mars_btn.visible = true
		else:
			completion_desc.text = "Congratulations! You have successfully surveyed all historical Martian exploration artifacts!"
			if travel_mars_btn:
				travel_mars_btn.visible = false

func _travel_to_mars() -> void:
	completion_modal.visible = false
	get_tree().change_scene_to_file("res://scenes/levels/mars.tscn")

func _update_header() -> void:
	location_label.text = current_planet.to_upper() + " EXPLORATION"
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var rec = gs.get_recovered_count(current_planet)
		var total = gs.get_total_count(current_planet)
		counter_label.text = "%d / %d Artifacts Found" % [rec, total]

func _show_discovery_popup(artifact_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	var data = {}
	if gs:
		data = gs.get_artifact_data(artifact_id)
	
	popup_title.text = "ARTIFACT IDENTIFIED & RESTORED!"
	popup_name.text = data.get("name", artifact_id.capitalize())
	popup_mission.text = "Mission: %s (%s) | Status: %s" % [
		str(data.get("mission", "Unknown")),
		str(data.get("year", "N/A")),
		str(data.get("status", "Active"))
	]
	popup_history.text = "[b]Purpose:[/b] %s\n\n[b]Historical Narrative:[/b] %s" % [
		data.get("purpose", ""),
		data.get("history", "")
	]
	
	discovery_popup.visible = true

func toggle_journal() -> void:
	journal_modal.visible = not journal_modal.visible
	if journal_modal.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_populate_journal(selected_journal_planet)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _open_journal_to_last_discovered() -> void:
	discovery_popup.visible = false
	journal_modal.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_populate_journal(selected_journal_planet)
	if _last_discovered_id != "":
		_show_artifact_detail(_last_discovered_id)

func _populate_journal(planet: String) -> void:
	selected_journal_planet = planet
	for c in journal_list.get_children():
		c.queue_free()
	
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	var artifacts = gs.artifacts_data
	var found_any = false
	
	for id in artifacts.keys():
		var data = artifacts[id]
		if data.get("location", "").to_lower() != planet.to_lower():
			continue
		
		found_any = true
		var is_rec = gs.is_artifact_recovered(id)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if is_rec:
			btn.text = " [✓] " + data.get("name", id)
			btn.modulate = Color(0.9, 1.0, 0.9)
		else:
			btn.text = " [ ? ] Unidentified Subsurface Anomaly"
			btn.modulate = Color(0.6, 0.65, 0.75)
		
		var target_id = id
		btn.pressed.connect(func(): _show_artifact_detail(target_id))
		journal_list.add_child(btn)
	
	# Select first item detail
	for id in artifacts.keys():
		if artifacts[id].get("location", "").to_lower() == planet.to_lower():
			_show_artifact_detail(id)
			break

func _show_artifact_detail(artifact_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	var is_rec = gs.is_artifact_recovered(artifact_id)
	var data = gs.get_artifact_data(artifact_id)
	
	if is_rec:
		journal_detail_name.text = data.get("name", artifact_id)
		journal_detail_name.modulate = Color(1.0, 0.9, 0.3)
		var sources_str = ", ".join(data.get("sources", []))
		journal_detail_text.text = "[b]Mission:[/b] %s\n[b]Year:[/b] %s\n[b]Location:[/b] %s\n[b]Status:[/b] %s\n\n[b]Purpose:[/b]\n%s\n\n[b]Historical Narrative:[/b]\n%s\n\n[b]Sources:[/b] %s" % [
			str(data.get("mission", "")),
			str(data.get("year", "")),
			str(data.get("location", "")),
			str(data.get("status", "")),
			str(data.get("purpose", "")),
			str(data.get("history", "")),
			sources_str
		]
	else:
		journal_detail_name.text = "Unidentified Anomaly"
		journal_detail_name.modulate = Color(0.7, 0.7, 0.7)
		journal_detail_text.text = "[i]This historical object remains buried beneath the lunar dust.\n\nFollow your handheld survey scanner signal to locate, excavate, and clean the artifact to uncover its identity and mission history![/i]"

func _on_menu_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
