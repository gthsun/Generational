extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	await create_timer(1).timeout
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_boss_test(3)
	game.state = "won"
	game.music.stop()
	game.refresh_view()
	await process_frame
	RenderingServer.force_draw()
	assert(root.get_texture().get_image().save_png("/tmp/generational-ending.png") == OK)
	var key = InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	game._unhandled_key_input(key)
	assert(game.state == "intro" and game.level == 0)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: ending render and replay")
	quit()
