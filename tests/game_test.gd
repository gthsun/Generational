extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const EnemyVisual = preload("res://scripts/enemy_visual.gd")
var game

func _initialize() -> void:
	call_deferred("run")

func enter_level(index: int) -> void:
	game.start_level(index)
	game._process(120.0)
	assert(game.state == "intro" and game.elapsed == 0 and game.enemies.grunts.is_empty())
	assert(game.hud.story_lines().size() <= 8)
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	game._unhandled_key_input(key)
	assert(game.state == "playing" and game.wave == 0 and game.enemies.grunts.size() == 4)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.state == "title" and game.assets.title_card != null and game.assets.firebar_frames.size() == 5)
	game._process(60)
	assert(game.state == "title" and game.elapsed == 0)
	var start := InputEventKey.new()
	start.keycode = KEY_ENTER
	start.pressed = true
	game._unhandled_key_input(start)
	assert(game.state == "intro" and game.enemies.grunts.is_empty())
	for frame in range(5):
		assert(game.assets.firebar_frames[frame] != null)
		if frame > 0:
			assert(EnemyVisual.charge_frame(Rules.SHOT_WARNING * (1.0 - (frame - 1 + 0.01) / 4.0)) == frame)
	assert(game.assets.forcefield_frames.size() == 3)
	for texture in game.assets.forcefield_frames:
		assert(texture != null)
	for tick in range(12):
		game.powers.power_timers[4] = Rules.POWER_SECONDS - (tick + 0.01) / 8.0
		assert(game.player.forcefield_frame() == [0, 1, 2, 1][tick % 4])
	game.powers.power_timers.clear()
	game.rng.seed = 321
	assert(game.assets.player_frames.size() == 52 and game.assets.grunt_frames.size() == 52)
	assert(game.assets.boss_frames.size() == 52)
	assert(game.assets.clock_frames.size() == 17 and game.assets.fire_frames.size() == 9)
	assert(game.assets.heart != null)
	for texture in game.assets.player_frames + game.assets.grunt_frames + game.assets.boss_frames + game.assets.clock_frames + game.assets.fire_frames + game.assets.slash_frames + game.assets.boom_frames:
		assert(texture != null)
	assert(ProjectSettings.get_setting("display/window/size/mode") == 3)
	check_animations_and_combat()
	check_wave_campaign()
	check_timeout()
	check_robot()
	check_fireballs()
	check_powers()
	print("PASS: four waves plus boss, 4/8/12/16/1 counts, boss size/health/collision/projectiles/cadence, level clocks and timeout life loss, pause, death and restart, animation mapping, robot bursts, fireball destruction")
	game.queue_free()
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()

func check_animations_and_combat() -> void:
	for index in range(4):
		enter_level(index)
		for direction in [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]:
			var base: int = index * 13 + (4 if direction.x != 0 else (8 if direction.y < 0 else 0))
			assert(Rules.frame_index(game.level, direction, false, false) == base)
			assert(Rules.frame_index(game.level, direction, true, true) == base + 3)
			for tick in range(8):
				assert(Rules.frame_index(game.level, direction, true, false, (tick + 0.01) / 9.0) == base + [1, 0, 2, 0][tick % 4])
		var effect_count := 4 if index == 2 else 7
		assert(game.player.melee.attack_effect_frames().size() == effect_count)
		for frame in range(effect_count):
			game.player.melee.attack_timer = Rules.LEVELS[game.level].attack_duration * (1 - (frame + 0.01) / effect_count)
			assert(game.player.melee.attack_effect_frame() == frame)
		game.enemies.clear()
		game.enemies.spawn_grunt()
		var grunt = game.enemies.grunts[0]
		for hit in range([1, 2, 2, 3][index]):
			grunt.pos = game.player.position + Vector2(0, 45)
			game.player.melee.attack_cooldown = 0
			game.player.melee.attack()
			game.player.melee.apply_attack_hits()
			assert(grunt.hp == [1, 2, 2, 3][index] - hit - 1, "Only one hit per swing")
		assert(game.enemies.grunts.is_empty() and game.enemies.corpses.size() == 1)
	enter_level(0)
	game.player.movement.update_player_motion(Vector2.LEFT, 0.02)
	game.player.movement.update_player_motion(Vector2(-1, -1).normalized(), 0.02)
	assert(game.player.movement.facing == Vector2.LEFT)
	game.player.melee.attack()
	var before: Vector2 = game.player.position
	game.player.movement.update_player_motion(Vector2.RIGHT, 0.02)
	assert(game.player.movement.facing == Vector2.LEFT and game.player.position == before)

func check_wave_campaign() -> void:
	for index in range(4):
		enter_level(index)
		assert(game.level == index and game.elapsed == 0 and game.player.health.lives == (4 if index == 3 else 3))
		for wave in range(5):
			assert(game.wave == wave and game.enemies.grunts.size() == [4, 8, 12, 16, 1][wave])
			game.player.health.invulnerable = 100
			for tick in range(40):
				game.update_game(0.01)
			assert(game.enemies.grunts.size() == [4, 8, 12, 16, 1][wave], "No continuous spawning")
			if wave == 4:
				var boss = game.enemies.grunts[0]
				assert(boss.boss and boss.size == 104 and is_equal_approx(boss.radius, 15.0 * 104 / 88) and boss.max_hp == [12, 15, 18, 24][index])
				game.projectiles.fireballs.clear()
				boss.weapon.fire()
				assert(game.projectiles.fireballs[0].size == [104.0, 56.0, 160.0, 56.0][index])
				assert(game.projectiles.fireballs[0].boss)
				assert(boss.weapon.firing_delay() < 1.3)
				# Boss contact and melee now use a normal-sized body.
				game.player.position = Vector2(560, 380)
				boss.pos = game.player.position + Vector2(0, 60)
				game.player.movement.facing = Vector2.DOWN
				game.player.melee.attack_cooldown = 0
				game.player.melee.attack()
				assert(boss.hp == boss.max_hp - 1)
				game.player.melee.attack_timer = 0
				game.player.health.invulnerable = 0
				boss.pos = game.player.position + Vector2(0, 25)
				game.update_game(0.001)
				assert(game.player.health.lives == (3 if index == 3 else 2))
			var previous_time: float = game.elapsed
			for grunt in game.enemies.grunts:
				grunt.hp = 0
			game.enemies.remove_dead_grunts()
			game.player.melee.attack_timer = 0
			game.update_game(0.001)
			assert(game.projectiles.fireballs.is_empty())
			if wave == 4:
				assert(game.state == "boss_defeated")
				game.victory_audio.stop()
				game.finish_boss_victory()
			if wave < 4:
				assert(game.state == "wave_intro")
				game._process(3.0 if game.wave == Rules.BOSS_WAVE else 1.0)
				assert(game.state == "playing" and game.elapsed >= previous_time)
			elif index < 3:
				assert(game.state == "intro" and game.level == index + 1 and game.player.health.lives == (4 if index == 2 else 3))
			else:
				assert(game.state == "won" and game.level == index)
				game._process(2.0)
				assert(game.state == "won" and game.level == index)
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	game._unhandled_key_input(event)
	assert(game.state == "intro" and game.level == 0 and game.player.health.lives == 3)

func check_timeout() -> void:
	for index in range(4):
		enter_level(index)
		var duration: float = [120.0, 135.0, 150.0, 165.0][index]
		assert(Rules.LEVELS[index].time_limit == duration)
		game.paused = true
		game._process(10)
		assert(game.elapsed == 0)
		game.paused = false
		game.player.health.invulnerable = 100
		game._process(0.5)
		assert(is_equal_approx(game.elapsed, 0.5), "Real time, not capped movement time")
		for frame in range(16):
			game.elapsed = duration * (frame + 0.01) / 16
			assert(game.hud.clock_frame() == frame)
		game.start_wave(1)
		game.powers.activate_power(2)
		game.powers.activate_power(4)
		game.elapsed = duration - 0.01
		game.player.health.invulnerable = 100
		game.update_game(0.02)
		assert(game.player.health.lives == 0 and game.hud.clock_frame() == 16)
		assert(game.state == "dying" and game.projectiles.fireballs.is_empty())
		game._process(0.1)
		assert(game.player.health.lives == 0 and game.state == "dying")
		game._process(2.0)
		assert(game.state == "gameover")

func check_robot() -> void:
	for boss in [false, true]:
		enter_level(3)
		game.enemies.clear()
		game.projectiles.fireballs.clear()
		game.enemies.spawn_grunt(boss)
		var robot = game.enemies.grunts[0]
		robot.pos = Vector2(200, 220)
		robot.weapon.shoot = 10
		robot.weapon.fire()
		var origin: Vector2 = robot.pos
		var aim: Vector2 = game.projectiles.fireballs[0].velocity
		assert(game.projectiles.fireballs.size() == 1)
		robot.tick(0.15)
		assert(game.projectiles.fireballs.size() == 1)
		robot.tick(0.02)
		assert(game.projectiles.fireballs.size() == 2)
		robot.tick(0.16)
		assert(game.projectiles.fireballs.size() == 3 and robot.pos == origin)
		for ball in game.projectiles.fireballs:
			assert(ball.velocity == aim and ball.size == (56 if boss else 28))
		var stopped := false
		var moved := false
		for tick in range(100):
			var old_pos: Vector2 = robot.pos
			robot.tick(0.01)
			var delta: Vector2 = robot.pos - old_pos
			assert(is_zero_approx(delta.x) or is_zero_approx(delta.y))
			stopped = stopped or delta.is_zero_approx()
			moved = moved or not delta.is_zero_approx()
		assert(stopped and moved and game.projectiles.fireballs.size() == 3)

func check_fireballs() -> void:
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
		enter_level(0)
		game.player.health.invulnerable = 0
		game.player.movement.facing = direction
		var shot := {"pos": game.player.position + direction * 60, "velocity": -direction * 400, "age": 0.0, "size": 52.0, "radius": 12.0}
		for tick in range(12):
			shot.age = (tick + 0.01) / 16
			assert(game.projectiles.fireball_frame(shot) == tick % 6)
		game.projectiles.fireballs.append(shot)
		game.player.melee.attack()
		assert(shot.burst_age == 0 and game.projectiles.fireball_frame(shot) == 6)
		game.projectiles.update_fireballs(0.063)
		assert(game.projectiles.fireball_frame(shot) == 7)
		game.projectiles.update_fireballs(0.063)
		assert(game.projectiles.fireball_frame(shot) == 8)
		game.projectiles.update_fireballs(0.063)
		assert(game.projectiles.fireballs.is_empty())
		game.projectiles.fireballs.append({"pos": game.player.position + direction * 120, "velocity": -direction * 3000, "age": 0.0, "size": 28.0, "radius": 7.0})
		game.projectiles.update_fireballs(0.05)
		assert(game.projectiles.fireballs[0].burst_age == 0 and game.player.health.lives == 3)
		game.projectiles.fireballs.clear()
		game.projectiles.fireballs.append({"pos": game.player.position - direction * 40, "velocity": direction * 800, "age": 0.0, "size": 28.0, "radius": 7.0})
		game.projectiles.update_fireballs(0.05)
		assert(game.player.health.lives == 2)

func check_powers() -> void:
	enter_level(0)
	assert(game.assets.power_frames.size() == 5)
	for texture in game.assets.power_frames:
		assert(texture != null)
	assert(game.powers.power_spawn_timer >= 10 and game.powers.power_spawn_timer <= 15)
	game.powers.power_spawn_timer = 5
	game.powers.update_powers(4.99)
	assert(game.powers.pickups.is_empty())
	game.powers.update_powers(0.02)
	assert(game.powers.pickups.size() == 1)
	assert(game.powers.power_spawn_timer >= 10 and game.powers.power_spawn_timer <= 15)
	game.powers.pickups.clear()
	# Collecting a heart at full health never increases the starting cap.
	game.powers.pickups.append({"kind": 2, "pos": game.player.position})
	game.powers.collect_powers()
	assert(game.player.health.lives == 3 and game.player.health.max_lives == 3 and game.powers.pickups.is_empty())
	assert(game.powers.power_timers.is_empty())
	game.powers.activate_power(0)
	game.powers.activate_power(1)
	game.powers.activate_power(3)
	game.powers.activate_power(4)
	assert(game.powers.power_timers.size() == 4)
	for kind in [0, 1, 3, 4]:
		assert(game.powers.power_clock_frame(kind) == 0)
	game.paused = true
	game._process(2.0)
	assert(game.powers.power_timers[0] == 5)
	game.paused = false
	game.powers.update_powers(2.5)
	for kind in [0, 1, 3, 4]:
		assert(game.powers.power_clock_frame(kind) == 8)
	game.powers.activate_power(0)
	assert(game.powers.power_timers.size() == 4 and game.powers.power_timers[0] == 5)
	game.player.health.invulnerable = 0
	game.player.health.hurt_player()
	game.player.health.hurt_player(true)
	assert(game.player.health.lives == 3, "Invincibility blocks combat damage")
	game.powers.update_powers(2.5)
	assert(game.powers.power_timers.size() == 1 and game.powers.power_active(0))
	game.player.health.hurt_player()
	assert(game.player.health.lives == 2)
	game.powers.update_powers(2.5)
	assert(game.powers.power_timers.is_empty())
	# Four directional hits stack with enlarged attacks and damage each enemy once.
	enter_level(3)
	game.enemies.clear()
	game.powers.activate_power(0)
	game.powers.activate_power(3)
	for direction in Rules.CARDINALS:
		game.enemies.spawn_grunt()
		game.enemies.grunts[-1].pos = game.player.position + direction * 125
	game.player.melee.attack()
	assert(game.player.melee.attack_directions().size() == 4 and game.player.melee.swing_scale == 1.8)
	assert(game.player.melee.attack_timer < Rules.LEVELS[3].attack_duration)
	assert(game.player.melee.attack_cooldown < Rules.LEVELS[3].attack_cooldown)
	game.player.melee.apply_attack_hits()
	for grunt in game.enemies.grunts:
		assert(grunt.hp == 2)
	# Four-direction attacks also intercept incoming shots from every side.
	for direction in Rules.CARDINALS:
		game.projectiles.fireballs.append({"pos": game.player.position + direction * 170, "velocity": -direction * 3000, "age": 0.0, "size": 28.0, "radius": 7.0})
	game.projectiles.update_fireballs(0.05)
	for ball in game.projectiles.fireballs:
		assert(ball.burst_age == 0)
	# Player shots follow attacks, tiny, friendly, and can damage enemies at range.
	enter_level(0)
	game.player.health.invulnerable = 0
	game.player.movement.facing = Vector2.RIGHT
	game.powers.activate_power(1)
	game.update_game(0.01)
	assert(game.projectiles.fireballs.is_empty())
	game.player.melee.attack()
	assert(game.projectiles.fireballs.size() == 1 and game.projectiles.fireballs[0].friendly)
	assert(game.projectiles.fireballs[0].size == 20)
	var target = game.enemies.grunts[0]
	target.pos = game.player.position + Vector2(100, 0)
	game.projectiles.update_fireballs(0.2)
	assert(game.enemies.grunts.size() == 3 and game.player.health.lives == 3)
	game.powers.update_powers(5.0)
	game.projectiles.fireballs.clear()
	game.update_game(0.01)
	assert(game.projectiles.fireballs.is_empty(), "Shooting ends after five seconds")
	# Power-up state resets for the next character or a replay.
	game.powers.activate_power(0)
	game.start_level(1)
	assert(game.powers.power_timers.is_empty() and game.powers.pickups.is_empty() and game.player.health.max_lives == 3)
