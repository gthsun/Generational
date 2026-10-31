extends Node
const Rules = preload("res://scripts/game_rules.gd")

var player_frames: Array[Texture2D] = []
var grunt_frames: Array[Texture2D] = []
var boss_frames: Array[Texture2D] = []
var fire_frames: Array[Texture2D] = []
var grass_frames: Array[Texture2D] = []
var slash_frames: Array[Texture2D] = []
var boom_frames: Array[Texture2D] = []
var clock_frames: Array[Texture2D] = []
var power_frames: Array[Texture2D] = []
var title_card: Texture2D
var firebar_frames: Array[Texture2D] = []
var forcefield_frames: Array[Texture2D] = []
var heart: Texture2D

func _ready() -> void:
	title_card = load("res://assets/sprites/ui/Title.png")
	for i in range(3):
		forcefield_frames.append(load("res://assets/sprites/effects/Forcefield/sprite_%d.png" % i))
	for i in range(5):
		firebar_frames.append(load("res://assets/sprites/ui/Firebar/sprite_%d.png" % i))
	for i in range(5):
		power_frames.append(load("res://assets/sprites/ui/Powers/sprite_%d.png" % i))
	for i in range(Rules.LEVEL_COUNT * 13):
		player_frames.append(load("res://assets/sprites/characters/GodotPlayer/sprite_%02d.png" % i))
		grunt_frames.append(load("res://assets/sprites/characters/EclipseGrunt/sprite_%02d.png" % i))
		boss_frames.append(load("res://assets/sprites/characters/EclipseBoss/sprite_%02d.png" % i))
	for i in range(9):
		fire_frames.append(load("res://assets/sprites/effects/Fireball/sprite_%d.png" % i))
	for i in range(7):
		slash_frames.append(load("res://assets/sprites/effects/Slash/sprite_%d.png" % i))
	for i in range(4):
		boom_frames.append(load("res://assets/sprites/effects/Boom/sprite_%d.png" % i))
	heart = load("res://assets/sprites/ui/Heart.png")
	for i in range(17):
		clock_frames.append(load("res://assets/sprites/ui/Clock/sprite_%02d.png" % i))
	for i in range(Rules.LEVEL_COUNT):
		grass_frames.append(load("res://assets/sprites/environment/grass/sprite_%d.png" % i))
