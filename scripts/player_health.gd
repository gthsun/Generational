extends "res://scripts/actor_component.gd"

var lives := 3
var max_lives := 3
var invulnerable := 0.0
signal died

func hurt_player(ignore_invulnerability = false) -> void:
	if game.powers.power_active(4) or (invulnerable > 0.0 and not ignore_invulnerability) or game.state != "playing":
		return
	lives -= 1
	game.sounds.play_effect("lose_life")
	invulnerable = 1.25
	if lives <= 0:
		actor.melee.attack_timer = 0.0
		died.emit()

func reset() -> void:
	lives = 3
	max_lives = 3
	invulnerable = 0

func tick(dt: float) -> void:
	invulnerable = maxf(0, invulnerable - dt)

func add_heart() -> void:
	lives = mini(lives + 1, max_lives)

func lose_all() -> void:
	if lives > 0:
		game.sounds.play_effect("lose_life")
	lives = 0
	died.emit()
