extends Enemy

# ============================================
# NODE REFERENCES
# ============================================

@onready var animated_goblin: AnimatedSprite2D = $GoblinTorchSprite
@onready var collision_shape_goblin: CollisionShape2D = $GoblinTorchCollision

# ============================================
# GOBLIN STATS
# ============================================

var goblin_health: int = randi_range(65, 85)
var goblin_max_health: int = goblin_health
var goblin_attack_damage: int = randi_range(12, 18)
var goblin_movement_speed: float = randf_range(45.0, 55.0)
var goblin_attack_range: float = randf_range(45.0, 55.0)
var goblin_detection_range: float = randf_range(225.0, 275.0)
var goblin_attack_cooldown: float = randf_range(1.2, 1.8)

# Lifespan
var goblin_lifespan_min: float = randf_range(180.0, 220.0)
var goblin_lifespan_max: float = randf_range(280.0, 320.0)

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	animated_sprite = animated_goblin
	collision_shape = collision_shape_goblin
	type = "Goblin"
	
	# Apply goblin stats
	health = goblin_health
	max_health = goblin_max_health
	attack_damage = goblin_attack_damage
	movement_speed = goblin_movement_speed
	attack_range = goblin_attack_range
	detection_range = goblin_detection_range
	attack_cooldown = goblin_attack_cooldown
	lifespan_min = goblin_lifespan_min
	lifespan_max = goblin_lifespan_max
	
	add_to_group("goblins")
	super._ready()
