extends "res://scripts/game_component.gd"
var level = 0
var walk_time = 0.0
var font = ThemeDB.fallback_font

func _ready() -> void:
	var controller = load("res://main.tscn").instantiate()
	add_child(controller)
	controller.set_process(false)
	controller.hide()
	setup(controller)

func label_at(text: String, pos: Vector2, size: int) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)

func centered(text: String, y: float, size: int) -> void:
	label_at(text, Vector2((1120 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) / 2, y), size)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1120, 760), Color("101b21"))
	centered("ANIMATION DIRECTION CHECK • ALL FOUR LEVELS", 35, 22)
	var headings := ["DOWN idle", "DOWN walk", "DOWN hit", "RIGHT idle", "RIGHT walk", "RIGHT hit", "LEFT idle", "LEFT walk", "LEFT hit", "UP idle", "UP walk", "UP hit", "DEATH"]
	for col in range(13):
		label_at(headings[col], Vector2(75 + col * 80, 78), 11)
	for row in range(8):
		level = row / 2
		var textures: Array[Texture2D] = game.assets.player_frames if row % 2 == 0 else game.assets.grunt_frames
		label_at("L%d %s" % [level + 1, "Player" if row % 2 == 0 else "Grunt"], Vector2(5, 130 + row * 77), 12)
		for col in range(13):
			var direction: Vector2 = [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP][mini(col / 3, 3)]
			var index: int = level * 13 + 12 if col == 12 else Rules.frame_index(level, direction, col % 3 == 1, col % 3 == 2, walk_time)
			sprite(textures[index], Vector2(110 + col * 80, 123 + row * 77), 74, direction == Vector2.LEFT and col != 12)
			label_at("%02d" % index, Vector2(100 + col * 80, 157 + row * 77), 12)
	centered("Walking phase %d / 4 — checks use the same frame selection and mirroring as gameplay" % (int(walk_time * 9) + 1), 735, 15)
