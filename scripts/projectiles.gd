extends "res://scripts/game_component.gd"

var fireballs: Array[Dictionary] = []

func burst_fireball(ball: Dictionary) -> void:
	if ball.get("unbreakable", false) or ball.get("burst_age", -1.0) >= 0:
		return
	game.sounds.play_effect("fireball_destroyed")
	ball.burst_age = 0.0
	ball.velocity = Vector2.ZERO

func fireball_frame(ball: Dictionary) -> int:
	if ball.get("burst_age", -1.0) >= 0:
		return mini(6 + int(ball.burst_age * Rules.FIRE_FPS), game.assets.fire_frames.size() - 1)
	return int(ball.age * Rules.FIRE_FPS) % 6

func shoot_player() -> void:
	var direction: Vector2 = game.player.melee.swing_direction
	fireballs.append({"pos": game.player.position + direction * 27.0, "velocity": direction * 520.0,
		"size": 20.0, "radius": 5.0, "age": 0.0, "friendly": true})

func update_fireballs(dt: float, real_dt: float = -1.0) -> void:
	for i in range(fireballs.size() - 1, -1, -1):
		var ball = fireballs[i]
		if ball.get("burst_age", -1.0) >= 0:
			ball.burst_age += dt
			if ball.burst_age >= (game.assets.fire_frames.size() - 6) / Rules.FIRE_FPS:
				fireballs.remove_at(i)
			continue
		if ball.get("homing", false):
			ball.age += dt if real_dt < 0 else real_dt
			if ball.age >= 30.0:
				fireballs.remove_at(i)
				continue
		var previous: Vector2 = ball.pos
		advance_ball(ball, dt)
		if not ball.get("homing", false):
			ball.age += dt
		if ball.get("friendly", false):
			if hit_enemy_or_expired(ball, previous):
				fireballs.remove_at(i)
		elif not parry_ball(ball, previous) and hit_player_or_expired(ball, previous):
			fireballs.remove_at(i)

func advance_ball(ball: Dictionary, dt: float) -> void:
	if ball.get("homing", false):
		update_homing(ball, dt)
	elif ball.has("acceleration"):
		ball.velocity = ball.velocity.normalized() * minf(1100, ball.velocity.length() + ball.acceleration * dt)
	ball.pos += ball.velocity * dt
	if ball.get("homing", false):
		# Stay inside the arena without reflecting from walls; steering brings it back.
		ball.pos = ball.pos.clamp(Vector2.ONE * ball.radius, Rules.ARENA.end - Vector2.ONE * ball.radius)

func update_homing(ball: Dictionary, dt: float) -> void:
	if ball.deflect_timer > 0:
		ball.deflect_timer = maxf(0, ball.deflect_timer - dt)
		return
	var desired: Vector2 = (game.player.position - ball.pos).normalized() * 170.0
	ball.velocity = ball.velocity.move_toward(desired, 520.0 * dt)

func hit_fireball(ball: Dictionary) -> void:
	if not ball.get("homing", false):
		burst_fireball(ball)
		return
	var swing: int = game.player.melee.swing_id
	if ball.get("last_parry", -1) == swing:
		return
	ball.last_parry = swing
	var away: Vector2 = (ball.pos - game.player.position).normalized()
	if away.is_zero_approx():
		away = game.player.movement.facing
	ball.velocity = away * 420.0
	ball.deflect_timer = 0.6

func hit_enemy_or_expired(ball: Dictionary, previous: Vector2) -> bool:
	var target: Node2D = null
	var nearest = INF
	for enemy in game.enemies.grunts:
		if enemy.phase.jump > 0:
			continue
		var point = Geometry2D.get_closest_point_to_segment(enemy.pos, previous, ball.pos)
		if point.distance_to(enemy.pos) <= ball.radius + enemy.radius and previous.distance_squared_to(point) < nearest:
			target = enemy
			nearest = previous.distance_squared_to(point)
	if target != null:
		target.hp -= 1
		target.flash = 0.15
		ball.pos = Geometry2D.get_closest_point_to_segment(target.pos, previous, ball.pos)
		burst_fireball(ball)
		game.enemies.remove_dead_grunts()
		return false
	return not Rules.ARENA.grow(30).has_point(ball.pos) or ball.age > 2.5

func parry_ball(ball: Dictionary, previous: Vector2) -> bool:
	if game.player.melee.attack_timer <= 0 or (ball.get("unbreakable", false) and not ball.get("homing", false)):
		return false
	for direction in game.player.melee.attack_directions():
		var swing_point = Geometry2D.get_closest_point_to_segment(game.player.position + direction * 45.0 * game.player.melee.swing_scale, previous, ball.pos)
		if game.player.melee.fireball_in_attack(swing_point, ball.radius):
			if ball.get("homing", false) and ball.get("last_parry", -1) == game.player.melee.swing_id:
				return true
			ball.pos = swing_point
			hit_fireball(ball)
			return true
	return false

func hit_player_or_expired(ball: Dictionary, previous: Vector2) -> bool:
	var closest = Geometry2D.get_closest_point_to_segment(game.player.position, previous, ball.pos)
	if closest.distance_to(game.player.position) < 14 + ball.radius:
		game.player.health.hurt_player()
		if not ball.get("unbreakable", false):
			ball.pos = closest
			burst_fireball(ball)
		return false
	return not Rules.ARENA.grow(110).has_point(ball.pos) or (ball.age > 14 and not ball.get("unbreakable", false))

func add_special_ball(g: Node2D, direction: Vector2, speed: float, size: float, radius: float, color: Color) -> void:
	game.sounds.fireball(true, size)
	var pos: Vector2 = g.pos + direction * (g.radius + radius + 4)
	pos = pos.clamp(Vector2.ONE * radius, Rules.ARENA.end - Vector2.ONE * radius)
	fireballs.append({"pos": pos, "velocity": direction * speed, "size": size, "radius": radius,
		"age": 0.0, "boss": true, "special_color": color})

func refresh() -> void:
	for layer in get_children():
		layer.visible = layer.kind == "normal" or (game.state in ["playing", "dying"] and not game.paused)
		layer.queue_redraw()

func update_death_bursts(dt: float) -> void:
	# Finish impact effects after a fatal hit without moving other projectiles.
	for i in range(fireballs.size() - 1, -1, -1):
		var ball = fireballs[i]
		if ball.get("burst_age", -1.0) >= 0:
			ball.burst_age += dt
			if ball.burst_age >= (game.assets.fire_frames.size() - 6) / Rules.FIRE_FPS:
				fireballs.remove_at(i)
