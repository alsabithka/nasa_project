extends Node3D

# Echoes Beyond Earth - Proximity Scanner
# Adheres strictly to the agreed team scanner interface.

signal scan_updated(target_id: String, distance: float, signal_strength: float)
signal target_acquired(target_id: String)
signal target_lost()

# New signals for location-based interaction
signal locked_on_location()
signal left_location()

# New signal without identity info
signal mystery_signal_updated(strength: float, distance: float)

@export var max_scan_range: float = 65.0
@export var scan_rate: float = 5.0 # Hz (scans 5 times a second)
@export var is_active: bool = true

var current_target_id: String = ""
var current_distance: float = 999.0
var current_signal_strength: float = 0.0
var target_direction: Vector3 = Vector3.ZERO
var is_locked_on: bool = false
var beep_interval_near: float = 0.38

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
	_audio_player.volume_db = -18.0
	
	# Procedurally generate a clean 16-bit synthetic telemetry ping
	var sample_rate = 22050
	var duration = 0.06
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# 980 Hz smooth sine wave with clean exponential decay
		var env = exp(-t * 35.0)
		var wave = sin(t * 980.0 * TAU) * env * 0.7
		var sample_val = clampi(int(wave * 32767.0), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
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
	
	# Proximity audio ping disabled per Task 2 (visual screen/LED pulse provides feedback)
	_audio_timer = 0.0

func _perform_scan() -> void:
	var player = _get_player()
	if not player:
		return
	
	var scan_origin = player.get_scan_origin()
	var artifacts = get_tree().get_nodes_in_group("artifacts")
	
	var closest_artifact: Node = null
	var closest_dist: float = max_scan_range + 10.0
	var closest_delta: Vector3 = Vector3.ZERO
	
	var terrain = get_tree().get_first_node_in_group("terrain")
	var world_size: float = 180.0
	if terrain and "terrain_size" in terrain:
		world_size = terrain.terrain_size
	var half_world: float = world_size * 0.5
	
	for art in artifacts:
		if not art.has_method("get_artifact_id") or not art.has_method("get_world_position"):
			continue
		
		var art_id = art.get_artifact_id()
		var game_state = get_node_or_null("/root/GameState")
		if game_state and game_state.is_artifact_recovered(art_id):
			continue
		
		var art_pos = art.get_world_position()
		var dx = art_pos.x - scan_origin.x
		if world_size > 0.0:
			if dx > half_world: dx -= world_size
			elif dx < -half_world: dx += world_size
		
		var dz = art_pos.z - scan_origin.z
		if world_size > 0.0:
			if dz > half_world: dz -= world_size
			elif dz < -half_world: dz += world_size
		
		var dy = art_pos.y - scan_origin.y
		var dist = sqrt(dx * dx + dy * dy + dz * dz)
		
		if dist < closest_dist:
			closest_dist = dist
			closest_artifact = art
			closest_delta = Vector3(dx, dy, dz)
	
	if closest_artifact != null and closest_dist <= max_scan_range:
		var art_id = closest_artifact.get_artifact_id()
		var strength = clamp(1.0 - (closest_dist / max_scan_range), 0.0, 1.0)
		target_direction = closest_delta.normalized()
		
		if current_target_id != art_id:
			current_target_id = art_id
			target_acquired.emit(art_id)
		
		current_distance = closest_dist
		current_signal_strength = strength
		scan_updated.emit(art_id, closest_dist, strength)
		mystery_signal_updated.emit(strength, closest_dist)
		
		# Lock-on logic: within 4m = locked on
		if closest_dist <= 4.0:
			if not is_locked_on:
				is_locked_on = true
				locked_on_location.emit()
		else:
			# Hysteresis: only release lock after moving >6m away
			if is_locked_on and closest_dist > 6.0:
				is_locked_on = false
				left_location.emit()
	else:
		if current_target_id != "":
			current_target_id = ""
			current_distance = 999.0
			current_signal_strength = 0.0
			target_lost.emit()
			# If we were locked on, leaving scan range releases lock
			if is_locked_on:
				is_locked_on = false
				left_location.emit()
		scan_updated.emit("", 999.0, 0.0)
		mystery_signal_updated.emit(0.0, 999.0)

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
