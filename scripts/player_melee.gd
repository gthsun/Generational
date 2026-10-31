extends "res://scripts/actor_component.gd"
signal attacked

var swing_direction := Vector2.DOWN
var swing_duration := 0.24
var swing_scale := 1.0
var swing_id := 0
var attack_requested := false
var attack_timer := 0.0
var attack_cooldown := 0.0

func attack() -> void:
	if attack_cooldown > 0.0:
		return
	swing_direction = actor.movement.input_direction if not actor.movement.input_direction.is_zero_approx() else actor.movement.facing
	swing_duration = Rules.LEVELS[game.level].attack_duration * (0.6 if game.powers.power_active(3) else 1.0)
	swing_scale = 1.8 if game.powers.power_active(3) else 1.0
	attack_timer = swing_duration
	attack_cooldown = Rules.LEVELS[game.level].attack_cooldown * (0.5 if game.powers.power_active(3) else 1.0)
	swing_id += 1
	game.sounds.play_effect("boom" if game.level == 2 else "slash")
	attacked.emit()
	apply_attack_hits()

func in_attack(pos: Vector2, radius = 0.0) -> bool:
	var offset = pos - actor.position
	if offset.length() > 88.0 * swing_scale + radius:
		return false
	for direction in attack_directions():
		if offset.length() < 22.0 or direction.dot(offset.normalized()) >= 0.25:
			return true
	return false

func apply_attack_hits() -> void:
	if attack_timer <= 0:
		return
	for g in game.enemies.grunts:
		if g.phase.jump <= 0 and g.last_swing != swing_id and in_attack(g.pos, g.radius - 15.0):
			g.last_swing = swing_id
			g.hp -= 1
			g.flash = 0.15
			var push: Vector2 = (g.pos - actor.position).normalized() if game.powers.power_active(0) else swing_direction
			g.pos = g.movement.clamp_position(g.pos + push * (8.0 if g.boss else 22.0))
	for ball in game.projectiles.fireballs:
		if not ball.get("friendly", false) and ball.get("burst_age", -1.0) < 0 and fireball_in_attack(ball.pos, ball.radius):
			game.projectiles.hit_fireball(ball)
	game.enemies.remove_dead_grunts()

func fireball_in_attack(pos: Vector2, radius: float) -> bool:
	for direction in attack_directions():
		if (pos - actor.position).dot(direction) >= 12.0 and in_attack(pos, radius):
			return true
	return false

func attack_effect_frames() -> Array[Texture2D]:
	return game.assets.boom_frames if game.level == 2 else game.assets.slash_frames

func attack_effect_frame() -> int:
	return mini(int((swing_duration - attack_timer) / swing_duration * attack_effect_frames().size()), attack_effect_frames().size() - 1)

func attack_directions() -> Array:
	return Rules.CARDINALS if game.powers.power_active(0) else [swing_direction]

func handle_attack() -> void:
	if attack_requested or game.controls.attack_held():
		attack()
	attack_requested = false

func reset(index: int) -> void:
	swing_direction = Vector2.DOWN
	attack_requested = false
	attack_timer = 0
	attack_cooldown = 0
	swing_duration = Rules.LEVELS[index].attack_duration
	swing_scale = 1

func tick(dt: float) -> void:
	attack_timer = maxf(0, attack_timer - dt)
	attack_cooldown = maxf(0, attack_cooldown - dt)
