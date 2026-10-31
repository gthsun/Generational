extends "res://scripts/game_component.gd"
func _ready() -> void:
	var controller = load("res://scenes/main.tscn").instantiate()
	add_child(controller)
	controller.set_process(false)
	controller.hide()
	setup(controller)

func _draw() -> void:
	draw_rect(Rules.ARENA, Color("172621"))
	for row in range(2):
		game.level = 0 if row == 0 else 2
		for col in range(4):
			var direction = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][col]
			var pos = Vector2(170 + col * 260, 230 + row * 320)
			game.player.melee.swing_duration = Rules.LEVELS[game.level].attack_duration
			game.player.melee.attack_timer = game.player.melee.swing_duration * 0.5
			sprite(game.assets.player_frames[Rules.frame_index(game.level, direction, false, true)], pos, 88, direction.x < 0)
			draw_hearts(pos + Vector2(0, -42), 2, 3, 17)
			var distance = 54.0 if row == 1 else 38.0
			var angle = 0.0 if direction == Vector2.LEFT else direction.angle()
			draw_set_transform(pos + direction * distance, angle, Vector2(-1, 1) if direction == Vector2.LEFT else Vector2.ONE)
			draw_texture_rect(game.player.melee.attack_effect_frames()[game.player.melee.attack_effect_frame()], Rect2(-72, -72, 144, 144), false)
			draw_set_transform(Vector2.ZERO)
