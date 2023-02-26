extends Node3D

class_name Gun

@export var bullet : PackedScene
@export var muzzle_speed: float = 30.0
@export var millis_between_shots: float = 100

@onready var rof_timer = $Timer
var can_shoot := true


func _ready() -> void:
	rof_timer.wait_time = millis_between_shots * 0.001


func shoot():
	if can_shoot:
		var new_bullet: Bullet = bullet.instantiate()
		new_bullet.global_transform = $Muzzle.global_transform
		new_bullet.speed = muzzle_speed
		var scene_root = get_tree().get_root().get_children()[0]
		scene_root.add_child(new_bullet)
		can_shoot = false
		rof_timer.start()


func _on_timer_timeout() -> void:
	can_shoot = true
