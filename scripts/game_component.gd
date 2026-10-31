extends Node2D
## Shared drawing primitives only. Gameplay state belongs to concrete components.
const Rules = preload("res://scripts/game_rules.gd")
var game

func setup(controller) -> void:
	game = controller
	add_to_group("game_views")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func sprite(texture: Texture2D, pos: Vector2, size: float, flip := false, tint := Color.WHITE) -> void:
	# Mirror around the sprite center, keeping its position and collision aligned.
	draw_set_transform(pos, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect(texture, Rect2(-Vector2.ONE * size / 2, Vector2.ONE * size), false, tint)
	draw_set_transform(Vector2.ZERO)

func draw_hearts(pos: Vector2, current: int, maximum: int, size: float) -> void:
	for i in range(maximum):
		var tint := Color.WHITE if i < current else Color(0.20, 0.20, 0.20, 0.65)
		sprite(game.assets.heart, pos + Vector2((i - (maximum - 1) / 2.0) * (size + 2), 0), size, false, tint)

func refresh() -> void:
	queue_redraw()
