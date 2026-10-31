extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_level(level)
		game.start_wave(3)
		assert(game.enemies.grunts.size() == 16)
		assert(game.music.stream == game.music.wave_track and game.music.playing and game.music.stream.loop)
		game.elapsed = game.Rules.LEVELS[level].time_limit - 0.01
		game.start_wave(4)
		assert(game.music.stream == game.music.boss_track and game.music.playing and game.music.stream.loop)
		game.update_game(0.05, 10)
		assert(game.player.health.lives == (4 if level == 3 else 3) and game.state == "playing")
		assert(is_equal_approx(game.elapsed, game.Rules.LEVELS[level].time_limit - 0.01))
		game.paused = true
		game._process(1)
		assert(game.music.stream_paused)
		game.paused = false
		game._process(0.01)
		assert(not game.music.stream_paused)
		var boss = game.enemies.grunts[0]
		boss.pos = Vector2(850, 380)
		boss.hp = floori(boss.max_hp - boss.phase.health_per_phase())
		boss.tick(0.1)
		assert(boss.phase.phase_two and not boss.phase.phase_three and boss.phase.jump_to.x == 70)
		boss.tick(1.2)
		boss.hp = floori(boss.max_hp - 2 * boss.phase.health_per_phase())
		boss.weapon.special_left = 20
		boss.tick(0.1)
		assert(boss.phase.phase_three and boss.phase.jump_to.x == 1050)
		assert(boss.size == 120 and boss.weapon.special_left == 0)
		boss.tick(1.2)
		assert(boss.maneuver.landing_frame and boss.pos == boss.phase.jump_to)
		boss.tick(0.01)
		assert(boss.maneuver.warning > 0 and not boss.maneuver.landing_frame)
		boss.tick(1)
		assert(boss.maneuver.active)
		var origin: Vector2 = boss.pos
		game.projectiles.fireballs.clear()
		var duration = [2.0, 5.0, 4.0, 5.0][level]
		for frame in range(roundi(duration * 100)):
			boss.maneuver.tick(0.01)
			assert(game.Rules.ARENA.has_point(boss.pos))
			if level == 0 and frame == 99:
				assert(boss.pos.distance_to(game.player.position) < 0.1)
			if level == 2 and frame in [79, 159, 239, 319]:
				assert(game.projectiles.fireballs.size() == (frame + 1) / 80)
		boss.maneuver.tick(0.001)
		assert(not boss.maneuver.active and boss.pos.distance_to(origin) < 0.01)
		match level:
			0: assert(game.projectiles.fireballs.is_empty())
			1: assert(game.projectiles.fireballs.size() >= 30)
			2: assert(game.projectiles.fireballs.size() == 4 and game.projectiles.fireballs[0].acceleration == 950)
			3: assert(game.projectiles.fireballs.size() >= 50 and game.projectiles.fireballs.size() <= 51)
		assert(boss.maneuver.cooldown > 8 and boss.weapon.recover == 1)
		# Existing blue attacks remain available between movement attacks.
		boss.weapon.special = false
		game.projectiles.fireballs.clear()
		boss.weapon.fire()
		assert(game.projectiles.fireballs[0].boss)
	game.start_level(0)
	game.start_wave(0)
	game.powers.activate_power(1)
	game.update_game(0.1)
	assert(game.projectiles.fireballs.is_empty())
	game.player.melee.attack()
	game.player.melee.attack()
	assert(game.projectiles.fireballs.size() == 1)
	game.player.melee.attack_cooldown = 0
	game.player.melee.attack()
	assert(game.projectiles.fireballs.size() == 2)
	game.queue_free()
	await process_frame
	print("PASS: fourth wave, wave-only deadline, music switch/pause, both phase jumps, phase-three growth/routes/durations/projectiles, attack-triggered shooting")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
