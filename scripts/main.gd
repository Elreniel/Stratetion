extends Node2D

# Preload the scenes
@onready var house_scene = preload("res://scenes/house.tscn")
@onready var pawn_scene = preload("res://scenes/pawn.tscn")
@onready var barracks_scene = preload("res://scenes/barracks.tscn")
@onready var mine_scene = preload("res://scenes/mine.tscn")
@onready var archery_scene = preload("res://scenes/archery.tscn")
@onready var monastry_scene = preload("res://scenes/monastry.tscn")
@onready var tower_scene = preload("res://scenes/tower.tscn")
@onready var wood_tower_scene = preload("res://scenes/wood_tower.tscn")
@onready var building_menu_scene = preload("res://scenes/building_menu.tscn")

# Building mode
var building_mode: bool = false
var building_preview = null
var current_building_type: String = ""
var active_menu = null

# Spawn settings
@export var pawn_min_distance: float = 50.0
@export var pawn_max_distance: float = 100.0

# Background size
@export var background_width: float = 1920.0
@export var background_height: float = 1080.0

# Track spawned building positions
var house_positions: Array[Vector2] = []
@export var min_distance_between_houses: float = 150.0

func _ready():
	print("Press 'B' to open building menu!")
	print("Press 'ESC' to cancel building")

func _input(event):
	# Open building menu with 'B' key
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_B and !building_mode:
			open_building_menu()
		elif event.keycode == KEY_ESCAPE:
			cancel_building_mode()
			close_building_menu()
	
	# Place building on mouse click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if building_mode:
				try_place_building(get_global_mouse_position())

func _process(delta):
	# Update preview position to follow mouse
	if building_mode and building_preview:
		building_preview.position = get_global_mouse_position()
		
		# Change color based on whether placement is valid
		if is_valid_building_position(building_preview.position):
			building_preview.modulate = Color(0.5, 1.0, 0.5, 0.7)  # Green = valid
		else:
			building_preview.modulate = Color(1.0, 0.5, 0.5, 0.7)  # Red = invalid

func open_building_menu():
	# Close existing menu if any
	close_building_menu()
	
	var menu = building_menu_scene.instantiate()
	add_child(menu)
	active_menu = menu
	
	# Get mouse position and center the menu on it
	var mouse_pos = get_global_mouse_position()
	
	# Center the menu by subtracting half its size (300x300, so 150x150)
	menu.position = mouse_pos - Vector2(150, 150)
	
	# Ensure menu is visible
	menu.visible = true
	menu.z_index = 100  # Make sure it's on top
	
	# Connect to the signal
	menu.building_selected.connect(_on_building_selected)
	
	print("Building menu opened at: ", mouse_pos)

func close_building_menu():
	if active_menu:
		active_menu.queue_free()
		active_menu = null
		print("Building menu closed")

func _on_building_selected(building_type: String):
	print("Selected building: ", building_type)
	current_building_type = building_type
	close_building_menu()
	start_building_mode(building_type)

func start_building_mode(building_type: String):
	building_mode = true
	create_building_preview(building_type)
	print("Building mode ENABLED - Click to place ", building_type)

func cancel_building_mode():
	if building_mode:
		building_mode = false
		current_building_type = ""
		print("Building cancelled")
		remove_building_preview()

func create_building_preview(building_type: String):
	print("Creating preview for: ", building_type)
	
	# Load the appropriate scene based on building type
	var scene_to_load
	match building_type:
		"house":
			scene_to_load = house_scene
		"barracks":
			scene_to_load = barracks_scene
		"mine":
			scene_to_load = mine_scene
		"archery":
			scene_to_load = archery_scene
		"monastry":
			scene_to_load = monastry_scene
		"tower":
			scene_to_load = tower_scene
		"wood_tower":
			scene_to_load = wood_tower_scene
		_:
			scene_to_load = house_scene
	
	if scene_to_load == null:
		print("ERROR: scene_to_load is null!")
		return
	
	building_preview = scene_to_load.instantiate()
	building_preview.modulate = Color(1, 1, 1, 0.5)
	add_child(building_preview)
	
	# Disable collision on preview
	for child in building_preview.get_children():
		if child is CollisionShape2D:
			child.disabled = true

func remove_building_preview():
	if building_preview:
		building_preview.queue_free()
		building_preview = null

func try_place_building(position: Vector2):
	if is_valid_building_position(position):
		# Place the actual building
		var building
		match current_building_type:
			"house":
				building = house_scene.instantiate()
			"barracks":
				building = barracks_scene.instantiate()
			"mine":
				building = mine_scene.instantiate()
			"archery":
				building = archery_scene.instantiate()
			"monastry":
				building = monastry_scene.instantiate()
			"tower":
				building = tower_scene.instantiate()
			"wood_tower":
				building = wood_tower_scene.instantiate()
			_:
				building = house_scene.instantiate()
		
		building.position = position
		add_child(building)
		house_positions.append(position)
				
		print(current_building_type.capitalize(), " placed at: ", position)
		
		# Exit building mode after placing
		cancel_building_mode()
	else:
		print("Invalid placement! Too close to another building, on top of object, or out of bounds")

func is_valid_building_position(position: Vector2) -> bool:
	# Check bounds
	if position.x < 100 or position.x > background_width - 100:
		return false
	if position.y < 100 or position.y > background_height - 100:
		return false
	
	# Check distance from other buildings
	for existing_position in house_positions:
		var distance = position.distance_to(existing_position)
		if distance < min_distance_between_houses:
			return false
	
	# Check if clicking on an existing interactable object
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	
	# If we hit anything, it's not valid
	if result.size() > 0:
		for collision in result:
			var collider = collision.collider
			# Ignore the preview itself
			if collider != building_preview and collider.get_parent() != building_preview:
				return false
	
	return true
