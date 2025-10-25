class_name Unit
extends StaticBody2D

# Base properties that all units share
var animated_sprite: AnimatedSprite2D = null
var collision_shape: CollisionShape2D = null
var type: String = "Unit"
var home = null
var health: int = 100
var attack_damage: int = 10
var movement_speed: float = 50.0
var target_position = Vector2.ZERO
var circle_radius = 200.0
var center_position = Vector2.ZERO
var is_moving = false
var is_idle = false

# Lifespan properties
var lifespan_min: float = 45.0  # Minimum lifespan in seconds
var lifespan_max: float = 75.0  # Maximum lifespan in seconds
var lifespan: float = 0.0  # Will be set randomly
var lifespan_timer: Timer = null

func _ready():
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	add_to_group("units")
	
	# Create and start lifespan timer
	create_lifespan_timer()
	
	# Start movement
	pick_random_target()
	
	print(type + " created")

func create_lifespan_timer():
	# Pick random lifespan between min and max
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

# Mouse hover effects
func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2)  # Brighten

func _on_mouse_exited():
	modulate = Color(1, 1, 1)  # Normal color

# Interaction - can be overridden by child classes
func on_interact():
	print("You clicked on " + type + "!")

# Base function that all units have
func take_damage(amount: int):
	health -= amount
	print(type + " took " + str(amount) + " damage. Health: " + str(health))
	if health <= 0:
		die()

func die():
	print(type + " died")
	queue_free()

func attack(target):
	print(type + " attacks for " + str(attack_damage) + " damage")
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
		
func _physics_process(delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5:
			global_position += direction * movement_speed * delta
			
			if animated_sprite:
				if direction.x < 0:
					animated_sprite.flip_h = true
				else:
					animated_sprite.flip_h = false
		else:
			start_idle()
			
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
