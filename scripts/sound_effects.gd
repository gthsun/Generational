extends Node
## Bounded voices and per-frame coalescing keep crowds and spread shots audible.
signal sound_played(sound_name: String, pitch: float)
const NAMES = ["boom", "enemy_grass_step", "enemy_level3_step", "enemy_level4_step", "fireball_big", "fireball_destroyed", "fireball", "grass_step", "jump", "level4_step", "lose_life", "select", "slash"]
var streams = {}
var voices: Array[AudioStreamPlayer] = []
var last_frame = {}
var next_voice = 0
var footstep_voice: AudioStreamPlayer
var menu_voice: AudioStreamPlayer

func _ready() -> void:
	for sound_name in NAMES:
		streams[sound_name] = load("res://assets/audio/sfx/%s.wav" % sound_name)
	menu_voice = AudioStreamPlayer.new()
	menu_voice.name = "Menu"
	add_child(menu_voice)
	footstep_voice = AudioStreamPlayer.new()
	footstep_voice.name = "Footsteps"
	add_child(footstep_voice)
	for i in range(24):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func play_effect(sound_name: String, pitch: float = 1.0) -> void:
	if sound_name == "select":
		start_voice(menu_voice, sound_name, pitch)
		return
	if "step" in sound_name:
		if not footstep_voice.playing:
			start_voice(footstep_voice, sound_name, pitch)
		return
	var key = sound_name + str(snappedf(pitch, 0.01))
	var frame = Engine.get_process_frames()
	if last_frame.get(key, -1) == frame:
		return
	last_frame[key] = frame
	var voice = voices[next_voice]
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	next_voice = (next_voice + 1) % voices.size()
	start_voice(voice, sound_name, pitch)

func start_voice(voice: AudioStreamPlayer, sound_name: String, pitch: float) -> void:
	voice.stream = streams[sound_name]
	voice.pitch_scale = pitch
	voice.volume_db = -20 if "step" in sound_name else (-14 if "fireball" in sound_name else -8)
	voice.play()
	sound_played.emit(sound_name, pitch)

func fireball(boss: bool, special_size: float = 0) -> void:
	var pitch = clampf(sqrt(104.0 / special_size), 0.55, 2.2) if special_size > 0 else 1.0
	play_effect("fireball_big" if boss else "fireball", pitch)

func set_paused(value: bool) -> void:
	footstep_voice.stream_paused = value
	for voice in voices:
		voice.stream_paused = value

func _exit_tree() -> void:
	menu_voice.stop()
	menu_voice.stream = null
	footstep_voice.stop()
	footstep_voice.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()

func stop_all() -> void:
	menu_voice.stop()
	footstep_voice.stop()
	for voice in voices:
		voice.stop()
