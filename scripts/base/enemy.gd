class_name Enemy
extends StaticBody2D

# ============================================
# CONFIGURABLE VARIABLES
# ============================================

# Enemy Properties
var type: String = "Enemy"
var health: int = randi_range(40, 60)
var max_health: int = health
var attack_damage: int = randi_range(8, 12)
var movement_speed: float = randf_range(25.0, 35.0)
var attack_range: float = randf_range(35.0, 45.0)
var detection_range: float = randf_range(270.0, 330.0)
var attack_cooldown: float = randf_range(1.2, 1.8)

# Patrol Behavior
var patrol_speed_multiplier: float = randf_range(0.5, 0.7)

# Lifespan
var lifespan_min: float = randf_range(110.0, 130.0)
var lifespan_max: float = randf_range(170.0, 190.0)

# Detection Multipliers
var detection_range_multiplier: float = 1.5
var building_detection_multiplier: float = 1.3
var castle_attack_range_multiplier: float = 2.0

# Target Check Frequency
var target_check_interval: float = randf_range(0.25, 0.35)

# Castle Proximity
var castle_proximity_check: float = 200.0
var castle_stop_distance: float = 50.0

# ============================================
# INTERNAL VARIABLES (Don't modify)
# ============================================

# References
var animated_sprite: AnimatedSprite2D = null
var collision_shape: CollisionShape2D = null

# AI & Combat State
var target_unit = null
var is_moving: bool = false
var is_attacking: bool = false
var can_attack: bool = true

# Timers
var attack_timer: Timer = null
var target_check_timer: Timer = null
var lifespan_timer: Timer = null

# Navigation
var castle_position: Vector2 = Vector2.ZERO

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_to_group("enemies")
	
	if castle_position == Vector2.ZERO:
		var viewport = get_viewport_rect()
		castle_position = viewport.size / 2
	
	create_attack_timer()
	create_target_check_timer()
	create_lifespan_timer()
	call_deferred("_check_for_targets")
	
	print(type + " spawned!")

func create_attack_timer():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)

func create_target_check_timer():
	target_check_timer = Timer.new()
	target_check_timer.wait_time = target_check_interval
	target_check_timer.timeout.connect(_check_for_targets)
	add_child(target_check_timer)
	target_check_timer.start()

func create_lifespan_timer():
	var lifespan = randf_range(lifespan_min, lifespan_max)
	lifespan_timer = Timer.new()
	lifespan_timer.wait_time = lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_lifespan_timeout)
	add_child(lifespan_timer)
	lifespan_timer.start()
	print(type + " will despawn in " + str(round(lifespan)) + " seconds")

# ============================================
# AI & MOVEMENT
# ============================================

func _physics_process(delta):
	if is_attacking:
		return
	
	if target_unit and is_instance_valid(target_unit):
		var distance = global_position.distance_to(target_unit.global_position)
		
		if distance > detection_range * detection_range_multiplier:
			target_unit = null
			patrol_toward_castle(delta)
			return
		
		if distance <= attack_range:
			if can_attack:
				attack(target_unit)
		else:
			move_toward_target(target_unit.global_position, delta)
	else:
		patrol_toward_castle(delta)

func _check_for_targets():
	# Priority 1: Units
	var closest_unit = null
	var closest_unit_distance = detection_range
	var all_units = get_tree().get_nodes_in_group("units")
	
	for unit in all_units:
		if is_instance_valid(unit):
			var distance = global_position.distance_to(unit.global_position)
			if distance < closest_unit_distance:
				closest_unit_distance = distance
				closest_unit = unit
	
	if closest_unit:
		target_unit = closest_unit
		return
	
	# Priority 2: Buildings (excluding castle)
	var closest_building = null
	var closest_building_distance = detection_range * building_detection_multiplier
	var all_buildings = get_tree().get_nodes_in_group("buildings")
	
	for building in all_buildings:
		if is_instance_valid(building) and not building.is_in_group("castle"):
			var distance = global_position.distance_to(building.global_position)
			if distance < closest_building_distance:
				closest_building_distance = distance
				closest_building = building
	
	if closest_building:
		target_unit = closest_building
		return
	
	# Priority 3: Castle (only when very close)
	var castles = get_tree().get_nodes_in_group("castle")
	for castle in castles:
		if is_instance_valid(castle):
			var distance = global_position.distance_to(castle.global_position)
			if distance < attack_range * castle_attack_range_multiplier:
				target_unit = castle
				return

func move_toward_target(target_pos: Vector2, delta: float):
	var direction = (target_pos - global_position).normalized()
	global_position += direction * movement_speed * delta
	is_moving = true
	
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

func patrol_toward_castle(delta):
	var distance_to_castle = global_position.distance_to(castle_position)
	
	if distance_to_castle < castle_proximity_check:
		_check_for_targets()
		if target_unit:
			return
	
	if distance_to_castle < castle_stop_distance:
		play_idle()
		return
	
	var direction = (castle_position - global_position).normalized()
	global_position += direction * movement_speed * patrol_speed_multiplier * delta
	is_moving = true
	
	if animated_sprite:
		animated_sprite.flip_h = direction.x < 0
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

# ============================================
# COMBAT
# ============================================

func attack(target):
	if not can_attack or is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	var target_type = target.type if target and "type" in target else "target"
	print(type + " attacks " + target_type + "!")
	
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	attack_timer.start()
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func _on_attack_cooldown_finished():
	can_attack = true

func take_damage(amount: int):
	health -= amount
	print(type + " took " + str(amount) + " damage. Health: " + str(health))
	
	if animated_sprite:
		animated_sprite.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

# ============================================
# LIFESPAN & DEATH
# ============================================

func _on_lifespan_timeout():
	print(type + " despawned")
	die()

func die():
	print(type + " died!")
	queue_free()

# ============================================
# UTILITY
# ============================================

func play_idle():
	is_moving = false
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _on_mouse_entered():
	modulate = Color(1.3, 1.0, 1.0)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)
