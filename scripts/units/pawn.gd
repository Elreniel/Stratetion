extends Unit

@onready var animated_pawn: AnimatedSprite2D = $PawnSprite
@onready var collision_shape_2d: CollisionShape2D = $PawnCollision
@onready var baby_timer: Timer = $BabyTimer

func _ready():
	animated_sprite = animated_pawn
	collision_shape = collision_shape_2d
	
	type = "Baby"
	
	# Pawn stats - weak
	health = 35
	max_health = 35
	attack_damage = 5
	movement_speed = 25.0
	attack_range = 15.0
	detection_range = 50.0
	attack_cooldown = 4.0
	
	circle_radius = 50.0
	
	lifespan_min = 200.0
	lifespan_max = 300.0
	
	# Connect pawn-specific signals
	baby_timer.timeout.connect(_on_baby_timer_timeout)
	
	# Set initial scale
	animated_pawn.scale = Vector2(0.3, 0.3)
	collision_shape_2d.scale = Vector2(0.3, 0.3)
	
	# Set center position
	center_position = global_position
	
	# Add to pawns group
	add_to_group("pawns")
	
	# Start baby timer
	baby_timer.start(30)
	
	# Call parent _ready()
	super._ready()

func _on_baby_timer_timeout() -> void:
	type = "Single"
	animated_pawn.scale = Vector2(1, 1)
	collision_shape_2d.scale = Vector2(1, 1)
	health = 75
	max_health = 75
	attack_damage = 10
	movement_speed = 50.0
	attack_range = 30.0
	detection_range = 100.0
	attack_cooldown = 2.0
