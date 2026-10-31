extends "res://scripts/game_component.gd"

const EnemyScene = preload("res://scenes/enemy.tscn")
var grunts: Array[Node2D]:
	get:
		var result: Array[Node2D] = []
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.get_parent() == self:
				result.append(enemy)
		return result
var corpses: Array[Dictionary] = []
signal enemy_defeated

func remove_dead_grunts() -> void:
	for enemy in grunts.duplicate():
		enemy.check_defeated()

func _on_enemy_defeated(enemy: Node2D) -> void:
	corpses.append({"pos": enemy.pos, "time": 2.2, "size": enemy.size, "boss": enemy.boss})
	remove_child(enemy)
	enemy.queue_free()
	enemy_defeated.emit()

func spawn_grunt(boss = false) -> void:
	var pos: Vector2
	match game.rng.randi_range(0, 3):
		0: pos = Vector2(Rules.ARENA.position.x + 36, game.rng.randf_range(60, 724))
		1: pos = Vector2(Rules.ARENA.end.x - 36, game.rng.randf_range(60, 724))
		2: pos = Vector2(game.rng.randf_range(36, 1084), Rules.ARENA.position.y + 60)
		3: pos = Vector2(game.rng.randf_range(36, 1084), Rules.ARENA.end.y - 36)
	if pos.distance_to(game.player.position) < 180:
		pos = game.player.movement.clamp_to_arena(Rules.ARENA.get_center() * 2 - pos)
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	enemy.configure(game, boss, pos)
	enemy.defeated.connect(_on_enemy_defeated)
	grunts[-1].pos = grunts[-1].movement.clamp_position(pos)
	if boss:
		grunts[-1].weapon.shoot = 0.8

func shooter_limit() -> int:
	return mini(Rules.LEVELS[game.level].max_shooters, 3 if game.wave >= 2 else 2)

func active_shooters() -> int:
	var count = 0
	for enemy in grunts:
		if enemy.weapon.is_firing():
			count += 1
	return count

func clear() -> void:
	for enemy in grunts:
		remove_child(enemy)
		enemy.queue_free()

func tick(dt: float) -> void:
	for enemy in grunts:
		enemy.tick(dt)

func check_contact() -> void:
	for enemy in grunts:
		var closest = Geometry2D.get_closest_point_to_segment(game.player.position, enemy.previous_pos, enemy.pos)
		if enemy.phase.jump <= 0 and not enemy.maneuver.landing_frame and closest.distance_to(game.player.position) < 14 + enemy.radius:
			game.player.health.hurt_player()

func update_corpses(dt: float) -> void:
	for i in range(corpses.size() - 1, -1, -1):
		corpses[i].time -= dt
		if corpses[i].time <= 0:
			corpses.remove_at(i)

func _draw() -> void:
	if game == null:
		return
	for c in corpses:
		sprite((game.assets.boss_frames if c.boss else game.assets.grunt_frames)[game.level * 13 + 12], c.pos, c.size, false, Color(1, 1, 1, minf(1, c.time)))

func spawn_wave(index: int) -> void:
	var count: int = Rules.WAVE_COUNTS[index]
	for i in range(count):
		spawn_grunt(index == Rules.BOSS_WAVE)
		# Spread each group around the arena, keeping its entrance away from the player.
		var g = grunts[-1]
		var fraction = float(i / 4 + 1) / float((count + 3) / 4 + 1)
		var pos: Vector2
		match i % 4:
			0: pos = Vector2(lerpf(80, 1040, fraction), 60)
			1: pos = Vector2(1040, lerpf(100, 660, fraction))
			2: pos = Vector2(lerpf(1040, 80, fraction), 700)
			3: pos = Vector2(80, lerpf(660, 100, fraction))
		if pos.distance_to(game.player.position) < 220:
			pos = Rules.ARENA.get_center() * 2 - pos
		g.pos = g.movement.clamp_position(pos)
