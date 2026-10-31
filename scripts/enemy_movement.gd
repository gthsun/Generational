extends "res://scripts/actor_component.gd"

var speed = 60.0
var facing = Vector2.DOWN
var moving = false
var walk_time = 0.0
var step_left = 0.0
var step_pause = 0.0
var step_direction = Vector2.DOWN

func update_robot_motion(dt: float) -> void:
	# Commit to straight, cardinal steps with abrupt stops and 90-degree turns.
	if step_pause > 0:
		step_pause = maxf(0, step_pause - dt)
		return
	if step_left <= 0:
		step_direction = Rules.cardinal_direction((game.player.position - actor.pos).normalized(), facing)
		facing = step_direction
		step_left = 0.42
		walk_time = 0.0
	var step_dt = minf(dt, step_left)
	var previous: Vector2 = actor.pos
	actor.pos = clamp_position(actor.pos + step_direction * (speed + 55.0) * step_dt)
	moving = not actor.pos.is_equal_approx(previous)
	step_left = maxf(0, step_left - dt)
	if step_left <= 0 or not moving:
		step_left = 0.0
		step_pause = 0.22

func clamp_position(point: Vector2) -> Vector2:
	var margin: float = actor.size / 2.0
	return point.clamp(Vector2(margin, margin + 20), Rules.ARENA.end - Vector2.ONE * margin)

func tick(dt: float) -> void:
	var toward: Vector2 = (game.player.position - actor.pos).normalized()
	if actor.weapon.attack <= 0 and actor.pos.distance_to(game.player.position) > 2.0:
		if game.level == 3:
			update_robot_motion(dt)
		else:
			var motion = toward
			# Victorian marksmen keep a modest distance, but cannot outrun the player.
			if game.level == 1:
				var distance: float = actor.pos.distance_to(game.player.position)
				motion = -toward * Rules.LEVELS[game.level].retreat_speed_scale if distance < 150 else (Vector2.ZERO if distance < 230 else toward)
			var next_facing = Rules.cardinal_direction(toward, facing)
			if next_facing != facing:
				walk_time = 0.0
			facing = next_facing
			var previous: Vector2 = actor.pos
			actor.pos = clamp_position(actor.pos + motion * speed * dt)
			moving = not actor.pos.is_equal_approx(previous)
	if moving:
		walk_time += dt
	else:
		walk_time = 0.0
