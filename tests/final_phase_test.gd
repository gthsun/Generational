extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_boss_test(3)
	var boss = game.enemies.grunts[0]
	assert(boss.hp == 24 and boss.phase.health_per_phase() == 7)
	for health in [17, 10, 3]:
		boss.hp = health
		boss.tick(0.01)
		assert(boss.phase.jump > 0 and boss.phase.current_phase_health() == (3 if health == 3 else 7))
		boss.tick(1.2)
	assert(boss.phase.phase_four and boss.pos == game.Rules.ARENA.get_center())
	for cycle in range(2):
		game.projectiles.fireballs.clear()
		boss.final_phase.tick(10)
		assert(game.projectiles.fireballs.size() >= 500)
		for i in range(4):
			var a = game.projectiles.fireballs[i].velocity.normalized()
			var b = game.projectiles.fireballs[(i + 1) % 4].velocity.normalized()
			assert(absf(a.dot(b)) < 0.001)
		var red = game.projectiles.fireballs[-1]
		assert(red.special_color == Color("ff2424"))
		assert(boss.final_phase.elapsed == 10)
		game.projectiles.fireballs.clear()
		boss.final_phase.tick(3)
		assert(game.projectiles.fireballs.size() >= 400)
		var pink = game.projectiles.fireballs[-1]
		assert(pink.special_color == Color("ff65cf") and pink.size < red.size)
		assert(pink.velocity.length() > red.velocity.length())
		assert(boss.final_phase.elapsed == 0)
	game.projectiles.fireballs.clear()
	boss.tick(0.05)
	assert(game.projectiles.fireballs[0].special_color == Color("ff2424"))
	assert(not boss.maneuver.active and boss.pos == game.Rules.ARENA.get_center())
	for voice in game.victory_audio.players:
		assert(voice.volume_db == 0)
	for hit in range(3):
		boss.hp -= 1
		boss.check_defeated()
		if hit < 2:
			assert(game.enemies.grunts.size() == 1)
	assert(game.enemies.grunts.is_empty())
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: 24 health, 7/7/7/3-heart phases, center jump, repeating 10s red/3s pink spirals, defeat volume")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
