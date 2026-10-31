extends AudioStreamPlayer
## A dedicated audio node keeps wave and boss tracks continuous across their stages.
var wave_track: AudioStreamMP3
var boss_track: AudioStreamMP3
var menu_track: AudioStreamMP3
var game_over_track: AudioStreamMP3
var exposition_track: AudioStreamMP3

func _ready() -> void:
	wave_track = load("res://Wave.mp3").duplicate()
	boss_track = load("res://Boss.mp3").duplicate()
	menu_track = load("res://MainMenu.mp3").duplicate()
	game_over_track = load("res://GameOver.mp3").duplicate()
	exposition_track = load("res://Exposition.mp3").duplicate()
	for track in [wave_track, boss_track, menu_track, game_over_track, exposition_track]:
		track.loop = true
	volume_db = -7

func play_stage(is_boss: bool) -> void:
	play_track(boss_track if is_boss else wave_track, -10 if is_boss else -7)

func play_menu() -> void:
	play_track(menu_track, -7)

func play_exposition() -> void:
	play_track(exposition_track, -7)

func play_game_over() -> void:
	play_track(game_over_track, -7)

func play_track(next_track: AudioStreamMP3, volume: float) -> void:
	volume_db = volume
	if stream == next_track and playing:
		return
	stream = next_track
	stream_paused = false
	play()
