extends Unit

# Training state
var is_in_training: bool = false
var training_building = null
var training_start_time: float = 0.0
var training_duration: float = 30.0
var has_arrived_at_training: bool = false

func _ready():
	animated_sprite = $LancerSprite
	collision_shape = $LancerCollision
	
	type = "Lancer"
	
	# Check if starting in training mode
	if has_meta("in_training"):
		start_as_trainee()
	else:
		start_as_trained()
	
	center_position = global_position
	
	super._ready()

func start_as_trainee():
	is_in_training = true
	
	# Trainee stats - weaker
	health = 80
	max_health = 80
	attack_damage = 12
	movement_speed = 50.0
	attack_range = 60.0
	detection_range = 180.0
	attack_cooldown = 2.0
	
	# Start at smaller scale
	if animated_sprite:
		animated_sprite.scale = Vector2(0.7, 0.7)
	if collision_shape:
		collision_shape.scale = Vector2(0.7, 0.7)
	
	# Get training building from metadata
	if has_meta("training_building"):
		training_building = get_meta("training_building")
		print("Lancer trainee created - heading to Barracks")
	
	# Longer lifespan during training
	lifespan_min = 200.0
	lifespan_max = 300.0

func start_as_trained():
	is_in_training = false
	
	# Full Lancer stats
	health = 110
	max_health = 110
	attack_damage = 20
	movement_speed = 55.0
	attack_range = 70.0
	detection_range = 220.0
	attack_cooldown = 1.5
	
	lifespan_min = 70.0
	lifespan_max = 100.0
	
	# Full scale
	if animated_sprite:
		animated_sprite.scale = Vector2(1.0, 1.0)
	if collision_shape:
		collision_shape.scale = Vector2(1.0, 1.0)
	
	print("Trained Lancer ready for battle!")

func _physics_process(delta):
	# If in training, handle training logic
	if is_in_training:
		handle_training(delta)
	
	# Call parent physics process
	super._physics_process(delta)

func handle_training(delta):
	# Check if training building still exists
	if not is_instance_valid(training_building):
		print("Training building destroyed! Lancer completes emergency training.")
		complete_training()
		return
	
	# Check if arrived at training building
	if not has_arrived_at_training:
		var distance = global_position.distance_to(training_building.global_position)
		if distance <= 100.0:
			print("Lancer arrived at Barracks - training begins!")
			has_arrived_at_training = true
			training_start_time = Time.get_ticks_msec() / 1000.0
			
			# Set to wander around the building (stay at trainee size)
			center_position = training_building.global_position
			circle_radius = 100.0
			pick_random_target()
	else:
		# Training in progress - check if complete
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed_time = current_time - training_start_time
		
		if elapsed_time >= training_duration:
			print("Lancer training complete!")
			complete_training()

func complete_training():
	is_in_training = false
	has_arrived_at_training = false
	training_building = null
	
	# Upgrade to full stats
	health = 110
	max_health = 110
	attack_damage = 20
	movement_speed = 55.0
	attack_range = 70.0
	detection_range = 220.0
	attack_cooldown = 1.5
	
	lifespan_min = 70.0
	lifespan_max = 100.0
	
	# Scale up to full size
	if animated_sprite:
		animated_sprite.scale = Vector2(1.0, 1.0)
	if collision_shape:
		collision_shape.scale = Vector2(1.0, 1.0)
	
	# Reset lifespan timer with new values
	if lifespan_timer:
		lifespan_timer.stop()
	create_lifespan_timer()
	
	# Set patrol area to entire city
	set_city_patrol_area()
	
	print("Lancer is now fully trained and ready for combat!")

func set_city_patrol_area():
	# Get city borders from main
	var main = get_parent()
	if main and main.has_method("get_city_patrol_position"):
		if main.city_initialized:
			# Set patrol area to city borders
			center_position = main.city_center
			circle_radius = max(
				main.city_border_right - main.city_border_left,
				main.city_border_bottom - main.city_border_top
			) / 2.0
			
			print("Lancer patrolling city - Center: " + str(center_position) + " Radius: " + str(circle_radius))
			
			# Pick first patrol target
			pick_random_target()
		else:
			# City not initialized yet, use home position
			if home and is_instance_valid(home):
				center_position = home.global_position
				circle_radius = 200.0
			print("City not initialized, patrolling around home")
	else:
		# Fallback to home position
		if home and is_instance_valid(home):
			center_position = home.global_position
			circle_radius = 200.0
