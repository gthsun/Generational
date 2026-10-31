extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const EnemyVisual = preload("res://scripts/enemy_visual.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		for start_x in [200, 900]:
			game.start_level(level)
			game.start_wave(4)
			var boss = game.enemies.grunts[0]
			boss.pos = Vector2(start_x, 400)
			boss.hp = boss.max_hp - boss.phase.health_per_phase()
			boss.tick(0.01)
			assert(boss.phase.phase_two and boss.phase.jump > 0 and boss.weapon.windup == 0)
			game.player.position = boss.pos
			var hp: int = boss.hp
			game.player.melee.attack_cooldown = 0
			game.player.melee.attack()
			assert(boss.hp == hp, "Airborne bosses cannot be hit")
			boss.tick(1.3)
			assert(boss.phase.jump == 0 and boss.pos.x == (1050 if start_x < 560 else 70))
			boss.tick(0.01)
			assert(boss.phase.jump == 0, "Only jump once")
		game.player.position = Vector2(560, 400)
		game.projectiles.fireballs.clear()
		game.player.melee.attack_timer = 0
		boss_setup(game)
		var boss = game.enemies.grunts[0]
		boss.tick(0.01)
		assert(boss.weapon.special and boss.weapon.windup == (1.0 if level in [1, 3] else 0.8))
		boss.tick(boss.weapon.warning_total + 0.01)
		for tick in range(500):
			if boss.weapon.special_left <= 0:
				break
			boss.tick(0.02)
		assert(game.projectiles.fireballs.size() == [1, 20, 1, 150][level])
		assert(boss.weapon.blue_volleys == 0 and boss.weapon.special_after >= 3)
		if level == 0:
			var ball = game.projectiles.fireballs[0]
			game.projectiles.burst_fireball(ball)
			assert(not ball.has("burst_age"))
			assert(ball.homing)
			game.player.position = Vector2(560, 400)
			game.player.movement.facing = Vector2.RIGHT
			ball.pos = game.player.position + Vector2(60, 0)
			ball.velocity = Vector2(-170, 0)
			game.player.melee.attack_cooldown = 0
			game.player.melee.attack()
			assert(ball.velocity.x == 420 and ball.deflect_timer == 0.6)
			assert(not ball.has("burst_age"))
			ball.deflect_timer = 0.3
			game.player.melee.apply_attack_hits()
			assert(ball.deflect_timer == 0.3, "One deflection per swing")
			game.player.melee.attack_timer = 0
			for tick in range(60):
				game.projectiles.update_fireballs(0.025)
			assert(ball.velocity.x < 0, "Turns back toward player after knockback")
			ball.pos = game.player.position + Vector2(60, 0)
			game.player.melee.attack_cooldown = 0
			game.player.melee.attack()
			assert(ball.velocity.x == 420, "A new swing can deflect it again")
			game.player.melee.attack_timer = 0
			ball.pos = Vector2(1103, 100)
			game.projectiles.update_fireballs(0.05)
			assert(ball.pos.x <= 1104 and ball.velocity.x > 0, "Walls constrain it without a bounce")
			game.paused = true
			var age: float = ball.age
			game._process(2)
			assert(ball.age == age)
			game.paused = false
			ball.age = 29.9
			game.projectiles.update_fireballs(0.02, 0.11)
			assert(game.projectiles.fireballs.is_empty(), "Expires after 30 active seconds even on slow frames")
		elif level == 2:
			var ball = game.projectiles.fireballs[0]
			assert(ball.size > 290 and ball.size < 300)
			var speed: float = ball.velocity.length()
			game.player.position = Vector2(560, 700)
			game.projectiles.update_fireballs(0.05)
			assert(ball.velocity.length() > speed * 2)
			game.projectiles.burst_fireball(ball)
			assert(ball.burst_age == 0)
		else:
			for ball in game.projectiles.fireballs:
				game.projectiles.burst_fireball(ball)
				assert(ball.burst_age == 0)
	print("PASS: opposite-edge jumps, airborne immunity, special cadence/warnings, 1/20/1/150 shots, homing/deflection/expiry, acceleration and destruction")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
func boss_setup(game) -> void:
	var boss = game.enemies.grunts[0]
	boss.pos = Vector2(100, 400)
	boss.weapon.recover = 0
	boss.weapon.shoot = 0
	boss.weapon.blue_volleys = boss.weapon.special_after
