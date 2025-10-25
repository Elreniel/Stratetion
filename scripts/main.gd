extends Node2D

# Preload the scenes
@onready var house_scene = preload("res://scenes/buildings/house.tscn")
@onready var barracks_scene = preload("res://scenes/buildings/barracks.tscn")
@onready var mine_scene = preload("res://scenes/buildings/mine.tscn")
@onready var archery_scene = preload("res://scenes/buildings/archery.tscn")
@onready var monastry_scene = preload("res://scenes/buildings/monastry.tscn")
@onready var tower_scene = preload("res://scenes/buildings/tower.tscn")
@onready var wood_tower_scene = preload("res://scenes/buildings/wood_tower.tscn")

@onready var pawn_scene = preload("res://scenes/units/pawn.tscn")
@onready var archer_scene = preload("res://scenes/units/archer.tscn")
@onready var lancer_scene = preload("res://scenes/units/lancer.tscn")
@onready var monk_scene = preload("res://scenes/units/monk.tscn")
@onready var knight_scene = preload("res://scenes/units/knight.tscn")

@onready var building_menu_scene = preload("res://scenes/ui/building_menu.tscn")

# Building mode
var building_mode: bool = false
var building_preview = null
var current_building_type: String = ""
var active_menu = null

# Spawn settings
@export var pawn_min_distance: float = 50.0
@export var pawn_max_distance: float = 100.0

@onready var main_background: ColorRect = $Background

# Background size
@export var background_width: float
@export var background_height: float

# Track spawned building positions
var house_positions: Array[Vector2] = []
@export var min_distance_between_houses: float = 150.0

# Pawn management (only pawns, not other units)
var all_pawns: Array = []
var marriage_check_timer: Timer

# House management
var all_houses: Array = []

# Building availability tracking
var has_barracks: bool = false
var has_archery: bool = false
var has_monastry: bool = false

# Log display
var log_label: Label
var log_messages: Array = []
var max_log_lines: int = 10

# Camera reference
var camera: Camera2D

func _ready():
	
	background_width = main_background.size.x
	background_height = main_background.size.y
	
	# Get camera reference (adjust path to your camera)
	camera = get_viewport().get_camera_2d()
	
	# Create log label
	create_log_label()
	
	log_message("Press 'B' to open building menu!")
	log_message("Press 'ESC' to cancel building")
	
	# Create a timer to periodically check for marriage opportunities
	marriage_check_timer = Timer.new()
	add_child(marriage_check_timer)
	marriage_check_timer.wait_time = 2.0  # Check every 2 seconds
	marriage_check_timer.timeout.connect(_check_for_marriages)
	marriage_check_timer.start()
	
	# Add existing pawns to the list
	call_deferred("_register_existing_pawns")
	call_deferred("_register_existing_houses")

func create_log_label():
	log_label = Label.new()
	log_label.add_theme_font_size_override("font_size", 16)  # Increased size
	log_label.add_theme_color_override("font_color", Color.WHITE)
	log_label.add_theme_color_override("font_outline_color", Color.BLACK)
	log_label.add_theme_constant_override("outline_size", 4)  # Thicker outline
	
	# Add a semi-transparent background
	var panel = Panel.new()
	panel.z_index = 999
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	stylebox.set_corner_radius_all(5)
	stylebox.content_margin_left = 10
	stylebox.content_margin_right = 10
	stylebox.content_margin_top = 5
	stylebox.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", stylebox)
	
	add_child(panel)
	panel.add_child(log_label)
	
	log_label.z_index = 1000  # Make sure it's on top
	
	# Store panel reference for positioning
	log_label.set_meta("panel", panel)

func log_message(message: String):
	log_messages.append(message)
	
	# Keep only the last max_log_lines messages
	if log_messages.size() > max_log_lines:
		log_messages.pop_front()
	
	# Update the label text
	log_label.text = "\n".join(log_messages)
	
	# Also print to console for debugging
	print(message)

func _register_existing_pawns():
	# Find all existing pawns in the scene
	for child in get_children():
		if child.is_in_group("pawns"):
			register_pawn(child)

func _register_existing_houses():
	# Find all existing houses in the scene
	for child in get_children():
		if child.is_in_group("houses"):
			register_house(child)

func register_pawn(pawn):
	if pawn not in all_pawns:
		all_pawns.append(pawn)
		log_message("Registered pawn. Total pawns: " + str(all_pawns.size()))

func register_house(house):
	if house not in all_houses:
		all_houses.append(house)
		log_message("Registered house. Total houses: " + str(all_houses.size()))

func get_available_unit_types() -> Array:
	var available_types = ["knight"]  # Knight is always available
	
	if has_barracks:
		available_types.append("lancer")
	
	if has_archery:
		available_types.append("archer")
	
	if has_monastry:
		available_types.append("monk")
	
	return available_types

func _check_for_marriages():
	# Check if houses should become available again
	check_house_availability()
	
	# Find all single pawns
	var single_pawns = []
	for pawn in all_pawns:
		if is_instance_valid(pawn) and pawn.type == "Single":
			single_pawns.append(pawn)
	
	# Find all empty houses
	var empty_houses = []
	for house in all_houses:
		if is_instance_valid(house) and not house.is_occupied:
			empty_houses.append(house)
	
	# Match single pawns with empty houses
	while single_pawns.size() >= 2 and empty_houses.size() > 0:
		var pawn1 = single_pawns.pop_front()
		var pawn2 = single_pawns.pop_front()
		var house = empty_houses.pop_front()
		
		marry_pawns(pawn1, pawn2, house)

# New function to check house availability
func check_house_availability():
	for house in all_houses:
		if is_instance_valid(house) and house.is_occupied:
			# Remove invalid (dead) occupants
			var valid_occupants = []
			for occupant in house.occupants:
				if is_instance_valid(occupant):
					valid_occupants.append(occupant)
			
			house.occupants = valid_occupants
			
			# If no valid occupants remain, free the house
			if house.occupants.size() == 0:
				house.is_occupied = false
				log_message("House became available again")

func marry_pawns(pawn1, pawn2, house):
	# Mark the house as occupied first
	house.is_occupied = true
	
	# Get available unit types based on buildings
	var available_units = get_available_unit_types()
	
	# Pick random unit types for each pawn from available types
	var unit_type1 = available_units[randi() % available_units.size()]
	var unit_type2 = available_units[randi() % available_units.size()]
	
	log_message("Transforming pawns into: " + unit_type1 + " and " + unit_type2)
	
	# Calculate positions close to the house
	var house_pos = house.global_position
	var offset_distance = 30.0  # How close to the house (adjust as needed)
	
	# Place them on opposite sides of the house
	var pos1 = house_pos + Vector2(offset_distance, 0)
	var pos2 = house_pos + Vector2(-offset_distance, 0)
	
	# Transform pawns into units (these won't be tracked)
	var new_unit1 = transform_pawn_to_unit(pawn1, unit_type1, house, pos1)
	var new_unit2 = transform_pawn_to_unit(pawn2, unit_type2, house, pos2)
	
	# Add to house occupants
	house.occupants.append(new_unit1)
	house.occupants.append(new_unit2)
	
	log_message("Marriage complete! " + str(randi_range(2, 5)) + " children spawned")
	
	var num_children = randi_range(2, 5)
	
	# Spawn children around the house
	for i in range(num_children):
		spawn_baby_pawn(house.global_position, house)

func transform_pawn_to_unit(old_pawn, unit_type: String, house, position: Vector2):
	# Remove old pawn from tracking (important!)
	all_pawns.erase(old_pawn)
	
	# Create new unit
	var new_unit
	match unit_type:
		"archer":
			new_unit = archer_scene.instantiate()
		"lancer":
			new_unit = lancer_scene.instantiate()
		"monk":
			new_unit = monk_scene.instantiate()
		"knight":
			new_unit = knight_scene.instantiate()
		_:
			new_unit = knight_scene.instantiate()  # Default to knight
	
	# Set position and basic properties
	new_unit.global_position = position
	
	# These units will stay idle, so no center_position movement needed
	# But we still set home for reference
	if "home" in new_unit:
		new_unit.home = house
	
	# Add to scene
	add_child(new_unit)
	
	# Remove old pawn
	old_pawn.queue_free()
	
	return new_unit

func spawn_baby_pawn(house_position: Vector2, house):
	var new_pawn = pawn_scene.instantiate()
	
	# Spawn near the house with some random offset
	var random_offset = Vector2(
		randf_range(-100, 100),
		randf_range(-100, 100)
	)
	new_pawn.global_position = house_position + random_offset
	
	# Set the center position for movement to the house
	new_pawn.center_position = house_position
	
	# Set the home
	new_pawn.home = house
	house.occupants.append(new_pawn)
	
	add_child(new_pawn)
	register_pawn(new_pawn)

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
	# Update log position to follow camera
	if camera and log_label:
		var viewport_size = get_viewport_rect().size
		var camera_pos = camera.get_screen_center_position()
		var top_left = camera_pos - viewport_size / 2 + Vector2(10, 10)
		
		var panel = log_label.get_meta("panel")
		if panel:
			panel.global_position = top_left
			log_label.position = Vector2(10, 5)  # Position relative to panel
			# Adjust panel size to fit text
			panel.size = log_label.size + Vector2(20, 10)
	
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
	
	log_message("Building menu opened")

func close_building_menu():
	if active_menu:
		active_menu.queue_free()
		active_menu = null

func _on_building_selected(building_type: String):
	current_building_type = building_type
	close_building_menu()
	start_building_mode(building_type)

func start_building_mode(building_type: String):
	building_mode = true
	create_building_preview(building_type)
	log_message("Building mode: " + building_type)

func cancel_building_mode():
	if building_mode:
		building_mode = false
		current_building_type = ""
		log_message("Building cancelled")
		remove_building_preview()

func create_building_preview(building_type: String):
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
		log_message("ERROR: scene_to_load is null!")
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
				has_barracks = true  # Enable lancer
				log_message("Barracks built! Lancers available")
			"mine":
				building = mine_scene.instantiate()
			"archery":
				building = archery_scene.instantiate()
				has_archery = true  # Enable archer
				log_message("Archery built! Archers available")
			"monastry":
				building = monastry_scene.instantiate()
				has_monastry = true  # Enable monk
				log_message("Monastry built! Monks available")
			"tower":
				building = tower_scene.instantiate()
			"wood_tower":
				building = wood_tower_scene.instantiate()
			_:
				building = house_scene.instantiate()
		
		building.position = position
		add_child(building)
		house_positions.append(position)
		
		# Register house if it's a house
		if current_building_type == "house":
			register_house(building)
				
		log_message(current_building_type.capitalize() + " placed")
		
		# Exit building mode after placing
		cancel_building_mode()
	else:
		log_message("Invalid placement!")

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
