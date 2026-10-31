extends "res://scripts/actor_component.gd"

var facing := Vector2.DOWN
var input_direction := Vector2.ZERO
var moving := false
var walk_time := 0.0

func update_player_motion(direction: Vector2, dt: float) -> void:
	# Finish a swing in one fixed direction before moving or starting another swing.
	if actor.melee.attack_timer > 0:
		moving = false
		walk_time = 0.0
		return
	input_direction = direction.normalized()
	var next_facing = Rules.cardinal_direction(direction, facing)
	var next_pos = clamp_to_arena(actor.position + direction * Rules.PLAYER_SPEED * dt)
	var will_move = not next_pos.is_equal_approx(actor.position)
	if not moving or not will_move or next_facing != facing:
		walk_time = 0.0
	else:
		walk_time += dt
	facing = next_facing
	moving = will_move
	var previous = actor.position
	actor.position = next_pos
	actor.footsteps.moved(previous, dt, false)

func clamp_to_arena(pos: Vector2) -> Vector2:
	return pos.clamp(Rules.ARENA.position + Vector2(36, 60), Rules.ARENA.end - Vector2(36, 36))

func reset() -> void:
	input_direction = Vector2.ZERO
	facing = Vector2.DOWN
	moving = false
	walk_time = 0

func tick_input(dt: float) -> void:
	update_player_motion(game.controls.movement(), dt)
