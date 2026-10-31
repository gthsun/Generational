extends "res://scripts/actor_component.gd"
@onready var special_attack = $SpecialAttack

var shoot = 0.0
var attack = 0.0
var burst_left = 0
var burst_timer = 0.0
var burst_direction = Vector2.DOWN
var special = false
var special_left = 0
var special_timer = 0.0
var blue_volleys = 0
var special_after = 3
var warning_total = Rules.SHOT_WARNING
var windup = 0.0
var recover = 0.0
var aim = Vector2.DOWN

func firing_delay() -> float:
	if actor.boss:
		return game.rng.randf_range(0.55, 0.8) if actor.phase.phase_two else game.rng.randf_range(0.8, 1.25)
	return game.rng.randf_range(3.0, 6.5)

func fire() -> void:
	if special:
		special_attack.fire()
		return
	if actor.boss and actor.phase.phase_two:
		blue_volleys += 1
	var direction: Vector2 = aim if windup > 0 else (game.player.position - actor.pos).normalized()
	if game.level == 3:
		# One fixed aim per salvo. The following rounds are emitted by the enemy update.
		burst_direction = direction
		burst_left = 2
		burst_timer = Rules.BURST_INTERVAL
		actor.movement.facing = Rules.cardinal_direction(direction, actor.movement.facing)
		actor.movement.step_left = 0.0
		actor.movement.step_pause = 0.22
		emit_robot_round()
		return
	var shot_speed = 135.0
	var shot_size = 52.0
	var shot_radius = 12.0
	if game.level == 1:
		shot_speed = 360.0
		shot_size = 28.0
		shot_radius = 7.0
	elif game.level == 2:
		shot_speed = Rules.LEVELS[game.level].fast_fireball_speed if game.rng.randf() < 0.5 else 90.0
		shot_size = 100.0
		shot_radius = 25.0
	if actor.boss:
		shot_size *= 2.0 * Rules.LEVELS[game.level].boss_fireball_scale
		shot_radius *= 2.0 * Rules.LEVELS[game.level].boss_fireball_scale
	actor.movement.facing = Rules.cardinal_direction(direction, actor.movement.facing)
	attack = 0.32
	game.sounds.fireball(actor.boss)
	var angles = [-0.32, 0.0, 0.32] if actor.boss and actor.phase.phase_two else [0.0]
	for angle in angles:
		var shot_direction = direction.rotated(angle)
		game.projectiles.fireballs.append({"pos": actor.pos + shot_direction * (actor.radius + shot_radius + 4.0), "velocity": shot_direction * shot_speed,
			"size": shot_size, "radius": shot_radius, "age": 0.0, "boss": actor.boss})

func emit_robot_round() -> void:
	game.sounds.fireball(actor.boss)
	attack = 0.12
	actor.movement.moving = false
	actor.movement.walk_time = 0.0
	var scale_factor = 2.0 if actor.boss else 1.0
	var shot_direction: Vector2 = burst_direction.rotated((1 - burst_left) * 0.18) if actor.boss and actor.phase.phase_two else burst_direction
	game.projectiles.fireballs.append({"pos": actor.pos + shot_direction * (actor.radius + 7.0 * scale_factor + 4.0),
		"velocity": shot_direction * 310.0, "size": 28.0 * scale_factor, "radius": 7.0 * scale_factor, "age": 0.0, "boss": actor.boss})

func cancel_for_jump() -> void:
	windup = 0
	burst_left = 0
	special_left = 0
	attack = 0
	recover = 0
	shoot = 0.6

func is_firing() -> bool:
	return windup > 0 or burst_left > 0 or special_left > 0 or recover > 0

func tick(dt: float) -> bool:
	if update_salvo(dt):
		return true
	if windup > 0:
		if windup <= dt:
			fire()
			windup = 0
			recover = Rules.LEVELS[game.level].boss_firing_recovery if actor.boss else Rules.LEVELS[game.level].firing_recovery
			shoot = firing_delay()
		else:
			windup -= dt
		return true
	if recover > 0:
		recover = maxf(0, recover - dt)
		return true
	shoot -= dt
	if shoot <= 0 and game.enemies.active_shooters() < game.enemies.shooter_limit():
		begin_charge()
		return true
	return false

func update_salvo(dt: float) -> bool:
	if special_left > 0:
		special_timer -= dt
		while special_timer <= 0 and special_left > 0:
			special_attack.emit_round()
			special_left -= 1
			special_timer += 0.45 if special_left > 0 and special_left % 50 == 0 else 0.055
		return true
	if burst_left > 0:
		burst_timer -= dt
		if burst_timer <= 0:
			burst_left -= 1
			emit_robot_round()
			burst_timer += Rules.BURST_INTERVAL
		return true
	return false

func begin_charge() -> void:
	aim = (game.player.position - actor.pos).normalized()
	actor.movement.facing = Rules.cardinal_direction(aim, actor.movement.facing)
	special = actor.boss and actor.phase.phase_two and blue_volleys >= special_after
	warning_total = Rules.LEVELS[game.level].special_warning if special else Rules.SHOT_WARNING
	windup = warning_total
	actor.movement.walk_time = 0

func setup(owner_actor, controller) -> void:
	super.setup(owner_actor, controller)
	special_attack.setup(owner_actor, controller)
