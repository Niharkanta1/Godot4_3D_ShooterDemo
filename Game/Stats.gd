extends Node

class_name Stats

@export var max_hp : float = 5.0

signal die_signal

@onready var current_hp := max_hp

func take_hit(damage) -> void:
	current_hp -= damage
	if current_hp <= 0:
		die()
		
func die() -> void:
	emit_signal("die_signal")
