extends "res://scripts/game_component.gd"

var pickups: Array[Dictionary] = []
var power_timers: Dictionary = {}
var power_spawn_timer := 10.0

func power_active(kind: int) -> bool:
	return power_timers.get(kind, 0.0) > 0.0

func activate_power(kind: int) -> void:
	if kind == 2:
		game.player.health.add_heart()
		return
	power_timers[kind] = Rules.POWER_SECONDS
	if kind == 3:
		game.player.melee.attack_cooldown = minf(game.player.melee.attack_cooldown, Rules.LEVELS[game.level].attack_cooldown * 0.5)

func spawn_power() -> void:
	var pos = Vector2(game.rng.randf_range(70, 1050), game.rng.randf_range(130, 680))
	if pos.distance_to(game.player.position) < 90:
		pos = Rules.ARENA.get_center() * 2 - pos
	var kind = game.rng.randi_range(0, 4)
	if game.player.health.lives == 1 and game.rng.randf() < 0.5:
		kind = 2
	pickups.append({"kind": kind, "pos": pos})

func update_powers(dt: float) -> void:
	for kind in power_timers.keys():
		power_timers[kind] = maxf(0.0, power_timers[kind] - dt)
		if power_timers[kind] <= 0:
			power_timers.erase(kind)
	power_spawn_timer -= dt
	if power_spawn_timer <= 0:
		spawn_power()
		power_spawn_timer = game.rng.randf_range(10.0, 15.0)

func collect_powers() -> void:
	for i in range(pickups.size() - 1, -1, -1):
		if game.player.position.distance_to(pickups[i].pos) < 32:
			activate_power(pickups[i].kind)
			pickups.remove_at(i)

func power_clock_frame(kind: int) -> int:
	return mini(int((1.0 - power_timers.get(kind, 0.0) / Rules.POWER_SECONDS) * 16.0), 16)

func reset() -> void:
	power_timers.clear()
	pickups.clear()
	power_spawn_timer = game.rng.randf_range(10, 15)

func on_player_attack() -> void:
	if power_active(1):
		game.projectiles.shoot_player()

func _draw() -> void:
	if game == null:
		return
	for pickup in pickups:
		sprite(game.assets.power_frames[pickup.kind], pickup.pos, 44)
