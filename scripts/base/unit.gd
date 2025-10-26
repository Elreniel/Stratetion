class_name Unit
extends StaticBody2D

# References
var animated_sprite: AnimatedSprite2D = null
var collision_shape: CollisionShape2D = null

# Base properties
var type: String = "Unit"
var home = null
var health: int = 100
var max_health: int = 100
var attack_damage: int = 10
var movement_speed: float = 50.0

# Movement properties
var target_position = Vector2.ZERO
var circle_radius = 200.0
var center_position = Vector2.ZERO
var is_moving = false
var is_idle = false

# Combat properties
var attack_range: float = 50.0
var detection_range: float = 200.0
var can_attack_enemies: bool = true
var enemy_target = null
var is_attacking: bool = false
var can_attack: bool = true
var attack_cooldown: float = 1.5

# Timers
var attack_timer: Timer = null
var enemy_check_timer: Timer = null

# Lifespan properties
var lifespan_min: float = 45.0
var lifespan_max: float = 75.0
var lifespan: float = 0.0
var lifespan_timer: Timer = null

func _ready():
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	add_to_group("units")
	
	# Create combat timers
	create_attack_timer()
	create_enemy_check_timer()
	
	# Create and start lifespan timer
	create_lifespan_timer()
	
	# Start movement
	pick_random_target()
	
	print(type + " created")

func create_attack_timer():
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)

func create_enemy_check_timer():
	# Check for nearby enemies every 0.5 seconds
	enemy_check_timer = Timer.new()
	add_child(enemy_check_timer)
	enemy_check_timer.wait_time = 0.5
	enemy_check_timer.timeout.connect(_check_for_enemies)
	enemy_check_timer.start()

func create_lifespan_timer():
	lifespan = randf_range(lifespan_min, lifespan_max)
	
	lifespan_timer = Timer.new()
	add_child(lifespan_timer)
	lifespan_timer.wait_time = lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_lifespan_timeout)
	lifespan_timer.start()
	print(type + " will die in " + str(round(lifespan)) + " seconds")

func _on_lifespan_timeout():
	print(type + " died of old age")
	die()

func _on_attack_cooldown_finished():
	can_attack = true

# Mouse hover effects
func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)

# Interaction
func on_interact():
	print("You clicked on " + type + "!")

# Combat
func take_damage(amount: int):
	health -= amount
	print(type + " took " + str(amount) + " damage. Health: " + str(health))
	
	# Flash red when taking damage
	if animated_sprite:
		animated_sprite.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	print(type + " died")
	queue_free()

func attack_target(target):
	if not can_attack or is_attacking:
		return
	
	# Check if target is still valid before attacking
	if not is_instance_valid(target):
		enemy_target = null
		return
	
	is_attacking = true
	can_attack = false
	
	# Play attack animation if it exists
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	# Get target type safely
	var target_type = "target"
	if target and "type" in target:
		target_type = target.type
	
	print(type + " attacks " + target_type + "!")
	
	# Check again before dealing damage (target might have died during animation)
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	# Start cooldown
	attack_timer.start()
	
	# Wait for attack animation
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	
	# Clear target if it died
	if not is_instance_valid(enemy_target):
		enemy_target = null

func _check_for_enemies():
	if not can_attack_enemies:
		return
	
	# Clear invalid target
	if enemy_target and not is_instance_valid(enemy_target):
		enemy_target = null
	
	# Find closest enemy within detection range
	var closest_enemy = null
	var closest_distance = detection_range
	
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	
	# Update enemy target
	if closest_enemy:
		enemy_target = closest_enemy

# Movement & AI
func _physics_process(delta):
	# Priority 1: Combat
	if enemy_target and is_instance_valid(enemy_target):
		handle_combat(delta)
		return
	
	# Clear attacking state when no valid enemy
	if is_attacking:
		is_attacking = false
	
	# Priority 2: Normal movement
	if is_moving and not is_attacking:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5:
			global_position += direction * movement_speed * delta
			
			if animated_sprite:
				if direction.x < 0:
					animated_sprite.flip_h = true
				else:
					animated_sprite.flip_h = false
				
				# Play walk animation when moving normally
				if animated_sprite.sprite_frames.has_animation("walk"):
					animated_sprite.play("walk")
		else:
			start_idle()

func handle_combat(delta):
	# Check if enemy target is still valid
	if not is_instance_valid(enemy_target):
		enemy_target = null
		is_attacking = false  # Clear attacking state
		# Resume normal movement
		if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
		return
	
	var distance = global_position.distance_to(enemy_target.global_position)
	
	# Enemy too far, forget it
	if distance > detection_range * 1.5:
		enemy_target = null
		is_attacking = false  # Clear attacking state
		return
	
	# Move toward enemy
	if distance > attack_range:
		var direction = (enemy_target.global_position - global_position).normalized()
		global_position += direction * movement_speed * delta
		
		# Flip sprite
		if animated_sprite:
			if direction.x < 0:
				animated_sprite.flip_h = true
			else:
				animated_sprite.flip_h = false
			
			# Play walk animation if not attacking
			if not is_attacking and animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.play("walk")
	else:
		# Close enough to attack - but check if still valid first
		if can_attack and is_instance_valid(enemy_target):
			attack_target(enemy_target)

func pick_random_target():
	var random_angle = randf() * TAU
	var random_distance = randf() * circle_radius
	
	target_position = center_position + Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
	
	is_moving = true
	is_idle = false
	
	if animated_sprite:
		animated_sprite.play("walk")

func start_idle():
	is_idle = true
	is_moving = false
	
	if animated_sprite:
		animated_sprite.play("idle")
	
	var idle_time = randf_range(1.0, 4.0)
	await get_tree().create_timer(idle_time).timeout
	
	pick_random_target()
