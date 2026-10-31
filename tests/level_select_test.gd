extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func press(game, code: int) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_key_input(event)
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	assert(game.selected_level == 0)
	press(game, KEY_LEFT)
	assert(game.selected_level == 3)
	press(game, KEY_RIGHT)
	assert(game.selected_level == 0)
	for level in range(4):
		game.state = "title"
		game.selected_level = level
		press(game, KEY_ENTER)
		assert(game.state == "intro" and game.level == level)
		assert(game.player.health.lives == (4 if level == 3 else 3))
		press(game, KEY_ENTER)
		assert(game.wave == 0 and game.state == "playing")
	game.state = "title"
	game.selected_level = 0
	var axis = InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0.9
	game.controls._unhandled_input(axis)
	game.controls._unhandled_input(axis)
	assert(game.selected_level == 1)
	axis.axis_value = 0
	game.controls._unhandled_input(axis)
	axis.axis_value = 0.9
	game.controls._unhandled_input(axis)
	assert(game.selected_level == 2)
	var button = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_DPAD_RIGHT
	button.pressed = true
	game.controls._unhandled_input(button)
	assert(game.selected_level == 3)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: level selection, wraparound, stories, starting health and controller navigation")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
