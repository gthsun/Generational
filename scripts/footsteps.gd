extends "res://scripts/actor_component.gd"
var distance = 0.0
var cooldown = 0.0

func reset() -> void:
	distance = 0
	cooldown = 0

func moved(from: Vector2, dt: float, enemy: bool, airborne: bool = false) -> void:
	cooldown = maxf(0, cooldown - dt)
	var travel = actor.position.distance_to(from)
	if airborne or travel < 0.01:
		distance = 0
		return
	distance += travel
	if distance < (24 if enemy else 44) or cooldown > 0:
		return
	distance = 0
	cooldown = 0.22
	var sound_name = "level4_step" if game.level == 3 else "grass_step"
	if enemy:
		sound_name = ["enemy_grass_step", "enemy_grass_step", "enemy_level3_step", "enemy_level4_step"][game.level]
	game.sounds.play_effect(sound_name)
