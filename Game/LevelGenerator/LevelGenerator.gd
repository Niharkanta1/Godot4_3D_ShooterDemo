@tool
extends Node3D

@export_category("Map:: Scenes")
@export var ground_scene: PackedScene
@export var obstacle_scene: PackedScene

var shader_material: ShaderMaterial

@export_category("Map:: Size")
@export_range(2, 20, 2) var map_width: int = 10: 
	set(value):
		map_width = value
		update_map_center()
		generate_map()
		
@export_range(2, 20, 2) var map_depth: int = 10:
	set(value):
		map_depth = value
		update_map_center()
		generate_map()

@export_category("Map:: Obstacle")
@export_range(0.00, 0.5, 0.05) var obstacle_ratio: float = 0.2:
	set(value):
		obstacle_ratio = value
		generate_map()

@export_range(1, 5, 1) var obstacle_max_height: int = 5:
	set(value):
		obstacle_max_height = max(value, obstacle_min_height)
		generate_map()
		
@export_range(1, 5, 1) var obstacle_min_height: int = 1:
	set(value):
		obstacle_min_height = min(value, obstacle_max_height)
		generate_map()
		
@export_category("Map:: Color Settings")
@export var background_color: Color :
	set(value):
		background_color = value
		generate_map()
		
@export var foreground_color: Color :
	set(value):
		foreground_color = value
		generate_map()

@export var obstacle_offset: float = 0.5:
	set(value):
		obstacle_offset = value
		generate_map()
		
@export var even_obstacle_offset: float = 0.25:
	set(value):
		even_obstacle_offset = value
		generate_map()
		
@export_category("Map:: Seed")
@export var rng_seed: int = 12345:
	set(value):
		rng_seed = value
		generate_map()
		

var map_cord_array := []
var num_obstacles := 0

# Cordinates Class
class Cords:
	var x: int
	var z: int
	
	func _init(x, z) -> void:
		self.x = x
		self.z = z
	
	func _to_string() -> String:
		return "(" + str(x) + ", "+ str(z) +")"

	func equals(cord: Cords) -> bool:
		return self.x == cord.x and self.z == cord.z

var map_center: Cords


func _ready() -> void:
	generate_map()


func fill_map_cordinates_array() -> void:
	map_cord_array = []
	for x in range(map_width):
		for z in range(map_depth):
			map_cord_array.append(Cords.new(x, z))

func update_map_center() -> void:
	map_center = Cords.new(map_width/2, map_depth/2)

func generate_map() -> void:
	clear_map()
	print("Generating Map...")	
	
	add_ground()
	update_obstacle_material()
	add_obstacles()
	print("Map generated with Size:(",map_width,"x",map_depth ,") and number of obstacles:", num_obstacles)


func clear_map() -> void:
	print("Clearing map...")
	num_obstacles = 0
	for node in get_children():
		node.queue_free()


func add_ground() -> void:
	var ground: CSGBox3D = ground_scene.instantiate() as CSGBox3D
	ground.size.x = map_width 
	ground.size.z = map_depth
	add_child(ground)


func add_obstacles() -> void:
	fill_map_cordinates_array()
#	print(map_cord_array)
	seed(rng_seed)
	map_cord_array.shuffle()
#	print(map_cord_array)
	var num_obstacle: int = map_cord_array.size() * obstacle_ratio
	for cord in map_cord_array.slice(0, num_obstacle): # GDScript slice is inclusive the bound index
		if not map_center.equals(cord):
			create_obstacle_at(cord.x, cord.z)


func create_obstacle_at(x: int, z: int) -> void:
	var obstactle_pos := Vector3(x, 0, z)
	obstactle_pos.x += -map_width/2 + 0.5
	obstactle_pos.z += -map_depth/2 + 0.5
	var height = get_random_obstacle_height()
	var offset = obstacle_offset - even_obstacle_offset if height % 2 == 0 else obstacle_offset
	obstactle_pos.y += offset + height/2
	var new_obstacle: CSGBox3D = obstacle_scene.instantiate() as CSGBox3D
	new_obstacle.transform.origin = obstactle_pos
	new_obstacle.size.y = height
	# Update Material 
	set_random_material_with_texture(new_obstacle, z)
	add_child(new_obstacle)
	num_obstacles += 1

func get_random_obstacle_height() -> int:
	return randi_range(obstacle_min_height, obstacle_max_height)
	

func update_obstacle_material() -> void:
	var temp_obstacle = obstacle_scene.instantiate() as CSGBox3D
	shader_material = temp_obstacle.material as ShaderMaterial
	shader_material.set_shader_parameter("ForegroundColor", foreground_color)
	shader_material.set_shader_parameter("BackgroundColor", background_color)
	shader_material.set_shader_parameter("MapDepth", map_depth)
	

func set_random_material_with_texture(new_obstacle: CSGBox3D, z: int) -> void:
	var new_material := StandardMaterial3D.new()
	new_material.albedo_color = get_color_at_depth(z)
	var existing_material = new_obstacle.material as StandardMaterial3D
	var texture = existing_material.albedo_texture as CompressedTexture2D
	new_material.albedo_texture = texture
	new_material.uv1_triplanar = true
	new_material.uv1_offset = Vector3(0.5, 0, 0.5)
	new_obstacle.material = new_material


func get_color_at_depth(z: int) -> Color:
	return background_color.lerp(foreground_color, float(z)/map_depth)
