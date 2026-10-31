extends SceneTree
var events = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sounds.sound_played.connect(func(sound_name, pitch): events.append([sound_name, pitch]))
	for stream in game.sounds.streams.values():
		assert(stream != null and stream.get_length() > 0)
	for level in range(4):
		await process_frame
		if game.sounds.footstep_voice.playing:
			await game.sounds.footstep_voice.finished
		game.start_level(level)
		game.start_wave(4)
		game.player.melee.attack()
		assert(events[-1][0] == ("boom" if level == 2 else "slash"))
		game.player.melee.attack_timer = 0
		game.player.movement.update_player_motion(Vector2.RIGHT, 0.3)
		assert(events[-1][0] == ("level4_step" if level == 3 else "grass_step"))
		var step_count = events.size()
		for step_name in ["grass_step", "level4_step", "enemy_grass_step", "enemy_level3_step", "enemy_level4_step"]:
			game.sounds.play_effect(step_name)
		assert(events.size() == step_count, "All footstep types share one voice")
		await game.sounds.footstep_voice.finished
		var boss = game.enemies.grunts[0]
		boss.footsteps.moved(boss.position - Vector2(30, 0), 0.3, true)
		assert(events[-1][0] == ["enemy_grass_step", "enemy_grass_step", "enemy_level3_step", "enemy_level4_step"][level])
		var count = events.size()
		boss.footsteps.moved(boss.position - Vector2(30, 0), 0.3, true, true)
		assert(events.size() == count)
		boss.weapon.fire()
		assert(events[-1] == ["fireball_big", 1.0])
		boss.phase.begin_jump(2)
		assert(events[-1][0] == "jump")
	await process_frame
	game.sounds.fireball(true, 18)
	assert(events[-1][1] > 1)
	game.sounds.fireball(true, 368)
	assert(events[-1][1] < 1)
	game.start_level(0)
	game.start_wave(0)
	game.enemies.grunts[0].weapon.fire()
	assert(events[-1] == ["fireball", 1.0])
	var ball = game.projectiles.fireballs[-1]
	game.projectiles.burst_fireball(ball)
	assert(events[-1][0] == "fireball_destroyed")
	await process_frame
	var count = events.size()
	game.projectiles.burst_fireball(ball)
	assert(events.size() == count)
	game.player.health.invulnerable = 0
	game.player.health.hurt_player()
	assert(events[-1][0] == "lose_life")
	await process_frame
	count = events.size()
	game.player.health.hurt_player()
	assert(events.size() == count)
	game.start_level(0)
	var key = InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	count = events.size()
	game._unhandled_key_input(key)
	assert(events.size() == count)
	key.keycode = KEY_ESCAPE
	game._unhandled_key_input(key)
	assert(events[-1][0] == "select" and game.paused)
	game._process(0.01)
	assert(not game.sounds.menu_voice.stream_paused)
	game._unhandled_key_input(key)
	assert(events[-1][0] == "select" and not game.paused)
	game.paused = true
	game._process(0.1)
	assert(game.sounds.footstep_voice.stream_paused)
	for voice in game.sounds.voices:
		if voice.playing:
			assert(voice.stream_paused)
	game.queue_free()
	await create_timer(0.25).timeout
	print("PASS: sound assets, attacks, footsteps, airborne silence, launch pitches, destruction, damage, menus and pause")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
