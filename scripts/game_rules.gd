extends RefCounted

const ARENA := Rect2(0, 0, 1120, 760)
const PLAYER_SPEED := 225.0
const TILE_SIZE := 88
const LEVEL_COUNT := 4
const LEVELS = [preload("res://resources/level_1.tres"), preload("res://resources/level_2.tres"), preload("res://resources/level_3.tres"), preload("res://resources/level_4.tres")]
const WAVE_COUNTS := [4, 8, 12, 16, 1]
const BOSS_WAVE := 4
const BURST_INTERVAL := 0.16
const WALK := [1, 0, 2, 0]
const SHOT_WARNING := 0.4
const BOSS_RECOVERY := 0.7
const FIRE_FPS := 16.0
const POWER_SECONDS := 5.0
const CARDINALS := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
static func cardinal_direction(direction: Vector2, previous: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return previous
	# Keep the existing axis near diagonals so pursuit cannot flicker between rows.
	if absf(absf(direction.x) - absf(direction.y)) < 0.15:
		if previous.x != 0 and direction.x != 0:
			return Vector2(signf(direction.x), 0)
		if previous.y != 0 and direction.y != 0:
			return Vector2(0, signf(direction.y))
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0)
	return Vector2(0, signf(direction.y))

static func frame_index(level: int, direction: Vector2, walking: bool, attacking: bool, animation_time := 0.0) -> int:
	var row := 0
	if direction.x != 0:
		row = 1
	elif direction.y < 0:
		row = 2
	var pose := 0
	if attacking:
		pose = 3
	elif walking:
		pose = WALK[int(animation_time * 9.0) % 4]
	return level * 13 + row * 4 + pose
