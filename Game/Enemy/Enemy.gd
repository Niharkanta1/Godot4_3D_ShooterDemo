extends CharacterBody3D

class_name Enemy

@onready var player: Player = get_parent().get_parent().get_node("Player") as Player
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D 
@onready var timer: Timer = $Timers/PathUpdateTimer
@onready var attack_timer: Timer = $Timers/AttackTimer

var default_material = load("res://Game/Enemy/Enemy_Default_Material.tres")
var attack_material = load("res://Game/Enemy/Enemy_Attack_Material.tres")
var resting_material = load("res://Game/Enemy/Enemy_Rest_Material.tres")

var move_speed: float = 3.0
var look_for_player: bool = false;
var attack_speed_modifier = 5
var attack_target: Vector3
var return_target: Vector3

enum State {
	SEEK,
	ATTACK,
	REST,
	RETURN
}

var current_state: State = State.SEEK

func _ready() -> void:
	timer.start(1)
	navigation_agent.set_target_position(player.global_transform.origin)
	$Body.set_surface_override_material(0, default_material)
	

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player): 
		return
	match current_state:
		State.ATTACK:
			move_and_attack()
			
		State.SEEK:
			if player.global_transform.origin.distance_to(global_transform.origin) > 0.9:
				if not look_for_player:
					timer.start(1)
				look_for_player = true
			else:
				print("Target reached")
				look_for_player = false
				timer.stop()
				return
			
			var seeking_vector : Vector3 = navigation_agent.get_next_path_position() - global_transform.origin
			seeking_vector = seeking_vector.normalized() * move_speed

			set_velocity(seeking_vector)
			move_and_slide()
			
			if $AttackRadius.overlaps_body(player):
				attack()
		
		State.RETURN:
			move_and_attack()
		
		State.REST:
			set_velocity(Vector3.ZERO)
			move_and_slide()
	
func move_and_attack() -> void:
	var attack_vector: Vector3 = attack_target - global_transform.origin
	var direction: Vector3 = attack_vector.normalized()
	var distance = attack_vector.length()
	set_velocity(direction * move_speed * attack_speed_modifier)
	move_and_slide()
	if distance < 1:
		match current_state:
			State.ATTACK:
				# Do Damage
				var player_stats: Stats = player.get_node("Stats") as Stats
				player_stats.take_hit(1)
				
				current_state = State.RETURN
				attack_target = return_target
			State.RETURN:
				current_state = State.REST
				$Body.set_surface_override_material(0, resting_material)
				attack_timer.start()
				set_collisions(true)


func set_collisions(flag: bool) -> void:
	set_collision_mask_value(2, flag)
	#set_collision_layer_value(2, flag)

# Signals
func _on_timer_timeout() -> void:
	if is_instance_valid(player) and look_for_player:
		navigation_agent.set_target_position(player.global_transform.origin)
	else:
		look_for_player = false

func _on_stats_die_signal() -> void:
	queue_free()


func attack() -> void:
	current_state = State.ATTACK
	attack_target = player.global_transform.origin
	return_target = global_transform.origin
	set_collisions(false)
	$Body.set_surface_override_material(0, attack_material)

func _on_attack_timer_timeout() -> void:
	current_state = State.SEEK
	$Body.set_surface_override_material(0, default_material)
