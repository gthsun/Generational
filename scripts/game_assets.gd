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
	title_card = load("res://Title.png")
	for i in range(3):
		forcefield_frames.append(load("res://Forcefield/sprite_%d.png" % i))
	for i in range(5):
		firebar_frames.append(load("res://Firebar/sprite_%d.png" % i))
	for i in range(5):
		power_frames.append(load("res://Powers/sprite_%d.png" % i))
	for i in range(Rules.LEVEL_COUNT * 13):
		player_frames.append(load("res://GodotPlayer/sprite_%02d.png" % i))
		grunt_frames.append(load("res://EclipseGrunt/sprite_%02d.png" % i))
		boss_frames.append(load("res://EclipseBoss/sprite_%02d.png" % i))
	for i in range(9):
		fire_frames.append(load("res://Fireball/sprite_%d.png" % i))
	for i in range(7):
		slash_frames.append(load("res://Slash/sprite_%d.png" % i))
	for i in range(4):
		boom_frames.append(load("res://Boom/sprite_%d.png" % i))
	heart = load("res://Heart.png")
	for i in range(17):
		clock_frames.append(load("res://Clock/sprite_%02d.png" % i))
	for i in range(Rules.LEVEL_COUNT):
		grass_frames.append(load("res://grass/sprite_%d.png" % i))
