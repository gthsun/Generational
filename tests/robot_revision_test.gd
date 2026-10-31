extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_boss_test(3)
	var boss = game.enemies.grunts[0]
	boss.pos = Vector2(800, 380)
	game.player.position = Vector2(800, 600)
	boss.weapon.special = true
	boss.weapon.fire()
	assert(game.projectiles.fireballs[-1].velocity.normalized().is_equal_approx(Vector2.DOWN))
	for i in range(149):
		game.player.position = Vector2(200 if i % 2 == 0 else 1000, 300)
		var delay: float = boss.weapon.special_timer
		boss.weapon.update_salvo(delay + 0.000001)
		assert(game.projectiles.fireballs.size() == i + 2)
		assert(game.projectiles.fireballs[-1].velocity.normalized().is_equal_approx((game.player.position - boss.pos).normalized()))
		if i + 2 in [50, 100]:
			assert(boss.weapon.special_timer > 0.44)
	assert(boss.weapon.special_left == 0)
	for side in [200, 900]:
		boss.pos = Vector2(side, 380)
		game.player.position = boss.pos
		boss.maneuver.begin_attack()
		assert(boss.maneuver.route[0].x == (80 if side < 560 else 1040))
	game.queue_free()
	await create_timer(0.25).timeout
	print("PASS: three aimed red volleys, gaps and boss-side sweep")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
