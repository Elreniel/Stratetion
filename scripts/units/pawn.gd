extends Unit

@onready var animated_pawn: AnimatedSprite2D = $AnimatedPawn
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var baby_timer: Timer = $BabyTimer
@onready var teenager_timer: Timer = $TeenagerTimer

func _ready():
	animated_sprite = animated_pawn
	collision_shape = collision_shape_2d
	
	type = "Baby"
	
	# Pawn stats - weak
	health = 80
	max_health = 80
	attack_damage = 5
	movement_speed = 50.0
	attack_range = 40.0
	detection_range = 150.0
	attack_cooldown = 2.0
	
	lifespan_min = 100.0
	lifespan_max = 150.0
	
	# Connect pawn-specific signals
	baby_timer.timeout.connect(_on_baby_timer_timeout)
	teenager_timer.timeout.connect(_on_teenager_timer_timeout)
	
	# Set initial scale
	animated_pawn.scale = Vector2(0.3, 0.3)
	collision_shape_2d.scale = Vector2(0.3, 0.3)
	
	# Set center position
	center_position = global_position
	
	# Add to pawns group
	add_to_group("pawns")
	
	# Start baby timer
	baby_timer.start(randf_range(1.0, 5.0))
	
	# Call parent _ready()
	super._ready()

func _on_baby_timer_timeout() -> void:
	animated_pawn.scale = Vector2(0.6, 0.6)
	collision_shape_2d.scale = Vector2(2, 2)
	type = "Teenager"
	health = 90
	attack_damage = 8
	teenager_timer.start(randf_range(1.0, 10.0))

func _on_teenager_timer_timeout() -> void:
	type = "Single"
	animated_pawn.scale = Vector2(1, 1)
	collision_shape_2d.scale = Vector2(1, 1)
	health = 100
	attack_damage = 10
