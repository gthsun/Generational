extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.state == "title" and game.music.playing)
	assert(game.music.stream == game.music.menu_track and game.music.stream.loop)
	assert(game.victory_audio.players.size() == 2)
	for level in range(4):
		game.start_level(level)
		assert(game.state == "intro" and game.music.playing)
		assert(game.music.stream == game.music.exposition_track and game.music.stream.loop)
	game.start_level(0)
	game.start_wave(0)
	assert(game.music.stream == game.music.wave_track)
	game.player.health.lose_all()
	game._process(2)
	assert(game.state == "gameover" and game.music.playing)
	assert(game.music.stream == game.music.game_over_track and game.music.stream.loop)
	game.start_wave_test(1)
	assert(game.music.stream == game.music.wave_track and game.music.playing)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: looping title/game-over tracks, restart switching and removed second finale")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
