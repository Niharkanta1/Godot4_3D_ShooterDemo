extends Node3D

@onready var timer: Timer = $Timer

@export var enemy: PackedScene
@export var num_enemies: int = 10
@export var seconds_between_spwans: float = 2

var enemy_remaining: int = num_enemies

func _ready() -> void:
	timer.wait_time = seconds_between_spwans
	timer.start()
	
func spawn_enemy() -> void:
	var new_enemy = enemy.instantiate()
	var spawn_root = get_parent().get_node("Enemies")
	spawn_root.add_child(new_enemy)
	enemy_remaining -= 1


func _on_timer_timeout() -> void:
	if enemy_remaining:
		spawn_enemy()
	else:
		timer.stop()
