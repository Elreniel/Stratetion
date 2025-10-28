extends Unit

# ============================================
# NODE REFERENCES
# ============================================

@onready var animated_knight: AnimatedSprite2D = $KnightSprite
@onready var collision_shape_knight: CollisionShape2D = $KnightCollision

# ============================================
# STRONG PHASE STATS (Tank with high damage)
# ============================================

var strong_health: int = randi_range(130, 170)
var strong_max_health: int = strong_health
var strong_attack_damage: int = randi_range(20, 30)
var strong_movement_speed: float = randf_range(45.0, 55.0)
var strong_attack_range: float = randf_range(45.0, 55.0)
var strong_detection_range: float = randf_range(450.0, 550.0)
var strong_attack_cooldown: float = randf_range(1.2, 1.8)

# ============================================
# WEAK PHASE STATS (Randomized Half Range)
# ============================================

var weak_health: int = randi_range(65, 85)
var weak_max_health: int = weak_health
var weak_attack_damage: int = randi_range(10, 15)
var weak_movement_speed: float = randf_range(22.5, 27.5)
var weak_attack_range: float = randf_range(22.5, 27.5)
var weak_detection_range: float = randf_range(225.0, 275.0)
var weak_attack_cooldown: float = randf_range(2.4, 3.6)

# ============================================
# SETTINGS
# ============================================

# Lifespan
var knight_lifespan_min: float = randf_range(180.0, 220.0)
var knight_lifespan_max: float = randf_range(280.0, 320.0)

# Patrol settings
var default_patrol_radius: float = randf_range(180.0, 220.0)

# ============================================
# KNIGHT BEHAVIOR
# ============================================

var should_guard_home: bool = false

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	animated_sprite = animated_knight
	collision_shape = collision_shape_knight
	type = "Knight"
	
	# Apply strong stats (Knights start fully trained)
	health = strong_health
	max_health = strong_max_health
	attack_damage = strong_attack_damage
	movement_speed = strong_movement_speed
	attack_range = strong_attack_range
	detection_range = strong_detection_range
	attack_cooldown = strong_attack_cooldown
	lifespan_min = knight_lifespan_min
	lifespan_max = knight_lifespan_max
	center_position = global_position
	
	super._ready()
	call_deferred("set_city_patrol_area")
	print("Knight ready to patrol city!")

# ============================================
# CITY PATROL SYSTEM
# ============================================

func set_city_patrol_area():
	var main = get_parent()
	
	if main and main.has_method("get_city_patrol_position"):
		if main.city_initialized:
			center_position = main.city_center
			circle_radius = max(
				main.city_border_right - main.city_border_left,
				main.city_border_bottom - main.city_border_top
			) / 2.0
			
			print("Knight patrolling city - Center: " + str(center_position) + " Radius: " + str(circle_radius))
			pick_random_target()
		else:
			set_home_patrol()
	else:
		set_home_patrol()

func set_home_patrol():
	if home and is_instance_valid(home):
		center_position = home.global_position
		circle_radius = default_patrol_radius
		print("City not initialized, patrolling around home")
	pick_random_target()
