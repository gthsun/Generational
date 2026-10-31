extends "res://scripts/actor_component.gd"

var phase_two = false
var phase_three = false
var phase_four = false
var jump = 0.0
var jump_from = Vector2.ZERO
var jump_to = Vector2.ZERO

signal entered_phase_two
signal entered_phase_three
signal transition_started
signal landed

func tick(dt: float) -> bool:
	if jump <= 0 and actor.boss:
		if not phase_two and actor.hp <= actor.max_hp - health_per_phase():
			begin_jump(2)
		elif phase_two and not phase_three and actor.hp <= actor.max_hp - health_per_phase() * 2:
			begin_jump(3)
		elif phase_three and not phase_four and phase_count() == 4 and actor.hp <= phase_health(3):
			begin_jump(4)
	if jump <= 0:
		return false
	jump = maxf(0, jump - dt)
	actor.pos = jump_from.lerp(jump_to, smoothstep(0, 1, 1 - jump / 1.2))
	if jump == 0:
		landed.emit()
	return true

func begin_jump(next_phase: int) -> void:
	game.sounds.play_effect("jump")
	if next_phase == 2:
		phase_two = true
		entered_phase_two.emit()
	elif next_phase == 3:
		phase_three = true
		actor.size = Rules.LEVELS[game.level].boss_final_size
		actor.radius = 15.0 * actor.size / 88.0
		entered_phase_three.emit()
	else:
		phase_four = true
	actor.flash = 0.4
	jump = 1.2
	jump_from = actor.pos
	jump_to = actor.movement.clamp_position(Vector2(70 if actor.pos.x >= Rules.ARENA.get_center().x else 1050, actor.pos.y))
	if next_phase == 4:
		jump_to = Rules.ARENA.get_center()
	transition_started.emit()

func phase_health(index: int) -> int:
	var last: int = Rules.LEVELS[game.level].boss_last_phase_health
	if last > 0:
		return last if index == phase_count() - 1 else int((actor.max_hp - last) / (phase_count() - 1))
	return int(actor.max_hp / phase_count())

func current_phase_index() -> int:
	return 3 if phase_four else (2 if phase_three else (1 if phase_two else 0))

func health_per_phase() -> int:
	return phase_health(current_phase_index())

func current_phase_health() -> int:
	var reserved = 0
	for index in range(current_phase_index() + 1, phase_count()):
		reserved += phase_health(index)
	return clampi(actor.hp - reserved, 0, health_per_phase())

func phase_count() -> int:
	return Rules.LEVELS[game.level].boss_phase_count
