class_name Building
extends StaticBody2D

# ============================================
# CONFIGURABLE VARIABLES
# ============================================

# Building Properties
var building_type: String = "Building"
var type: String = "Building"  # For compatibility with attack system
var health: int = randi_range(180, 220)
var max_health: int = health
var max_occupants: int = randi_range(8, 12)

# Visual Feedback
var damage_flash_duration: float = 0.1
var damage_flash_color: Color = Color(1.5, 0.5, 0.5)
var normal_color: Color = Color(1, 1, 1)

# ============================================
# INTERNAL VARIABLES (Don't modify)
# ============================================

var is_occupied: bool = false
var occupants: Array = []

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	add_to_group("buildings")
	print(building_type + " created with " + str(health) + " health")

# ============================================
# COMBAT
# ============================================

func take_damage(amount: int):
	health -= amount
	print(building_type + " took " + str(amount) + " damage! Health: " + str(health) + "/" + str(max_health))
	
	# Visual feedback - flash red
	modulate = damage_flash_color
	await get_tree().create_timer(damage_flash_duration).timeout
	modulate = normal_color
	
	if health <= 0:
		on_destroyed()

func on_destroyed():
	print(building_type + " destroyed!")
	queue_free()

# ============================================
# PLACEMENT
# ============================================

func can_place_here(position: Vector2) -> bool:
	return true
