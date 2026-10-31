extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func press(game, code: int) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_key_input(event)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for level in range(4):
		game.start_wave_test(level)
		game.player.health.lose_all()
		game._process(2)
		assert(game.state == "gameover" and game.game_over_choice == 0)
		press(game, KEY_ENTER)
		assert(game.level == level and game.state == "intro" and game.elapsed == 0)
		assert(game.player.health.lives == (4 if level == 3 else 3))
		game.start_wave(0)
		game.player.health.lose_all()
		game._process(2)
		var down = InputEventJoypadButton.new()
		down.button_index = JOY_BUTTON_DPAD_DOWN
		down.pressed = true
		game.controls._unhandled_input(down)
		assert(game.game_over_choice == 1)
		var confirm = InputEventJoypadButton.new()
		confirm.button_index = JOY_BUTTON_A
		confirm.pressed = true
		game.controls._unhandled_input(confirm)
		assert(game.level == 0 and game.state == "intro")
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: retry current level, fresh health/timer, start over and controller selection")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
