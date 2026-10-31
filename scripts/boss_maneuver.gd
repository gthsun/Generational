extends "res://scripts/actor_component.gd"

var active = false
var landing_frame = false
var cooldown = 0.0
var warning = 0.0
var origin = Vector2.ZERO
var route: Array[Vector2] = []
var durations: Array[float] = []
var segment = 0
var elapsed = 0.0
var segment_from = Vector2.ZERO
var shot_timer = 0.0

func cancel() -> void:
	active = false
	warning = 0
	route.clear()
	durations.clear()

func on_landed() -> void:
	landing_frame = true
	cooldown = 0

func tick(dt: float) -> bool:
	if not actor.boss or not actor.phase.phase_three:
		return false
	if warning > 0:
		warning = maxf(0, warning - dt)
		actor.weapon.windup = warning
		if warning == 0:
			begin_attack()
		return true
	if active:
		advance(dt)
		return true
	cooldown = maxf(0, cooldown - dt)
	if cooldown == 0 and not actor.weapon.is_firing():
		warning = 1.0
		actor.movement.facing = Rules.cardinal_direction(game.player.position - actor.pos, actor.movement.facing)
		actor.weapon.warning_total = warning
		actor.weapon.windup = warning
		return true
	return false

func begin_attack() -> void:
	origin = actor.pos
	route.clear()
	durations.clear()
	var corners: Array[Vector2] = [Vector2(80, 100), Vector2(1040, 100), Vector2(1040, 680), Vector2(80, 680)]
	var nearest = 0
	for i in range(4):
		if origin.distance_squared_to(corners[i]) < origin.distance_squared_to(corners[nearest]):
			nearest = i
	match game.level:
		0:
			add_stop(actor.movement.clamp_position(game.player.position), 1.0)
			add_stop(origin, 1.0)
		1:
			add_stop(corners[nearest], 0.5)
			for i in range(1, 5):
				add_stop(corners[(nearest + i) % 4], 1.0)
			add_stop(origin, 0.5)
		2:
			var travel_time: float = Rules.LEVELS[game.level].boss_corner_travel_time
			for i in range(4):
				add_stop(corners[(nearest + i) % 4], travel_time)
			add_stop(origin, travel_time)
		3:
			var edge = 1040.0 if actor.pos.x >= Rules.ARENA.get_center().x else 80.0
			add_stop(Vector2(edge, 100), 0.5)
			add_stop(Vector2(edge, 680), 4.0)
			add_stop(origin, 0.5)
	segment = 0
	elapsed = 0
	segment_from = origin
	shot_timer = 0
	active = true
	actor.weapon.windup = 0

func add_stop(point: Vector2, duration: float) -> void:
	route.append(point)
	durations.append(duration)

func advance(dt: float) -> void:
	var remaining = dt
	while active and remaining > 0:
		var step = minf(remaining, durations[segment] - elapsed)
		elapsed += step
		remaining -= step
		var direction = route[segment] - segment_from
		if actor.weapon.attack <= 0:
			actor.movement.facing = Rules.cardinal_direction(direction, actor.movement.facing)
		actor.movement.moving = true
		actor.movement.walk_time += step
		actor.pos = segment_from.lerp(route[segment], elapsed / durations[segment])
		shoot_while_moving(step)
		if elapsed >= durations[segment]:
			if game.level == 2 and segment < 4:
				actor.weapon.aim = (game.player.position - actor.pos).normalized()
				actor.movement.facing = Rules.cardinal_direction(actor.weapon.aim, actor.movement.facing)
				actor.weapon.attack = 0.12
				actor.weapon.special_attack.emit_purple()
			segment += 1
			elapsed = 0
			segment_from = actor.pos
			if segment == route.size():
				active = false
				cooldown = 9.0
				actor.weapon.recover = 1.0
				actor.weapon.shoot = 0.6

func shoot_while_moving(dt: float) -> void:
	if game.level != 1 and not (game.level == 3 and segment == 1):
		return
	shot_timer -= dt
	while shot_timer <= 0:
		var direction = (game.player.position - actor.pos).normalized()
		actor.movement.facing = Rules.cardinal_direction(direction, actor.movement.facing)
		if game.level == 1:
			game.projectiles.add_special_ball(actor, direction, 240, 18, 4.5, Color("fff020"))
			shot_timer += 0.16
		else:
			game.projectiles.add_special_ball(actor, direction, 300, 24, 6, Color("ff2424"))
			shot_timer += 0.08
		actor.weapon.attack = 0.12
