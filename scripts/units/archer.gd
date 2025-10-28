extends Unit

# ============================================
# NODE REFERENCES
# ============================================

@onready var animated_archer: AnimatedSprite2D = $ArcherSprite
@onready var collision_shape_archer: CollisionShape2D = $ArcherCollision

# ============================================
# STRONG PHASE STATS (Fully Trained Archer - Long Range, Fast Attacks)
# ============================================

var strong_health: int = randi_range(85, 115)
var strong_max_health: int = strong_health
var strong_attack_damage: int = randi_range(17, 23)
var strong_movement_speed: float = randf_range(45.0, 55.0)
var strong_attack_range: float = randf_range(225.0, 275.0)
var strong_detection_range: float = randf_range(350.0, 450.0)
var strong_attack_cooldown: float = randf_range(0.8, 1.2)

# ============================================
# WEAK PHASE STATS (Trainee - Randomized Half Range)
# ============================================

var weak_health: int = randi_range(42, 57)
var weak_max_health: int = weak_health
var weak_attack_damage: int = randi_range(8, 11)
var weak_movement_speed: float = randf_range(22.5, 27.5)
var weak_attack_range: float = randf_range(90.0, 110.0)
var weak_detection_range: float = randf_range(175.0, 225.0)
var weak_attack_cooldown: float = randf_range(1.6, 2.4)

# ============================================
# TRAINING SETTINGS
# ============================================

var training_duration: float = randf_range(25.0, 35.0)
var training_circle_radius: float = randf_range(90.0, 110.0)
var arrival_distance: float = 100.0
var trainee_scale: Vector2 = Vector2(0.7, 0.7)
var trained_scale: Vector2 = Vector2(1.0, 1.0)

# Lifespan
var archer_lifespan_min: float = randf_range(180.0, 220.0)
var archer_lifespan_max: float = randf_range(280.0, 320.0)

# Patrol settings
var default_patrol_radius: float = randf_range(180.0, 220.0)

# ============================================
# TRAINING STATE
# ============================================

var is_in_training: bool = false
var training_building = null
var training_start_time: float = 0.0
var has_arrived_at_training: bool = false

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	animated_sprite = animated_archer
	collision_shape = collision_shape_archer
	type = "Archer"
	center_position = global_position
	
	if has_meta("in_training"):
		start_as_trainee()
	else:
		start_as_trained()
	
	super._ready()

func start_as_trainee():
	is_in_training = true
	
	# Apply weak phase stats
	health = weak_health
	max_health = weak_max_health
	attack_damage = weak_attack_damage
	movement_speed = weak_movement_speed
	attack_range = weak_attack_range
	detection_range = weak_detection_range
	attack_cooldown = weak_attack_cooldown
	lifespan_min = archer_lifespan_min
	lifespan_max = archer_lifespan_max
	
	# Trainee appearance
	if animated_sprite:
		animated_sprite.scale = trainee_scale
	if collision_shape:
		collision_shape.scale = trainee_scale
	
	if has_meta("training_building"):
		training_building = get_meta("training_building")
		print("Archer trainee created - heading to Archery")

func start_as_trained():
	is_in_training = false
	
	# Apply strong phase stats
	health = strong_health
	max_health = strong_max_health
	attack_damage = strong_attack_damage
	movement_speed = strong_movement_speed
	attack_range = strong_attack_range
	detection_range = strong_detection_range
	attack_cooldown = strong_attack_cooldown
	lifespan_min = archer_lifespan_min
	lifespan_max = archer_lifespan_max
	
	# Trained appearance
	if animated_sprite:
		animated_sprite.scale = trained_scale
	if collision_shape:
		collision_shape.scale = trained_scale
	
	print("Trained Archer ready for battle!")

# ============================================
# PHYSICS & TRAINING
# ============================================

func _physics_process(delta):
	if is_in_training:
		handle_training(delta)
		return
	super._physics_process(delta)

func handle_training(delta):
	if not is_instance_valid(training_building):
		print("Training building destroyed! Archer completes emergency training.")
		complete_training()
		return
	
	if not has_arrived_at_training:
		var distance = global_position.distance_to(training_building.global_position)
		
		# Move toward the training building
		if distance > arrival_distance:
			var direction = (training_building.global_position - global_position).normalized()
			global_position += direction * movement_speed * delta
			
			# Flip sprite and play walk animation
			if animated_sprite:
				animated_sprite.flip_h = direction.x < 0
				if animated_sprite.sprite_frames.has_animation("walk"):
					animated_sprite.play("walk")
		else:
			# Arrived at training building
			print("Archer arrived at Archery - training begins!")
			has_arrived_at_training = true
			visible = false
			training_start_time = Time.get_ticks_msec() / 1000.0
			
	else:
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed_time = current_time - training_start_time
		
		if elapsed_time >= training_duration:
			print("Archer training complete!")
			complete_training()

func complete_training():
	is_in_training = false
	has_arrived_at_training = false
	training_building = null
	visible = true
	
	# Apply strong phase stats
	health = strong_health
	max_health = strong_max_health
	attack_damage = strong_attack_damage
	movement_speed = strong_movement_speed
	attack_range = strong_attack_range
	detection_range = strong_detection_range
	attack_cooldown = strong_attack_cooldown
	lifespan_min = archer_lifespan_min
	lifespan_max = archer_lifespan_max
	
	# Scale up to full size
	if animated_sprite:
		animated_sprite.scale = trained_scale
	if collision_shape:
		collision_shape.scale = trained_scale
	
	# Reset lifespan timer
	if lifespan_timer:
		lifespan_timer.stop()
	create_lifespan_timer()
	
	set_city_patrol_area()
	print("Archer is now fully trained and ready for combat!")

# ============================================
# CITY PATROL SYSTEM
# ============================================

func set_city_patrol_area():
	var main = get_parent()
	
	if main and main.has_method("get_city_patrol_position"):
		if main.city_initialized:
			center_position = main.city_center
			circle_radius = max(
				main.city_border_right - main.city_border_left,
				main.city_border_bottom - main.city_border_top
			) / 2.0
			
			print("Archer patrolling city - Center: " + str(center_position) + " Radius: " + str(circle_radius))
			pick_random_target()
		else:
			set_home_patrol()
	else:
		set_home_patrol()

func set_home_patrol():
	if home and is_instance_valid(home):
		center_position = home.global_position
		circle_radius = default_patrol_radius
		print("City not initialized, patrolling around home")
