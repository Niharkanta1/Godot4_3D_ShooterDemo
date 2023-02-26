extends Node3D

var ray_origin := Vector3.ZERO
var ray_target := Vector3.ZERO

func _physics_process(_delta: float) -> void:
	
	var mouse_pos = get_viewport().get_mouse_position()
	ray_origin = $Camera3D.project_ray_origin(mouse_pos)
	ray_target = ray_origin + $Camera3D.project_ray_normal(mouse_pos) * 2000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	var intersection : Dictionary = space_state.intersect_ray(query) 
	
	if not intersection.is_empty():
		var pos = intersection.get("position")
		var look_pos = Vector3(pos.x, $Player.position.y , pos.z)
		$Player.get_node("Body").look_at(look_pos, Vector3.UP)
		
