extends Unit

# ============================================
# NODE REFERENCES
# ============================================

@onready var animated_pawn: AnimatedSprite2D = $PawnSprite
@onready var collision_shape_2d: CollisionShape2D = $PawnCollision
@onready var baby_timer: Timer = $BabyTimer

# ============================================
# STRONG PHASE STATS (Actual Stats)
# ============================================

var strong_health: int = randi_range(65, 85)
var strong_max_health: int = strong_health
var strong_attack_damage: int = randi_range(8, 12)
var strong_movement_speed: float = randf_range(45.0, 55.0)
var strong_attack_range: float = randf_range(25.0, 35.0)
var strong_detection_range: float = randf_range(90.0, 110.0)
var strong_attack_cooldown: float = randf_range(1.7, 2.3)

# ============================================
# WEAK PHASE STATS (Randomized Half Range)
# ============================================

var weak_health: int = randi_range(32, 42)
var weak_max_health: int = weak_health
var weak_attack_damage: int = randi_range(4, 6)
var weak_movement_speed: float = randf_range(22.5, 27.5)
var weak_attack_range: float = randf_range(12.5, 17.5)
var weak_detection_range: float = randf_range(45.0, 55.0)
var weak_attack_cooldown: float = randf_range(3.4, 4.6)

# ============================================
# PHASE SETTINGS
# ============================================

var baby_scale: Vector2 = Vector2(0.3, 0.3)
var adult_scale: Vector2 = Vector2(1.0, 1.0)
var baby_duration: float = randf_range(25.0, 35.0)
var weak_circle_radius: float = randf_range(45.0, 55.0)

# Lifespan (remains long for both phases)
var pawn_lifespan_min: float = randf_range(180.0, 220.0)
var pawn_lifespan_max: float = randf_range(280.0, 320.0)

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	animated_sprite = animated_pawn
	collision_shape = collision_shape_2d
	type = "Baby"
	
	# Apply weak phase stats
	health = weak_health
	max_health = weak_max_health
	attack_damage = weak_attack_damage
	movement_speed = weak_movement_speed
	attack_range = weak_attack_range
	detection_range = weak_detection_range
	attack_cooldown = weak_attack_cooldown
	circle_radius = weak_circle_radius
	lifespan_min = pawn_lifespan_min
	lifespan_max = pawn_lifespan_max
	
	# Set baby appearance
	animated_pawn.scale = baby_scale
	collision_shape_2d.scale = baby_scale
	center_position = global_position
	
	# Setup groups and timers
	add_to_group("pawns")
	baby_timer.timeout.connect(_on_baby_timer_timeout)
	baby_timer.start(baby_duration)
	
	super._ready()

# ============================================
# PHASE TRANSITION
# ============================================

func _on_baby_timer_timeout() -> void:
	type = "Single"
	
	# Transform to adult appearance
	animated_pawn.scale = adult_scale
	collision_shape_2d.scale = adult_scale
	
	# Apply strong phase stats
	health = strong_health
	max_health = strong_max_health
	attack_damage = strong_attack_damage
	movement_speed = strong_movement_speed
	attack_range = strong_attack_range
	detection_range = strong_detection_range
	attack_cooldown = strong_attack_cooldown
