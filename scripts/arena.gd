extends "res://scripts/game_component.gd"

func _draw() -> void:
	if game == null:
		return
	var tint: Color = Rules.LEVELS[game.level].ground_tint
	if game.wave == Rules.BOSS_WAVE:
		tint = tint.lerp(Color(0.85, 0.30, 0.28), 0.42)
	for y in range(ceili(Rules.ARENA.size.y / Rules.TILE_SIZE)):
		for x in range(ceili(Rules.ARENA.size.x / Rules.TILE_SIZE)):
			var rect = Rect2(x * Rules.TILE_SIZE, y * Rules.TILE_SIZE, Rules.TILE_SIZE, Rules.TILE_SIZE)
			draw_texture_rect(game.assets.grass_frames[game.level], rect, false, tint)
	if game.wave == Rules.BOSS_WAVE:
		draw_rect(Rules.ARENA, Color(0.55, 0.035, 0.025, 0.24))
