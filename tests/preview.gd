extends SceneTree
const Rules = preload("res://scripts/game_rules.gd")
const EnemyVisual = preload("res://scripts/enemy_visual.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.state = "playing"
	game.elapsed = 42
	game.clock = 1
	for i in range(7):
		game.enemies.spawn_grunt()
		game.enemies.grunts[i].pos = Vector2(170 + (i % 4) * 230, 235 + (i / 4) * 310)
		game.enemies.grunts[i].movement.facing = Rules.cardinal_direction((game.player.position - game.enemies.grunts[i].pos).normalized(), Vector2.DOWN)
	game.enemies.grunts[0].weapon.fire()
	game.projectiles.fireballs[0].pos = Vector2(350, 320)
	game.refresh_view()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview.png")
	quit()
