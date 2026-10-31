extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const EnemyVisual = preload("res://scripts/enemy_visual.gd")
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await create_timer(0.5).timeout
	for level in range(4):
		game.start_level(level)
		game.start_wave(4)
		game.player.health.invulnerable = 0
		game.player.position = Vector2(850, 500)
		var boss = game.enemies.grunts[0]
		boss.pos = Vector2(1000, 440)
		boss.hp = boss.max_hp - boss.phase.health_per_phase()
		boss.tick(0.6)
		game.refresh_view()
		await capture("res://tests/boss_jump_%d.png" % (level + 1))
		boss.tick(0.61)
		boss.pos = Vector2(180, 400)
		boss.weapon.aim = (game.player.position - boss.pos).normalized()
		boss.weapon.special = true
		boss.weapon.fire()
		for i in range(25):
			if boss.weapon.special_left > 0:
				boss.tick(0.02)
			game.projectiles.update_fireballs(0.02)
		game.refresh_view()
		await capture("res://tests/boss_special_%d.png" % (level + 1))
	print("PASS: boss jump and special attack visual captures")
	quit()
