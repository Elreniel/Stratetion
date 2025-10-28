extends Node2D

# ============================================
# SCENE PRELOADS
# ============================================

# Building Scenes
@onready var house_scene = preload("res://scenes/buildings/house.tscn")
@onready var barracks_scene = preload("res://scenes/buildings/barracks.tscn")
@onready var mine_scene = preload("res://scenes/buildings/mine.tscn")
@onready var forest_scene = preload("res://scenes/buildings/forest.tscn")
@onready var archery_scene = preload("res://scenes/buildings/archery.tscn")
@onready var monastry_scene = preload("res://scenes/buildings/monastry.tscn")
@onready var tower_scene = preload("res://scenes/buildings/tower.tscn")
@onready var wood_tower_scene = preload("res://scenes/buildings/wood_tower.tscn")

# Unit Scenes
@onready var pawn_scene = preload("res://scenes/units/pawn.tscn")
@onready var archer_scene = preload("res://scenes/units/archer.tscn")
@onready var lancer_scene = preload("res://scenes/units/lancer.tscn")
@onready var monk_scene = preload("res://scenes/units/monk.tscn")
@onready var knight_scene = preload("res://scenes/units/knight.tscn")

# Enemy Scenes
@onready var goblin_torch_scene = preload("res://scenes/units/goblin_torch.tscn")

# UI Scenes
@onready var building_menu_scene = preload("res://scenes/ui/building_menu.tscn")

# ============================================
# CONFIGURABLE GAME SETTINGS
# ============================================

# Resource Spawn Settings
@export var num_forests: int = randi_range(3, 5)  # Number of forest clusters
@export var trees_per_forest_min: int = 20  # Min trees per forest cluster
@export var trees_per_forest_max: int = 35  # Max trees per forest cluster
@export var tree_spacing_min: float = 30.0  # Min distance between trees in forest
@export var tree_spacing_max: float = 60.0  # Max distance between trees in forest
@export var forest_cluster_radius: float = randf_range(100.0, 150.0)  # Size of forest cluster

@export var num_mines: int = randi_range(3, 5)
@export var resource_min_distance_between: float = randf_range(150.0, 200.0)

# Pawn Spawn Settings
@export var pawn_min_distance: float = randf_range(45.0, 55.0)
@export var pawn_max_distance: float = randf_range(90.0, 110.0)

# Building Placement Settings
@export var min_distance_between_houses: float = randf_range(135.0, 165.0)
var building_edge_margin: float = 100.0

# Background Size
@export var background_width: float
@export var background_height: float

# Marriage System Settings
var marriage_check_interval: float = randf_range(1.8, 2.2)
var marriage_arrival_check_interval: float = randf_range(0.08, 0.12)

# Child Spawning Settings
@export var child_spawn_interval: float = randf_range(0.8, 1.2)

# Training Settings
@export var training_duration: float = randf_range(27.0, 33.0)

# Enemy Spawn Settings
var first_enemy_spawn_delay: float = randf_range(110.0, 130.0)
var spawn_interval_min: float = randf_range(13.0, 17.0)
var spawn_interval_max: float = randf_range(23.0, 27.0)
var spawn_distance_from_edge: float = randf_range(90.0, 110.0)
var initial_max_enemies: int = randi_range(18, 22)
var enemy_spawn_delay_between: float = randf_range(0.25, 0.35)

# Difficulty Scaling Settings
var difficulty_increase_interval: float = randf_range(55.0, 65.0)
var spawn_rate_increase_per_level: float = randf_range(0.13, 0.17)
var max_enemies_increase: int = 2
var enemies_per_difficulty_tier: int = 3

# City Border Settings
var city_border_padding: float = randf_range(135.0, 165.0)

# Game Over UI Settings
var game_over_panel_size: Vector2 = Vector2(400, 300)

# ============================================
# NODE REFERENCES
# ============================================

@onready var main_background: ColorRect = $Background

# ============================================
# BUILDING MODE STATE
# ============================================

var building_mode: bool = false
var building_preview = null
var current_building_type: String = ""
var active_menu = null

# ============================================
# GAME STATE
# ============================================

var game_over: bool = false
var game_time: float = 0.0
var spawn_rate_multiplier: float = 1.0
var max_enemies: int = initial_max_enemies

# ============================================
# POSITION TRACKING
# ============================================

var castle_position: Vector2 = Vector2.ZERO
var house_positions: Array[Vector2] = []

# City Borders
var city_border_left: float = 0.0
var city_border_right: float = 0.0
var city_border_top: float = 0.0
var city_border_bottom: float = 0.0
var city_center: Vector2 = Vector2.ZERO
var city_initialized: bool = false

# ============================================
# ENTITY TRACKING ARRAYS
# ============================================

# Units
var all_pawns: Array = []
var units_waiting_for_children: Array = []

# Buildings
var all_houses: Array = []
var all_barracks: Array = []
var all_archeries: Array = []
var all_monasteries: Array = []
var all_buildings: Array = []

# Building Availability
var has_barracks: bool = false
var has_archery: bool = false
var has_monastry: bool = false

# Marriage System
var pending_marriages: Array = []

# Resource positions
var forest_cluster_positions: Array[Vector2] = []  # Center positions of forest clusters
var all_tree_positions: Array[Vector2] = []  # Individual tree positions
var mine_positions: Array[Vector2] = []

# ============================================
# TIMERS
# ============================================

var marriage_check_timer: Timer
var marriage_arrival_check_timer: Timer
var enemy_spawn_timer: Timer = null

# ============================================
# REFERENCES
# ============================================

var castle = null
var camera: Camera2D

# UI References
var game_over_panel: Panel = null
var game_over_label: Label = null

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	castle = get_node_or_null("Castle")
	if castle:
		castle_position = castle.global_position
		castle.castle_destroyed.connect(_on_castle_destroyed)
		print("Castle defended at " + str(castle_position))
	else:
		castle_position = Vector2(background_width / 2, background_height / 2)
		print("No castle found, using center position")
	
	background_width = main_background.size.x
	background_height = main_background.size.y
	camera = get_viewport().get_camera_2d()
	
	print("Press 'B' to open building menu!")
	print("Press 'ESC' to cancel building")
	
	create_marriage_check_timer()
	create_marriage_arrival_check_timer()
	
	call_deferred("_register_existing_pawns")
	call_deferred("_register_existing_houses")
	call_deferred("_register_existing_training_buildings")
	call_deferred("_register_existing_buildings")
	call_deferred("spawn_initial_resources")
	
	create_enemy_spawn_timer()

func create_marriage_check_timer():
	marriage_check_timer = Timer.new()
	marriage_check_timer.wait_time = marriage_check_interval
	marriage_check_timer.timeout.connect(_check_for_marriages)
	add_child(marriage_check_timer)
	marriage_check_timer.start()

func create_marriage_arrival_check_timer():
	marriage_arrival_check_timer = Timer.new()
	marriage_arrival_check_timer.wait_time = marriage_arrival_check_interval
	marriage_arrival_check_timer.timeout.connect(_check_marriage_arrivals)
	add_child(marriage_arrival_check_timer)
	marriage_arrival_check_timer.start()

# ============================================
# REGISTRATION SYSTEM
# ============================================

func _register_existing_pawns():
	for child in get_children():
		if child.is_in_group("pawns"):
			register_pawn(child)

func _register_existing_houses():
	for child in get_children():
		if child.is_in_group("houses"):
			register_house(child)

func _register_existing_training_buildings():
	for child in get_children():
		if child.is_in_group("barracks") or child.is_in_group("archery") or child.is_in_group("monastry"):
			register_training_building(child)

func _register_existing_buildings():
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
	if building not in all_buildings:
		all_buildings.append(building)
		calculate_city_borders()
		print("Building registered. Total buildings: " + str(all_buildings.size()))

# ============================================
# CITY BORDER CALCULATION
# ============================================

func calculate_city_borders():
	if all_buildings.size() == 0:
		return
	
	var first_building = all_buildings[0]
	city_border_left = first_building.global_position.x
	city_border_right = first_building.global_position.x
	city_border_top = first_building.global_position.y
	city_border_bottom = first_building.global_position.y
	
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
	
	city_border_left -= city_border_padding
	city_border_right += city_border_padding
	city_border_top -= city_border_padding
	city_border_bottom += city_border_padding
	
	city_center = Vector2(
		(city_border_left + city_border_right) / 2,
		(city_border_top + city_border_bottom) / 2
	)
	
	city_initialized = true
	print("City borders updated - Center: " + str(city_center))

func get_city_patrol_position() -> Vector2:
	if city_initialized:
		return city_center
	return castle_position

# ============================================
# GAME LOOP
# ============================================

func _process(delta):
	if game_over:
		return
	
	game_time += delta
	update_difficulty()
	
	if building_mode and building_preview:
		var mouse_pos = get_global_mouse_position()
		building_preview.global_position = mouse_pos
		
		if is_valid_building_position(mouse_pos):
			building_preview.modulate = Color(0.5, 1, 0.5, 0.7)
		else:
			building_preview.modulate = Color(1, 0.5, 0.5, 0.7)

func _input(event):
	if game_over:
		return
	
	if event.is_action_pressed("ui_cancel"):
		cancel_building_mode()
	
	# Check for 'B' key press to toggle building menu
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle_building_menu()
	
	if building_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			if is_valid_building_position(mouse_pos):
				place_building(mouse_pos)

# ============================================
# BUILDING MENU SYSTEM
# ============================================

func toggle_building_menu():
	if active_menu:
		close_building_menu()
	else:
		open_building_menu()

func open_building_menu():
	if active_menu:
		return
	
	active_menu = building_menu_scene.instantiate()
	add_child(active_menu)
	
	# Position menu at mouse cursor
	var mouse_pos = get_global_mouse_position()
	active_menu.global_position = mouse_pos - Vector2(150, 150)  # Center the 300x300 menu on cursor
	
	active_menu.building_selected.connect(_on_building_selected)
	
	print("Building menu opened")

func close_building_menu():
	if active_menu:
		active_menu.queue_free()
		active_menu = null
		print("Building menu closed")

func _on_building_selected(building_type: String):
	print("Building selected: " + building_type)
	
	# Capitalize first letter to match scene loading
	var capitalized_type = building_type.capitalize()
	
	start_building_mode(capitalized_type)
	close_building_menu()

# ============================================
# BUILDING MODE SYSTEM
# ============================================

func start_building_mode(building_type: String):
	current_building_type = building_type
	building_mode = true
	
	var scene_to_load = null
	match building_type:
		"House":
			scene_to_load = house_scene
		"Barracks", "Barrack":
			scene_to_load = barracks_scene
		"Mine":
			scene_to_load = mine_scene
		"Archery":
			scene_to_load = archery_scene
		"Monastery", "Monastry":
			scene_to_load = monastry_scene
		"Tower":
			scene_to_load = tower_scene
		"Wood Tower":
			scene_to_load = wood_tower_scene
	
	if scene_to_load:
		building_preview = scene_to_load.instantiate()
		building_preview.modulate = Color(0.5, 1, 0.5, 0.7)
		add_child(building_preview)
		print("Building mode started: " + building_type)
	else:
		print("ERROR: Unknown building type: " + building_type)
		building_mode = false

func cancel_building_mode():
	if building_mode:
		building_mode = false
		if building_preview:
			building_preview.queue_free()
			building_preview = null
		current_building_type = ""
		print("Building mode cancelled")

func place_building(position: Vector2):
	if not building_mode or not building_preview:
		return
	
	building_preview.modulate = Color(1, 1, 1, 1)
	building_preview.global_position = position
	
	# Normalize building type for comparison
	var normalized_type = current_building_type.capitalize()
	
	if normalized_type == "House":
		house_positions.append(position)
		register_house(building_preview)
	
	if normalized_type == "Barracks" or normalized_type == "Barrack":
		has_barracks = true
		register_training_building(building_preview)
	elif normalized_type == "Archery":
		has_archery = true
		register_training_building(building_preview)
	elif normalized_type == "Monastery" or normalized_type == "Monastry":
		has_monastry = true
		register_training_building(building_preview)
	
	register_building(building_preview)
	
	print(current_building_type + " placed at " + str(position))
	
	building_preview = null
	building_mode = false
	current_building_type = ""

func is_valid_building_position(position: Vector2) -> bool:
	if position.x < building_edge_margin or position.x > background_width - building_edge_margin:
		return false
	if position.y < building_edge_margin or position.y > background_height - building_edge_margin:
		return false
	
	for existing_position in house_positions:
		var distance = position.distance_to(existing_position)
		if distance < min_distance_between_houses:
			return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	
	if result.size() > 0:
		for collision in result:
			var collider = collision.collider
			if collider != building_preview and collider.get_parent() != building_preview:
				return false
	
	return true

# ============================================
# MARRIAGE SYSTEM
# ============================================

func _check_for_marriages():
	var available_houses = []
	for house in all_houses:
		if is_instance_valid(house) and not house.is_occupied:
			available_houses.append(house)
	
	if available_houses.size() == 0:
		return
	
	var single_pawns = []
	for pawn in all_pawns:
		if is_instance_valid(pawn) and pawn.type == "Single":
			var already_in_marriage = false
			for marriage in pending_marriages:
				if marriage.pawn1 == pawn or marriage.pawn2 == pawn:
					already_in_marriage = true
					break
			
			if not already_in_marriage:
				single_pawns.append(pawn)
	
	if single_pawns.size() < 2:
		return
	
	single_pawns.shuffle()
	var pawn1 = single_pawns[0]
	var pawn2 = single_pawns[1]
	var chosen_house = available_houses[randi() % available_houses.size()]
	
	chosen_house.is_occupied = true
	
	pending_marriages.append({
		"pawn1": pawn1,
		"pawn2": pawn2,
		"house": chosen_house,
		"pawn1_arrived": false,
		"pawn2_arrived": false
	})
	
	pawn1.type = "Married"
	pawn2.type = "Married"
	
	# Set metadata to keep them waiting at the house
	pawn1.set_meta("waiting_for_marriage", true)
	pawn2.set_meta("waiting_for_marriage", true)
	
	pawn1.target_position = chosen_house.global_position
	pawn2.target_position = chosen_house.global_position
	pawn1.is_moving = true
	pawn2.is_moving = true
	
	print("💑 Marriage arranged! Pawns heading to house at " + str(chosen_house.global_position))

func _check_marriage_arrivals():
	for i in range(pending_marriages.size() - 1, -1, -1):
		var marriage = pending_marriages[i]
		
		# Check if house was destroyed - reassign to another available house
		if not is_instance_valid(marriage.house):
			print("⚠️ Marriage house destroyed! Looking for another house...")
			var available_houses = []
			for house in all_houses:
				if is_instance_valid(house) and not house.is_occupied:
					available_houses.append(house)
			
			if available_houses.size() > 0:
				# Assign new house
				var new_house = available_houses[randi() % available_houses.size()]
				new_house.is_occupied = true
				marriage.house = new_house
				marriage.pawn1.target_position = new_house.global_position
				marriage.pawn2.target_position = new_house.global_position
				marriage.pawn1.is_moving = true
				marriage.pawn2.is_moving = true
				print("✅ New house assigned at " + str(new_house.global_position))
			else:
				# No houses available, cancel marriage
				print("❌ No houses available, marriage cancelled")
				if is_instance_valid(marriage.pawn1):
					marriage.pawn1.type = "Single"
					marriage.pawn1.set_meta("waiting_for_marriage", false)
				if is_instance_valid(marriage.pawn2):
					marriage.pawn2.type = "Single"
					marriage.pawn2.set_meta("waiting_for_marriage", false)
				pending_marriages.remove_at(i)
			continue
		
		if not is_instance_valid(marriage.pawn1) or not is_instance_valid(marriage.pawn2):
			print("DEBUG: Marriage cancelled - invalid pawn")
			pending_marriages.remove_at(i)
			if is_instance_valid(marriage.house):
				marriage.house.is_occupied = false
			continue
		
		var distance1 = marriage.pawn1.global_position.distance_to(marriage.house.global_position)
		var distance2 = marriage.pawn2.global_position.distance_to(marriage.house.global_position)
		
		# Only use distance check (removed "or not is_moving" check)
		var arrival_threshold = 50.0
		
		if distance1 < arrival_threshold and not marriage.pawn1_arrived:
			marriage.pawn1_arrived = true
			marriage.pawn1.is_moving = false
			marriage.pawn1.target_position = marriage.house.global_position
			print("Pawn 1 arrived at house! (distance: " + str(int(distance1)) + ")")
		
		if distance2 < arrival_threshold and not marriage.pawn2_arrived:
			marriage.pawn2_arrived = true
			marriage.pawn2.is_moving = false
			marriage.pawn2.target_position = marriage.house.global_position
			print("Pawn 2 arrived at house! (distance: " + str(int(distance2)) + ")")
		
		if marriage.pawn1_arrived and marriage.pawn2_arrived:
			print("💕 Both pawns arrived! Starting family...")
			complete_marriage(marriage)
			pending_marriages.remove_at(i)

func complete_marriage(marriage):
	var house = marriage["house"]
	var pawn1 = marriage["pawn1"]
	var pawn2 = marriage["pawn2"]
	
	if not is_instance_valid(house) or not is_instance_valid(pawn1) or not is_instance_valid(pawn2):
		return
	
	# Clear marriage waiting state
	pawn1.set_meta("waiting_for_marriage", false)
	pawn2.set_meta("waiting_for_marriage", false)
	
	# DON'T teleport - pawns are already at the house from walking
	# Just make them invisible
	pawn1.visible = false
	pawn2.visible = false
	
	house.add_family(pawn1, pawn2)
	
	pawn1.home = house
	pawn2.home = house
	pawn1.center_position = house.global_position
	pawn2.center_position = house.global_position
	pawn1.circle_radius = 100
	pawn2.circle_radius = 100
	
	pawn1.set_meta("waiting_for_children", true)
	pawn2.set_meta("waiting_for_children", true)
	
	units_waiting_for_children.append(pawn1)
	units_waiting_for_children.append(pawn2)
	
	# Store initial house health to detect if under attack
	house.set_meta("initial_health_for_birth", house.health)
	
	spawn_children(house, pawn1, pawn2)

func spawn_children(house, parent1, parent2):
	var num_children = randi_range(3, 5)
	print("👶 Spawning " + str(num_children) + " children...")
	
	var initial_house_health = house.get_meta("initial_health_for_birth") if house.has_meta("initial_health_for_birth") else house.health
	
	for i in range(num_children):
		await get_tree().create_timer(child_spawn_interval).timeout
		
		# Check if house is destroyed
		if not is_instance_valid(house):
			print("🏠 House destroyed during birth! Stopping child generation.")
			# Make parents visible and free
			if is_instance_valid(parent1):
				parent1.visible = true
				parent1.set_meta("waiting_for_children", false)
				if parent1 in units_waiting_for_children:
					units_waiting_for_children.erase(parent1)
			if is_instance_valid(parent2):
				parent2.visible = true
				parent2.set_meta("waiting_for_children", false)
				if parent2 in units_waiting_for_children:
					units_waiting_for_children.erase(parent2)
			return
		
		# Check if house is under attack (health decreased)
		if house.health < initial_house_health:
			print("⚔️ House under attack! Birth process interrupted.")
			# Make parents visible and free
			if is_instance_valid(parent1):
				parent1.visible = true
				parent1.set_meta("waiting_for_children", false)
				if parent1 in units_waiting_for_children:
					units_waiting_for_children.erase(parent1)
			if is_instance_valid(parent2):
				parent2.visible = true
				parent2.set_meta("waiting_for_children", false)
				if parent2 in units_waiting_for_children:
					units_waiting_for_children.erase(parent2)
			return
		
		# Check if parents are still valid
		if not is_instance_valid(parent1) or not is_instance_valid(parent2):
			print("Parents no longer valid, stopping child spawn")
			return
		
		# Spawn baby pawn
		var baby = pawn_scene.instantiate()
		var spawn_offset = Vector2(randf_range(-pawn_max_distance, pawn_max_distance), randf_range(-pawn_max_distance, pawn_max_distance))
		baby.global_position = house.global_position + spawn_offset
		baby.home = house
		baby.center_position = house.global_position
		baby.circle_radius = 100
		
		add_child(baby)
		register_pawn(baby)
		print("👶 Baby pawn spawned! (" + str(i + 1) + "/" + str(num_children) + ")")
	
	print("✅ All children spawned! Parents picking jobs...")
	
	# Make parents visible and assign them jobs
	if is_instance_valid(parent1):
		parent1.visible = true
		parent1.set_meta("waiting_for_children", false)
		if parent1 in units_waiting_for_children:
			units_waiting_for_children.erase(parent1)
		assign_parent_job(parent1, house)
	
	if is_instance_valid(parent2):
		parent2.visible = true
		parent2.set_meta("waiting_for_children", false)
		if parent2 in units_waiting_for_children:
			units_waiting_for_children.erase(parent2)
		assign_parent_job(parent2, house)

func assign_parent_job(pawn, house):
	# Build job list based on available buildings
	var job_types = ["Knight"]  # Knight is always available
	if has_barracks:
		job_types.append("Lancer")
	if has_monastry:
		job_types.append("Monk")
	if has_archery:
		job_types.append("Archer")
	
	# Randomly pick from available jobs
	var chosen_job = job_types[randi() % job_types.size()]
	
	print("👔 Parent getting job: " + chosen_job + " (Available jobs: " + str(job_types) + ")")
	
	# Get the spawn position BEFORE removing the pawn
	var spawn_position = pawn.global_position
	
	# Remove the old pawn
	pawn.queue_free()
	
	match chosen_job:
		"Knight":
			# Knights don't need training - spawn directly as full units
			var knight = knight_scene.instantiate()
			knight.global_position = spawn_position
			knight.home = house
			add_child(knight)
			print("⚔️ Parent became a Knight!")
		
		"Lancer":
			# Lancers need training at Barracks
			if all_barracks.size() > 0:
				var training_building = all_barracks[randi() % all_barracks.size()]
				if is_instance_valid(training_building):
					var lancer = lancer_scene.instantiate()
					lancer.global_position = spawn_position  # Spawn at house position
					lancer.set_meta("in_training", true)
					lancer.set_meta("training_building", training_building)
					lancer.home = house  # ← Changed from training_building to house
					add_child(lancer)
					print("🗡️ Parent became a Lancer trainee!")
		
		"Monk":
			# Monks need training at Monastery
			if all_monasteries.size() > 0:
				var training_building = all_monasteries[randi() % all_monasteries.size()]
				if is_instance_valid(training_building):
					var monk = monk_scene.instantiate()
					monk.global_position = spawn_position  # Spawn at house position
					monk.set_meta("in_training", true)
					monk.set_meta("training_building", training_building)
					monk.home = house  # ← Changed from training_building to house
					add_child(monk)
					print("🙏 Parent became a Monk trainee!")
		
		"Archer":
			# Archers need training at Archery
			if all_archeries.size() > 0:
				var training_building = all_archeries[randi() % all_archeries.size()]
				if is_instance_valid(training_building):
					var archer = archer_scene.instantiate()
					archer.global_position = spawn_position  # Spawn at house position
					archer.set_meta("in_training", true)
					archer.set_meta("training_building", training_building)
					archer.home = house  # ← Changed from training_building to house
					add_child(archer)
					print("🏹 Parent became an Archer trainee!")

# ============================================
# TRAINING SYSTEM
# ============================================

func spawn_training_unit(unit_type: String, training_building):
	var unit_scene = null
	var unit_name = ""
	
	match unit_type:
		"Lancer":
			unit_scene = lancer_scene
			unit_name = "Lancer"
		"Archer":
			unit_scene = archer_scene
			unit_name = "Archer"
		"Monk":
			unit_scene = monk_scene
			unit_name = "Monk"
	
	if not unit_scene or not is_instance_valid(training_building):
		return
	
	var unit = unit_scene.instantiate()
	var spawn_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
	unit.global_position = training_building.global_position + spawn_offset
	unit.set_meta("in_training", true)
	unit.set_meta("training_building", training_building)
	
	# Set home to the training building for now
	unit.home = training_building
	
	add_child(unit)
	print(unit_name + " trainee spawned near " + training_building.building_type)

# ============================================
# ENEMY SPAWN SYSTEM
# ============================================

func create_enemy_spawn_timer():
	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.wait_time = first_enemy_spawn_delay
	enemy_spawn_timer.one_shot = true
	enemy_spawn_timer.timeout.connect(_on_first_enemy_spawn)
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()
	print("Enemies will start spawning in " + str(int(first_enemy_spawn_delay)) + " seconds...")

func _on_first_enemy_spawn():
	print("Enemy spawning enabled!")
	enemy_spawn_timer.one_shot = false
	enemy_spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	enemy_spawn_timer.timeout.disconnect(_on_first_enemy_spawn)
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	enemy_spawn_timer.start()

func _on_enemy_spawn_timer_timeout():
	var current_enemies = get_tree().get_nodes_in_group("enemies")
	var difficulty_level = int(game_time / difficulty_increase_interval)
	
	var enemies_to_spawn = 1 + int(difficulty_level / enemies_per_difficulty_tier)
	
	for i in range(enemies_to_spawn):
		if current_enemies.size() < max_enemies:
			spawn_random_enemy()
			current_enemies = get_tree().get_nodes_in_group("enemies")
			await get_tree().create_timer(enemy_spawn_delay_between).timeout
	
	var base_wait = randf_range(spawn_interval_min, spawn_interval_max)
	enemy_spawn_timer.wait_time = base_wait * spawn_rate_multiplier

func spawn_random_enemy():
	var goblin = goblin_torch_scene.instantiate()
	var spawn_pos = get_random_edge_position()
	goblin.global_position = spawn_pos
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

# ============================================
# DIFFICULTY SYSTEM
# ============================================

func update_difficulty():
	var difficulty_level = int(game_time / difficulty_increase_interval)
	spawn_rate_multiplier = 1.0 / (1.0 + (difficulty_level * spawn_rate_increase_per_level))
	max_enemies = initial_max_enemies + (difficulty_level * max_enemies_increase)

# ============================================
# GAME OVER SYSTEM
# ============================================

func _on_castle_destroyed():
	if game_over:
		return
	
	game_over = true
	print("💀 GAME OVER - Castle Destroyed!")
	
	if enemy_spawn_timer:
		enemy_spawn_timer.stop()
	if marriage_check_timer:
		marriage_check_timer.stop()
	if marriage_arrival_check_timer:
		marriage_arrival_check_timer.stop()
	
	show_game_over_screen()

func show_game_over_screen():
	game_over_panel = Panel.new()
	game_over_panel.z_index = 2000
	
	if castle and is_instance_valid(castle):
		game_over_panel.global_position = castle.global_position - (game_over_panel_size / 2)
	else:
		var viewport_size = get_viewport_rect().size
		game_over_panel.position = (viewport_size - game_over_panel_size) / 2
	
	game_over_panel.size = game_over_panel_size
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	stylebox.border_color = Color(0.8, 0.2, 0.2)
	stylebox.set_border_width_all(5)
	stylebox.set_corner_radius_all(10)
	game_over_panel.add_theme_stylebox_override("panel", stylebox)
	
	add_child(game_over_panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = game_over_panel_size - Vector2(40, 40)
	game_over_panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "💀 GAME OVER 💀"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	var message_label = Label.new()
	message_label.text = "Your Castle Has Been Destroyed!"
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(message_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
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
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer3)
	
	var restart_button = Button.new()
	restart_button.text = "Restart Game"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)
	
	var quit_button = Button.new()
	quit_button.text = "Quit to Menu"
	quit_button.custom_minimum_size = Vector2(200, 50)
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)
	
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().quit()
	
# ============================================
# RESOURCE SPAWNING SYSTEM
# ============================================

func spawn_initial_resources():
	print("Spawning initial resources around map...")
	
	# Spawn forest clusters
	for i in range(num_forests):
		var forest_center = get_random_map_position(forest_cluster_positions)
		if forest_center != Vector2.ZERO:
			spawn_forest_cluster(forest_center)
			await get_tree().create_timer(0.1).timeout
	
	# Spawn mines scattered around map
	for i in range(num_mines):
		var mine_position = get_random_map_position(mine_positions)
		if mine_position != Vector2.ZERO:
			spawn_mine(mine_position)
			await get_tree().create_timer(0.05).timeout
	
	print("Resource spawning complete!")

func get_random_map_position(existing_positions: Array[Vector2]) -> Vector2:
	var max_attempts = 100
	var attempts = 0
	
	while attempts < max_attempts:
		# Random position anywhere on the map
		var test_position = Vector2(
			randf_range(building_edge_margin, background_width - building_edge_margin),
			randf_range(building_edge_margin, background_height - building_edge_margin)
		)
		
		# Check distance from castle (don't spawn too close to castle)
		var min_distance_from_castle = 200.0
		if test_position.distance_to(castle_position) < min_distance_from_castle:
			attempts += 1
			continue
		
		# Check distance from existing forest clusters
		var too_close = false
		for existing_pos in existing_positions:
			if test_position.distance_to(existing_pos) < resource_min_distance_between:
				too_close = true
				break
		
		if too_close:
			attempts += 1
			continue
		
		# Check distance from all forest clusters
		for forest_pos in forest_cluster_positions:
			if test_position.distance_to(forest_pos) < resource_min_distance_between:
				too_close = true
				break
		
		if too_close:
			attempts += 1
			continue
		
		# Check distance from all mines
		for mine_pos in mine_positions:
			if test_position.distance_to(mine_pos) < resource_min_distance_between:
				too_close = true
				break
		
		if too_close:
			attempts += 1
			continue
		
		# Valid position found
		return test_position
	
	print("Warning: Could not find valid position for resource after " + str(max_attempts) + " attempts")
	return Vector2.ZERO

func spawn_forest_cluster(center_position: Vector2):
	var num_trees = randi_range(trees_per_forest_min, trees_per_forest_max)
	
	print("Spawning forest cluster with " + str(num_trees) + " trees at " + str(center_position))
	
	# Save cluster center position
	forest_cluster_positions.append(center_position)
	
	# Spawn multiple individual trees to form a forest
	for i in range(num_trees):
		# Random position within the forest cluster radius
		var angle = randf() * TAU
		var distance = randf() * forest_cluster_radius
		
		var tree_position = center_position + Vector2(
			cos(angle) * distance,
			sin(angle) * distance
		)
		
		# Make sure tree is still within bounds
		tree_position.x = clamp(tree_position.x, building_edge_margin, background_width - building_edge_margin)
		tree_position.y = clamp(tree_position.y, building_edge_margin, background_height - building_edge_margin)
		
		# Check if this tree is too close to other trees (avoid overlap)
		var too_close = false
		for existing_tree_pos in all_tree_positions:
			if tree_position.distance_to(existing_tree_pos) < tree_spacing_min:
				too_close = true
				break
		
		if not too_close:
			spawn_single_tree(tree_position)

func spawn_single_tree(position: Vector2):
	var tree = forest_scene.instantiate()
	tree.global_position = position
		
	# Random scale variation for more natural look
	var scale_variation = randf_range(0.85, 1.15)
	tree.scale = Vector2(scale_variation, scale_variation)
	
	add_child(tree)
	
	all_tree_positions.append(position)

func spawn_mine(position: Vector2):
	var mine = mine_scene.instantiate()
	mine.global_position = position
	add_child(mine)
	mine_positions.append(position)
	print("Mine spawned at " + str(position))
