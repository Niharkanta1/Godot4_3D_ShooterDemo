@tool
extends Node3D

@export_category("Map:: Scenes")
@export var ground_scene: PackedScene
@export var obstacle_scene: PackedScene

var shader_material: ShaderMaterial

@export_category("Map:: Size")
@export_range(1, 19, 2) var map_width: int = 10: 
	set(value):
		map_width = value
		update_map_center()
		
@export_range(1, 19, 2) var map_depth: int = 10:
	set(value):
		map_depth = value
		update_map_center()

@export_category("Map:: Obstacle")
@export_range(0.05, 0.35, 0.05) var obstacle_ratio: float = 0.2:
	set(value):
		obstacle_ratio = value

@export_range(1, 5) var obstacle_max_height: float = 3:
	set(value):
		obstacle_max_height = max(value, obstacle_min_height)

@export_range(1, 5) var obstacle_min_height: float = 1:
	set(value):
		obstacle_min_height = min(value, obstacle_max_height)

@export var obstacle_offset: float = 0.5:
	set(value):
		obstacle_offset = value
		
@export_category("Map:: Color Settings")
@export var background_color: Color :
	set(value):
		background_color = value
		
@export var foreground_color: Color :
	set(value):
		foreground_color = value

@export_category("Map:: Seed")
@export var rng_seed: int = 12345:
	set(value):
		rng_seed = value

@export var generate_level = false:
	set(value):
		if value:
			generate_map()
			generate_level = false
			
@export var save_level = false:
	set(value):
		if value:
			save_current_level()
			save_level = false

@export var level_name := "New Level"

var map_cord_array := []
var obstacle_map := []
var num_obstacles := 0
var navigation_region: NavigationRegion3D
@onready var navigation_mesh := load("res://Game/LevelGenerator/NavigationMeshData.tres") as NavigationMesh

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


func fill_obstacle_cords_array() -> void:
	obstacle_map = []
	for x in range(map_width):
		# 2D array
		obstacle_map.append([]) 
		for z in range(map_depth):
			obstacle_map[x].append(false)


func update_map_center() -> void:
	map_center = Cords.new(map_width/2, map_depth/2)

func generate_map() -> void:
	clear_map()
	print("Generating Map...")	
	
	add_level()	
	add_ground()
	update_obstacle_material()
	add_obstacles()
	navigation_region.bake_navigation_mesh(true)
	print("Map generated with Size:(",map_width,"x",map_depth ,") and number of obstacles:", num_obstacles)


func clear_map() -> void:
	print("Clearing map...")
	num_obstacles = 0
	for node in get_children():
		node.queue_free()


func add_level() -> void:
	# Add Navigation Node
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion"
	navigation_mesh.agent_radius = 0.25
	navigation_mesh.agent_max_slope = 20
	navigation_region.navigation_mesh = navigation_mesh
	add_child(navigation_region)
	navigation_region.owner = self
	

func add_ground() -> void:
	var ground: CSGBox3D = ground_scene.instantiate() as CSGBox3D
	ground.size.x = map_width 
	ground.size.z = map_depth
	navigation_region.add_child(ground)
	ground.owner = self


func add_obstacles() -> void:
	fill_map_cordinates_array()
	fill_obstacle_cords_array()
	seed(rng_seed)
	map_cord_array.shuffle()

	var num_obstacle: int = map_cord_array.size() * obstacle_ratio
	var current_obstacle_count = 0
	
	if num_obstacle > 0:
		for cord in map_cord_array.slice(0, num_obstacle): # GDScript slice is inclusive the bound index
			
			if not map_center.equals(cord):		
				current_obstacle_count += 1
				obstacle_map[cord.x][cord.z] = true
				if map_if_fully_accessible(current_obstacle_count):
					create_obstacle_at(cord.x, cord.z)
				else:
					current_obstacle_count -= 1
					obstacle_map[cord.x][cord.z] = false
					

func map_if_fully_accessible(current_obstacle_count: int) -> bool:
	#Flood Fill
	var already_checked_array := []
	for x in range(map_width):
		# 2D array
		already_checked_array.append([]) 
		for z in range(map_depth):
			already_checked_array[x].append(false)
			
	var cords_to_check = [map_center] # Array
	already_checked_array[map_center.x][map_center.z] = true
	var accessible_tile_count = 1
	
	while cords_to_check:
		var current_tile = cords_to_check.pop_front()
		for x in [-1, 0, 1]: # X offset
			for z in [-1, 0, 1]: # Z offset
				if x == 0 or z == 0: # non-diagonal neighbor
					var neighbor = Cords.new(current_tile.x + x, current_tile.z + z)
					if on_the_map(neighbor):
						if not already_checked_array[neighbor.x][neighbor.z]:
							if not obstacle_map[neighbor.x][neighbor.z]:
								already_checked_array[neighbor.x][neighbor.z] = true
								cords_to_check.append(neighbor)
								accessible_tile_count += 1
	
	var target_accessible_tile_count = map_width * map_depth - current_obstacle_count
	if target_accessible_tile_count == accessible_tile_count:
		return true
	else:
		return false


func on_the_map(cords: Cords) -> bool:
	return cords.x >= 0 and cords.x < map_width and cords.z >= 0 and cords.z < map_depth


func create_obstacle_at(x: int, z: int) -> void:
	var obstactle_pos := Vector3(x, 0, z)
	obstactle_pos.x += -map_width/2
	obstactle_pos.z += -map_depth/2
	var height = get_random_obstacle_height()
	obstactle_pos.y += height/2 + obstacle_offset
	var new_obstacle: CSGBox3D = obstacle_scene.instantiate() as CSGBox3D
	new_obstacle.transform.origin = obstactle_pos
	new_obstacle.size.y = height 
	# Update Material 
	#set_random_material_with_texture(new_obstacle, z)
	navigation_region.add_child(new_obstacle)
	new_obstacle.owner = self
	num_obstacles += 1

func get_random_obstacle_height() -> float:
	return randf_range(obstacle_min_height, obstacle_max_height)
	

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
	

func save_current_level() -> void:
	var packed_scene = PackedScene.new()
	for child in navigation_region.get_children():
		child.owner = navigation_region

	packed_scene.pack(navigation_region)
	var path = "res://Game/Levels/Generated/%s.tscn" % level_name
	print("Saving Level at Path: ", path)
	var error = ResourceSaver.save(packed_scene, path, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	if error != OK:
		print("Error...")
