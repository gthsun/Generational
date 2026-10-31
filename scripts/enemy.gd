extends Node2D
signal defeated(enemy)
@onready var footsteps = $Footsteps
@onready var movement = $Movement
@onready var weapon = $Weapon
@onready var phase = $PhaseTransition
@onready var visual = $Visual
@onready var final_phase = $FinalPhase
@onready var maneuver = $Maneuver
var game
var hp = 1
var max_hp = 1
var boss = false
var size = 88.0
var radius = 15.0
var flash = 0.0
var last_swing = -1
var previous_pos = Vector2.ZERO
var pos: Vector2:
	get: return position
	set(value): position = value

func configure(controller, is_boss: bool, spawn_position: Vector2) -> void:
	game = controller
	for component in [movement, weapon, phase, maneuver, footsteps, final_phase]:
		component.setup(self, game)
	visual.bind(self, game)
	phase.transition_started.connect(weapon.cancel_for_jump)
	phase.transition_started.connect(maneuver.cancel)
	phase.landed.connect(maneuver.on_landed)
	var definition = game.Rules.LEVELS[game.level]
	boss = is_boss
	if boss:
		size = definition.boss_size
		radius = 15.0 * size / 88.0
	pos = spawn_position
	previous_pos = pos
	max_hp = definition.boss_health if boss else definition.health_for_wave(game.wave)
	hp = max_hp
	movement.speed = game.rng.randf_range(46, 85) + definition.enemy_speed_bonus
	weapon.shoot = game.rng.randf_range(2, 5)
	weapon.special_after = game.rng.randi_range(3, 5)
	phase.jump_from = pos
	phase.jump_to = pos
	add_to_group("enemies")

func tick(dt: float) -> void:
	previous_pos = pos
	maneuver.landing_frame = false
	flash = maxf(0, flash - dt)
	weapon.attack = maxf(0, weapon.attack - dt)
	movement.moving = false
	if not (phase.tick(dt) or final_phase.tick(dt) or maneuver.tick(dt) or weapon.tick(dt)):
		movement.tick(dt)
	footsteps.moved(previous_pos, dt, true, phase.jump > 0 or maneuver.landing_frame)

func refresh() -> void:
	visual.queue_redraw()

func check_defeated() -> void:
	if hp <= 0:
		defeated.emit(self)
