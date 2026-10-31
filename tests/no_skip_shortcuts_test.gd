extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for state in ["title", "intro", "playing", "gameover"]:
		game.start_level(1)
		game.state = state
		for modifier in [KEY_B, KEY_W]:
			var held = InputEventKey.new()
			held.physical_keycode = modifier
			held.keycode = modifier
			held.pressed = true
			Input.parse_input_event(held)
			Input.flush_buffered_events()
			for number in [KEY_1, KEY_2, KEY_3, KEY_4]:
				var event = InputEventKey.new()
				event.keycode = number
				event.pressed = true
				game._unhandled_key_input(event)
				assert(game.level == 1 and game.wave == 0 and game.state == state)
			held = held.duplicate()
			held.pressed = false
			Input.parse_input_event(held)
			Input.flush_buffered_events()
	game.queue_free()
	await create_timer(0.5).timeout
	print("PASS: B/W number combinations cannot skip levels or bosses")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
