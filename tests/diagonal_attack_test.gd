extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		for direction in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			game.start_level(level)
			game.start_wave(0)
			assert(game.player.health.lives == (4 if level == 3 else 3))
			assert(game.player.health.max_lives == (4 if level == 3 else 3))
			game.powers.activate_power(1)
			var aim = direction.normalized()
			game.player.movement.update_player_motion(aim, 0.01)
			game.player.melee.attack()
			var shot = game.projectiles.fireballs[0]
			assert(shot.friendly and shot.velocity.is_equal_approx(aim * 520))
			assert(shot.pos.is_equal_approx(game.player.position + aim * 27))
			assert(game.player.melee.attack_directions()[0].is_equal_approx(aim))
			assert(game.player.melee.in_attack(game.player.position + aim * 80))
			assert(not game.player.melee.in_attack(game.player.position - aim * 80))
			assert(game.player.melee.fireball_in_attack(game.player.position + aim * 60, 7))
			game.player.movement.update_player_motion(-aim, 0.01)
			assert(game.player.melee.attack_directions()[0].is_equal_approx(aim))
			game.powers.activate_power(0)
			assert(game.player.melee.attack_directions() == game.Rules.CARDINALS)
	game.queue_free()
	await create_timer(0.25).timeout
	print("PASS: all diagonal slash/boom directions, hit/parry alignment, swing lock, four-direction power")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
