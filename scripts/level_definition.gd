extends Resource
class_name LevelDefinition
@export var boss_title: String
@export var boss_name: String
@export var year: String
@export_multiline var story: String
@export var time_limit: float = 75
@export var attack_duration: float = 0.24
@export var attack_cooldown: float = 0.44
@export var ground_tint: Color = Color.WHITE
@export var enemy_health: int = 1
@export var boss_health: int = 12
@export var boss_phase_count: int = 3
@export var boss_last_phase_health: int = 0
@export var boss_fireball_scale: float = 1.0
@export var boss_corner_travel_time: float = 0.5
@export var boss_size: float = 104
@export var boss_final_size: float = 120
@export var enemy_speed_bonus: float = 0
@export var enemy_health_by_wave: PackedInt32Array = []
@export var max_shooters: int = 2
@export var retreat_speed_scale: float = 0.55
@export var fast_fireball_speed: float = 400
@export var firing_recovery: float = 0.35
@export var boss_firing_recovery: float = 0.7
@export var special_warning: float = 0.8
@export var special_fireball_speed: float = 290

func health_for_wave(wave: int) -> int:
	return enemy_health_by_wave[wave] if wave < enemy_health_by_wave.size() else enemy_health
