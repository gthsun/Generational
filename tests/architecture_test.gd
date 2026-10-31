extends SceneTree
var defeated_count := 0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn")
	var first = scene.instantiate()
	var second = scene.instantiate()
	root.add_child(first)
	root.add_child(second)
	first.set_process(false)
	second.set_process(false)
	assert(first.player.movement.get_parent() == first.player)
	assert(first.player.health.get_parent() == first.player)
	assert(first.player.melee.get_parent() == first.player)
	assert(first.Rules.LEVELS[0] is Resource)
	assert(first.Rules.LEVELS[3].time_limit == 165)
	first.start_level(0)
	second.start_level(3)
	first.start_wave(2)
	second.start_wave(4)
	assert(first.enemies.grunts.size() == 12 and second.enemies.grunts.size() == 1)
	var boss = second.enemies.grunts[0]
	assert(boss.weapon.special_attack.get_parent() == boss.weapon)
	assert(boss.phase.transition_started.is_connected(boss.weapon.cancel_for_jump))
	first.enemies.enemy_defeated.connect(func(): defeated_count += 1)
	first.enemies.grunts[0].hp = 0
	first.enemies.remove_dead_grunts()
	assert(defeated_count == 1 and first.kills == 1 and second.kills == 0)
	first.enemies.remove_dead_grunts()
	assert(defeated_count == 1)
	first.player.health.lose_all()
	assert(first.state == "dying" and second.state == "playing")
	for index in range(12):
		first.start_level(index % 4)
		first.start_wave(index % 4)
		assert(first.enemies.get_child_count() == first.enemies.grunts.size())
	first.enemies.clear()
	assert(first.enemies.grunts.is_empty() and first.enemies.get_child_count() == 0)
	assert(second.enemies.grunts.size() == 1)
	first.queue_free()
	second.queue_free()
	await process_frame
	assert(get_nodes_in_group("enemies").is_empty())
	assert(get_nodes_in_group("players").is_empty())
	assert(get_nodes_in_group("game_views").is_empty())
	print("PASS: child composition, resource settings, scoped groups, lifecycle signals and cleanup")
	for child in root.get_children():
		if not child.is_queued_for_deletion():
			child.queue_free()
	await create_timer(0.5).timeout
	quit()
