# res://scripts/enemies/hound.gd
extends Enemy
class_name Hound

func _ready() -> void:
	enemy_type = "hound_pale"
	super._ready()
