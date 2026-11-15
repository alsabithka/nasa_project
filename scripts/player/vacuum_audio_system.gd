extends Node

# Echoes Beyond Earth - Vacuum Environmental Audio System
# Recreates scientifically authentic sound propagation in the lunar vacuum:
# 1. No sound travels through external vacuum (no wind, air whoosh, or ambient hiss).
# 2. Audio originates strictly inside the spacesuit helmet:
#    - Astronaut breathing cadence (speeds up during physical exertion)
#    - PLSS (Portable Life Support System) cooling pump and O2 fan hum
#    - Mechanically conducted low-frequency thuds from boots transmitted through the suit frame
#    - NASA Apollo Quindar telemetry beeps (2525 Hz) and radio communication clicks

var breathing_player: AudioStreamPlayer
var plss_hum_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer
var impact_player: AudioStreamPlayer
var comm_player: AudioStreamPlayer

var breathing_timer: float = 0.0
var breathing_period: float = 4.2 # Seconds per breath cycle (rest)
var target_breathing_period: float = 4.2
var is_inhaling: bool = true
var exertion: float = 0.0 # 0.0 (resting) to 1.0 (heavy loping/jumping)

func _ready() -> void:
	name = "VacuumAudioSystem"
	_setup_audio_players()

func _setup_audio_players() -> void:
	breathing_player = AudioStreamPlayer.new()
	breathing_player.name = "BreathingAudio"
	breathing_player.bus = &"Master"
	breathing_player.volume_db = -80.0
	add_child(breathing_player)
	
	plss_hum_player = AudioStreamPlayer.new()
	plss_hum_player.name = "PLSSHumAudio"
	plss_hum_player.bus = &"Master"
	plss_hum_player.volume_db = -80.0
	add_child(plss_hum_player)
	
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepAudio"
	footstep_player.bus = &"Master"
	footstep_player.volume_db = -12.0
	add_child(footstep_player)
	
	impact_player = AudioStreamPlayer.new()
	impact_player.name = "ImpactAudio"
	impact_player.bus = &"Master"
	impact_player.volume_db = -10.0
	add_child(impact_player)
	
	comm_player = AudioStreamPlayer.new()
	comm_player.name = "CommAudio"
	comm_player.bus = &"Master"
	comm_player.volume_db = -18.0
	add_child(comm_player)

func _start_plss_hum() -> void:
	if plss_hum_player:
		plss_hum_player.stop()

func _start_breathing() -> void:
	if breathing_player:
		breathing_player.stop()

func _process(delta: float) -> void:
	exertion = move_toward(exertion, 0.0, 0.15 * delta)
	target_breathing_period = lerp(4.4, 2.1, exertion)

func _play_breath_phase(_inhale: bool) -> void:
	pass

# Called by player controller when physical exertion occurs
func report_exertion(amount: float) -> void:
	exertion = clampf(exertion + amount, 0.0, 1.0)

# Muffled suit-conducted footstep vibration thud (clean 16-bit signed PCM)
func play_footstep(is_loping: bool) -> void:
	var sample_rate = 22050
	var duration = 0.12 if not is_loping else 0.16
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Deep mechanical thud: 55Hz pitch dropping exponentially to 25Hz
		var freq = lerp(55.0, 25.0, t / duration)
		var env = exp(-t * 28.0)
		var wave = sin(t * freq * TAU) * env * (0.6 if is_loping else 0.4)
		var sample_val = clampi(int(wave * 32767.0), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	
	footstep_player.stream = wav
	footstep_player.volume_db = -10.0 if is_loping else -14.0
	footstep_player.pitch_scale = randf_range(0.92, 1.08)
	footstep_player.play()

# Heavy landing impact vibration through astronaut's knees and suit (clean 16-bit signed PCM)
func play_landing_thud(impact_velocity: float) -> void:
	var sample_rate = 22050
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	var intensity = clampf(abs(impact_velocity) / 4.0, 0.3, 1.0)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var freq = lerp(45.0, 18.0, t / duration)
		var env = exp(-t * 18.0)
		var wave = sin(t * freq * TAU) * env * intensity * 0.8
		var sample_val = clampi(int(wave * 32767.0), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	
	impact_player.stream = wav
	impact_player.volume_db = lerp(-14.0, -6.0, intensity)
	impact_player.play()
	report_exertion(0.35)

# Apollo Quindar tone removed per Task 2
func play_quindar_tone() -> void:
	pass

# Radio static squelch click (clean 16-bit signed PCM)
func play_comm_click() -> void:
	var sample_rate = 22050
	var duration = 0.05
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var noise = (randf() * 2.0 - 1.0) * 0.35
		var sample_val = clampi(int(noise * 32767.0), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	
	comm_player.stream = wav
	comm_player.play()
