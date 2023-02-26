extends Node3D


class_name Bullet

@export var speed := 50.0

const KILL_TIME := 2
var timer = 0

func _physics_process(delta: float) -> void:
	var forward_dir = global_transform.basis.z.normalized()
	global_translate(forward_dir * speed * delta)
	
	timer += delta
	if(timer >= KILL_TIME):
		queue_free()
