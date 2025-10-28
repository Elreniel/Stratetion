extends Unit

# ============================================
# NODE REFERENCES
# ============================================

@onready var animated_monk: AnimatedSprite2D = $MonkSprite
@onready var collision_shape_monk: CollisionShape2D = $MonkCollision

# ============================================
# STRONG PHASE STATS (Fully Trained Monk - Healer/Support)
# ============================================

var strong_health: int = randi_range(130, 170)
var strong_max_health: int = strong_health
var strong_attack_damage: int = randi_range(12, 18)
var strong_movement_speed: float = randf_range(45.0, 55.0)
var strong_attack_range: float = randf_range(45.0, 55.0)
var strong_detection_range: float = randf_range(300.0, 400.0)
var strong_attack_cooldown: float = randf_range(1.2, 1.8)

# Healing stats
var strong_heal_amount: int = randi_range(20, 30)
var strong_heal_range: float = randf_range(55.0, 65.0)
var strong_heal_detection_range: float = randf_range(300.0, 400.0)
var strong_heal_cooldown: float = randf_range(2.5, 3.5)

# ============================================
# WEAK PHASE STATS (Trainee - Randomized Half Range)
# ============================================

var weak_health: int = randi_range(65, 85)
var weak_max_health: int = weak_health
var weak_attack_damage: int = randi_range(6, 9)
var weak_movement_speed: float = randf_range(22.5, 27.5)
var weak_attack_range: float = randf_range(22.5, 27.5)
var weak_detection_range: float = randf_range(150.0, 200.0)
var weak_attack_cooldown: float = randf_range(2.4, 3.6)

# Healing stats (weaker)
var weak_heal_amount: int = randi_range(10, 15)
var weak_heal_range: float = randf_range(27.5, 32.5)
var weak_heal_detection_range: float = randf_range(150.0, 200.0)
var weak_heal_cooldown: float = randf_range(5.0, 7.0)

# ============================================
# TRAINING SETTINGS
# ============================================

var training_duration: float = randf_range(25.0, 35.0)
var training_circle_radius: float = randf_range(90.0, 110.0)
var arrival_distance: float = 100.0
var trainee_scale: Vector2 = Vector2(0.7, 0.7)
var trained_scale: Vector2 = Vector2(1.0, 1.0)

# Lifespan
var monk_lifespan_min: float = randf_range(180.0, 220.0)
var monk_lifespan_max: float = randf_range(280.0, 320.0)

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
# HEALING STATE
# ============================================

var heal_amount: int = 0
var heal_range: float = 0.0
var heal_detection_range: float = 0.0
var heal_cooldown: float = 0.0
var can_heal: bool = true
var is_healing: bool = false
var heal_target = null
var heal_timer: Timer = null
var ally_check_timer: Timer = null

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	animated_sprite = animated_monk
	collision_shape = collision_shape_monk
	type = "Monk"
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
	lifespan_min = monk_lifespan_min
	lifespan_max = monk_lifespan_max
	
	# Apply weak healing stats
	heal_amount = weak_heal_amount
	heal_range = weak_heal_range
	heal_detection_range = weak_heal_detection_range
	heal_cooldown = weak_heal_cooldown
	
	# Trainee appearance
	if animated_sprite:
		animated_sprite.scale = trainee_scale
	if collision_shape:
		collision_shape.scale = trainee_scale
	
	if has_meta("training_building"):
		training_building = get_meta("training_building")
		print("Monk trainee created - heading to Monastery")

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
	lifespan_min = monk_lifespan_min
	lifespan_max = monk_lifespan_max
	
	# Apply strong healing stats
	heal_amount = strong_heal_amount
	heal_range = strong_heal_range
	heal_detection_range = strong_heal_detection_range
	heal_cooldown = strong_heal_cooldown
	
	# Trained appearance
	if animated_sprite:
		animated_sprite.scale = trained_scale
	if collision_shape:
		collision_shape.scale = trained_scale
	
	# Create healing timers
	create_healing_timers()
	
	print("Trained Monk ready for battle!")

# ============================================
# PHYSICS & TRAINING
# ============================================

func _physics_process(delta):
	if is_in_training:
		handle_training(delta)
		return
	
	# Priority 1: Healing injured allies (Monk's primary role)
	if heal_target and is_instance_valid(heal_target):
		handle_healing(delta)
		return
	
	# Priority 2: Combat (only if no one needs healing)
	super._physics_process(delta)

func handle_training(delta):
	if not is_instance_valid(training_building):
		print("Training building destroyed! Monk completes emergency training.")
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
			print("Monk arrived at Monastery - training begins!")
			has_arrived_at_training = true
			training_start_time = Time.get_ticks_msec() / 1000.0
			visible = false
	else:
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed_time = current_time - training_start_time
		
		if elapsed_time >= training_duration:
			print("Monk training complete!")
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
	lifespan_min = monk_lifespan_min
	lifespan_max = monk_lifespan_max
	
	# Apply strong healing stats
	heal_amount = strong_heal_amount
	heal_range = strong_heal_range
	heal_detection_range = strong_heal_detection_range
	heal_cooldown = strong_heal_cooldown
	
	# Scale up to full size
	if animated_sprite:
		animated_sprite.scale = trained_scale
	if collision_shape:
		collision_shape.scale = trained_scale
	
	# Reset lifespan timer
	if lifespan_timer:
		lifespan_timer.stop()
	create_lifespan_timer()
	
	# Create healing timers
	create_healing_timers()
	
	set_city_patrol_area()
	print("Monk is now fully trained and ready for combat!")

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
			
			print("Monk patrolling city - Center: " + str(center_position) + " Radius: " + str(circle_radius))
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

# ============================================
# HEALING SYSTEM
# ============================================

func create_healing_timers():
	# Heal cooldown timer
	heal_timer = Timer.new()
	heal_timer.wait_time = heal_cooldown
	heal_timer.one_shot = true
	heal_timer.timeout.connect(_on_heal_cooldown_finished)
	add_child(heal_timer)
	
	# Check for injured allies periodically
	ally_check_timer = Timer.new()
	ally_check_timer.wait_time = randf_range(0.4, 0.6)
	ally_check_timer.timeout.connect(_check_for_injured_allies)
	add_child(ally_check_timer)
	ally_check_timer.start()

func _check_for_injured_allies():
	# Clear invalid target
	if heal_target and not is_instance_valid(heal_target):
		heal_target = null
	
	# Don't look for new targets if already healing
	if is_healing or not can_heal:
		return
	
	# Find closest injured ally within detection range
	var closest_ally = null
	var closest_distance = heal_detection_range
	var highest_priority = 0.0  # Priority = percentage of health lost
	
	var all_units = get_tree().get_nodes_in_group("units")
	
	for unit in all_units:
		if is_instance_valid(unit) and unit != self:
			# Check if unit is injured
			if unit.health < unit.max_health:
				var distance = global_position.distance_to(unit.global_position)
				if distance < heal_detection_range:
					# Calculate priority (lower health = higher priority)
					var health_percent = float(unit.health) / float(unit.max_health)
					var priority = 1.0 - health_percent
					
					# Prioritize most injured ally
					if priority > highest_priority:
						highest_priority = priority
						closest_distance = distance
						closest_ally = unit
	
	# Update heal target
	if closest_ally:
		heal_target = closest_ally
		print("Monk found injured ally: " + str(heal_target.type) + " (" + str(heal_target.health) + "/" + str(heal_target.max_health) + " HP)")

func handle_healing(delta):
	# Check if heal target is still valid
	if not is_instance_valid(heal_target):
		heal_target = null
		is_healing = false
		return
	
	# Check if target is fully healed
	if heal_target.health >= heal_target.max_health:
		print("Ally fully healed!")
		heal_target = null
		is_healing = false
		return
	
	var distance = global_position.distance_to(heal_target.global_position)
	
	# Target too far, forget it
	if distance > heal_detection_range * 1.5:
		heal_target = null
		is_healing = false
		return
	
	# Move toward injured ally
	if distance > heal_range:
		var direction = (heal_target.global_position - global_position).normalized()
		global_position += direction * movement_speed * delta
		
		# Flip sprite
		if animated_sprite:
			animated_sprite.flip_h = direction.x < 0
			if not is_healing and animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.play("walk")
	else:
		# Close enough to heal
		if can_heal and is_instance_valid(heal_target):
			heal_ally(heal_target)

func heal_ally(target):
	if not can_heal or is_healing or not is_instance_valid(target):
		return
	
	is_healing = true
	can_heal = false
	
	# Play healing animation if it exists (or use attack animation as placeholder)
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	print("Monk heals " + target.type + "!")
	
	# Calculate heal amount (don't overheal)
	var actual_heal = min(heal_amount, target.max_health - target.health)
	target.health += actual_heal
	
	# Visual feedback on healed target
	if target.animated_sprite:
		target.animated_sprite.modulate = Color(0.5, 1.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(target) and is_instance_valid(target.animated_sprite):
			target.animated_sprite.modulate = Color(1, 1, 1)
	
	print("  → " + target.type + " restored " + str(actual_heal) + " HP (" + str(target.health) + "/" + str(target.max_health) + ")")
	
	# Start cooldown
	heal_timer.start()
	
	# Wait for healing animation
	await get_tree().create_timer(0.5).timeout
	is_healing = false
	
	# Clear target if fully healed
	if is_instance_valid(heal_target) and heal_target.health >= heal_target.max_health:
		heal_target = null

func _on_heal_cooldown_finished():
	can_heal = true
