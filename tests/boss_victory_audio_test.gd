extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_boss_test(level)
		game.enemies.grunts[0].hp = 0
		game.enemies.remove_dead_grunts()
		game.update_game(0.01)
		assert(game.state == "boss_defeated" and game.level == level)
		assert(not game.music.playing)
		assert(game.victory_audio.remaining == 1)
		assert(game.victory_audio.players[0].playing == (level < 3))
		assert(game.victory_audio.players[1].playing == (level == 3))
		assert(game.victory_audio.players.size() == 2)
		var clock: float = game.clock
		game._process(100)
		assert(game.state == "boss_defeated" and game.clock == clock)
		await game.victory_audio.completed
		assert(game.state == ("won" if level == 3 else "intro"))
		assert(game.level == mini(level + 1, 3))
	game.start_boss_test(0)
	game.finish_wave()
	game.start_wave_test(2)
	assert(game.victory_audio.remaining == 0 and game.state == "playing")
	for voice in game.victory_audio.players:
		assert(not voice.playing)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: defeat pause, real audio completion, single final track, progression and debug cancellation")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
