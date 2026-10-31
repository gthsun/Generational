extends "res://scripts/game_component.gd"

const PixelFont = preload("res://scripts/pixel_font.gd")
const GLYPHS = PixelFont.GLYPHS

func clock_frame() -> int:
	# 00 is full; 01–15 progressively empty; 16 is reached exactly at the deadline.
	return mini(int(game.elapsed / Rules.LEVELS[game.level].time_limit * (game.assets.clock_frames.size() - 1)), game.assets.clock_frames.size() - 1)

func label_at(text: String, pos: Vector2, size: int, color = Color.WHITE) -> void:
	var scale = maxi(1, size / 8)
	PixelFont.draw(self, text, pos - Vector2(0, 7 * scale), scale, color)

func centered(text: String, y: float, size: int, color = Color.WHITE) -> void:
	var scale = maxi(1, size / 8)
	while PixelFont.width(text, scale) > 1000 and scale > 1:
		scale -= 1
	PixelFont.draw(self, text, Vector2((1120 - PixelFont.width(text, scale)) / 2, y - 7 * scale), scale, color)

func pixel_text(text: String, y: float, pixel_size: int, color: Color) -> void:
	PixelFont.draw(self, text, Vector2((1120 - PixelFont.width(text, pixel_size)) / 2, y), pixel_size, color)

func overlay(title: String, hint = "") -> void:
	draw_rect(Rules.ARENA, Color(0.025, 0.035, 0.045, 0.87))
	pixel_text(title, 337, 8, Color("f8e8bc"))
	if not hint.is_empty():
		centered(hint, 460, 22, Color("adbaae"))

func draw_boss_intro() -> void:
	draw_rect(Rules.ARENA, Color(0.10, 0.025, 0.035, 0.90))
	var definition = Rules.LEVELS[game.level]
	pixel_text(definition.boss_title.to_upper(), 300, 3, Color("e4aaa0"))
	pixel_text(definition.boss_name.to_upper(), 365, 6, Color("f8e8bc"))

func story_lines() -> PackedStringArray:
	var lines = PackedStringArray()
	var line = ""
	for word in Rules.LEVELS[game.level].story.split(" "):
		var candidate: String = word if line.is_empty() else line + " " + word
		if PixelFont.width(candidate, 3) > 800:
			lines.append(line)
			line = word
		else:
			line = candidate
	lines.append(line)
	return lines

func draw_story() -> void:
	draw_rect(Rules.ARENA, Color("101923"))
	pixel_text("LEVEL %d" % (game.level + 1), 82, 3, Color("adbaae"))
	pixel_text(Rules.LEVELS[game.level].year, 132, 8, Color("f8e8bc"))
	sprite(game.assets.player_frames[game.level * 13], Vector2(560, 255), 88)
	var lines = story_lines()
	for i in range(lines.size()):
		label_at(lines[i], Vector2(160, 350 + i * 35), 24, Color("eee6d3"))
	centered(game.controls.confirm_hint() + " TO CONTINUE", 675, 22, Color("adbaae"))
func draw_ending() -> void:
	draw_rect(Rules.ARENA, Color("101923"))
	pixel_text("PASS IT ON", 120, 7, Color("f8e8bc"))
	for generation in range(4):
		sprite(game.assets.player_frames[generation * 13], Vector2(350 + generation * 140, 285), 100)
	centered("The Eclipse Corporation was shut down for good.", 410, 16, Color("eee6d3"))
	centered("Never again would it steal the Braunerkopf family's flame.", 450, 16, Color("eee6d3"))
	centered("Passed from one generation to the next,", 510, 16, Color("eee6d3"))
	centered("the flame could finally burn in peace.", 550, 16, Color("eee6d3"))
	pixel_text("THE END", 615, 4, Color("f8e8bc"))
	centered(game.controls.confirm_hint() + " TO REPLAY", 700, 22, Color("adbaae"))

func _draw() -> void:
	if game == null:
		return
	if game.state == "title":
		draw_rect(Rules.ARENA, Color("101923"))
		var title_size = game.assets.title_card.get_size() * minf(960.0 / game.assets.title_card.get_width(), 300.0 / game.assets.title_card.get_height())
		draw_texture_rect(game.assets.title_card, Rect2(Vector2(560, 320) - title_size / 2, title_size), false)
		centered(game.controls.confirm_hint() + " TO START", 530, 24, Color("f8e8bc"))
		centered(game.controls.controls_hint(), 610, 20, Color("adbaae"))
		centered("- LEVEL %d -" % (game.selected_level + 1), 680, 24, Color("f8e8bc"))
		var level_hint = "STICK / D-PAD LEFT OR RIGHT" if game.controls.controller_active else "LEFT / RIGHT ARROWS"
		centered(level_hint + " TO SELECT LEVEL", 715, 16, Color("adbaae"))
		return
	var power_slot = 0
	for kind in game.powers.power_timers:
		var clock_pos = Vector2(42 + power_slot * 76, 42)
		sprite(game.assets.clock_frames[game.powers.power_clock_frame(kind)], clock_pos, 52, false, Color("ff6464"))
		sprite(game.assets.power_frames[kind], clock_pos + Vector2(0, 43), 28)
		power_slot += 1
	sprite(game.assets.clock_frames[clock_frame()], Vector2(1072, 48), 64)
	if game.state == "won":
		draw_ending()
	elif game.state == "intro":
		draw_story()
	elif game.state == "wave_intro":
		if game.wave == Rules.BOSS_WAVE:
			draw_boss_intro()
		else:
			overlay("WAVE %d" % (game.wave + 1))
	elif game.state == "gameover":
		overlay("GAME OVER")
		for index in range(2):
			var selected = game.game_over_choice == index
			var text = "RETRY LEVEL %d" % (game.level + 1) if index == 0 else "START OVER"
			centered(("- " if selected else "") + text + (" -" if selected else ""), 455 + index * 50, 24, Color("f8e8bc") if selected else Color("adbaae"))
		var navigation = "STICK / D-PAD" if game.controls.controller_active else "ARROW KEYS"
		centered(navigation + " TO CHOOSE", 585, 16, Color("adbaae"))
		centered(game.controls.confirm_hint() + " TO CONFIRM", 620, 16, Color("adbaae"))
	elif game.paused:
		overlay("PAUSED", game.controls.pause_hint() + " TO RESUME")
		centered(game.controls.controls_hint(), 535, 20, Color("adbaae"))
