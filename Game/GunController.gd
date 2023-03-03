extends Node


@export var starting_weapon : PackedScene

var hand: Marker3D
var equipped_weapon: Gun

func  _ready() -> void:
	hand = get_parent().get_node("Body/Hand")
	if starting_weapon:
		equip_weapon(starting_weapon)
		
		
func equip_weapon(weapon_to_equip: PackedScene) -> void:
	if equipped_weapon:
		print("Deleting current weapon")
		equipped_weapon.queue_free()
	else:
		print("No weapon equipped.")
		equipped_weapon = weapon_to_equip.instantiate()
		hand.add_child(equipped_weapon)

func shoot() -> void:
	if equipped_weapon:
		equipped_weapon.shoot()
	else:
		print("No gun is equiped")
		
