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

@onready var goblin_torch_scene = preload("res://scenes/units/goblin_torch.tscn")

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

# City border tracking
var city_border_left: float = 0.0
var city_border_right: float = 0.0
var city_border_top: float = 0.0
var city_border_bottom: float = 0.0
var city_center: Vector2 = Vector2.ZERO
var city_initialized: bool = false

# Track all buildings for city border calculation
var all_buildings: Array = []

var castle_position: Vector2 = Vector2.ZERO

var enemy_spawn_timer: Timer = null
var spawn_interval_min: float = 15.0
var spawn_interval_max: float = 25.0
var spawn_distance_from_edge: float = 100.0
var max_enemies: int = 20  # Limit total enemies

# Child spawning settings
@export var child_spawn_interval: float = 1.0  # Time between each child spawn

# Training settings
@export var training_duration: float = 30.0  # Time units spend training at their building

# Track units waiting for children
var units_waiting_for_children: Array = []

# Building tracking
var all_barracks: Array = []
var all_archeries: Array = []
var all_monasteries: Array = []

# Difficulty scaling
var game_time: float = 0.0
var difficulty_increase_interval: float = 60.0  # Increase difficulty every 60 seconds
var spawn_rate_multiplier: float = 1.0
var max_enemies_increase: int = 2  # Add 2 to max enemies per difficulty increase

# Game state
var game_over: bool = false
var castle = null

# UI for game over
var game_over_panel: Panel = null
var game_over_label: Label = null

# Camera reference
var camera: Camera2D

# NEW: Marriage queue system
var pending_marriages: Array = []  # Array of {pawn1, pawn2, house}
var marriage_arrival_check_timer: Timer

func _ready():
	
	castle = get_node_or_null("Castle")
	if castle:
		castle_position = castle.global_position
		castle.castle_destroyed.connect(_on_castle_destroyed)
		print("Castle defended at " + str(castle_position))
	else:
		# Fallback position if no castle node
		castle_position = Vector2(background_width / 2, background_height / 2)
		print("No castle found, using center position")
		
	background_width = main_background.size.x
	background_height = main_background.size.y
	
	# Get camera reference (adjust path to your camera)
	camera = get_viewport().get_camera_2d()
	
	print("Press 'B' to open building menu!")
	print("Press 'ESC' to cancel building")
	
	# Create a timer to periodically check for marriage opportunities
	marriage_check_timer = Timer.new()
	add_child(marriage_check_timer)
	marriage_check_timer.wait_time = 2.0  # Check every 2 seconds
	marriage_check_timer.timeout.connect(_check_for_marriages)
	marriage_check_timer.start()
	
	# NEW: Create timer to check if pawns have arrived at houses
	marriage_arrival_check_timer = Timer.new()
	add_child(marriage_arrival_check_timer)
	marriage_arrival_check_timer.wait_time = 0.1  # Check every 0.1 seconds for faster response
	marriage_arrival_check_timer.timeout.connect(_check_marriage_arrivals)
	marriage_arrival_check_timer.start()
	
	# Add existing pawns to the list
	call_deferred("_register_existing_pawns")
	call_deferred("_register_existing_houses")
	call_deferred("_register_existing_training_buildings")
	call_deferred("_register_existing_buildings")
	
	create_enemy_spawn_timer()

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

func _register_existing_training_buildings():
	# Find all existing training buildings in the scene
	for child in get_children():
		if child.is_in_group("barracks") or child.is_in_group("archery") or child.is_in_group("monastry"):
			register_training_building(child)

func _register_existing_buildings():
	# Find all existing buildings and calculate city borders
	for child in get_children():
		if child.is_in_group("buildings"):
			register_building(child)

func register_pawn(pawn):
	if pawn not in all_pawns:
		all_pawns.append(pawn)
		print("Registered pawn. Total pawns: " + str(all_pawns.size()))

func register_house(house):
	if house not in all_houses:
		all_houses.append(house)
		print("Registered house. Total houses: " + str(all_houses.size()))

func register_training_building(building):
	if building.is_in_group("barracks") and building not in all_barracks:
		all_barracks.append(building)
		print("Registered barracks. Total: " + str(all_barracks.size()))
	elif building.is_in_group("archery") and building not in all_archeries:
		all_archeries.append(building)
		print("Registered archery. Total: " + str(all_archeries.size()))
	elif building.is_in_group("monastry") and building not in all_monasteries:
		all_monasteries.append(building)
		print("Registered monastery. Total: " + str(all_monasteries.size()))

func register_building(building):
	# Register building for city border calculation
	if building not in all_buildings:
		all_buildings.append(building)
		calculate_city_borders()
		print("Building registered. Total buildings: " + str(all_buildings.size()))

func calculate_city_borders():
	if all_buildings.size() == 0:
		return
	
	# Start with first building position
	var first_building = all_buildings[0]
	city_border_left = first_building.global_position.x
	city_border_right = first_building.global_position.x
	city_border_top = first_building.global_position.y
	city_border_bottom = first_building.global_position.y
	
	# Find the extreme positions
	for building in all_buildings:
		if not is_instance_valid(building):
			continue
		
		var pos = building.global_position
		
		if pos.x < city_border_left:
			city_border_left = pos.x
		if pos.x > city_border_right:
			city_border_right = pos.x
		if pos.y < city_border_top:
			city_border_top = pos.y
		if pos.y > city_border_bottom:
			city_border_bottom = pos.y
	
	# Add padding around the borders (so units patrol slightly outside buildings)
	var padding = 150.0
	city_border_left -= padding
	city_border_right += padding
	city_border_top -= padding
	city_border_bottom += padding
	
	# Calculate city center
	city_center = Vector2(
		(city_border_left + city_border_right) / 2.0,
		(city_border_top + city_border_bottom) / 2.0
	)
	
	city_initialized = true
	
	print("=== CITY BORDERS UPDATED ===")
	print("Left: " + str(city_border_left))
	print("Right: " + str(city_border_right))
	print("Top: " + str(city_border_top))
	print("Bottom: " + str(city_border_bottom))
	print("Center: " + str(city_center))
	print("Width: " + str(city_border_right - city_border_left))
	print("Height: " + str(city_border_bottom - city_border_top))
	print("============================")

func get_city_patrol_position() -> Vector2:
	# Return a random position within city borders
	if not city_initialized or all_buildings.size() == 0:
		# Fallback to castle position if city not initialized
		return castle_position
	
	var random_x = randf_range(city_border_left, city_border_right)
	var random_y = randf_range(city_border_top, city_border_bottom)
	
	return Vector2(random_x, random_y)

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
	
	# Find all single pawns that are not already in a pending marriage
	var single_pawns = []
	for pawn in all_pawns:
		if is_instance_valid(pawn) and pawn.type == "Single":
			# Check if this pawn is already in a pending marriage
			var already_pending = false
			for marriage_data in pending_marriages:
				if marriage_data.pawn1 == pawn or marriage_data.pawn2 == pawn:
					already_pending = true
					break
			
			if not already_pending:
				single_pawns.append(pawn)
	
	# Find all empty houses
	var empty_houses = []
	for house in all_houses:
		if is_instance_valid(house) and not house.is_occupied:
			# Check if this house is already assigned to a pending marriage
			var already_assigned = false
			for marriage_data in pending_marriages:
				if marriage_data.house == house:
					already_assigned = true
					break
			
			if not already_assigned:
				empty_houses.append(house)
	
	# Match single pawns with empty houses and initiate marriage journey
	while single_pawns.size() >= 2 and empty_houses.size() > 0:
		var pawn1 = single_pawns.pop_front()
		var pawn2 = single_pawns.pop_front()
		var house = empty_houses.pop_front()
		
		initiate_marriage_journey(pawn1, pawn2, house)

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
				print("House became available again")

# NEW: Function to initiate the marriage journey
func initiate_marriage_journey(pawn1, pawn2, house):
	print("Marriage journey initiated! Pawns heading to house...")
	
	# Mark the house as reserved (but not occupied yet)
	# This prevents other pawns from claiming it
	var marriage_data = {
		"pawn1": pawn1,
		"pawn2": pawn2,
		"house": house,
		"initiated_at": Time.get_ticks_msec()
	}
	pending_marriages.append(marriage_data)
	
	# Set both pawns to walk towards the house
	# Set their center_position to the house location
	pawn1.center_position = house.global_position
	pawn1.target_position = house.global_position
	pawn1.is_moving = true
	pawn1.is_idle = false
	
	pawn2.center_position = house.global_position
	pawn2.target_position = house.global_position
	pawn2.is_moving = true
	pawn2.is_idle = false

# NEW: Check if pawns have arrived at their houses
func _check_marriage_arrivals():
	var marriages_to_complete = []
	
	for i in range(pending_marriages.size() - 1, -1, -1):
		var marriage_data = pending_marriages[i]
		var pawn1 = marriage_data.pawn1
		var pawn2 = marriage_data.pawn2
		var house = marriage_data.house
		
		# Validate all participants still exist
		if not is_instance_valid(pawn1) or not is_instance_valid(pawn2) or not is_instance_valid(house):
			print("Marriage cancelled - participant no longer valid")
			pending_marriages.remove_at(i)
			continue
		
		# Check if both pawns are close to the house FIRST (most important check)
		var distance1 = pawn1.global_position.distance_to(house.global_position)
		var distance2 = pawn2.global_position.distance_to(house.global_position)
		var arrival_threshold = 50.0  # Distance considered "arrived"
		
		# If they haven't arrived yet, skip other checks
		if distance1 > arrival_threshold or distance2 > arrival_threshold:
			continue
		
		# They've arrived! Now check if it's safe to marry
		# Check if pawns are fighting (have enemy_target)
		var pawn1_fighting = false
		var pawn2_fighting = false
		
		if "enemy_target" in pawn1 and pawn1.enemy_target != null and is_instance_valid(pawn1.enemy_target):
			pawn1_fighting = true
		if "enemy_target" in pawn2 and pawn2.enemy_target != null and is_instance_valid(pawn2.enemy_target):
			pawn2_fighting = true
		
		# Check if house is under attack (only if there are enemies in the game)
		var house_under_attack = false
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			house_under_attack = is_house_under_attack(house)
		
		# If anyone is fighting or house is under attack, delay the marriage
		if pawn1_fighting or pawn2_fighting or house_under_attack:
			print("Marriage delayed - combat in progress")
			# Optionally, we could cancel after a certain timeout
			var time_elapsed = (Time.get_ticks_msec() - marriage_data.initiated_at) / 1000.0
			if time_elapsed > 60.0:  # Cancel if waiting more than 60 seconds
				print("Marriage cancelled - took too long (combat)")
				pending_marriages.remove_at(i)
			continue
		
		# Both pawns have arrived and it's safe! Complete the marriage
		print("Both pawns arrived at house - starting marriage!")
		marriages_to_complete.append(marriage_data)
		pending_marriages.remove_at(i)
	
	# Complete all ready marriages
	for marriage_data in marriages_to_complete:
		complete_marriage(marriage_data.pawn1, marriage_data.pawn2, marriage_data.house)

# NEW: Check if a house is currently under attack
func is_house_under_attack(house) -> bool:
	# Get all enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# Only consider it "under attack" if enemy is actively targeting this house
		if "target_unit" in enemy and enemy.target_unit == house:
			return true
		
		# Or if enemy is VERY close to the house (actively attacking range)
		var distance = enemy.global_position.distance_to(house.global_position)
		var threat_range = 50.0  # Only pause if enemy is RIGHT next to the house
		if distance <= threat_range:
			return true
	
	return false

# NEW: Complete the marriage (this replaces the old marry_pawns function)
func complete_marriage(pawn1, pawn2, house):
	# Mark the house as occupied
	house.is_occupied = true
	
	print("Marriage ceremony starting!")
	
	# Get available unit types based on buildings
	var available_units = get_available_unit_types()
	
	# Pick random unit types for each pawn from available types
	var unit_type1 = available_units[randi() % available_units.size()]
	var unit_type2 = available_units[randi() % available_units.size()]
	
	print("Creating trainees for: " + unit_type1 + " and " + unit_type2)
	
	# Calculate positions close to the house
	var house_pos = house.global_position
	var offset_distance = 30.0
	
	# Place them on opposite sides of the house
	var pos1 = house_pos + Vector2(offset_distance, 0)
	var pos2 = house_pos + Vector2(-offset_distance, 0)
	
	# Create trainee units (they handle their own training)
	var trainee1 = create_trainee_unit(pawn1, unit_type1, house, pos1)
	var trainee2 = create_trainee_unit(pawn2, unit_type2, house, pos2)
	
	# Add to house occupants
	house.occupants.append(trainee1)
	house.occupants.append(trainee2)
	
	# ALL units (including Knights) wait for children to be born
	set_unit_waiting(trainee1, true)
	set_unit_waiting(trainee2, true)
	units_waiting_for_children.append(trainee1)
	units_waiting_for_children.append(trainee2)
	
	# Determine number of children
	var num_children = randi_range(3, 5)
	print("Marriage complete! " + str(num_children) + " children will be born")
	
	# Start the child spawning process (async)
	spawn_children_over_time(house, num_children, trainee1, trainee2)

# NEW: Set a unit's waiting state (prevents wandering)
func set_unit_waiting(unit, waiting: bool):
	if not is_instance_valid(unit):
		return
	
	# Set the metadata flag
	unit.set_meta("waiting_for_children", waiting)
	
	if waiting:
		# Stop all movement
		unit.is_moving = false
		unit.is_idle = true
		
		# Hide the unit (parents go inside the house)
		unit.visible = false
		
		# Play idle animation
		if unit.animated_sprite and unit.animated_sprite.sprite_frames.has_animation("idle"):
			unit.animated_sprite.play("idle")

# NEW: Spawn children one by one with delays
func spawn_children_over_time(house, num_children: int, parent1, parent2):
	print("Starting child spawning process for " + str(num_children) + " children")
	print("Parents have entered the house (invisible)")
	
	for i in range(num_children):
		# Check if house still exists
		if not is_instance_valid(house):
			print("Child spawning interrupted - house destroyed")
			# Release parents from waiting (they'll become visible again)
			release_parents_from_waiting(parent1, parent2)
			return
		
		# Check if house is under attack (only if there are enemies)
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0 and is_house_under_attack(house):
			print("Child spawning paused - house under attack!")
			print("Parents emerge from house to defend!")
			# Make parents visible so they can fight
			if is_instance_valid(parent1):
				parent1.visible = true
			if is_instance_valid(parent2):
				parent2.visible = true
			
			# Wait until house is no longer under attack
			while is_house_under_attack(house) and is_instance_valid(house):
				await get_tree().create_timer(0.5).timeout
			
			# Check again if house still exists after waiting
			if not is_instance_valid(house):
				print("Child spawning interrupted - house destroyed during attack")
				# Release parents from waiting
				release_parents_from_waiting(parent1, parent2)
				return
			
			print("House safe again - resuming child spawning")
			print("Parents return inside the house (invisible)")
			# Hide parents again as they go back inside
			if is_instance_valid(parent1):
				parent1.visible = false
			if is_instance_valid(parent2):
				parent2.visible = false
		
		# Spawn the child
		print("Spawning child " + str(i + 1) + "/" + str(num_children))
		spawn_baby_pawn(house.global_position, house)
		print("Child " + str(i + 1) + "/" + str(num_children) + " born!")
		
		# Wait before spawning next child (unless it's the last one)
		if i < num_children - 1:
			print("Waiting " + str(child_spawn_interval) + " seconds before next child...")
			await get_tree().create_timer(child_spawn_interval).timeout
	
	print("All " + str(num_children) + " children have been born!")
	print("Parents emerge from the house!")
	
	# Release parents from waiting state (they'll become visible again)
	release_parents_from_waiting(parent1, parent2)

# NEW: Release parents from waiting state - send them to appropriate place
func release_parents_from_waiting(parent1, parent2):
	# Release parent 1
	if is_instance_valid(parent1):
		parent1.set_meta("waiting_for_children", false)
		parent1.visible = true
		units_waiting_for_children.erase(parent1)
		
		# Check if this is a Knight (Knights skip training and go straight to patrol)
		if parent1.type == "Knight":
			# Knights need to start patrolling - pick their first target
			if parent1.has_method("pick_random_target"):
				parent1.pick_random_target()
			parent1.is_idle = false
			parent1.is_moving = true
			print("Knight parent 1 emerges and starts city patrol!")
		else:
			# Send trainee to training
			send_trainee_to_training(parent1)
			print("Trainee parent 1 heading to training!")
	
	# Release parent 2
	if is_instance_valid(parent2):
		parent2.set_meta("waiting_for_children", false)
		parent2.visible = true
		units_waiting_for_children.erase(parent2)
		
		# Check if this is a Knight (Knights skip training and go straight to patrol)
		if parent2.type == "Knight":
			# Knights need to start patrolling - pick their first target
			if parent2.has_method("pick_random_target"):
				parent2.pick_random_target()
			parent2.is_idle = false
			parent2.is_moving = true
			print("Knight parent 2 emerges and starts city patrol!")
		else:
			# Send trainee to training
			send_trainee_to_training(parent2)
			print("Trainee parent 2 heading to training!")
	
	print("All parents have emerged from the house!")

# NEW: Send a trainee to their assigned training building (called when children are born)
func send_trainee_to_training(trainee):
	if not is_instance_valid(trainee):
		return
	
	# Units with training handle their own arrival and training
	# Just make sure they're moving toward their building
	if trainee.has_meta("training_building"):
		var training_building = trainee.get_meta("training_building")
		if is_instance_valid(training_building):
			trainee.target_position = training_building.global_position
			trainee.is_moving = true
			trainee.is_idle = false
			print("Trainee heading to training building")

# NEW: Find the appropriate training building for a job
func find_training_building(job: String):
	match job:
		"lancer":
			if all_barracks.size() > 0:
				return all_barracks[0]  # Return first barracks
		"archer":
			if all_archeries.size() > 0:
				return all_archeries[0]  # Return first archery
		"monk":
			if all_monasteries.size() > 0:
				return all_monasteries[0]  # Return first monastery
		"knight":
			return null  # Knights don't need training
	
	return null

# NEW: Create a trainee unit (unit that starts in training mode)
func create_trainee_unit(old_pawn, unit_type: String, house, position: Vector2):
	# Remove old pawn from tracking
	all_pawns.erase(old_pawn)
	
	# Create the unit in training mode
	var trainee
	var training_building = find_training_building(unit_type)
	
	match unit_type:
		"lancer":
			trainee = lancer_scene.instantiate()
		"archer":
			trainee = archer_scene.instantiate()
		"monk":
			trainee = monk_scene.instantiate()
		"knight":
			# Knights don't need training - create fully trained
			trainee = knight_scene.instantiate()
			trainee.global_position = position
			if "home" in trainee:
				trainee.home = house
			add_child(trainee)
			old_pawn.queue_free()
			print("Knight created - no training needed!")
			return trainee
		_:
			# Default to knight
			trainee = knight_scene.instantiate()
			trainee.global_position = position
			if "home" in trainee:
				trainee.home = house
			add_child(trainee)
			old_pawn.queue_free()
			print("Knight created (default) - no training needed!")
			return trainee
	
	# Set training metadata BEFORE adding to tree
	trainee.set_meta("in_training", true)
	if training_building:
		trainee.set_meta("training_building", training_building)
		# Set them to walk toward the training building
		trainee.center_position = training_building.global_position
		trainee.circle_radius = 150.0  # Start wandering toward it
	
	# Set position and home
	trainee.global_position = position
	if "home" in trainee:
		trainee.home = house
	
	# Add to scene (this calls _ready())
	add_child(trainee)
	
	# Remove old pawn
	old_pawn.queue_free()
	
	print("Created " + unit_type + " trainee")
	
	return trainee

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
	
	game_time += delta
	update_difficulty()
	
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
	
	print("Building menu opened")

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
	print("Building mode: " + building_type)

func cancel_building_mode():
	if building_mode:
		building_mode = false
		current_building_type = ""
		print("Building cancelled")
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
				has_barracks = true  # Enable lancer
				print("Barracks built! Lancers available")
			"mine":
				building = mine_scene.instantiate()
			"archery":
				building = archery_scene.instantiate()
				has_archery = true  # Enable archer
				print("Archery built! Archers available")
			"monastry":
				building = monastry_scene.instantiate()
				has_monastry = true  # Enable monk
				print("Monastry built! Monks available")
			"tower":
				building = tower_scene.instantiate()
			"wood_tower":
				building = wood_tower_scene.instantiate()
			_:
				building = house_scene.instantiate()
		
		building.position = position
		add_child(building)
		house_positions.append(position)
		
		# Register building for city borders
		register_building(building)
		
		# Register house if it's a house
		if current_building_type == "house":
			register_house(building)
		
		# Register training buildings
		if current_building_type in ["barracks", "archery", "monastry"]:
			register_training_building(building)
				
		print(current_building_type.capitalize() + " placed")
		
		# Exit building mode after placing
		cancel_building_mode()
	else:
		print("Invalid placement!")

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

func create_enemy_spawn_timer():
	enemy_spawn_timer = Timer.new()
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.wait_time = 120.0  # Wait 2 minutes (120 seconds) before first spawn
	enemy_spawn_timer.one_shot = true  # First timer is one-shot
	enemy_spawn_timer.timeout.connect(_on_first_enemy_spawn)
	enemy_spawn_timer.start()
	print("Enemies will start spawning in 2 minutes...")

func _on_first_enemy_spawn():
	print("2 minutes passed - enemy spawning enabled!")
	# Now create the recurring timer
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	enemy_spawn_timer.timeout.disconnect(_on_first_enemy_spawn)
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	enemy_spawn_timer.start()

func _on_enemy_spawn_timer_timeout():
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	var difficulty_level = int(game_time / difficulty_increase_interval)
	
	# Spawn multiple enemies at higher difficulties
	var enemies_to_spawn = 1 + int(difficulty_level / 3)  # 1 enemy at level 0-2, 2 at level 3-5, etc.
	
	for i in range(enemies_to_spawn):
		if current_enemies.size() < max_enemies:
			spawn_random_enemy()
			current_enemies = get_tree().get_nodes_in_group("enemies")  # Update count
			await get_tree().create_timer(0.3).timeout  # Small delay between spawns
	
	var base_wait = randf_range(spawn_interval_min, spawn_interval_max)
	enemy_spawn_timer.wait_time = base_wait * spawn_rate_multiplier

func spawn_random_enemy():
	var goblin = goblin_torch_scene.instantiate()
	var spawn_pos = get_random_edge_position()
	goblin.global_position = spawn_pos
	
	# Set castle position for the goblin
	goblin.castle_position = castle_position
	
	add_child(goblin)
	print("Goblin spawned!")

func get_random_edge_position() -> Vector2:
	var edge = randi() % 4
	var pos = Vector2.ZERO
	
	match edge:
		0:  # Top
			pos = Vector2(
				randf_range(spawn_distance_from_edge, background_width - spawn_distance_from_edge),
				spawn_distance_from_edge
			)
		1:  # Right
			pos = Vector2(
				background_width - spawn_distance_from_edge,
				randf_range(spawn_distance_from_edge, background_height - spawn_distance_from_edge)
			)
		2:  # Bottom
			pos = Vector2(
				randf_range(spawn_distance_from_edge, background_width - spawn_distance_from_edge),
				background_height - spawn_distance_from_edge
			)
		3:  # Left
			pos = Vector2(
				spawn_distance_from_edge,
				randf_range(spawn_distance_from_edge, background_height - spawn_distance_from_edge)
			)
	
	return pos

func update_difficulty():
	# Calculate current difficulty level (every 60 seconds)
	var difficulty_level = int(game_time / difficulty_increase_interval)
	
	# Update spawn rate multiplier (spawns get faster)
	spawn_rate_multiplier = 1.0 / (1.0 + (difficulty_level * 0.15))  # 15% faster each level
	
	# Update max enemies (more enemies can exist at once)
	max_enemies = 20 + (difficulty_level * max_enemies_increase)

func _on_castle_destroyed():
	if game_over:
		return
	
	game_over = true
	print("💀 GAME OVER - Castle Destroyed!")
	
	# Stop enemy spawning
	if enemy_spawn_timer:
		enemy_spawn_timer.stop()
	
	# Stop marriage checking
	if marriage_check_timer:
		marriage_check_timer.stop()
	
	# Stop marriage arrival checking
	if marriage_arrival_check_timer:
		marriage_arrival_check_timer.stop()
	
	# Show game over screen
	show_game_over_screen()

func show_game_over_screen():
	# Create game over panel
	game_over_panel = Panel.new()
	game_over_panel.z_index = 2000
	
	# Panel size
	var panel_size = Vector2(400, 300)
	
	# Center on castle position instead of screen
	if castle and is_instance_valid(castle):
		game_over_panel.global_position = castle.global_position - (panel_size / 2)
	else:
		# Fallback: center on screen
		var viewport_size = get_viewport_rect().size
		game_over_panel.position = (viewport_size - panel_size) / 2
	
	game_over_panel.size = panel_size
	
	# Style the panel
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	stylebox.border_color = Color(0.8, 0.2, 0.2)
	stylebox.set_border_width_all(5)
	stylebox.set_corner_radius_all(10)
	game_over_panel.add_theme_stylebox_override("panel", stylebox)
	
	add_child(game_over_panel)
	
	# Create container for content
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = panel_size - Vector2(40, 40)
	game_over_panel.add_child(vbox)
	
	# Game Over title
	var title_label = Label.new()
	title_label.text = "💀 GAME OVER 💀"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Castle destroyed message
	var message_label = Label.new()
	message_label.text = "Your Castle Has Been Destroyed!"
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(message_label)
	
	# Add spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# Stats
	var stats_label = Label.new()
	var survived_time = int(game_time)
	var minutes = survived_time / 60
	var seconds = survived_time % 60
	var difficulty_level = int(game_time / difficulty_increase_interval)
	
	stats_label.text = "Survived: %d:%02d\nDifficulty Level: %d" % [minutes, seconds, difficulty_level]
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	# Add spacing
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer3)
	
	# Restart button
	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)
	
	# Quit button
	var quit_button = Button.new()
	quit_button.text = "Quit to Menu"
	quit_button.custom_minimum_size = Vector2(200, 50)
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)
	
	# Pause the game
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()
