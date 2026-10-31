extends Node
## A behavior attached to an actor; configured by the actor during scene setup.
const Rules = preload("res://scripts/game_rules.gd")
var actor
var game
func setup(owner_actor, controller) -> void:
	actor = owner_actor
	game = controller
