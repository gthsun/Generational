extends Node2D
@export_enum("normal", "boss", "special", "friendly") var kind: String = "normal"

func _draw() -> void:
	var system = get_parent()
	if system.game == null:
		return
	for ball in system.fireballs:
		if not matches(ball):
			continue
		var texture = system.game.assets.fire_frames[system.fireball_frame(ball)]
		var tint = ball.get("special_color", Color.WHITE) if kind == "special" else Color.WHITE
		draw_texture_rect(texture, Rect2(ball.pos - Vector2.ONE * ball.size / 2, Vector2.ONE * ball.size), false, tint)

func matches(ball: Dictionary) -> bool:
	match kind:
		"normal": return not ball.get("boss", false) and not ball.get("friendly", false)
		"boss": return ball.get("boss", false) and not ball.has("special_color")
		"special": return ball.has("special_color")
		"friendly": return ball.get("friendly", false)
	return false
