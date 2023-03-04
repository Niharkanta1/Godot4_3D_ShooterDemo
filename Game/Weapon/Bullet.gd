extends Node3D


class_name Bullet

@export var speed := 50.0
@export var damage := 1


const KILL_TIME := 2
var timer: float = 0 


func _physics_process(delta: float) -> void:
	var forward_dir = global_transform.basis.z.normalized()
	global_translate(forward_dir * speed * delta)
	
	timer += delta
	if(timer >= KILL_TIME):
		queue_free()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_node("Stats"):
		var stats = body.get_node("Stats") as Stats
		stats.take_hit(damage)
	
	queue_free()
