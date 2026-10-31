extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	await create_timer(1).timeout
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_level(level)
		game.start_wave(4)
		var boss = game.enemies.grunts[0]
		boss.pos = Vector2(820, 380)
		game.player.position = Vector2(400, 450)
		game.elapsed = 65
		game.refresh_view()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/tmp/boss_full_health_%d.png" % level)
		boss.phase.phase_two = true
		boss.hp = floori(boss.max_hp - 2 * boss.phase.health_per_phase())
		boss.tick(0.5)
		game.refresh_view()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/tmp/boss_third_jump_%d.png" % level)
		boss.tick(1)
		boss.maneuver.begin_attack()
		boss.maneuver.advance([0.6, 1.5, 0.5, 2.5][level])
		game.refresh_view()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("/tmp/boss_third_attack_%d.png" % level)
	game.queue_free()
	await process_frame
	print("PASS: phase-three fullscreen captures")
	quit()
