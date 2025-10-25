extends Unit

@onready var animated_pawn: AnimatedSprite2D = $AnimatedPawn
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var baby_timer: Timer = $BabyTimer
@onready var teenager_timer: Timer = $TeenagerTimer

func _ready():
	# Set the animated_sprite reference for the base class
	animated_sprite = animated_pawn
	collision_shape = collision_shape_2d
	# Pawn-specific setup
	type = "Baby"
	
	# Connect pawn-specific signals
	baby_timer.timeout.connect(_on_baby_timer_timeout)
	teenager_timer.timeout.connect(_on_teenager_timer_timeout)
	
	# Set initial scale
	animated_pawn.scale = Vector2(0.3, 0.3)
	collision_shape_2d.scale = Vector2(0.3, 0.3)
	
	# Set center position (must be set BEFORE calling super._ready())
	center_position = global_position
	
	# Add to pawns group (in addition to units group from parent)
	add_to_group("pawns")
	
	# Start baby timer
	baby_timer.start(randf_range(1.0, 5.0))
	
	# Call parent _ready() - this will call pick_random_target()
	super._ready()

# Growth stages
func _on_baby_timer_timeout() -> void:
	animated_pawn.scale = Vector2(0.6, 0.6)
	collision_shape_2d.scale = Vector2(2, 2)
	type = "Teenager"
	teenager_timer.start(randf_range(1.0, 10.0))

func _on_teenager_timer_timeout() -> void:
	type = "Single"
	animated_pawn.scale = Vector2(1, 1)
	collision_shape_2d.scale = Vector2(1, 1)
