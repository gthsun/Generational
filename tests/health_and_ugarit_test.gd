extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_wave_test(level)
		var cap = 4 if level == 3 else 3
		for i in range(10):
			game.powers.activate_power(2)
		assert(game.player.health.lives == cap and game.player.health.max_lives == cap)
		game.player.health.lives = 1
		game.powers.activate_power(2)
		assert(game.player.health.lives == 2)
	game.start_boss_test(2)
	var boss = game.enemies.grunts[0]
	boss.weapon.fire()
	assert(game.projectiles.fireballs[0].size == 160 and game.projectiles.fireballs[0].radius == 40)
	game.projectiles.fireballs.clear()
	boss.weapon.special_attack.emit_purple()
	assert(game.projectiles.fireballs[0].size > 290 and game.projectiles.fireballs[0].size < 300)
	game.projectiles.fireballs.clear()
	boss.maneuver.begin_attack()
	var origin: Vector2 = boss.pos
	boss.maneuver.advance(0.5)
	assert(game.projectiles.fireballs.is_empty())
	boss.maneuver.advance(0.3)
	assert(game.projectiles.fireballs.size() == 1)
	boss.maneuver.advance(3.2)
	assert(game.projectiles.fireballs.size() == 4 and not boss.maneuver.active)
	assert(boss.pos.is_equal_approx(origin))
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: starting-heart caps and healing, smaller Ugarit blue/purple shots, slower four-second corner attack")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
