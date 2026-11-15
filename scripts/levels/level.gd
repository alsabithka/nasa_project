extends Node3D

# Echoes Beyond Earth - Base Level Controller
# Configures planet gravity, player state, and UI.

@export var planet_name: String = "Moon"
@export var level_gravity: float = 1.62
@export var background_music_path: String = "res://audio/music/lunar_ambient_exploration.wav"
@export var music_volume_db: float = -22.0

var _music_player: AudioStreamPlayer = null
var _music_fade_tween: Tween = null

func _ready() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.current_planet = planet_name
	
	var player = get_tree().get_first_node_in_group("player")
	if player and "gravity" in player:
		if player.has_method("update_gravity"):
			player.update_gravity(level_gravity)
		else:
			player.gravity = level_gravity
	
	var dust = get_tree().get_first_node_in_group("ballistic_dust")
	if dust and dust.has_method("set_gravity"):
		dust.set_gravity(level_gravity)
	
	_start_background_music()
	print("[Level] Loaded ", planet_name, " with gravity: ", level_gravity)

func _start_background_music() -> void:
	if background_music_path.is_empty():
		return
	if not ResourceLoader.exists(background_music_path):
		push_warning("[Level] Music track not found: " + background_music_path)
		return
	
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "LevelBGMPlayer"
	_music_player.bus = &"Master"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS  # merge D11: music keeps playing while paused
	add_child(_music_player)
	
	var stream = load(background_music_path)
	if not stream:
		push_warning("[Level] Failed to load music stream: " + background_music_path)
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= 0:
			# For 16-bit stereo (4 bytes per frame) or mono (2 bytes per frame)
			var bytes_per_frame = 4 if stream.stereo else 2
			stream.loop_end = stream.data.size() / bytes_per_frame
	_music_player.stream = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	print("[Level] Music started: ", background_music_path)
	
	# Smooth fade-in on level entry (3.5s)
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", music_volume_db, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func fade_out_music(duration: float = 1.5) -> void:
	if _music_player and _music_player.playing:
		if _music_fade_tween and _music_fade_tween.is_valid():
			_music_fade_tween.kill()
		_music_fade_tween = create_tween()
		_music_fade_tween.tween_property(_music_player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_fade_tween.tween_callback(func():
			if _music_player:
				_music_player.stop()
		)
