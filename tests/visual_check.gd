extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const EnemyVisual = preload("res://scripts/enemy_visual.gd")

func _initialize() -> void:
	call_deferred("capture")

func save_frame(path: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	assert(root.get_texture().get_image().save_png(path) == OK)

func capture() -> void:
	# The project must open in a real fullscreen window with its aspect preserved.
	await create_timer(1.0).timeout
	assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("Fullscreen window: ", DisplayServer.window_get_size(), "; screen: ", DisplayServer.screen_get_size())
	var effects_board = load("res://tests/effects_board.gd").new()
	root.add_child(effects_board)
	await save_frame("res://tests/effect_directions.png")
	root.remove_child(effects_board)
	effects_board.queue_free()
	var board = load("res://tests/animation_board.gd").new()
	root.add_child(board)
	for phase in range(4):
		board.walk_time = (phase + 0.01) / 9.0
		board.queue_redraw()
		await save_frame("res://tests/animation_phase_%d.png" % phase)
	root.remove_child(board)
	board.queue_free()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.refresh_view()
	await save_frame("res://tests/title_screen.png")
	for test_level in range(4):
		game.start_level(test_level)
		game.state = "playing"
		game.clock = 1
		game.elapsed = 42
		game.player.movement.facing = Vector2.LEFT
		game.player.movement.moving = true
		for i in range(8):
			game.enemies.spawn_grunt()
			game.enemies.grunts[i].pos = Vector2(210 + (i % 4) * 230, 245 + (i / 4) * 300)
			game.enemies.grunts[i].movement.facing = [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP][i % 4]
			game.enemies.grunts[i].movement.moving = true
			game.enemies.grunts[i].movement.walk_time = 0.23
		game.enemies.grunts[0].weapon.fire()
		if test_level == 3:
			game.enemies.grunts[0].weapon.shoot = 10
			for tick in range(36):
				game.enemies.grunts[0].tick(0.01)
				for ball in game.projectiles.fireballs:
					ball.pos += ball.velocity * 0.01
			assert(game.projectiles.fireballs.size() == 3)
		else:
			game.projectiles.fireballs[0].pos = Vector2(400, 310)
		game.player.movement.facing = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][test_level]
		game.player.melee.attack_cooldown = 0
		game.player.melee.attack()
		game.player.melee.attack_timer = Rules.LEVELS[game.level].attack_duration * 0.5
		game.projectiles.fireballs.append({"pos": game.player.position + game.player.movement.facing * 85, "velocity": Vector2.ZERO, "age": 0.0, "size": 52.0, "radius": 12.0, "burst_age": 0.08})
		game.refresh_view()
		await save_frame("res://tests/fullscreen_level_%d.png" % (test_level + 1))
	for story_level in range(4):
		game.start_level(story_level)
		game.refresh_view()
		await save_frame("res://tests/story_level_%d.png" % (story_level + 1))
	game.state = "gameover"
	game.player.health.lives = 0
	game.refresh_view()
	await save_frame("res://tests/game_over.png")
	for boss_level in range(4):
		game.start_level(boss_level)
		game.start_wave(4)
		game.enemies.grunts[0].pos = Vector2(560, 230)
		game.player.position = Vector2(650, 500)
		game.enemies.grunts[0].weapon.fire()
		game.enemies.grunts[0].weapon.shoot = 10
		for tick in range(36):
			game.enemies.grunts[0].tick(0.01)
			for ball in game.projectiles.fireballs:
				ball.pos += ball.velocity * 0.01
		game.refresh_view()
		await save_frame("res://tests/boss_level_%d.png" % (boss_level + 1))
	game.elapsed = Rules.LEVELS[game.level].time_limit - 0.01
	game.update_game(0.02)
	game.refresh_view()
	await save_frame("res://tests/time_up.png")
	game.start_level(0)
	game.start_wave(4)
	game.enemies.grunts[0].hp = 0
	game.enemies.remove_dead_grunts()
	game.update_game(0.01)
	assert(game.state == "won")
	game.refresh_view()
	await save_frame("res://tests/you_win.png")
	for effect_level in [0, 2]:
		game.start_level(effect_level)
		game.start_wave(1)
		game.player.health.invulnerable = 0
		game.player.movement.facing = Vector2.RIGHT
		for kind in [0, 1, 3, 4]:
			game.powers.activate_power(kind)
		game.powers.power_timers[0] = 4.5
		game.powers.power_timers[1] = 3.5
		game.powers.power_timers[3] = 2.5
		game.powers.power_timers[4] = 1.5
		game.powers.activate_power(2)
		for kind in range(5):
			game.powers.pickups.append({"kind": kind, "pos": Vector2(330 + kind * 115, 570)})
		game.player.melee.attack()
		game.player.melee.attack_timer = game.player.melee.swing_duration * 0.5
		for offset in [180, 240, 300]:
			game.projectiles.shoot_player()
			game.projectiles.fireballs[-1].pos = game.player.position + Vector2(offset, 0)
		game.refresh_view()
		await save_frame("res://tests/powers_level_%d.png" % (effect_level + 1))
	for warning_level in range(4):
		game.start_level(warning_level)
		game.start_wave(4)
		game.player.position = Vector2(650, 500)
		var boss = game.enemies.grunts[0]
		boss.pos = Vector2(560, 300)
		boss.hp = boss.max_hp - boss.phase.health_per_phase()
		boss.weapon.shoot = 0
		boss.tick(0.01)
		boss.tick(1.3)
		boss.weapon.shoot = 0
		boss.tick(0.01)
		boss.tick(0.2)
		game.refresh_view()
		await save_frame("res://tests/boss_warning_%d.png" % (warning_level + 1))
		boss.tick(0.21)
		for tick in range(34):
			boss.tick(0.01)
			for ball in game.projectiles.fireballs:
				ball.pos += ball.velocity * 0.01
		game.refresh_view()
		await save_frame("res://tests/boss_phase_two_%d.png" % (warning_level + 1))
	print("PASS: fullscreen rendering and all animation phases captured")
	quit()
