extends "res://scripts/game_component.gd"

func _draw() -> void:
	if game != null and game.player.melee.attack_timer > 0:
		# Render above the actors; melee timing remains owned by the player.
		for direction in game.player.melee.attack_directions():
			var distance = (54.0 if game.level == 2 else 38.0) * game.player.melee.swing_scale
			var angle = (-direction).angle() if direction.x < 0 else direction.angle()
			var scale_value = Vector2(-1, 1) if direction.x < 0 else Vector2.ONE
			draw_set_transform(game.player.position + direction * distance, angle, scale_value * game.player.melee.swing_scale)
			draw_texture_rect(game.player.melee.attack_effect_frames()[game.player.melee.attack_effect_frame()], Rect2(-72, -72, 144, 144), false)
		draw_set_transform(Vector2.ZERO)
