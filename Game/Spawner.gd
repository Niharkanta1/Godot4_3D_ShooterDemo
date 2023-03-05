extends Node3D

@onready var timer: Timer = $Timer

@export var enemy: PackedScene
@export var num_enemies: int = 10
@export var seconds_between_spwans: float = 2

var enemy_killed_this_wave: int = 0
var enemy_remaining: int = num_enemies
var waves
var current_wave : Wave
var current_wave_index = -1

func _ready() -> void:
	waves = $Waves.get_children()
	print(waves.size())
	start_next_wave()
	

func start_next_wave() -> void:
	enemy_killed_this_wave = 0
	current_wave_index += 1
	if current_wave_index < waves.size():
		current_wave = waves[current_wave_index]
		enemy_remaining = current_wave.num_enemies
		timer.wait_time = current_wave.seconds_between_spwans
		timer.start()
	else:
		print("No Wave to Spawn")
		timer.stop()
	
func spawn_enemy() -> void:
	var new_enemy : Enemy = enemy.instantiate()
	connect_to_enemy_signal(new_enemy)
	var spawn_root = get_parent().get_node("Enemies")
	spawn_root.add_child(new_enemy)
	enemy_remaining -= 1


func connect_to_enemy_signal(new_enemy: Enemy) -> void:
	var stats = new_enemy.get_node("Stats") as Stats
	stats.die_signal.connect(_on_enemy_die_signal)

var _on_enemy_die_signal = func():
	enemy_killed_this_wave += 1


func _on_timer_timeout() -> void:
#	print("Enemy Remaining this Wave:", enemy_remaining)
	if enemy_remaining:
		spawn_enemy()
	else:
		if enemy_killed_this_wave >= current_wave.num_enemies:
#			print("Starting Next Wave")
			start_next_wave()
