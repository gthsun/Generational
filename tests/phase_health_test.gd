extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_level(level)
		game.start_wave(4)
		var boss = game.enemies.grunts[0]
		var portion = level + 4
		assert(boss.phase.health_per_phase() == portion)
		for phase_index in range(4 if level == 3 else 3):
			portion = boss.phase.health_per_phase()
			assert(boss.phase.current_phase_health() == portion)
			for hit in range(portion):
				boss.hp -= 1
				assert(boss.phase.current_phase_health() == portion - hit - 1)
				if hit < portion - 1:
					boss.phase.tick(0.01)
					assert(boss.phase.jump == 0)
			if phase_index < (3 if level == 3 else 2):
				boss.phase.tick(0.01)
				assert(boss.phase.jump > 0)
				assert(boss.phase.phase_two)
				assert(boss.phase.phase_three == (phase_index >= 1))
				assert(boss.phase.current_phase_health() == boss.phase.health_per_phase())
				boss.phase.tick(1.2)
		assert(boss.hp == 0 and boss.phase.current_phase_health() == 0)
		boss.check_defeated()
		assert(game.enemies.grunts.is_empty())
	game.queue_free()
	await process_frame
	print("PASS: all four bosses, exact thirds, heart depletion/refill, unchanged total health and death")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
