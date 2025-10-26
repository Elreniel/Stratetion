class_name Enemy
extends StaticBody2D

# References
var animated_sprite: AnimatedSprite2D = null
var collision_shape: CollisionShape2D = null

# Enemy properties
var type: String = "Enemy"
var health: int = 50
var max_health: int = 50
var attack_damage: int = 10
var movement_speed: float = 30.0
var attack_range: float = 40.0
var detection_range: float = 300.0

# AI & Combat
var target_unit = null
var is_moving: bool = false
var is_attacking: bool = false
var can_attack: bool = true
var attack_cooldown: float = 1.5

# Patrol
var castle_position: Vector2 = Vector2.ZERO  # Castle position
var patrol_speed_multiplier: float = 0.6  # Patrol slower than chase

# Timers
var attack_timer: Timer = null
var target_check_timer: Timer = null
var lifespan_timer: Timer = null

# Lifespan
var lifespan_min: float = 120.0
var lifespan_max: float = 180.0

func _ready():
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Add to groups
	add_to_group("enemies")
	
	# Castle position will be set by spawner
	# Default to center if not set
	if castle_position == Vector2.ZERO:
		var viewport = get_viewport_rect()
		castle_position = viewport.size / 2
	
	# Setup timers
	create_attack_timer()
	create_target_check_timer()
	create_lifespan_timer()
	
	# Find initial target immediately (don't wait for timer)
	call_deferred("_check_for_targets")
	
	print(type + " spawned!")

func create_attack_timer():
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)

func create_target_check_timer():
	target_check_timer = Timer.new()
	add_child(target_check_timer)
	target_check_timer.wait_time = 0.3  # Check frequently
	target_check_timer.timeout.connect(_check_for_targets)
	target_check_timer.start()

func create_lifespan_timer():
	var lifespan = randf_range(lifespan_min, lifespan_max)
	lifespan_timer = Timer.new()
	add_child(lifespan_timer)
	lifespan_timer.wait_time = lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_lifespan_timeout)
	lifespan_timer.start()
	print(type + " will despawn in " + str(round(lifespan)) + " seconds")

func _on_lifespan_timeout():
	print(type + " despawned")
	die()

func _physics_process(delta):
	if is_attacking:
		return
	
	if target_unit and is_instance_valid(target_unit):
		var distance = global_position.distance_to(target_unit.global_position)
		
		# Target too far, forget it
		if distance > detection_range * 1.5:
			target_unit = null
			patrol_toward_castle(delta)
			return
		
		# Close enough to attack
		if distance <= attack_range:
			if can_attack:
				attack(target_unit)
		else:
			# Move toward target
			move_toward_target(target_unit.global_position, delta)
	else:
		# No target - patrol toward castle
		patrol_toward_castle(delta)

func _check_for_targets():
	var closest_unit = null
	var closest_distance = detection_range
	
	var all_units = get_tree().get_nodes_in_group("units")
	
	for unit in all_units:
		if is_instance_valid(unit):
			var distance = global_position.distance_to(unit.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_unit = unit
	
	if closest_unit:
		target_unit = closest_unit

func move_toward_target(target_pos: Vector2, delta: float):
	var direction = (target_pos - global_position).normalized()
	global_position += direction * movement_speed * delta
	
	is_moving = true
	
	# Flip sprite based on direction
	if animated_sprite:
		if direction.x < 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		
		# Play walk animation
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

func patrol_toward_castle(delta):
	var distance_to_castle = global_position.distance_to(castle_position)
	
	# If very close to castle, attack it or just idle
	if distance_to_castle < 50:
		play_idle()
		# Optional: Attack castle here
		return
	
	# Move toward castle
	var direction = (castle_position - global_position).normalized()
	global_position += direction * movement_speed * patrol_speed_multiplier * delta
	
	is_moving = true
	
	# Flip sprite based on direction
	if animated_sprite:
		if direction.x < 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		
		# Play walk animation
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

func attack(target):
	if not can_attack or is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	
	# Play attack animation
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("attack"):
			animated_sprite.play("attack")
	
	# Get target type safely
	var target_type = "target"
	if target and "type" in target:
		target_type = target.type
	
	print(type + " attacks " + target_type + "!")
	
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	attack_timer.start()
	
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func _on_attack_cooldown_finished():
	can_attack = true

func play_idle():
	is_moving = false
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

func take_damage(amount: int):
	health -= amount
	print(type + " took " + str(amount) + " damage. Health: " + str(health))
	
	# Flash red
	if animated_sprite:
		animated_sprite.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	print(type + " died!")
	queue_free()

# Mouse hover
func _on_mouse_entered():
	modulate = Color(1.3, 1.0, 1.0)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)
