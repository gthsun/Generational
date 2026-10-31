extends Node
## Wait for the selected defeat sound before progression.
signal completed
var players: Array[AudioStreamPlayer] = []
var remaining = 0

func _ready() -> void:
	for sound_name in ["boss_defeated", "final_boss_defeated"]:
		var voice = AudioStreamPlayer.new()
		voice.stream = load("res://assets/audio/sfx/%s.wav" % sound_name)
		voice.volume_db = 0
		add_child(voice)
		voice.finished.connect(on_finished)
		players.append(voice)

func play_defeat(final_boss: bool) -> void:
	stop()
	remaining = 1
	if final_boss:
		players[1].play()
	else:
		players[0].play()

func on_finished() -> void:
	if remaining <= 0:
		return
	remaining -= 1
	if remaining == 0:
		completed.emit()

func stop() -> void:
	remaining = 0
	for voice in players:
		voice.stop()

func _exit_tree() -> void:
	stop()
	for voice in players:
		voice.stream = null
