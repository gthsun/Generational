extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	await create_timer(1).timeout
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_wave_test(level)
		game.wave = 3
		game.enemies.clear()
		game.finish_wave()
		assert(game.wave == 4 and game.state == "wave_intro" and game.state_timer == 3)
		for text in [game.Rules.LEVELS[level].boss_title, game.Rules.LEVELS[level].boss_name]:
			assert(not text.is_empty())
			for letter in text.to_upper():
				assert(game.hud.GLYPHS.has(letter), letter)
		game.refresh_view()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/tmp/boss-intro-%d.png" % level)
		game._process(3)
		assert(game.state == "playing" and game.enemies.grunts[0].boss)
		game.refresh_view()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/tmp/boss-tint-%d.png" % level)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: boss cards, glyphs, three-second transitions and tinted arena captures")
	quit()
