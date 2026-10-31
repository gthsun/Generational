extends SceneTree
# A reproducible melee-only reference, not a substitute for human playtesting.
# Infinite health isolates clear time from deaths; power drops are disabled.
class ReferenceMovement extends "res://scripts/player_movement.gd":
	func tick_input(dt: float) -> void:
		if game.enemies.grunts.is_empty():
			return
		var target = game.enemies.grunts[0]
		for enemy in game.enemies.grunts:
			if actor.position.distance_squared_to(enemy.pos) < actor.position.distance_squared_to(target.pos):
				target = enemy
		var offset = target.pos - actor.position
		update_player_motion(offset.normalized() if offset.length() > 65 else Vector2.ZERO, dt)
		if actor.melee.attack_timer <= 0:
			facing = Rules.cardinal_direction(offset.normalized(), facing)
		if offset.length() < 86:
			actor.melee.attack_requested = true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.get_node("World/Actors/Player/Movement").set_script(ReferenceMovement)
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		var times: Array[float] = []
		for seed_value in range(12):
			game.rng.seed = seed_value + 100
			game.start_level(level)
			game.start_wave(0)
			game.player.health.lives = 1000
			game.powers.power_spawn_timer = 10000
			var total := 0.0
			for tick in range(20000):
				if game.state == "won":
					break
				if game.state == "playing":
					total += 0.02
					game.update_game(0.02)
				else:
					game._process(1.0)
			assert(game.state == "won")
			times.append(total)
		times.sort()
		print("Level ", level + 1, " melee-only reference seconds: min=", snappedf(times[0], 0.1), " median=", snappedf(times[6], 0.1), " max=", snappedf(times[-1], 0.1))
	quit()
