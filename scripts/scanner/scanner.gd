extends Node3D

# Echoes Beyond Earth - Proximity Scanner
# Adheres strictly to the agreed team scanner interface.

signal scan_updated(target_id: String, distance: float, signal_strength: float)
signal target_acquired(target_id: String)
signal target_lost()

@export var max_scan_range: float = 65.0
@export var scan_rate: float = 5.0 # Hz (scans 5 times a second)
@export var is_active: bool = true

var current_target_id: String = ""
var current_distance: float = 999.0
var current_signal_strength: float = 0.0
var target_direction: Vector3 = Vector3.ZERO

var _scan_timer: float = 0.0
var _audio_timer: float = 0.0
var _audio_player: AudioStreamPlayer

func _ready() -> void:
	_setup_audio()
	add_to_group("scanner")

func _setup_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.bus = &"Master"
	_audio_player.volume_db = -12.0
	
	# Procedurally generate a clean synthetic beep sound
	var sample_rate = 22050
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# 880 Hz beep with subtle exponential decay
		var wave = sin(t * 880.0 * TAU) * exp(-t * 25.0)
		var byte_val = clampi(int((wave + 1.0) * 0.5 * 255.0), 0, 255)
		data[i] = byte_val
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	_audio_player.stream = wav

func _process(delta: float) -> void:
	if not is_active:
		return
	
	_scan_timer += delta
	if _scan_timer >= (1.0 / scan_rate):
		_scan_timer = 0.0
		_perform_scan()
	
	# Handle proximity beep cadence
	if current_signal_strength > 0.05:
		_audio_timer += delta
		# Beep interval scales inversely with signal strength: 1.2s far -> 0.15s near
		var beep_interval = lerp(1.2, 0.15, current_signal_strength)
		if _audio_timer >= beep_interval:
			_audio_timer = 0.0
			if _audio_player and not _audio_player.playing:
				# Scale pitch slightly higher when closer (880Hz -> 1320Hz)
				_audio_player.pitch_scale = lerp(0.9, 1.4, current_signal_strength)
				_audio_player.play()

func _perform_scan() -> void:
	var player = _get_player()
	if not player:
		return
	
	var scan_origin = player.get_scan_origin()
	var artifacts = get_tree().get_nodes_in_group("artifacts")
	
	var closest_artifact: Node = null
	var closest_dist: float = max_scan_range + 10.0
	
	for art in artifacts:
		if not art.has_method("get_artifact_id") or not art.has_method("get_world_position"):
			continue
		
		var art_id = art.get_artifact_id()
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.is_artifact_recovered(art_id):
			continue
		
		var dist = scan_origin.distance_to(art.get_world_position())
		if dist < closest_dist:
			closest_dist = dist
			closest_artifact = art
	
	if closest_artifact != null and closest_dist <= max_scan_range:
		var art_id = closest_artifact.get_artifact_id()
		var strength = clamp(1.0 - (closest_dist / max_scan_range), 0.0, 1.0)
		target_direction = (closest_artifact.get_world_position() - scan_origin).normalized()
		
		if current_target_id != art_id:
			current_target_id = art_id
			target_acquired.emit(art_id)
		
		current_distance = closest_dist
		current_signal_strength = strength
		scan_updated.emit(art_id, closest_dist, strength)
	else:
		if current_target_id != "":
			current_target_id = ""
			current_distance = 999.0
			current_signal_strength = 0.0
			target_lost.emit()
		scan_updated.emit("", 999.0, 0.0)

func _get_player() -> Node:
	if get_parent() and get_parent().has_method("get_scan_origin"):
		return get_parent()
	return get_tree().get_first_node_in_group("player")

# Public accessors
func get_current_target() -> String:
	return current_target_id

func get_signal_strength() -> float:
	return current_signal_strength

func get_target_distance() -> float:
	return current_distance

func get_target_direction() -> Vector3:
	return target_direction
