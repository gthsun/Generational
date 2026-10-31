extends "res://scripts/game_component.gd"
@onready var footsteps = $Footsteps
@onready var movement = $Movement
@onready var health = $Health
@onready var melee = $Melee

func setup(controller) -> void:
	super.setup(controller)
	for component in [movement, health, melee, footsteps]:
		component.setup(self, controller)
	add_to_group("players")

func reset(index: int) -> void:
	position = Rules.ARENA.get_center()
	footsteps.reset()
	health.reset()
	if index == 3:
		health.lives = 4
		health.max_lives = 4
	movement.reset()
	melee.reset(index)

func tick_input(dt: float) -> void:
	health.tick(dt)
	melee.tick(dt)
	movement.tick_input(dt)

func forcefield_frame() -> int:
	var age: float = Rules.POWER_SECONDS - game.powers.power_timers.get(4, Rules.POWER_SECONDS)
	return [0, 1, 2, 1][int(age * 8.0) % 4]

func _draw() -> void:
	if game == null:
		return
	draw_set_transform(Vector2(0, 22), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 22, Color(0.02, 0.05, 0.04, 0.3))
	draw_set_transform(Vector2.ZERO)
	var dead = game.state in ["dying", "gameover"]
	var index = game.level * 13 + 12 if dead else Rules.frame_index(game.level, movement.facing, movement.moving, melee.attack_timer > 0, movement.walk_time)
	var tint = Color(1, 1, 1, 0.35) if health.invulnerable > 0 and int(game.clock * 16) % 2 == 0 and not dead else Color.WHITE
	sprite(game.assets.player_frames[index], Vector2.ZERO, 88, movement.facing.x < 0 and not dead, tint)
	if game.powers.power_active(4) and not dead:
		sprite(game.assets.forcefield_frames[forcefield_frame()], Vector2.ZERO, 100, false, Color(1, 1, 1, 0.4))
	if health.lives > 0:
		draw_hearts(Vector2(0, -40), health.lives, health.max_lives, 17)
