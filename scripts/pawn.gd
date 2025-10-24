extends StaticBody2D

@onready var animated_pawn: AnimatedSprite2D = $AnimatedPawn
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var baby_timer: Timer = $BabyTimer
@onready var teenager_timer: Timer = $TeenagerTimer

var movement_speed = 50.0
var target_position = Vector2.ZERO
var circle_radius = 200.0
var center_position = Vector2.ZERO
var is_moving = false
var is_idle = false

var type
var home

func _ready():
	
	add_to_group("pawns") 
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	baby_timer.timeout.connect(_on_baby_timer_timeout)
	teenager_timer.timeout.connect(_on_teenager_timer_timeout)
	
	animated_pawn.scale = Vector2(0.3,0.3)
	collision_shape_2d.scale = Vector2(0.3,0.3)
	
	center_position = global_position
	
	type = "Baby"
	baby_timer.start(randf_range(1.0, 5.0))
	pick_random_target()
	
func on_interact():
	print("You clicked on the Pawn!")

func _on_mouse_entered():
	modulate = Color(1.2, 1.2, 1.2)  # Brighten

func _on_mouse_exited():
	modulate = Color(1, 1, 1)  # Normal color


func _on_baby_timer_timeout() -> void:
	animated_pawn.scale = Vector2(0.6,0.6)
	collision_shape_2d.scale = Vector2(2,2)
	type = "Teenager"
	teenager_timer.start(randf_range(1.0, 10.0))

func _on_teenager_timer_timeout() -> void:
	type = "Single"
	animated_pawn.scale = Vector2(1,1)
	collision_shape_2d.scale = Vector2(1,1)
	
func _physics_process(delta):
	if is_moving:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > 5:
			global_position += direction * movement_speed * delta
			
			if direction.x < 0:
				animated_pawn.flip_h = true
			else:
				animated_pawn.flip_h = false
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
	
	animated_pawn.play("walk")
	
func start_idle():
	is_idle = true
	is_moving = false
	
	animated_pawn.play("idle")
	
	var idle_time = randf_range(1.0, 4.0)
	await get_tree().create_timer(idle_time).timeout
	
	pick_random_target()
