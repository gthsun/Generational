extends "res://scripts/game_component.gd"
var actor

func bind(owner_actor, controller) -> void:
	actor = owner_actor
	setup(controller)

static func charge_frame(remaining: float) -> int:
	return clampi(1 + int((1.0 - remaining / Rules.SHOT_WARNING) * 4), 1, 4)

func _draw() -> void:
	if game == null:
		return
	var render_pos = Vector2.ZERO
	if actor.phase.jump <= 0:
		draw_set_transform(Vector2(0, actor.size * 0.25), 0, Vector2(1, 0.32))
		draw_circle(Vector2.ZERO, actor.size * 0.25, Color(0.02, 0.05, 0.04, 0.3))
		draw_set_transform(Vector2.ZERO)
	else:
		var airborne_frame = Rules.frame_index(game.level, actor.movement.facing, false, false)
		draw_set_transform(Vector2(0, 20), 0, Vector2(-1 if actor.movement.facing.x < 0 else 1, -0.65))
		for sy in range(-2, 3):
			for sx in range(-2, 3):
				draw_texture_rect(game.assets.boss_frames[airborne_frame], Rect2(-Vector2.ONE * actor.size / 2 + Vector2(sx, sy) * 2, Vector2.ONE * actor.size), false, Color(0, 0, 0, 0.025))
		draw_set_transform(Vector2.ZERO)
		render_pos.y -= sin(PI * (1.0 - actor.phase.jump / 1.2)) * minf(160, actor.position.y - 55)
	var textures = game.assets.boss_frames if actor.boss else game.assets.grunt_frames
	sprite(textures[Rules.frame_index(game.level, actor.movement.facing, actor.movement.moving, actor.weapon.attack > 0 or actor.weapon.windup > 0, actor.movement.walk_time)], render_pos, actor.size, actor.movement.facing.x < 0, Color(2, 1.4, 1.4) if actor.flash > 0 else Color.WHITE)
	if actor.weapon.windup > 0:
		var bar_pos = (actor.position + render_pos + Vector2(0, actor.size * 0.41)).clamp(Vector2(16, 4), Rules.ARENA.end - Vector2(16, 4)) - actor.position
		draw_texture_rect(game.assets.firebar_frames[charge_frame(actor.weapon.windup * Rules.SHOT_WARNING / actor.weapon.warning_total)], Rect2(bar_pos - Vector2(16, 4), Vector2(32, 8)), false, Color(1, 1, 1, 0.7))
	if actor.boss:
		draw_boss_hearts(render_pos)
	else:
		draw_hearts(render_pos + Vector2(0, -40), actor.hp, actor.max_hp, 13)

func draw_boss_hearts(render_pos: Vector2) -> void:
	var count: int = actor.phase.health_per_phase()
	var top: Vector2 = actor.position + render_pos + Vector2(0, -actor.size * 0.4 - 12)
	top = top.clamp(Vector2(48, 10), Rules.ARENA.end - Vector2(48, 48)) - actor.position
	draw_hearts(top, actor.phase.current_phase_health(), count, 10)
