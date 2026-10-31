extends Node
## Godot's mapped joypad buttons use physical positions across controller brands.
const DEADZONE = 0.22
var device = -1
var controller_active = false
var game
var menu_axis_held = false

func _ready() -> void:
	game = get_parent()
	Input.joy_connection_changed.connect(connection_changed)
	var connected = Input.get_connected_joypads()
	if not connected.is_empty():
		device = connected[0]
		controller_active = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		controller_active = false
	elif event is InputEventJoypadButton and event.pressed:
		device = event.device
		controller_active = true
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] and absf(event.axis_value) > DEADZONE:
		device = event.device
		controller_active = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and ((game.state == "title" and event.axis == JOY_AXIS_LEFT_X) or (game.state == "gameover" and event.axis == JOY_AXIS_LEFT_Y)):
		if absf(event.axis_value) < 0.3:
			menu_axis_held = false
		elif absf(event.axis_value) > 0.6 and not menu_axis_held:
			menu_axis_held = true
			if game.state == "title":
				forward_key(KEY_RIGHT if event.axis_value > 0 else KEY_LEFT)
			else:
				forward_key(KEY_DOWN if event.axis_value > 0 else KEY_UP)
		return
	if not event is InputEventJoypadButton or not event.pressed:
		return
	var key = 0
	match event.button_index:
		JOY_BUTTON_A: key = KEY_ENTER
		JOY_BUTTON_X: key = KEY_X
		JOY_BUTTON_START: key = KEY_ESCAPE
		JOY_BUTTON_DPAD_LEFT: key = KEY_LEFT
		JOY_BUTTON_DPAD_RIGHT: key = KEY_RIGHT
		JOY_BUTTON_DPAD_UP: key = KEY_UP
		JOY_BUTTON_DPAD_DOWN: key = KEY_DOWN
	if key == 0:
		return
	forward_key(key)

func forward_key(key: int) -> void:
	var action = InputEventKey.new()
	action.keycode = key
	action.pressed = true
	game._unhandled_key_input(action)
	get_viewport().set_input_as_handled()

func connection_changed(id: int, connected: bool) -> void:
	if connected and device < 0:
		device = id
		controller_active = true
	elif not connected and id == device:
		device = -1
		controller_active = false
		if game.state == "playing":
			game.paused = true

func movement() -> Vector2:
	if not controller_active or device < 0:
		return Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))).normalized()
	var pad = Vector2(float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)), float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)))
	if not pad.is_zero_approx():
		return pad.normalized()
	return stick_direction(Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)))

static func stick_direction(raw: Vector2) -> Vector2:
	if raw.length() <= DEADZONE:
		return Vector2.ZERO
	return raw.normalized() * clampf((raw.length() - DEADZONE) / (1.0 - DEADZONE), 0, 1)

func attack_held() -> bool:
	return Input.is_joy_button_pressed(device, JOY_BUTTON_X) if controller_active and device >= 0 else Input.is_physical_key_pressed(KEY_X)

static func button_labels(controller_name: String) -> Array:
	var name_lower = controller_name.to_lower()
	if "playstation" in name_lower or "dualshock" in name_lower or "dualsense" in name_lower or "ps4" in name_lower or "ps5" in name_lower:
		return ["CROSS", "SQUARE", "OPTIONS"]
	if "nintendo" in name_lower or "switch" in name_lower or "joy-con" in name_lower:
		return ["B", "Y", "PLUS"]
	if "xbox" in name_lower or "xinput" in name_lower:
		return ["A", "X", "MENU"]
	return ["BOTTOM BUTTON", "LEFT BUTTON", "START"]

func labels() -> Array:
	return button_labels(Input.get_joy_name(device)) if controller_active else ["ENTER", "X", "ESC"]

func confirm_hint() -> String:
	return labels()[0]

func pause_hint() -> String:
	return labels()[2]

func controls_hint() -> String:
	var move = "LEFT STICK / D-PAD" if controller_active else "ARROW KEYS"
	return "%s: MOVE    %s: ATTACK    %s: PAUSE" % [move, labels()[1], labels()[2]]
