extends Node2D
## Coordinates the scene. Components own their state, simulation and drawing.
const Rules = preload("res://scripts/game_rules.gd")
@onready var controls = $InputControls
@onready var assets = $Assets
@onready var player = $World/Actors/Player
@onready var enemies = $World/Actors/Enemies
@onready var projectiles = $World/Projectiles
@onready var powers = $World/Powerups
@onready var hud = $HUD
@onready var arena = $World/Arena
@onready var effects = $World/PlayerEffects
@onready var sounds = $SoundEffects
@onready var victory_audio = $BossVictoryAudio
@onready var music = $Music
var level := 0
var kills := 0
var total_kills := 0
var elapsed := 0.0
var clock := 0.0
var state := "title"
var state_timer := 1.2
var wave := 0
var rng := RandomNumberGenerator.new()
var paused := false
var game_over_choice := 0
var selected_level := 0

func _ready() -> void:
	victory_audio.completed.connect(finish_boss_victory)
	music.play_menu()
	rng.randomize()
	for component in [player, enemies, projectiles, powers, hud, arena, effects]:
		component.setup(self)
	player.health.died.connect(begin_death)
	enemies.enemy_defeated.connect(record_kill)
	powers.reset()
	player.melee.attacked.connect(powers.on_player_attack)
	refresh_view()

func record_kill() -> void:
	kills += 1
	total_kills += 1

func begin_death() -> void:
	game_over_choice = 0
	music.stop()
	state = "dying"
	state_timer = 1.8

func refresh_view() -> void:
	$World.visible = state != "title"
	for view in get_tree().get_nodes_in_group("game_views"):
		if view.game == self:
			view.refresh()

func start_level(index: int) -> void:
	victory_audio.stop()
	music.stop()
	level = index
	player.reset(index)
	powers.reset()
	enemies.clear()
	enemies.corpses.clear()
	projectiles.fireballs.clear()
	kills = 0
	elapsed = 0
	wave = 0
	state = "intro"
	music.play_exposition()
	state_timer = 1.2
	paused = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ENTER and state in ["title", "wave_intro", "won", "gameover"]:
		sounds.play_effect("select")
	if event.keycode == KEY_F11:
		var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if state == "title" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
		selected_level = posmod(selected_level + (1 if event.keycode == KEY_RIGHT else -1), Rules.LEVEL_COUNT)
		sounds.play_effect("select")
		return
	if state == "title" and event.keycode in [KEY_ENTER, KEY_SPACE]:
		start_level(selected_level)
		return
	if state == "intro" and event.keycode in [KEY_ENTER, KEY_SPACE]:
		start_wave(0)
		return
	if event.keycode == KEY_ESCAPE and state == "playing":
		paused = not paused
		sounds.play_effect("select")
	if state == "gameover" and event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		game_over_choice = 1 - game_over_choice
		sounds.play_effect("select")
	if state in ["gameover", "won"] and event.keycode in [KEY_ENTER, KEY_R, KEY_SPACE]:
		var restart_level = level if state == "gameover" and game_over_choice == 0 else 0
		total_kills = 0
		start_level(restart_level)
	if event.keycode == KEY_X and state == "playing" and not paused:
		player.melee.attack_requested = true

func start_wave_test(index: int) -> void:
	start_debug_stage(index, 0)

func start_boss_test(index: int) -> void:
	start_debug_stage(index, Rules.BOSS_WAVE)

func start_debug_stage(index: int, wave_index: int) -> void:
	total_kills = 0
	start_level(index)
	start_wave(wave_index)
	sounds.set_paused(false)
	refresh_view()

func start_wave(index: int) -> void:
	wave = index
	enemies.clear()
	projectiles.fireballs.clear()
	player.melee.attack_timer = 0.0
	player.melee.attack_requested = false
	enemies.spawn_wave(wave)
	state = "playing"
	music.play_stage(wave == Rules.BOSS_WAVE)
	player.health.invulnerable = maxf(player.health.invulnerable, 0.8)

func finish_wave() -> void:
	projectiles.fireballs.clear()
	player.melee.attack_timer = 0.0
	player.melee.attack_requested = false
	player.movement.moving = false
	if wave < Rules.BOSS_WAVE:
		wave += 1
		state = "wave_intro"
		state_timer = 3.0 if wave == Rules.BOSS_WAVE else 0.85
	else:
		state = "boss_defeated"
		music.stop()
		sounds.stop_all()
		victory_audio.play_defeat(level == Rules.LEVEL_COUNT - 1)

func finish_boss_victory() -> void:
	if state != "boss_defeated":
		return
	if level < Rules.LEVEL_COUNT - 1:
		start_level(level + 1)
	else:
		state = "won"
	refresh_view()

func timeout_level() -> void:
	# The deadline ends this character's life, regardless of hearts or immunity.
	player.health.lose_all()
	projectiles.fireballs.clear()
	player.melee.attack_timer = 0.0
	player.melee.attack_requested = false
	player.movement.moving = false

func _process(delta: float) -> void:
	music.stream_paused = paused
	sounds.set_paused(paused)
	if paused:
		refresh_view()
		return
	if state == "boss_defeated":
		refresh_view()
		return
	clock += delta
	if state == "dying":
		projectiles.update_death_bursts(delta)
	if state in ["dying", "wave_intro"]:
		state_timer -= delta
		if state_timer <= 0:
			if state == "wave_intro":
				start_wave(wave)
			else:
				state = "gameover"
				music.play_game_over()
	elif state == "playing":
		update_game(minf(delta, 0.05), delta)
	refresh_view()

func update_game(dt: float, real_dt := -1.0) -> void:
	# Keep the established simulation order; only gameplay advances component clocks.
	powers.update_powers(dt if real_dt < 0 else real_dt)
	if wave < Rules.BOSS_WAVE:
		elapsed = minf(Rules.LEVELS[level].time_limit, elapsed + (dt if real_dt < 0 else real_dt))
		if elapsed >= Rules.LEVELS[level].time_limit:
			timeout_level()
			return
	player.tick_input(dt)
	powers.collect_powers()
	player.melee.handle_attack()
	enemies.tick(dt)
	player.melee.apply_attack_hits()
	if enemies.grunts.is_empty():
		finish_wave()
		return
	enemies.check_contact()
	projectiles.update_fireballs(dt, real_dt)
	if state == "playing" and enemies.grunts.is_empty():
		finish_wave()
		return
	enemies.update_corpses(dt)
