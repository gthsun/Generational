extends "res://scripts/actor_component.gd"
@onready var weapon = get_parent()

func fire() -> void:
	weapon.blue_volleys = 0
	weapon.special_after = game.rng.randi_range(3, 5)
	weapon.attack = 0.32
	match game.level:
		0:
			game.projectiles.add_special_ball(actor, weapon.aim, 170, 64, 16, Color.BLACK)
			game.projectiles.fireballs[-1].unbreakable = true
			game.projectiles.fireballs[-1].homing = true
			game.projectiles.fireballs[-1].deflect_timer = 0.0
		1:
			for i in range(20):
				game.projectiles.add_special_ball(actor, weapon.aim.rotated(lerpf(-0.7, 0.7, i / 19.0)), Rules.LEVELS[game.level].special_fireball_speed, 18, 4.5, Color("fff020"))
		2:
			emit_purple()
		3:
			weapon.special_left = 149
			weapon.special_timer = 0.055
			emit_round()

func emit_round() -> void:
	weapon.aim = (game.player.position - actor.pos).normalized()
	actor.movement.facing = Rules.cardinal_direction(weapon.aim, actor.movement.facing)
	weapon.attack = 0.12
	game.projectiles.add_special_ball(actor, weapon.aim, Rules.LEVELS[game.level].special_fireball_speed, 24, 6, Color("ff2424"))


func emit_purple() -> void:
	# Apply the same boss projectile scale to purple specials and corner shots.
	var diameter = sqrt(Rules.ARENA.size.x * Rules.ARENA.size.y / (8.0 * PI)) * 2 * Rules.LEVELS[game.level].boss_fireball_scale
	game.projectiles.add_special_ball(actor, weapon.aim, 45, diameter, diameter * 0.42, Color("b54cff"))
	game.projectiles.fireballs[-1].acceleration = 950.0
