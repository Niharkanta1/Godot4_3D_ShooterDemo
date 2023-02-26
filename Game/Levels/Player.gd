extends CharacterBody3D


class_name Player

@export var speed : float = 5.0

@onready var gun_controller = $GunController

func _physics_process(_delta: float) -> void:
	
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
