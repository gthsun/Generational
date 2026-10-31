extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func button(game, index: int) -> void:
	var event = InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = true
	game.controls._input(event)
	game.controls._unhandled_input(event)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var controls = game.controls
	assert(controls.stick_direction(Vector2(0.1, 0)).is_zero_approx())
	assert(controls.stick_direction(Vector2(1, 1)).is_equal_approx(Vector2(1, 1).normalized()))
	assert(controls.button_labels("Xbox Wireless Controller") == ["A", "X", "MENU"])
	assert(controls.button_labels("DualSense Wireless Controller") == ["CROSS", "SQUARE", "OPTIONS"])
	assert(controls.button_labels("Nintendo Switch Pro Controller") == ["B", "Y", "PLUS"])
	button(game, JOY_BUTTON_A)
	assert(game.state == "intro" and controls.controller_active)
	button(game, JOY_BUTTON_A)
	assert(game.state == "playing")
	button(game, JOY_BUTTON_X)
	assert(game.player.melee.attack_requested)
	game.player.melee.handle_attack()
	assert(game.player.melee.attack_timer > 0)
	button(game, JOY_BUTTON_START)
	assert(game.paused)
	button(game, JOY_BUTTON_START)
	assert(not game.paused)
	controls.connection_changed(0, false)
	assert(game.paused and not controls.controller_active)
	var key = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	controls._input(key)
	game._unhandled_key_input(key)
	assert(not game.paused and controls.confirm_hint() == "ENTER")
	game.state = "won"
	button(game, JOY_BUTTON_A)
	assert(game.state == "intro" and game.level == 0)
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: controller navigation, attack, pause, disconnect safety, keyboard switching, brand prompts and stick deadzone")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
