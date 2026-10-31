extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_level(level)
		for wave in range(5):
			game.start_wave(wave)
			var hp = [12, 15, 18, 24][level] if wave == 4 else ([[1, 1, 1, 1], [2, 2, 2, 2], [2, 2, 2, 2], [3, 3, 3, 3]][level][wave])
			for enemy in game.enemies.grunts:
				assert(enemy.hp == hp and enemy.max_hp == hp)
			assert(game.enemies.shooter_limit() == (3 if level == 3 and wave >= 2 else 2))
		var boss = game.enemies.grunts[0]
		boss.weapon.special = true
		boss.weapon.aim = Vector2.RIGHT
		boss.weapon.fire()
		if level == 1:
			assert(game.projectiles.fireballs[0].velocity.length() < 241)
		if level == 3:
			assert(game.projectiles.fireballs[0].velocity.length() == 300)
			boss.weapon.special_left = 0
			boss.weapon.special = false
			boss.weapon.windup = 0.1
			boss.tick(0.11)
			assert(boss.weapon.recover == 1.0)
		if level == 2:
			boss.weapon.special = false
			game.projectiles.fireballs.clear()
			for shot in range(20):
				boss.weapon.fire()
			for ball in game.projectiles.fireballs:
				assert(ball.velocity.length() < 301)
	print("PASS: all wave health values, boss health, shooter limits, slower projectiles and robot recovery")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
