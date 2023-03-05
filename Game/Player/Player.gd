extends CharacterBody3D


class_name Player

@export var speed : float = 5.0
@export var gravity: float = 300

@onready var gun_controller = $GunController
@onready var body = $Body
@onready var hand = $Body/Hand

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Movement
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
	# Shooting
	if Input.is_action_pressed("fire"):
		gun_controller.shoot()


func set_look_direction(dir: Vector3) -> void:
	body.look_at(dir, Vector3.UP)
	if(dir.distance_to(position) > 2.0):
		hand.look_at(dir, Vector3.UP)


func _on_stats_die_signal() -> void:
	queue_free()
	print("Game Over")
