extends "res://scripts/actor_component.gd"
## The final phase alternates a red spiral and a faster pink spiral.
var elapsed = 0.0
var shot_timer = 0.0
var angle = 0.0

func tick(dt: float) -> bool:
	if not actor.phase.phase_four:
		return false
	actor.pos = Rules.ARENA.get_center()
	var remaining = dt
	while remaining > 0:
		var boundary = 10.0 if elapsed < 10 else 13.0
		var step = minf(remaining, boundary - elapsed)
		if elapsed < 13:
			var pink = elapsed >= 10
			shot_timer -= step
			while shot_timer <= 0:
				emit_round(pink)
				shot_timer += 0.03 if pink else 0.08
		elapsed += step
		remaining -= step
		if elapsed >= boundary:
			shot_timer = 0
			if elapsed >= 13:
				elapsed = 0
	return true

func emit_round(pink: bool) -> void:
	var direction = Vector2.RIGHT.rotated(angle)
	angle = fmod(angle + (0.12 if pink else 0.10), TAU)
	actor.movement.facing = Rules.cardinal_direction(direction, actor.movement.facing)
	actor.weapon.attack = 0.12
	for spoke in range(4):
		var shot_direction = direction.rotated(spoke * PI / 2.0)
		if pink:
			game.projectiles.add_special_ball(actor, shot_direction, 480, 18, 4.5, Color("ff65cf"))
		else:
			game.projectiles.add_special_ball(actor, shot_direction, 310, 56, 14, Color("ff2424"))
