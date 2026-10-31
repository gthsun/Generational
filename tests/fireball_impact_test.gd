extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for fatal in [false, true]:
		game.start_level(0)
		game.start_wave(0)
		game.player.health.invulnerable = 0
		game.player.health.lives = 1 if fatal else 3
		var ball = {"pos": game.player.position - Vector2(80, 0), "velocity": Vector2(800, 0), "age": 0.0, "size": 52.0, "radius": 12.0}
		game.projectiles.fireballs.append(ball)
		game.projectiles.update_fireballs(0.1)
		assert(game.player.health.lives == (0 if fatal else 2))
		assert(game.projectiles.fireballs.size() == 1 and ball.burst_age == 0)
		assert(ball.velocity == Vector2.ZERO and game.projectiles.fireball_frame(ball) == 6)
		for frame in [7, 8]:
			if fatal:
				game._process(0.063)
			else:
				game.projectiles.update_fireballs(0.063)
			assert(game.projectiles.fireball_frame(ball) == frame)
		if fatal:
			game._process(0.063)
		else:
			game.projectiles.update_fireballs(0.063)
		assert(game.projectiles.fireballs.is_empty())
	game.queue_free()
	await create_timer(0.25).timeout
	print("PASS: player impact bursts, all break frames, single damage and fatal-hit completion")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
