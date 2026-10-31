extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const EnemyVisual = preload("res://scripts/enemy_visual.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.rng.seed = 901
	for level in range(4):
		game.start_level(level)
		game.start_wave(2)
		for g in game.enemies.grunts:
			g.weapon.shoot = 0
		for g in game.enemies.grunts:
			g.tick(0.01)
		assert(game.enemies.active_shooters() == (3 if level == 3 else 2) and game.projectiles.fireballs.is_empty())
		var gun = game.enemies.grunts[0]
		var origin: Vector2 = gun.pos
		var aim: Vector2 = gun.weapon.aim
		game.player.position += Vector2(100, 0)
		gun.tick(0.3)
		assert(game.projectiles.fireballs.is_empty() and gun.pos == origin and gun.weapon.aim == aim)
		gun.tick(0.11)
		assert(game.projectiles.fireballs.size() == 1)
		assert(game.projectiles.fireballs[0].velocity.normalized().is_equal_approx(aim))
		for tick in range(100):
			for g in game.enemies.grunts:
				g.tick(0.02)
			assert(game.enemies.active_shooters() <= (3 if level == 3 else 2))
		game.start_wave(0)
		for g in game.enemies.grunts:
			g.weapon.shoot = 0
			g.tick(0.01)
		assert(game.enemies.active_shooters() == 2)
		game.start_wave(4)
		var boss = game.enemies.grunts[0]
		boss.hp = boss.max_hp - boss.phase.health_per_phase()
		boss.weapon.shoot = 0
		boss.tick(0.01)
		assert(boss.phase.phase_two and boss.phase.jump > 0)
		boss.tick(1.3)
		boss.weapon.shoot = 0
		boss.tick(0.01)
		assert(boss.weapon.windup > 0)
		boss.tick(0.41)
		for tick in range(34):
			boss.tick(0.01)
		assert(game.projectiles.fireballs.size() == 3)
		assert(not game.projectiles.fireballs[0].velocity.normalized().is_equal_approx(game.projectiles.fireballs[1].velocity.normalized()))
		assert(boss.weapon.recover > 0)
		var position: Vector2 = boss.pos
		boss.tick(0.1)
		assert(boss.pos == position)
		game.player.melee.attack_cooldown = 0
		game.player.melee.attack()
		assert(game.player.melee.attack_cooldown - game.player.melee.attack_timer >= 0.19)
	game.start_level(1)
	game.start_wave(0)
	var marksman = game.enemies.grunts[0]
	marksman.pos = game.player.position + Vector2(100, 0)
	marksman.weapon.shoot = 10
	var before: float = marksman.pos.distance_to(game.player.position)
	marksman.tick(0.05)
	assert(marksman.pos.distance_to(game.player.position) > before)
	var hearts := [0, 0]
	for health_index in range(2):
		game.player.health.lives = 3 if health_index == 0 else 1
		for i in range(1000):
			game.powers.spawn_power()
			if game.powers.pickups[-1].kind == 2:
				hearts[health_index] += 1
			game.powers.pickups.clear()
	assert(hearts[0] > 150 and hearts[0] < 260)
	assert(hearts[1] > 520 and hearts[1] < 680)
	print("PASS: warning and locked aim, shooter caps, boss phases/recovery, attack gaps, ranged movement, heart weighting ", hearts)
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
