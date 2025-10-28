class_name Unit
extends StaticBody2D

# ============================================
# CONFIGURABLE VARIABLES
# ============================================

# Base Properties
var type: String = "Unit"
var health: int = randi_range(80, 120)
var max_health: int = health
var attack_damage: int = randi_range(8, 12)
var movement_speed: float = randf_range(45.0, 55.0)

# Combat Properties
var attack_range: float = randf_range(45.0, 55.0)
var detection_range: float = randf_range(180.0, 220.0)
var attack_cooldown: float = randf_range(1.2, 1.8)
var can_attack_enemies: bool = true
var can_attack: bool = true
var is_attacking: bool = false

# Movement Properties
var circle_radius: float = randf_range(180.0, 220.0)
var is_moving: bool = false
var is_idle: bool = false

# Lifespan Properties
var lifespan_min: float = randf_range(40.0, 50.0)
var lifespan_max: float = randf_range(70.0, 80.0)
var lifespan: float = 0.0

# ============================================
# INTERNAL VARIABLES (Don't modify)
# ============================================

# References
var animated_sprite: AnimatedSprite2D = null
var collision_shape: CollisionShape2D = null
var home = null
var enemy_target = null

# Timers
var attack_timer: Timer = null
var enemy_check_timer: Timer = null
var lifespan_timer: Timer = null

# Movement State
var target_position: Vector2 = Vector2.ZERO
var center_position: Vector2 = Vector2.ZERO

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_to_group("units")
	
	create_attack_timer()
	create_enemy_check_timer()
	create_lifespan_timer()
	pick_random_target()
	
	print(type + " created")

func create_attack_timer():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)

func create_enemy_check_timer():
	enemy_check_timer = Timer.new()
	enemy_check_timer.wait_time = randf_range(0.4, 0.6)
	enemy_check_timer.timeout.connect(_check_for_enemies)
	add_child(enemy_check_timer)
	enemy_check_timer.start()

func create_lifespan_timer():
	lifespan = randf_range(lifespan_min, lifespan_max)
	lifespan_timer = Timer.new()
	lifespan_timer.wait_time = lifespan
	lifespan_timer.one_shot = true
	lifespan_timer.timeout.connect(_on_lifespan_timeout)
	add_child(lifespan_timer)
	lifespan_timer.start()
	print(type + " will die in " + str(round(lifespan)) + " seconds")

# ============================================
# MOUSE INTERACTION
# ============================================

func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)

func on_interact():
	print("You clicked on " + type + "!")

# ============================================
# COMBAT SYSTEM
# ============================================

func take_damage(amount: int):
	health -= amount
	print(type + " took " + str(amount) + " damage. Health: " + str(health))
	
	if animated_sprite:
		animated_sprite.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func attack_target(target):
	if not can_attack or is_attacking or not is_instance_valid(target):
		return
	
	is_attacking = true
	can_attack = false
	
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	var target_type = target.type if target and "type" in target else "target"
	print(type + " attacks " + target_type + "!")
	
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	attack_timer.start()
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	
	if not is_instance_valid(enemy_target):
		enemy_target = null

func _check_for_enemies():
	if not can_attack_enemies:
		return
	
	if enemy_target and not is_instance_valid(enemy_target):
		enemy_target = null
	
	var closest_enemy = null
	var closest_distance = detection_range
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	
	if closest_enemy:
		enemy_target = closest_enemy

func _on_attack_cooldown_finished():
	can_attack = true

# ============================================
# MOVEMENT & AI
# ============================================

func _physics_process(delta):
	if enemy_target and is_instance_valid(enemy_target):
		handle_combat(delta)
		return
	
	if is_attacking:
		is_attacking = false
	
	if is_waiting_for_children():
		if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		is_moving = false
		return
		
	if is_moving and not is_attacking:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5:
			global_position += direction * movement_speed * delta
			
			if animated_sprite:
				animated_sprite.flip_h = direction.x < 0
				if animated_sprite.sprite_frames.has_animation("walk"):
					animated_sprite.play("walk")
		else:
			start_idle()

func handle_combat(delta):
	if not is_instance_valid(enemy_target):
		enemy_target = null
		is_attacking = false
		if animated_sprite and animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
		return
	
	var distance = global_position.distance_to(enemy_target.global_position)
	
	if distance > detection_range * 1.5:
		enemy_target = null
		is_attacking = false
		return
	
	if distance > attack_range:
		var direction = (enemy_target.global_position - global_position).normalized()
		global_position += direction * movement_speed * delta
		
		if animated_sprite:
			animated_sprite.flip_h = direction.x < 0
			if not is_attacking and animated_sprite.sprite_frames.has_animation("walk"):
				animated_sprite.play("walk")
	else:
		if can_attack and is_instance_valid(enemy_target):
			attack_target(enemy_target)

func pick_random_target():
	if is_waiting_for_children():
		return
	
	# Don't pick new targets if waiting for marriage partner
	if is_waiting_for_marriage():
		return
	
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
	if is_waiting_for_children():
		if animated_sprite:
			animated_sprite.play("idle")
		return
	
	# Don't start idle wandering if waiting for marriage partner
	if is_waiting_for_marriage():
		if animated_sprite:
			animated_sprite.play("idle")
		return
	
	is_idle = true
	is_moving = false
	
	if animated_sprite:
		animated_sprite.play("idle")
	
	var idle_time = randf_range(1.0, 4.0)
	await get_tree().create_timer(idle_time).timeout
	pick_random_target()

# ============================================
# LIFESPAN & DEATH
# ============================================

func _on_lifespan_timeout():
	print(type + " died of old age")
	die()

func die():
	print(type + " died")
	queue_free()

# ============================================
# HELPER FUNCTIONS
# ============================================

func is_waiting_for_children() -> bool:
	return has_meta("waiting_for_children") and get_meta("waiting_for_children") == true

func is_waiting_for_marriage() -> bool:
	return has_meta("waiting_for_marriage") and get_meta("waiting_for_marriage") == true
