extends CharacterBody3D

class_name Enemy

@onready var player: Player = get_parent().get_parent().get_node("Player") as Player
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D 
@onready var timer: Timer = $Timer

var move_speed: float = 3.0
var look_for_player: bool = false;

func _ready() -> void:
	timer.start(1)
	navigation_agent.set_target_position(player.global_transform.origin)
	

func _physics_process(_delta: float) -> void:

	if player.global_transform.origin.distance_to(global_transform.origin) > 0.9:
		if not look_for_player:
			timer.start(1)
		look_for_player = true
	else:
		print("Target reached")
		look_for_player = false
		timer.stop()
		return
	
	var direction : Vector3 = navigation_agent.get_next_path_position() - global_transform.origin
	direction = direction.normalized() * move_speed

	set_velocity(direction)
	move_and_slide()
	

func _on_timer_timeout() -> void:
	if look_for_player:
		navigation_agent.set_target_position(player.global_transform.origin)


func _on_stats_die_signal() -> void:
	queue_free()
